import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import '../settings_dialogs.dart';

class ShowArtistsRowTile extends ConsumerWidget {
  const ShowArtistsRowTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.user, color: Colors.white70),
      title: Text(l10n.showArtistsRow, style: _tileTitleStyle()),
      subtitle: Text(l10n.showArtistsRowDesc, style: _tileSubtitleStyle()),
      activeThumbColor: Color(settings.accentColor),
      value: settings.showHomeArtists,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateShowHomeArtists(value);
      },
    );
  }
}

class ShowAlbumsRowTile extends ConsumerWidget {
  const ShowAlbumsRowTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.disc, color: Colors.white70),
      title: Text(l10n.showAlbumsRow, style: _tileTitleStyle()),
      subtitle: Text(l10n.showAlbumsRowDesc, style: _tileSubtitleStyle()),
      activeThumbColor: Color(settings.accentColor),
      value: settings.showHomeAlbums,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateShowHomeAlbums(value);
      },
    );
  }
}

class ShowGenresRowTile extends ConsumerWidget {
  const ShowGenresRowTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.music, color: Colors.white70),
      title: Text(l10n.showGenresRow, style: _tileTitleStyle()),
      subtitle: Text(l10n.showGenresRowDesc, style: _tileSubtitleStyle()),
      activeThumbColor: Color(settings.accentColor),
      value: settings.showHomeGenres,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateShowHomeGenres(value);
      },
    );
  }
}

class ShowRecentRowTile extends ConsumerWidget {
  const ShowRecentRowTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.history, color: Colors.white70),
      title: Text(l10n.showRecentRow, style: _tileTitleStyle()),
      subtitle: Text(l10n.showRecentRowDesc, style: _tileSubtitleStyle()),
      activeThumbColor: Color(settings.accentColor),
      value: settings.showHomeRecent,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateShowHomeRecent(value);
      },
    );
  }
}

class ReorderDashboardSectionsTile extends ConsumerWidget {
  const ReorderDashboardSectionsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(LucideIcons.listOrdered, color: Colors.white70),
      title: Text(l10n.reorderDashboardSections, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.reorderDashboardSectionsDesc,
        style: _tileSubtitleStyle(),
      ),
      trailing: const Icon(LucideIcons.chevronRight, color: Colors.white30),
      onTap: () {
        showReorderBottomSheet(context, ref, settings);
      },
    );
  }
}

TextStyle _tileTitleStyle() =>
    AppFonts.jostStyle(color: Colors.white, fontWeight: FontWeight.w500);

TextStyle _tileSubtitleStyle() =>
    AppFonts.jostStyle(color: Colors.white54, fontSize: 12);
