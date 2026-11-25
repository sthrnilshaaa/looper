// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#include "include/mpv_audio_kit/mpv_audio_kit_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

#include <cstring>

#include "engine_ownership.h"
#include "mpris_server.h"

/**
 * @file mpv_audio_kit_plugin.cc
 * @brief Implementation of the Linux side of the mpv_audio_kit plugin.
 */

// Macros to simplify GObject casting.
#define MPV_AUDIO_KIT_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), mpv_audio_kit_plugin_get_type(), \
                               MpvAudioKitPlugin))

// Private struct for the plugin instance, one per engine.
struct _MpvAudioKitPlugin {
  GObject parent_instance;
  // This engine's end of `mpv_audio_kit/media_session/commands` (one ref).
  FlEventChannel* media_session_events;
  // Counted in the hub until dispose.
  bool in_hub;
};

namespace {

// The OS media session of the process: one MPRIS server, as the bus name it
// owns, shared by the plugin of every engine. The first engine to enable owns
// it until it disables or detaches (engine_ownership.h), and the server sends
// the commands to that engine's event channel. Created with the first
// plugin, deleted with the last.
struct MprisHub {
  mpv_audio_kit::EngineOwnership<FlEventChannel*> engines;
  mpv_audio_kit::MprisServer server{[this] { return engines.CommandSink(); }};
  int plugins = 0;
};

MprisHub* hub = nullptr;

}  // namespace

// Define the GType for the plugin.
G_DEFINE_TYPE(MpvAudioKitPlugin, mpv_audio_kit_plugin, g_object_get_type())

/**
 * @brief Handler for the OS media-session method channel.
 *
 * Routes `enable` / `updateConfig` / `updateMetadata` / `updatePlayback` /
 * `disable` / `debugMediaSessionState` to the process's MprisServer. Only
 * the owner engine's calls change it: another engine's enable answers
 * `already_owned`, its updates and disable are dropped.
 */
static void media_session_method_call_cb(FlMethodChannel* channel,
                                         FlMethodCall* method_call,
                                         gpointer user_data) {
  MpvAudioKitPlugin* plugin = MPV_AUDIO_KIT_PLUGIN(user_data);
  // The hub lives while any plugin does, and this handler holds a ref on
  // its plugin.
  mpv_audio_kit::MprisServer* mpris = &hub->server;
  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);
  g_autoptr(FlMethodResponse) response = nullptr;

  // enable/update* carry a map payload; reject malformed input rather than
  // letting fl_value_lookup_string emit a GLib critical on a null/non-map arg.
  const bool needs_map =
      strcmp(method, "enable") == 0 || strcmp(method, "updateConfig") == 0 ||
      strcmp(method, "updateMetadata") == 0 ||
      strcmp(method, "updatePlayback") == 0;
  if (needs_map &&
      (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP)) {
    // As on Windows: a malformed enable fails, a malformed update is dropped.
    response =
        strcmp(method, "enable") == 0
            ? FL_METHOD_RESPONSE(fl_method_error_response_new(
                  "bad_args", "enable expects a map", nullptr))
            : FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
    fl_method_call_respond(method_call, response, nullptr);
    return;
  }

  if (strcmp(method, "enable") == 0) {
    if (hub->engines.TryEnable(plugin)) {
      mpris->Enable(fl_value_lookup_string(args, "config"),
                    fl_value_lookup_string(args, "metadata"),
                    fl_value_lookup_string(args, "playback"));
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
    } else {
      // Dart throws a StateError and leaves its state off.
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "already_owned",
          "Another Flutter engine of this process owns the media session.",
          nullptr));
    }
  } else if (strcmp(method, "updateConfig") == 0) {
    if (hub->engines.MayUpdate(plugin)) mpris->UpdateConfig(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "updateMetadata") == 0) {
    if (hub->engines.MayUpdate(plugin)) mpris->UpdateMetadata(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "updatePlayback") == 0) {
    if (hub->engines.MayUpdate(plugin)) mpris->UpdatePlayback(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "disable") == 0) {
    if (hub->engines.MayDisable(plugin)) {
      mpris->Disable();
      hub->engines.OnDisabled();
    }
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "debugMediaSessionState") == 0) {
    g_autoptr(FlValue) state = mpris->DebugState();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(state));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }
  fl_method_call_respond(method_call, response, nullptr);
}

