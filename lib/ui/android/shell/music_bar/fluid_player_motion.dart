import 'dart:ui' show Offset, Rect, Size, lerpDouble;

import 'package:flutter/animation.dart' show Curve, Curves;
import 'package:flutter/physics.dart' show SpringDescription;
import 'package:looper_player/core/motion/rubber_band.dart';

export 'package:looper_player/core/motion/rubber_band.dart';

/// Geometry and motion of the Fluid Player (the slide-to-expand player), as
/// pure functions of the expand progress `p` (0 = mini bar, 1 = full player)
/// so the per-frame values can be unit-tested without the audio backend.
///
/// Everything is in the coordinates of the full-screen layer that hosts the
/// player. The panel (background and rounded clip) grows from the mini bar's
/// rect to the whole screen; the player's content stays pinned to the screen
/// and only eases in over a short distance ([FluidSectionMotion]) rather than
/// riding the panel's top edge up the whole screen.
/// Progress at which the morphing art hands over to the real artwork (and
/// the mini-bar layers leave). The panel's top edge travels ~1700 px, so at
/// the old 0.99 the morph was still ~17 px short and 1 % small and the real
/// art snapped into place; at 0.999 the gap is under 2 px. Settling springs
/// land exactly on 1.0, so the handoff always happens.
const double kFluidHandoff = 0.999;

class FluidPlayerGeometry {
  const FluidPlayerGeometry({
    required this.screenSize,
    required this.restingBottom,
  });

  /// Size of the full-screen host layer.
  final Size screenSize;

  /// Gap between the collapsed mini bar and the bottom of the screen (clears
  /// the navbar at a tab root, or just the system inset elsewhere).
  final double restingBottom;

  static const double miniHeight = 72.0;
  static const double miniMargin = 16.0;
  static const double panelRadius = 36.0;

  /// Width the mini content is laid out at. Fixed (the collapsed panel's
  /// width) so a moving panel never re-lays it out.
  double get miniWidth => screenSize.width - 2 * miniMargin;

  /// Top of the collapsed panel.
  double get collapsedTop => screenSize.height - restingBottom - miniHeight;

  /// How far the panel's top edge travels from collapsed to expanded. Drag
  /// deltas are divided by this (not the screen height) so the edge stays
  /// under the finger.
  double get travel => collapsedTop > 1.0 ? collapsedTop : 1.0;

  /// Most the fully open panel can lift when pulled past the open end.
  double get stretchOpenMax => screenSize.height * 0.12;

  /// How far the collapsed mini bar travels to leave the screen. Pushing it
  /// down follows the finger with rubber-band resistance toward this (the
  /// drag-down dismiss); a dismiss animates the rest of the way.
  double get dismissTravel => restingBottom + miniHeight + 24.0;

  /// Visible progress (0..1) for an unclamped physics position [r].
  static double progressOf(double r) => r.clamp(0.0, 1.0).toDouble();

  /// Signed stretch in px for an unclamped physics position [r]: positive
  /// lifts the open panel, negative sinks the collapsed one. `r` beyond an
  /// end is the finger's (or spring's) overshoot in progress units; it is
  /// turned into px and damped through [rubberBand], so it never exceeds the
  /// end's max.
  double stretchOf(double r) {
    if (r > 1.0) return rubberBand((r - 1.0) * travel, stretchOpenMax);
    if (r < 0.0) return -rubberBand(-r * travel, dismissTravel);
    return 0.0;
  }

  /// [stretch] > 0 (open end) raises the top edge and keeps the bottom on
  /// the screen edge; [stretch] < 0 (collapsed end) moves the whole rect down.
  Rect panelRect(double p, {double stretch = 0.0}) {
    final double margin = miniMargin * (1.0 - p);
    double top = collapsedTop * (1.0 - p);
    double bottom = screenSize.height - restingBottom * (1.0 - p);
    if (stretch > 0) {
      top -= stretch;
    } else if (stretch < 0) {
      top -= stretch;
      bottom -= stretch;
    }
    return Rect.fromLTRB(margin, top, screenSize.width - margin, bottom);
  }

