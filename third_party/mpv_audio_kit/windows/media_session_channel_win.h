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

#include <atomic>
#include <memory>

#include "media_session_smtc.h"

namespace mpv_audio_kit {

// Bridges the two media-session Flutter channels to the C++/WinRT
// [SmtcController]. Owns both channels, the controller, and a message-only
// window used to marshal OS commands (which fire on WinRT pool threads) back
// onto the Flutter platform thread before touching the event sink.
//
// Constructed during plugin registration (on the platform thread) and kept
// alive for the plugin lifetime.
class MediaSessionChannelWin {
 public:
  explicit MediaSessionChannelWin(flutter::PluginRegistrarWindows* registrar);
  ~MediaSessionChannelWin();

  MediaSessionChannelWin(const MediaSessionChannelWin&) = delete;
  MediaSessionChannelWin& operator=(const MediaSessionChannelWin&) = delete;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Invoked on a WinRT pool thread by the controller; PostMessages the command
  // to the platform-thread window so the event sink is touched on the right thread.
  void ForwardCommand(flutter::EncodableValue command);

  static LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wparam,
                                  LPARAM lparam);

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> method_channel_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> event_channel_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink_;
  std::unique_ptr<SmtcController> controller_;
  // Read on WinRT pool threads (ForwardCommand) while the platform thread
  // creates/destroys it — atomic so teardown can publish nullptr with a
  // happens-before edge instead of racing an unsynchronised HWND read.
  std::atomic<HWND> message_window_{nullptr};
};

}  // namespace mpv_audio_kit

#endif  // MPV_AUDIO_KIT_MEDIA_SESSION_CHANNEL_WIN_H_
