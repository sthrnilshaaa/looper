// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:typed_data';

/// One PCM frame — raw post-DSP audio samples captured at the player's
/// output, before they're handed to the OS audio driver.
///
/// Emitted on [PlayerStream.pcm] at the rate configured in
/// [SpectrumSettings.emitInterval] (default ~30 Hz). Use this for
/// time-domain visualisations the FFT pipeline can't express:
/// scrolling waveforms, accurate VU/peak meters, oscilloscopes,
/// vectorscopes, custom feature extractors that need raw amplitude.
///
/// For a frequency-domain visualizer (spectrum bars, glow effects),
/// prefer [FftFrame] from [PlayerStream.fft]. The two streams
/// share the same upstream tap, so subscribing to both costs only
/// the duplicate FFT computation, not a second tap.
///
/// Example — a peak-hold VU meter:
///
/// ```dart
/// double peak = 0;
/// player.stream.pcm.listen((frame) {
///   for (final s in frame.samples) {
///     if (s.abs() > peak) peak = s.abs();
///   }
///   peak *= 0.92; // decay
///   _vuController.value = peak;
/// });
/// ```
class PcmFrame {
  /// Creates a frame. Only used internally by the spectrum pipeline.
  const PcmFrame({
    required this.samples,
    required this.timestamp,
    required this.sampleRate,
    required this.channels,
  });

  /// Interleaved Float32 samples in the range `[-1.0, +1.0]`. For
  /// stereo audio the layout is `L, R, L, R, …`; for 5.1 it's
  /// `L, R, C, LFE, Ls, Rs, …`. Length is
  /// `samplesPerChannel * channels`. Total samples per channel:
  /// `samples.length ~/ channels`.
  ///
  /// Owned by this frame — safe to pass to `CustomPainter`, isolate
  /// boundaries, or background processing without copying.
  final Float32List samples;

  /// Wall-clock timestamp at which the audio output captured this
  /// frame. Process-monotonic — derived from libmpv's internal
  /// `mp_time_ns()`, which counts from the moment the engine
  /// initialised, not from the start of the track. Use it to detect
  /// fresh frames or to align side-effects in real time; for the
  /// playback PTS of these samples, read [PlayerStream.position] /
  /// [PlayerStream.audioPts] instead.
  final Duration timestamp;

  /// Sample rate in Hz (typically 44100 or 48000).
  final int sampleRate;

  /// Channel count — 1 for mono, 2 for stereo, 6 for 5.1, etc.
  /// Combine with [samples].length to compute `samplesPerChannel`.
  final int channels;

  /// Convenience: number of samples per channel — `samples.length / channels`.
  int get samplesPerChannel => channels == 0 ? 0 : samples.length ~/ channels;
}
