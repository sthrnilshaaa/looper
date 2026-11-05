import 'dart:math' as math;

import 'package:flutter/widgets.dart';

export 'package:looper_player/ui/widgets/common/player_scale.dart';

/// Portrait geometry of the expanded player as a pure function of the
/// window size.
///
/// The player was designed on a 1080x2400 phone at the default ~420dpi
/// (about 411x914dp). A lower display density (Display size "small", or a
/// high-res panel at a low dpi) gives the same physical screen more dp: the
/// cover, which fills the width, grew with it, while every control stayed at
/// its fixed dp size, so the controls looked tiny under a huge cover with
/// wide empty bands around it. The top bar and the controls are therefore
/// drawn at [scale], so the player keeps the reference proportions, just
/// sharper. At the reference size and below [scale] is exactly 1.
class PlayerPortraitMetrics {
  /// The reference window, 1080x2340 px at 420dpi. The width of 1080x2400
  /// is the same; its extra height is what the cover's side gaps absorb.
  static const double referenceWidth = 411.43;
  static const double referenceHeight = 891.43;

  /// Beyond this (portrait tablets) scaling stops and the layout is capped
  /// to [maxLayoutWidth] instead.
  static const double maxScale = 1.6;

  /// Widest the controls lay out (before [scale]), so a wide portrait
  /// window (tablet, unfolded foldable) doesn't stretch them edge to edge.
  static const double maxLayoutWidth = 480;

  /// How much the top bar and controls are enlarged.
  final double scale;

  /// Width of the player column, centered in the window.
  final double contentWidth;

  const PlayerPortraitMetrics._(this.scale, this.contentWidth);

  /// [uiScale] is the user's whole-app scale: the density check uses the
  /// size at 100%, so picking 80% shrinks the player instead of being
  /// undone by the low-density enlargement.
  factory PlayerPortraitMetrics.of(Size size, {double uiScale = 1.0}) {
    final Size unscaled = size * uiScale;
    // Height counts too: a wide but short window (16:9 phone at a low dpi)
    // must not grow the controls until they squeeze out the cover.
    final double scale = math
        .min(unscaled.width / referenceWidth, unscaled.height / referenceHeight)
        .clamp(1.0, maxScale);
    return PlayerPortraitMetrics._(
      scale,
      math.min(size.width, maxLayoutWidth * scale),
    );
  }
}
