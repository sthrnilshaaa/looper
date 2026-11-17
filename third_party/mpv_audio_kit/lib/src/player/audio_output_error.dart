// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import '../events/mpv_player_error.dart';
import '../types/enums/log_level.dart';
import '../types/state/audio_output_state.dart';

/// Maps an [AudioOutputState] transition to an optional [MpvLogError] for
/// `Player.stream.error`. Only [AudioOutputState.failed] produces an error;
/// every other state returns `null` so subscribers see a typed signal
/// the moment the audio output stops producing samples.
@internal
MpvLogError? buildAudioOutputError(AudioOutputState state) {
  if (state == AudioOutputState.failed) {
    return const MpvLogError(
      prefix: 'mpv_audio_kit',
      level: LogLevel.error,
      text: 'Audio output failed to initialize — playback is silent',
    );
  }
  return null;
}
