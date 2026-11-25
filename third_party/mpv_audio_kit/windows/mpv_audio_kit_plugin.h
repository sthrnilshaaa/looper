// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#ifndef FLUTTER_PLUGIN_MPV_AUDIO_KIT_PLUGIN_H_
#define FLUTTER_PLUGIN_MPV_AUDIO_KIT_PLUGIN_H_

#include <flutter/plugin_registrar_windows.h>

namespace mpv_audio_kit {

// The entry point of the plugin: it registers the media session channels
// of an engine (MediaSessionChannelWin), the one thing the plugin does
// natively on Windows.
class MpvAudioKitPlugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);
};

}  // namespace mpv_audio_kit

#endif  // FLUTTER_PLUGIN_MPV_AUDIO_KIT_PLUGIN_H_
