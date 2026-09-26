import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:looper_player/core/theme/app_icons.dart';

/// Shared scale+fade transition used by every animated transport icon below,
/// in place of the built-in `AnimatedIcon` glyph morph (which only works
/// with Flutter's own bundled AnimatedIconData, not custom SVG assets).
Widget _transportIconSwitcher({
  required Widget child,
  required Duration duration,
}) {
  return AnimatedSwitcher(
    duration: duration,
    switchInCurve: Curves.easeOutBack,
    switchOutCurve: Curves.easeIn,
    // Grows from 0.6, not 0: scaling from nothing read as the icon blinking
    // out and back in rather than morphing.
    transitionBuilder: (child, animation) => ScaleTransition(
      scale: Tween<double>(begin: 0.6, end: 1.0).animate(animation),
      child: FadeTransition(opacity: animation, child: child),
    ),
    child: child,
  );
}

/// Animated swap between the app's own play/pause SVG assets
/// ([AppIcons.play] / [AppIcons.pause]). Cross-fades and scales the
/// outgoing/incoming icon instead of a true path-morph, which reads just as
/// smoothly for a two-icon swap.
class AnimatedPlayPauseIcon extends StatelessWidget {
  final bool isPlaying;
  final double size;
  final Color color;
  final Duration duration;

  const AnimatedPlayPauseIcon({
    super.key,
    required this.isPlaying,
    required this.size,
    required this.color,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return _transportIconSwitcher(
      duration: duration,
      child: SvgPicture.asset(
        isPlaying ? AppIcons.pause : AppIcons.play,
        key: ValueKey<bool>(isPlaying),
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        width: size,
        height: size,
      ),
    );
  }
}

/// Press "pulse" for an icon that doesn't swap assets on tap (next/previous):
/// a quick dip to 0.78 and an overshooting return to full size. It replays
/// whenever [triggerKey] changes, so pass a counter that this specific
/// button's own `onTap` bumps - each button (prev/next) needs its own
/// counter. Keying both buttons off a shared value like the current song's
/// id would replay both animations together whenever either is pressed.
///
/// (It used to swap the icon through an AnimatedSwitcher that scaled it from
/// 0, so every tap blinked the icon out and back in.)
class AnimatedTransportIcon extends StatefulWidget {
  final String asset;
  final double size;
  final Color color;
  final Object? triggerKey;
  final Duration duration;

  const AnimatedTransportIcon({
    super.key,
    required this.asset,
    required this.size,
    required this.color,
    required this.triggerKey,
    this.duration = const Duration(milliseconds: 280),
  });

  @override
  State<AnimatedTransportIcon> createState() => _AnimatedTransportIconState();
}

class _AnimatedTransportIconState extends State<AnimatedTransportIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1.0,
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.78,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.78,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 65,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(AnimatedTransportIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (widget.triggerKey != oldWidget.triggerKey) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: SvgPicture.asset(
        widget.asset,
        colorFilter: ColorFilter.mode(widget.color, BlendMode.srcIn),
        width: widget.size,
        height: widget.size,
      ),
    );
  }
}
