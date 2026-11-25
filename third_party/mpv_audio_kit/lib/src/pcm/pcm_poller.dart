// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of 'pcm_source.dart';

// The poll of the live sources.
//
// One timer serves every source while any is not done: the reader runs
// on an mpv thread and the C API never calls back into Dart, so the
// queue, the state and [ready] follow by polling. A tick costs a few
// leaf calls per source. Sources are watched through weak references,
// so one the app dropped is still collected (its finalizer releases
// it); a source with queued chunks, a pending close or a ready waiter
// is held strongly until that work is done.
//
// The timer ticks every [_interval] while a player reads one of the
// sources. With no reader (sources queued in a playlist, or never
// opened) nothing moves on the native side: [add] and [close] write
// what fits themselves, and the rest waits for room only a reader
// makes. The timer then ticks every [_idleInterval], just to see a
// reader come. The native buffer holds at least a second of audio, so
// the reader has that much before the first fast tick refills it.

const Duration _interval = Duration(milliseconds: 20);
const Duration _idleInterval = Duration(milliseconds: 250);
final List<WeakReference<PcmSource>> _watched = [];
final Set<PcmSource> _held = {};
Timer? _timer;
// The period of [_timer].
Duration? _period;
// Whether [_pollAll] is walking [_watched].
bool _polling = false;

void _watch(PcmSource source) {
  _watched.add(WeakReference(source));
  // A new source has no reader: the timer keeps the rate it has.
  if (_timer == null) _setPeriod(_idleInterval);
}

void _hold(PcmSource source) {
  if (!source.isDone) _held.add(source);
}

void _setPeriod(Duration? period) {
  if (period == _period) return;
  _timer?.cancel();
  _period = period;
  _timer = period == null ? null : Timer.periodic(period, (_) => _pollAll());
}

/// Stops watching [source], which is done, and the timer with the last
/// one. During a poll the loop does it.
void _unwatch(PcmSource source) {
  if (_polling) return;
  _watched.removeWhere((w) => identical(w.target, source));
  if (_watched.isEmpty) _setPeriod(null);
}

void _pollAll() {
  _polling = true;
  try {
    _pollWatched();
  } finally {
    _polling = false;
  }
}

void _pollWatched() {
  var read = false;
  for (var i = _watched.length - 1; i >= 0; i--) {
    final source = _watched[i].target;
    if (source != null) source._tick();
    if (source == null || source.isDone) {
      _watched.removeAt(i);
      continue;
    }
    if (source._read) read = true;
    if (!source._hasWork) _held.remove(source);
  }
  if (_watched.isEmpty) return _setPeriod(null);
  _setPeriod(read ? _interval : _idleInterval);
}
