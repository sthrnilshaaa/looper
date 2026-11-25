// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import '../types/enums/interruption_policy.dart';

/// What an outside pause of the web session's `<audio>` element does
/// under [MediaSession.interruptionPolicy], as an interruption on iOS and
/// Android: the command to send, or none.
@internal
final class OutsidePauseFollower {
  /// The policy of the session, by its name.
  InterruptionPolicy policy = InterruptionPolicy.pauseAndResume;

  // Paused by an outside pause, to play again when it ends.
  bool _paused = false;

  /// The command for an outside change of the element: `'pause'` when it
  /// stopped while the player played ([playing]), `'play'` when it plays
  /// again after a pause this sent, under [InterruptionPolicy.pauseAndResume].
  String? onOutside({required bool elementPlaying, required bool playing}) {
    if (policy == InterruptionPolicy.keepPlaying) {
      _paused = false;
      return null;
    }
    if (!elementPlaying) {
      if (!playing) {
        // Paused by the user since: an earlier outside pause has
        // nothing to resume.
        _paused = false;
        return null;
      }
      _paused = policy == InterruptionPolicy.pauseAndResume;
      return 'pause';
    }
    // The policy now, not the one of the pause: an app that turned
    // pauseOnly on since gets no play.
    final resume = _paused && policy == InterruptionPolicy.pauseAndResume;
    _paused = false;
    return resume ? 'play' : null;
  }

  /// Forgets a pause this sent: the session ended, or the user played or
  /// paused the player since.
  void reset() => _paused = false;

  /// [policy] from its name in the session's config, the default for an
  /// unknown one.
  static InterruptionPolicy policyOf(Object? name) =>
      InterruptionPolicy.values.firstWhere(
        (p) => p.name == name,
        orElse: () => InterruptionPolicy.pauseAndResume,
      );
}

/// Tells the plays and pauses of the session's `<audio>` element that come
/// from outside the page's output (the browser, a call, another app) from
/// the output's own. The output feeds it the element's events, the
/// context's states and its own calls of `play()`. A play at a gesture of
/// the page is the output's own; the one at the end of an interruption is
/// not.
@internal
final class OutsideElementWatch {
  // The element plays.
  bool _playing = false;
  // A play() of the output's own waits for its `playing` event.
  bool _asked = false;
  // Paused from outside, and not played since.
  bool _paused = false;
  // The context's state, and whether it just ran again after an
  // interruption: the output's next play() is then the interruption's end.
  String _state = 'none';
  bool _interruptionEnded = false;

  /// The output routes again: nothing of the element before counts.
  void reset() => _playing = _asked = _paused = _interruptionEnded = false;

  /// The context's new [state]: whether the output plays the element now.
  ///
  /// A context that runs again after `interrupted` (iOS: a call, another
  /// app's sound) is the interruption ending. The browser does not play
  /// the element again by itself there, the output does: that play counts
  /// as from outside, so the player resumes under pauseAndResume.
  bool onContextState(String state) {
    _interruptionEnded = _state == 'interrupted' && state == 'running';
    _state = state;
    return state == 'running';
  }

  /// The output calls `play()` on the element, [elementPaused] before the
  /// call. Only a paused element counts: `play()` on a playing one fires no
  /// `playing`, and a flag left set would take the browser's next play,
  /// after an outside pause, for the output's own.
  void onOutputPlay({required bool elementPaused}) {
    if (elementPaused) _asked = !_interruptionEnded;
    _interruptionEnded = false;
  }

  /// The browser refused that `play()` (no gesture yet).
  void onPlayRefused() => _asked = false;

  /// The element's `playing` event: whether it plays again from outside
  /// after an outside pause. A play of the output's own says no.
  bool onPlaying() {
    final asked = _asked;
    _asked = false;
    _playing = true;
    if (!_paused) return false;
    _paused = false;
    return !asked;
  }

  /// The element's `pause` event: whether it is an outside pause, of an
  /// element that played.
  bool onPause() {
    _asked = false;
    if (!_playing) return false;
    _playing = false;
    _paused = true;
    return true;
  }
}
