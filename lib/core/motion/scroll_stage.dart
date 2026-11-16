import 'package:flutter/widgets.dart';

import 'package:looper_player/core/utils/motion.dart';

/// One frame of a scroll-driven stage, derived only from the scroll offset,
/// so scrolling back plays every phase exactly in reverse.
@immutable
class StagePhase {
  const StagePhase({
    required this.scale,
    required this.opacity,
    required this.dy,
  });

  static const StagePhase rest = StagePhase(scale: 1, opacity: 1, dy: 0);

  final double scale;
  final double opacity;

  /// Extra downward shift against the scroll (positive = lags behind it).
  final double dy;

  /// Phases over [length] px of scroll:
  /// - pulled past the top (negative offset): grows a little with the pull,
  ///   pinned to the top so it stretches with the list;
  /// - 0..length: stays on stage - moves up at [lag] of the scroll speed -
  ///   while it shrinks to [endScale] and fades out over the last 60 %.
  static StagePhase at(
    double offset,
    double length, {
    double lag = 0.45,
    double endScale = 0.86,
  }) {
    if (length <= 0) return rest;
    if (offset < 0) {
      final double pull = -offset;
      return StagePhase(
        scale: 1 + (pull / length * 0.35).clamp(0.0, 0.18),
        opacity: 1,
        dy: offset / 2,
      );
    }
    final double sp = (offset / length).clamp(0.0, 1.0);
    final double fade = ((sp - 0.4) / 0.6).clamp(0.0, 1.0);
    return StagePhase(
      scale: 1 - (1 - endScale) * Curves.easeOutCubic.transform(sp),
      opacity: 1 - Curves.easeInCubic.transform(fade),
      dy: offset.clamp(0.0, length) * lag,
    );
  }
}

/// Puts [child] on a sticky stage driven by [controller]'s scroll offset
/// ([StagePhase.at]). Paint-only (transform + opacity), isolated in a
/// RepaintBoundary so scrolling never relays out the list.
class ScrollStage extends StatelessWidget {
  const ScrollStage({
    super.key,
    required this.controller,
    required this.length,
    required this.child,
  });

  final ScrollController controller;
  final double length;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Motion.reducedOf(context)) return child;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final double offset = controller.hasClients
            ? controller.positions.last.pixels
            : 0.0;
        final StagePhase phase = StagePhase.at(offset, length);
        return Opacity(
          opacity: phase.opacity,
          child: Transform.translate(
            offset: Offset(0, phase.dy),
            child: Transform.scale(
              scale: phase.scale,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          ),
        );
      },
      child: RepaintBoundary(child: child),
    );
  }
}
