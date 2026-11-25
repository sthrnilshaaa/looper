// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#include "mpris_server.h"

#include <glib/gstdio.h>

#include <signal.h>
#include <unistd.h>

#include <cctype>
#include <cerrno>
#include <cstdlib>
#include <cstring>
#include <string>
#include <utility>

#include "mpris_introspection.h"

namespace mpv_audio_kit {

namespace {

const char kObjectPath[] = "/org/mpris/MediaPlayer2";
const char kRootIface[] = "org.mpris.MediaPlayer2";
const char kPlayerIface[] = "org.mpris.MediaPlayer2.Player";

std::string FlString(FlValue* map, const char* key) {
  FlValue* v = map ? fl_value_lookup_string(map, key) : nullptr;
  if (v && fl_value_get_type(v) == FL_VALUE_TYPE_STRING) {
    return fl_value_get_string(v);
  }
  return std::string();
}

bool FlBool(FlValue* map, const char* key, bool fallback) {
  FlValue* v = map ? fl_value_lookup_string(map, key) : nullptr;
  if (v && fl_value_get_type(v) == FL_VALUE_TYPE_BOOL) return fl_value_get_bool(v);
  return fallback;
}

bool FlInt(FlValue* map, const char* key, int64_t* out) {
  FlValue* v = map ? fl_value_lookup_string(map, key) : nullptr;
  if (v && fl_value_get_type(v) == FL_VALUE_TYPE_INT) {
    *out = fl_value_get_int(v);
    return true;
  }
  return false;
}

double FlDouble(FlValue* map, const char* key, double fallback) {
  FlValue* v = map ? fl_value_lookup_string(map, key) : nullptr;
  if (!v) return fallback;
  if (fl_value_get_type(v) == FL_VALUE_TYPE_FLOAT) return fl_value_get_float(v);
  if (fl_value_get_type(v) == FL_VALUE_TYPE_INT) {
    return static_cast<double>(fl_value_get_int(v));
  }
  return fallback;
}

const char* LoopToStatus(const std::string& loop) {
  if (loop == "file") return "Track";
  if (loop == "playlist") return "Playlist";
  return "None";
}

std::string StatusToLoop(const char* status) {
  if (status && !strcmp(status, "Track")) return "file";
  if (status && !strcmp(status, "Playlist")) return "playlist";
  return "off";
}

std::string SanitizeBusSuffix(const std::string& in) {
  std::string out;
  for (char c : in) {
    out += std::isalnum(static_cast<unsigned char>(c)) ? c : '_';
  }
  if (out.empty()) return "mpv_audio_kit";
  if (std::isdigit(static_cast<unsigned char>(out[0]))) out = "_" + out;
  return out;
}

}  // namespace

MprisServer::MprisServer(std::function<FlEventChannel*()> command_channel)
    : command_channel_(std::move(command_channel)) {
  node_info_ = g_dbus_node_info_new_for_xml(kMprisIntrospectionXml, nullptr);
  changed_props_ =
      g_hash_table_new_full(g_str_hash, g_str_equal, g_free, nullptr);
}

MprisServer::~MprisServer() {
  if (flush_source_id_) {
    g_source_remove(flush_source_id_);
    flush_source_id_ = 0;
  }
  ReleaseBus();
  SweepArtwork();
  if (changed_props_) {
    g_hash_table_destroy(changed_props_);
    changed_props_ = nullptr;
  }
  if (node_info_) {
    g_dbus_node_info_unref(node_info_);
    node_info_ = nullptr;
  }
}

// ── Bus ownership ───────────────────────────────────────────────────────────

void MprisServer::EnsureOwned() {
  if (owner_id_ != 0) return;
  std::string suffix =
      app_name_.empty() ? "mpv_audio_kit" : SanitizeBusSuffix(app_name_);
  // The spec's form for a player that can run more than once: without the
  // instance part a second copy of the app loses the name and, with it,
  // its media controls. Clients match on the part before ".instance".
  // The pid alone is not unique on the bus: each `flatpak run` has a pid
  // namespace of its own, where the app is nearly always pid 2. A name
  // another process holds is asked again with a suffix (OnNameLost).
  std::string bus = "org.mpris.MediaPlayer2." + suffix + ".instance" +
                    std::to_string(getpid());
  if (name_attempt_ > 0) bus += "_" + std::to_string(name_attempt_);
  name_acquired_ = false;
  // Not queued: a name that cannot be taken is lost at once (OnNameLost).
  owner_id_ = g_bus_own_name(G_BUS_TYPE_SESSION, bus.c_str(),
                             G_BUS_NAME_OWNER_FLAGS_DO_NOT_QUEUE, OnBusAcquired,
                             OnNameAcquired, OnNameLost, this, nullptr);
}

void MprisServer::ReleaseBus() {
  if (connection_) {
    if (player_reg_id_) {
      g_dbus_connection_unregister_object(connection_, player_reg_id_);
    }
    if (root_reg_id_) {
      g_dbus_connection_unregister_object(connection_, root_reg_id_);
    }
  }
  player_reg_id_ = 0;
  root_reg_id_ = 0;
  if (owner_id_) {
    g_bus_unown_name(owner_id_);
    owner_id_ = 0;
  }
  connection_ = nullptr;
  name_acquired_ = false;
  name_attempt_ = 0;
}

void MprisServer::OnBusAcquired(GDBusConnection* connection, const gchar*,
                                gpointer user_data) {
  auto* self = static_cast<MprisServer*>(user_data);
  self->connection_ = connection;
  // The introspection XML is a compile-time constant so parsing won't fail in
  // practice, but guard so a future edit can't silently null-deref here.
  if (self->node_info_ == nullptr) return;

  GDBusInterfaceInfo* root =
      g_dbus_node_info_lookup_interface(self->node_info_, kRootIface);
  GDBusInterfaceInfo* player =
      g_dbus_node_info_lookup_interface(self->node_info_, kPlayerIface);

  static const GDBusInterfaceVTable root_vtable = {RootMethodCall,
                                                   RootGetProperty, nullptr};
  static const GDBusInterfaceVTable player_vtable = {
      PlayerMethodCall, PlayerGetProperty, PlayerSetProperty};

  self->root_reg_id_ = g_dbus_connection_register_object(
      connection, kObjectPath, root, &root_vtable, self, nullptr, nullptr);
  self->player_reg_id_ = g_dbus_connection_register_object(
      connection, kObjectPath, player, &player_vtable, self, nullptr, nullptr);

  self->RepublishAll();
}

void MprisServer::OnNameAcquired(GDBusConnection*, const gchar*,
                                 gpointer user_data) {
  static_cast<MprisServer*>(user_data)->name_acquired_ = true;
}

namespace {

// How many names EnsureOwned asks for before it gives up: `instance<pid>`,
// then `instance<pid>_1` and on.
constexpr int kNameAttempts = 8;

// From inside the lost handler GLib still counts a name it never had as
// one to release: the ReleaseName then logs a GLib-GIO-WARNING.
gboolean UnownLater(gpointer owner_id) {
  g_bus_unown_name(GPOINTER_TO_UINT(owner_id));
  return G_SOURCE_REMOVE;
}

}  // namespace

void MprisServer::OnNameLost(GDBusConnection* connection, const gchar*,
                             gpointer user_data) {
  // Either the connection couldn't be established, or another instance took
  // the name. If a live connection exists, unregister the objects before
  // forgetting their ids so a later lost→re-acquired cycle doesn't leak them.
  auto* self = static_cast<MprisServer*>(user_data);
  GDBusConnection* conn = self->connection_ ? self->connection_ : connection;
  if (conn) {
    if (self->player_reg_id_) {
      g_dbus_connection_unregister_object(conn, self->player_reg_id_);
    }
    if (self->root_reg_id_) {
      g_dbus_connection_unregister_object(conn, self->root_reg_id_);
    }
  }
  self->connection_ = nullptr;
  self->root_reg_id_ = 0;
  self->player_reg_id_ = 0;
  // Stop asking for the name, so EnsureOwned asks again on the next Enable
  // instead of keeping a request that never comes back.
  if (self->owner_id_) {
    g_idle_add(UnownLater, GUINT_TO_POINTER(self->owner_id_));
    self->owner_id_ = 0;
  }
  // Another process holds the name (a second Flatpak instance with the
  // same pid): ask for the next one now, not at an Enable that may never
  // come. A name that was ours, or a bus that cannot be reached, waits
  // for the next Enable.
  if (connection != nullptr && self->enabled_ && !self->name_acquired_ &&
      self->name_attempt_ + 1 < kNameAttempts) {
    ++self->name_attempt_;
    self->EnsureOwned();
  }
}

// ── Root interface ──────────────────────────────────────────────────────────

void MprisServer::RootMethodCall(GDBusConnection*, const gchar*, const gchar*,
                                 const gchar*, const gchar* /*method*/,
                                 GVariant*, GDBusMethodInvocation* invocation,
                                 gpointer) {
  // Raise / Quit are advertised but no-ops for an embedded audio session.
  g_dbus_method_invocation_return_value(invocation, nullptr);
}

GVariant* MprisServer::RootGetProperty(GDBusConnection*, const gchar*,
                                       const gchar*, const gchar*,
                                       const gchar* property, GError** error,
                                       gpointer user_data) {
  auto* self = static_cast<MprisServer*>(user_data);
  if (!strcmp(property, "CanQuit")) return g_variant_new_boolean(FALSE);
  if (!strcmp(property, "CanRaise")) return g_variant_new_boolean(FALSE);
  if (!strcmp(property, "HasTrackList")) return g_variant_new_boolean(FALSE);
  if (!strcmp(property, "Identity")) {
    return g_variant_new_string(
        self->app_name_.empty() ? "mpv_audio_kit" : self->app_name_.c_str());
  }
  if (!strcmp(property, "DesktopEntry")) {
    // The basename of the installed .desktop file, supplied verbatim by the
    // consumer. If unset, OMIT the property (return an error so it reads as
    // absent) rather than emitting a guessed value that resolves to the wrong
    // icon — a sanitized display name almost never matches an installed file.
    if (self->desktop_entry_.empty()) {
      g_set_error(error, G_DBUS_ERROR, G_DBUS_ERROR_UNKNOWN_PROPERTY,
                  "DesktopEntry not set");
      return nullptr;
    }
    return g_variant_new_string(self->desktop_entry_.c_str());
  }
  if (!strcmp(property, "SupportedUriSchemes") ||
      !strcmp(property, "SupportedMimeTypes")) {
    return g_variant_new_strv(nullptr, 0);
  }
  // GDBus requires NULL be paired with a set error, or the call hangs/criticals.
  g_set_error(error, G_DBUS_ERROR, G_DBUS_ERROR_UNKNOWN_PROPERTY,
              "Unknown property: %s", property);
  return nullptr;
}

// ── Player interface ────────────────────────────────────────────────────────

void MprisServer::PlayerMethodCall(GDBusConnection*, const gchar*, const gchar*,
                                   const gchar*, const gchar* method,
                                   GVariant* params,
                                   GDBusMethodInvocation* invocation,
                                   gpointer user_data) {
  auto* self = static_cast<MprisServer*>(user_data);
  const bool can_seek = self->seekable_ && self->actions_.count("seek") > 0;
  if (!strcmp(method, "Next")) {
    if (self->actions_.count("next") > 0) self->Emit("next");
  } else if (!strcmp(method, "Previous")) {
    if (self->actions_.count("previous") > 0) self->Emit("previous");
  } else if (!strcmp(method, "Pause")) {
    if (self->CanPauseAction()) self->Emit("pause");
  } else if (!strcmp(method, "Play")) {
    if (self->CanPlayAction()) self->Emit("play");
  } else if (!strcmp(method, "PlayPause")) {
    // The toggle itself when it is declared. With play or pause alone, the
    // one of the two this state calls for, if it is declared.
    if (self->HasAction("playPause")) {
      self->Emit("playPause");
    } else if (self->playing_) {
      if (self->HasAction("pause")) self->Emit("pause");
    } else if (self->HasAction("play")) {
      self->Emit("play");
    }
  } else if (!strcmp(method, "Stop")) {
    if (self->HasAction("stop")) self->Emit("stop");
  } else if (!strcmp(method, "Seek")) {
    // Ignore (but still ack) when not seekable — CanSeek is advertised false.
    if (can_seek) {
      gint64 offset_us = 0;
      g_variant_get(params, "(x)", &offset_us);
      FlValue* m = fl_value_new_map();
      fl_value_set_string_take(m, "type", fl_value_new_string("seekBy"));
      fl_value_set_string_take(m, "offsetMs", fl_value_new_int(offset_us / 1000));
      self->EmitWith(m);
    }
  } else if (!strcmp(method, "SetPosition")) {
    const gchar* track_id = nullptr;
    gint64 pos_us = 0;
    g_variant_get(params, "(&ox)", &track_id, &pos_us);
    // Per spec: ignore if the trackid doesn't match the current track, the
    // source isn't seekable, or the position is out of [0, length].
    const int64_t length_us = self->duration_ms_ * 1000;
    const bool in_bounds =
        pos_us >= 0 && (!self->has_duration_ || pos_us <= length_us);
    if (can_seek && in_bounds && track_id && self->track_id_ == track_id) {
      FlValue* m = fl_value_new_map();
      fl_value_set_string_take(m, "type", fl_value_new_string("seekTo"));
      fl_value_set_string_take(m, "positionMs", fl_value_new_int(pos_us / 1000));
      self->EmitWith(m);
    }
  }
  // Anything else, and a method whose action is not declared: acknowledged,
  // no-op.
  g_dbus_method_invocation_return_value(invocation, nullptr);
}

// The actions the app declared (MediaSession.actions). A command of the bus
// reaches Dart only when its action is one of them, as on the other
// platforms.
bool MprisServer::HasAction(const char* action) const {
  return actions_.count(action) > 0;
}

// Play and Pause, the two methods and the two halves of PlayPause: the
// toggle declares both.
bool MprisServer::CanPlayAction() const {
  return HasAction("play") || HasAction("playPause");
}

bool MprisServer::CanPauseAction() const {
  return HasAction("pause") || HasAction("playPause");
}

GVariant* MprisServer::PlayerPropertyValue(const char* property) {
  if (!strcmp(property, "PlaybackStatus")) {
    // `completed_` (end-of-content) reports Stopped while the session stays
    // enabled, so a finished track doesn't linger as "Paused at full length".
    return g_variant_new_string(
        (!enabled_ || completed_) ? "Stopped"
                                  : (playing_ ? "Playing" : "Paused"));
  }
  if (!strcmp(property, "LoopStatus")) {
    return g_variant_new_string(LoopToStatus(loop_));
  }
  if (!strcmp(property, "Rate")) return g_variant_new_double(rate_);
  if (!strcmp(property, "Shuffle")) return g_variant_new_boolean(shuffle_);
  if (!strcmp(property, "Metadata")) return BuildMetadata();
  if (!strcmp(property, "Position")) {
    return g_variant_new_int64(ExtrapolatedPositionUs());
  }
  if (!strcmp(property, "MinimumRate")) return g_variant_new_double(min_rate_);
  if (!strcmp(property, "MaximumRate")) return g_variant_new_double(max_rate_);
  if (!strcmp(property, "CanGoNext")) {
    return g_variant_new_boolean(enabled_ && actions_.count("next") > 0 &&
                                 has_next_);
  }
  if (!strcmp(property, "CanGoPrevious")) {
    return g_variant_new_boolean(enabled_ && actions_.count("previous") > 0 &&
                                 has_prev_);
  }
  // CanPlay/CanPause require real content, not just an enabled session, so a
  // pre-load shell doesn't advertise actionable transport. And the action.
  // Stopped or at the end, the title shown is gone and the one kept may be
  // stale: Play starts the queue again (a kept stop, the last entry from its
  // start) exactly when it has entries.
  if (!strcmp(property, "CanPlay")) {
    return g_variant_new_boolean(
        enabled_ && (completed_ ? queued_ : has_title_) && CanPlayAction());
  }
  if (!strcmp(property, "CanPause")) {
    return g_variant_new_boolean(enabled_ && has_title_ && CanPauseAction());
  }
  if (!strcmp(property, "CanSeek")) {
    return g_variant_new_boolean(enabled_ && seekable_ &&
                                 actions_.count("seek") > 0);
  }
  if (!strcmp(property, "CanControl")) return g_variant_new_boolean(TRUE);
  return nullptr;
}

GVariant* MprisServer::PlayerGetProperty(GDBusConnection*, const gchar*,
                                         const gchar*, const gchar*,
                                         const gchar* property, GError** error,
                                         gpointer user_data) {
  GVariant* v =
      static_cast<MprisServer*>(user_data)->PlayerPropertyValue(property);
  if (!v) {
    g_set_error(error, G_DBUS_ERROR, G_DBUS_ERROR_UNKNOWN_PROPERTY,
                "Unknown property: %s", property);
  }
  return v;
}

gboolean MprisServer::PlayerSetProperty(GDBusConnection*, const gchar*,
                                        const gchar*, const gchar*,
                                        const gchar* property, GVariant* value,
                                        GError** error, gpointer user_data) {
  auto* self = static_cast<MprisServer*>(user_data);
  // GDBus wants the error set with every FALSE. A write whose action is not
  // declared is refused, so the client hears that nothing changed.
  auto refuse = [&](const char* action) {
    g_set_error(error, G_DBUS_ERROR, G_DBUS_ERROR_NOT_SUPPORTED,
                "%s cannot be set: the app does not declare %s", property,
                action);
    return FALSE;
  };
  if (!strcmp(property, "LoopStatus")) {
    if (!self->HasAction("setRepeatMode")) return refuse("setRepeatMode");
    const gchar* s = g_variant_get_string(value, nullptr);
    FlValue* m = fl_value_new_map();
    fl_value_set_string_take(m, "type", fl_value_new_string("setRepeatMode"));
    fl_value_set_string_take(m, "loop",
                             fl_value_new_string(StatusToLoop(s).c_str()));
    self->EmitWith(m);
    return TRUE;
  }
  if (!strcmp(property, "Rate")) {
    if (!self->HasAction("setPlaybackRate")) return refuse("setPlaybackRate");
    double r = g_variant_get_double(value);
    if (r <= 0.0) {
      // MPRIS: a Rate of 0.0 is equivalent to pausing.
      if (!self->CanPauseAction()) return refuse("pause");
      self->Emit("pause");
      return TRUE;
    }
    if (r < self->min_rate_) r = self->min_rate_;
    if (r > self->max_rate_) r = self->max_rate_;
    FlValue* m = fl_value_new_map();
    fl_value_set_string_take(m, "type", fl_value_new_string("setPlaybackRate"));
    fl_value_set_string_take(m, "rate", fl_value_new_float(r));
    self->EmitWith(m);
    return TRUE;
  }
  if (!strcmp(property, "Shuffle")) {
    if (!self->HasAction("setShuffle")) return refuse("setShuffle");
    FlValue* m = fl_value_new_map();
    fl_value_set_string_take(m, "type", fl_value_new_string("setShuffle"));
    fl_value_set_string_take(
        m, "shuffle", fl_value_new_bool(g_variant_get_boolean(value)));
    self->EmitWith(m);
    return TRUE;
  }
  // No volume command exists in the wire protocol, so Volume is not advertised
  // at all (removed from the introspection XML) rather than exposed as a dead
  // read-only slider. Reject any other write defensively.
  g_set_error(error, G_DBUS_ERROR, G_DBUS_ERROR_NOT_SUPPORTED,
              "%s cannot be set", property);
  return FALSE;
}

GVariant* MprisServer::BuildMetadata() {
  GVariantBuilder b;
  g_variant_builder_init(&b, G_VARIANT_TYPE("a{sv}"));
  // An empty a{sv} on end-of-content (Stopped) clears the finished track from
  // the GNOME/KDE popup instead of pinning it at full length.
  if (enabled_ && has_title_ && !completed_) {
    g_variant_builder_add(&b, "{sv}", "mpris:trackid",
                          g_variant_new_object_path(track_id_.c_str()));
    if (has_duration_) {
      g_variant_builder_add(&b, "{sv}", "mpris:length",
                            g_variant_new_int64(duration_ms_ * 1000));
    }
    g_variant_builder_add(&b, "{sv}", "xesam:title",
                          g_variant_new_string(title_.c_str()));
    if (!artist_.empty()) {
      const char* arr[] = {artist_.c_str(), nullptr};
      g_variant_builder_add(&b, "{sv}", "xesam:artist",
                            g_variant_new_strv(arr, -1));
    }
    if (!album_.empty()) {
      g_variant_builder_add(&b, "{sv}", "xesam:album",
                            g_variant_new_string(album_.c_str()));
    }
    if (!album_artist_.empty()) {
      const char* arr[] = {album_artist_.c_str(), nullptr};
      g_variant_builder_add(&b, "{sv}", "xesam:albumArtist",
                            g_variant_new_strv(arr, -1));
    }
    if (!genre_.empty()) {
      const char* arr[] = {genre_.c_str(), nullptr};
      g_variant_builder_add(&b, "{sv}", "xesam:genre",
                            g_variant_new_strv(arr, -1));
    }
    if (xesam_track_ > 0) {
      g_variant_builder_add(&b, "{sv}", "xesam:trackNumber",
                            g_variant_new_int32(static_cast<gint32>(xesam_track_)));
    }
    if (xesam_disc_ > 0) {
      g_variant_builder_add(&b, "{sv}", "xesam:discNumber",
                            g_variant_new_int32(static_cast<gint32>(xesam_disc_)));
    }
    if (!xesam_url_.empty()) {
      g_variant_builder_add(&b, "{sv}", "xesam:url",
                            g_variant_new_string(xesam_url_.c_str()));
    }
    if (!art_url_.empty()) {
      g_variant_builder_add(&b, "{sv}", "mpris:artUrl",
                            g_variant_new_string(art_url_.c_str()));
    }
  }
  return g_variant_builder_end(&b);
}

// ── Change batching ─────────────────────────────────────────────────────────

void MprisServer::MarkChanged(const char* prop) {
  if (!changed_props_) return;
  g_hash_table_add(changed_props_, g_strdup(prop));
  if (flush_source_id_ == 0) {
    flush_source_id_ = g_idle_add(FlushChangedCb, this);
  }
}

gboolean MprisServer::FlushChangedCb(gpointer user_data) {
  static_cast<MprisServer*>(user_data)->FlushChanged();
  return G_SOURCE_REMOVE;
}

void MprisServer::FlushChanged() {
  flush_source_id_ = 0;
  if (!connection_ || !enabled_) {
    g_hash_table_remove_all(changed_props_);
    return;
  }
  if (g_hash_table_size(changed_props_) == 0) return;

  GVariantBuilder b;
  g_variant_builder_init(&b, G_VARIANT_TYPE("a{sv}"));
  GHashTableIter it;
  gpointer key, val;
  g_hash_table_iter_init(&it, changed_props_);
  while (g_hash_table_iter_next(&it, &key, &val)) {
    const char* prop = static_cast<const char*>(key);
    GVariant* v = PlayerPropertyValue(prop);
    if (v) g_variant_builder_add(&b, "{sv}", prop, v);
  }
  g_hash_table_remove_all(changed_props_);

  GVariant* changed = g_variant_builder_end(&b);
  GVariant* params = g_variant_new(
      "(s@a{sv}@as)", kPlayerIface, changed,
      g_variant_new_array(G_VARIANT_TYPE_STRING, nullptr, 0));
  g_dbus_connection_emit_signal(connection_, nullptr, kObjectPath,
                                "org.freedesktop.DBus.Properties",
                                "PropertiesChanged", params, nullptr);
}

void MprisServer::RepublishAll() {
  static const char* kProps[] = {
      "PlaybackStatus", "LoopStatus",    "Rate",          "Shuffle",
      "Metadata",       "MinimumRate",   "MaximumRate",
      "CanGoNext",      "CanGoPrevious", "CanPlay",       "CanPause",
      "CanSeek"};
  for (const char* p : kProps) MarkChanged(p);
}

// ── Command forwarding ──────────────────────────────────────────────────────

void MprisServer::Emit(const gchar* type) {
  FlValue* m = fl_value_new_map();
  fl_value_set_string_take(m, "type", fl_value_new_string(type));
  EmitWith(m);
}

void MprisServer::EmitWith(FlValue* command) {
  FlEventChannel* channel = command_channel_ ? command_channel_() : nullptr;
  if (channel) fl_event_channel_send(channel, command, nullptr, nullptr);
  fl_value_unref(command);
}

// ── Position extrapolation ──────────────────────────────────────────────────

int64_t MprisServer::ExtrapolatedPositionUs() const {
  int64_t us = base_position_ms_ * 1000;
  // Advance only while audio is genuinely playing (not during a buffer stall or
  // a seek transient where intent stays true) so the slider doesn't over-run.
  if (actual_playing_) {
    gint64 now = g_get_monotonic_time();
    us += static_cast<int64_t>((now - base_monotonic_us_) * rate_);
  }
  if (us < 0) us = 0;
  // Clamp to the track length so a poll past the last update while playing
  // doesn't report Position beyond mpris:length (clients render >100%).
  if (has_duration_) {
    const int64_t max_us = duration_ms_ * 1000;
    if (us > max_us) us = max_us;
  }
  return us;
}

void MprisServer::AnchorPosition() {
  base_position_ms_ = position_ms_;
  base_monotonic_us_ = g_get_monotonic_time();
}

// ── Artwork temp files ──────────────────────────────────────────────────────

void MprisServer::WriteArtwork(const uint8_t* data, size_t size,
                               const std::string& mime) {
  if (data == nullptr || size == 0) {
    // Switching to no-art: remove the previous temp file too, or it leaks
    // on disk until disable/SweepArtwork.
    if (!prev_art_path_.empty()) {
      g_remove(prev_art_path_.c_str());
      prev_art_path_.clear();
    }
    art_url_.clear();
    has_artwork_ = false;
    art_cache_key_.clear();
    return;
  }
  // Unchanged: compared in the codec's buffer, so the cover of a push that
  // only changes the title is not copied.
  if (size == art_cache_key_.size() &&
      memcmp(data, art_cache_key_.data(), size) == 0) {
    return;
  }

  if (art_dir_.empty()) {
    // One directory per process: two apps on the kit would otherwise
    // overwrite and delete each other's art-N files. g_get_user_runtime_dir
    // never returns NULL (it falls back to the user cache dir).
    std::string instance;
    std::string root = ArtRoot(&instance);
    if (instance.empty()) {
      RemoveStaleArtDirs(root);
      art_dir_ = root + "/" + std::to_string(getpid());
    } else {
      // The pid of a sandboxed app is nearly always 2 and other instances
      // are out of sight, so the directory is named by the instance and
      // nothing else is swept. The runtime dir is a tmpfs: what a crash
      // leaves goes at logout.
      art_dir_ = root + "/instance-" + instance;
    }
  }
  g_mkdir_with_parents(art_dir_.c_str(), 0700);

  std::string ext = "img";
  if (mime.find("png") != std::string::npos) {
    ext = "png";
  } else if (mime.find("jpeg") != std::string::npos ||
             mime.find("jpg") != std::string::npos) {
    ext = "jpg";
  } else if (mime.find("webp") != std::string::npos) {
    ext = "webp";
  }
  // Unique filename per track: desktops cache mpris:artUrl by URL, so reusing
  // a path can show stale art.
  std::string path = art_dir_ + "/art-" + std::to_string(++art_counter_) + "." +
                     ext;

  GError* err = nullptr;
  if (g_file_set_contents(path.c_str(),
                          reinterpret_cast<const char*>(data),
                          static_cast<gssize>(size), &err)) {
    if (!prev_art_path_.empty()) g_remove(prev_art_path_.c_str());
    prev_art_path_ = path;
    // Build a correct percent-encoded file:// URI rather than concatenating.
    gchar* uri = g_filename_to_uri(path.c_str(), nullptr, nullptr);
    art_url_ = uri ? uri : ("file://" + path);
    if (uri) g_free(uri);
    has_artwork_ = true;
    art_cache_key_.assign(data, data + size);
  } else if (err) {
    g_error_free(err);
  }
}

// The directory the covers go in. Inside a Flatpak sandbox the runtime dir is
// private to the sandbox, so the desktop shell, which reads mpris:artUrl from
// the host, would not find the file. Only $XDG_RUNTIME_DIR/app/$FLATPAK_ID is
// shared with the host, at the same path. There [instance] gets the Flatpak
// instance id; elsewhere it stays empty.
std::string MprisServer::ArtRoot(std::string* instance) {
  const std::string runtime = g_get_user_runtime_dir();
  const gchar* app_id = g_getenv("FLATPAK_ID");
  if (app_id != nullptr && *app_id != '\0') {
    GKeyFile* info = g_key_file_new();
    if (g_key_file_load_from_file(info, "/.flatpak-info", G_KEY_FILE_NONE,
                                  nullptr)) {
      gchar* id =
          g_key_file_get_string(info, "Instance", "instance-id", nullptr);
      if (id != nullptr && *id != '\0' && strchr(id, '/') == nullptr) {
        *instance = id;
      }
      g_free(id);
    }
    g_key_file_free(info);
    if (!instance->empty() && strchr(app_id, '/') == nullptr) {
      return runtime + "/app/" + app_id + "/mpv_audio_kit";
    }
    instance->clear();
  }
  return runtime + "/mpv_audio_kit";
}

// Deletes the artwork directories under [root] left by processes that are
// gone (a crash skips SweepArtwork). Directory names are PIDs.
void MprisServer::RemoveStaleArtDirs(const std::string& root) {
  GDir* dir = g_dir_open(root.c_str(), 0, nullptr);
  if (!dir) return;
  while (const gchar* name = g_dir_read_name(dir)) {
    char* end = nullptr;
    const long pid = strtol(name, &end, 10);
    if (*name == '\0' || *end != '\0' || pid <= 0) continue;
    if (pid == getpid() || kill(static_cast<pid_t>(pid), 0) == 0 ||
        errno == EPERM) {
      continue;  // this process, or one still alive
    }
    std::string path = root + "/" + name;
    if (GDir* stale = g_dir_open(path.c_str(), 0, nullptr)) {
      while (const gchar* file = g_dir_read_name(stale)) {
        g_remove((path + "/" + file).c_str());
      }
      g_dir_close(stale);
    }
    g_rmdir(path.c_str());
  }
  g_dir_close(dir);
}

void MprisServer::SweepArtwork() {
  if (!prev_art_path_.empty()) {
    g_remove(prev_art_path_.c_str());
    prev_art_path_.clear();
  }
  // The per-process directory goes too once empty; WriteArtwork recreates it.
  if (!art_dir_.empty()) g_rmdir(art_dir_.c_str());
  art_url_.clear();
  has_artwork_ = false;
  art_cache_key_.clear();
}

// ── Public state ops ────────────────────────────────────────────────────────

// Reads the config fields Enable and UpdateConfig share: actions, appName,
// desktopEntry and the rate bounds. An absent or empty rate list keeps the
// bounds in place.
void MprisServer::ParseConfig(FlValue* config) {
  actions_.clear();
  FlValue* acts = config ? fl_value_lookup_string(config, "actions") : nullptr;
  if (acts && fl_value_get_type(acts) == FL_VALUE_TYPE_LIST) {
    size_t n = fl_value_get_length(acts);
    for (size_t i = 0; i < n; i++) {
      FlValue* e = fl_value_get_list_value(acts, i);
      if (fl_value_get_type(e) == FL_VALUE_TYPE_STRING) {
        actions_.insert(fl_value_get_string(e));
      }
    }
  }
  app_name_ = FlString(config, "appName");
  desktop_entry_ = FlString(config, "desktopEntry");
  // supportedPlaybackRates → MinimumRate/MaximumRate. A Dart List<double>
  // arrives as a generic list (FL_VALUE_TYPE_LIST); a Float64List would arrive
  // as FL_VALUE_TYPE_FLOAT_LIST — handle both.
  FlValue* rates =
      config ? fl_value_lookup_string(config, "supportedPlaybackRates")
             : nullptr;
  // The type before the length: fl_value_get_length of a value that is no
  // list logs a GLib critical.
  const FlValueType rt =
      rates ? fl_value_get_type(rates) : FL_VALUE_TYPE_NULL;
  if (rt == FL_VALUE_TYPE_LIST || rt == FL_VALUE_TYPE_FLOAT_LIST) {
    size_t n = fl_value_get_length(rates);
    double mn = 0, mx = 0;
    bool first = true;
    for (size_t i = 0; i < n; i++) {
      double r;
      if (rt == FL_VALUE_TYPE_FLOAT_LIST) {
        r = fl_value_get_float_list(rates)[i];
      } else {
        FlValue* e = fl_value_get_list_value(rates, i);
        FlValueType et = fl_value_get_type(e);
        if (et == FL_VALUE_TYPE_FLOAT) {
          r = fl_value_get_float(e);
        } else if (et == FL_VALUE_TYPE_INT) {
          r = static_cast<double>(fl_value_get_int(e));
        } else {
          continue;
        }
      }
      if (first) {
        mn = mx = r;
        first = false;
      } else {
        if (r < mn) mn = r;
        if (r > mx) mx = r;
      }
    }
    if (!first) {
      min_rate_ = mn;
      max_rate_ = mx;
    }
  }
}

void MprisServer::Enable(FlValue* config, FlValue* metadata, FlValue* playback) {
  // A sub-value that is no map reads as absent: fl_value_lookup_string of
  // one logs a GLib critical.
  auto map_or_null = [](FlValue* v) {
    return v && fl_value_get_type(v) == FL_VALUE_TYPE_MAP ? v : nullptr;
  };
  config = map_or_null(config);
  metadata = map_or_null(metadata);
  playback = map_or_null(playback);
  ParseConfig(config);

  UpdateMetadata(metadata);  // parses metadata + writes artwork
  // playback (anchor without seek detection on enable)
  playing_ = FlBool(playback, "playing", false);
  actual_playing_ = FlBool(playback, "actualPlaying", false);
  // A stop shows as the end of content does: Stopped, empty Metadata.
  completed_ = FlBool(playback, "completed", false) ||
               FlBool(playback, "stopped", false);
  queued_ = FlBool(playback, "queued", false);
  int64_t pos = 0;
  if (FlInt(playback, "positionMs", &pos)) position_ms_ = pos;
  rate_ = FlDouble(playback, "rate", 1.0);
  seekable_ = FlBool(playback, "seekable", false);
  has_next_ = FlBool(playback, "hasNext", true);
  has_prev_ = FlBool(playback, "hasPrevious", true);
  loop_ = FlString(playback, "loop");
  if (loop_.empty()) loop_ = "off";
  shuffle_ = FlBool(playback, "shuffle", false);
  AnchorPosition();

  enabled_ = true;
  EnsureOwned();
  RepublishAll();
  ++publish_count_;
}

void MprisServer::UpdateConfig(FlValue* config) {
  const std::string old_app_name = app_name_;
  const std::string old_desktop_entry = desktop_entry_;
  const double old_min_rate = min_rate_;
  const double old_max_rate = max_rate_;
  ParseConfig(config);
  // The bus name is fixed at the first Enable: an appName change renames
  // Identity only.
  if (enabled_) {
    MarkChanged("CanGoNext");
    MarkChanged("CanGoPrevious");
    MarkChanged("CanPlay");
    MarkChanged("CanPause");
    MarkChanged("CanSeek");
    if (min_rate_ != old_min_rate) MarkChanged("MinimumRate");
    if (max_rate_ != old_max_rate) MarkChanged("MaximumRate");
    EmitRootChanged(app_name_ != old_app_name,
                    desktop_entry_ != old_desktop_entry);
  }
  ++publish_count_;
}

// Identity and DesktopEntry live on the root interface, which the batched
// FlushChanged does not cover, so their PropertiesChanged goes out here. An
// unset DesktopEntry reads as absent (its getter returns an error), so it is
// listed as invalidated rather than sent with a value.
void MprisServer::EmitRootChanged(bool identity, bool desktop_entry) {
  if (!connection_ || (!identity && !desktop_entry)) return;
  GVariantBuilder changed;
  g_variant_builder_init(&changed, G_VARIANT_TYPE("a{sv}"));
  GVariantBuilder invalidated;
  g_variant_builder_init(&invalidated, G_VARIANT_TYPE("as"));
  if (identity) {
    g_variant_builder_add(
        &changed, "{sv}", "Identity",
        g_variant_new_string(app_name_.empty() ? "mpv_audio_kit"
                                               : app_name_.c_str()));
  }
  if (desktop_entry) {
    if (desktop_entry_.empty()) {
      g_variant_builder_add(&invalidated, "s", "DesktopEntry");
    } else {
      g_variant_builder_add(&changed, "{sv}", "DesktopEntry",
                            g_variant_new_string(desktop_entry_.c_str()));
    }
  }
  GVariant* params =
      g_variant_new("(s@a{sv}@as)", kRootIface, g_variant_builder_end(&changed),
                    g_variant_builder_end(&invalidated));
  g_dbus_connection_emit_signal(connection_, nullptr, kObjectPath,
                                "org.freedesktop.DBus.Properties",
                                "PropertiesChanged", params, nullptr);
}

void MprisServer::UpdateMetadata(FlValue* metadata) {
  std::string new_title = FlString(metadata, "title");
  bool new_has_title = !new_title.empty();
  bool title_presence_changed = new_has_title != has_title_;
  // A title change implies a new track → bump the trackid object path and
  // rebuild the cached object-path string.
  bool new_track = new_has_title && new_title != title_;
  if (new_track) {
    track_no_++;
    track_id_ = "/org/mpris/MediaPlayer2/Track/" + std::to_string(track_no_);
    // Reset the extrapolation anchor so the Position getter doesn't briefly
    // over-run by extrapolating from the previous track's playhead before the
    // next UpdatePlayback lands.
    position_ms_ = 0;
    AnchorPosition();
  }
  title_ = new_title;
  has_title_ = new_has_title;
  artist_ = FlString(metadata, "artist");
  album_ = FlString(metadata, "album");
  album_artist_ = FlString(metadata, "albumArtist");
  genre_ = FlString(metadata, "genre");
  xesam_url_ = FlString(metadata, "url");
  int64_t tn = 0;
  xesam_track_ = FlInt(metadata, "trackNumber", &tn) ? tn : 0;
  int64_t dn = 0;
  xesam_disc_ = FlInt(metadata, "discNumber", &dn) ? dn : 0;

  int64_t dur = 0;
  if (FlInt(metadata, "durationMs", &dur)) {
    duration_ms_ = dur;
    has_duration_ = dur > 0;
  } else {
    has_duration_ = false;
  }

  // Every cover arrives as bytes (the package downloads a URL and reads a
  // file:// itself) and is written to a file of the runtime directory.
  FlValue* art =
      metadata ? fl_value_lookup_string(metadata, "artworkBytes") : nullptr;
  std::string mime = FlString(metadata, "artworkMime");
  if (art && fl_value_get_type(art) == FL_VALUE_TYPE_UINT8_LIST) {
    WriteArtwork(fl_value_get_uint8_list(art), fl_value_get_length(art), mime);
  } else {
    WriteArtwork(nullptr, 0, "");
  }

  if (enabled_) {
    MarkChanged("Metadata");
    // CanPlay/CanPause/CanSeek depend on has_title_ → re-advertise on a
    // content load/clear boundary.
    if (title_presence_changed) {
      MarkChanged("CanPlay");
      MarkChanged("CanPause");
      MarkChanged("CanSeek");
    }
  }
  ++publish_count_;
}

void MprisServer::UpdatePlayback(FlValue* playback) {
  int64_t new_pos_ms = 0;
  bool have_pos = FlInt(playback, "positionMs", &new_pos_ms);
  // The Dart side flags a snapshot that originates from a seek landing, so we
  // emit `Seeked` deterministically — no magnitude threshold that would miss a
  // sub-second scrub (which otherwise snaps the OS slider back).
  bool is_seek = FlBool(playback, "seek", false);

  const bool was_completed = completed_;
  const bool was_queued = queued_;
  const bool was_next = has_next_;
  const bool was_prev = has_prev_;
  const bool was_playing = playing_;
  const double was_rate = rate_;
  const bool was_seekable = seekable_;
  const std::string was_loop = loop_;
  const bool was_shuffle = shuffle_;
  playing_ = FlBool(playback, "playing", false);
  actual_playing_ = FlBool(playback, "actualPlaying", false);
  // A stop shows as the end of content does: Stopped, empty Metadata.
  completed_ = FlBool(playback, "completed", false) ||
               FlBool(playback, "stopped", false);
  queued_ = FlBool(playback, "queued", false);
  if (have_pos) position_ms_ = new_pos_ms;
  rate_ = FlDouble(playback, "rate", 1.0);
  seekable_ = FlBool(playback, "seekable", false);
  has_next_ = FlBool(playback, "hasNext", true);
  has_prev_ = FlBool(playback, "hasPrevious", true);
  loop_ = FlString(playback, "loop");
  if (loop_.empty()) loop_ = "off";
  shuffle_ = FlBool(playback, "shuffle", false);
  AnchorPosition();

  if (enabled_) {
    // Only what changed: most pushes carry a new position and nothing
    // else, and Position is not a property MPRIS signals.
    if (playing_ != was_playing || completed_ != was_completed) {
      MarkChanged("PlaybackStatus");
    }
    if (rate_ != was_rate) MarkChanged("Rate");
    if (loop_ != was_loop) MarkChanged("LoopStatus");
    if (shuffle_ != was_shuffle) MarkChanged("Shuffle");
    if (seekable_ != was_seekable) MarkChanged("CanSeek");
    if (has_next_ != was_next) MarkChanged("CanGoNext");
    if (has_prev_ != was_prev) MarkChanged("CanGoPrevious");
    // A completed transition flips Metadata visibility (full ↔ empty),
    // and CanPlay with it when there is no title.
    if (completed_ != was_completed) MarkChanged("Metadata");
    if (completed_ != was_completed || queued_ != was_queued) {
      MarkChanged("CanPlay");
    }
    if (is_seek && have_pos && connection_) {
      g_dbus_connection_emit_signal(connection_, nullptr, kObjectPath,
                                    kPlayerIface, "Seeked",
                                    g_variant_new("(x)", position_ms_ * 1000),
                                    nullptr);
    }
  }
  ++publish_count_;
}

void MprisServer::Disable() {
  enabled_ = false;
  ReleaseBus();  // drop off the session bus → the entry disappears.
  SweepArtwork();
  if (flush_source_id_) {
    g_source_remove(flush_source_id_);
    flush_source_id_ = 0;
  }
  if (changed_props_) g_hash_table_remove_all(changed_props_);

  actions_.clear();
  app_name_.clear();
  desktop_entry_.clear();
  title_.clear();
  artist_.clear();
  album_.clear();
  album_artist_.clear();
  genre_.clear();
  xesam_url_.clear();
  xesam_track_ = 0;
  xesam_disc_ = 0;
  has_title_ = false;
  duration_ms_ = 0;
  has_duration_ = false;
  playing_ = false;
  actual_playing_ = false;
  completed_ = false;
  queued_ = false;
  position_ms_ = 0;
  rate_ = 1.0;
  seekable_ = false;
  loop_ = "off";
  shuffle_ = false;
  // Reset the rate bounds so a later Enable() without supportedPlaybackRates
  // doesn't advertise stale bounds from the previous session.
  min_rate_ = 0.5;
  max_rate_ = 2.0;
  ++publish_count_;
}

FlValue* MprisServer::DebugState() {
  FlValue* m = fl_value_new_map();
  fl_value_set_string_take(m, "publishCount", fl_value_new_int(publish_count_));
  const char* state =
      !enabled_ ? "stopped"
                : (completed_ ? "completed" : (playing_ ? "playing" : "paused"));
  fl_value_set_string_take(m, "playbackState", fl_value_new_string(state));

  // Metadata is cleared on the OS surface at end-of-content; mirror that here.
  bool active = enabled_ && has_title_ && !completed_;
  fl_value_set_string_take(
      m, "title",
      active ? fl_value_new_string(title_.c_str()) : fl_value_new_null());
  fl_value_set_string_take(m, "artist",
                           (active && !artist_.empty())
                               ? fl_value_new_string(artist_.c_str())
                               : fl_value_new_null());
  fl_value_set_string_take(m, "album",
                           (active && !album_.empty())
                               ? fl_value_new_string(album_.c_str())
                               : fl_value_new_null());
  fl_value_set_string_take(
      m, "durationMs",
      has_duration_ ? fl_value_new_int(duration_ms_) : fl_value_new_null());
  fl_value_set_string_take(m, "positionMs", fl_value_new_int(position_ms_));
  fl_value_set_string_take(m, "rate", fl_value_new_float(rate_));
  fl_value_set_string_take(m, "hasArtwork", fl_value_new_bool(has_artwork_));
  fl_value_set_string_take(m, "seekable", fl_value_new_bool(seekable_));
  fl_value_set_string_take(m, "loop", fl_value_new_string(loop_.c_str()));
  fl_value_set_string_take(m, "shuffle", fl_value_new_bool(shuffle_));
  return m;
}

}  // namespace mpv_audio_kit
