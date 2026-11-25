// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

/// What [EventSequencer.take] did: whether it took an event out of mpv's
/// queue (`false` when the queue was empty), the future of the reads the
/// event takes, and whether it was the last one (MPV_EVENT_SHUTDOWN).
typedef TakenEvent = (bool taken, Future<void>? reads, bool last);

/// The loop of an event pump that may not block, as on the web, where the
/// pump runs on the main thread. It takes mpv's events one at a time
/// through [take], and while the reads of one are in flight it takes no
/// other: the later events stay in mpv's queue, where the native pump
/// leaves them while it blocks in its reads. So the player gets the events
/// in the native order, and mpv builds the property changes after them
/// with the newest values, as it does for the native pump.
///
/// The reads must not come back through the queue [take] drains: the web
/// pump sends them on a second client of the same core.
@internal
final class EventSequencer {
  /// A sequencer over [take], which takes the next event of the queue and
  /// hands it to the logic. [idle] runs after every event and once the
  /// queue is empty: it sends the values the logic held whose window
  /// closed, and may return reads to wait for. [waitSeconds] says when
  /// the next window closes (`null` when no value is held). [onError]
  /// gets what an event threw.
  EventSequencer({
    required this.take,
    required this.idle,
    required this.waitSeconds,
    required this.onError,
  });

  /// Takes the next event of mpv's queue and dispatches it.
  final TakenEvent Function() take;

  /// Seconds until the earliest held value's window closes; `null` when
  /// none is held.
  final double? Function() waitSeconds;

  /// Gets an error an event threw, synchronously or from its reads.
  final void Function(Object error, StackTrace stack) onError;

  /// Sends the held values whose window has closed, then starts the reads
  /// that are due, if any, and returns their future.
  final Future<void>? Function() idle;

  bool _stepping = false;
  bool _stopped = false;
  bool _pumping = false;
  bool _again = false;
  Timer? _flush;

  /// Whether the reads of an event are in flight: nothing is taken until
  /// they complete.
  bool get stepping => _stepping;

  /// Whether [stop] was called or the last event was taken.
  bool get stopped => _stopped;

  /// Takes events until mpv's queue is empty or the reads of one are in
  /// flight. The pump calls it at every wakeup of the client; while an
  /// event's reads are in flight it returns at once, and the sequencer
  /// takes the next events itself when they complete.
  void pump() {
    if (_stepping) return;
    // A wakeup that comes while [take] runs (the web pump's calls can run
    // the module's posted work) takes its events in the loop below, never
    // in a nested one.
    if (_pumping) {
      _again = true;
      return;
    }
    _pumping = true;
    try {
      _pumpLoop();
    } finally {
      _pumping = false;
    }
  }

  void _pumpLoop() {
    _flush?.cancel();
    _flush = null;
    while (!_stopped && !_stepping) {
      // A wakeup from here on asks for another take, which this one is.
      _again = false;
      final TakenEvent next;
      try {
        next = take();
      } catch (e, st) {
        // One undecodable event must not stop the pump, as natively.
        onError(e, st);
        continue;
      }
      final (taken, reads, last) = next;
      if (!taken) {
        // The queue is empty: the native pump's wait would end here with
        // no event, after which it flushes and runs the reads that are due.
        final due = _idle();
        if (due != null) {
          _step(due);
          return;
        }
        // A wakeup during that take: its event may have come after it.
        if (!_again) break;
        continue;
      }
      if (last) _stopped = true;
      if (reads == null) {
        // As the native pump after every event: flush, and the reads that
        // are due go before the next event.
        final due = _idle();
        if (due != null) {
          _step(due);
          return;
        }
        continue;
      }
      _step(reads);
      return;
    }
    _armFlush();
  }

  Future<void>? _idle() {
    try {
      return idle();
    } catch (e, st) {
      onError(e, st);
      return null;
    }
  }

  void _step(Future<void> reads) {
    _stepping = true;
    unawaited(
      reads.then(
        (_) => _stepped(true),
        onError: (Object e, StackTrace st) {
          onError(e, st);
          _stepped(false);
        },
      ),
    );
  }

  void _stepped(bool ok) {
    _stepping = false;
    if (ok && !_stopped) {
      final due = _idle();
      if (due != null) {
        _step(due);
        return;
      }
    }
    pump();
  }

  // The native pump's wait ends when the earliest held value's window
  // closes; here a timer takes its place.
  void _armFlush() {
    if (_stopped) return;
    final seconds = waitSeconds();
    if (seconds == null) return;
    _flush = Timer(Duration(microseconds: (seconds * 1e6).ceil()), pump);
  }

  /// Takes no more events, now or after the reads in flight.
  void stop() {
    _stopped = true;
    _flush?.cancel();
    _flush = null;
  }
}
