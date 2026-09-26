import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/analyze/domain/analyze_models.dart';
import 'package:looper_player/ui/android/widgets/premium_section.dart';
import 'package:looper_player/core/utils/l10n.dart';

/// Last-30-days listening trend — a hand-painted animated bar chart built
/// from the play-event log. Bars grow in from the baseline on first build.
class AnalyzeTrendChart extends StatelessWidget {
  final List<DailyCount> dailyCounts;
  final Color accent;

  const AnalyzeTrendChart({
    super.key,
    required this.dailyCounts,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.listeningTrend,
          style: AppFonts.jostStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          context.l10n.last30Days,
          style: AppFonts.jostStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 12.5,
          ),
        ),
        const SizedBox(height: 12),
        PremiumSection(
          borderRadius: BorderRadius.circular(20),
          useExpanded: false,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          useCenter: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 110,
                width: double.infinity,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, progress, _) => CustomPaint(
                    painter: _TrendPainter(
                      counts: dailyCounts,
                      progress: progress,
                      color: accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (dailyCounts.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMM d').format(dailyCounts.first.date),
                      style: AppFonts.jostStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      DateFormat('MMM d').format(dailyCounts.last.date),
                      style: AppFonts.jostStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<DailyCount> counts;
  final double progress;
  final Color color;

  _TrendPainter({
    required this.counts,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (counts.isEmpty) return;
    final maxCount = counts
        .map((c) => c.plays)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final safeMax = maxCount == 0 ? 1 : maxCount;

    final barWidth = size.width / counts.length;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < counts.length; i++) {
      final count = counts[i];
      final heightFraction = (count.plays / safeMax) * progress;
      final barHeight = (size.height - 4) * heightFraction;
      final isToday = count.date == todayOnly;

      final left = i * barWidth + barWidth * 0.22;
      final right = (i + 1) * barWidth - barWidth * 0.22;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTRB(left, size.height - barHeight, right, size.height),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );

      paint.color = count.plays == 0
          ? Colors.white.withValues(alpha: 0.06)
          : color.withValues(alpha: isToday ? 1.0 : 0.65);
      canvas.drawRRect(
        count.plays == 0
            ? RRect.fromRectAndCorners(
                Rect.fromLTRB(left, size.height - 3, right, size.height),
                topLeft: const Radius.circular(2),
                topRight: const Radius.circular(2),
              )
            : rect,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.counts != counts;
}
