// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../enums/mpv_value.dart';

/// Lifecycle of mpv's audio output, reported by the `audio-output-state`
/// mpv property.
enum AudioOutputState {
  /// No audio output is open: before the first file plays, or after the
  /// output closed. After [failed] the state stays [failed] instead, until
  /// the next attempt to open an output.
  closed('closed'),

  /// The output is opening. The opening blocks mpv's core and the next
  /// state follows in the same step, so observers almost never see this
  /// one: do not build UI on it.
  initializing('initializing'),

  /// The output is open. When the device cannot be opened, mpv opens its
  /// null output instead and the state is [active] too, while nothing is
  /// heard: [PlayerStream.error] then gets a [LogError].
  active('active'),

  /// No output could be opened, not even the null one. With the player's
  /// defaults this needs mpv's `audio-fallback-to-null` turned off. A
  /// typed [LogError] is emitted on [PlayerStream.error] when this state
  /// arrives. It stays until the next attempt, and a second failure in a
  /// row is not emitted again: each file that cannot play still ends with
  /// an [EndFileError].
  failed('failed');

  const AudioOutputState(this.mpvValue);

  /// The wire-level string mpv expects.
  final String mpvValue;

  /// Maps a raw mpv-side value back to the enum. Unknown → [closed].
  static AudioOutputState fromMpv(String raw) =>
      byMpvValue(values, raw, (v) => v.mpvValue) ?? closed;
}