// Event-channel handlers for `mpv_audio_kit/media_session/commands`: the
// MprisServer sends the commands to the owner engine's channel while its
// Dart listens. user_data is the plugin.
static FlMethodErrorResponse* media_session_events_listen_cb(
    FlEventChannel* channel, FlValue* args, gpointer user_data) {
  if (hub != nullptr) hub->engines.OnListen(user_data, channel);
  return nullptr;
}

static FlMethodErrorResponse* media_session_events_cancel_cb(
    FlEventChannel* channel, FlValue* args, gpointer user_data) {
  if (hub != nullptr) hub->engines.OnCancel(user_data);
  return nullptr;
}

/**
 * @brief Cleans up the plugin instance resources.
 */
static void mpv_audio_kit_plugin_dispose(GObject* object) {
  MpvAudioKitPlugin* self = MPV_AUDIO_KIT_PLUGIN(object);
  if (self->media_session_events != nullptr) {
    // No listen or cancel may reach the plugin once it is gone.
    fl_event_channel_set_stream_handlers(self->media_session_events, nullptr,
                                         nullptr, nullptr, nullptr);
    g_clear_object(&self->media_session_events);
  }
  if (self->in_hub) {
    self->in_hub = false;
    // The engine is going, and its Dart may never have disabled (an engine
    // destroyed while it plays): the session goes with its owner. Another
    // engine's stays.
    if (hub->engines.OnDetach(self)) hub->server.Disable();
    if (--hub->plugins == 0) {
      delete hub;
      hub = nullptr;
    }
  }
  G_OBJECT_CLASS(mpv_audio_kit_plugin_parent_class)->dispose(object);
}

/**
 * @brief Initializes the plugin class.
 */
static void mpv_audio_kit_plugin_class_init(MpvAudioKitPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = mpv_audio_kit_plugin_dispose;
}

/**
 * @brief Initializes the plugin instance.
 */
static void mpv_audio_kit_plugin_init(MpvAudioKitPlugin* self) {
  self->media_session_events = nullptr;
  self->in_hub = false;
}

/**
 * @brief Public entry point for registering the plugin with the Flutter engine.
 */
void mpv_audio_kit_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  MpvAudioKitPlugin* plugin = MPV_AUDIO_KIT_PLUGIN(
      g_object_new(mpv_audio_kit_plugin_get_type(), nullptr));

  // The `mpv_audio_kit` method channel (openFileDescriptor and
  // closeFileDescriptor) is Android's alone: Dart calls it nowhere else, so
  // it is not registered here. libmpv is driven via FFI.

  // ── OS media session via MPRIS2 (GLib/GDBus) ────────────────────────
  // One MprisServer for the process (MprisHub), shared by every engine.
  // The plugin keeps its event channel, where the server forwards the
  // D-Bus commands while this engine owns the session. The method channel
  // routes enable/update*/disable to the server; the messenger keeps it.
  if (hub == nullptr) hub = new MprisHub();
  hub->plugins++;
  plugin->in_hub = true;
  g_autoptr(FlStandardMethodCodec) ms_event_codec =
      fl_standard_method_codec_new();
  plugin->media_session_events = fl_event_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "mpv_audio_kit/media_session/commands",
      FL_METHOD_CODEC(ms_event_codec));
  // No ref for the handlers: dispose clears them before the plugin goes.
  fl_event_channel_set_stream_handlers(plugin->media_session_events,
                                       media_session_events_listen_cb,
                                       media_session_events_cancel_cb,
                                       plugin, nullptr);

  g_autoptr(FlStandardMethodCodec) ms_method_codec =
      fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) ms_method_channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "mpv_audio_kit/media_session", FL_METHOD_CODEC(ms_method_codec));
  fl_method_channel_set_method_call_handler(
      ms_method_channel, media_session_method_call_cb, g_object_ref(plugin),
      g_object_unref);

  g_object_unref(plugin);
}
