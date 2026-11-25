// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../internals/duration_seconds.dart';
import '../internals/mpv_float.dart';
import '../models/audio_params.dart';
import '../models/chapter.dart';
import '../models/mpv_track.dart';
import '../player/player_state.dart';
import '../reactive/node_parsers.dart';
import '../types/enums/cache.dart';
import '../types/enums/cover.dart';
import '../types/enums/format.dart';
import '../types/enums/gapless.dart';
import '../types/enums/hls_bitrate.dart';
import '../types/enums/replay_gain.dart';
import '../types/enums/spdif.dart';
import '../types/sealed/channels.dart';
import '../types/settings/cache_settings.dart';
import '../types/settings/demuxer_settings.dart';
import '../types/settings/replay_gain_settings.dart';
import '../types/state/audio_output_state.dart';
import '../types/state/prefetch_state.dart';
import 'default_reactives.dart';
import 'duration_hint.dart';
import 'mpv_property_spec.dart';
import 'reactive_property.dart';

part 'spec_parsers.dart';
part 'specs_audio.dart';
part 'specs_file.dart';
part 'specs_gain.dart';
part 'specs_network.dart';
part 'specs_playback.dart';

/// Builds the default list of [MpvPropertySpec]s mapping mpv property names
/// to their [PlayerState] reducers.
///
/// The callbacks let the caller hook side effects to property changes
/// without leaking the player object into the spec list:
/// - [onIdleActive]: fires every time mpv toggles `idle-active`; used by the
///   player to clear its lifecycle (`playing=false, buffering=false`) when
///   mpv has nothing left to do.
/// - [onAudioOutputState]: fires on every transition of
///   `audio-output-state`; the player uses it to surface a typed
///   error when the AO fails to initialise.
List<MpvPropertySpec<Object?>> buildDefaultSpecs(
  DefaultPropertyReactives r, {
  required void Function(bool idle) onIdleActive,
  required void Function(AudioOutputState state) onAudioOutputState,
  DurationHint? durationHint,
}) {
  // mpv's duration and its flag, combined with the entry's hint; the
  // player applies it again when the playlist or its index changes.
  final hint = durationHint ?? DurationHint(r);
  return <MpvPropertySpec<Object?>>[
    ..._playbackSpecs(r, hint, onIdleActive),
    ..._audioParamsSpecs(r),
    ..._gainSpecs(r),
    ..._networkSpecs(r),
    ..._outputSpecs(r, onAudioOutputState),
    ..._playbackExtraSpecs(r),
    ..._fileSpecs(r),
  ];
}
