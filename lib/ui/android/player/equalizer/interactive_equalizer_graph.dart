import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/responsive.dart';
import 'package:looper_player/features/playback/presentation/providers/equalizer/equalizer_notifier.dart';

class InteractiveEqualizerGraph extends ConsumerStatefulWidget {
  final EqualizerState eqState;
  final Equalizer eqNotifier;
  final Color accentColor;

  const InteractiveEqualizerGraph({
    required this.eqState,
    required this.eqNotifier,
    required this.accentColor,
    super.key,
  });

  @override
  ConsumerState<InteractiveEqualizerGraph> createState() =>
      _InteractiveEqualizerGraphState();
}

class _InteractiveEqualizerGraphState
    extends ConsumerState<InteractiveEqualizerGraph> {
  int? _activeDragIndex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final graphHeight = Responsive.isShort(MediaQuery.sizeOf(context))
            ? 200.0
            : 290.0;
        final size = Size(constraints.maxWidth, graphHeight);
        final colWidth = size.width / 18;
        final trackTop = 16.0;
        final trackBottom = size.height - 24.0;
        final trackHeight = trackBottom - trackTop;

        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            if (!widget.eqState.enabled) return;
            HapticFeedback.selectionClick();
            final localPos = event.localPosition;
            final index = (localPos.dx / colWidth).floor().clamp(0, 17);
            setState(() {
              _activeDragIndex = index;
            });
            _updateGain(index, localPos.dy, trackTop, trackBottom, trackHeight);
          },
          onPointerMove: (event) {
            if (_activeDragIndex == null) return;
            final localPos = event.localPosition;
            _updateGain(
              _activeDragIndex!,
              localPos.dy,
              trackTop,
              trackBottom,
              trackHeight,
            );
          },
          onPointerUp: (event) {
            if (_activeDragIndex != null) {
              widget.eqNotifier.applyEqualizerInstant();
              setState(() {
                _activeDragIndex = null;
              });
            }
          },
          onPointerCancel: (event) {
            if (_activeDragIndex != null) {
              widget.eqNotifier.applyEqualizerInstant();
              setState(() {
                _activeDragIndex = null;
              });
            }
          },
          child: Container(
            height: graphHeight,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
            ),
            child: CustomPaint(
              size: size,
              painter: _InteractiveGraphPainter(
                gains: widget.eqState.currentSongGains.sublist(0, 18),
                accentColor: widget.accentColor,
                enabled: widget.eqState.enabled,
                activeDragIndex: _activeDragIndex,
              ),
            ),
          ),
        );
      },
    );
  }

  void _updateGain(
    int index,
    double dy,
    double trackTop,
    double trackBottom,
    double trackHeight,
  ) {
    final localY = dy.clamp(trackTop, trackBottom);
    final percent = (trackBottom - localY) / trackHeight;
    double gain = (percent * 40.0) - 20.0;

    // Snap to zero logic
    if (gain.abs() < 0.8) {
      gain = 0.0;
    }

    widget.eqNotifier.setBandGain(index, gain);
  }
}

class _InteractiveGraphPainter extends CustomPainter {
  final List<double> gains;
  final Color accentColor;
  final bool enabled;
  final int? activeDragIndex;

  _InteractiveGraphPainter({
    required this.gains,
    required this.accentColor,
    required this.enabled,
    this.activeDragIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final colWidth = size.width / 18;
    final trackTop = 16.0;
    final trackBottom = size.height - 24.0;
    final trackHeight = trackBottom - trackTop;

    double getMappedY(double gain) {
      final percent = ((gain + 20) / 40).clamp(0.0, 1.0);
      final thumbBottom = percent * trackHeight;
      return trackBottom - thumbBottom;
    }

    double getMappedX(int index) {
      return (index + 0.5) * colWidth;
    }

    // 1. Draw grid lines (dB)
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    final dashedPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.2;

    const dbValues = [-20.0, -10.0, 0.0, 10.0, 20.0];
    for (final db in dbValues) {
      final y = getMappedY(db);
      if (db == 0.0) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), dashedPaint);
      } else {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }

      // Draw dB Label text
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${db > 0 ? "+" : ""}${db.round()} dB',
          style: AppFonts.jostStyle(
            fontSize: 9,
            color: Colors.white24,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(8, y - textPainter.height - 2));
    }

    // 2. Draw vertical grid/frequencies lines
    const List<String> bands = [
      '65',
      '92',
      '131',
      '185',
      '262',
      '370',
      '523',
      '740',
      '1k',
      '1.4k',
      '2k',
      '2.9k',
      '4.1k',
      '5.9k',
      '8.3k',
      '11.7k',
      '16.6k',
      '20k',
    ];
    for (int i = 0; i < 18; i++) {
      final x = getMappedX(i);
      // Freq vertical line (drawn extremely faintly)
      canvas.drawLine(
        Offset(x, trackTop),
        Offset(x, trackBottom),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.02)
          ..strokeWidth = 1.0,
      );

      // Freq label at bottom
      final textPainter = TextPainter(
        text: TextSpan(
          text: bands[i],
          style: AppFonts.jostStyle(
            fontSize: 8,
            color: enabled ? Colors.white30 : Colors.white12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - 18),
      );
    }

    if (gains.length < 2) return;

    // 3. Draw smooth curve path
    final curveColor = enabled ? accentColor : Colors.grey;
    final path = Path();
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
        ..color = curveColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = curveColor.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Fill under path
    final fillPath = Path.from(path)
      ..lineTo(getMappedX(gains.length - 1), trackBottom)
      ..lineTo(getMappedX(0), trackBottom)
      ..close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        curveColor.withValues(alpha: 0.12),
        curveColor.withValues(alpha: 0.0),
      ],
    );
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );
    canvas.drawPath(fillPath, fillPaint);

    // 4. Draw interactive node handles
    final handlePaint = Paint()
      ..color = curveColor.withValues(alpha: enabled ? 1.0 : 0.4)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < gains.length; i++) {
      final x = getMappedX(i);
      final y = getMappedY(gains[i]);
      final isDragged = i == activeDragIndex;

      if (isDragged && enabled) {
        // Draw selection outer ring
        canvas.drawCircle(
          Offset(x, y),
          12,
          Paint()
            ..color = curveColor.withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }

      // Draw dot handle
      canvas.drawCircle(Offset(x, y), isDragged ? 6.0 : 4.5, handlePaint);

      // Draw inner core
      canvas.drawCircle(
        Offset(x, y),
        isDragged ? 2.5 : 1.8,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _InteractiveGraphPainter oldDelegate) {
    // See the identical note on EqualizerCurvePainter.shouldRepaint above -
    // gains needs a value comparison, not identity, since it's a fresh
    // sublist() every time.
    return !listEquals(oldDelegate.gains, gains) ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.enabled != enabled ||
        oldDelegate.activeDragIndex != activeDragIndex;
  }
}
