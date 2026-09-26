import 'dart:ui' show Offset, Rect, Size, lerpDouble;

import 'package:flutter/animation.dart' show Curve, Curves;
import 'package:flutter/physics.dart' show SpringDescription;

/// Geometry and motion of the Fluid Player (the slide-to-expand player), as
/// pure functions of the expand progress `p` (0 = mini bar, 1 = full player)
/// so the per-frame values can be unit-tested without the audio backend.
///
/// Everything is in the coordinates of the full-screen layer that hosts the
/// player. The panel (background and rounded clip) grows from the mini bar's
/// rect to the whole screen; the player's content stays pinned to the screen
/// and only eases in over a short distance ([FluidSectionMotion]) rather than
/// riding the panel's top edge up the whole screen.
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

  Rect panelRect(double p) {
    final double margin = miniMargin * (1.0 - p);
    final double top = collapsedTop * (1.0 - p);
    final double bottom = screenSize.height - restingBottom * (1.0 - p);
    return Rect.fromLTRB(margin, top, screenSize.width - margin, bottom);
  }

  /// Converts a vertical pointer velocity (px/s, down positive) into
  /// progress units per second (expanding positive).
  double progressVelocity(double pixelsPerSecondDy) =>
      -pixelsPerSecondDy / travel;

  /// Rect of the morphing album art: from the mini bar's 50dp thumbnail
  /// (riding the panel) to the expanded player's artwork rect.
  Rect morphArtRect(double p, Rect expandedArt) {
    final Rect panel = panelRect(p);
    final double size = lerpDouble(50.0, expandedArt.width, p)!;
    final double left = panel.left + 12.0 + (expandedArt.left - 12.0) * p;
    final double top = panel.top + 11.0 + (expandedArt.top - 11.0) * p;
    return Rect.fromLTWH(left, top, size, size);
  }

  /// Corner radius of the morphing art: the mini thumbnail's 32 to the
  /// expanded artwork's 12.
  static double morphArtRadius(double p) => lerpDouble(32.0, 12.0, p)!;

  Offset miniOrigin(double p) => panelRect(p).topLeft;
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

/// Release/programmatic settle spring: critically damped (no bounce), and
/// started with the finger's velocity so letting go never jumps in speed.
final SpringDescription fluidPlayerSpring = SpringDescription.withDampingRatio(
  mass: 1.0,
  stiffness: 380.0,
  ratio: 1.0,
);
