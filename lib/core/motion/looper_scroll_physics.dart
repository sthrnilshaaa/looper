import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'rubber_band.dart';

/// The app's one scroll feel on Android: past either end of a list, content
/// follows the finger through [rubberBand] (the same curve as the Fluid
/// Player), and a fling that reaches an end bounces a little into that
/// stretch - capped by the same curve - before settling.
///
/// On other platforms it behaves exactly like [BouncingScrollPhysics], so
/// shared widgets keep their desktop feel.
class LooperScrollPhysics extends BouncingScrollPhysics {
  const LooperScrollPhysics({super.parent, super.decelerationRate});

  /// Most content can be displaced past an end, as a share of the viewport.
  static const double maxStretchFraction = 0.12;

  @override
  LooperScrollPhysics applyTo(ScrollPhysics? ancestor) => LooperScrollPhysics(
    parent: buildParent(ancestor),
    decelerationRate: decelerationRate,
  );

  static bool get _active => defaultTargetPlatform == TargetPlatform.android;

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (!_active) return super.applyPhysicsToUserOffset(position, offset);
    final _Band band = _Band.of(position);
    // Work in "finger space" (overscroll undamped), move by the full
    // finger delta there, then map back. Crossing an edge mid-delta damps
    // only the part past it, and easing back is exact.
    final double finger = band.toFinger(position.pixels) - offset;
    return position.pixels - band.toDisplay(finger);
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if (!_active) return super.createBallisticSimulation(position, velocity);
    final Tolerance tolerance = toleranceFor(position);
    if (velocity.abs() < tolerance.velocity && !position.outOfRange) {
      return null;
    }
    final _Band band = _Band.of(position);
    final double start = band.toFinger(position.pixels);
    final double slope = band.slopeAt(start);
    // Display velocity -> finger-space velocity (the inverse of the band's
    // slope), bounded so a release deep in a stretch stays sane.
    final double rawVelocity = (velocity / (slope <= 0.05 ? 0.05 : slope))
        .clamp(-maxFlingVelocity * 2, maxFlingVelocity * 2)
        .toDouble();
    return _BandedSimulation(
      BouncingScrollSimulation(
        spring: spring,
        position: start,
        velocity: rawVelocity,
        leadingExtent: position.minScrollExtent,
        trailingExtent: position.maxScrollExtent,
        tolerance: tolerance,
        constantDeceleration: switch (decelerationRate) {
          ScrollDecelerationRate.fast => 1400,
          ScrollDecelerationRate.normal => 0,
        },
      ),
      band,
    );
  }
}

/// Maps between real scroll pixels and finger-space pixels for one scroll
/// position: identical inside the content, rubber-banded past either end.
@immutable
class _Band {
  const _Band(this.min, this.max, this.d);

  factory _Band.of(ScrollMetrics p) => _Band(
    p.minScrollExtent,
    p.maxScrollExtent,
    p.viewportDimension * LooperScrollPhysics.maxStretchFraction,
  );

  final double min;
  final double max;
  final double d;

  double toFinger(double pixels) {
    if (pixels < min) return min - inverseRubberBand(min - pixels, d);
    if (pixels > max) return max + inverseRubberBand(pixels - max, d);
    return pixels;
  }

  double toDisplay(double finger) {
    if (finger < min) return min - rubberBand(min - finger, d);
    if (finger > max) return max + rubberBand(finger - max, d);
    return finger;
  }

  double slopeAt(double finger) {
    if (finger < min) return rubberBandSlope(min - finger, d);
    if (finger > max) return rubberBandSlope(finger - max, d);
    return 1.0;
  }
}

/// Runs a scroll simulation in finger space and shows it through the band,
/// so a fling's overshoot at an end is damped by the same curve as a drag.
class _BandedSimulation extends Simulation {
  _BandedSimulation(this.raw, this.band) : super(tolerance: raw.tolerance);

  final Simulation raw;
  final _Band band;

  @override
  double x(double time) => band.toDisplay(raw.x(time));

  @override
  double dx(double time) => raw.dx(time) * band.slopeAt(raw.x(time));

  @override
  bool isDone(double time) => raw.isDone(time);
}

/// App scroll behavior: [LooperScrollPhysics] by default, and no Android
/// stretch/glow on top of it (the stretch is the content itself).
class LooperScrollBehavior extends MaterialScrollBehavior {
  const LooperScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    if (getPlatform(context) == TargetPlatform.android) {
      return const LooperScrollPhysics(parent: RangeMaintainingScrollPhysics());
    }
    return super.getScrollPhysics(context);
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    if (getPlatform(context) == TargetPlatform.android) return child;
    return super.buildOverscrollIndicator(context, child, details);
  }
}
