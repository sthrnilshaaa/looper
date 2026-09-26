import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/analyze/domain/analyze_models.dart';
import 'package:looper_player/ui/android/widgets/premium_section.dart';
import 'package:looper_player/core/utils/l10n.dart';

/// Genre breakdown: an animated donut ring (hand-painted, no chart
/// dependency) that sweeps in on first build, paired with a legend.
class AnalyzeGenreDonut extends StatelessWidget {
  final List<GenreStat> genres;

  const AnalyzeGenreDonut({super.key, required this.genres});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.genreBreakdown,
          style: AppFonts.jostStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        PremiumSection(
          borderRadius: BorderRadius.circular(20),
          useExpanded: false,
          padding: const EdgeInsets.all(18),
          useCenter: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, progress, _) => SizedBox(
                  width: 108,
                  height: 108,
                  child: CustomPaint(
                    painter: _DonutPainter(genres: genres, progress: progress),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            genres.isEmpty
                                ? '—'
                                : '${(genres.first.fraction * 100).round()}%',
                            style: AppFonts.jostStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (genres.isNotEmpty)
                            Text(
                              _genreLabel(context, genres.first.name),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.jostStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 10.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [for (final g in genres) _LegendRow(genre: g)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final GenreStat genre;
  const _LegendRow({required this.genre});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: genre.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _genreLabel(context, genre.name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.jostStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12.5,
              ),
            ),
          ),
          Text(
            '${(genre.fraction * 100).round()}%',
            style: AppFonts.jostStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<GenreStat> genres;
  final double progress;
  static const _gapDegrees = 3.0;

  _DonutPainter({required this.genres, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (genres.isEmpty) return;
    final rect = Offset.zero & size;
    final strokeWidth = size.shortestSide * 0.16;
    final ringRect = rect.deflate(strokeWidth / 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    var remainingSweep = 2 * math.pi * progress;
    var startAngle = -math.pi / 2;
    final gapRad = _gapDegrees * math.pi / 180;

    for (final genre in genres) {
      if (remainingSweep <= 0) break;
      final fullSweep = math.max(0.0, (2 * math.pi * genre.fraction) - gapRad);
      final sweep = math.min(fullSweep, remainingSweep);
      if (sweep > 0) {
        paint.color = genre.color;
        canvas.drawArc(ringRect, startAngle, sweep, false, paint);
      }
      startAngle += fullSweep + gapRad;
      remainingSweep -= fullSweep + gapRad;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.genres != genres;
}

/// The analyzer groups small genres under the English sentinel 'Other';
/// show it in the app's language.
String _genreLabel(BuildContext context, String name) =>
    name == 'Other' ? context.l10n.otherGenre : name;
