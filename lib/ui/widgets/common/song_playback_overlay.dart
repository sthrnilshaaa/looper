import 'dart:io';
import 'package:looper_player/ui/widgets/common/looper_loader.dart';
import 'package:flutter/material.dart';
import 'package:looper_player/core/theme/app_assets.dart';
import 'package:looper_player/core/utils/motion.dart';

class SongPlaybackOverlay extends StatelessWidget {
  const SongPlaybackOverlay({
    super.key,
    required this.isPlaying,
    this.indicatorSize = 24,
  });

  final bool isPlaying;
  final double indicatorSize;

  /// Darkening behind the playing bars on artwork. Shared by the classic
  /// mini bar and the Fluid Player's artwork so both always match.
  static const double dimAlpha = 0.18;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black.withValues(alpha: dimAlpha),
    child: Center(
      child: SongPlaybackIndicator(isPlaying: isPlaying, size: indicatorSize),
    ),
  );
}

class SongPlaybackIndicator extends StatelessWidget {
  const SongPlaybackIndicator({
    super.key,
    required this.isPlaying,
    this.size = 24,
  });

  final bool isPlaying;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Play/pause cross-fades between the playing animation and the still
    // dots instead of snapping.
    final bool animating =
        isPlaying && TickerMode.of(context) && !Motion.reducedOf(context);
    return AnimatedSwitcher(
      duration: Duration(milliseconds: Motion.reducedOf(context) ? 0 : 250),
      child: KeyedSubtree(
        key: ValueKey<bool>(animating),
        child: _content(context),
      ),
    );
  }

  Widget _content(BuildContext context) =>
      // Android shows the playing GIF; desktop the code-drawn bars. Either is
      // only mounted when visible and playing (GIF decoding keeps running
      // offstage and while paused).
      isPlaying && TickerMode.of(context) && !Motion.reducedOf(context)
      ? (Platform.isAndroid
            ? Image.asset(
                AppAssets.playingGif,
                width: size,
                height: size,
                color: Colors.white,
              )
            : LooperLoader(size: size, color: Colors.white))
      : FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: size,
            height: size,
            // Match the GIF's four columns and baseline, flattened while paused.
            child: Padding(
              padding: EdgeInsets.only(top: size * 5.2 / 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: size * 0.8 / 24,
                children: [
                  for (var i = 0; i < 4; i++)
                    Container(
                      width: size * 2.2 / 24,
                      height: size * 2.2 / 24,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(size * 1.1 / 24),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
}
