// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Looping behaviour for playback.
///
/// mpv splits looping across two properties (`loop-file` and
/// `loop-playlist`); this enum aggregates them into a single mutually-
/// exclusive choice, matching the way most player UIs expose the
/// concept (off / repeat-track / repeat-playlist).
///
/// Variant names follow mpv's vocabulary: `file` mirrors `loop-file`,
/// `playlist` mirrors `loop-playlist`.
enum Loop {
  /// No looping: `loop-file=no` and `loop-playlist=no`. Playback stops
  /// after the last track of the playlist.
  off,

  /// Loop the currently playing file: `loop-file=inf`,
  /// `loop-playlist=no`.
  file,

  /// Loop the entire playlist: `loop-file=no`, `loop-playlist=inf`.
  playlist,
}
