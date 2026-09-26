import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import '../../settings_widgets.dart';

class HomeDarknessSlider extends ConsumerWidget {
  const HomeDarknessSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SettingsSliderTile(
      icon: LucideIcons.home,
      title: l10n.homeDarkness,
      subtitle: l10n.homeDarknessDesc,
      value: (settings.homeDarkness.isNaN ? 0.72 : settings.homeDarkness) * 100,
      min: 0.0,
      max: 100.0,
      divisions: 100,
      suffix: '%',
      onChanged: (val) {
        ref.read(settingsProvider.notifier).updateHomeDarkness(val / 100.0);
      },
    );
  }
}

class SongsDarknessSlider extends ConsumerWidget {
  const SongsDarknessSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SettingsSliderTile(
      icon: LucideIcons.music,
      title: l10n.songsDarkness,
      subtitle: l10n.songsDarknessDesc,
      value:
          (settings.songsDarkness.isNaN ? 0.72 : settings.songsDarkness) * 100,
      min: 0.0,
      max: 100.0,
      divisions: 100,
      suffix: '%',
      onChanged: (val) {
        ref.read(settingsProvider.notifier).updateSongsDarkness(val / 100.0);
      },
    );
  }
}

class LibraryDarknessSlider extends ConsumerWidget {
  const LibraryDarknessSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SettingsSliderTile(
      icon: LucideIcons.library,
      title: l10n.libraryDarkness,
      subtitle: l10n.libraryDarknessDesc,
      value:
          (settings.libraryDarkness.isNaN ? 0.72 : settings.libraryDarkness) *
          100,
      min: 0.0,
      max: 100.0,
      divisions: 100,
      suffix: '%',
      onChanged: (val) {
        ref.read(settingsProvider.notifier).updateLibraryDarkness(val / 100.0);
      },
    );
  }
}

class MusicDarknessSlider extends ConsumerWidget {
  const MusicDarknessSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SettingsSliderTile(
      icon: LucideIcons.playCircle,
      title: l10n.musicDarkness,
      subtitle: l10n.musicDarknessDesc,
      value:
          (settings.musicDarkness.isNaN ? 0.62 : settings.musicDarkness) * 100,
      min: 0.0,
      max: 100.0,
      divisions: 100,
      suffix: '%',
      onChanged: (val) {
        ref.read(settingsProvider.notifier).updateMusicDarkness(val / 100.0);
      },
    );
  }
}

class LyricsDarknessSlider extends ConsumerWidget {
  const LyricsDarknessSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SettingsSliderTile(
      icon: LucideIcons.alignLeft,
      title: l10n.lyricsDarkness,
      subtitle: l10n.lyricsDarknessDesc,
      value:
          (settings.lyricsDarkness.isNaN ? 0.55 : settings.lyricsDarkness) *
          100,
      min: 0.0,
      max: 100.0,
      divisions: 100,
      suffix: '%',
      onChanged: (val) {
        ref.read(settingsProvider.notifier).updateLyricsDarkness(val / 100.0);
      },
    );
  }
}
