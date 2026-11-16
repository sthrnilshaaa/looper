// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#include "include/mpv_audio_kit/mpv_audio_kit_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

#include <cstring>

#include "mpris_server.h"

/**
 * @file mpv_audio_kit_plugin.cc
 * @brief Implementation of the Linux side of the mpv_audio_kit plugin.
 */

// Macros to simplify GObject casting.
#define MPV_AUDIO_KIT_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), mpv_audio_kit_plugin_get_type(), \
                               MpvAudioKitPlugin))

// Private struct for the plugin instance.
struct _MpvAudioKitPlugin {
  GObject parent_instance;
  // Owns the MPRIS2 D-Bus server for the OS media session. Created in
  // register_with_registrar, freed in dispose.
  mpv_audio_kit::MprisServer* mpris;
};

// Define the GType for the plugin.
G_DEFINE_TYPE(MpvAudioKitPlugin, mpv_audio_kit_plugin, g_object_get_type())

/**
 * @brief Handles method calls from Dart via the MethodChannel.
 *
 * The package drives libmpv via direct FFI/C bindings, so the MethodChannel
 * carries no platform methods on Linux.
 *
 * @param self The plugin instance.
 * @param method_call The method call details.
 */
static void mpv_audio_kit_plugin_handle_method_call(
    MpvAudioKitPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  // No platform methods on the main channel; libmpv is driven via FFI.
  response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());

  fl_method_call_respond(method_call, response, nullptr);
}

/**
 * @brief Handler for the OS media-session method channel.
 *
 * Routes `enable` / `updateConfig` / `updateMetadata` / `updatePlayback` /
 * `disable` / `debugMediaSessionState` to the plugin's MprisServer.
 */
static void media_session_method_call_cb(FlMethodChannel* channel,
                                         FlMethodCall* method_call,
                                         gpointer user_data) {
  MpvAudioKitPlugin* plugin = MPV_AUDIO_KIT_PLUGIN(user_data);
  mpv_audio_kit::MprisServer* mpris = plugin->mpris;
  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);
  g_autoptr(FlMethodResponse) response = nullptr;

  // enable/update* carry a map payload; reject malformed input rather than
  // letting fl_value_lookup_string emit a GLib critical on a null/non-map arg.
  const bool needs_map =
      strcmp(method, "enable") == 0 || strcmp(method, "updateConfig") == 0 ||
      strcmp(method, "updateMetadata") == 0 ||
      strcmp(method, "updatePlayback") == 0;
  if (mpris != nullptr && needs_map &&
      (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP)) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
    fl_method_call_respond(method_call, response, nullptr);
    return;
  }

  if (mpris == nullptr) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "enable") == 0) {
    mpris->Enable(fl_value_lookup_string(args, "config"),
                  fl_value_lookup_string(args, "metadata"),
                  fl_value_lookup_string(args, "playback"));
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "updateConfig") == 0) {
    mpris->UpdateConfig(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "updateMetadata") == 0) {
    mpris->UpdateMetadata(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "updatePlayback") == 0) {
    mpris->UpdatePlayback(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "disable") == 0) {
    mpris->Disable();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "debugMediaSessionState") == 0) {
    g_autoptr(FlValue) state = mpris->DebugState();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(state));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }
  fl_method_call_respond(method_call, response, nullptr);
}

// Event-channel handlers for `mpv_audio_kit/media_session/commands`. The
// MprisServer sends commands through this channel; the listen/cancel hooks
// just satisfy the Flutter stream-handler contract.
static FlMethodErrorResponse* media_session_events_listen_cb(
    FlEventChannel* channel, FlValue* args, gpointer user_data) {
  return nullptr;
}

static FlMethodErrorResponse* media_session_events_cancel_cb(
    FlEventChannel* channel, FlValue* args, gpointer user_data) {
  return nullptr;
}

/**
 * @brief Cleans up the plugin instance resources.
 */
static void mpv_audio_kit_plugin_dispose(GObject* object) {
  MpvAudioKitPlugin* self = MPV_AUDIO_KIT_PLUGIN(object);
  if (self->mpris != nullptr) {
    delete self->mpris;
    self->mpris = nullptr;
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
  self->mpris = nullptr;
}

/**
 * @brief Callback for method channel calls, delegating to handle_method_call.
 */
static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  MpvAudioKitPlugin* plugin = MPV_AUDIO_KIT_PLUGIN(user_data);
  mpv_audio_kit_plugin_handle_method_call(plugin, method_call);
}

/**
 * @brief Public entry point for registering the plugin with the Flutter engine.
 */
void mpv_audio_kit_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  MpvAudioKitPlugin* plugin = MPV_AUDIO_KIT_PLUGIN(
      g_object_new(mpv_audio_kit_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "mpv_audio_kit",
                            FL_METHOD_CODEC(codec));

  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  // ── OS media session via MPRIS2 (GLib/GDBus) ────────────────────────
  // The event channel is created first and handed to the MprisServer
  // (which takes ownership of one ref) so incoming D-Bus commands can be
  // forwarded to Dart. The method channel then routes enable/update*/
  // disable to the server. Both channel objects are leaked for the
  // plugin lifetime (matching the channel-ownership pattern Flutter uses).
  g_autoptr(FlStandardMethodCodec) ms_event_codec =
      fl_standard_method_codec_new();
  FlEventChannel* ms_event_channel = fl_event_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "mpv_audio_kit/media_session/commands",
      FL_METHOD_CODEC(ms_event_codec));
  fl_event_channel_set_stream_handlers(ms_event_channel,
                                       media_session_events_listen_cb,
                                       media_session_events_cancel_cb,
                                       nullptr, nullptr);
  plugin->mpris = new mpv_audio_kit::MprisServer(ms_event_channel);

  g_autoptr(FlStandardMethodCodec) ms_method_codec =
      fl_standard_method_codec_new();
  FlMethodChannel* ms_method_channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "mpv_audio_kit/media_session", FL_METHOD_CODEC(ms_method_codec));
  fl_method_channel_set_method_call_handler(
      ms_method_channel, media_session_method_call_cb, g_object_ref(plugin),
      g_object_unref);

  g_object_unref(plugin);
}
