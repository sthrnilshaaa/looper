// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'mpv_value.dart';

/// Gapless playback mode, mirroring `--gapless-audio=<no|yes|weak>`.
enum Gapless {
  /// Disabled: close and re-open the audio output between tracks.
  no('no'),

  /// Keeps the audio output open across tracks, in the format chosen for
  /// the first file. Later files are resampled and converted to that
  /// format, so a low sample rate on the first file lowers the rest.
  yes('yes'),

  /// Weak gapless (mpv default): no underruns, but allows minor format
  /// switches. Recommended for mixed-format playlists.
  weak('weak');

  const Gapless(this.mpvValue);

  /// The wire-level string mpv expects.
  final String mpvValue;

  /// Maps a raw mpv-side value back to the enum. Unknown → [weak] (mpv default).
  static Gapless fromMpv(String raw) =>
      byMpvValue(values, raw, (v) => v.mpvValue) ?? weak;
}
