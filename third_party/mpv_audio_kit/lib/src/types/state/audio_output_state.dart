// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Lifecycle of mpv's audio output, reported by the `audio-output-state`
/// mpv property.
enum AudioOutputState {
  /// No audio output is active. Reported when no file is loaded or the
  /// file has been unloaded.
  closed('closed'),

  /// AO initialization is in flight. Useful for "connecting…" UI on slow
  /// backends (PipeWire negotiation, Bluetooth device init).
  initializing('initializing'),

  /// AO opened successfully and is producing samples.
  active('active'),

  /// AO initialization failed. A typed [MpvLogError] is emitted on
  /// [PlayerStream.error] when this state arrives.
  failed('failed');

  const AudioOutputState(this.mpvValue);

  /// The wire-level string mpv expects.
  final String mpvValue;

  /// Maps a raw mpv-side value back to the enum. Unknown → [closed].
  static AudioOutputState fromMpv(String raw) => switch (raw) {
        'closed' => closed,
        'initializing' => initializing,
        'active' => active,
        'failed' => failed,
        _ => closed,
      };
}
