// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:typed_data';

/// One FFT frame — a frequency-domain snapshot of the audio currently
/// playing through the player's output.
///
/// Emitted on [PlayerStream.fft] at the rate configured in
/// [SpectrumSettings.emitInterval] (default ~30 Hz). Each frame carries
/// both the **raw FFT bins** (linear frequency axis, post-window
/// magnitude, normalised to `[0, 1]`) and the **perceptual bands**
/// (log-spaced bucketing of the bins with asymmetric EMA smoothing —
/// the visualizer staple). Most callers only need [bands]; [bins] is
/// exposed for custom remappings (mel, Bark, constant-Q).
///
/// The frame is immutable and thread-safe to pass between isolates —
/// the underlying [Float32List]s are not aliased into the audio thread's
/// ring buffer; they were copied out before this object was constructed.
///
/// Example — paint a 64-bar spectrum analyzer:
///
/// ```dart
/// player.stream.fft.listen((frame) {
///   for (var i = 0; i < frame.bands.length; i++) {
///     final h = frame.bands[i] * canvasHeight;
///     // draw bar i with height h …
///   }
/// });
/// ```
class FftFrame {
  /// Creates a frame. Only used internally by the spectrum pipeline.
  const FftFrame({
    required this.bins,
    required this.bands,
    required this.timestamp,
    required this.sampleRate,
    required this.bandLowHz,
    required this.bandHighHz,
  });

  /// Magnitude per FFT bin, normalised to `[0, 1]` after the
  /// power → log → clip → normalise pipeline. Length is half of
  /// [SpectrumSettings.fftSize] (the real FFT only returns the
  /// positive-frequency half). Bin `i` covers `i * sampleRate / fftSize`
  /// Hz. No smoothing is applied here — it runs on [bands] only.
  ///
  /// Use [bands] for the typical visualizer; [bins] is for custom
  /// frequency-axis remappings (mel, Bark, constant-Q, peak detection).
  final Float32List bins;

  /// Per-band magnitude on the configured perceptual axis (default:
  /// log-spaced 64 bands from [bandLowHz] to [bandHighHz]). Length is
  /// [SpectrumSettings.bandCount].
  ///
  /// Each entry is in `[0, 1]`. Hand straight to a `CustomPainter`
  /// rendering bars, blobs, radial waves — no further smoothing is
  /// needed.
  final Float32List bands;

  /// Playback position the samples backing this FFT correspond to —
  /// derived from mpv's tap timestamp (`pts_ns` on the `pcm-tap-frame`
  /// property). Useful for syncing visual effects against the audio
  /// playhead.
  final Duration timestamp;

  /// Sample rate of the audio that produced this frame, in Hz.
  /// Multiply [bins] indices by `sampleRate / fftSize` to map a bin
  /// to its centre frequency.
  final int sampleRate;

  /// Lower edge of the band axis in Hz. Matches
  /// [SpectrumSettings.bandLowHz].
  final double bandLowHz;

  /// Upper edge of the band axis in Hz. Matches
  /// [SpectrumSettings.bandHighHz].
  final double bandHighHz;
}
