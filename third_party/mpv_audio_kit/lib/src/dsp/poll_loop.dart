// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

/// The timer of a pipeline that polls a property of the core, and the
/// guard that keeps its polls from overlapping: under a busy core an async
/// read's reply can land after the next tick has fired, so a poll is
/// skipped while one read is still outstanding.
///
/// Each period calls [_tick], the pipeline's own check of whether to poll,
/// which calls [run] to start the poll itself.
@internal
final class PollLoop {
  /// A loop that calls [_tick] each period and runs [_poll] from [run].
  PollLoop(this._tick, this._poll);

  final void Function() _tick;
  final Future<void> Function() _poll;
  Timer? _timer;
  bool _running = false;

  /// Whether the timer runs.
  bool get isArmed => _timer != null;

  /// Starts the timer at [period], unless it runs.
  void arm(Duration period) {
    _timer ??= Timer.periodic(period, (_) => _tick());
  }

  /// Starts the timer at [period] again, from now.
  void rearm(Duration period) {
    _timer?.cancel();
    _timer = Timer.periodic(period, (_) => _tick());
  }

  /// Stops the timer. A poll in flight completes.
  void disarm() {
    _timer?.cancel();
    _timer = null;
  }

  /// Starts one poll, unless the one before is still running.
  void run() {
    if (_running) return;
    _running = true;
    unawaited(_poll().whenComplete(() => _running = false));
  }
}
