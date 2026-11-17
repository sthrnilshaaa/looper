// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// A contiguous time range currently held in the demuxer cache.
///
/// Used to render the already-buffered regions on a network seek bar.
final class CacheRange {
  /// Start of the cached range, relative to the file timeline.
  final Duration start;

  /// End of the cached range, relative to the file timeline.
  final Duration end;

  /// Creates a cache range spanning [start]–[end].
  const CacheRange(this.start, this.end);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheRange && other.start == start && other.end == end);

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'CacheRange($start–$end)';
}

/// Rich snapshot of mpv's `demuxer-cache-state` — the parts useful to an
/// audio UI streaming over the network. Complements the scalar
/// [PlayerState.bufferingPercentage] / [PlayerState.bufferDuration] with the
/// structured cache picture.
///
/// All fields are empty / `false` / `null` for directly-seekable local files
/// (mpv only populates the cache state for network / cached sources).
final class DemuxerCacheState {
  /// Time ranges currently buffered — render these as the "downloaded"
  /// regions of a network seek bar. Empty when nothing is cached.
  final List<CacheRange> seekableRanges;

  /// Actual input (download) rate in bytes per second, or `null` when not
  /// reading over the network. Distinct from [PlayerState.cacheSpeed] (the
  /// cache fill rate); this is the raw stream read rate.
  final double? rawInputRate;

  /// Whether the cache holds data up to the end of the stream — a seek to the
  /// end is instant and no further network reads are needed.
  final bool eofCached;

  /// Whether the cache holds data back to the beginning of the stream.
  final bool bofCached;

  /// Whether the demuxer is currently starved (read faster than the network
  /// delivers). Complements [PlayerState.pausedForCache].
  final bool underrun;

  /// Creates a cache-state snapshot; defaults model an inactive cache.
  const DemuxerCacheState({
    this.seekableRanges = const <CacheRange>[],
    this.rawInputRate,
    this.eofCached = false,
    this.bofCached = false,
    this.underrun = false,
  });

  /// The inactive cache state — no ranges, nothing cached.
  static const DemuxerCacheState empty = DemuxerCacheState();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DemuxerCacheState) return false;
    if (other.rawInputRate != rawInputRate ||
        other.eofCached != eofCached ||
        other.bofCached != bofCached ||
        other.underrun != underrun ||
        other.seekableRanges.length != seekableRanges.length) {
      return false;
    }
    for (var i = 0; i < seekableRanges.length; i++) {
      if (other.seekableRanges[i] != seekableRanges[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(seekableRanges),
        rawInputRate,
        eofCached,
        bofCached,
        underrun,
      );

  @override
  String toString() => 'DemuxerCacheState(ranges: ${seekableRanges.length}, '
      'rawInputRate: $rawInputRate, eofCached: $eofCached, '
      'bofCached: $bofCached, underrun: $underrun)';
}
