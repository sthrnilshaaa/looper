import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'package:looper_player/core/theme/app_assets.dart';
import 'package:looper_player/core/utils/motion.dart';

/// The first-scan animation (welcome scan and the first library scan),
/// shown on a tilted 3D stage: leaned back in perspective, swaying slowly,
/// with a soft glow on the "floor" below it.
///
/// It sizes itself to the space it gets (never wider than [maxWidth] or
/// taller than 36 % of the screen), so it is no longer cropped or pushed
/// off-centre on narrow phones and in landscape. Still with Reduce Motion.
class FirstScanStage extends StatefulWidget {
  const FirstScanStage({super.key, this.maxWidth = 360});

  final double maxWidth;

  /// Lean back around the horizontal axis, radians.
  static const double tilt = 0.38;

  @override
  State<FirstScanStage> createState() => _FirstScanStageState();
}

class _FirstScanStageState extends State<FirstScanStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sway = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reducedOf(context)) {
      _sway.stop();
    } else if (!_sway.isAnimating) {
      _sway.repeat();
    }
  }

  @override
  void dispose() {
    _sway.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    final double screenH = MediaQuery.sizeOf(context).height;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = math.min(
          widget.maxWidth,
          constraints.hasBoundedWidth ? constraints.maxWidth : widget.maxWidth,
        );
        final double height = math.min(width * 0.75, screenH * 0.36);
        final Widget art = RepaintBoundary(
          child: Lottie.asset(
            AppAssets.loadingAnimation,
            fit: BoxFit.contain,
            repeat: true,
          ),
        );
        return SizedBox(
          width: width,
          height: height,
          child: AnimatedBuilder(
            animation: _sway,
            builder: (context, child) {
              final double a = _sway.value * 2 * math.pi;
              final Matrix4 m = Matrix4.identity()
                ..setEntry(3, 2, 0.0014) // perspective
                ..rotateX(FirstScanStage.tilt + 0.035 * math.sin(a))
                ..rotateY(0.12 * math.sin(a + math.pi / 3));
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Floor glow just under the art, drifting with the sway.
                  Align(
                    alignment: const Alignment(0, 0.8),
                    child: Transform.translate(
                      offset: Offset(width * 0.04 * math.sin(a), 0),
                      // A radial glow squashed into a wide floor ellipse.
                      child: SizedBox(
                        // Lay out at the squashed size so it aligns by its
                        // visible ellipse, not the unscaled circle.
                        width: width * 0.7,
                        height: width * 0.7 * 0.22,
                        child: OverflowBox(
                          maxHeight: width * 0.7,
                          child: Transform.scale(
                            scaleY: 0.22,
                            child: Container(
                              width: width * 0.7,
                              height: width * 0.7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    accent.withValues(alpha: 0.34),
                                    accent.withValues(alpha: 0.10),
                                    accent.withValues(alpha: 0.0),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Transform(
                    transform: m,
                    alignment: Alignment.center,
                    child: child,
                  ),
                ],
              );
            },
            // The animation has wide margins in its canvas; scale it up so
            // the art itself fills the stage.
            child: Transform.scale(scale: 1.45, child: art),
          ),
        );
      },
    );
  }
}
