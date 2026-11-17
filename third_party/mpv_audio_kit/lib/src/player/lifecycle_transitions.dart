// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import '../types/enums/loop.dart';
import 'player_state.dart';

/// Result of a lifecycle transition, used by [computeLifecycle].
///
/// The three `*DidChange` flags tell the caller which of the three
/// observable lifecycle reactives (playing / buffering / completed) needs
/// to be fed an `update()`. Splitting the diff out of the dispatch site
/// keeps `state.copyWith(...)` and `controller.add(...)` from drifting
/// out of sync — they share one decision point and one set of flags.
@internal
class LifecycleResult {
  const LifecycleResult({
    required this.newState,
    required this.playingDidChange,
    required this.bufferingDidChange,
    required this.completedDidChange,
  });

  final PlayerState newState;
  final bool playingDidChange;
  final bool bufferingDidChange;
  final bool completedDidChange;
}

/// Pure-function core of the lifecycle update used on file boundaries.
/// Given the previous [PlayerState] and any subset of `playing` /
/// `buffering` / `completed` overrides, returns the new state plus a
/// per-field "did-change" flag the caller pushes to the corresponding
/// broadcast reactives.
@internal
LifecycleResult computeLifecycle({
  required PlayerState prev,
  bool? playing,
  bool? buffering,
  bool? completed,
}) {
  var next = prev;
  if (playing != null) next = next.copyWith(playing: playing);
  if (buffering != null) next = next.copyWith(buffering: buffering);
  if (completed != null) next = next.copyWith(completed: completed);
  return LifecycleResult(
    newState: next,
    playingDidChange: playing != null && prev.playing != playing,
    bufferingDidChange: buffering != null && prev.buffering != buffering,
    completedDidChange: completed != null && prev.completed != completed,
  );
}

/// Folds an event from one of mpv's two loop properties (`loop-file`,
/// `loop-playlist`) into a typed [Loop]. Returns `null` when the
/// event isn't a meaningful state change — e.g. `loop-file=no` while the
/// active mode is [Loop.playlist], where the file-side toggle must
/// not reset the playlist loop.
@internal
Loop? deriveLoop(
  String mpvName,
  String value,
  Loop prevMode,
) {
  // `loop-file` / `loop-playlist` accept `'inf'`, `'no'`, or a non-negative
  // integer (finite repeat count). Any value other than `'no'` / `'0'` is
  // an active loop; both `'inf'` and `'N>0'` collapse into the
  // corresponding [Loop].
  bool isActiveLoopValue(String v) {
    if (v == 'inf') return true;
    if (v == 'no' || v.isEmpty) return false;
    final n = int.tryParse(v);
    return n != null && n > 0;
  }

  final active = isActiveLoopValue(value);
  switch (mpvName) {
    case 'loop-file':
      if (active) return Loop.file;
      if (prevMode == Loop.file) return Loop.off;
      return null;
    case 'loop-playlist':
      if (active) return Loop.playlist;
      if (prevMode == Loop.playlist) return Loop.off;
      return null;
    default:
      return null;
  }
}
