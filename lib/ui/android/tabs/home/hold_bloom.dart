import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Damped wobble for the settle: 0 at t=0, rings twice, dies out.
double holdJelly(double t) => math.exp(-4.5 * t) * math.sin(t * math.pi * 4.5);

/// The page's swell: a slight dip toward the finger while holding, then a
/// small rise and settle as the ripples spread, like a water surface.
double holdPageScale(double hold, double bloom) => bloom > 0
    ? 1 -
          0.012 * (1 - (bloom / 0.15).clamp(0.0, 1.0)) +
          0.006 * holdJelly(bloom)
    : 1 - 0.012 * Curves.easeOutCubic.transform(hold);

/// The finger's thin ring for the 5 s reorder hold, then a water-drop
/// ripple.
///
/// [hold] 0..1: a thin ring around [origin] that fills clockwise.
/// [bloom] 0..1: after the hold fires, a drop lands on still water at
/// [origin]: a small splash, then thin rings spread out one after another,
/// fading as they travel.
class HoldDrop extends StatelessWidget {
  const HoldDrop({
    super.key,
    required this.origin,
    required this.hold,
    required this.bloom,
    required this.accent,
  });

  final Offset origin;
  final double hold;
  final double bloom;
  final Color accent;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.infinite,
    painter: _DropPainter(
      origin: origin,
      hold: hold,
      bloom: bloom,
      accent: accent,
    ),
  );
}

class _DropPainter extends CustomPainter {
  _DropPainter({
    required this.origin,
    required this.hold,
    required this.bloom,
    required this.accent,
  });

  final Offset origin;
  final double hold, bloom;
  final Color accent;

  static const double ringRadius = 30;
  static const int ripples = 4;
  // Each ripple starts this much later (in bloom units) than the one before.
  static const double rippleGap = 0.11;

  @override
  void paint(Canvas canvas, Size size) {
    if (bloom <= 0) {
      if (hold > 0) _paintHoldRing(canvas);
      return;
    }
    _paintRipples(canvas, size);
  }

  void _paintHoldRing(Canvas canvas) {
    final appear = (hold / 0.1).clamp(0.0, 1.0);
    // Tightens a little as it fills, like a drop gathering.
    final r = ringRadius - 4 * Curves.easeIn.transform(hold);
    final rect = Rect.fromCircle(center: origin, radius: r);
    canvas.drawCircle(
      origin,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.18 * appear),
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * hold,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = accent.withValues(alpha: appear),
    );
  }

  void _paintRipples(Canvas canvas, Size size) {
    final far = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((c) => (c - origin).distance).reduce(math.max);

    // The splash: the drop's impact point flashes and shrinks away.
    final splash = (1 - bloom / 0.18).clamp(0.0, 1.0);
    if (splash > 0) {
      canvas.drawCircle(
        origin,
        (ringRadius - 4) * splash,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.55 * splash),
              accent.withValues(alpha: 0.35 * splash),
              accent.withValues(alpha: 0),
            ],
            stops: const [0, 0.6, 1],
          ).createShader(Rect.fromCircle(center: origin, radius: ringRadius)),
      );
    }

    for (var i = 0; i < ripples; i++) {
      final start = i * rippleGap;
      final span = 1 - start;
      final t = ((bloom - start) / span).clamp(0.0, 1.0);
      if (t <= 0 || t >= 1) continue;
      // Ripples slow as they spread; later ones are weaker and don't
      // travel as far, as on real water.
      final reach = far * (1 - 0.12 * i);
      final r =
          (ringRadius - 4) +
          (reach - ringRadius) * Curves.easeOutCubic.transform(t);
      final strength = (1 - i * 0.2) * math.pow(1 - t, 1.4).toDouble();
      final width = 2.2 - 1.2 * t;
      // A bright crest with a soft trough just inside it.
      canvas.drawCircle(
        origin,
        r - width * 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * 3
          ..color = accent.withValues(alpha: 0.10 * strength),
      );
      canvas.drawCircle(
        origin,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..color = Color.lerp(
            accent,
            Colors.white,
            0.35,
          )!.withValues(alpha: 0.9 * strength),
      );
    }
  }

  @override
  bool shouldRepaint(_DropPainter old) =>
      old.origin != origin ||
      old.hold != hold ||
      old.bloom != bloom ||
      old.accent != accent;
}
