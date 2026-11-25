// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import '../events/player_error.dart';
import '../types/enums/log_level.dart';
import '../types/state/audio_output_state.dart';

/// Maps an [AudioOutputState] transition to an optional [LogError] for
/// `Player.stream.error`. Only [AudioOutputState.failed] produces an error;
/// every other state returns `null` so subscribers see a typed signal
/// the moment the audio output stops producing samples.
@internal
LogError? buildAudioOutputError(AudioOutputState state) {
  if (state == AudioOutputState.failed) {
    return const LogError(
      prefix: 'mpv_audio_kit',
      level: LogLevel.error,
      text: 'Audio output failed to initialize: playback is silent',
    );
  }
  return null;
}

/// The [LogError] for an output that fell back to the null driver: no
/// device could be opened, and playback goes on without sound.
@internal
const LogError nullOutputError = LogError(
  prefix: 'mpv_audio_kit',
  level: LogLevel.error,
  text:
      'No audio device could be opened: playback goes on silently on the '
      'null output',
);

/// Whether the `ao` option [value] names the null driver: the app chose
/// it, alone or as a fallback of its own.
@internal
bool aoListHasNull(String value) => value
    .split(',')
    .map((d) => d.trim())
    .any((d) => d == 'null' || d.startsWith('null='));
