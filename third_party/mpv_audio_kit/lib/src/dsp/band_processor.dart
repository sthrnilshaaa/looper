// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fftea/fftea.dart';

import '../models/fft_frame.dart';
import '../models/pcm_frame.dart';
import '../types/settings/spectrum_settings.dart';

/// Stateful PCM-to-bands processor: runs the same FFT, windowing,
/// log-band aggregation and asymmetric-EMA smoothing the library uses
/// internally to back [PlayerStream.fft].
///
/// Use it to compute frequency-domain bands from any [PcmFrame] stream
/// (typically the per-filter [PlayerStream.tap]) when you want the
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
/// A tap frame holds the latest 4096 frames per channel, so two frames
/// in a row overlap. [process] finds where a frame continues the one
/// before and analyzes only the audio that is new, so each sample is
/// analyzed once and the smoothing follows the time of the audio, not
/// how often frames arrive. The player's own [PlayerStream.fft] does the
/// same. Frames that do not overlap (pieces of a stream one after the
/// other, a seek, a new track) are analyzed whole.
///
/// Example: bind a per-filter editor's input and output curves to the
/// player's live spectrum settings:
///
/// ```dart
/// final processor = BandProcessor(player.state.settings.spectrum);
/// // Track config changes so the local FFT stays in lock-step with
/// // the global visualizer.
/// final cfgSub = player.stream.spectrum.listen(processor.setSettings);
/// final tapSub =
///     player.stream.tap(AudioFilter.equalizer, side: TapSide.post)
///         .listen((pcm) {
///       final fft = processor.process(pcm);
///       if (fft != null) painter.bands = fft.bands;
///     });
/// ```
final class BandProcessor {
  /// Creates a processor seeded with the given [SpectrumSettings]. The
  /// FFT engine and scratch buffers stay unallocated until the first
  /// [process] call, so an idle processor costs no memory.
  ///
  /// Throws [ArgumentError] when a field of the settings is out of range,
  /// in a release build too, where the asserts of [SpectrumSettings] are
  /// skipped.
  BandProcessor(this._settings) {
    _settings.validate();
  }

  SpectrumSettings _settings;

  // ── Sample ring (mono) ─────────────────────────────────────────────
  // Rolling buffer of the last `fftSize` mono samples. Each input
  // sample is mixed down to mono on push so the ring has the same
  // length regardless of the source's channel count.
  Float64List? _ring;
  int _ringWrite = 0;
  int _samplesInRing = 0;
  int _samplesUntilNextHop = 0;

  // ── FFT machinery: recreated only on `fftSize` or window changes.
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

  // ── The frame before ───────────────────────────────────────────────
  // A copy of the samples [process] got last, with their format and
  // timestamp: the next frame is laid over them to find its new part.
  Float32List? _last;
  int _lastLength = 0;
  int _lastChannels = 0;
  int _lastSampleRate = 0;
  Duration _lastTimestamp = Duration.zero;

  // The most-recent raw bin power vector: the consumer-facing
  // [FftFrame.bins] payload of the next emitted frame. Allocated
  // once (size = fftSize / 2) and overwritten every FFT.
  Float32List? _rawBins;

