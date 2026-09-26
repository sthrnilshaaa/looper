import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';

class PremiumSection extends ConsumerWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final bool isSelected;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final bool useExpanded;
  final Color? backgroundColor;
  final int flex;
  final String? heroTag;
  final bool showLeftBorder;
  final bool showRightBorder;
  final bool showBorder;
  final bool showShadow;
  final double blurAmount;
  final bool useBlur;
  final bool forceNoBlur;
  final bool forceBlur;
  final bool keepSurfaceOnDisableBlur;
  final bool animate;

  final bool useCenter;
  final bool forceTransparent;

  /// Start the press-down scale on raw pointer-down instead of on the tap
  /// recognizer's onTapDown. Under an ancestor drag recognizer (the Fluid
  /// Player's pan) onTapDown is held back until kPressTimeout (100ms), so a
  /// quick tap showed almost no feedback. Off by default: in scrollables it
  /// would flash the press on every scroll start.
  final bool instantPressFeedback;

  const PremiumSection({
    super.key,
    required this.child,
    required this.borderRadius,
    this.onTap,
    this.isSelected = false,
    this.height,
    this.width,
    this.padding,
    this.useExpanded = true,
    this.backgroundColor,
    this.flex = 1,
    this.heroTag,
    this.showLeftBorder = true,
    this.showRightBorder = true,
    this.showBorder = true,
    this.showShadow = false,
    this.blurAmount = 3,
    this.useBlur = false,
    this.forceNoBlur = false,
    this.forceBlur = false,
    this.keepSurfaceOnDisableBlur = false,
    this.animate = false,
    this.useCenter = true,
    this.forceTransparent = false,
    this.instantPressFeedback = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool disableBlur = ref.watch(
      settingsProvider.select((s) => s.disableBlur),
    );

    // Detect if we are transitioning (route or tab transitions)
    final ModalRoute<dynamic>? parentRoute = ModalRoute.of(context);
    final bool isRouteTransitioning =
        parentRoute != null &&
        (parentRoute.animation?.status == AnimationStatus.forward ||
            parentRoute.animation?.status == AnimationStatus.reverse ||
            parentRoute.secondaryAnimation?.status == AnimationStatus.forward ||
            parentRoute.secondaryAnimation?.status == AnimationStatus.reverse);
    final bool isTabTransitioning = TransitionStatusProvider.of(context);
    final bool isTransitioning = isRouteTransitioning || isTabTransitioning;

    final bool isBlurActive =
        (useBlur || forceBlur) && !disableBlur && !isTransitioning;

    final borderSide = BorderSide(
      color: Colors.white.withValues(alpha: 0.05),
      width: showBorder ? 0.8 : 0,
    );

    final decoration = forceTransparent
        ? const BoxDecoration(color: Colors.transparent)
        : BoxDecoration(
            color:
                backgroundColor ??
                (isBlurActive
                    ? Colors.white.withValues(alpha: 0.05)
                    : ((useBlur || forceBlur)
                          ? (isTransitioning
                                ? Colors.black.withValues(alpha: 0.12)
                                : (disableBlur && !keepSurfaceOnDisableBlur
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainer))
                          : Theme.of(context).colorScheme.surfaceContainer)),
            borderRadius: borderRadius,
            border: showBorder
                ? Border(
                    top: borderSide,
                    bottom: borderSide,
                    left: showLeftBorder ? borderSide : BorderSide.none,
                    right: showRightBorder ? borderSide : BorderSide.none,
                  )
                : null,
            boxShadow: showShadow
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          );

    Widget containerBody = animate
        ? AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            height: height,
            width: width,
            padding: padding,
            decoration: decoration,
            child: useCenter ? Center(child: child) : child,
          )
        : Container(
            height: height,
            width: width,
            padding: padding,
            decoration: decoration,
            child: useCenter ? Center(child: child) : child,
          );

    final bool enableBlur = isBlurActive && !forceNoBlur && !forceTransparent;

    if (enableBlur) {
      containerBody = RepaintBoundary(
        child: ClipRRect(
          borderRadius: borderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: blurAmount.clamp(0.0, 16.0),
              sigmaY: blurAmount.clamp(0.0, 16.0),
            ),
            child: containerBody,
          ),
        ),
      );
    }

    Widget content;
    if (onTap != null) {
      content = _PremiumBouncyTap(
        onTap: onTap!,
        instantPressFeedback: instantPressFeedback,
        child: containerBody,
      );
    } else {
      content = containerBody;
    }

    if (heroTag != null) {
      content = Hero(
        tag: heroTag!,
        child: Material(type: MaterialType.transparency, child: content),
      );
    }

    if (useExpanded) {
      return Expanded(flex: flex, child: content);
    }
    return content;
  }
}

class _PremiumBouncyTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool instantPressFeedback;

  const _PremiumBouncyTap({
    required this.child,
    required this.onTap,
    this.instantPressFeedback = false,
  });

  @override
  State<_PremiumBouncyTap> createState() => _PremiumBouncyTapState();
}

class _PremiumBouncyTapState extends State<_PremiumBouncyTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Press generations: pointer-up and onTapUp can both release the same
  // press, and a new press can start before the last release finished -
  // each press is released exactly once, and a stale release never undoes a
  // newer press.
  int _pressGen = 0;
  int _releasedGen = -1;

  void _press() {
    _pressGen++;
    _controller.forward();
  }

  // Lets a quick tap still show the whole press: finish pressing in, then
  // spring back, instead of reversing a barely-started animation.
  void _release() {
    if (_releasedGen == _pressGen) return;
    _releasedGen = _pressGen;
    final int gen = _pressGen;
    if (_controller.status == AnimationStatus.forward) {
      _controller.forward().whenCompleteOrCancel(() {
        if (mounted && gen == _pressGen) _controller.reverse();
      });
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget detector = GestureDetector(
      onTapDown: widget.instantPressFeedback ? null : (_) => _press(),
      onTapUp: (_) {
        _release();
        widget.onTap();
      },
      onTapCancel: _release,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
    if (!widget.instantPressFeedback) return detector;
    // Listener isn't in the gesture arena, so it fires on the very first
    // pointer event. Its up/cancel also cover the case where a drag wins
    // before the tap recognizer ever sent onTapDown (no onTapCancel then).
    return Listener(
      onPointerDown: (_) => _press(),
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: detector,
    );
  }
}

class TransitionStatusProvider extends InheritedWidget {
  final bool isTransitioning;

  const TransitionStatusProvider({
    super.key,
    required this.isTransitioning,
    required super.child,
  });

  static bool of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<TransitionStatusProvider>();
    return provider?.isTransitioning ?? false;
  }

  @override
  bool updateShouldNotify(TransitionStatusProvider oldWidget) {
    return oldWidget.isTransitioning != isTransitioning;
  }
}
