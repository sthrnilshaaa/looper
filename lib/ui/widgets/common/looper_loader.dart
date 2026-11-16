import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:looper_player/core/utils/motion.dart';

/// The app's loading mark: four rounded equalizer bars rising and falling as
/// one wave in the accent colour. Code-drawn (no Lottie), so it is crisp at
/// any size from a 12dp pill glyph to a page loader, costs one ticker, and
/// isolates its repaints. With Reduce Motion it holds still.
class LooperLoader extends StatefulWidget {
  const LooperLoader({super.key, this.size = 40, this.color});

  /// Width and height of the square it draws in.
  final double size;

  /// Defaults to the theme's primary (accent) colour.
  final Color? color;

  @override
  State<LooperLoader> createState() => _LooperLoaderState();
}

class _LooperLoaderState extends State<LooperLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reducedOf(context)) {
      _controller
        ..stop()
        ..value = 0.3;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color color = widget.color ?? Theme.of(context).colorScheme.primary;
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(painter: _BarsPainter(_controller, color)),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.t, this.color) : super(repaint: t);

  final Animation<double> t;
  final Color color;

  static const int bars = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    // Bars take 60 % of the width, gaps the rest.
    final double barW = w * 0.6 / bars;
    final double gap = (w - barW * bars) / (bars + 1);
    final Radius r = Radius.circular(barW / 2);
    final Paint paint = Paint()..isAntiAlias = true;
    for (int i = 0; i < bars; i++) {
      // One travelling wave across the bars: each lags the last by a
      // quarter cycle. Heights stay within 28-100 % so it never looks idle.
      final double phase = (t.value - i / bars) * 2 * math.pi;
      final double k = 0.5 + 0.5 * math.sin(phase);
      final double barH = h * (0.28 + 0.72 * k);
      final double left = gap + i * (barW + gap);
      final Rect rect = Rect.fromLTWH(left, (h - barH) / 2, barW, barH);
      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(color, Colors.white, 0.35)!,
          color.withValues(alpha: 0.75),
        ],
      ).createShader(rect);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, r), paint);
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.color != color || old.t != t;
}
