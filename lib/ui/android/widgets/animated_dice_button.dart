import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/utils/motion.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AnimatedDiceButton extends StatefulWidget {
  final VoidCallback onTap;
  final double size;
  final Color? color;
  final String? tooltip;
  final EdgeInsetsGeometry padding;

  const AnimatedDiceButton({
    super.key,
    required this.onTap,
    this.size = 20.0,
    this.color,
    this.tooltip,
    this.padding = const EdgeInsets.all(8.0),
  });

  @override
  State<AnimatedDiceButton> createState() => _AnimatedDiceButtonState();
}

class _AnimatedDiceButtonState extends State<AnimatedDiceButton>
    with TickerProviderStateMixin {
  late final AnimationController _rollController;
  late final Animation<double> _rollAnimation;
  late final AnimationController _pressController;
  late final Animation<double> _pressAnimation;

  @override
  void initState() {
    super.initState();
    _rollController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _rollAnimation = CurvedAnimation(
      parent: _rollController,
      curve: Curves.easeInOutCubic,
    );

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _pressAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _rollController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _pressController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _pressController.reverse();
    _triggerTap();
  }

  void _onTapCancel() {
    _pressController.reverse();
  }

  void _triggerTap() {
    AppHaptics.light();
    widget.onTap();
    if (!mounted) return;
    final reduced = Motion.reducedOf(context);
    if (!reduced) {
      _rollController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? Colors.white;
    final reduced = Motion.reducedOf(context);

    Widget iconWidget = Icon(
      LucideIcons.dices,
      size: widget.size,
      color: effectiveColor,
    );

    if (!reduced) {
      iconWidget = AnimatedBuilder(
        animation: _rollAnimation,
        builder: (context, child) {
          final t = _rollAnimation.value;
          final angle = t * 2 * math.pi;
          final flip = math.sin(t * math.pi) * 0.45;
          final bounceScale = 1.0 + (math.sin(t * math.pi) * 0.18);

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002)
              ..scale(bounceScale, bounceScale)
              ..rotateZ(angle)
              ..rotateY(flip),
            child: child,
          );
        },
        child: iconWidget,
      );
    }

    Widget button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _pressAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _pressAnimation.value, child: child);
        },
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.06),
          ),
          child: iconWidget,
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }

    return Material(color: Colors.transparent, child: button);
  }
}
