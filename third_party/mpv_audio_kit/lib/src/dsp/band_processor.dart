// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fftea/fftea.dart';

import '../models/fft_frame.dart';
import '../models/pcm_frame.dart';
import '../types/settings/spectrum_settings.dart';

/// Stateful PCM-to-bands processor — runs the same FFT, windowing,
/// log-band aggregation and asymmetric-EMA smoothing the library uses
/// internally to back [PlayerStream.fft].
///
/// Use it to compute frequency-domain bands from any [PcmFrame] stream
/// — typically the per-filter [PlayerStream.tap] — when you want the
/// bands to share the global visualizer's exact settings (FFT size,
/// window, overlap, smoothing, dB clip, log-band layout).
///
/// Holds a rolling sample ring of [SpectrumSettings.fftSize] mono
/// samples and runs an FFT every `fftSize / overlapFactor` samples
/// (75 % overlap by default). The smoothed bands are accumulated
/// across hops; a single [FftFrame] is returned per [process] call,
/// carrying the latest snapshot, or `null` while the ring is still
/// priming or the input metadata is invalid. Lazy allocation: the FFT
/// engine and scratch buffers are not built until [process] is called
/// for the first time, so an unused processor costs no memory.
///
/// Example — bind a per-filter editor's input/output curves to the
/// player's live spectrum settings:
///
/// ```dart
/// final processor = BandProcessor(player.spectrumSettings);
/// // Track config changes so the local FFT stays in lock-step with
/// // the global visualizer.
/// final cfgSub = player.stream.spectrum.listen(processor.setSettings);
/// final tapSub =
///     player.stream.tap(AudioEffect.equalizer, side: TapSide.post)
///         .listen((pcm) {
///       final fft = processor.process(pcm);
///       if (fft != null) painter.bands = fft.bands;
///     });
/// ```
class BandProcessor {
  /// Creates a processor seeded with the given [SpectrumSettings]. The
  /// FFT engine and scratch buffers stay unallocated until the first
  /// [process] call, so an idle processor costs no memory.
  BandProcessor(this._settings);

  SpectrumSettings _settings;

  // ── Sample ring (mono) ─────────────────────────────────────────────
  // Rolling buffer of the last `fftSize` mono samples. Each input
  // sample is mixed down to mono on push so the ring has the same
  // length regardless of the source's channel count.
  Float64List? _ring;
  int _ringWrite = 0;
  int _samplesInRing = 0;
  int _samplesUntilNextHop = 0;

  // ── FFT machinery — recreated only on `fftSize` / window changes.
  FFT? _fft;
  Float64List? _windowed;
  Float64x2List? _buffer;
  Float32List? _window;
  Float32List? _smoothedBands;

  // Bin-aggregation cache, recomputed lazily on sample-rate or band
  // config change.
  Int32List? _bandStartBin;
  Int32List? _bandEndBin;
  int _lastBandSampleRate = 0;

  // The most-recent raw bin power vector — the consumer-facing
  // [FftFrame.bins] payload of the next emitted frame. Allocated
  // once (size = fftSize / 2) and overwritten every FFT.
  Float32List? _rawBins;

  /// Replaces the configuration. Reallocates only the buffers that
  /// depend on changed fields (FFT size / window / band layout).
  /// Smoothing is reset on band-count change so the bands don't
  /// inherit stale heights from a different layout.
  void setSettings(SpectrumSettings next) {
    final fftSizeChanged = next.fftSize != _settings.fftSize;
    final overlapChanged = next.overlapFactor != _settings.overlapFactor;
    final windowChanged =
        next.window != _settings.window || fftSizeChanged;
    final bandConfigChanged = next.bandCount != _settings.bandCount ||
        next.bandLowHz != _settings.bandLowHz ||
        next.bandHighHz != _settings.bandHighHz;

    _settings = next;

    if (fftSizeChanged) {
      _fft = null;
      _ring = null;
      _windowed = null;
      _buffer = null;
      _rawBins = null;
      _ringWrite = 0;
      _samplesInRing = 0;
      _samplesUntilNextHop = 0;
    }
    if (windowChanged) _window = null;
    if (bandConfigChanged || fftSizeChanged) {
      _smoothedBands = null;
      _bandStartBin = null;
      _bandEndBin = null;
    }
    if (overlapChanged) {
      // Overlap change retunes the hop spacing — let the next push
      // re-prime the countdown.
      _samplesUntilNextHop = 0;
    }
  }

  /// Pushes [frame]'s samples through the ring. Returns an [FftFrame]
  /// holding the latest smoothed bands when at least one FFT fired
  /// during this call, or `null` while the ring is still priming.
  /// `null` is also returned when the input has invalid metadata so
  /// the caller can simply ignore it.
  FftFrame? process(PcmFrame frame) {
    final samples = frame.samples;
    final channels = frame.channels;
    final sampleRate = frame.sampleRate;
    if (samples.isEmpty || channels <= 0 || sampleRate <= 0) {
      return null;
    }

    final fftSize = _settings.fftSize;
    final hopSize = fftSize ~/ _settings.overlapFactor;

    _ring ??= Float64List(fftSize);
    _windowed ??= Float64List(fftSize);
    _buffer ??= Float64x2List(fftSize);
    _window ??= _settings.window.compute(fftSize);
    _smoothedBands ??= Float32List(_settings.bandCount);
    _rawBins ??= Float32List(fftSize ~/ 2);
    _fft ??= FFT(fftSize);
    if (_samplesUntilNextHop <= 0) _samplesUntilNextHop = hopSize;

    final samplesPerChannel = samples.length ~/ channels;
    if (samplesPerChannel <= 0) return null;

    // Push every input sample (mono-mixed) into the ring. Fire an FFT
    // every `hopSize` samples once the ring has been filled at least
    // once (otherwise the front-edge would carry leftover zeros).
    var didFft = false;
    final invChannels = channels == 1 ? 1.0 : 1.0 / channels;
    for (var i = 0; i < samplesPerChannel; i++) {
      double mono;
      if (channels == 1) {
        mono = samples[i].toDouble();
      } else {
        var sum = 0.0;
        final base = i * channels;
        for (var c = 0; c < channels; c++) {
          sum += samples[base + c];
        }
        mono = sum * invChannels;
      }
      _ring![_ringWrite] = mono;
      _ringWrite = (_ringWrite + 1) % fftSize;
      if (_samplesInRing < fftSize) _samplesInRing++;
      _samplesUntilNextHop--;
      if (_samplesUntilNextHop <= 0 && _samplesInRing >= fftSize) {
        _samplesUntilNextHop = hopSize;
        _runFftOnRing(sampleRate, fftSize);
        didFft = true;
      }
    }

    if (!didFft) return null;
    return _emit(frame.timestamp, sampleRate);
  }

