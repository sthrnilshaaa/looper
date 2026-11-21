import 'dart:async';

import 'package:looper_player/core/utils/motion.dart';
import 'package:flutter/material.dart';

const double _gap = 40;

class ScrollingText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double? height;
  final TextAlign textAlign;

  /// Sizes every line by [style]'s own font alone, whatever glyphs the
  /// text contains. Otherwise a line grows to fit its tallest fallback
  /// font (emoji, CJK, other scripts), so a layout built around it shifts
  /// from song to song. Glyphs reaching past the line box still paint.
  final bool lockLineHeight;

  const ScrollingText({
    super.key,
    required this.text,
    required this.style,
    this.height,
    this.textAlign = TextAlign.start,
    this.lockLineHeight = false,
  });

  @override
  Widget build(BuildContext context) {
    final TextScaler textScaler = MediaQuery.textScalerOf(context);
    final StrutStyle? strut = lockLineHeight
        ? StrutStyle.fromTextStyle(style, forceStrutHeight: true)
        : null;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Measured exactly as the Text below is drawn (same scale, strut
        // and direction), so the scroll-or-fit decision and the marquee's
        // height match the static text's.
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
          textScaler: textScaler,
          strutStyle: strut,
        )..layout();
        final bool overflows = textPainter.width > constraints.maxWidth;
        final double measuredHeight = textPainter.height;
        final double travel = textPainter.width + _gap;
        textPainter.dispose();

        // With system animations off the title is ellipsized like any other
        // long text.
        if (overflows && !Motion.reducedOf(context)) {
          // Not a guessed fontSize * 1.5 - that under-measures scripts like
          // Devanagari, which need more vertical room than Latin text at the
          // same font size (ascent/descent plus vowel signs above and below
          // the baseline), so the marquee child ended up taller than this
          // SizedBox allowed and overflowed by a few pixels on non-Latin
          // lyrics/titles. textPainter is already laid out for this exact
          // text+style above, so its measured height is exact.
          // Readable as one fixed label; the scrolling copies stay
          // out of the accessibility tree, or its moving geometry was
          // recomputed every frame whenever an accessibility service is on.
          return Semantics(
            label: text,
            child: ExcludeSemantics(
              child: SizedBox(
                height: height ?? measuredHeight,
                child: RepaintBoundary(
                  child: _OnePassMarquee(
                    key: ValueKey('$text|$travel'),
                    travel: travel,
                    child: Padding(
                      padding: const EdgeInsets.only(right: _gap),
                      child: Text(
                        text,
                        style: style,
                        strutStyle: strut,
                        textAlign: textAlign,
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        } else {
          return Text(
            text,
            style: style,
            strutStyle: strut,
            textAlign: textAlign,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }
      },
    );
  }
}

/// Scrolls [child] once, then rests: every marquee frame also redraws any
/// backdrop blur behind it, so an endless one kept the GPU busy all song.
class _OnePassMarquee extends StatefulWidget {
  const _OnePassMarquee({super.key, required this.travel, required this.child});

  final double travel;
  final Widget child;

  @override
  State<_OnePassMarquee> createState() => _OnePassMarqueeState();
}

class _OnePassMarqueeState extends State<_OnePassMarquee>
    with SingleTickerProviderStateMixin {
  static const double _pixelsPerSecond = 30;

  late final AnimationController _scroll = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds: (widget.travel / _pixelsPerSecond * 1000).round(),
    ),
  );
  late final Timer _start = Timer(
    const Duration(seconds: 3),
    () => _scroll.forward(),
  );

  @override
  void initState() {
    super.initState();
    _start;
  }

  @override
  void dispose() {
    _start.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.centerLeft,
        minWidth: 0,
        maxWidth: double.infinity,
        child: AnimatedBuilder(
          animation: _scroll,
          builder: (context, row) => Transform.translate(
            offset: Offset(-_scroll.value * widget.travel, 0),
            child: row,
          ),
          // The second copy lands exactly where the first began, so the
          // resting text looks the same as before the scroll.
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.ltr,
            children: [widget.child, widget.child],
          ),
        ),
      ),
    );
  }
}
