// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../models/loudness.dart';
import '../mpv_bindings.dart';
import 'dsp_async_io.dart';

/// Live EBU R128 loudness meter pipeline.
///
/// Reads the per-frame measurements the `ebur128` lavfi filter injects
/// into its frame metadata (`lavfi.r128.M/S/I/LRA`) back through mpv's
/// `af-metadata/<label>` property — the filter must be enabled on the
/// [AudioEffects] bundle with its `metadata` option on, which gives it
/// the stable `aek_ebur128` chain label this pipeline polls.
///
/// Listener-gated by [setEnabled] (driven by the player's `loudness`
/// controller): polling runs only while `PlayerStream.loudness` has a
/// listener, so an unused meter costs nothing. While the filter is not
/// in the chain the poll reads nothing and emits nothing.
@internal
class LoudnessMeterPipeline {
  /// Creates the pipeline over the player's async-get callback.
  LoudnessMeterPipeline({
    required AsyncPropertyGet asyncGet,
    Duration pollInterval = const Duration(milliseconds: 100),
  })  : _asyncGet = asyncGet,
        _pollInterval = pollInterval;

  /// The chain label the typed `ebur128` slot is emitted under.
  static const String chainLabel = 'aek_ebur128';

  final AsyncPropertyGet _asyncGet;
  final Duration _pollInterval;

  final StreamController<Loudness> _ctrl =
      StreamController<Loudness>.broadcast();
  Timer? _pollTimer;
  bool _enabled = false;
  bool _disposed = false;
  // Guards against overlapping polls: under a busy core an async read's
  // reply can land after the next tick has fired, so a tick is skipped
  // while one read is still outstanding.
  bool _polling = false;

  static const List<String> _keys = ['M', 'S', 'I', 'LRA'];

  /// The live measurement stream. Emits one [Loudness] per poll tick
  /// while the meter is active in the chain.
  Stream<Loudness> get stream => _ctrl.stream;

  /// Starts or stops polling. Driven by the `onListen` / `onCancel` of
  /// the player's `loudness` controller.
  void setEnabled(bool enabled) {
    if (_disposed || enabled == _enabled) return;
    _enabled = enabled;
    if (enabled) {
      _pollTimer ??= Timer.periodic(_pollInterval, (_) => _poll());
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  /// Closes the stream.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _pollTimer?.cancel();
    _pollTimer = null;
    if (!_ctrl.isClosed) await _ctrl.close();
  }

  void _poll() {
    if (_disposed || _polling) return;
    _polling = true;
    unawaited(_doPoll().whenComplete(() => _polling = false));
  }

  Future<void> _doPoll() async {
    // Read the four r128 metadata fields off the main isolate. Each is a
    // STRING property; the reply carries the decoded value.
    final values = List<double?>.filled(4, null);
    for (var i = 0; i < _keys.length; i++) {
      final (rc, value) = await _asyncGet(
        'af-metadata/$chainLabel/lavfi.r128.${_keys[i]}',
        MpvFormat.mpvFormatString,
      );
      if (_disposed) return;
      if (rc >= 0 && value is String) values[i] = double.tryParse(value);
    }

    // Nothing available — the meter is not in the chain (or no frame has
    // flowed yet). Stay silent rather than emitting an all-null snapshot.
    if (values.every((v) => v == null)) return;

    if (!_ctrl.isClosed) {
      _ctrl.add(Loudness(
        momentary: values[0],
        shortTerm: values[1],
        integrated: values[2],
        range: values[3],
      ),);
    }
  }
}