  /// Replaces the configuration. Reallocates only the buffers that
  /// depend on changed fields (FFT size, window or band layout).
  /// Smoothing is reset on band-count change so the bands don't
  /// inherit stale heights from a different layout.
  ///
  /// Throws [ArgumentError] when a field of [next] is out of range, and
  /// keeps the configuration it had.
  void setSettings(SpectrumSettings next) {
    next.validate();
    final fftSizeChanged = next.fftSize != _settings.fftSize;
    final overlapChanged = next.overlapFactor != _settings.overlapFactor;
    final windowChanged = next.window != _settings.window || fftSizeChanged;
    final bandConfigChanged =
        next.bandCount != _settings.bandCount ||
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
      // The ring is empty: the next frame fills it whole.
      _lastLength = 0;
    }
    if (windowChanged) _window = null;
    if (bandConfigChanged || fftSizeChanged) {
      _smoothedBands = null;
      _bandStartBin = null;
      _bandEndBin = null;
    }
    if (overlapChanged) {
      // Overlap change retunes the hop spacing: let the next push
      // re-prime the countdown.
      _samplesUntilNextHop = 0;
    }
  }

  /// Pushes the samples of [frame] the ring does not have yet: all of
  /// them, or only those past the overlap with the frame before (see the
  /// class doc). Returns an [FftFrame] holding the latest smoothed bands
  /// when at least one FFT fired during this call. Returns `null` while
  /// the ring is still priming, and when the new audio did not reach the
  /// next FFT (less than `fftSize / overlapFactor` samples since the
  /// last one). `null` is also returned when the input has invalid
  /// metadata so the caller can simply ignore it.
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

    final firstNew = _firstNewFrame(frame, samplesPerChannel);
    _remember(frame, samplesPerChannel);

    // Push every new input sample (mono-mixed) into the ring. Fire an FFT
    // every `hopSize` samples once the ring has been filled at least
    // once (otherwise the front-edge would carry leftover zeros).
    var didFft = false;
    final invChannels = channels == 1 ? 1.0 : 1.0 / channels;
    for (var i = firstNew; i < samplesPerChannel; i++) {
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
      // A NaN or an infinity (an unstable filter, a corrupt float file)
      // would turn every bin of the next FFTs into NaN, and the smoothing
      // would keep the bands NaN for good. Read it as silence.
      if (!mono.isFinite) mono = 0;
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

  /// Keeps a copy of the [frames] whole frames of [frame] for the next
  /// call ([_firstNewFrame]). A copy: the caller may reuse its buffer.
  void _remember(PcmFrame frame, int frames) {
    final length = frames * frame.channels;
    var last = _last;
    if (last == null || last.length < length) {
      last = _last = Float32List(length);
    }
    last.setRange(0, length, frame.samples);
    _lastLength = length;
    _lastChannels = frame.channels;
    _lastSampleRate = frame.sampleRate;
    _lastTimestamp = frame.timestamp;
  }

  /// The index of the first frame of [frame] (of [frames] frames) the
  /// ring does not have: where it stops repeating the end of the frame
  /// before. 0 when the whole frame is new.
  ///
  /// The timestamps say about how much audio is new: they are exact for
  /// pieces of one stream, and close for a tap, whose clock is not the
  /// samples'. So they only say where to look. The proof is the samples:
  /// the start of [frame] must equal, value by value, the end of the
  /// frame before. Offsets are tried from the one the timestamps give,
  /// outwards. For silence or a periodic signal several offsets fit, and
  /// each of them leaves the ring with the same audio.
  ///
  /// The whole frame is new when there is no frame before or its format
  /// differs, when the timestamp did not advance, when it advanced by the
  /// length of the frame or more, and when no offset fits (a seek, a new
  /// track, audio the tap missed).
  int _firstNewFrame(PcmFrame frame, int frames) {
    final last = _last;
    final channels = frame.channels;
    if (last == null ||
        _lastLength == 0 ||
        channels != _lastChannels ||
        frame.sampleRate != _lastSampleRate) {
      return 0;
    }
    final elapsed = (frame.timestamp - _lastTimestamp).inMicroseconds;
    if (elapsed <= 0) return 0;
    final guess = (elapsed * frame.sampleRate / Duration.microsecondsPerSecond)
        .round();
    if (guess >= frames) return 0;

    // With n new frames, the first `frames - n` repeat the end of the
    // frame before, which has to hold that many.
    final least = math.max(1, frames - _lastLength ~/ channels);
    final most = frames - 1;
    if (least > most) return 0;
    final n = _newFramesNear(
      frame.samples,
      frames,
      channels,
      guess.clamp(least, most),
      least,
      most,
    );
    return n == null ? 0 : frames - n;
  }

  /// How many of the [frames] frames of [samples] are new: the count
  /// from [least] to [most] nearest to [center] at which the frames
  /// before them repeat the end of the frame before. `null` when none
  /// does.
  int? _newFramesNear(
    Float32List samples,
    int frames,
    int channels,
    int center,
    int least,
    int most,
  ) {
    // A bound on the compares of counts that fit at first and fail later
    // (long runs of one value): past it the frame is taken whole.
    var budget = 8 * frames * channels;
    for (var d = 0; center - d >= least || center + d <= most; d++) {
      // Below the center, then above it.
      for (var n = center - d; n <= center + d; n += 2 * d) {
        if (n >= least && n <= most) {
          final length = (frames - n) * channels;
          final same = _repeated(samples, length);
          if (same == length) return n;
          budget -= same;
          if (budget < 0) return null;
        }
        if (d == 0) break;
      }
    }
    return null;
  }

  /// How many of the first [length] values of [samples] equal, one by
  /// one, the last [length] of the frame before: [length] when all do.
  /// 0 at once when one of three values spread over them differs, which
  /// refuses nearly every placement that does not fit.
  int _repeated(Float32List samples, int length) {
    final last = _last!;
    final base = _lastLength - length;
    final middle = length >> 1;
    if (samples[0] != last[base] ||
        samples[length - 1] != last[base + length - 1] ||
        samples[middle] != last[base + middle]) {
      return 0;
    }
    var i = 0;
    while (i < length && samples[i] == last[base + i]) {
      i++;
    }
    return i;
  }

  void _runFftOnRing(int sampleRate, int fftSize) {
    final ring = _ring!;
    final windowed = _windowed!;
    final buffer = _buffer!;
    final window = _window!;
    final fft = _fft!;

    // Read the ring in time order: oldest sample is at [_ringWrite],
    // newest is at [(_ringWrite − 1) mod fftSize]. Apply the configured
    // window while copying so the next loop is one mul + one store per
    // sample.
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
    // `fftSize`: equivalent here since the input is real-valued and
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
      if (!(n >= 0)) n = 0; // NaN too
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