  /// Converts a vertical pointer velocity (px/s, down positive) into
  /// progress units per second (expanding positive).
  double progressVelocity(double pixelsPerSecondDy) =>
      -pixelsPerSecondDy / travel;

  /// Rect of the morphing album art: from the mini bar's 50dp thumbnail
  /// (riding the panel) to the expanded player's artwork rect.
  Rect morphArtRect(double p, Rect expandedArt, {double stretch = 0.0}) {
    final Rect panel = panelRect(p, stretch: stretch);
    final double size = lerpDouble(50.0, expandedArt.width, p)!;
    final double left = panel.left + 12.0 + (expandedArt.left - 12.0) * p;
    final double top = panel.top + 11.0 + (expandedArt.top - 11.0) * p;
    return Rect.fromLTWH(left, top, size, size);
  }

  /// Corner radius of the morphing art: the mini thumbnail's 32 to the
  /// expanded artwork's 12.
  static double morphArtRadius(double p) => lerpDouble(32.0, 12.0, p)!;

  Offset miniOrigin(double p, {double stretch = 0.0}) =>
      panelRect(p, stretch: stretch).topLeft;
}

/// Staggered entrance of one expanded-player section: it fades in and rises
/// [distance] into place over its own [start]..[end] slice of the progress.
/// Collapsing plays the same mapping backwards, so sections leave in reverse.
class FluidSectionMotion {
  const FluidSectionMotion(this.start, this.end, {this.slide = true});

  final double start;
  final double end;

  /// False for layers that should only fade (e.g. a background fill).
  final bool slide;

  static const double distance = 48.0;
  static const Curve curve = Curves.easeOutCubic;

  // Bottom-up, following the panel as it grows upward and uncovers the lower
  // controls first. Every section is fully in place well before p = 1.
  static const FluidSectionMotion utilityRow = FluidSectionMotion(0.30, 0.75);
  static const FluidSectionMotion transportRow = FluidSectionMotion(0.35, 0.80);
  static const FluidSectionMotion seekBar = FluidSectionMotion(0.40, 0.85);
  static const FluidSectionMotion songInfo = FluidSectionMotion(0.45, 0.90);
  static const FluidSectionMotion topBar = FluidSectionMotion(0.55, 1.0);
  static const FluidSectionMotion backgroundFill = FluidSectionMotion(
    0.0,
    1.0,
    slide: false,
  );

  double _t(double p) =>
      curve.transform(((p - start) / (end - start)).clamp(0.0, 1.0).toDouble());

  double opacity(double p) => _t(p);

  double offsetY(double p) => slide ? (1.0 - _t(p)) * distance : 0.0;
}

/// Underdamped spring for every open: the whole sheet (background, artwork
/// and controls together) carries a little past the top and settles back
/// once. A plain tap overshoots ~10 % of the travel, which the rubber band
/// shows as ~25 dp; a hard flick goes further but never past the stretch max.
final SpringDescription fluidPlayerOpenBounceSpring =
    SpringDescription.withDampingRatio(
      mass: 1.0,
      stiffness: 380.0,
      ratio: 0.62,
    );

/// Firmer bounce for minimizing: the mini bar dips ~15 dp under its resting
/// spot and comes back, so it lands like the sheet it was.
final SpringDescription fluidPlayerCloseBounceSpring =
    SpringDescription.withDampingRatio(
      mass: 1.0,
      stiffness: 380.0,
      ratio: 0.72,
    );

/// Critically damped settle (no bounce): releases from inside a stretch,
/// catches let go without a drag, and reduced motion. Started with the
/// finger's velocity so letting go never jumps in speed.
final SpringDescription fluidPlayerSpring = SpringDescription.withDampingRatio(
  mass: 1.0,
  stiffness: 380.0,
  ratio: 1.0,
);
