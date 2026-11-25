// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../enums/cache.dart';

/// Aggregate of mpv's six cache properties (`cache`, `cache-secs`,
/// `cache-on-disk`, `cache-pause`, `cache-pause-wait`, `cache-pause-initial`).
///
/// Apply atomically via [Player.setCache]. For one-off tweaks use
/// `state.settings.cache.copyWith(...)`. Read the current configuration via
/// [PlayerSettings.cache] or observe live changes via [PlayerStream.cache].
///
/// {@category Network and cache}
final class CacheSettings {
  /// Caching policy. Default mirrors mpv's `--cache=auto`.
  final Cache mode;

  /// Target cache duration ahead of the playhead. Matches mpv's
  /// `--cache-secs` default (~1000 h, effectively unbounded by time):
  /// actual memory is bounded by [DemuxerSettings.maxBytes] (150 MiB by
  /// default), which is what governs in practice.
  final Duration secs;

  /// Whether to spill cache to disk instead of holding it in memory.
  ///
  /// Not a persistent cache: mpv creates a new file with a random name in
  /// [PlayerConfiguration.demuxerCacheDir] each time it opens a source, and
  /// never reads an earlier one. By default it deletes the file as soon as
  /// it creates it. A source played again is downloaded again. To keep a
  /// file for offline listening, download it in Dart and open the local
  /// file.
  final bool onDisk;

  /// Whether playback pauses when the cache runs empty (network stall).
  final bool pause;

  /// Pre-buffer required before resuming after a [pause] stall. Default
  /// 1 second mirrors mpv's `--cache-pause-wait=1.0`.
  final Duration pauseWait;

  /// Whether to enter the buffering and paused state before playback starts
  /// (and again after every seek restart) until the cache fills. The fix
  /// for choppy start-up on network sources (web-radio, HLS or Plex).
  /// Default `false`, matching mpv's `--cache-pause-initial=no`; only takes
  /// effect when [pause] is enabled.
  final bool pauseInitial;

  /// Creates a cache configuration. Each default mirrors the corresponding
  /// mpv property default.
  const CacheSettings({
    this.mode = Cache.auto,
    this.secs = const Duration(hours: 1000),
    this.onDisk = false,
    this.pause = true,
    this.pauseWait = const Duration(seconds: 1),
    this.pauseInitial = false,
  });

  /// Returns a copy with the given fields replaced. Omitted fields keep
  /// their current value.
  CacheSettings copyWith({
    Cache? mode,
    Duration? secs,
    bool? onDisk,
    bool? pause,
    Duration? pauseWait,
    bool? pauseInitial,
  }) => CacheSettings(
    mode: mode ?? this.mode,
    secs: secs ?? this.secs,
    onDisk: onDisk ?? this.onDisk,
    pause: pause ?? this.pause,
    pauseWait: pauseWait ?? this.pauseWait,
    pauseInitial: pauseInitial ?? this.pauseInitial,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheSettings &&
          other.mode == mode &&
          other.secs == secs &&
          other.onDisk == onDisk &&
          other.pause == pause &&
          other.pauseWait == pauseWait &&
          other.pauseInitial == pauseInitial);

  @override
  int get hashCode =>
      Object.hash(mode, secs, onDisk, pause, pauseWait, pauseInitial);

  @override
  String toString() =>
      'CacheSettings(mode: $mode, secs: $secs, onDisk: $onDisk, '
      'pause: $pause, pauseWait: $pauseWait, pauseInitial: $pauseInitial)';
}
