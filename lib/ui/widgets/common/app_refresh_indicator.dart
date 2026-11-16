import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:looper_player/core/motion/looper_scroll_physics.dart';
import 'package:looper_player/core/motion/rubber_band.dart';

/// Pull-to-refresh wrapper used across the library screens. The spinner
/// stays pinned for as long as [onRefresh] is still working and is released
/// when it finishes, so it doubles as the "still processing" signal.
///
/// It never shows for less than [_minimumVisible], so a refresh that returns
/// at once still reads as having happened, and a failure in [onRefresh]
/// releases it like a normal finish.
class AppRefreshIndicator extends StatelessWidget {
  static const _minimumVisible = Duration(milliseconds: 350);

  final Widget child;
  final Future<void> Function() onRefresh;

  const AppRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: const Color(0xFF1E1E1E),
      onRefresh: () => Future.wait([
        Future<void>.sync(onRefresh).catchError((_) {}),
        Future<void>.delayed(_minimumVisible),
      ]),
      child: defaultTargetPlatform == TargetPlatform.android
          ? _FingerDistanceRelay(child: child)
          : child,
    );
  }
}

/// RefreshIndicator arms once the list has moved ~17 % of its height past
/// the top, but [LooperScrollPhysics] rubber-bands that overscroll and never
/// lets it pass 12 %. This relays the top-overscroll scroll updates to the
/// indicator in finger distance instead (undoing the rubber band), so the
/// list keeps its feel and refresh triggers after a normal pull.
class _FingerDistanceRelay extends StatelessWidget {
  const _FingerDistanceRelay({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // This context sits above the listener below, so re-dispatching from it
    // reaches the RefreshIndicator without looping back here.
    final BuildContext relay = context;
    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (n) {
        final ScrollMetrics m = n.metrics;
        final double delta = n.scrollDelta ?? 0.0;
        if (delta == 0.0 || m.axis != Axis.vertical) return false;
        final double after = m.pixels;
        final double before = after - delta;
        final double min = m.minScrollExtent;
        if (after >= min && before >= min) return false;
        final double d =
            m.viewportDimension * LooperScrollPhysics.maxStretchFraction;
        double finger(double pixels) =>
            inverseRubberBand(math.max(min - pixels, 0.0), d);
        // Overscroll grows as pixels drop, so the finger delta is negative
        // while pulling down - the same sign convention as scrollDelta.
        final double fingerDelta = -(finger(after) - finger(before));
        ScrollUpdateNotification(
          metrics: m,
          context: n.context ?? relay,
          scrollDelta: fingerDelta,
          dragDetails: n.dragDetails,
          depth: n.depth,
        ).dispatch(relay);
        return true;
      },
      child: child,
    );
  }
}
