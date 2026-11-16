import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'equalizer_curve_math.dart';

class EqualizerCurvePainter extends CustomPainter {
  final List<double> gains;
  final Color color;
  final List<double>? autoEqGains;

  EqualizerCurvePainter({
    required this.gains,
    required this.color,
    this.autoEqGains,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (gains.length < 2) return;

    final geo = EqualizerCurveGeometry(
      width: size.width,
      height: size.height,
      bandCount: gains.length,
      trackTop: 8.0,
      bottomPadding: 8.0,
    );

    // 1. AutoEQ dashed curve (doc 21 §1.7)
    if (autoEqGains != null && autoEqGains!.length >= gains.length) {
      final autoEqPath = geo.buildCubicPath(autoEqGains!);
      final dashPaint = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      for (final metric in autoEqPath.computeMetrics()) {
        double dist = 0.0;
        while (dist < metric.length) {
          final len = math.min(5.0, metric.length - dist);
          canvas.drawPath(metric.extractPath(dist, dist + len), dashPaint);
          dist += 5.0 + 4.0;
        }
      }
    }

    // 2. User's EQ solid curve
    final path = geo.buildCubicPath(gains);

    // Shadow glow
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);

    // Fill under path
    final fillPath = Path.from(path)
      ..lineTo(geo.mapX(gains.length - 1), geo.trackBottom)
      ..lineTo(geo.mapX(0), geo.trackBottom)
      ..close();

    final fillPaint = Paint()..style = PaintingStyle.fill;
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.0)],
    );
    fillPaint.shader = gradient.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );
    canvas.drawPath(fillPath, fillPaint);

    // 3. Combined curve (sum of user EQ + AutoEQ, drawn as thin line)
    if (autoEqGains != null && autoEqGains!.length >= gains.length) {
      final sumGains = List.generate(gains.length, (i) {
        return (gains[i] + autoEqGains![i]).clamp(-20.0, 20.0);
      });
      final sumPath = geo.buildCubicPath(sumGains);
      canvas.drawPath(
        sumPath,
        Paint()
          ..color = color.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(EqualizerCurvePainter oldDelegate) {
    return !listEquals(oldDelegate.gains, gains) ||
        !listEquals(oldDelegate.autoEqGains, autoEqGains) ||
        oldDelegate.color != color;
  }
}
