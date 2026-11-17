// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Aggregate playback lifecycle, derived from `playing` / `buffering` /
/// `completed` / `pausedForCache` / `duration`. Subscribe via
/// `PlayerStream.playbackState` when a single mutually-exclusive
/// state fits the UI better than three separate booleans. The underlying
/// booleans remain available on `PlayerStream` for granular use cases.
///
/// The `Mpv` prefix avoids a name clash with `audio_service.PlaybackState`,
/// a common downstream library.
enum MpvPlaybackState {
  /// No file loaded. UI should hide transport controls.
  idle,

  /// File is opening — demuxer / decoder init, before the first audio frame.
  loading,

  /// Mid-playback network stall (`paused-for-cache=true`). Distinct from
  /// `loading` (initial open) and `paused` (user-initiated).
  buffering,

  /// Producing audio.
  playing,

  /// File loaded but not producing audio (user pause, EOF without natural
  /// completion, etc.).
  paused,

  /// Reached natural end-of-file. Advance the queue here.
  completed,
}
