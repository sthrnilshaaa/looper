// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'mpv_value.dart';

/// External cover-art auto-load behaviour, mirroring
/// `--cover-art-auto=<no|exact|fuzzy|all>`.
enum Cover {
  /// Disabled: no external cover-art loading. The library default
  /// (mpv's own default is [exact]).
  no('no'),

  /// Match a file whose base name equals the audio file's base name with
  /// an image extension, plus the names in `--cover-art-whitelist`.
  exact('exact'),

  /// Match any image whose name *contains* the audio file's base name,
  /// plus the names in `--cover-art-whitelist`.
  fuzzy('fuzzy'),

  /// Load every image file in the same directory as the audio file.
  all('all');

  const Cover(this.mpvValue);

  /// The wire-level string mpv expects.
  final String mpvValue;

  /// Maps a raw mpv-side value back to the enum. Unknown → [no].
  static Cover fromMpv(String raw) =>
      byMpvValue(values, raw, (v) => v.mpvValue) ?? no;
}
