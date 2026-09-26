import 'dart:math' as math;
import 'dart:typed_data';

/// Turns mpv_audio_kit FFT frames into three calm energy levels (bass, mids,
/// highs) for the animated player gradient.
///
/// The FFT arrives at ~20 Hz and is jumpy even after the plugin's own EMA,
/// so [step] runs once per painted frame and eases each level toward its
/// latest target with a slow attack and an even slower release. The result
/// is a gentle "breathing" signal rather than a meter or a beat detector
/// (tried, and dropped: discrete pulses didn't sit well with the slow
/// visuals). Kept free of Flutter so it can be unit tested.
class GradientAudioEnergy {
  /// Bands below this frequency count as bass.
  static const double bassMaxHz = 180;

  /// Bands below this frequency (and above [bassMaxHz]) count as mids.
  static const double midMaxHz = 2500;

  // Time constants in seconds. Attack is how fast a level rises toward a
  // louder target, release how fast it falls back.
  static const double _attackTau = 0.28;
  static const double _releaseTau = 0.9;
  // Slow running average of the bass, used to pick out swells above the
  // song's usual bass level.
  static const double _averageTau = 3.0;
  // How fast motion speed follows play/pause.
  static const double _speedTau = 0.8;

  double _bassTarget = 0;
  double _midTarget = 0;
  double _highTarget = 0;

  double bass = 0;
  double mid = 0;
  double high = 0;
  double _bassAverage = 0;

  /// Bass rising above its recent average, `[0, 1]`.
  double bassPulse = 0;

  /// Drift speed multiplier: eases to 0 on pause and back up on play.
  double speed = 1;

  /// Overall loudness feel, `[0, 1]`.
  double get energy => bass * 0.45 + mid * 0.35 + high * 0.20;

  /// Feeds one FFT frame's perceptual bands (log-spaced from [lowHz] to
  /// [highHz], as emitted by `FftFrame.bands`).
  void addFrame(Float32List bands, double lowHz, double highHz) {
    final int n = bands.length;
    if (n == 0 || lowHz <= 0 || highHz <= lowHz) return;
    final double ratio = math.pow(highHz / lowHz, 1 / n).toDouble();
    double bassSum = 0, midSum = 0, highSum = 0;
    int bassCount = 0, midCount = 0, highCount = 0;
    double edge = lowHz;
    for (int i = 0; i < n; i++) {
      // Geometric center of band i.
      final double center = edge * math.sqrt(ratio);
      edge *= ratio;
      final double v = bands[i];
      if (center < bassMaxHz) {
        bassSum += v;
        bassCount++;
      } else if (center < midMaxHz) {
        midSum += v;
        midCount++;
      } else {
        highSum += v;
        highCount++;
      }
    }
    _bassTarget = bassCount == 0 ? 0 : bassSum / bassCount;
    _midTarget = midCount == 0 ? 0 : midSum / midCount;
    _highTarget = highCount == 0 ? 0 : highSum / highCount;
  }

  /// Advances the smoothing by [dt] seconds. While not [playing] the FFT
  /// stops emitting, so all targets fall to zero and everything settles.
  void step(double dt, {required bool playing}) {
    if (dt <= 0) return;
    if (!playing) {
      _bassTarget = 0;
      _midTarget = 0;
      _highTarget = 0;
    }
    bass = _ease(bass, _bassTarget, dt);
    mid = _ease(mid, _midTarget, dt);
    high = _ease(high, _highTarget, dt);
    _bassAverage += (bass - _bassAverage) * _k(dt, _averageTau);
    final double pulseTarget = ((bass - _bassAverage) * 2.5).clamp(0.0, 1.0);
    bassPulse = _ease(bassPulse, pulseTarget, dt);
    speed += ((playing ? 1.0 : 0.0) - speed) * _k(dt, _speedTau);
  }

  /// True once paused motion and every level have faded out, so the
  /// caller can stop ticking entirely.
  bool get settled =>
      speed < 0.01 &&
      bass < 0.005 &&
      mid < 0.005 &&
      high < 0.005 &&
      bassPulse < 0.005;

  static double _k(double dt, double tau) => 1 - math.exp(-dt / tau);

  static double _ease(double current, double target, double dt) =>
      current +
      (target - current) * _k(dt, target > current ? _attackTau : _releaseTau);
}
