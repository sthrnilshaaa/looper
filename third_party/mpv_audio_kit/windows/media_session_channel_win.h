// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#ifndef MPV_AUDIO_KIT_MEDIA_SESSION_CHANNEL_WIN_H_
#define MPV_AUDIO_KIT_MEDIA_SESSION_CHANNEL_WIN_H_

// Keep windows.h from defining the min/max macros (they break C++/WinRT's
// std::min/std::max usage) and trim the header for faster, conflict-free
// compilation alongside the C++/WinRT projection headers.
#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>

#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>

#include "media_session_smtc.h"

namespace mpv_audio_kit {

// Bridges the two media-session Flutter channels of one engine to the
// process's SystemMediaTransportControls. The SMTC is one per process while
// the plugin runs once per engine: a MediaSessionHub (in the .cpp) holds the
// [SmtcController], the message-only window that marshals OS commands (which
// fire on WinRT pool threads) back onto the platform thread, and which engine
// owns the session (native_common/engine_ownership.h). Another engine's
// enable answers `already_owned`, its updates and disable are dropped, and
// the commands go to the owner's event sink.
//
// The hub is never destroyed, which keeps WinRT teardown out of process exit
// (e876881). A channel is a plugin of its registrar and goes with its engine:
// the owner's turns the session off on its way, so no command reaches a
// messenger that is gone.
class MediaSessionChannelWin : public flutter::Plugin {
 public:
  explicit MediaSessionChannelWin(flutter::PluginRegistrarWindows* registrar);
  ~MediaSessionChannelWin() override;

  MediaSessionChannelWin(const MediaSessionChannelWin&) = delete;
  MediaSessionChannelWin& operator=(const MediaSessionChannelWin&) = delete;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> method_channel_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> event_channel_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink_;
};

}  // namespace mpv_audio_kit

#endif  // MPV_AUDIO_KIT_MEDIA_SESSION_CHANNEL_WIN_H_
