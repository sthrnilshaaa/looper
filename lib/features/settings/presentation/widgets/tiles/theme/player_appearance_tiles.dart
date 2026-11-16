part of 'theme_settings_tiles.dart';

/// Opens the progress bar style sheet (wave, thickness, thumb, ...). Took
/// over the old "Flat progress bar" switch, which is now the sheet's Wave
/// toggle.
class ProgressBarStyleTile extends ConsumerWidget {
  const ProgressBarStyleTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(LucideIcons.slidersHorizontal),
      title: Text(l10n.progressBarStyle, style: _tileTitleStyle()),
      subtitle: Text(l10n.progressBarStyleDesc, style: _tileSubtitleStyle()),
      trailing: const Icon(
        LucideIcons.chevronRight,
        color: Colors.white38,
        size: 20,
      ),
      onTap: () {
        AppHaptics.light();
        showProgressBarStyleSheet(context);
      },
    );
  }
}

/// Opens the artwork visualizer sheet (effect, intensity, colors).
class ArtworkVisualizerTile extends ConsumerWidget {
  const ArtworkVisualizerTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final type = ref.watch(
      settingsProvider.select(
        (s) => ArtworkVisualizerStyle.fromSettings(s).type,
      ),
    );
    return ListTile(
      leading: const Icon(LucideIcons.audioLines),
      title: Text(l10n.artworkVisualizer, style: _tileTitleStyle()),
      subtitle: Text(
        type == ArtworkVisualizerType.none
            ? l10n.artworkVisualizerDesc
            : artworkVisualizerTypeLabel(l10n, type),
        style: _tileSubtitleStyle(),
      ),
      trailing: const Icon(
        LucideIcons.chevronRight,
        color: Colors.white38,
        size: 20,
      ),
      onTap: () {
        AppHaptics.light();
        showArtworkVisualizerSheet(context);
      },
    );
  }
}

class PlainTimestampsTile extends ConsumerWidget {
  const PlainTimestampsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.clock),
      title: Text(l10n.plainTimestamps, style: _tileTitleStyle()),
      subtitle: Text(l10n.useStaticTextTimestamps, style: _tileSubtitleStyle()),
      value: settings.disableAnimatedDuration,
      onChanged: (value) {
        ref
            .read(settingsProvider.notifier)
            .updateDisableAnimatedDuration(value);
      },
    );
  }
}

class ShowQualityBadgeTile extends ConsumerWidget {
  const ShowQualityBadgeTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.info),
      title: Text(l10n.showQualityBadge, style: _tileTitleStyle()),
      subtitle: Text(l10n.showQualityBadgeDesc, style: _tileSubtitleStyle()),
      value: settings.showQualityBadge,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateShowQualityBadge(value);
      },
    );
  }
}

class KeepScreenAwakeTile extends ConsumerWidget {
  const KeepScreenAwakeTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.sun),
      title: Text(l10n.keepScreenAwake, style: _tileTitleStyle()),
      subtitle: Text(l10n.keepScreenAwakeDesc, style: _tileSubtitleStyle()),
      value: settings.keepScreenAwake ?? true,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateKeepScreenAwake(value);
      },
    );
  }
}

class HighRefreshRateTile extends ConsumerWidget {
  const HighRefreshRateTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.gauge),
      title: Text(l10n.highRefreshRate, style: _tileTitleStyle()),
      subtitle: Text(l10n.highRefreshRateDesc, style: _tileSubtitleStyle()),
      value: settings.forceHighRefreshRate ?? true,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateForceHighRefreshRate(value);
      },
    );
  }
}

/// Lists an artist page's songs under album headers. Off by default.
class GroupArtistByAlbumTile extends ConsumerWidget {
  const GroupArtistByAlbumTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.libraryBig),
      title: Text(l10n.groupByAlbum, style: _tileTitleStyle()),
      subtitle: Text(l10n.groupByAlbumDesc, style: _tileSubtitleStyle()),
      value: settings.artistGroupByAlbum,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateArtistGroupByAlbum(value);
      },
    );
  }
}

/// Adds the album after the artist ("Artist • Album") under song titles.
class ShowAlbumNextToArtistTile extends ConsumerWidget {
  const ShowAlbumNextToArtistTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.disc3),
      title: Text(l10n.showAlbumNextToArtist, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.showAlbumNextToArtistDesc,
        style: _tileSubtitleStyle(),
      ),
      value: settings.showAlbumNextToArtist,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateShowAlbumNextToArtist(value);
      },
    );
  }
}

