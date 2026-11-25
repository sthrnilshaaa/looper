// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#ifndef FLUTTER_PLUGIN_MPV_AUDIO_KIT_PLUGIN_H_
#define FLUTTER_PLUGIN_MPV_AUDIO_KIT_PLUGIN_H_

#include <flutter_linux/flutter_linux.h>

G_BEGIN_DECLS

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __attribute__((visibility("default")))
#else
#define FLUTTER_PLUGIN_EXPORT
#endif

typedef struct _MpvAudioKitPlugin MpvAudioKitPlugin;
typedef struct {
  GObjectClass parent_class;
} MpvAudioKitPluginClass;

FLUTTER_PLUGIN_EXPORT GType mpv_audio_kit_plugin_get_type();

FLUTTER_PLUGIN_EXPORT void mpv_audio_kit_plugin_register_with_registrar(
    FlPluginRegistrar* registrar);

G_END_DECLS

#endif  // FLUTTER_PLUGIN_MPV_AUDIO_KIT_PLUGIN_H_
