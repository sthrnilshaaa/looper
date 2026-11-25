// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import '../player/player_state.dart';
import 'default_reactives.dart';

/// mpv's `duration` and `duration-estimated`, combined with the duration
/// hint of the playing entry into [PlaybackState.duration] and
/// [PlaybackState.durationEstimated].
///
/// The three change apart, in any order: the two properties arrive before
/// FILE_LOADED, the playlist with the new index with it or after it. The
/// specs of both properties and the player's playlist updates call
/// [apply], which sets both fields and both streams from what it holds.
@internal
final class DurationHint {
  DurationHint(this._r);

  final DefaultPropertyReactives _r;

  /// mpv's own duration, zero without one.
  Duration mpv = Duration.zero;

  /// Whether FFmpeg estimated [mpv] from the bitrate.
  bool estimated = false;

  /// The duration hint of the playing entry, if it has one.
  static Duration? entryHint(PlayerState s) {
    final playlist = s.playback.playlist;
    final i = playlist.index;
    if (i < 0 || i >= playlist.items.length) return null;
    return playlist.items[i].waveformDurationHint;
  }

  /// [mpv], or the entry's hint over one FFmpeg [estimated] from the
  /// bitrate: such an estimate can be far off, the hint is the length the
  /// app knows. An exact duration always wins.
  Duration duration(PlayerState s) {
    if (!estimated || mpv <= Duration.zero) return mpv;
    return entryHint(s) ?? mpv;
  }

  /// Whether [duration] is FFmpeg's estimate, with no hint over it.
  bool isEstimate(PlayerState s) =>
      estimated && mpv > Duration.zero && entryHint(s) == null;

  /// [s] with both fields from what this holds, and both streams.
  PlayerState apply(PlayerState s) {
    final d = duration(s);
    final e = isEstimate(s);
    _r.duration.update(d);
    _r.durationEstimated.update(e);
    if (s.playback.duration == d && s.playback.durationEstimated == e) {
      return s;
    }
    return s.copyWith(duration: d, durationEstimated: e);
  }
}
