// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';

/// A typed value cell that exposes the current value synchronously (via [value])
/// and pushes changes asynchronously through a broadcast [stream].
///
/// Designed to back the per-property state of [Player]: each observed mpv
/// property owns a [ReactiveProperty] of the appropriate Dart type, and the
/// property registry mutates them as raw mpv events arrive.
///
/// The [update] method deduplicates writes — a write of the same value (by
/// `==`) is a no-op and does not emit on the stream. This is the primary
/// reason this class exists: it removes the per-call-site burden of "did the
/// value actually change?" branching, so a setter that updates state
/// optimistically can write unconditionally and trust that streams stay
/// quiet on no-ops.
class ReactiveProperty<T> {
  /// Creates a [ReactiveProperty] seeded with [initial] as its current value.
  ReactiveProperty(T initial) : _value = initial;

  T _value;
  final StreamController<T> _ctrl = StreamController<T>.broadcast();

  /// The current value. Synchronous, never throws.
  T get value => _value;

  /// Broadcast stream of future updates.
  ///
  /// Subscribers do **not** receive [value] on subscribe — they only see
  /// changes that occur after `listen()` is called. Pair with [value] when
  /// you need the seed.
  Stream<T> get stream => _ctrl.stream;

  /// Whether [close] has been called.
  bool get isClosed => _ctrl.isClosed;

  /// Updates the current [value] and emits on [stream].
  ///
  /// If [next] equals the current value (by `==`), this is a no-op: no update
  /// to the cached value, no emission. Returns `true` if the value changed
  /// and was emitted, `false` on dedup (or if the controller is closed).
  bool update(T next) {
    if (_ctrl.isClosed) return false;
    if (_value == next) return false;
    _value = next;
    _ctrl.add(next);
    return true;
  }

  /// Forces an emission on [stream] without changing [value].
  ///
  /// Used by lifecycle helpers that want to re-broadcast the current value
  /// (e.g. the file-loaded transition wants to re-emit `playing=true` even
  /// when `playing` was already `true` before the previous track ended).
  /// Most callers should use [update] instead.
  void emitCurrent() {
    if (_ctrl.isClosed) return;
    _ctrl.add(_value);
  }

  /// Closes the underlying broadcast controller. Idempotent.
  Future<void> close() {
    if (_ctrl.isClosed) return Future.value();
    return _ctrl.close();
  }
}