/// Also adds the album in Home's Quick Picks; shown only while
/// [ShowAlbumNextToArtistTile] is on.
class ShowAlbumInQuickPicksTile extends ConsumerWidget {
  const ShowAlbumInQuickPicksTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.sparkles),
      title: Text(l10n.showAlbumInQuickPicks, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.showAlbumInQuickPicksDesc,
        style: _tileSubtitleStyle(),
      ),
      value: settings.showAlbumInQuickPicks,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateShowAlbumInQuickPicks(value);
      },
    );
  }
}

/// Opens the quality badge style sheet (look, icon, colors, details).
class QualityBadgeStyleTile extends ConsumerWidget {
  const QualityBadgeStyleTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(LucideIcons.badgeCheck),
      title: Text(l10n.qualityBadgeStyle, style: _tileTitleStyle()),
      subtitle: Text(l10n.qualityBadgeStyleDesc, style: _tileSubtitleStyle()),
      trailing: const Icon(
        LucideIcons.chevronRight,
        color: Colors.white38,
        size: 20,
      ),
      onTap: () {
        AppHaptics.light();
        showQualityBadgeSheet(context);
      },
    );
  }
}

/// Swaps the player's shuffle / repeat / next up / lyrics pill groups for
/// four icon-only tiles styled like the prev / play / next row.
class SegmentedUtilityButtonsTile extends ConsumerWidget {
  const SegmentedUtilityButtonsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.columns4),
      title: Text(l10n.segmentedUtilityButtons, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.segmentedUtilityButtonsDesc,
        style: _tileSubtitleStyle(),
      ),
      value: settings.segmentedUtilityButtons,
      onChanged: (value) {
        ref
            .read(settingsProvider.notifier)
            .updateSegmentedUtilityButtons(value);
      },
    );
  }
}

/// Shows the current lyric line under the player's cover.
class PlayerLyricLineTile extends ConsumerWidget {
  const PlayerLyricLineTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.micVocal),
      title: Text(l10n.playerLyricLine, style: _tileTitleStyle()),
      subtitle: Text(l10n.playerLyricLineDesc, style: _tileSubtitleStyle()),
      value: settings.playerLyricLine,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updatePlayerLyricLine(value);
      },
    );
  }
}

/// Portrait Now Playing layout: classic, arc or linear.
class PlayerStyleTile extends ConsumerWidget {
  const PlayerStyleTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    final current = settings.playerStyle.isEmpty
        ? 'classic'
        : settings.playerStyle;
    final options = [
      ('classic', l10n.playerStyleClassic),
      ('arc', l10n.playerStyleArc),
      ('linear', l10n.playerStyleLinear),
      ('card', l10n.playerStyleCard),
    ];
    final styleTile = ListTile(
      leading: const Icon(LucideIcons.layoutTemplate),
      title: Text(l10n.playerStyle, style: _tileTitleStyle()),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PlayerStylePreview(style: current, accent: settings.accent),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (value, label) in options)
                  ChoiceChip(
                    label: Text(label),
                    selected: current == value,
                    showCheckmark: false,
                    selectedColor: Colors.white.withValues(alpha: 0.15),
                    onSelected: (_) {
                      AppHaptics.selection();
                      ref
                          .read(settingsProvider.notifier)
                          .updatePlayerStyle(value);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    if (current == 'classic') return styleTile;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        styleTile,
        SwitchListTile(
          secondary: const Icon(LucideIcons.moon),
          title: Text(l10n.cardBlackBackground, style: _tileTitleStyle()),
          subtitle: Text(
            l10n.cardBlackBackgroundDesc,
            style: _tileSubtitleStyle(),
          ),
          value: settings.cardBlackBackground,
          onChanged: (value) {
            AppHaptics.selection();
            ref
                .read(settingsProvider.notifier)
                .updateCardBlackBackground(value);
          },
        ),
        if (!settings.cardBlackBackground) ...[
          SwitchListTile(
            secondary: const Icon(LucideIcons.paintBucket),
            title: Text(
              l10n.cardAccentBackground,
              style: _tileTitleStyle(),
            ),
            subtitle: Text(
              l10n.cardAccentBackgroundDesc,
              style: _tileSubtitleStyle(),
            ),
            value: settings.cardAccentBackground,
            onChanged: (value) {
              AppHaptics.selection();
              ref
                  .read(settingsProvider.notifier)
                  .updateCardAccentBackground(value);
            },
          ),
          if (settings.cardAccentBackground) ...[
            const EnablePlayerGradientTile(),
            if (settings.enablePlayerGradient)
              const AnimatePlayerGradientTile(),
          ] else ...[
            SwitchListTile(
              secondary: const Icon(LucideIcons.sparkles),
              title: Text(
                l10n.playerStyleBlurBackground,
                style: _tileTitleStyle(),
              ),
              subtitle: Text(
                l10n.playerStyleBlurBackgroundDesc,
                style: _tileSubtitleStyle(),
              ),
              value: settings.playerStyleBlur,
              onChanged: (value) {
                AppHaptics.selection();
                ref
                    .read(settingsProvider.notifier)
                    .updatePlayerStyleBlur(value);
              },
            ),
          ],
        ],
        // Separate toggle: accent color for lyrics line + progress bar.
        SwitchListTile(
          secondary: const Icon(LucideIcons.palette),
          title: Text(l10n.cardAccentColors, style: _tileTitleStyle()),
          subtitle: Text(
            l10n.cardAccentColorsDesc,
            style: _tileSubtitleStyle(),
          ),
          value: settings.cardAccentColors || settings.playerStyleAccent,
          onChanged: (value) {
            AppHaptics.selection();
            ref
                .read(settingsProvider.notifier)
                .updateCardAccentColors(value);
          },
        ),
      ],
    );
  }
}

