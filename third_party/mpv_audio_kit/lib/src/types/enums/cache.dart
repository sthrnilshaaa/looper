// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Network cache mode, mirroring `--cache=<auto|yes|no>`.
enum Cache {
  /// Auto (mpv default): enabled for network sources, disabled for local files.
  auto('auto'),

  /// Always cache.
  yes('yes'),

  /// Never cache.
  no('no');

  const Cache(this.mpvValue);

  /// The wire-level string mpv expects.
  final String mpvValue;

  /// Maps a raw mpv-side value back to the enum. Unknown → [auto].
  static Cache fromMpv(String raw) => switch (raw) {
        'auto' => auto,
        'yes' => yes,
        'no' => no,
        _ => auto,
      };
}
