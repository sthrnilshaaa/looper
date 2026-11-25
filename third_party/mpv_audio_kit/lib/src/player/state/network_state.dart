// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../../internals/unset_sentinel.dart';
import '../../models/demuxer_cache_state.dart';

part '../../generated/network_state_data.dart';

/// Buffering, cache and read health of the current source: what mpv holds ahead
/// and how the transport is doing.
///
/// The [PlayerState.network] of a player: read it from `player.state.network`,
/// or follow one value through its stream in `player.stream`.
///
/// {@category State and streams}
final class NetworkState with _$NetworkState {
  /// Whether a file is opening, from start-file to file-loaded. A network
  /// stall during playback does not set it: see [pausedForCache].
  final bool buffering;

  /// Absolute position up to which the demuxer has buffered content.
  ///
  /// This is an absolute timestamp from the start of the track (equivalent
  /// to `demuxer-cache-time` in mpv), not a relative duration. For example,
  /// if the current position is 1:00 and 30 s are cached ahead, [buffer] is
  /// 1:30. Use this value directly as the buffered position in audio_service
  /// or any progress-bar UI without adding [PlaybackState.position].
  final Duration buffer;

  /// Cache fill as a percentage (0.0 to 100.0) of [CacheSettings.secs].
  ///
  /// With mpv's default `cache-secs` (1000 hours) this stays near 0 on any real
  /// stream. For a buffering indicator use [cacheBufferingState] (mpv's own 0
  /// to 100 while it waits for data), or [bufferDuration] (the headroom ahead
  /// of [PlaybackState.position]) against a target of your choice.
  final double bufferingPercentage;

  /// Buffered duration ahead of the playhead (`demuxer-cache-duration`).
  /// Complements [buffer] (which is `demuxer-cache-time`, an absolute
  /// timestamp): [bufferDuration] is the headroom.
  final Duration bufferDuration;

  /// Rich demuxer cache snapshot: buffered time ranges + network-cache flags
  /// (mpv's `demuxer-cache-state`). Empty for directly-seekable local files;
  /// populated when streaming. Render `seekableRanges` as the downloaded
  /// regions of a network seek bar. Read live via
  /// [PlayerStream.demuxerCacheState].
  final DemuxerCacheState demuxerCacheState;

  /// Whether playback is paused because the network cache ran empty.
  ///
  /// This is mpv's `paused-for-cache` property, the authoritative signal
  /// for network buffering stalls. When `true`, mpv is waiting for data
  /// and will auto-resume once [CacheSettings.pauseWait] seconds are buffered.
  final bool pausedForCache;

  /// Whether the current stream is being read via a network protocol.
  ///
  /// Mirrors mpv's `demuxer-via-network` property. Useful for deciding
  /// whether an error is likely network-related.
  final bool demuxerViaNetwork;

  /// Whether the demuxer thread is idle. `true` while the demuxer has
  /// no data to fetch (cache full or EOF); `false` while pulling.
  /// Combined with `pausedForCache` it disambiguates "starved network"
  /// from "fully cached, sitting idle".
  final bool demuxerIdle;

  /// Current demuxer cache download speed in bytes per second.
  /// `0.0` when no network reads are active. Mirrors mpv's
  /// `cache-speed`.
  final double cacheSpeed;

  /// Cache fill state as a percentage (0 to 100). Distinct from
  /// [bufferingPercentage] (which is computed against `cache.secs`):
  /// this is mpv's own assessment of how much of the configured cache
  /// is full. Mirrors mpv's `cache-buffering-state`. `0` when no
  /// caching is active.
  final int cacheBufferingState;

  /// Whether the entry that ended at the end of content
  /// ([PlaybackState.completed]) stopped reading on an error instead of at its
  /// end, as [MpvFileEndedEvent.readError] tells for an entry that ends with an
  /// event. `null` while [PlaybackState.completed] is `false`. It changes with
  /// [PlaybackState.completed]: read it when [PlayerStream.completed] turns
  /// `true`. A seek at the park tries the read again, and the next park tells
  /// how it ended then: [PlaybackState.completed] turns `false` and `true`
  /// again for it, also when the seek played on to the end at once.
  final bool? readError;

  /// The HLS or DASH segments the entry that ended at the end of content
  /// ([PlaybackState.completed]) lost to errors, as
  /// [MpvFileEndedEvent.skippedSegments] tells. `null` while
  /// [PlaybackState.completed] is `false`. It changes with
  /// [PlaybackState.completed].
  final int? skippedSegments;

  /// Creates a [NetworkState]; each value defaults to the one of a player that
  /// has loaded nothing.
  const NetworkState({
    this.buffering = false,
    this.buffer = Duration.zero,
    this.bufferingPercentage = 0.0,
    this.bufferDuration = Duration.zero,
    this.demuxerCacheState = DemuxerCacheState.empty,
    this.pausedForCache = false,
    this.demuxerViaNetwork = false,
    this.demuxerIdle = true,
    this.cacheSpeed = 0.0,
    this.cacheBufferingState = 0,
    this.readError,
    this.skippedSegments,
  });
}
