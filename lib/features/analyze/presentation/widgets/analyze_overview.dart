import 'package:flutter/material.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/l10n.dart';
import 'package:looper_player/features/analyze/domain/analyze_models.dart';
import 'package:looper_player/features/analyze/presentation/widgets/analyze_common.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The headline numbers as a bento: one large listening-time tile (with
/// total plays under it) beside two stacked streak tiles. Values count up
/// from 0 on first build.
class AnalyzeOverview extends StatelessWidget {
  final AnalyzeSnapshot snapshot;
  final Color accent;

  const AnalyzeOverview({
    super.key,
    required this.snapshot,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 11,
            child: AnalyzeCard(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IconChip(icon: LucideIcons.clock, accent: accent),
                  const Spacer(),
                  const SizedBox(height: 16),
                  _CountUp(
                    value: snapshot.totalListenedMs,
                    format: (v) => formatListeningTime(context, v),
                    style: AppFonts.jostStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    context.l10n.listeningTime,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _labelStyle,
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    thickness: 0.8,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(LucideIcons.play, color: accent, size: 13),
                      const SizedBox(width: 6),
                      _CountUp(
                        value: snapshot.totalPlays,
                        format: (v) => formatCount(context, v),
                        style: AppFonts.jostStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          context.l10n.totalPlays,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _labelStyle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 9,
            child: Column(
              children: [
                Expanded(
                  child: _StreakTile(
                    icon: LucideIcons.flame,
                    days: snapshot.streak.current,
                    label: context.l10n.analyzeCurrentStreak,
                    accent: accent,
                    highlighted: snapshot.streak.current > 0,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _StreakTile(
                    icon: LucideIcons.award,
                    days: snapshot.streak.longest,
                    label: context.l10n.analyzeLongestStreak,
                    accent: accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle get _labelStyle => AppFonts.jostStyle(
  color: Colors.white.withValues(alpha: 0.55),
  fontSize: 12,
  fontWeight: FontWeight.w500,
);

class _StreakTile extends StatelessWidget {
  final IconData icon;
  final int days;
  final String label;
  final Color accent;
  final bool highlighted;

  const _StreakTile({
    required this.icon,
    required this.days,
    required this.label,
    required this.accent,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnalyzeCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      gradient: highlighted
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.2),
                Colors.white.withValues(alpha: 0.04),
              ],
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 15),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _labelStyle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _CountUp(
            value: days,
            format: (v) => context.l10n.daysCount(v),
            style: AppFonts.jostStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  final IconData icon;
  final Color accent;
  const _IconChip({required this.icon, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(UiUtils.artCorner(11)),
      ),
      child: Icon(icon, color: accent, size: 18),
    );
  }
}

class _CountUp extends StatelessWidget {
  final int value;
  final String Function(int value) format;
  final TextStyle style;

  const _CountUp({
    required this.value,
    required this.format,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Text(format(v), maxLines: 1, style: style),
      ),
    );
  }
}
