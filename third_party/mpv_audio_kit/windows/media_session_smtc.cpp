// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#include "media_session_smtc.h"

#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Storage.Streams.h>

#include <fstream>
#include <chrono>
#include <future>

#include <shlwapi.h>
#pragma comment(lib, "shlwapi.lib")

namespace mpv_audio_kit {

namespace {

namespace wm = winrt::Windows::Media;
namespace wmp = winrt::Windows::Media::Playback;
namespace wss = winrt::Windows::Storage::Streams;
using winrt::Windows::Foundation::TimeSpan;

TimeSpan Ms(int64_t ms) { return std::chrono::milliseconds(ms); }

int64_t ToMs(TimeSpan span) {
  return std::chrono::duration_cast<std::chrono::milliseconds>(span).count();
}

wm::MediaPlaybackAutoRepeatMode LoopToRepeat(const std::string& loop) {
  if (loop == "file") return wm::MediaPlaybackAutoRepeatMode::Track;
  if (loop == "playlist") return wm::MediaPlaybackAutoRepeatMode::List;
  return wm::MediaPlaybackAutoRepeatMode::None;
}

std::string RepeatToLoop(wm::MediaPlaybackAutoRepeatMode mode) {
  switch (mode) {
    case wm::MediaPlaybackAutoRepeatMode::Track:
      return "file";
    case wm::MediaPlaybackAutoRepeatMode::List:
      return "playlist";
    default:
      return "off";
  }
}

// Builds an in-memory thumbnail stream reference from raw encoded image bytes.
// C++/WinRT's blocking `.get()` is only safe on an MTA thread, but the Flutter
// platform thread (where the channel handlers run) is STA — calling `.get()`
// there can assert/deadlock. So the async store/flush run on a dedicated MTA
// thread; the platform thread blocks on a std::future (a plain C++ wait, not a
// COM wait). The returned reference is agile, so it crosses back safely.
// Returns the RandomAccessStreamReference runtime class (not the bare
// IRandomAccessStreamReference interface): the SMTC DisplayUpdater's `Thumbnail`
// setter is projected as `Thumbnail(RandomAccessStreamReference const&)`, and
// the interface does not implicitly convert back up to the concrete class.
wss::RandomAccessStreamReference MakeThumbnail(const std::vector<uint8_t>& bytes) {
  return std::async(std::launch::async,
                    [bytes]() -> wss::RandomAccessStreamReference {
    // `.get()` is only safe on an MTA thread; this dedicated worker is MTA.
    // init_apartment can throw RPC_E_CHANGED_MODE on a pooled/reused thread —
    // swallow it (agile work is fine regardless). Do NOT uninit_apartment():
    // COM tears down on thread exit, and an explicit uninit here would destroy
    // the apartment while the returned reference's proxy is still live.
    try {
      winrt::init_apartment(winrt::apartment_type::multi_threaded);
    } catch (const winrt::hresult_error&) {
    }
    try {
      wss::InMemoryRandomAccessStream stream;
      wss::DataWriter writer{stream};
      writer.WriteBytes(winrt::array_view<uint8_t const>(
          bytes.data(), bytes.data() + bytes.size()));
      writer.StoreAsync().get();  // commits the buffer to the in-memory stream
      writer.DetachStream();
      stream.Seek(0);
      return wss::RandomAccessStreamReference::CreateFromStream(stream);
    } catch (const winrt::hresult_error&) {
      // Undecodable / bad blob → no thumbnail rather than a crashed thread.
      return wss::RandomAccessStreamReference{nullptr};
    }
  }).get();
}

// Builds an in-memory thumbnail stream reference by reading a local file.
// Uses PathCreateFromUrlW to resolve a `file://` URI to a Win32 path, then
// reads the bytes and forwards them to MakeThumbnail — same MTA-safe pattern.
wss::RandomAccessStreamReference MakeThumbnailFromFile(
    const std::wstring& path) {
  return std::async(std::launch::async,
                    [path]() -> wss::RandomAccessStreamReference {
    try {
      winrt::init_apartment(winrt::apartment_type::multi_threaded);
    } catch (const winrt::hresult_error&) {
    }
    try {
      std::ifstream file(path, std::ios::binary | std::ios::ate);
      if (!file.is_open())
        return wss::RandomAccessStreamReference{nullptr};
      const auto size = file.tellg();
      if (size <= 0)
        return wss::RandomAccessStreamReference{nullptr};
      file.seekg(0);
      std::vector<uint8_t> bytes(static_cast<size_t>(size));
      file.read(reinterpret_cast<char*>(bytes.data()), size);
      if (!file)
        return wss::RandomAccessStreamReference{nullptr};

      wss::InMemoryRandomAccessStream stream;
      wss::DataWriter writer{stream};
      writer.WriteBytes(winrt::array_view<uint8_t const>(
          bytes.data(), bytes.data() + bytes.size()));
      writer.StoreAsync().get();
      writer.DetachStream();
      stream.Seek(0);
      return wss::RandomAccessStreamReference::CreateFromStream(stream);
    } catch (...) {
      return wss::RandomAccessStreamReference{nullptr};
    }
  }).get();
}

flutter::EncodableValue Str(const std::optional<std::string>& v) {
  return v.has_value() ? flutter::EncodableValue(*v) : flutter::EncodableValue();
}

}  // namespace

SmtcController::SmtcController(
    std::function<void(flutter::EncodableValue)> command_sink)
    : command_sink_(std::move(command_sink)) {}

SmtcController::~SmtcController() {
  // Stop in-flight OS handlers from dereferencing command_sink_ before we revoke
  // their tokens (revoke does not join a handler already running on a pool thread).
  alive_.store(false);
  if (created_) {
    smtc_.ButtonPressed(button_token_);
    smtc_.PlaybackPositionChangeRequested(position_token_);
    smtc_.AutoRepeatModeChangeRequested(repeat_token_);
    smtc_.ShuffleEnabledChangeRequested(shuffle_token_);
    smtc_.PlaybackRateChangeRequested(rate_token_);
  }
}

void SmtcController::EnsureCreated() {
  if (created_) return;

  // Guard the SMTC acquisition: if MediaPlayer / SMTC init throws (missing
  // Media Foundation, unpackaged-app limits, apartment issues) stay disabled
  // instead of letting the exception escape the channel handler and crash the
  // Flutter engine.
  try {
    // Host MediaPlayer purely to obtain a process-wide SMTC without an HWND.
    player_ = wmp::MediaPlayer();
#pragma warning(push)
#pragma warning(disable : 4996)
    // SystemMediaTransportControls() is marked deprecated on some Windows SDKs;
    // the MediaPlayer shim is the supported HWND-less path for a desktop app,
    // so the deprecation is suppressed locally rather than promoted by /WX.
    smtc_ = player_.SystemMediaTransportControls();
#pragma warning(pop)
    // Disable the automatic MediaPlayer↔SMTC integration; we drive it manually.
    player_.CommandManager().IsEnabled(false);
  } catch (const winrt::hresult_error&) {
    return;  // created_ stays false → the controller is a safe no-op.
  }

  button_token_ = smtc_.ButtonPressed(
      [this](wm::SystemMediaTransportControls const&,
             wm::SystemMediaTransportControlsButtonPressedEventArgs const& args) {
        OnButton(args.Button());
      });

  position_token_ = smtc_.PlaybackPositionChangeRequested(
      [this](wm::SystemMediaTransportControls const&,
             wm::PlaybackPositionChangeRequestedEventArgs const& args) {
        if (!alive_.load()) return;
        command_sink_(flutter::EncodableValue(flutter::EncodableMap{
            {flutter::EncodableValue("type"), flutter::EncodableValue("seekTo")},
            {flutter::EncodableValue("positionMs"),
             flutter::EncodableValue(ToMs(args.RequestedPlaybackPosition()))},
        }));
      });

  repeat_token_ = smtc_.AutoRepeatModeChangeRequested(
      [this](wm::SystemMediaTransportControls const&,
             wm::AutoRepeatModeChangeRequestedEventArgs const& args) {
        if (!alive_.load()) return;
        command_sink_(flutter::EncodableValue(flutter::EncodableMap{
            {flutter::EncodableValue("type"),
             flutter::EncodableValue("setRepeatMode")},
            {flutter::EncodableValue("loop"),
             flutter::EncodableValue(RepeatToLoop(args.RequestedAutoRepeatMode()))},
        }));
      });

  shuffle_token_ = smtc_.ShuffleEnabledChangeRequested(
      [this](wm::SystemMediaTransportControls const&,
             wm::ShuffleEnabledChangeRequestedEventArgs const& args) {
        if (!alive_.load()) return;
        command_sink_(flutter::EncodableValue(flutter::EncodableMap{
            {flutter::EncodableValue("type"), flutter::EncodableValue("setShuffle")},
            {flutter::EncodableValue("shuffle"),
             flutter::EncodableValue(args.RequestedShuffleEnabled())},
        }));
      });

  rate_token_ = smtc_.PlaybackRateChangeRequested(
      [this](wm::SystemMediaTransportControls const&,
             wm::PlaybackRateChangeRequestedEventArgs const& args) {
        if (!alive_.load()) return;
        command_sink_(flutter::EncodableValue(flutter::EncodableMap{
            {flutter::EncodableValue("type"),
             flutter::EncodableValue("setPlaybackRate")},
            {flutter::EncodableValue("rate"),
             flutter::EncodableValue(args.RequestedPlaybackRate())},
        }));
      });

  created_ = true;
}

void SmtcController::OnButton(wm::SystemMediaTransportControlsButton button) {
  if (!alive_.load()) return;
  using B = wm::SystemMediaTransportControlsButton;
  switch (button) {
    case B::Play:
      Emit("play");
      break;
    case B::Pause:
      Emit("pause");
      break;
    case B::Stop:
      Emit("stop");
      break;
    case B::Next:
      Emit("next");
      break;
    case B::Previous:
      Emit("previous");
      break;
    case B::FastForward:
      // Read the atomic interval (this fires on a WinRT pool thread; config_
      // is mutated on the platform thread).
      command_sink_(flutter::EncodableValue(flutter::EncodableMap{
          {flutter::EncodableValue("type"), flutter::EncodableValue("seekBy")},
          {flutter::EncodableValue("offsetMs"),
           flutter::EncodableValue(ff_ms_.load())},
      }));
      break;
    case B::Rewind:
      command_sink_(flutter::EncodableValue(flutter::EncodableMap{
          {flutter::EncodableValue("type"), flutter::EncodableValue("seekBy")},
          {flutter::EncodableValue("offsetMs"),
           flutter::EncodableValue(-rw_ms_.load())},
      }));
      break;
    default:
      break;
  }
}

void SmtcController::Emit(const std::string& type) {
  command_sink_(flutter::EncodableValue(flutter::EncodableMap{
      {flutter::EncodableValue("type"), flutter::EncodableValue(type)}}));
}

void SmtcController::ConfigureButtons() {
  const auto& a = config_.actions;
  auto has = [&](const char* k) { return a.find(k) != a.end(); };
  smtc_.IsPlayEnabled(has("play") || has("playPause"));
  smtc_.IsPauseEnabled(has("pause") || has("playPause"));
  smtc_.IsStopEnabled(has("stop"));
  // Gate skip buttons on real navigability so they grey out at playlist bounds.
  smtc_.IsNextEnabled(has("next") && playback_.has_next);
  smtc_.IsPreviousEnabled(has("previous") && playback_.has_previous);
  smtc_.IsFastForwardEnabled(has("fastForward"));
  smtc_.IsRewindEnabled(has("rewind"));
}

void SmtcController::PublishMetadata() {
  if (!enabled_) return;
  std::string title = metadata_.title.value_or("");
  // Tagless source (internet radio / untagged file): fall back to the app name
  // rather than skipping the publish. SMTC requires Type + Update() to
  // publish, even when only the app name is available as a title.
  if (title.empty()) title = config_.app_name;

  auto du = smtc_.DisplayUpdater();
  du.Type(wm::MediaPlaybackType::Music);
  auto mp = du.MusicProperties();
  mp.Title(winrt::to_hstring(title));
  mp.Artist(winrt::to_hstring(metadata_.artist.value_or("")));
  mp.AlbumTitle(winrt::to_hstring(metadata_.album.value_or("")));
  mp.AlbumArtist(winrt::to_hstring(metadata_.album_artist.value_or("")));
  if (metadata_.track_number.has_value() && *metadata_.track_number > 0) {
    mp.TrackNumber(static_cast<uint32_t>(*metadata_.track_number));
  }
  if (metadata_.genre.has_value() && !metadata_.genre->empty()) {
    mp.Genres().Append(winrt::to_hstring(*metadata_.genre));
  }

  if (!metadata_.artwork.empty()) {
    if (metadata_.artwork != artwork_cache_key_) {
      wss::RandomAccessStreamReference thumb = MakeThumbnail(metadata_.artwork);
      du.Thumbnail(thumb);
      artwork_cache_key_ = metadata_.artwork;
      artwork_uri_cache_key_.clear();
    }
  } else if (metadata_.artwork_uri.has_value() &&
             !metadata_.artwork_uri->empty()) {
    // A URL the OS fetches itself (e.g. a transcoded stream's cover, which
    // has no embedded bytes) — hand SMTC a stream reference built straight
    // from the URI rather than shipping a blob across the channel.
    if (*metadata_.artwork_uri != artwork_uri_cache_key_) {
      const std::string& uri_str = *metadata_.artwork_uri;
      const bool is_file_uri =
          uri_str.size() >= 7 &&
          uri_str.compare(0, 7, "file://") == 0;
      if (is_file_uri) {
        // `RandomAccessStreamReference::CreateFromUri` does not support
        // `file://` URIs — resolve to a Win32 path and read the bytes.
        std::wstring wide_uri =
            winrt::to_hstring(uri_str).c_str();
        wchar_t win_path[MAX_PATH] = {};
        DWORD path_len = MAX_PATH;
        if (SUCCEEDED(PathCreateFromUrlW(wide_uri.c_str(), win_path,
                                        &path_len, 0))) {
          du.Thumbnail(MakeThumbnailFromFile(win_path));
        } else {
          du.Thumbnail(wss::RandomAccessStreamReference{nullptr});
        }
      } else {
        try {
          winrt::Windows::Foundation::Uri uri{
              winrt::to_hstring(uri_str)};
          du.Thumbnail(wss::RandomAccessStreamReference::CreateFromUri(uri));
        } catch (const winrt::hresult_error&) {
          du.Thumbnail(wss::RandomAccessStreamReference{nullptr});
        }
      }
      artwork_uri_cache_key_ = uri_str;
      artwork_cache_key_.clear();
    }
  } else {
    // A bare `nullptr` is ambiguous for the projected property setter — pass an
    // explicitly typed empty reference to clear the thumbnail.
    du.Thumbnail(wss::RandomAccessStreamReference{nullptr});
    artwork_cache_key_.clear();
    artwork_uri_cache_key_.clear();
  }
  du.Update();  // commits the DisplayUpdater changes to the OS.
}

void SmtcController::PublishPlayback() {
  if (!enabled_) return;

  // Intent axis: the OS button binds to `playing`, stable across seeks.
  // While buffering, report `Changing` so the SMTC shows a transitional state
  // instead of a stale play/pause icon.
  smtc_.PlaybackStatus(playback_.buffering ? wm::MediaPlaybackStatus::Changing
                       : playback_.playing ? wm::MediaPlaybackStatus::Playing
                                           : wm::MediaPlaybackStatus::Paused);

  // Initialise these so the OS exposes the repeat / shuffle controls.
  smtc_.AutoRepeatMode(LoopToRepeat(playback_.loop));
  smtc_.ShuffleEnabled(playback_.shuffle);
  smtc_.PlaybackRate(playback_.rate <= 0.0 ? 1.0 : playback_.rate);

  // Re-apply skip enablement here too: ConfigureButtons runs only on
  // enable/config, but navigability changes arrive on playback (track advance).
  const auto& acts = config_.actions;
  smtc_.IsNextEnabled(acts.count("next") > 0 && playback_.has_next);
  smtc_.IsPreviousEnabled(acts.count("previous") > 0 && playback_.has_previous);

  const int64_t dur = metadata_.duration_ms.value_or(0);
  const bool can_scrub =
      config_.actions.find("seek") != config_.actions.end() &&
      playback_.seekable && dur > 0;

  wm::SystemMediaTransportControlsTimelineProperties tl;
  tl.StartTime(Ms(0));
  tl.MinSeekTime(Ms(0));
  tl.EndTime(Ms(dur > 0 ? dur : 0));
  // Scrubbing requires Min/MaxSeekTime; gate it on seekability + the action.
  tl.MaxSeekTime(can_scrub ? Ms(dur) : Ms(0));
  // Clamp Position into [0, duration]; a value outside [Min,Max]SeekTime can
  // make UpdateTimelineProperties reject the whole update.
  int64_t pos = playback_.position_ms;
  if (pos < 0) pos = 0;
  if (dur > 0 && pos > dur) pos = dur;
  tl.Position(Ms(pos));
  smtc_.UpdateTimelineProperties(tl);
}

void SmtcController::Enable(const SmtcConfig& config, const SmtcMetadata& metadata,
                            const SmtcPlayback& playback) {
  config_ = config;
  metadata_ = metadata;
  playback_ = playback;
  ff_ms_ = config.fast_forward_ms;
  rw_ms_ = config.rewind_ms;
  EnsureCreated();
  if (!created_) {  // SMTC unavailable — enable is a no-op.
    ++publish_count_;
    return;
  }
  enabled_ = true;
  smtc_.IsEnabled(true);
  ConfigureButtons();
  PublishMetadata();
  PublishPlayback();
  ++publish_count_;
}

void SmtcController::UpdateConfig(const SmtcConfig& config) {
  config_ = config;
  ff_ms_ = config.fast_forward_ms;
  rw_ms_ = config.rewind_ms;
  if (enabled_) {
    ConfigureButtons();
    // Re-publish playback so an actions change re-gates the scrubber.
    PublishPlayback();
  }
  ++publish_count_;
}

void SmtcController::UpdateMetadata(const SmtcMetadata& metadata) {
  metadata_ = metadata;
  if (enabled_) {
    PublishMetadata();
    // Duration lives in metadata → refresh the timeline too.
    PublishPlayback();
  }
  ++publish_count_;
}

void SmtcController::UpdatePlayback(const SmtcPlayback& playback) {
  playback_ = playback;
  if (enabled_) PublishPlayback();
  ++publish_count_;
}

void SmtcController::Disable() {
  enabled_ = false;
  if (created_) {
    smtc_.PlaybackStatus(wm::MediaPlaybackStatus::Stopped);
    auto du = smtc_.DisplayUpdater();
    du.ClearAll();
    du.Update();
    smtc_.IsEnabled(false);
    smtc_.IsPlayEnabled(false);
    smtc_.IsPauseEnabled(false);
    smtc_.IsStopEnabled(false);
    smtc_.IsNextEnabled(false);
    smtc_.IsPreviousEnabled(false);
    smtc_.IsFastForwardEnabled(false);
    smtc_.IsRewindEnabled(false);
  }
  config_ = SmtcConfig{};
  metadata_ = SmtcMetadata{};
  playback_ = SmtcPlayback{};
  artwork_cache_key_.clear();
  // Also the URI's: a re-enable with the same artwork URI would otherwise
  // match the stale key and never republish the cover ClearAll removed.
  artwork_uri_cache_key_.clear();
  ++publish_count_;
}

flutter::EncodableValue SmtcController::DebugState() const {
  const bool active = enabled_ && metadata_.title.has_value() &&
                      !metadata_.title->empty();
  const std::string state =
      !enabled_ ? "stopped" : (playback_.playing ? "playing" : "paused");

  flutter::EncodableMap m{
      {flutter::EncodableValue("publishCount"),
       flutter::EncodableValue(publish_count_)},
      {flutter::EncodableValue("playbackState"), flutter::EncodableValue(state)},
      {flutter::EncodableValue("title"),
       active ? Str(metadata_.title) : flutter::EncodableValue()},
      {flutter::EncodableValue("artist"),
       active ? Str(metadata_.artist) : flutter::EncodableValue()},
      {flutter::EncodableValue("album"),
       active ? Str(metadata_.album) : flutter::EncodableValue()},
      {flutter::EncodableValue("durationMs"),
       metadata_.duration_ms.has_value()
           ? flutter::EncodableValue(*metadata_.duration_ms)
           : flutter::EncodableValue()},
      {flutter::EncodableValue("positionMs"),
       flutter::EncodableValue(playback_.position_ms)},
      {flutter::EncodableValue("rate"), flutter::EncodableValue(playback_.rate)},
      {flutter::EncodableValue("hasArtwork"),
       flutter::EncodableValue(!metadata_.artwork.empty())},
      {flutter::EncodableValue("seekable"),
       flutter::EncodableValue(playback_.seekable)},
      {flutter::EncodableValue("loop"), flutter::EncodableValue(playback_.loop)},
      {flutter::EncodableValue("shuffle"),
       flutter::EncodableValue(playback_.shuffle)},
  };
  return flutter::EncodableValue(std::move(m));
}

}  // namespace mpv_audio_kit
