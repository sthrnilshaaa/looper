import 'package:looper_player/core/motion/looper_scroll_physics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/features/settings/domain/artwork_visualizer_style.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:looper_player/ui/widgets/player/artwork_visualizer/artwork_visualizer.dart';
import 'package:looper_player/ui/widgets/sheets/app_bottom_sheet.dart';

import 'style_sheet_controls.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';

String artworkVisualizerTypeLabel(
  AppLocalizations l10n,
  ArtworkVisualizerType type,
) => switch (type) {
  ArtworkVisualizerType.none => l10n.none,
  ArtworkVisualizerType.aura => l10n.visualizerAura,
  ArtworkVisualizerType.ring => l10n.visualizerRing,
  ArtworkVisualizerType.wave => l10n.visualizerWave,
  ArtworkVisualizerType.bars => l10n.visualizerBars,
  ArtworkVisualizerType.breathing => l10n.visualizerBreathing,
};

IconData _typeIcon(ArtworkVisualizerType type) => switch (type) {
  ArtworkVisualizerType.none => LucideIcons.circleOff,
  ArtworkVisualizerType.aura => LucideIcons.sun,
  ArtworkVisualizerType.ring => LucideIcons.loaderPinwheel,
  ArtworkVisualizerType.wave => LucideIcons.waves,
  ArtworkVisualizerType.bars => LucideIcons.chartNoAxesColumn,
  ArtworkVisualizerType.breathing => LucideIcons.heartPulse,
};

void showArtworkVisualizerSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _ArtworkVisualizerSheet(),
  );
}

/// Pick the artwork effect, its intensity, colors and audio sync, with the
/// current song's cover (or a placeholder) showing the effect live: on the
/// real audio while a song plays (so the sync can be tuned by ear), on a
/// made-up spectrum otherwise.
class _ArtworkVisualizerSheet extends ConsumerStatefulWidget {
  const _ArtworkVisualizerSheet();

  @override
  ConsumerState<_ArtworkVisualizerSheet> createState() =>
      _ArtworkVisualizerSheetState();
}

class _ArtworkVisualizerSheetState
    extends ConsumerState<_ArtworkVisualizerSheet> {
  // The sync slider's value while dragging; saved when the drag ends.
  double? _syncDraft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final saved = ref.watch(
      settingsProvider.select(ArtworkVisualizerStyle.fromSettings),
    );
    final style = _syncDraft == null
        ? saved
        : saved.copyWith(syncMs: _syncDraft!.round());
    final bool playing = ref.watch(playbackProvider.select((s) => s.isPlaying));
    final accent = Color(
      ref.watch(settingsProvider.select((s) => s.accentColor)),
    );
    final String? artPath = ref.watch(
      playbackProvider.select((s) => s.currentSong?.artPath),
    );
    final notifier = ref.read(settingsProvider.notifier);
    final bool off = style.type == ArtworkVisualizerType.none;

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
                l10n.artworkVisualizer,
                style: AppFonts.jostStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.artworkVisualizerDesc,
                style: AppFonts.jostStyle(color: Colors.white54, fontSize: 13),
              ),
              // Room around the cover for the aura and the ring.
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: SizedBox.square(
                    dimension: 170,
                    child: ArtworkVisualizer(
                      demo: !playing,
                      style: style,
                      artPath: artPath,
                      child: _PreviewCover(artPath: artPath),
                    ),
                  ),
                ),
              ),
              StyleSectionLabel(l10n.visualizerEffect, accent: accent),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.25,
                children: [
                  for (final type in ArtworkVisualizerType.values)
                    _EffectOption(
                      icon: _typeIcon(type),
                      label: artworkVisualizerTypeLabel(l10n, type),
                      selected: type == style.type,
                      accent: accent,
                      onTap: () => notifier.updateArtworkVisualizer(type),
                    ),
                ],
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: off ? 0.4 : 1,
                child: IgnorePointer(
                  ignoring: off,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      StyleSectionLabel(
                        l10n.visualizerIntensity,
                        accent: accent,
                      ),
                      StyleSegmentedChoice<ArtworkVisualizerIntensity>(
                        values: ArtworkVisualizerIntensity.values,
                        selected: style.intensity,
                        accent: accent,
                        label: (i) => switch (i) {
                          ArtworkVisualizerIntensity.subtle =>
                            l10n.visualizerSubtle,
                          ArtworkVisualizerIntensity.normal =>
                            l10n.visualizerNormal,
                          ArtworkVisualizerIntensity.strong =>
                            l10n.visualizerStrong,
                        },
                        onSelected: notifier.updateArtworkVisualizerIntensity,
                      ),
                      StyleSectionLabel(l10n.visualizerColors, accent: accent),
                      StyleSegmentedChoice<ArtworkVisualizerColors>(
                        values: ArtworkVisualizerColors.values,
                        selected: style.colors,
                        accent: accent,
                        label: (c) => switch (c) {
                          ArtworkVisualizerColors.artwork =>
                            l10n.visualizerColorsArtwork,
                          ArtworkVisualizerColors.theme =>
                            l10n.visualizerColorsTheme,
                          ArtworkVisualizerColors.white =>
                            l10n.visualizerColorsWhite,
                        },
                        onSelected: notifier.updateArtworkVisualizerColors,
                      ),
                      const SizedBox(height: 8),
                      StyleSliderRow(
                        title: l10n.visualizerSync,
                        subtitle: playing
                            ? l10n.visualizerSyncDesc
                            : '${l10n.visualizerSyncDesc} '
                                  '${l10n.visualizerSyncHint}',
                        valueLabel: '${style.syncMs} ms',
                        value: style.syncMs.toDouble(),
                        min: ArtworkVisualizerStyle.minSyncMs.toDouble(),
                        max: ArtworkVisualizerStyle.maxSyncMs.toDouble(),
                        accent: accent,
                        onChanged: (v) =>
                            setState(() => _syncDraft = (v / 10).round() * 10),
                        onChangeEnd: (v) async {
                          await notifier.updateArtworkVisualizerSyncMs(
                            (v / 10).round() * 10,
                          );
                          if (mounted) setState(() => _syncDraft = null);
                        },
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

class _PreviewCover extends StatelessWidget {
  final String? artPath;

  const _PreviewCover({required this.artPath});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final BorderRadius radius = BorderRadius.circular(12);
    final String? path = artPath;
    if (path != null) {
      return OptimizedImage(
        imagePath: path.startsWith('http') ? null : path,
        imageUrl: path.startsWith('http') ? path : null,
        borderRadius: radius,
        fit: BoxFit.cover,
        cacheWidth: 400,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primaryContainer, colorScheme.surface],
        ),
      ),
      child: Center(
        child: Icon(LucideIcons.music, color: colorScheme.primary, size: 48),
      ),
    );
  }
}

class _EffectOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _EffectOption({
    required this.icon,
    required this.label,
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
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? accent : Colors.white10,
            width: selected ? 1.4 : 0.6,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? accent : Colors.white70, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppFonts.jostStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
