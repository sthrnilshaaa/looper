part of 'theme_settings_tiles.dart';

class FlatProgressBarTile extends ConsumerWidget {
  const FlatProgressBarTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.sliders, color: Colors.white70),
      title: Text(l10n.flatProgressBar, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.disableSquigglyProgressBar,
        style: _tileSubtitleStyle(),
      ),
      activeThumbColor: Color(settings.accentColor),
      value: settings.disableSquiggle,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateDisableSquiggle(value);
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
