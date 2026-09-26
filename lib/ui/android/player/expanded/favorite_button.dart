import 'dart:math' as math;
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/core/theme/app_icons.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import '../../widgets/premium_section.dart';

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
    if (oldWidget.song.id == widget.song.id &&
        !oldWidget.song.isFavorite &&
        widget.song.isFavorite) {
      if (_glowController.status != AnimationStatus.forward) {
        _generateRandomParticles();
        _glowController.forward(from: 0.0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          backgroundColor: widget.song.isFavorite
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
              : Colors.transparent,
          onTap: () {
            HapticFeedback.selectionClick();
            if (!widget.song.isFavorite) {
              _generateRandomParticles();
              _glowController.forward(from: 0.0);
            }
            widget.ref.read(playbackProvider.notifier).toggleFavorite();
          },
          child: Center(
            child: SvgPicture.asset(
              widget.song.isFavorite ? AppIcons.like : AppIcons.unlike,
              colorFilter: ColorFilter.mode(
                widget.song.isFavorite
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white.withOpacity(0.2),
                BlendMode.srcIn,
              ),
              width: AppIcons.sizeLarge.s,
              height: AppIcons.sizeLarge.s,
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
