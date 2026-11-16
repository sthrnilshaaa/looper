// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Gapless playback mode, mirroring `--gapless-audio=<no|yes|weak>`.
enum Gapless {
  /// Disabled — close and re-open the audio output between tracks.
  no('no'),

  /// Strict gapless: re-uses the audio decoder across track boundaries.
  /// Requires identical format/sample-rate/channels between tracks.
  yes('yes'),

  /// Weak gapless (mpv default): no underruns, but allows minor format
  /// switches. Recommended for mixed-format playlists.
  weak('weak');

  const Gapless(this.mpvValue);

  /// The wire-level string mpv expects.
  final String mpvValue;

  /// Maps a raw mpv-side value back to the enum. Unknown → [weak] (mpv default).
  static Gapless fromMpv(String raw) => switch (raw) {
        'no' => no,
        'yes' => yes,
        'weak' => weak,
        _ => weak,
      };
}
