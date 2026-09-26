import 'package:flutter/material.dart' hide RepeatMode;
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:google_fonts/google_fonts.dart';

class SleepTimerClock extends StatelessWidget {
  final double progress;
  final String label;
  final Color color;

  const SleepTimerClock({
    super.key,
    required this.progress,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double size = 28.s;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _SleepTimerClockPainter(progress: progress, color: color),
          ),
          Text(
            label,
            style: GoogleFonts.jost(
              fontSize: 8.5.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SleepTimerClockPainter extends CustomPainter {
  final double progress;
  final Color color;

  _SleepTimerClockPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 2.0) / 2;

    // Draw background circle track
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, bgPaint);

    // Draw active progress arc clockwise starting from top (-pi / 2)
    if (progress > 0) {
      final activePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      const startAngle = -3.141592653589793 / 2;
      final sweepAngle = 2 * 3.141592653589793 * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SleepTimerClockPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
