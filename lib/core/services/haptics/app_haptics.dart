import 'dart:io';

import 'package:flutter/services.dart';

/// The single entry point for every haptic in the app.
///
/// Widgets call a named event (`AppHaptics.light()`, `AppHaptics.success()`,
/// ...) instead of Flutter's [HapticFeedback], so one switch in settings
/// silences everything and every event's strength is tuned in one place.
///
/// On Android each event is a short list of [_Pulse]s handed to the app's own
/// native player (TouchHaptics.kt), because the haptic plugins hard-code
/// pulse strengths that feel too heavy for taps that repeat all the time. It
/// plays them as scaled primitives where the motor has them, as an amplitude
/// waveform otherwise, and as one system tick on motors with no strength
/// control - always tagged as touch feedback, so the system "touch feedback"
/// switch and intensity still apply.
///
/// Everywhere else (desktop) the event falls back to Flutter's
/// [HapticFeedback]. Every call is fire-and-forget and never throws.
class AppHaptics {
  AppHaptics._();

  /// Mirrors the "Haptic feedback" setting. Kept static so the ~200 call
  /// sites (many in plain widgets without a `ref`) need no provider access;
  /// the settings notifier writes it whenever settings load or change.
  static bool enabled = true;

  /// Mirrors the haptic strength setting: 0 = Low (the tuning below, as
  /// designed), 1 = Medium, 2 = High. Scales every pulse's strength,
  /// capped at what the motor can do.
  static int strength = 0;

  static const List<double> _strengthScale = [1.0, 1.6, 2.3];

  static const _channel = MethodChannel('com.looper.player/haptics');

  /// Nothing to warm up any more; kept so startup code needs no change.
  static void init() {}

  /// Small, frequent touches: list taps, chips, menu items.
  static void light() =>
      _play(const [_Pulse.tick(30, ms: 10, amplitude: 50)], _lightImpact);

  /// The faintest touch, for taps that repeat constantly (navigation bar
  /// tabs, fast-scroll letters).
  static void tick() =>
      _play(const [_Pulse.tick(20, ms: 8, amplitude: 35)], _selectionClick);

  /// Confirming a choice: toggles, primary buttons, sheet actions. Also the
  /// strongest single pulse the app plays - there is deliberately no heavy
  /// event, weighty actions (resets, destructive confirmations) use this too.
  static void medium() =>
      _play(const [_Pulse.click(35, ms: 12, amplitude: 85)], _mediumImpact);

  /// A value stepping while dragging: sliders, pickers, segmented rows.
  static void selection() =>
      _play(const [_Pulse.tick(25, ms: 8, amplitude: 40)], _selectionClick);

  /// A crisp click when something locks into place (a slider snapping to
  /// zero or a detent).
  static void snap() =>
      _play(const [_Pulse.click(45, ms: 10, amplitude: 105)], _mediumImpact);

  /// A gentle bump for soft UI (reveals, drag handles): one round, low tap.
  static void soft() =>
      _play(const [_Pulse.low(45, ms: 18, amplitude: 40)], _lightImpact);

  /// A task finished well: saved, imported, restored. A soft tap that lands
  /// on a firmer one, so it reads as "done".
  static void success() => _play(const [
    _Pulse.low(40, ms: 16, amplitude: 45),
    _Pulse.click(50, ms: 12, amplitude: 105, gap: 65),
  ], _mediumImpact);

  /// Something needs attention but nothing failed. Two even, unhurried taps -
  /// a nudge with no resolution, unlike [success].
  static void warning() => _play(const [
    _Pulse.click(40, ms: 12, amplitude: 90),
    _Pulse.click(40, ms: 12, amplitude: 90, gap: 120),
  ], _mediumImpact);

  /// Something failed. A quick double knock that drops into a dull tap, so
  /// it feels like bouncing off rather than landing.
  static void error() => _play(const [
    _Pulse.click(45, ms: 10, amplitude: 100),
    _Pulse.click(45, ms: 10, amplitude: 100, gap: 40),
    _Pulse.low(55, ms: 22, amplitude: 55, gap: 70),
  ], _mediumImpact);

  /// Liking a song: a "lub-dub" heartbeat, a round beat then a sharper one.
  static void heartbeat() => _play(const [
    _Pulse.low(50, ms: 20, amplitude: 55),
    _Pulse.click(55, ms: 14, amplitude: 115, gap: 85),
  ], _mediumImpact);

  static Future<void> _lightImpact() => HapticFeedback.lightImpact();
  static Future<void> _mediumImpact() => HapticFeedback.mediumImpact();
  static Future<void> _selectionClick() => HapticFeedback.selectionClick();

  static void _play(List<_Pulse> pulses, Future<void> Function() desktop) {
    if (!enabled) return;
    _run(() async {
      if (!Platform.isAndroid) return desktop();
      final double k = _strengthScale[strength.clamp(0, 2)];
      await _channel.invokeMethod<void>('play', {
        'pulses': [for (final p in pulses) p.encode(k)],
      });
    });
  }

  static void _run(Future<void> Function() body) {
    body().catchError((_) {});
  }
}

/// One pulse of an event. [scale] (percent of the motor's tuned primitive) is
/// what plays on motors with primitives; [ms] at [amplitude] (1-255) is the
/// equivalent for motors with only amplitude control. [gap] is the pause in
/// milliseconds before the pulse.
class _Pulse {
  const _Pulse.tick(this.scale, {required this.ms, required this.amplitude})
    : primitive = 0,
      gap = 0;

  /// A rounder, lower-pitched tap; a plain tick on motors without it.
  const _Pulse.low(
    this.scale, {
    required this.ms,
    required this.amplitude,
    this.gap = 0,
  }) : primitive = 2;

  const _Pulse.click(
    this.scale, {
    required this.ms,
    required this.amplitude,
    this.gap = 0,
  }) : primitive = 1;

  final int primitive;
  final int scale;
  final int ms;
  final int amplitude;
  final int gap;

  /// [k] scales the strength: the primitive scale (percent, max 100) and the
  /// waveform amplitude (max 255); durations and gaps stay the same.
  List<int> encode([double k = 1.0]) => [
    gap,
    ms,
    (amplitude * k).round().clamp(1, 255),
    primitive,
    (scale * k).round().clamp(1, 100),
  ];
}
