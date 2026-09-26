import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show listEquals;

class EqualizerCurvePainter extends CustomPainter {
  final List<double> gains;
  final Color color;

  EqualizerCurvePainter({required this.gains, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (gains.length < 2) return;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()..style = PaintingStyle.fill;

    final path = Path();
    final colWidth = size.width / gains.length;

    final trackTop = 8.0;
    final trackBottom = size.height - 8.0;
    final trackHeight = trackBottom - trackTop;

    double getMappedY(double gain) {
      final percent = ((gain + 20) / 40).clamp(0.0, 1.0);
      final thumbBottom = percent * trackHeight;
      return trackBottom - thumbBottom;
    }

    double getMappedX(int index) {
      return (index + 0.5) * colWidth;
    }

    path.moveTo(getMappedX(0), getMappedY(gains[0]));

    for (int i = 0; i < gains.length - 1; i++) {
      final x1 = getMappedX(i);
      final y1 = getMappedY(gains[i]);
      final x2 = getMappedX(i + 1);
      final y2 = getMappedY(gains[i + 1]);

      final stepX = x2 - x1;
      final cx1 = x1 + stepX / 2;
      final cy1 = y1;
      final cx2 = x2 - stepX / 2;
      final cy2 = y2;

      path.cubicTo(cx1, cy1, cx2, cy2, x2, y2);
    }

    // Shadow glow
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    canvas.drawPath(path, paint);

    // Fill under path
    final fillPath = Path.from(path)
      ..lineTo(getMappedX(gains.length - 1), trackBottom)
      ..lineTo(getMappedX(0), trackBottom)
      ..close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.0)],
    );
    fillPaint.shader = gradient.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(EqualizerCurvePainter oldDelegate) {
    // gains is a freshly-built sublist() on every call site, so comparing
    // with != (identity, for a plain List) was always true regardless of
    // whether the visible curve actually changed - listEquals compares the
    // values instead, so an unrelated EqualizerState change (e.g. toggling
    // an effect that isn't one of these 18 bands) no longer repaints.
    return !listEquals(oldDelegate.gains, gains) || oldDelegate.color != color;
  }
}
