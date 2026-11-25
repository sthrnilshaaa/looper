// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
// This TU mixes windows.h with the C++/WinRT projection (via
// media_session_channel_win.h). Suppress the min/max macros so they don't
// clash with C++/WinRT's std::min/std::max.
#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif

#include "mpv_audio_kit_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/plugin_registrar_windows.h>

#include <memory>

#include "media_session_channel_win.h"

namespace mpv_audio_kit {

// Registers the plugin with the Windows registrar. libmpv is driven via FFI
// from Dart, and the `mpv_audio_kit` method channel (openFileDescriptor and
// closeFileDescriptor) is Android's alone: Dart calls it nowhere else, so it
// is not registered here.
void MpvAudioKitPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  // ── OS media session (SMTC via C++/WinRT) ───────────────────────────
  // MediaSessionChannelWin holds this engine's media-session channels and
  // goes with the registrar. The SystemMediaTransportControls controller
  // and the platform-thread command marshaling are one per process, in a
  // hub that is never destroyed (see media_session_channel_win.h).
  registrar->AddPlugin(std::make_unique<MediaSessionChannelWin>(registrar));
}

}  // namespace mpv_audio_kit
