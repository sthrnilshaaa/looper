import 'package:flutter/material.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:intl/intl.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/l10n.dart';
import 'package:looper_player/features/analyze/domain/analyze_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Shared building blocks for the Looper Analyze report: one section header
/// style, one card surface, and the locale-aware labels every section uses.

/// Title (+ optional dimmed subtitle and trailing widget) above a section.
class AnalyzeSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const AnalyzeSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.jostStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.jostStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 12.5,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

/// The flat glass surface every Analyze card sits on. Deliberately not
/// [PremiumSection]: no blur, no press scale, so a long scrolling report
/// stays cheap to paint.
class AnalyzeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Gradient? gradient;

  const AnalyzeCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? Colors.white.withValues(alpha: 0.055) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(UiUtils.cardCorner(radius)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: child,
    );
  }
}

String analyzeLocale(BuildContext context) =>
    Localizations.localeOf(context).toLanguageTag();

/// "12h 34m" / "34m", in the app's language.
String formatListeningTime(BuildContext context, int ms) {
  final totalMinutes = (ms / 60000).round();
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (hours > 0) return context.l10n.durationHoursMinutes(hours, minutes);
  return context.l10n.durationMinutesOnly(minutes);
}

/// Grouped integer, e.g. "1,234" / "1.234".
String formatCount(BuildContext context, int value) =>
    NumberFormat.decimalPattern(analyzeLocale(context)).format(value);

/// Full weekday name for a [DateTime.weekday] (1 = Monday .. 7 = Sunday).
String weekdayName(BuildContext context, int weekday) =>
    DateFormat.EEEE(analyzeLocale(context)).format(DateTime(2024, 1, weekday));

String dayPartName(BuildContext context, DayPart part) => switch (part) {
  DayPart.morning => context.l10n.dayPartMorning,
  DayPart.afternoon => context.l10n.dayPartAfternoon,
  DayPart.evening => context.l10n.dayPartEvening,
  DayPart.night => context.l10n.dayPartNight,
};

String dayPartShortName(BuildContext context, DayPart part) => switch (part) {
  DayPart.morning => context.l10n.dayPartMorningShort,
  DayPart.afternoon => context.l10n.dayPartAfternoonShort,
  DayPart.evening => context.l10n.dayPartEveningShort,
  DayPart.night => context.l10n.dayPartNightShort,
};

IconData dayPartIcon(DayPart part) => switch (part) {
  DayPart.morning => LucideIcons.sunrise,
  DayPart.afternoon => LucideIcons.sun,
  DayPart.evening => LucideIcons.sunset,
  DayPart.night => LucideIcons.moon,
};

/// The analyzer groups small genres under the English sentinel 'Other';
/// show it in the app's language.
String genreLabel(BuildContext context, String name) =>
    name == 'Other' ? context.l10n.otherGenre : name;
