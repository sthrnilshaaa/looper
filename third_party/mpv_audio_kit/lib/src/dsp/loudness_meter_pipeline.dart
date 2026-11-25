// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../models/loudness.dart';
import '../mpv_constants.dart';
import 'dsp_async_io.dart';
import 'poll_loop.dart';

/// Live EBU R128 loudness meter pipeline.
///
/// Reads the per-frame measurements the `ebur128` lavfi filter injects
/// into its frame metadata (`lavfi.r128.M/S/I/LRA`) back through mpv's
/// `af-metadata/<label>` property. The meter follows the first enabled
/// `Ebur128Effect` in `PlayerState.audioEffects`, which needs its
/// `metadata` option on; the player hands this pipeline that stage's
/// chain label.
///
/// Listener-gated by [setEnabled] (driven by the player's `loudness`
/// controller): polling runs only while `PlayerStream.loudnessMeter` has a
/// listener, so an unused meter costs nothing. While the filter is not
/// in the chain the poll reads nothing and emits nothing.
@internal
class LoudnessMeterPipeline {
  /// Creates the pipeline over the player's async-get callback.
  LoudnessMeterPipeline({
    required AsyncPropertyGet asyncGet,
    required String? Function() label,
    Duration pollInterval = const Duration(milliseconds: 100),
  }) : _asyncGet = asyncGet,
       _label = label,
       _pollInterval = pollInterval;

  final AsyncPropertyGet _asyncGet;

  /// The chain label of the `ebur128` stage to read, `null` when the chain
  /// has none running.
  final String? Function() _label;
  final Duration _pollInterval;

  final StreamController<Loudness> _ctrl =
      StreamController<Loudness>.broadcast();
  late final PollLoop _loop = PollLoop(_poll, _doPoll);
  bool _enabled = false;
  bool _disposed = false;

  /// The live measurement stream. Emits one [Loudness] per poll tick
  /// while the meter is active in the chain.
  Stream<Loudness> get stream => _ctrl.stream;

  /// Starts or stops polling. Driven by the `onListen` and `onCancel` of
  /// the player's `loudness` controller.
  void setEnabled(bool enabled) {
    if (_disposed || enabled == _enabled) return;
    _enabled = enabled;
    if (enabled) {
      _loop.arm(_pollInterval);
    } else {
      _loop.disarm();
    }
  }

  /// Closes the stream.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _loop.disarm();
    if (!_ctrl.isClosed) await _ctrl.close();
  }

  void _poll() {
    if (_disposed) return;
    _loop.run();
  }

  Future<void> _doPoll() async {
    // One read of the stage's whole frame metadata: the four fields come
    // from the same frame, in one round trip off the main isolate.
    final label = _label();
    if (label == null) return;
    final (rc, value) = await _asyncGet(
      'af-metadata/$label',
      MpvFormat.mpvFormatNode,
    );
    if (_disposed || rc < 0 || value is! Map) return;
    double? field(String key) {
      final v = value['lavfi.r128.$key'];
      return v is String
          ? double.tryParse(v)
          : (v is num ? v.toDouble() : null);
    }

    final next = Loudness(
      momentary: field('M'),
      shortTerm: field('S'),
      integrated: field('I'),
      range: field('LRA'),
    );
    // Nothing available: the meter is not in the chain (or no frame has
    // flowed yet). Stay silent rather than emitting an all-null snapshot.
    if (next.momentary == null &&
        next.shortTerm == null &&
        next.integrated == null &&
        next.range == null) {
      return;
    }
    if (!_ctrl.isClosed) _ctrl.add(next);
  }
}
