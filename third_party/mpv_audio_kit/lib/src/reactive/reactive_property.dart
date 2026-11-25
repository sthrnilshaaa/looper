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
/// The [update] method deduplicates writes: a write of the same value (by
/// `==`, or by the cell's `equals`) is a no-op and does not emit on the
/// stream. This is the primary
/// reason this class exists: it removes the per-call-site burden of "did the
/// value actually change?" branching, so a setter that updates state
/// optimistically can write unconditionally and trust that streams stay
/// quiet on no-ops.
class ReactiveProperty<T> {
  /// Creates a [ReactiveProperty] seeded with [initial] as its current value.
  ///
  /// [equals] replaces `==` in the dedup of [update]. A collection cell
  /// passes a content comparison, since `==` on a `List`, `Set` or `Map`
  /// is identity and every mpv event builds a new one.
  ReactiveProperty(this.initial, {bool Function(T a, T b)? equals})
    : _value = initial,
      _equals = equals;

  /// The seed value, which the cell returns to when mpv reports its
  /// property unavailable (see [MpvPropertySpec.resetAndDispatch]).
  final T initial;

  T _value;
  final bool Function(T a, T b)? _equals;
  final StreamController<T> _ctrl = StreamController<T>.broadcast();

  /// The current value. Synchronous, never throws.
  T get value => _value;

  /// Broadcast stream of the value: each subscriber first receives the
  /// current [value], then every change.
  late final Stream<T> stream = replayStream(() => _value, _ctrl.stream);

  /// Broadcast stream of the changes only, without the current value on
  /// subscribe. For internal consumers that react to a change, such as
  /// the media session.
  Stream<T> get changes => _ctrl.stream;

  /// Whether [close] has been called.
  bool get isClosed => _ctrl.isClosed;

  /// Updates the current [value] and emits on [stream].
  ///
  /// If [next] equals the current value (by `==`, or by the `equals` the
  /// cell was created with), this is a no-op: no update
  /// to the cached value, no emission. Returns `true` if the value changed
  /// and was emitted, `false` on dedup (or if the controller is closed).
  bool update(T next) {
    if (_ctrl.isClosed) return false;
    final equals = _equals;
    if (equals != null ? equals(_value, next) : _value == next) return false;
    _value = next;
    _ctrl.add(next);
    return true;
  }

  /// Closes the underlying broadcast controller. Idempotent.
  Future<void> close() {
    if (_ctrl.isClosed) return Future.value();
    return _ctrl.close();
  }
}

/// A broadcast stream that gives each new subscriber [current]'s result
/// first, then every event of [changes]. The state streams of `Player`
/// are built on it, so a `StreamBuilder` starts from the current value
/// without `initialData`.
Stream<T> replayStream<T>(T Function() current, Stream<T> changes) =>
    Stream<T>.multi((controller) {
      controller.add(current());
      final sub = changes.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller
        ..onPause = sub.pause
        ..onResume = sub.resume
        ..onCancel = sub.cancel;
    }, isBroadcast: true);

/// A broadcast stream of the value [current] derives from [sources]: each
/// subscriber gets it first, then once per change, whichever source
/// moved. The dedup is per subscriber, so one that joins while a source
/// event is still queued is not sent the value it already has. Done when
/// a source is done, as the sources close together on dispose.
Stream<T> aggregateStream<T>(
  T Function() current,
  List<Stream<Object?>> sources,
) => Stream<T>.multi((controller) {
  var last = current();
  var done = false;
  controller.add(last);
  void pump(Object? _) {
    if (done) return;
    final next = current();
    if (next == last) return;
    last = next;
    controller.add(next);
  }

  void finish() {
    if (done) return;
    done = true;
    unawaited(controller.close());
  }

  final subs = [
    for (final s in sources)
      s.listen(pump, onError: controller.addError, onDone: finish),
  ];
  controller
    ..onPause = () {
      for (final s in subs) {
        s.pause();
      }
    }
    ..onResume = () {
      for (final s in subs) {
        s.resume();
      }
    }
    ..onCancel = () => Future.wait([for (final s in subs) s.cancel()]);
}, isBroadcast: true);
