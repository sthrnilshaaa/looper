// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#ifndef MPV_AUDIO_KIT_MEDIA_SESSION_SMTC_H_
#define MPV_AUDIO_KIT_MEDIA_SESSION_SMTC_H_

#include <flutter/encodable_value.h>

#include <winrt/Windows.Media.Playback.h>
#include <winrt/Windows.Media.h>

#include <atomic>
#include <cstdint>
#include <functional>
#include <optional>
#include <set>
#include <string>
#include <vector>

namespace mpv_audio_kit {

// Parsed `enable`/`updateConfig` config payload (everything that is not a
// resolved metadata field). `app_name` is Windows-specific (Dart sends it
// only on win/linux).
struct SmtcConfig {
  std::set<std::string> actions;
  std::string interruption_policy = "pauseAndResume";
  int64_t fast_forward_ms = 15000;
  int64_t rewind_ms = 15000;
  std::vector<double> supported_rates;
  std::string app_name;
};

// Parsed metadata payload — already resolved Dart-side (override > mpv).
struct SmtcMetadata {
  std::optional<std::string> title;
  std::optional<std::string> artist;
  std::optional<std::string> album;
  std::optional<std::string> album_artist;
  std::optional<std::string> genre;
  std::optional<int64_t> track_number;
  std::vector<uint8_t> artwork;          // empty => no embedded/custom bytes
  std::optional<std::string> artwork_uri;  // URL the OS fetches itself
  std::optional<int64_t> duration_ms;
};

// Parsed playback payload. `playing` is the INTENT axis (stable across seeks).
struct SmtcPlayback {
  bool playing = false;  // intent axis (drives the SMTC PlaybackStatus)
  bool buffering = false;
  int64_t position_ms = 0;
  double rate = 1.0;
  bool seekable = false;
  bool has_next = true;  // real playlist navigability (IsNextEnabled)
  bool has_previous = true;
  std::string loop = "off";
  bool shuffle = false;
};

// Owns the MediaPlayer-hosted SystemMediaTransportControls and renders the
// Dart-side media-session state to the OS. Stateless renderer: each Update*
// replaces the cached snapshot and re-publishes.
//
// The SMTC is obtained via the MediaPlayer shim (no HWND) with the automatic
// CommandManager disabled, so we drive it manually. SMTC objects are agile,
// so these methods are called directly on the Flutter platform thread.
// Inbound OS commands fire on WinRT thread-pool threads and are handed to the
// `command_sink` (supplied by the channel glue), which MUST marshal to the
// platform thread before touching the Flutter event channel.
class SmtcController {
 public:
  explicit SmtcController(
      std::function<void(flutter::EncodableValue)> command_sink);
  ~SmtcController();

  SmtcController(const SmtcController&) = delete;
  SmtcController& operator=(const SmtcController&) = delete;

  void Enable(const SmtcConfig& config, const SmtcMetadata& metadata,
              const SmtcPlayback& playback);
  void UpdateConfig(const SmtcConfig& config);
  void UpdateMetadata(const SmtcMetadata& metadata);
  void UpdatePlayback(const SmtcPlayback& playback);
  void Disable();

  // Real published state, for the integration-test probe.
  flutter::EncodableValue DebugState() const;

 private:
  void EnsureCreated();
  void ConfigureButtons();
  void PublishMetadata();
  void PublishPlayback();
  void Emit(const std::string& type);
  void OnButton(winrt::Windows::Media::SystemMediaTransportControlsButton button);

  std::function<void(flutter::EncodableValue)> command_sink_;

  winrt::Windows::Media::Playback::MediaPlayer player_{nullptr};
  winrt::Windows::Media::SystemMediaTransportControls smtc_{nullptr};

  winrt::event_token button_token_{};
  winrt::event_token position_token_{};
  winrt::event_token repeat_token_{};
  winrt::event_token shuffle_token_{};
  winrt::event_token rate_token_{};

  bool created_ = false;
  bool enabled_ = false;
  int64_t publish_count_ = 0;

  // Cleared at the top of the destructor. OS event handlers fire on WinRT pool
  // threads and capture `this`; revoking their tokens does not join an already-
  // running handler, so each handler checks this flag before touching
  // command_sink_ to avoid a use-after-free across teardown.
  std::atomic<bool> alive_{true};

  // Seek intervals are read on WinRT pool threads (button handlers) while the
  // platform thread mutates config_ — keep them as atomics to avoid a race.
  std::atomic<int64_t> ff_ms_{15000};
  std::atomic<int64_t> rw_ms_{15000};

  SmtcConfig config_{};
  SmtcMetadata metadata_{};
  SmtcPlayback playback_{};

  // Thumbnail cache keyed by byte identity — skip rebuilding when unchanged.
  std::vector<uint8_t> artwork_cache_key_{};
  // Thumbnail cache for the URL path — skip re-issuing CreateFromUri when the
  // URL is unchanged. Empty when the current art is byte- or none-sourced.
  std::string artwork_uri_cache_key_{};
};

}  // namespace mpv_audio_kit

#endif  // MPV_AUDIO_KIT_MEDIA_SESSION_SMTC_H_
