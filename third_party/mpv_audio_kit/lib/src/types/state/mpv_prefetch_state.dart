// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

/// Lifecycle phase of mpv's background playlist-prefetch.
///
/// Emitted by [PlayerStream.prefetchState] whenever mpv transitions
/// between phases, so clients can show "Prefetching…" UI, verify that
/// gapless transitions are actually reusing the buffered stream, or log
/// warnings when a prefetch is aborted/dropped.
///
/// Backed by mpv's `prefetch-state` property, with the same lifecycle
/// across every demuxer backend — HLS, DASH, raw HTTP range reads,
/// SMB, local files.
enum MpvPrefetchState {
  /// No background prefetch is active. Default state.
  idle('idle'),

  /// `prefetch_next()` fired: the opener thread is creating the demuxer
  /// for the next playlist item, and once open, the secondary cache is
  /// filling in the background.
  loading('loading'),

  /// The secondary demuxer is open AND its reader reports idle (= mpv's
  /// `cache-secs` threshold has been hit and no further segment fetches
  /// are outstanding). Gapless transition is armed.
  ready('ready'),

  /// The prefetched stream was just consumed — the current track ended
  /// and mpv reused the secondary demuxer instead of re-opening. The
  /// state PERSISTS at [used] until the next [loading] (next
  /// `prefetch_next`) or a cancel resets it to [idle], so observers
  /// reading `state.prefetchState` after a track transition still see
  /// the success signal.
  used('used'),

  /// The opener thread failed to create a demuxer for the next playlist
  /// item — typically a network error (404 / timeout / DNS), an
  /// unsupported codec, or a deliberate abort by an `on_load` hook
  /// rewrite. Distinct from a silent return to [idle] because no
  /// gapless transition is armed: the next track will be re-opened
  /// from scratch when playback reaches it. Persists at [failed] until
  /// the next [loading] or a cancel resets it.
  failed('failed');

  const MpvPrefetchState(this.mpvValue);

  /// The wire-level string mpv emits for this phase.
  final String mpvValue;

  /// Parses the string emitted by mpv. Unknown values fall back to
  /// [idle] so future mpv additions don't crash clients — they just
  /// see the phase treated as "not actively prefetching".
  static MpvPrefetchState fromMpv(String value) {
    for (final v in MpvPrefetchState.values) {
      if (v.mpvValue == value) return v;
    }
    return MpvPrefetchState.idle;
  }
}
