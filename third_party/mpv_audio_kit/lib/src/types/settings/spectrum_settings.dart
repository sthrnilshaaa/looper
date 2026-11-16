// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../enums/window_function.dart';

/// Configuration for the real-time FFT spectrum + raw PCM streams.
///
/// Apply atomically via [Player.setSpectrum] (replace the whole
/// bundle) or [Player.updateSpectrum] (mutate one or more fields with
/// a copyWith mapper). Read live via [PlayerStream.spectrum] and
/// [PlayerStream.pcm].
///
/// The streams are **lazy** — the FFT pipeline allocates and the FFI
/// poll loop starts only on the first listener, and tears down on
/// the last cancel. A subscriber to either [PlayerStream.spectrum]
/// or [PlayerStream.pcm] alone is enough to arm the pipeline; both
/// streams share the same upstream tap.
///
/// Default values pick a balanced "music visualizer" preset:
/// 2048-point Hann FFT at 30 Hz emit rate, log-spaced 64 bands from
/// 20 Hz to 20 kHz, asymmetric EMA (fast attack, slow decay) and a
/// `[-70, -10] dB` clip range that looks lively on most music. Tweak
/// from there.
final class SpectrumSettings {
  /// FFT size in samples. Power of 2 between 256 and 4096. Larger
  /// = better frequency resolution at the cost of time resolution
  /// (a 2048-point FFT @ 48 kHz spans 42.7 ms of audio). 2048 is
  /// the visualizer sweet spot — sub-50 Hz resolution to separate
  /// kick fundamentals from sub-bass, latency below the ~80 ms
  /// A/V sync threshold.
  final int fftSize;

  /// Number of perceptual bands the [FftFrame.bands] field is
  /// bucketed into. Typical 32 / 64 / 128. Bands are log-spaced
  /// from [bandLowHz] to [bandHighHz] — geometric edges, ratio
  /// `(bandHighHz / bandLowHz)^(1 / bandCount)` per band.
  final int bandCount;

  /// Lower edge of the band axis, in Hz. Default 20 Hz (bottom of
  /// human hearing).
  final double bandLowHz;

  /// Upper edge of the band axis, in Hz. Default 20 kHz (top of
  /// human hearing). Clamped at FFT time to the Nyquist limit
  /// (`sampleRate / 2`).
  final double bandHighHz;

  /// Window function applied to each FFT block before transform.
  /// See [WindowFunction] for the trade-offs. Default Hann is the
  /// universal music-visualizer choice.
  final WindowFunction window;

  /// Time between [FftFrame] / [PcmFrame] emissions. 33 ms ≈ 30 fps
  /// (default), 16 ms ≈ 60 fps. Range 8 ms (~120 fps) to 67 ms
  /// (~15 fps); the pipeline is gated by this independently of the
  /// FFT block rate.
  final Duration emitInterval;

  /// EMA smoothing coefficient applied when a band's new value is
  /// **higher** than the previous frame. Range `[0, 1]`; higher =
  /// snappier attack. 0.5 default — visualizer pops with transients
  /// (kicks, snare hits) without flickering on noise.
  final double attackSmoothing;

  /// EMA smoothing coefficient applied when a band's new value is
  /// **lower** than the previous frame. Range `[0, 1]`; lower =
  /// slower decay ("afterglow"). 0.1 default. Asymmetric attack /
  /// release is the standard choice — symmetric EMA is simultaneously
  /// sluggish on transients AND jittery on decays.
  final double releaseSmoothing;

  /// Lower edge of the dB clip range mapped to band value 0.0.
  /// Anything below [minDb] reads as silent. -100 dB default — matches
  /// the Web Audio API `AnalyserNode.minDecibels` default and gives
  /// quiet passages room to breathe at the bottom of the visualizer.
  final double minDb;

  /// Upper edge of the dB clip range mapped to band value 1.0.
  /// Anything above [maxDb] saturates at 1.0. -30 dB default — matches
  /// the Web Audio API `AnalyserNode.maxDecibels` default. Modern
  /// loudness-war masters animate in the upper range with peaks
  /// touching the top on transients; quieter classical material
  /// occupies the lower range without bottoming out.
  final double maxDb;

  /// Overlap-add factor for the FFT loop. `1` runs a single FFT per
  /// emit on the latest [fftSize] samples (snappy, no interpolation
  /// between blocks). `4` (default) runs four FFTs spaced
  /// `fftSize / 4` samples apart — the classic 75 % overlap, visibly
  /// smoother visualizer motion at no extra latency. Higher values
  /// trade CPU for smoother curves; values must be powers of two so
  /// `fftSize / overlapFactor` is an integer hop.
  final int overlapFactor;

