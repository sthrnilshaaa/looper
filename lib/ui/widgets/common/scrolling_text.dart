import 'package:flutter/material.dart';
import 'package:marqueer/marqueer.dart';

class ScrollingText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double? height;
  final TextAlign textAlign;

  const ScrollingText({
    super.key,
    required this.text,
    required this.style,
    this.height,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout();

        if (textPainter.width > constraints.maxWidth) {
          // Not a guessed fontSize * 1.5 - that under-measures scripts like
          // Devanagari, which need more vertical room than Latin text at the
          // same font size (ascent/descent plus vowel signs above and below
          // the baseline), so the Marqueer child ended up taller than this
          // SizedBox allowed and overflowed by a few pixels on non-Latin
          // lyrics/titles. textPainter is already laid out for this exact
          // text+style above, so its measured height is exact.
          return SizedBox(
            height: height ?? textPainter.height,
            child: Marqueer(
              pps: 30.0,
              infinity: true,
              direction: MarqueerDirection.rtl,
              autoStart: true,
              autoStartAfter: const Duration(seconds: 3),

              child: Padding(
                padding: const EdgeInsets.only(right: 40.0),
                child: Text(
                  text,
                  style: style,
                  textAlign: textAlign,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
          );
        } else {
          return Text(
            text,
            style: style,
            textAlign: textAlign,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }
      },
    );
  }
}
