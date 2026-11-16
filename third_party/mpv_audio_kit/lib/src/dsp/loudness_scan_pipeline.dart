// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../models/loudness_scan.dart';
import '../mpv_bindings.dart';
import '../types/state/loudness_scan_state.dart';
import 'dsp_async_io.dart';

/// Offline loudness-scan pipeline.
///
/// Listener-gated by [setEnabled]: while a listener is attached to
/// [PlayerStream.loudness] the player writes the
/// `loudness-scan-enabled` mpv property `true` (the native scan only
/// runs while this flag is set) and the pipeline polls
/// `loudness-scan-data` on a low-rate timer. On the last cancel the
/// player writes the flag `false` and the timer stops — an idle scan
/// costs nothing.
///
/// While the scan runs it emits `scanning` snapshots carrying a progress
/// fraction on each poll. As soon as it reaches a terminal state (`ready` /
/// `failed` / `unavailable`) the result is emitted via [stream] and the timer
/// stops until the next track-change. On track change the player calls
/// [reset]: the pipeline drops the current result, emits `null`, and
/// rearms the timer if still enabled.
@internal
class LoudnessScanPipeline {
  LoudnessScanPipeline({
    required AsyncPropertyGet asyncGet,
    required AsyncPropertySet asyncSet,
    Duration pollInterval = const Duration(milliseconds: 120),
  })  : _asyncGet = asyncGet,
        _asyncSet = asyncSet,
        _pollInterval = pollInterval;

  final AsyncPropertyGet _asyncGet;
  final AsyncPropertySet _asyncSet;
  final Duration _pollInterval;

  final StreamController<LoudnessScan?> _ctrl =
      StreamController<LoudnessScan?>.broadcast();
  Timer? _pollTimer;
  LoudnessScan? _result;
  // Last scanning fraction seen, to skip re-emitting unchanged progress.
  double? _lastScanProgress;
  bool _enabled = false;
  bool _disposed = false;
  // Guards against overlapping async polls — see [LoudnessMeterPipeline].
  bool _polling = false;

  Stream<LoudnessScan?> get stream => _ctrl.stream;

  /// Arms or disarms the scan. Driven by the `onListen` / `onCancel` of
  /// the player's scan controller. Writes the
  /// `loudness-scan-enabled` mpv property and starts / stops polling.
  void setEnabled(bool enabled) {
    if (_disposed || enabled == _enabled) return;
    _enabled = enabled;
    _writeEnabledProperty(enabled);
    if (enabled) {
      if (_result != null) {
        _emit(_result);
      } else {
        _armTimer();
      }
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  /// Drops the current result and emits `null` so consumers clear stale
  /// data on the track-change boundary. Rearms the polling timer when
  /// the scan is still enabled.
  void reset() {
    if (_disposed) return;
    _result = null;
    _lastScanProgress = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _emit(null);
    if (_enabled) _armTimer();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _pollTimer?.cancel();
    _pollTimer = null;
    if (!_ctrl.isClosed) await _ctrl.close();
  }

  void _emit(LoudnessScan? result) {
    if (!_ctrl.isClosed) _ctrl.add(result);
  }

  void _writeEnabledProperty(bool enabled) {
    unawaited(_asyncSet('loudness-scan-enabled', enabled ? 'yes' : 'no'));
  }

  void _armTimer() {
    if (_disposed || _result != null) return;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
    _poll();
  }

  void _poll() {
    if (_disposed || _polling || _result != null) return;
    _polling = true;
    unawaited(_doPoll().whenComplete(() => _polling = false));
  }

  Future<void> _doPoll() async {
    final (rc, value) =
        await _asyncGet('loudness-scan-data', MpvFormat.mpvFormatNode);
    if (_disposed || _result != null) return;
    if (rc < 0 || value is! Map) return;

    final state = value['state'];
    if (state is! String) return;

    double asDouble(Object? v) => v is num ? v.toDouble() : 0.0;
    int asInt(Object? v) => v is int ? v : 0;

    double? asFraction(Object? v) =>
        v is num ? v.toDouble().clamp(0.0, 1.0) : null;

    final parsed = LoudnessScanState.fromMpv(state);
    switch (parsed) {
      case LoudnessScanState.ready:
        _result = LoudnessScan(
          state: LoudnessScanState.ready,
          integrated: asDouble(value['integrated_lufs']),
          range: asDouble(value['lra_lu']),
          samplePeak: asDouble(value['sample_peak']),
          truePeak: asDouble(value['true_peak']),
          gatedBlockCount: asInt(value['gated_block_count']),
          progress: 1.0,
        );
      case LoudnessScanState.failed:
      case LoudnessScanState.unavailable:
        _result = LoudnessScan(state: parsed);
      case LoudnessScanState.scanning:
        // Non-terminal: surface a progress snapshot and keep polling. Never
        // cache it (_result stays null) so the poll loop stays armed until a
        // terminal state lands. De-dup on the fraction to avoid UI churn.
        final progress = asFraction(value['progress']);
        if (progress != _lastScanProgress) {
          _lastScanProgress = progress;
          final scan = LoudnessScan(
            state: LoudnessScanState.scanning,
            progress: progress,
          );
          _emit(scan);
        }
        return;
      case LoudnessScanState.idle:
        return; // non-terminal — keep polling
    }
    _pollTimer?.cancel();
    _pollTimer = null;
    _emit(_result);
  }
}
