// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#ifndef MPV_AUDIO_KIT_MPRIS_SERVER_H_
#define MPV_AUDIO_KIT_MPRIS_SERVER_H_

#include <flutter_linux/flutter_linux.h>
#include <gio/gio.h>

#include <cstdint>
#include <set>
#include <string>
#include <vector>

namespace mpv_audio_kit {

// Native MPRIS2 server over D-Bus (GLib/GDBus). Renders the Dart-side
// media-session state to org.mpris.MediaPlayer2[.Player] and forwards incoming
// OS commands to Dart via the event channel.
//
// Constructed on the Flutter platform thread (during plugin registration); all
// GDBus callbacks are delivered on that thread's GMainContext — the same loop
// as the Flutter channels — so there is no extra thread/loop and no locking.
// Takes ownership of one ref on the supplied FlEventChannel.
class MprisServer {
 public:
  explicit MprisServer(FlEventChannel* event_channel);
  ~MprisServer();

  MprisServer(const MprisServer&) = delete;
  MprisServer& operator=(const MprisServer&) = delete;

  void Enable(FlValue* config, FlValue* metadata, FlValue* playback);
  void UpdateConfig(FlValue* config);
  void UpdateMetadata(FlValue* metadata);
  void UpdatePlayback(FlValue* playback);
  void Disable();

  // Real published state, for the integration-test probe. Returns a new
  // FlValue (transfer full).
  FlValue* DebugState();

  // ── GDBus trampolines (user_data == this) ──────────────────────────────
  static void OnBusAcquired(GDBusConnection* connection, const gchar* name,
                            gpointer user_data);
  static void OnNameLost(GDBusConnection* connection, const gchar* name,
                         gpointer user_data);
  static void RootMethodCall(GDBusConnection*, const gchar*, const gchar*,
                             const gchar*, const gchar* method, GVariant*,
                             GDBusMethodInvocation* invocation, gpointer user_data);
  static GVariant* RootGetProperty(GDBusConnection*, const gchar*, const gchar*,
                                   const gchar*, const gchar* property,
                                   GError**, gpointer user_data);
  static void PlayerMethodCall(GDBusConnection*, const gchar*, const gchar*,
                               const gchar*, const gchar* method,
                               GVariant* params,
                               GDBusMethodInvocation* invocation,
                               gpointer user_data);
  static GVariant* PlayerGetProperty(GDBusConnection*, const gchar*, const gchar*,
                                     const gchar*, const gchar* property,
                                     GError**, gpointer user_data);
  static gboolean PlayerSetProperty(GDBusConnection*, const gchar*, const gchar*,
                                    const gchar*, const gchar* property,
                                    GVariant* value, GError**, gpointer user_data);
  static gboolean FlushChangedCb(gpointer user_data);

 private:
  void EnsureOwned();
  void ReleaseBus();
  void MarkChanged(const char* prop);
  void FlushChanged();
  void RepublishAll();
  GVariant* PlayerPropertyValue(const char* property);
  GVariant* BuildMetadata();
  void Emit(const gchar* type);
  void EmitWith(FlValue* command);  // takes ownership of command
  void WriteArtwork(const std::vector<uint8_t>& bytes, const std::string& mime);
  void SetExternalArtwork(const std::string& url);
  void SweepArtwork();
  static void RemoveStaleArtDirs(const std::string& root);
  int64_t ExtrapolatedPositionUs() const;
  void AnchorPosition();

  FlEventChannel* event_channel_;  // owned (one ref)

  guint owner_id_ = 0;
  GDBusConnection* connection_ = nullptr;  // borrowed (from OnBusAcquired)
  GDBusNodeInfo* node_info_ = nullptr;
  guint root_reg_id_ = 0;
  guint player_reg_id_ = 0;

  GHashTable* changed_props_ = nullptr;  // set<char*> of dirty property names
  guint flush_source_id_ = 0;
  int64_t publish_count_ = 0;

  // ── Cached state ────────────────────────────────────────────────────────
  bool enabled_ = false;

  // config
  std::set<std::string> actions_;
  std::string app_name_;
  std::string desktop_entry_;  // installed .desktop basename (MPRIS icon)

  // metadata
  std::string title_;
  std::string artist_;
  std::string album_;
  bool has_title_ = false;
  int64_t duration_ms_ = 0;
  bool has_duration_ = false;
  std::string art_url_;
  bool has_artwork_ = false;
  int64_t track_no_ = 0;  // monotonic trackid counter (mpris:trackid path)
  // Rich xesam:* tags (0 / empty = absent).
  int64_t xesam_track_ = 0;
  int64_t xesam_disc_ = 0;
  std::string album_artist_;
  std::string genre_;
  std::string xesam_url_;
  std::string track_id_ =  // cached mpris:trackid object path (rebuilt on track change)
      "/org/mpris/MediaPlayer2/Track/0";

  // playback
  bool playing_ = false;        // intent axis (drives PlaybackStatus Playing/Paused)
  bool actual_playing_ = false; // actual output — gates position extrapolation
  bool completed_ = false;      // eof-reached → PlaybackStatus=Stopped, empty Metadata
  int64_t position_ms_ = 0;
  double rate_ = 1.0;
  bool seekable_ = false;
  bool has_next_ = true;      // real playlist navigability (CanGoNext)
  bool has_prev_ = true;
  std::string loop_ = "off";
  bool shuffle_ = false;
  double volume_ = 1.0;
  double min_rate_ = 0.5;
  double max_rate_ = 2.0;

  // position extrapolation
  int64_t base_position_ms_ = 0;
  gint64 base_monotonic_us_ = 0;

  // artwork temp files
  std::string art_dir_;
  std::string prev_art_path_;
  std::vector<uint8_t> art_cache_key_;
  int64_t art_counter_ = 0;
};

}  // namespace mpv_audio_kit

#endif  // MPV_AUDIO_KIT_MPRIS_SERVER_H_
