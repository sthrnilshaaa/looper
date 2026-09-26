import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:looper_player/core/utils/responsive.dart';

/// Geometry for the expanded player in landscape: a square artwork pane on the
/// left and the controls on the right, under a slim top bar.
///
/// Everything is a pure function of the window size and safe-area insets, and
/// every rect is in window coordinates (the expanded player fills the window).
/// That lets the mini-player -> player artwork morph aim at [artRect] without
/// waiting for the real artwork to be measured - a measurement taken in
/// portrait goes stale the moment the device rotates.
@immutable
class PlayerLandscapeMetrics {
  const PlayerLandscapeMetrics._({
    required this.compact,
    required this.topBarTopPadding,
    required this.topBarRect,
    required this.artRect,
    required this.controlsRect,
    required this.transportHeight,
    required this.sectionGap,
  });

  /// Height of the close / more buttons in the top bar.
  static const double _topBarButtonHeight = 48;

  /// The artwork never grows past this, however big the tablet.
  static const double _maxArtSize = 640;

  /// The controls stay this narrow or less so tablet rows don't stretch.
  static const double _maxControlsWidth = 520;

  /// The artwork takes at most this share of the usable width.
  static const double _artWidthFraction = 0.42;

  /// Gap between neighbouring covers in the swipe-to-skip carousel, which is
  /// clipped to [artRect] in landscape so covers read as separate pages.
  static const double artSlideGap = 16;

  /// True on short windows (phones in landscape): tighter spacing and smaller
  /// transport buttons so the whole control stack fits beside the artwork.
  final bool compact;

  /// Space above the top bar buttons.
  final double topBarTopPadding;

  final Rect topBarRect;

  /// The square the artwork is drawn in.
  final Rect artRect;

  /// The area the controls are centered in (scaled down if they overflow it).
  final Rect controlsRect;

  /// Height of the prev / play / next buttons.
  final double transportHeight;

  /// Vertical gap between the stacked control rows.
  final double sectionGap;

  /// How far one swipe-to-skip page travels: one cover plus [artSlideGap].
  double get artSlideExtent => artRect.width + artSlideGap;

  factory PlayerLandscapeMetrics.of(Size size, EdgeInsets safe) {
    final bool compact = Responsive.isShort(size);
    final double topBarTopPadding = compact ? 4 : 8;
    final double topBarHeight = topBarTopPadding + _topBarButtonHeight;
    final double verticalPadding = compact ? 8 : 16;
    final double sideInset = compact ? 16 : 24;
    final double paneGap = compact ? 20 : 32;

    final double bodyWidth = math.max(0, size.width - safe.horizontal);
    final double bodyHeight = math.max(0, size.height - safe.vertical);
    final double paneTop = safe.top + topBarHeight;
    final double paneHeight = math.max(0, bodyHeight - topBarHeight);
    final double availableWidth = math.max(0, bodyWidth - 2 * sideInset);

    final double artSize = math.max(
      0,
      math.min(
        math.min(
          paneHeight - 2 * verticalPadding,
          availableWidth * _artWidthFraction,
        ),
        _maxArtSize,
      ),
    );
    final double controlsWidth = math.max(
      0,
      math.min(availableWidth - paneGap - artSize, _maxControlsWidth),
    );

    // Center the artwork + controls group so it doesn't hug the left edge on
    // wide tablets.
    final double groupWidth = artSize + paneGap + controlsWidth;
    final double groupLeft = safe.left + (bodyWidth - groupWidth) / 2;

    return PlayerLandscapeMetrics._(
      compact: compact,
      topBarTopPadding: topBarTopPadding,
      topBarRect: Rect.fromLTWH(safe.left, safe.top, bodyWidth, topBarHeight),
      artRect: Rect.fromLTWH(
        groupLeft,
        paneTop + (paneHeight - artSize) / 2,
        artSize,
        artSize,
      ),
      controlsRect: Rect.fromLTWH(
        groupLeft + artSize + paneGap,
        paneTop + verticalPadding,
        controlsWidth,
        math.max(0, paneHeight - 2 * verticalPadding),
      ),
      transportHeight: compact ? 64 : 80,
      sectionGap: compact ? 12 : 20,
    );
  }
}

/// Places the landscape player's three slots at the rects in [metrics].
///
/// Slots are absolutely positioned rather than flowed in a Row/Column so the
/// artwork lands exactly on [PlayerLandscapeMetrics.artRect], which is what the
/// morph animation targets.
class PlayerLandscapeLayout extends StatelessWidget {
  final PlayerLandscapeMetrics metrics;
  final Widget topBar;
  final Widget artwork;
  final Widget controls;

  const PlayerLandscapeLayout({
    super.key,
    required this.metrics,
    required this.topBar,
    required this.artwork,
    required this.controls,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fromRect(rect: metrics.topBarRect, child: topBar),
        Positioned.fromRect(rect: metrics.artRect, child: artwork),
        Positioned.fromRect(
          rect: metrics.controlsRect,
          // The stack is centered and only ever scaled *down*: at large font
          // scales or in a split-screen window it shrinks to fit instead of
          // overflowing onto the artwork.
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: metrics.controlsRect.width,
                child: controls,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
