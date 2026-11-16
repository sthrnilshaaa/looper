import 'dart:ui';

/// Pure geometry helpers for mapping frequency band gains to canvas coordinates
/// and constructing smooth cubic bezier curves for equalizer painters.
class EqualizerCurveGeometry {
  final double colWidth;
  final double trackTop;
  final double trackBottom;
  final double trackHeight;

  EqualizerCurveGeometry({
    required double width,
    required double height,
    required int bandCount,
    this.trackTop = 8.0,
    double bottomPadding = 8.0,
  })  : colWidth = width / bandCount,
        trackBottom = height - bottomPadding,
        trackHeight = (height - bottomPadding) - trackTop;

  double mapY(double gain) {
    final percent = ((gain + 20) / 40).clamp(0.0, 1.0);
    final thumbBottom = percent * trackHeight;
    return trackBottom - thumbBottom;
  }

  double mapX(int index) => (index + 0.5) * colWidth;

  Path buildCubicPath(List<double> values) {
    final p = Path();
    if (values.isEmpty) return p;
    p.moveTo(mapX(0), mapY(values[0]));
    for (int i = 0; i < values.length - 1; i++) {
      final x1 = mapX(i);
      final y1 = mapY(values[i]);
      final x2 = mapX(i + 1);
      final y2 = mapY(values[i + 1]);
      final stepX = x2 - x1;
      p.cubicTo(x1 + stepX / 2, y1, x2 - stepX / 2, y2, x2, y2);
    }
    return p;
  }
}