  /// Creates a spectrum-analyzer configuration. Defaults yield the
  /// [defaults] preset; asserts enforce each field's valid range.
  const SpectrumSettings({
    this.fftSize = 2048,
    this.bandCount = 64,
    this.bandLowHz = 20.0,
    this.bandHighHz = 20000.0,
    this.window = WindowFunction.hann,
    this.emitInterval = const Duration(milliseconds: 33),
    this.attackSmoothing = 0.5,
    this.releaseSmoothing = 0.1,
    this.minDb = -100.0,
    this.maxDb = -30.0,
    this.overlapFactor = 4,
  })  : assert(fftSize >= 256 && fftSize <= 4096,
            'fftSize must be in [256, 4096]',),
        assert(
            (fftSize & (fftSize - 1)) == 0, 'fftSize must be a power of two',),
        assert(bandCount > 0, 'bandCount must be positive'),
        assert(bandLowHz > 0, 'bandLowHz must be positive'),
        assert(bandHighHz > bandLowHz,
            'bandHighHz must be strictly greater than bandLowHz',),
        assert(attackSmoothing >= 0 && attackSmoothing <= 1,
            'attackSmoothing must be in [0, 1]',),
        assert(releaseSmoothing >= 0 && releaseSmoothing <= 1,
            'releaseSmoothing must be in [0, 1]',),
        assert(maxDb > minDb, 'maxDb must be strictly greater than minDb'),
        assert(overlapFactor >= 1 && overlapFactor <= 16,
            'overlapFactor must be in [1, 16]',),
        assert((overlapFactor & (overlapFactor - 1)) == 0,
            'overlapFactor must be a power of two',);

  /// Default visualizer preset — 2048 Hann FFT at 30 fps with 64
  /// log-spaced bands. Convenience `setSpectrum(SpectrumSettings.defaults)`
  /// to reset.
  static const SpectrumSettings defaults = SpectrumSettings();

  /// Returns a copy with the given fields replaced. Omitted fields keep
  /// their current value.
  SpectrumSettings copyWith({
    int? fftSize,
    int? bandCount,
    double? bandLowHz,
    double? bandHighHz,
    WindowFunction? window,
    Duration? emitInterval,
    double? attackSmoothing,
    double? releaseSmoothing,
    double? minDb,
    double? maxDb,
    int? overlapFactor,
  }) =>
      SpectrumSettings(
        fftSize: fftSize ?? this.fftSize,
        bandCount: bandCount ?? this.bandCount,
        bandLowHz: bandLowHz ?? this.bandLowHz,
        bandHighHz: bandHighHz ?? this.bandHighHz,
        window: window ?? this.window,
        emitInterval: emitInterval ?? this.emitInterval,
        attackSmoothing: attackSmoothing ?? this.attackSmoothing,
        releaseSmoothing: releaseSmoothing ?? this.releaseSmoothing,
        minDb: minDb ?? this.minDb,
        maxDb: maxDb ?? this.maxDb,
        overlapFactor: overlapFactor ?? this.overlapFactor,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SpectrumSettings &&
          other.fftSize == fftSize &&
          other.bandCount == bandCount &&
          other.bandLowHz == bandLowHz &&
          other.bandHighHz == bandHighHz &&
          other.window == window &&
          other.emitInterval == emitInterval &&
          other.attackSmoothing == attackSmoothing &&
          other.releaseSmoothing == releaseSmoothing &&
          other.minDb == minDb &&
          other.maxDb == maxDb &&
          other.overlapFactor == overlapFactor);

  @override
  int get hashCode => Object.hash(
        fftSize,
        bandCount,
        bandLowHz,
        bandHighHz,
        window,
        emitInterval,
        attackSmoothing,
        releaseSmoothing,
        minDb,
        maxDb,
        overlapFactor,
      );

  @override
  String toString() => 'SpectrumSettings(fftSize: $fftSize, '
      'bandCount: $bandCount, bandLowHz: $bandLowHz, bandHighHz: $bandHighHz, '
      'window: $window, emitInterval: $emitInterval, '
      'attackSmoothing: $attackSmoothing, releaseSmoothing: $releaseSmoothing, '
      'minDb: $minDb, maxDb: $maxDb, overlapFactor: $overlapFactor)';
}
