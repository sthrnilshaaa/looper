import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/core/utils/responsive.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:looper_player/ui/widgets/player/player_gradient/animated_player_gradient.dart';
import 'player_landscape_layout.dart';

/// The player's gradient background (Dynamic Theming off, Player Gradient
/// on), shared by the classic pushed player and the Fluid Player panel so
/// both look the same. The stops are pre-blended onto the surface, so it's
/// opaque on its own and bright at 0% Music Darkness: the old translucent
/// 5-20% primary tint over a dark surface stayed dark even with no overlay.
///
/// With [animated] (the Animated Gradient setting) it hands off to
/// AnimatedPlayerGradient instead; the static gradient below is unchanged.
class PlayerGradientBackground extends StatelessWidget {
  final double darkness;
  final bool animated;
  final bool followExpandProgress;
  const PlayerGradientBackground({
    required this.darkness,
    this.animated = false,
    this.followExpandProgress = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (animated) {
      return AnimatedPlayerGradient(
        darkness: darkness,
        followExpandProgress: followExpandProgress,
      );
    }
    final ColorScheme scheme = Theme.of(context).colorScheme;
    Color tint(Color color, double alpha) =>
        Color.alphaBlend(color.withValues(alpha: alpha), scheme.surface);
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.6,
              colors: [
                tint(scheme.primary, 0.55),
                tint(scheme.primary, 0.28),
                tint(scheme.primary, 0.14),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // Music Darkness slider, same as the dynamic-art background.
        if (darkness > 0)
          ColoredBox(color: Colors.black.withValues(alpha: darkness)),
      ],
    );
  }
}

class BlurredBackgroundArt extends StatelessWidget {
  final Song song;
  const BlurredBackgroundArt({required this.song, super.key});

  @override
  Widget build(BuildContext context) {
    final path = song.artPath;
    if (path == null) return const SizedBox.shrink();
    return RepaintBoundary(
      child: Transform.scale(
        scale: 1.08,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Image.file(
            File(path),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            filterQuality: FilterQuality.low,
            cacheWidth: 80,
            cacheHeight: 80,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class ForegroundAlbumArt extends StatelessWidget {
  final Song song;
  const ForegroundAlbumArt({required this.song, super.key});

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);
    final double decodeWidth = Responsive.isLandscape(screenSize)
        ? PlayerLandscapeMetrics.of(
            screenSize,
            MediaQuery.paddingOf(context),
          ).artRect.width
        : screenSize.width;
    final double dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;

    return AspectRatio(
      aspectRatio: 1.0,
      child: OptimizedImage(
        imagePath: song.artPath != null && !song.artPath!.startsWith('http')
            ? song.artPath
            : null,
        imageUrl: song.artPath != null && song.artPath!.startsWith('http')
            ? song.artPath
            : null,
        borderRadius: BorderRadius.circular(12),
        fit: BoxFit.cover,
        cacheWidth: (decodeWidth * dpr).toInt(),
      ),
    );
  }
}
