// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../mpv_constants.dart';
import 'dsp_async_io.dart';
import 'poll_loop.dart';
import 'shared_property_writer.dart';

/// The polling shared by the per-file analyses (waveform, loudness scan).
///
/// Listener-gated by [setEnabled]: while a listener is attached the player
/// writes the analysis' enable property `true` (the native side only runs
/// while it is set) and the pipeline polls its data property on a low-rate
/// timer. On the last cancel the property goes back to `false` and the
/// timer stops, so an idle analysis costs nothing.
///
/// The enable property is a static of the libmpv process, shared by every
/// player: it stays on while a pipeline of this isolate holds it, and the
/// last one to let go (a cancel, or [dispose]) turns it off. A listener
/// that comes back while the file's result stands gets it from the
/// player's replay, and the property stays off until the next file
/// ([reset]): writing it on would decode the whole file again.
///
/// A subclass decodes each poll in [onData]: it [emit]s partial values and
/// calls [finish] with the final one, which stops polling until the next
/// [reset] (a new file) or [clear] (no file).
@internal
abstract class AnalysisPollPipeline<T extends Object> {
  AnalysisPollPipeline({
    required AsyncPropertyGet asyncGet,
    required AsyncPropertySet asyncSet,
    required String enabledProperty,
    required String dataProperty,
    Duration pollInterval = const Duration(milliseconds: 120),
  }) : _asyncGet = asyncGet,
       _asyncSet = asyncSet,
       _enabledProperty = enabledProperty,
       _dataProperty = dataProperty,
       _pollInterval = pollInterval;

  final AsyncPropertyGet _asyncGet;
  final AsyncPropertySet _asyncSet;
  final String _enabledProperty;
  final String _dataProperty;
  final Duration _pollInterval;

  final StreamController<T?> _ctrl = StreamController<T?>.broadcast();
  late final PollLoop _loop = PollLoop(_poll, _doPoll);
  T? _result;
  // The result of the file loaded again, kept on screen until the first
  // reply says whether it stands (see [reset]).
  T? _held;
  // Replies since [_held] was set that neither confirmed nor replaced it
  // (an error, a node with nothing in it): past [_heldReplies] it goes.
  int _heldWaited = 0;
  static const int _heldReplies = 25;
  // The reply being handled already cleared the held result: its own
  // `null` (a failed pass) would be a second one.
  bool _clearedHeld = false;
  bool _enabled = false;
  // Whether this pipeline holds the native enable property on.
  bool _nativeOn = false;
  late final _Switch _switch = _switches.putIfAbsent(
    _enabledProperty,
    () => _Switch(_enabledProperty),
  );

  // The enable properties, one per analysis, by name.
  static final Map<String, _Switch> _switches = {};
  bool _disposed = false;
  // No file loaded (after [clear]): mpv still holds the last file's
  // analysis, so nothing is polled until the next [reset].
  bool _idle = false;

  Stream<T?> get stream => _ctrl.stream;

  /// Arms or disarms the analysis. Driven by the `onListen` and `onCancel`
  /// of the player's controller. Writes the enable property and starts or
  /// stops polling.
  void setEnabled(bool enabled) {
    if (_disposed || enabled == _enabled) return;
    _enabled = enabled;
    if (enabled) {
      // A finished result already reaches a new subscriber through the
      // player's replay of the last value: the native side stays off until
      // the next file. Only a pending result arms it and polls.
      if (_result == null) {
        _setNative(true);
        _armTimer();
      }
    } else {
      _setNative(false);
      stopPolling();
    }
  }

  /// Drops the current result and emits `null` so renderers clear stale
  /// data on the track-change boundary. Rearms the polling timer when the
  /// analysis is still enabled.
  ///
  /// With [sameFile] (the path loaded again) a finished result stays on
  /// screen instead of `null`: mpv keeps a complete
  /// analysis of the same file, and the first reply gives it back as it
  /// was. A reply of a new pass (another file under the same path, or a
  /// pass that had not finished) replaces it, and so does `null` when
  /// about 3 seconds of replies say neither.
  void reset({bool sameFile = false}) {
    if (_disposed) return;
    _idle = false;
    // The one still held when the file is loaded again before any reply
    // (a short entry on loop).
    final result = _result ?? _held;
    final held = sameFile && result != null && keepsAcrossReload(result)
        ? result
        : null;
    if (held == null) {
      _drop();
    } else {
      _result = null;
      onDrop();
      stopPolling();
    }
    _held = held;
    _heldWaited = 0;
    if (_enabled) {
      _setNative(true);
      _armTimer();
    }
  }

