// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../models/waveform_data.dart';
import '../mpv_bindings.dart';
import 'dsp_async_io.dart';

/// Static waveform pipeline.
///
/// Listener-gated by [setEnabled]: while a listener is attached to
/// [PlayerStream.waveform] the player writes the `waveform-enabled`
/// mpv property `true` (the native analyzer only runs while this flag
/// is set) and the pipeline polls `waveform-data` on a low-rate timer.
/// On the last cancel the player writes `waveform-enabled` `false` and
/// the timer stops — an idle waveform costs nothing.
///
/// As soon as the analyzer reports `state == "ready"` the assembled
/// envelope is emitted once via [stream] and the timer stops until the
/// next track-change. On track change the player calls [reset]: the
/// pipeline drops the current envelope, emits `null`, and rearms the
/// timer if still enabled.
@internal
class WaveformPipeline {
  WaveformPipeline({
    required AsyncPropertyGet asyncGet,
    required AsyncPropertySet asyncSet,
    Duration pollInterval = const Duration(milliseconds: 120),
  })  : _asyncGet = asyncGet,
        _asyncSet = asyncSet,
        _pollInterval = pollInterval;

  final AsyncPropertyGet _asyncGet;
  final AsyncPropertySet _asyncSet;
  final Duration _pollInterval;

  final StreamController<WaveformData?> _ctrl =
      StreamController<WaveformData?>.broadcast();
  Timer? _pollTimer;
  WaveformData? _data;
  // Last coverage seen while DECODING, to skip re-emitting unchanged partials.
  int? _lastDecodeCoverage;
  bool _enabled = false;
  bool _disposed = false;
  // Guards against overlapping async polls — see [LoudnessMeterPipeline].
  bool _polling = false;

  Stream<WaveformData?> get stream => _ctrl.stream;

  /// Arms or disarms the analyzer. Driven by the `onListen` / `onCancel`
  /// of the player's `waveform` controller. Writes the
  /// `waveform-enabled` mpv property and starts / stops polling.
  void setEnabled(bool enabled) {
    if (_disposed || enabled == _enabled) return;
    _enabled = enabled;
    _writeEnabledProperty(enabled);
    if (enabled) {
      if (_data != null) {
        _emit(_data);
      } else {
        _armTimer();
      }
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  /// Drops the current envelope and emits `null` so renderers clear
  /// stale data on the track-change boundary. Rearms the polling timer
  /// when the analyzer is still enabled.
  void reset() {
    if (_disposed) return;
    _data = null;
    _lastDecodeCoverage = null;
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

  void _emit(WaveformData? data) {
    if (!_ctrl.isClosed) _ctrl.add(data);
  }

  void _writeEnabledProperty(bool enabled) {
    unawaited(_asyncSet('waveform-enabled', enabled ? 'yes' : 'no'));
  }

  void _armTimer() {
    if (_disposed || _data != null) return;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
    _poll();
  }

  void _poll() {
    if (_disposed || _polling || _data != null) return;
    _polling = true;
    unawaited(_doPoll().whenComplete(() => _polling = false));
  }

  Future<void> _doPoll() async {
    final (rc, value) =
        await _asyncGet('waveform-data', MpvFormat.mpvFormatNode);
    if (_disposed || _data != null) return;
    try {
      if (rc < 0 || value is! Map) return;

      final stateValue = value['state'];
      final state = stateValue is String ? stateValue : null;
      final durationUs = value['duration_us'] is int
          ? value['duration_us'] as int
          : 0;
      final rangeStartUs = value['range_start_us'] is int
          ? value['range_start_us'] as int
          : 0;
      final rangeEndUs =
          value['range_end_us'] is int ? value['range_end_us'] as int : 0;
      final min = float32FromByteValue(value['min']);
      final max = float32FromByteValue(value['max']);
      // Absent before libmpv-r14; null then, like a length mismatch.
      final rmsValue = float32FromByteValue(value['rms']);
      final filled =
          value['filled'] is Uint8List ? value['filled'] as Uint8List : null;

      final ready = state == 'ready';
      final progressive = state == 'progressive';
      final rolling = state == 'rolling';
      final decoding = state == 'decoding';
      final coverageBins =
          value['coverage_bins'] is int ? value['coverage_bins'] as int : null;
      final totalBins =
          value['total_bins'] is int ? value['total_bins'] as int : null;

      final haveBins = min != null &&
          max != null &&
          min.isNotEmpty &&
          min.length == max.length;
      final rms =
          (rmsValue != null && min != null && rmsValue.length == min.length)
              ? rmsValue
              : null;

      // Fall back to all-covered if the native side omitted/mismatched the
      // flags, so the renderer never misreads it.
      Uint8List safeFilled(Float32List m) =>
          (filled != null && filled.length == m.length)
              ? filled
              : (Uint8List(m.length)..fillRange(0, m.length, 1));

      // ROLLING (true live, unknown total): a sliding window keyed to the
      // demuxer cache. The native side reports the absolute range it holds;
      // the envelope grows and slides, so never cache it — keep polling.
      if (rolling && haveBins && rangeEndUs > rangeStartUs) {
        final data = WaveformData(
          start: Duration(microseconds: rangeStartUs),
          duration: Duration(microseconds: rangeEndUs - rangeStartUs),
          min: min,
          max: max,
          rms: rms,
          filled: safeFilled(min),
          live: true,
        );
        _emit(data);
        return;
      }

      // DECODING (local-file bulk analysis in flight): a partial envelope that
      // grows on every poll. The full axis is emitted with [filled] marking the
      // regions decoded so far. Never cache it and never stop the timer — the
      // final `ready` emission below supersedes it. De-dup on coverage so an
      // unchanged snapshot does not churn the UI.
      if (decoding && durationUs > 0 && haveBins) {
        if (coverageBins == null || coverageBins != _lastDecodeCoverage) {
          _lastDecodeCoverage = coverageBins;
          final data = WaveformData(
            duration: Duration(microseconds: durationUs),
            min: min,
            max: max,
            rms: rms,
            filled: safeFilled(min),
            decoding: true,
            coverageBins: coverageBins,
            totalBins: totalBins,
          );
          _emit(data);
        }
        return;
      }

      if ((ready || progressive) && durationUs > 0 && haveBins) {
        final data = WaveformData(
          duration: Duration(microseconds: durationUs),
          min: min,
          max: max,
          rms: rms,
          filled: safeFilled(min),
        );
        if (ready) {
          // Bulk envelope is final: cache it and stop polling.
          _data = data;
          _pollTimer?.cancel();
          _pollTimer = null;
        }
        // Progressive (network) envelope grows: leave _data null and the
        // timer running so each poll drives the native fold and emits the
        // freshly-grown envelope.
        _emit(data);
        return;
      }
      if (state == 'failed') {
        // No envelope is coming (true live / unsupported). Stop polling
        // and clear — there is nothing further to wait for.
        _pollTimer?.cancel();
        _pollTimer = null;
        _emit(null);
      }
    } catch (_) {
      // A single malformed / unexpected waveform-data node must never
      // escape the poll: an uncaught throw would tear down the poll loop
      // and freeze the waveform until app restart. Swallow it — the next
      // tick retries against fresh native state.
    }
  }
}
