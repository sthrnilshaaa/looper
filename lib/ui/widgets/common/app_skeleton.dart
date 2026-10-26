import 'package:looper_player/core/motion/pause_when_offscreen.dart';
import 'package:flutter/material.dart';
import 'package:looper_player/core/utils/motion.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// [Skeletonizer] with the app's shimmer: faint white bones on the dark
/// backgrounds, with a highlight tinted by the accent colour. Shared by every
/// loading skeleton so they all pulse alike.
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    super.key,
    required this.child,
    this.justifyMultiLineText = true,
    this.textBoneBorderRadius,
  });

  final Widget child;
  final bool justifyMultiLineText;
  final TextBoneBorderRadius? textBoneBorderRadius;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    // The shimmer loops forever: pause it while scrolled off screen.
    return ExcludeSemantics(
      child: PauseWhenOffscreen(
        child: Skeletonizer(
          ignorePointers: true,
          justifyMultiLineText: justifyMultiLineText,
          textBoneBorderRadius: textBoneBorderRadius,
          // Still bones, no sweeping highlight, when system animations are off.
          effect: Motion.reducedOf(context)
              ? SolidColorEffect(color: Colors.white.withValues(alpha: 0.07))
              : ShimmerEffect(
                  baseColor: Colors.white.withValues(alpha: 0.07),
                  highlightColor: Color.lerp(
                    Colors.white,
                    accent,
                    0.35,
                  )!.withValues(alpha: 0.2),
                  duration: const Duration(milliseconds: 1600),
                ),
          child: child,
        ),
      ),
    );
  }
}
