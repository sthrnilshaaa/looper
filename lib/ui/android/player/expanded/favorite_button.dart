import 'dart:math' as math;
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/core/theme/app_icons.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import '../../widgets/premium_section.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';

class FavoriteButtonWithGlow extends StatefulWidget {
  final Song song;
  final WidgetRef ref;
  final bool useBlur;

  const FavoriteButtonWithGlow({
    super.key,
    required this.song,
    required this.ref,
    required this.useBlur,
  });

  @override
  State<FavoriteButtonWithGlow> createState() => _FavoriteButtonWithGlowState();
}

class _FavoriteButtonWithGlowState extends State<FavoriteButtonWithGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  final math.Random _random = math.Random();
  final List<double> _randomAngles = [];
  final List<double> _randomRadii = [];
  final List<double> _randomSpeeds = [];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _generateRandomParticles();
  }

  void _generateRandomParticles() {
    _randomAngles.clear();
    _randomRadii.clear();
    _randomSpeeds.clear();
    for (int i = 0; i < 12; i++) {
      _randomAngles.add(_random.nextDouble() * 2 * math.pi);
      _randomRadii.add((_random.nextDouble() - 0.5) * 8.0);
      _randomSpeeds.add(
        (_random.nextBool() ? 1 : -1) * (0.4 + _random.nextDouble() * 0.6),
      );
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FavoriteButtonWithGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only animate when the *same* song actually transitions to favorite
    // (a real like toggle). If the song itself changed - e.g. replaying a
    // previously-liked track after another song - don't replay the glow.
    final sameTrack =
        oldWidget.song.path == widget.song.path ||
        oldWidget.song.id == widget.song.id;
    if (sameTrack && !oldWidget.song.isFavorite && widget.song.isFavorite) {
      if (_glowController.status != AnimationStatus.forward) {
        _generateRandomParticles();
        _glowController.forward(from: 0.0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // toggleFavorite mutates the same Song object, so watch the flag itself.
    return Consumer(
      builder: (context, ref, _) {
        final isFav = ref.watch(
          playbackProvider.select(
            (s) => s.currentSong?.isFavorite ?? widget.song.isFavorite,
          ),
        );
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            PremiumSection(
              borderRadius: BorderRadius.circular(32),
              width: 56,
              height: 56,
              useExpanded: false,
              showShadow: false,
              useBlur: widget.useBlur,
              forceNoBlur: true,
              showBorder: false,
              backgroundColor: Colors.transparent,
              onTap: () {
                if (isFav) {
                  AppHaptics.selection();
                } else {
                  AppHaptics.heartbeat();
                  _generateRandomParticles();
                  _glowController.forward(from: 0.0);
                }
                widget.ref.read(playbackProvider.notifier).toggleFavorite();
              },
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/player_styles/star.svg',
                  width: 25,
                  height: 25,
                  colorFilter: ColorFilter.mode(
                    Colors.white.withValues(alpha: isFav ? 1 : 0.1),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(56, 56),
                    painter: LikedGlowPainter(
                      progress: _glowController.value,
                      randomAngles: _randomAngles,
                      randomRadii: _randomRadii,
                      randomSpeeds: _randomSpeeds,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class LikedGlowPainter extends CustomPainter {
  final double progress;
  final List<double> randomAngles;
  final List<double> randomRadii;
  final List<double> randomSpeeds;

  LikedGlowPainter({
    required this.progress,
    required this.randomAngles,
    required this.randomRadii,
    required this.randomSpeeds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0.0 || progress == 1.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = 24.0 + progress * 10.0;
    final fade = 1.0 - progress;

    // Glowing circle stroke
    final circlePaint = Paint()
      ..color = Colors.yellow.withOpacity(0.35 * fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(center, baseRadius, circlePaint);

    final linePaint = Paint()
      ..color = Colors.yellow.withOpacity(0.5 * fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, baseRadius, linePaint);
  }

  @override
  bool shouldRepaint(covariant LikedGlowPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
