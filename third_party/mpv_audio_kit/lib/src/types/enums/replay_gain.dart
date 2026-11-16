// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// ReplayGain normalization mode, mirroring `--replaygain=<no|track|album>`.
enum ReplayGain {
  /// Disabled — no normalization.
  no('no'),

  /// Per-track ReplayGain.
  track('track'),

  /// Per-album ReplayGain. Useful for cohesive albums where inter-track
  /// dynamics matter.
  album('album');

  const ReplayGain(this.mpvValue);

  /// The wire-level string mpv expects.
  final String mpvValue;

  /// Maps a raw mpv-side value back to the enum. Unknown → [no].
  static ReplayGain fromMpv(String raw) => switch (raw) {
        'no' => no,
        'track' => track,
        'album' => album,
        _ => no,
      };
}
