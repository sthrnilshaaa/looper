// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../models/waveform_data.dart';
import 'analysis_poll_pipeline.dart';
import 'dsp_async_io.dart';

/// Static waveform pipeline: polls `waveform-data` while
/// [PlayerStream.waveform] has a listener (`waveform-enabled` on), see
/// [AnalysisPollPipeline].
///
/// As soon as the analyzer reports `state == "ready"` the assembled
/// envelope is emitted once via [stream] and the timer stops until the
/// next file load. On every file load the player calls [reset]: the
/// pipeline drops the current envelope, emits `null`, and rearms the
/// timer if still enabled.
@internal
class WaveformPipeline extends AnalysisPollPipeline<WaveformData> {
  WaveformPipeline({
    required super.asyncGet,
    required super.asyncSet,
    super.pollInterval,
  }) : super(
         enabledProperty: 'waveform-enabled',
         dataProperty: 'waveform-data',
       );

  // Last coverage seen while DECODING, to skip re-emitting unchanged partials.
  int? _lastDecodeCoverage;

  // Last envelope emitted while it grows with playback (progressive or
  // rolling). Polled on a timer, it is unchanged while paused: emitting it
  // again would copy up to a few MB to the UI for nothing. A new listener
  // still gets it from the player's replay.
  WaveformData? _lastGrowing;

  @override
  void onDrop() {
    _lastDecodeCoverage = null;
    _lastGrowing = null;
  }

  void _emitGrowing(WaveformData data) {
    final last = _lastGrowing;
    if (last != null && _sameEnvelope(last, data)) return;
    _lastGrowing = data;
    emit(data);
  }

  @override
  bool sameResult(WaveformData a, WaveformData b) =>
      _sameEnvelope(a, b) &&
      a.decoding == b.decoding &&
      a.coverageBins == b.coverageBins;

  @override
  void onData(Map<Object?, Object?> value) {
    final state = value['state'];
    if (state == 'failed') {
      // No envelope is coming (true live or unsupported). Stop polling
      // and clear: there is nothing further to wait for.
      stopPolling();
      _lastGrowing = null;
      emit(null);
      return;
    }
    final bins = _readBins(value);
    if (bins == null) return;
    final durationUs = _int(value['duration_us']);
    switch (state) {
      case 'rolling':
        _onRolling(value, bins);
      case 'decoding' when durationUs > 0:
        _onDecoding(value, bins, durationUs);
      case 'ready' || 'progressive' when durationUs > 0:
        final data = WaveformData(
          duration: Duration(microseconds: durationUs),
          min: bins.min,
          max: bins.max,
          rms: bins.rms,
          filled: bins.filled,
        );
        if (state == 'ready') {
          // Bulk envelope is final: keep it and stop polling.
          finish(_padded(data, _intOrNull(value['total_bins'])));
          return;
        }
        // Progressive envelope (grown from playback) grows: keep the timer
        // running so each poll drives the native fold and emits the grown
        // envelope.
        _emitGrowing(data);
    }
  }

  /// ROLLING (true live, unknown total): a sliding window keyed to the
  /// demuxer cache. The native side reports the absolute range it holds;
  /// the envelope grows and slides, so never cache it: keep polling.
  void _onRolling(Map<Object?, Object?> value, _Bins bins) {
    final rangeStartUs = _int(value['range_start_us']);
    final rangeEndUs = _int(value['range_end_us']);
    if (rangeEndUs <= rangeStartUs) return;
    _emitGrowing(
      WaveformData(
        start: Duration(microseconds: rangeStartUs),
        duration: Duration(microseconds: rangeEndUs - rangeStartUs),
        min: bins.min,
        max: bins.max,
        rms: bins.rms,
        filled: bins.filled,
        live: true,
      ),
    );
  }