  void _runFftOnRing(int sampleRate, int fftSize) {
    final ring = _ring!;
    final windowed = _windowed!;
    final buffer = _buffer!;
    final window = _window!;
    final fft = _fft!;

    // Read the ring in time order: oldest sample is at [_ringWrite],
    // newest is at [(_ringWrite − 1) mod fftSize]. Apply Hann while
    // copying so the next loop is one mul + one store per sample.
    final start = _ringWrite;
    for (var i = 0; i < fftSize; i++) {
      final src = (start + i) % fftSize;
      windowed[i] = ring[src] * window[i];
    }
    for (var i = 0; i < fftSize; i++) {
      buffer[i] = Float64x2(windowed[i], 0);
    }
    fft.inPlaceFft(buffer);

    final binCount = fftSize ~/ 2;
    final raw = _rawBins!;
    final minDb = _settings.minDb;
    final maxDb = _settings.maxDb;
    final dbRange = maxDb - minDb;
    if (dbRange <= 0) return;

    // Normalise bin magnitude by N/2 so the dB scale matches the Web
    // Audio API convention (`AnalyserNode` magnitudes are divided by
    // `fftSize` — equivalent here since the input is real-valued and
    // `binCount = fftSize / 2`). Without this the dB output drifts up
    // by ~`20·log10(N/2)` and the [SpectrumSettings.minDb] /
    // [SpectrumSettings.maxDb] defaults stop matching every Web-Audio
    // tutorial on the internet.
    final invBinCount = 1.0 / binCount;

    // Magnitude → log → clip → normalise [0, 1].
    for (var i = 0; i < binCount; i++) {
      final c = buffer[i];
      final mag = math.sqrt(c.x * c.x + c.y * c.y) * invBinCount;
      final db = 20 * (math.log(mag + 1e-12) / math.ln10);
      var n = (db - minDb) / dbRange;
      if (n < 0) n = 0;
      if (n > 1) n = 1;
      raw[i] = n;
    }

    // Lazy-recompute bin → band mapping when sample rate changes.
    if (_bandStartBin == null || sampleRate != _lastBandSampleRate) {
      _computeBandMapping(sampleRate, fftSize, binCount);
      _lastBandSampleRate = sampleRate;
    }

    final bandCount = _settings.bandCount;
    final smoothed = _smoothedBands!;
    final attack = _settings.attackSmoothing;
    final release = _settings.releaseSmoothing;
    final bandStart = _bandStartBin!;
    final bandEnd = _bandEndBin!;

    for (var b = 0; b < bandCount; b++) {
      final s = bandStart[b];
      final e = bandEnd[b];
      var sum = 0.0;
      final count = e - s;
      if (count > 0) {
        for (var i = s; i < e; i++) {
          sum += raw[i];
        }
        sum /= count;
      }
      final prev = smoothed[b];
      final alpha = sum > prev ? attack : release;
      smoothed[b] = prev + alpha * (sum - prev);
    }
  }

  void _computeBandMapping(int sampleRate, int fftSize, int binCount) {
    final bandCount = _settings.bandCount;
    final bandLow = math.max(_settings.bandLowHz, 1.0);
    final nyquist = sampleRate / 2.0;
    final bandHigh = math.min(_settings.bandHighHz, nyquist);
    final start = Int32List(bandCount);
    final end = Int32List(bandCount);
    if (bandHigh <= bandLow || binCount <= 0) {
      _bandStartBin = start;
      _bandEndBin = end;
      return;
    }
    final binHz = sampleRate / fftSize;
    final ratio = math.pow(bandHigh / bandLow, 1 / bandCount).toDouble();
    for (var b = 0; b < bandCount; b++) {
      final lowHz = bandLow * math.pow(ratio, b);
      final highHz = bandLow * math.pow(ratio, b + 1);
      var s = (lowHz / binHz).floor();
      var e = (highHz / binHz).ceil();
      if (s < 0) s = 0;
      if (s >= binCount) s = binCount - 1;
      if (e <= s) e = s + 1;
      if (e > binCount) e = binCount;
      start[b] = s;
      end[b] = e;
    }
    _bandStartBin = start;
    _bandEndBin = end;
  }

  FftFrame _emit(Duration timestamp, int sampleRate) {
    final bandCount = _settings.bandCount;
    final bins = Float32List(_rawBins!.length)..setAll(0, _rawBins!);
    final bands = Float32List(bandCount)..setAll(0, _smoothedBands!);
    return FftFrame(
      bins: bins,
      bands: bands,
      timestamp: timestamp,
      sampleRate: sampleRate,
      bandLowHz: _settings.bandLowHz,
      bandHighHz: math.min(_settings.bandHighHz, sampleRate / 2.0),
    );
  }
}
