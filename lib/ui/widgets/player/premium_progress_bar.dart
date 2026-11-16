import 'package:flutter/material.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'squiggly_slider/slider.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:looper_player/features/settings/domain/progress_bar_style.dart';

class ExpressiveSlider extends ConsumerStatefulWidget {
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final ValueChanged<Duration> onSeek;
  final VoidCallback? onSeekStart;
  final VoidCallback? onSeekEnd;
  final Color color;
  final bool showTimestamps;

  /// Overrides the style from settings - used by the settings preview to
  /// show unsaved changes live. Ignored on Linux, which keeps its own look.
  final ProgressBarStyle? style;

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
    this.style,
  });

  /// Whether this is the desktop (Linux/Windows) bar with its own fixed look.
  /// Overridable so tests (which run on Linux) can reach the Android bar.
  @visibleForTesting
  static bool useDesktopLayout = UiUtils.isDesktop;

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
          fontWeight: UiUtils.isDesktop ? FontWeight.w300 : FontWeight.w600,
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
              // Digits roll through a clip: no fade, because a fading digit
              // is a GPU save-layer, and the clock changed every second -
              // most of the player screen's per-frame layers came from here.
              return ClipRect(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0.0, isIn ? 1.0 : -1.0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              char,
              key: ValueKey(char),
              style: AppFonts.jostStyle(
                color: Colors.white,
                fontWeight: UiUtils.isDesktop
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

  void _onChanged(double val) {
    setState(() => _dragValue = val);
    widget.onSeek(widget.duration * val);
  }

  void _onChangeStart(double val) {
    setState(() => _dragValue = val);
    widget.onSeekStart?.call();
  }

  void _onChangeEnd(double val) {
    setState(() => _dragValue = null);
    widget.onSeekEnd?.call();
  }

  /// The desktop (Linux) bar: fixed look, not affected by the progress bar
  /// style settings apart from the flat-bar toggle.
  Widget _buildLinuxSlider(double displayValue) {
    final disableSquiggle = ref.watch(
      settingsProvider.select((s) => s.disableSquiggle),
    );
    final bool enableWave = widget.isPlaying && displayValue > 0.12;
    final targetAmplitude = disableSquiggle ? 0.0 : (enableWave ? 2.0 : 0.0);
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3.0,
        activeTrackColor: widget.color,
        inactiveTrackColor: Colors.white10,
        thumbShape: const LineThumbShape(thumbHeight: 12, thumbWidth: 3),
        overlayShape: SliderComponentShape.noOverlay,
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: targetAmplitude),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
        builder: (context, amplitude, child) {
          return SquigglySlider(
            value: displayValue,
            onChanged: _onChanged,
            onChangeStart: _onChangeStart,
            onChangeEnd: _onChangeEnd,
            activeColor: widget.color,
            inactiveColor: Colors.white10,
            squiggleAmplitude: amplitude,
            squiggleWavelength: 4.5,
            squiggleSpeed: 0.08,
            useLineThumb: false,
          );
        },
      ),
    );
  }

  Widget _buildStyledSlider(double displayValue, ProgressBarStyle style) {
    final bool pastStart = style.waveFromStart || displayValue > 0.12;
    final bool showWave =
        style.wave && pastStart && (widget.isPlaying || style.freezeWhenPaused);
    final double targetAmplitude = showWave ? style.waveHeight : 0.0;
    final Color inactive = Colors.white.withValues(
      alpha: style.inactiveOpacity,
    );
    final double thumbWidth = switch (style.thumbStyle) {
      ProgressThumbStyle.pill => style.thumbWidth,
      ProgressThumbStyle.round => style.thumbHeight,
      ProgressThumbStyle.none => 0,
    };
    final double thumbHeight = style.thumbStyle == ProgressThumbStyle.none
        ? 0
        : style.thumbHeight;

    // Fixed at the default bar's height (its 16dp thumb) whatever the style,
    // so thicker bars, taller thumbs or no thumb never move the player's
    // layout - bigger parts just paint past it (nothing up the tree clips).
    return SizedBox(
      height: ProgressBarStyle.defaultThumbHeight,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: style.thickness,
          activeTrackColor: widget.color,
          inactiveTrackColor: inactive,
          thumbShape: LineThumbShape(
            thumbHeight: thumbHeight,
            thumbWidth: thumbWidth,
            growOnDrag: style.growThumbOnDrag,
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
              onChanged: _onChanged,
              onChangeStart: _onChangeStart,
              onChangeEnd: _onChangeEnd,
              activeColor: widget.color,
              inactiveColor: inactive,
              squiggleAmplitude: amplitude,
              squiggleWavelength: style.squiggleWavelength,
              squiggleSpeed: style.waveSpeed,
              squiggleAnimating: widget.isPlaying,
              thumbGap: style.thumbGap,
              useLineThumb: false,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double progress = widget.duration.inMilliseconds > 0
        ? (widget.position.inMilliseconds / widget.duration.inMilliseconds)
              .clamp(0.0, 1.0)
        : 0.0;

    final displayValue = _dragValue ?? progress;
    final displayPosition = _dragValue != null
        ? widget.duration * _dragValue!
        : widget.position;

    final sliderWidget = ExpressiveSlider.useDesktopLayout
        ? _buildLinuxSlider(displayValue)
        : _buildStyledSlider(
            displayValue,
            widget.style ??
                ref.watch(
                  settingsProvider.select(ProgressBarStyle.fromSettings),
                ),
          );

    if (ExpressiveSlider.useDesktopLayout) {
      // In a narrow window the two timestamps alone are wider than the bar's
      // slot: drop them and keep the slider.
      return LayoutBuilder(
        builder: (context, constraints) {
          final showTimestamps =
              widget.showTimestamps && constraints.maxWidth >= 180;
          return Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showTimestamps) ...[
                _buildAnimatedDuration(_formatDuration(displayPosition), false),
                const SizedBox(width: 12),
              ],
              Expanded(child: sliderWidget),
              if (showTimestamps) ...[
                const SizedBox(width: 12),
                _buildAnimatedDuration(_formatDuration(widget.duration), true),
              ],
            ],
          );
        },
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

  /// Grow the thumb a little while it's being dragged.
  final bool growOnDrag;

  const LineThumbShape({
    this.thumbHeight = 12,
    this.thumbWidth = 2,
    this.growOnDrag = false,
  });

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
    if (thumbWidth <= 0 || thumbHeight <= 0) return;
    final double grow = growOnDrag ? 1 + 0.35 * activationAnimation.value : 1;
    final Canvas canvas = context.canvas;
    final Paint paint = Paint()
      ..color = sliderTheme.thumbColor ?? Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: thumbWidth * grow,
          height: thumbHeight * grow,
        ),
        Radius.circular(thumbWidth * grow / 2),
      ),
      paint,
    );
  }
}
