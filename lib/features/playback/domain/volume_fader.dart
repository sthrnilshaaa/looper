import 'dart:async';

/// Animates a 0..1 gain factor that is multiplied into the user's volume,
/// so a fade never has to remember (or overwrite) the volume it is fading
/// toward, and a volume change mid-fade is not lost.
///
/// Progress is driven by elapsed wall-clock time rather than a fixed step
/// count, so a 10ms fade really takes ~10ms and a timer that fires late
/// doesn't stretch the fade out.
class VolumeFader {
  VolumeFader(
    this._onChanged, {
    Duration tick = const Duration(milliseconds: 16),
  }) : _tick = tick;

  final void Function(double factor) _onChanged;
  final Duration _tick;

  double _factor = 1.0;
  Timer? _timer;
  Completer<bool>? _completer;

  double get factor => _factor;
  bool get isFading => _timer != null;

  /// Jumps straight to [factor], cancelling any fade in progress.
  void set(double factor) {
    _cancel();
    _factor = factor.clamp(0.0, 1.0);
    _onChanged(_factor);
  }

  /// Fades from the current factor to [target] over [duration].
  ///
  /// Completes with `true` once the fade finishes, or `false` if it was
  /// superseded by another [fadeTo]/[set]/[cancel] call - callers that act
  /// after a fade (e.g. pause once faded out) must skip that action then.
  Future<bool> fadeTo(double target, Duration duration) {
    _cancel();
    target = target.clamp(0.0, 1.0);
    if (duration <= Duration.zero || _factor == target) {
      _factor = target;
      _onChanged(_factor);
      return Future.value(true);
    }

    final start = _factor;
    final totalUs = duration.inMicroseconds;
    final watch = Stopwatch()..start();
    final completer = _completer = Completer<bool>();
    _timer = Timer.periodic(_tick, (timer) {
      final t = (watch.elapsedMicroseconds / totalUs).clamp(0.0, 1.0);
      _factor = start + (target - start) * t;
      _onChanged(_factor);
      if (t >= 1.0) {
        timer.cancel();
        _timer = null;
        _completer = null;
        completer.complete(true);
      }
    });
    return completer.future;
  }

  /// Stops any fade in progress, leaving the factor where it currently is.
  void cancel() => _cancel();

  void _cancel() {
    _timer?.cancel();
    _timer = null;
    final pending = _completer;
    _completer = null;
    if (pending != null && !pending.isCompleted) pending.complete(false);
  }
}