  /// DECODING (a decode apart from playback in flight: a local file, or a
  /// remote one read from mpv's cache or opened again): a partial envelope
  /// that grows on every poll. The full axis is emitted with `filled`
  /// marking the regions decoded so far. Never cache it and never stop the
  /// timer: the final `ready` emission supersedes it. De-dup on coverage
  /// so an unchanged snapshot does not churn the UI.
  void _onDecoding(Map<Object?, Object?> value, _Bins bins, int durationUs) {
    final coverageBins = _intOrNull(value['coverage_bins']);
    if (coverageBins != null && coverageBins == _lastDecodeCoverage) return;
    _lastDecodeCoverage = coverageBins;
    _lastGrowing = null;
    emit(
      WaveformData(
        duration: Duration(microseconds: durationUs),
        min: bins.min,
        max: bins.max,
        rms: bins.rms,
        filled: bins.filled,
        decoding: true,
        coverageBins: coverageBins,
        totalBins: _intOrNull(value['total_bins']),
      ),
    );
  }
}

/// The bins of a `waveform-data` reply.
typedef _Bins = ({
  Float32List min,
  Float32List max,
  Float32List? rms,
  Uint8List filled,
});

/// [value] when it is an int, 0 otherwise.
int _int(Object? value) => value is int ? value : 0;

/// [value] when it is an int, `null` otherwise.
int? _intOrNull(Object? value) => value is int ? value : null;

/// The bins of [value], `null` when `min` and `max` are missing, empty or
/// of different lengths. `rms` is dropped on a length mismatch, and
/// `filled` falls back to all-covered when the native side omitted or
/// mismatched the flags, so the renderer never misreads it.
_Bins? _readBins(Map<Object?, Object?> value) {
  final min = float32FromByteValue(value['min']);
  final max = float32FromByteValue(value['max']);
  if (min == null || max == null || min.isEmpty || min.length != max.length) {
    return null;
  }
  // Null on a length mismatch.
  final rms = float32FromByteValue(value['rms']);
  final filled = value['filled'];
  return (
    min: min,
    max: max,
    rms: rms != null && rms.length == min.length ? rms : null,
    filled: filled is Uint8List && filled.length == min.length
        ? filled
        : (Uint8List(min.length)..fillRange(0, min.length, 1)),
  );
}

/// The most bins an axis holds (a live window's), a bound on a malformed
/// `total_bins`.
const int _kMaxBins = 131072;

/// [data] on an axis of [total] bins. A decode that ends short of the axis
/// (mpv estimated the length from the bitrate, and the audio is shorter)
/// fills fewer bins than the axis holds: the tail goes out unfilled, so
/// each bin stays at its time on the track's `[0, duration]`.
WaveformData _padded(WaveformData data, int? total) {
  final bins = data.bins;
  if (total == null || total <= bins || total > _kMaxBins) return data;
  Float32List pad(Float32List v) => Float32List(total)..setRange(0, bins, v);
  final rms = data.rms;
  return WaveformData(
    duration: data.duration,
    min: pad(data.min),
    max: pad(data.max),
    rms: rms == null ? null : pad(rms),
    filled: Uint8List(total)..setRange(0, bins, data.filled),
  );
}

/// Whether [a] and [b] carry the same axis and the same bins.
bool _sameEnvelope(WaveformData a, WaveformData b) =>
    a.live == b.live &&
    a.start == b.start &&
    a.duration == b.duration &&
    _sameFloats(a.min, b.min) &&
    _sameFloats(a.max, b.max) &&
    _sameFloatsOrNull(a.rms, b.rms) &&
    _sameBytes(a.filled, b.filled);

bool _sameFloatsOrNull(Float32List? a, Float32List? b) =>
    a == null || b == null ? a == b : _sameFloats(a, b);

// Bit compare: NaN equals itself, 0.0 and -0.0 differ, as in the bytes.
bool _sameFloats(Float32List a, Float32List b) =>
    a.length == b.length &&
    _sameWords(
      a.buffer.asUint32List(a.offsetInBytes, a.length),
      b.buffer.asUint32List(b.offsetInBytes, b.length),
    );

bool _sameWords(Uint32List a, Uint32List b) {
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _sameBytes(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
