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
      leading: const Icon(LucideIcons.slidersHorizontal, color: Colors.white70),
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
      leading: const Icon(LucideIcons.audioLines, color: Colors.white70),
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
      secondary: const Icon(LucideIcons.clock, color: Colors.white70),
      title: Text(l10n.plainTimestamps, style: _tileTitleStyle()),
      subtitle: Text(l10n.useStaticTextTimestamps, style: _tileSubtitleStyle()),
      activeThumbColor: Color(settings.accentColor),
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
      secondary: const Icon(LucideIcons.info, color: Colors.white70),
      title: Text(l10n.showQualityBadge, style: _tileTitleStyle()),
      subtitle: Text(l10n.showQualityBadgeDesc, style: _tileSubtitleStyle()),
      activeThumbColor: Color(settings.accentColor),
      value: settings.showQualityBadge,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateShowQualityBadge(value);
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
      secondary: const Icon(LucideIcons.libraryBig, color: Colors.white70),
      title: Text(l10n.groupByAlbum, style: _tileTitleStyle()),
      subtitle: Text(l10n.groupByAlbumDesc, style: _tileSubtitleStyle()),
      activeThumbColor: Color(settings.accentColor),
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
      secondary: const Icon(LucideIcons.disc3, color: Colors.white70),
      title: Text(l10n.showAlbumNextToArtist, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.showAlbumNextToArtistDesc,
        style: _tileSubtitleStyle(),
      ),
      activeThumbColor: Color(settings.accentColor),
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
      secondary: const Icon(LucideIcons.sparkles, color: Colors.white70),
      title: Text(l10n.showAlbumInQuickPicks, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.showAlbumInQuickPicksDesc,
        style: _tileSubtitleStyle(),
      ),
      activeThumbColor: Color(settings.accentColor),
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
      leading: const Icon(LucideIcons.badgeCheck, color: Colors.white70),
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
      secondary: const Icon(LucideIcons.columns4, color: Colors.white70),
      title: Text(l10n.segmentedUtilityButtons, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.segmentedUtilityButtonsDesc,
        style: _tileSubtitleStyle(),
      ),
      activeThumbColor: Color(settings.accentColor),
      value: settings.segmentedUtilityButtons,
      onChanged: (value) {
        ref
            .read(settingsProvider.notifier)
            .updateSegmentedUtilityButtons(value);
      },
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
      secondary: const Icon(LucideIcons.sparkles, color: Colors.white70),
      title: Text(l10n.enablePlayerGradient, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.enablePlayerGradientDesc,
        style: _tileSubtitleStyle(),
      ),
      activeThumbColor: Color(settings.accentColor),
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
      secondary: const Icon(LucideIcons.audioWaveform, color: Colors.white70),
      title: Text(l10n.animatePlayerGradient, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.animatePlayerGradientDesc,
        style: _tileSubtitleStyle(),
      ),
      activeThumbColor: Color(settings.accentColor),
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
      secondary: const Icon(LucideIcons.layers, color: Colors.white70),
      title: Text(l10n.keepBackgroundGradient, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.keepBackgroundGradientDesc,
        style: _tileSubtitleStyle(),
      ),
      activeThumbColor: Color(settings.accentColor),
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
      secondary: const Icon(LucideIcons.waves, color: Colors.white70),
      title: Text(l10n.animateBackgroundGradient, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.animateBackgroundGradientDesc,
        style: _tileSubtitleStyle(),
      ),
      activeThumbColor: Color(settings.accentColor),
      value: settings.animateBackgroundGradient,
      onChanged: (value) {
        ref
            .read(settingsProvider.notifier)
            .updateAnimateBackgroundGradient(value);
      },
    );
  }
}
