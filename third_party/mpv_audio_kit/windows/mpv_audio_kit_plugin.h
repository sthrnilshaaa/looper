// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#ifndef FLUTTER_PLUGIN_MPV_AUDIO_KIT_PLUGIN_H_
#define FLUTTER_PLUGIN_MPV_AUDIO_KIT_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace mpv_audio_kit {

class MpvAudioKitPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  MpvAudioKitPlugin();

  virtual ~MpvAudioKitPlugin();

  // Disallow copy and assign.
  MpvAudioKitPlugin(const MpvAudioKitPlugin&) = delete;
  MpvAudioKitPlugin& operator=(const MpvAudioKitPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace mpv_audio_kit

#endif  // FLUTTER_PLUGIN_MPV_AUDIO_KIT_PLUGIN_H_
