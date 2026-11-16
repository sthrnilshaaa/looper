// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// HLS variant-selection policy for adaptive streams — mpv's `--hls-bitrate`.
///
/// Chooses which audio rendition mpv picks from an HLS master playlist. The
/// per-variant bitrate *values* are read-side on `MpvTrack.hlsBitrate`; this
/// is the selection *policy*, set via `Player.setHlsBitrate` (its initial
/// value comes from `PlayerConfiguration.hlsBitrate`).
enum HlsBitrate {
  /// Disable HLS bitrate-based selection (mpv's `no`).
  no('no'),

  /// Prefer the lowest-bitrate variant — least bandwidth (mpv's `min`).
  min('min'),

  /// Prefer the highest-bitrate variant — best quality (mpv's `max`).
  /// mpv's default.
  max('max');

  const HlsBitrate(this.mpvValue);

  /// The wire-level token mpv expects for `--hls-bitrate`.
  final String mpvValue;

  /// Maps an mpv-side token back to the enum. Unknown values fall back to
  /// [max] (mpv's default), never throwing.
  static HlsBitrate fromMpv(String raw) => switch (raw) {
        'no' => no,
        'min' => min,
        'max' => max,
        _ => max,
      };
}
