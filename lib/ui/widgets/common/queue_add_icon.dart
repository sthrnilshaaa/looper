import 'package:flutter/material.dart';

/// Looper's add-to-queue mark: stepped queue lines with a round badge holding a
/// plus, or a check once the song is [queued].
class QueueAddIcon extends StatelessWidget {
  const QueueAddIcon({
    super.key,
    this.size = 20,
    this.color,
    this.queued = false,
  });

  final double size;
  final Color? color;
  final bool queued;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? Colors.white;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _QueueAddPainter(c, queued)),
    );
  }
}

class _QueueAddPainter extends CustomPainter {
  _QueueAddPainter(this.color, this.queued);

  final Color color;
  final bool queued;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final line = Paint()
      ..color = color
      ..strokeWidth = 2.2 * s
      ..strokeCap = StrokeCap.round;
    // Queue lines, shortening to make room for the badge.
    canvas.drawLine(Offset(3 * s, 6 * s), Offset(19 * s, 6 * s), line);
    canvas.drawLine(Offset(3 * s, 11.5 * s), Offset(11 * s, 11.5 * s), line);
    canvas.drawLine(Offset(3 * s, 17 * s), Offset(8 * s, 17 * s), line);

    // Badge: a filled disc with the mark knocked out of it.
    final center = Offset(16.5 * s, 16 * s);
    final r = 6 * s;
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawCircle(center, r, Paint()..color = color);
    final cut = Paint()
      ..blendMode = BlendMode.clear
      ..strokeWidth = 1.9 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    if (queued) {
      final path = Path()
        ..moveTo(center.dx - 2.6 * s, center.dy + 0.2 * s)
        ..lineTo(center.dx - 0.6 * s, center.dy + 2.2 * s)
        ..lineTo(center.dx + 2.8 * s, center.dy - 1.8 * s);
      canvas.drawPath(path, cut);
    } else {
      final a = 2.7 * s;
      canvas.drawLine(center - Offset(a, 0), center + Offset(a, 0), cut);
      canvas.drawLine(center - Offset(0, a), center + Offset(0, a), cut);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_QueueAddPainter old) =>
      old.color != color || old.queued != queued;
}
