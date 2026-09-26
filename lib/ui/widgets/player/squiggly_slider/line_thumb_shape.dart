import 'package:flutter/material.dart';

/// A variant of the default circle thumb shape
/// Similar to the one found in Android 13 Media control
class LineThumbShape extends SliderComponentShape {
  /// The size of the thumb
  final Size thumbSize;

  const LineThumbShape({this.thumbSize = const Size(8, 32)});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return thumbSize;
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    assert(sliderTheme.disabledThumbColor != null);
    assert(sliderTheme.thumbColor != null);

    final colorTween = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.thumbColor,
    );

    final paint = Paint()..color = colorTween.evaluate(enableAnimation)!;

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: thumbSize.width,
          height: thumbSize.height,
        ),
        Radius.circular(thumbSize.width),
      ),
      paint,
    );
  }
}
