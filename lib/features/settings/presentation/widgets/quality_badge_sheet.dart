import 'package:looper_player/core/motion/looper_scroll_physics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/playback/data/audio_analyzer.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/features/settings/domain/quality_badge_style.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/player/quality_badge.dart';
import 'package:looper_player/ui/widgets/sheets/app_bottom_sheet.dart';

import 'style_sheet_controls.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';

void showQualityBadgeSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _QualityBadgeSheet(),
  );
}

/// Pick the quality badge's look, icon, colors, separator and details, with
/// a live preview of the current song's badge (or a sample FLAC one).
class _QualityBadgeSheet extends ConsumerWidget {
  const _QualityBadgeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final style = ref.watch(
      settingsProvider.select(QualityBadgeStyle.fromSettings),
    );
    final accent = Color(
      ref.watch(settingsProvider.select((s) => s.accentColor)),
    );
    final String? path = ref.watch(
      playbackProvider.select((s) => s.currentSong?.path),
    );
    final analysis = path == null
        ? null
        : AudioAnalyzer.getCachedAnalysis(path);
    final QualityInfo info = analysis != null
        ? QualityInfo.fromAnalysis(analysis)
        : path != null
        ? QualityInfo.fromPath(path)
        : QualityInfo.sample;
    final notifier = ref.read(settingsProvider.notifier);
    final bool nameOnly = style.layout == QualityBadgeLayout.name;
    final int enabledFields = QualityBadgeField.values
        .where(style.shows)
        .length;

    String fieldLabel(QualityBadgeField f) => switch (f) {
      QualityBadgeField.tier => l10n.qualityBadgeLevel,
      QualityBadgeField.codec => l10n.codec,
      QualityBadgeField.bitDepth => l10n.bitDepth,
      QualityBadgeField.sampleRate => l10n.sampleRate,
      QualityBadgeField.bitrate => l10n.bitrate,
      QualityBadgeField.channels => l10n.channels,
    };

    return AppBottomSheetContainer(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          physics: const LooperScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.qualityBadgeStyle,
                style: AppFonts.jostStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.qualityBadgeStyleDesc,
                style: AppFonts.jostStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 20),
              // Preview, on a dark strip like the player's top bar.
              Container(
                height: 72,
                alignment: Alignment.center,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10, width: 0.5),
                ),
                child: QualityBadge(info: info, style: style),
              ),
              StyleSectionLabel(l10n.qualityBadgeLayout, accent: accent),
              StyleSegmentedChoice<QualityBadgeLayout>(
                values: QualityBadgeLayout.values,
                selected: style.layout,
                accent: accent,
                label: (l) => switch (l) {
                  QualityBadgeLayout.details => l10n.qualityBadgeDetails,
                  QualityBadgeLayout.name => l10n.qualityBadgeLayoutName,
                },
                onSelected: notifier.updateQualityBadgeLayout,
              ),
              StyleSectionLabel(l10n.qualityBadgeShape, accent: accent),
              StyleSegmentedChoice<QualityBadgeShape>(
                values: QualityBadgeShape.values,
                selected: style.shape,
                accent: accent,
                label: (sh) => switch (sh) {
                  QualityBadgeShape.pill => l10n.qualityBadgeShapePill,
                  QualityBadgeShape.rounded => l10n.qualityBadgeShapeRounded,
                  QualityBadgeShape.square => l10n.qualityBadgeShapeSquare,
                },
                onSelected: notifier.updateQualityBadgeShape,
              ),
              StyleSectionLabel(l10n.qualityBadgeLook, accent: accent),
              StyleSegmentedChoice<QualityBadgeLook>(
                values: QualityBadgeLook.values,
                selected: style.look,
                accent: accent,
                label: (l) => switch (l) {
                  QualityBadgeLook.pill => l10n.qualityBadgeLookPill,
                  QualityBadgeLook.outlined => l10n.qualityBadgeLookOutlined,
                  QualityBadgeLook.text => l10n.qualityBadgeLookText,
                },
                onSelected: notifier.updateQualityBadgeLook,
              ),
              StyleSectionLabel(l10n.qualityBadgeIcon, accent: accent),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.7,
                children: [
                  for (final icon in QualityBadgeIcon.values)
                    _IconOption(
                      icon: (color) =>
                          QualityBadge.iconWidget(icon, 18, color) ??
                          Icon(LucideIcons.circleOff, color: color, size: 18),
                      selected: icon == style.icon,
                      accent: accent,
                      onTap: () => notifier.updateQualityBadgeIcon(icon),
                    ),
                ],
              ),
              StyleSectionLabel(l10n.visualizerColors, accent: accent),
              StyleSegmentedChoice<QualityBadgeColors>(
                values: QualityBadgeColors.values,
                selected: style.colors,
                accent: accent,
                label: (c) => switch (c) {
                  QualityBadgeColors.white => l10n.visualizerColorsWhite,
                  QualityBadgeColors.theme => l10n.visualizerColorsTheme,
                  QualityBadgeColors.byQuality =>
                    l10n.qualityBadgeColorsByQuality,
                },
                onSelected: notifier.updateQualityBadgeColors,
              ),
              // Name only shows just the quality level, so these don't apply.
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: nameOnly ? 0.4 : 1,
                child: IgnorePointer(
                  ignoring: nameOnly,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      StyleSectionLabel(
                        l10n.qualityBadgeSeparator,
                        accent: accent,
                      ),
                      StyleSegmentedChoice<QualityBadgeSeparator>(
                        values: QualityBadgeSeparator.values,
                        selected: style.separator,
                        accent: accent,
                        label: (s) => switch (s) {
                          QualityBadgeSeparator.dot => '•',
                          QualityBadgeSeparator.middot => '·',
                          QualityBadgeSeparator.bar => '|',
                          QualityBadgeSeparator.slash => '/',
                        },
                        onSelected: notifier.updateQualityBadgeSeparator,
                      ),
                      StyleSectionLabel(
                        l10n.qualityBadgeDetails,
                        accent: accent,
                      ),
                      for (final field in QualityBadgeField.values)
                        StyleSwitchRow(
                          title: fieldLabel(field),
                          value: style.shows(field),
                          accent: accent,
                          // The last detail left on stays on.
                          enabled: !(style.shows(field) && enabledFields == 1),
                          onChanged: (on) =>
                              notifier.updateQualityBadgeField(field, on),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconOption extends StatelessWidget {
  final Widget Function(Color color) icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _IconOption({
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (selected) return;
        AppHaptics.light();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? accent : Colors.white10,
            width: selected ? 1.4 : 0.6,
          ),
        ),
        alignment: Alignment.center,
        child: icon(selected ? accent : Colors.white70),
      ),
    );
  }
}