/// How that line changes to the next: cube, rolling, flip or blur.
class PlayerLyricLineTransitionTile extends ConsumerWidget {
  const PlayerLyricLineTransitionTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    final accent = settings.accent;
    final current = settings.playerLyricLineTransition.isEmpty
        ? 'cube'
        : settings.playerLyricLineTransition;
    final options = [
      ('cube', l10n.lyricLineTransitionCube),
      ('roll', l10n.lyricLineTransitionRoll),
      ('flip', l10n.lyricLineTransitionFlip),
      ('blur', l10n.lyricLineTransitionBlur),
    ];
    return ListTile(
      leading: const Icon(LucideIcons.box),
      title: Text(l10n.playerLyricLineTransition, style: _tileTitleStyle()),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (value, label) in options)
              ChoiceChip(
                label: Text(label),
                selected: current == value,
                showCheckmark: false,
                selectedColor: Colors.white.withValues(alpha: 0.15),
                onSelected: (_) {
                  AppHaptics.selection();
                  ref
                      .read(settingsProvider.notifier)
                      .updatePlayerLyricLineTransition(value);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class EnablePlayerGradientTile extends ConsumerWidget {
  const EnablePlayerGradientTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.sparkles),
      title: Text(l10n.enablePlayerGradient, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.enablePlayerGradientDesc,
        style: _tileSubtitleStyle(),
      ),
      value: settings.enablePlayerGradient,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateEnablePlayerGradient(value);
      },
    );
  }
}

class AnimatePlayerGradientTile extends ConsumerWidget {
  const AnimatePlayerGradientTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.audioWaveform),
      title: Text(l10n.animatePlayerGradient, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.animatePlayerGradientDesc,
        style: _tileSubtitleStyle(),
      ),
      value: settings.animatePlayerGradient,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateAnimatePlayerGradient(value);
      },
    );
  }
}

class KeepBackgroundGradientTile extends ConsumerWidget {
  const KeepBackgroundGradientTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.layers),
      title: Text(l10n.keepBackgroundGradient, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.keepBackgroundGradientDesc,
        style: _tileSubtitleStyle(),
      ),
      value: settings.keepBackgroundGradient,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateKeepBackgroundGradient(value);
      },
    );
  }
}

class AnimateBackgroundGradientTile extends ConsumerWidget {
  const AnimateBackgroundGradientTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.waves),
      title: Text(l10n.animateBackgroundGradient, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.animateBackgroundGradientDesc,
        style: _tileSubtitleStyle(),
      ),
      value: settings.animateBackgroundGradient,
      onChanged: (value) {
        ref
            .read(settingsProvider.notifier)
            .updateAnimateBackgroundGradient(value);
      },
    );
  }
}
