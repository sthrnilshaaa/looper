import 'dart:io';
import 'package:flutter/material.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'squiggly_slider/slider.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/core/utils/ui_utils.dart';

class ExpressiveSlider extends ConsumerStatefulWidget {
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final ValueChanged<Duration> onSeek;
  final VoidCallback? onSeekStart;
  final VoidCallback? onSeekEnd;
  final Color color;
  final bool showTimestamps;

  const ExpressiveSlider({
    super.key,
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.onSeek,
    this.onSeekStart,
    this.onSeekEnd,
    required this.color,
    this.showTimestamps = true,
  });

  @override
  ConsumerState<ExpressiveSlider> createState() => _ExpressiveSliderState();
}

class _ExpressiveSliderState extends ConsumerState<ExpressiveSlider> {
  double? _dragValue;

  String _formatDuration(Duration duration) {
    return UiUtils.formatPlaybackDuration(
      duration,
      showHours: widget.duration.inHours > 0,
    );
  }

  Widget _buildAnimatedDuration(String durationStr, bool isRightAligned) {
    final settings = ref.watch(settingsProvider);
    if (settings.disableAnimatedDuration) {
      return Text(
        durationStr,
        style: AppFonts.jostStyle(
          color: Colors.white,
          fontWeight: Platform.isLinux ? FontWeight.w300 : FontWeight.w600,
          fontSize: 14,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: isRightAligned
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: durationStr.characters.map((char) {
        return SizedBox(
          width: char == ':' ? 5 : 9,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              final isIn = (child as Text).data == char;
              return ClipRect(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0.0, isIn ? 0.5 : -0.5),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
              );
            },
            child: Text(
              char,
              key: ValueKey(char),
              style: AppFonts.jostStyle(
                color: Colors.white,
                fontWeight: Platform.isLinux
                    ? FontWeight.w300
                    : FontWeight.w600,
                fontSize: 12,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final double progress = widget.duration.inMilliseconds > 0
        ? (widget.position.inMilliseconds / widget.duration.inMilliseconds)
              .clamp(0.0, 1.0)
        : 0.0;

    final displayValue = _dragValue ?? progress;
    final bool enableWave = widget.isPlaying && displayValue > 0.12;
    final displayPosition = _dragValue != null
        ? widget.duration * _dragValue!
        : widget.position;

    final targetAmplitude = settings.disableSquiggle
        ? 0.0
        : (enableWave ? 2.0 : 0.0);

    final sliderWidget = SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: Platform.isLinux ? 3.0 : 8.0,
        activeTrackColor: widget.color,
        trackShape: PremiumGapTrackShape(gap: Platform.isLinux ? 4 : 6),
        inactiveTrackColor: Colors.white10,

        thumbShape: LineThumbShape(
          thumbHeight: Platform.isLinux ? 12 : 16,
          thumbWidth: Platform.isLinux ? 3 : 6,
        ),
        overlayShape: SliderComponentShape.noOverlay,
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: targetAmplitude),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
        builder: (context, amplitude, child) {
          return SquigglySlider(
            value: displayValue,
            onChanged: (val) {
              setState(() => _dragValue = val);
              widget.onSeek(widget.duration * val);
            },
            onChangeStart: (val) {
              setState(() => _dragValue = val);
              widget.onSeekStart?.call();
            },
            onChangeEnd: (val) {
              setState(() => _dragValue = null);
              widget.onSeekEnd?.call();
            },
            activeColor: widget.color,
            inactiveColor: Colors.white10,
            squiggleAmplitude: amplitude,
            squiggleWavelength: Platform.isLinux ? 4.5 : 6.0,
            squiggleSpeed: Platform.isLinux ? 0.08 : 0.05,
            useLineThumb: false,
          );
        },
      ),
    );

    if (Platform.isLinux) {
      return Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.showTimestamps) ...[
            _buildAnimatedDuration(_formatDuration(displayPosition), false),
            const SizedBox(width: 12),
          ],
          Expanded(child: sliderWidget),
          if (widget.showTimestamps) ...[
            const SizedBox(width: 12),
            _buildAnimatedDuration(_formatDuration(widget.duration), true),
          ],
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        sliderWidget,
        if (widget.showTimestamps) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAnimatedDuration(_formatDuration(displayPosition), false),
                _buildAnimatedDuration(_formatDuration(widget.duration), true),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class LineThumbShape extends SliderComponentShape {
  final double thumbHeight;
  final double thumbWidth;

  const LineThumbShape({this.thumbHeight = 12, this.thumbWidth = 2});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(thumbWidth, thumbHeight);
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
    final Canvas canvas = context.canvas;
    final Paint paint = Paint()
      ..color = sliderTheme.thumbColor ?? Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: thumbWidth, height: thumbHeight),
        Radius.circular(thumbWidth / 2),
      ),
      paint,
    );
  }
}

class PremiumGapTrackShape extends RoundedRectSliderTrackShape {
  final double gap;

  const PremiumGapTrackShape({this.gap = 6});

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
    double additionalActiveTrackHeight = 0.0,
  }) {
    if (sliderTheme.trackHeight == null || sliderTheme.trackHeight! <= 0) {
      return;
    }

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Paint activePaint = Paint()..color = sliderTheme.activeTrackColor!;

    final Paint inactivePaint = Paint()
      ..color = sliderTheme.inactiveTrackColor!;

    final double trackHeight = sliderTheme.trackHeight!;
    final Radius radius = Radius.circular(trackHeight / 2);

    // ACTIVE TRACK
    final RRect activeRRect = RRect.fromLTRBAndCorners(
      trackRect.left,
      trackRect.top,
      thumbCenter.dx - gap,
      trackRect.bottom,
      topLeft: radius,
      bottomLeft: radius,
      topRight: radius,
      bottomRight: radius,
    );

    // INACTIVE TRACK
    final RRect inactiveRRect = RRect.fromLTRBAndCorners(
      thumbCenter.dx + gap,
      trackRect.top,
      trackRect.right,
      trackRect.bottom,
      topLeft: radius,
      bottomLeft: radius,
      topRight: radius,
      bottomRight: radius,
    );

    context.canvas.drawRRect(activeRRect, activePaint);
    context.canvas.drawRRect(inactiveRRect, inactivePaint);
  }
}
