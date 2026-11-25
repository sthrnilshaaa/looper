// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

import '../enums/mpv_value.dart';

/// Lifecycle phase of mpv's background playlist-prefetch.
///
/// Emitted by [PlayerStream.prefetchState] whenever mpv transitions
/// between phases, so clients can show "Prefetching…" UI, verify that
/// gapless transitions are actually reusing the buffered stream, or log
/// warnings when a prefetch is aborted or dropped.
///
/// Backed by mpv's `prefetch-state` property, with the same lifecycle
/// across every demuxer backend: HLS, DASH, raw HTTP range reads,
/// SMB, local files.
///
/// [failed] comes as soon as the open fails, while the current entry
/// plays, and a stop resets the state to [idle].
enum PrefetchState {
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

  /// The prefetched stream was just consumed: the current track ended
  /// and mpv reused the secondary demuxer instead of re-opening. The
  /// state PERSISTS at [used] until the next [loading] (next
  /// `prefetch_next`) or a cancel resets it to [idle], so a subscriber
  /// that arrives after a track transition still sees the success signal.
  /// An entry the source resolver rewrote gets here too: it opens with
  /// the URL the resolver gave for the prefetch.
  used('used'),

  /// The opener thread failed to create a demuxer for the next playlist
  /// item, typically a network error (404, timeout or DNS), an
  /// unsupported codec, or a deliberate abort by an `on_load` hook
  /// rewrite. Distinct from a silent return to [idle] because no
  /// gapless transition is armed: the next track will be re-opened
  /// from scratch when playback reaches it. Persists at [failed] until
  /// the next [loading] or a stop; a cancel does not reset it.
  failed('failed');

  const PrefetchState(this.mpvValue);

  /// The wire-level string mpv emits for this phase.
  final String mpvValue;

  /// Parses the string emitted by mpv. Unknown values fall back to
  /// [idle] so future mpv additions don't crash clients; they just
  /// see the phase treated as "not actively prefetching".
  static PrefetchState fromMpv(String value) =>
      byMpvValue(values, value, (v) => v.mpvValue) ?? idle;
}
