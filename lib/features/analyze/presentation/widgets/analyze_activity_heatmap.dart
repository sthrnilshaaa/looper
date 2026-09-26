import 'package:flutter/material.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/analyze/domain/analyze_models.dart';
import 'package:looper_player/ui/android/widgets/premium_section.dart';
import 'package:looper_player/core/utils/l10n.dart';

/// Monday-first narrow weekday labels in the app's language.
List<String> _weekdayLabels(BuildContext context) {
  final narrow = MaterialLocalizations.of(
    context,
  ).narrowWeekdays; // Sunday-first
  return [...narrow.skip(1), narrow.first];
}

String _dayPartLabel(BuildContext context, DayPart part) => switch (part) {
  DayPart.morning => context.l10n.dayPartMorningShort,
  DayPart.afternoon => context.l10n.dayPartAfternoonShort,
  DayPart.evening => context.l10n.dayPartEveningShort,
  DayPart.night => context.l10n.dayPartNightShort,
};

/// "When do you listen most" — a 7 (weekday) x 4 (day-part) heatmap grid
/// built from the play-event log, cell intensity = share of the accent
/// color's alpha.
class AnalyzeActivityHeatmap extends StatelessWidget {
  final List<DayPartCount> grid;
  final Color accent;

  const AnalyzeActivityHeatmap({
    super.key,
    required this.grid,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final maxPlays = grid
        .map((c) => c.plays)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final safeMax = maxPlays == 0 ? 1 : maxPlays;

    Widget cellFor(int weekday, DayPart part) {
      final match = grid.firstWhere(
        (c) => c.weekday == weekday && c.part == part,
        orElse: () => DayPartCount(weekday: weekday, part: part, plays: 0),
      );
      final intensity = match.plays / safeMax;
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: intensity),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, animatedIntensity, _) => AspectRatio(
          aspectRatio: 1,
          child: Container(
            margin: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              color: match.plays == 0
                  ? Colors.white.withValues(alpha: 0.04)
                  : accent.withValues(alpha: 0.12 + 0.75 * animatedIntensity),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.activityPattern,
          style: AppFonts.jostStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          context.l10n.whenYouListenMost,
          style: AppFonts.jostStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 12.5,
          ),
        ),
        const SizedBox(height: 12),
        PremiumSection(
          borderRadius: BorderRadius.circular(20),
          useExpanded: false,
          padding: const EdgeInsets.all(16),
          useCenter: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 34,
                child: Column(
                  children: [
                    const SizedBox(height: 22),
                    for (final part in DayPart.values)
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _dayPartLabel(context, part),
                            style: AppFonts.jostStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (final label in _weekdayLabels(context))
                          Expanded(
                            child: Center(
                              child: Text(
                                label,
                                style: AppFonts.jostStyle(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    for (final part in DayPart.values)
                      Row(
                        children: [
                          for (var weekday = 1; weekday <= 7; weekday++)
                            Expanded(child: cellFor(weekday, part)),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