  /// Drops the current result and emits `null` once no file is loaded,
  /// without polling again until the next [reset].
  void clear() {
    if (_disposed) return;
    _idle = true;
    _held = null;
    _drop();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    stopPolling();
    // The flag outlives this player: left on, the next player in the
    // process would analyze every file it loads.
    _setNative(false);
    if (!_ctrl.isClosed) await _ctrl.close();
  }

  void _setNative(bool on) {
    if (on == _nativeOn) return;
    _nativeOn = on;
    final sw = _switch;
    if (on) {
      sw.holders++;
      // Written on every enable, held already or not: on a core with a
      // file loaded it starts the analysis of that file, so it goes
      // through this player's core.
      sw.writer.write(_asyncSet, () => _nativeOn ? 'yes' : null);
    } else if (--sw.holders == 0) {
      // Off only when no other player of this isolate holds it.
      sw.writer.write(
        _asyncSet,
        () => sw.holders == 0 ? 'no' : null,
        anyCore: true,
      );
    }
  }

  /// Decodes one reply of the data property, a map.
  @protected
  void onData(Map<Object?, Object?> value);

  /// Whether the finished [result] stays on screen across a reload of
  /// the same file until the first reply (see [reset]). A result mpv
  /// gives back as it was; by default every one.
  @protected
  bool keepsAcrossReload(T result) => true;

  /// Whether [a] is the same result as [b], so a reply after a reload
  /// does not emit it again.
  @protected
  bool sameResult(T a, T b);

  /// Forgets what [onData] remembers between polls (progress seen, ...).
  @protected
  void onDrop();

  @protected
  void emit(T? value) {
    _held = null;
    if (value == null && _clearedHeld) return;
    if (!_ctrl.isClosed) _ctrl.add(value);
  }

  /// Emits the final [value] and stops polling until the next [reset]. The
  /// same result as the one held across a reload is not emitted again.
  @protected
  void finish(T value) {
    _result = value;
    stopPolling();
    final held = _held;
    if (held != null && sameResult(value, held)) {
      _held = null;
      return;
    }
    emit(value);
  }

  @protected
  void stopPolling() => _loop.disarm();

  void _drop() {
    _result = null;
    onDrop();
    stopPolling();
    emit(null);
  }

  void _armTimer() {
    if (_disposed || _idle || _result != null) return;
    _loop.rearm(_pollInterval);
    _poll();
  }

  void _poll() {
    if (_disposed || _result != null) return;
    _loop.run();
  }

  Future<void> _doPoll() async {
    final (rc, value) = await _asyncGet(_dataProperty, MpvFormat.mpvFormatNode);
    if (_disposed || _idle || _result != null) return;
    if (rc >= 0 && value is Map) _onReply(value);
    // Still held: this reply said nothing of it. A result nothing confirms
    // does not stay on screen for good.
    if (_held != null && ++_heldWaited >= _heldReplies) emit(null);
  }

  /// Hands a reply to [onData]. A new pass on the file loaded again clears
  /// the held result at once, not with the first partial value.
  void _onReply(Map<Object?, Object?> value) {
    if (_held != null && value['state'] != 'ready') {
      emit(null);
      _clearedHeld = true;
    }
    try {
      onData(value);
    } catch (_) {
      // A single malformed node must never escape the poll: an uncaught
      // throw would tear down the poll loop and freeze the analysis until
      // the next file. The next tick retries against fresh native state.
    } finally {
      _clearedHeld = false;
    }
  }
}

/// One enable property: how many pipelines of this isolate hold it on, and
/// the writer that orders their writes across the players' cores.
final class _Switch {
  _Switch(String property) : writer = SharedPropertyWriter(property);

  final SharedPropertyWriter writer;
  int holders = 0;
}
