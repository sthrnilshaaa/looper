// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../models/fft_frame.dart';
import '../models/pcm_frame.dart';
import '../mpv_constants.dart';
import '../types/settings/spectrum_settings.dart';
import 'band_processor.dart';
import 'dsp_async_io.dart';
import 'poll_loop.dart';

/// Real-time FFT + raw PCM pipeline backed by the mpv `pcm-tap-frame`
/// property.
///
/// Owns two broadcast streams ([fftStream], [pcmStream]) and a
/// poll loop that reads `pcm-tap-frame` with an async get at the
/// configured emit rate. The poll loop is **lazy**: it starts on the
/// first listener (to either stream) and stops on the last cancel.
///
/// While the core is idle ([setIdle]: paused, stopped, at the end) the
/// output writes nothing and the loop does not run: a new listener still
/// gets one read, the frame the output holds.
///
/// The pipeline:
///   1. Poll the property → MAP_NODE { sample_rate, channels, pts_ns, samples }.
///   2. Skip a stream when `pts_ns` matches the frame it got last (no new
///      audio). A stream's first listener gets the current frame, paused too.
///   3. Keep only the audio the spectrum has not analyzed: the frame
///      holds the latest 4096 samples per channel and overlaps the one
///      before (see [BandProcessor]). A read with less new audio than an
///      FFT hop sends its [PcmFrame] and no [FftFrame].
///   4. Mix down to mono (mean of channels).
///   5. Multiply by the configured window function.
///   6. Real FFT (fftea) → magnitude per bin.
///   7. Power → 10·log₁₀ → clip [minDb, maxDb] → normalise [0, 1].
///   8. Aggregate bins into log-spaced bands (mean per band).
///   9. Apply asymmetric EMA on the bands (fast attack, slow release).
///   10. Emit [FftFrame] (raw bins + smoothed bands) and [PcmFrame].
@internal
class SpectrumPipeline {
  SpectrumPipeline({required AsyncPropertyGet asyncGet})
    : _asyncGet = asyncGet {
    _fftCtrl = StreamController<FftFrame>.broadcast(
      onListen: () {
        _fftActive = true;
        _lastFftPtsNs = 0;
        _maybeStart();
        _poll();
      },
      onCancel: () {
        _fftActive = false;
        _maybeStop();
      },
    );
    _pcmCtrl = StreamController<PcmFrame>.broadcast(
      onListen: () {
        _pcmActive = true;
        _lastPcmPtsNs = 0;
        _maybeStart();
        _poll();
      },
      onCancel: () {
        _pcmActive = false;
        _maybeStop();
      },
    );
  }

  final AsyncPropertyGet _asyncGet;

  late final StreamController<FftFrame> _fftCtrl;
  late final StreamController<PcmFrame> _pcmCtrl;

  Stream<FftFrame> get fftStream => _fftCtrl.stream;
  Stream<PcmFrame> get pcmStream => _pcmCtrl.stream;

  SpectrumSettings _settings = SpectrumSettings.defaults;

  bool _fftActive = false;
  bool _pcmActive = false;
  bool _disposed = false;
  bool _idle = false;
  late final PollLoop _loop = PollLoop(_poll, _doPoll);

  // Shared FFT, windowing and EMA pipeline: same component the
  // public [BandProcessor] exposes, so global and per-filter
  // spectrum surfaces stay byte-identical when fed equivalent PCM.
  late final BandProcessor _processor = BandProcessor(_settings);
  // The frame each stream got last. Paused, the output writes nothing and
  // every poll reads the same frame: a stream skips it once it has it.
  // Its first listener starts from 0, so it gets the frame the output
  // holds now (a listener that comes back while paused, an fft listener
  // next to a pcm one), and the other stream gets no duplicate.
  int _lastFftPtsNs = 0;
  int _lastPcmPtsNs = 0;

  /// Replaces the pipeline configuration. Reallocates FFT, window and
  /// EMA memory only on changes that require it; the poll timer is
  /// re-armed only when [SpectrumSettings.emitInterval] changes.
  void setSettings(SpectrumSettings next) {
    final emitChanged = next.emitInterval != _settings.emitInterval;
    _settings = next;
    _processor.setSettings(next);
    if (emitChanged && _loop.isArmed) _loop.rearm(_interval);
  }

  /// Stops the poll loop while the core is idle (mpv's `core-idle`) and
  /// starts it again when it plays: idle, every read would return the
  /// frame the streams already have.
  void setIdle(bool idle) {
    if (_disposed || idle == _idle) return;
    _idle = idle;
    if (idle) {
      _loop.disarm();
    } else if (_fftActive || _pcmActive) {
      _maybeStart();
    }
  }

  /// The shortest poll period. A shorter [SpectrumSettings.emitInterval]
  /// (a zero one would poll as fast as replies come back) is raised to it.
  static const Duration minEmitInterval = Duration(milliseconds: 8);

  Duration get _interval => _settings.emitInterval < minEmitInterval
      ? minEmitInterval
      : _settings.emitInterval;

  void _maybeStart() {
    if (_disposed || _idle) return;
    // [BandProcessor] allocates lazily on first [process], so we don't
    // need to prime anything here: just arm the poll loop.
    _loop.arm(_interval);
  }

  void _maybeStop() {
    if (_fftActive || _pcmActive) return;
    _loop.disarm();
  }

  void _poll() {
    if (_disposed) return;
    if (!_fftActive && !_pcmActive) return;
    _loop.run();
  }

  Future<void> _doPoll() async {
    final (rc, value) = await _asyncGet(
      'pcm-tap-frame',
      MpvFormat.mpvFormatNode,
    );
    if (_disposed) return;
    if (rc < 0 || value is! Map) return;

    // Scalars first: a stale frame (same pts as the previous poll, e.g.
    // while paused) is discarded BEFORE the sample buffer is reinterpreted.
    final sampleRate = _intOrZero(value['sample_rate']);
    final channels = _intOrZero(value['channels']);
    final ptsNs = _intOrZero(value['pts_ns']);

    if (sampleRate <= 0 || channels <= 0 || ptsNs == 0) return;
    final fftNew = _fftActive && ptsNs != _lastFftPtsNs;
    final pcmNew = _pcmActive && ptsNs != _lastPcmPtsNs;
    if (!fftNew && !pcmNew) return;

    final samples = float32FromByteValue(value['samples']);
    if (samples == null) return;

    _emit(
      PcmFrame(
        samples: samples,
        timestamp: Duration(microseconds: ptsNs ~/ 1000),
        sampleRate: sampleRate,
        channels: channels,
      ),
      ptsNs,
      fft: fftNew,
      pcm: pcmNew,
    );
  }

  /// Adds [frame], read at [ptsNs], to the streams that do not have it:
  /// [pcm] for the PCM stream, [fft] for the spectrum.
  void _emit(
    PcmFrame frame,
    int ptsNs, {
    required bool fft,
    required bool pcm,
  }) {
    if (pcm && !_pcmCtrl.isClosed) {
      _lastPcmPtsNs = ptsNs;
      _pcmCtrl.add(frame);
    }
    if (fft && !_fftCtrl.isClosed) {
      _lastFftPtsNs = ptsNs;
      final spectrum = _processor.process(frame);
      if (spectrum != null) _fftCtrl.add(spectrum);
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _loop.disarm();
    if (!_fftCtrl.isClosed) await _fftCtrl.close();
    if (!_pcmCtrl.isClosed) await _pcmCtrl.close();
  }
}

/// [value] when it is an int, 0 otherwise.
int _intOrZero(Object? value) => value is int ? value : 0;
