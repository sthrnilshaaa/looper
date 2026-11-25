// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import '../types/state/mpv_playback_state.dart';

/// Pure derivation of the aggregate [MpvPlaybackState] from five
/// observables the library already tracks.
///
/// The mapping, first match wins:
/// - `completed`: completed
/// - `pausedForCache`: buffering
/// - `buffering`: loading
/// - `playing`: playing
/// - not `fileLoaded` (mpv's `path` is empty): idle
/// - otherwise: paused
///
/// [fileLoaded] decides idle, not the duration: a live stream has no
/// known duration and a file reports none until it is loaded, and both
/// are paused, not idle.
///
/// Two semantically-different "stalled" states are distinguished by
/// `pausedForCache` (mpv's `paused-for-cache`): `loading` is the initial
/// open, `buffering` is a mid-playback network re-buffer.
@internal
MpvPlaybackState deriveMpvPlaybackState({
  required bool playing,
  required bool buffering,
  required bool completed,
  required bool pausedForCache,
  required bool fileLoaded,
}) {
  if (completed) return MpvPlaybackState.completed;
  if (pausedForCache) return MpvPlaybackState.buffering;
  if (buffering) return MpvPlaybackState.loading;
  if (playing) return MpvPlaybackState.playing;
  if (!fileLoaded) return MpvPlaybackState.idle;
  return MpvPlaybackState.paused;
}
