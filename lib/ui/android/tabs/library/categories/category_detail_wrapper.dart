import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/android/widgets/premium_section.dart';
import 'package:looper_player/ui/widgets/sheets/app_bottom_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'library_categories_views.dart';

class CategoryDetailWrapper extends ConsumerWidget {
  final String title;
  final Widget child;
  const CategoryDetailWrapper({
    super.key,
    required this.title,
    required this.child,
  });

  void _showSortBottomSheet(
    BuildContext context,
    WidgetRef ref,
    String title,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AppBottomSheetContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.sortBy,
                style: AppFonts.jostStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              PremiumSection(
                borderRadius: BorderRadius.circular(20),
                padding: EdgeInsets.zero,
                useExpanded: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title == 'Albums') ...[
                      _buildSortItem(
                        context,
                        ref,
                        l10n.sortAlphabeticalAZ,
                        AlbumSortOption.nameAsc.index,
                        'album',
                      ),
                      const Divider(
                        color: Colors.white10,
                        height: 1,
                        indent: 20,
                        endIndent: 20,
                      ),
                      _buildSortItem(
                        context,
                        ref,
                        l10n.sortAlphabeticalZA,
                        AlbumSortOption.nameDesc.index,
                        'album',
                      ),
                      const Divider(
                        color: Colors.white10,
                        height: 1,
                        indent: 20,
                        endIndent: 20,
                      ),
                      _buildSortItem(
                        context,
                        ref,
                        l10n.sortRecentlyAdded,
                        AlbumSortOption.dateAddedNewest.index,
                        'album',
                      ),
                      const Divider(
                        color: Colors.white10,
                        height: 1,
                        indent: 20,
                        endIndent: 20,
                      ),
                      _buildSortItem(
                        context,
                        ref,
                        l10n.sortOldestAdded,
                        AlbumSortOption.dateAddedOldest.index,
                        'album',
                      ),
                      const Divider(
                        color: Colors.white10,
                        height: 1,
                        indent: 20,
                        endIndent: 20,
                      ),
                      _buildSortItem(
                        context,
                        ref,
                        l10n.sortYearNewest,
                        AlbumSortOption.yearNewest.index,
                        'album',
                      ),
                      const Divider(
                        color: Colors.white10,
                        height: 1,
                        indent: 20,
                        endIndent: 20,
                      ),
                      _buildSortItem(
                        context,
                        ref,
                        l10n.sortYearOldest,
                        AlbumSortOption.yearOldest.index,
                        'album',
                      ),
                    ] else if (title == 'Artists') ...[
                      _buildSortItem(
                        context,
                        ref,
                        l10n.sortAlphabeticalAZ,
                        ArtistSortOption.nameAsc.index,
                        'artist',
                      ),
                      const Divider(
                        color: Colors.white10,
                        height: 1,
                        indent: 20,
                        endIndent: 20,
                      ),
                      _buildSortItem(
                        context,
                        ref,
                        l10n.sortAlphabeticalZA,
                        ArtistSortOption.nameDesc.index,
                        'artist',
                      ),
                    ] else if (title == 'Genres') ...[
                      _buildSortItem(
                        context,
                        ref,
                        l10n.sortAlphabeticalAZ,
                        GenreSortOption.nameAsc.index,
                        'genre',
                      ),
                      const Divider(
                        color: Colors.white10,
                        height: 1,
                        indent: 20,
                        endIndent: 20,
                      ),
                      _buildSortItem(
                        context,
                        ref,
                        l10n.sortAlphabeticalZA,
                        GenreSortOption.nameDesc.index,
                        'genre',
                      ),
                      const Divider(
                        color: Colors.white10,
                        height: 1,
                        indent: 20,
                        endIndent: 20,
                      ),
                      _buildSortItem(
                        context,
                        ref,
                        l10n.sortMostSongs,
                        GenreSortOption.songCountDesc.index,
                        'genre',
                      ),
                      const Divider(
                        color: Colors.white10,
                        height: 1,
                        indent: 20,
                        endIndent: 20,
                      ),
                      _buildSortItem(
                        context,
                        ref,
                        l10n.sortLeastSongs,
                        GenreSortOption.songCountAsc.index,
                        'genre',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortItem(
    BuildContext context,
    WidgetRef ref,
    String label,
    int valueIndex,
    String categoryType,
  ) {
    final settings = ref.watch(settingsProvider);
    final int currentVal;
    if (categoryType == 'album') {
      currentVal = settings.albumSortOptionIndex;
    } else if (categoryType == 'artist') {
      currentVal = settings.artistSortOptionIndex;
    } else {
      currentVal = settings.genreSortOptionIndex;
    }
    final isSelected = currentVal == valueIndex;
    final accentColor = Color(settings.accentColor);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        if (categoryType == 'album') {
          ref
              .read(settingsProvider.notifier)
              .updateAlbumSortOptionIndex(valueIndex);
        } else if (categoryType == 'artist') {
          ref
              .read(settingsProvider.notifier)
              .updateArtistSortOptionIndex(valueIndex);
        } else {
          ref
              .read(settingsProvider.notifier)
              .updateGenreSortOptionIndex(valueIndex);
        }
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppFonts.jostStyle(
                color: isSelected ? accentColor : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
              ),
            ),
            if (isSelected)
              Icon(LucideIcons.check, color: accentColor, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    String translatedTitle = title;
    switch (title) {
      case 'Albums':
        translatedTitle = l10n.albums;
        break;
      case 'Artists':
        translatedTitle = l10n.artists;
        break;
      case 'Genres':
        translatedTitle = l10n.genres;
        break;
      case 'Folders':
        translatedTitle = l10n.folders;
        break;
      case 'Queue':
        translatedTitle = l10n.queue;
        break;
      case 'History':
        translatedTitle = l10n.history;
        break;
      case 'Favorites':
        translatedTitle = l10n.favorites;
        break;
      case 'Playlists':
        translatedTitle = l10n.playlists;
        break;
      case 'Recently Played':
        translatedTitle = l10n.recentlyPlayed;
        break;
    }

    final showSortButton =
        title == 'Albums' || title == 'Artists' || title == 'Genres';

    return Scaffold(
      // Not Colors.transparent: this screen is reached via a non-opaque
      // PageRoute (_createPremiumRoute) meant to let the black root screen
      // underneath show through, but that compositing isn't reliable on
      // every device/renderer combo (seen as a white/native-window-
      // background flash on some devices, e.g. Albums/Artists/Genres).
      // Painting an explicit opaque background removes the dependency on
      // that compositing entirely.
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
              child: Row(
                children: [
                  PremiumSection(
                    useExpanded: false,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      bottomLeft: Radius.circular(32),
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                    width: 44,
                    height: 44,
                    onTap: () =>
                        ref.read(appNavigationProvider.notifier).goBack(),
                    child: const Icon(
                      LucideIcons.chevronLeft,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      translatedTitle,
                      style: AppFonts.jostStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (showSortButton) ...[
                    const SizedBox(width: 8),
                    PremiumSection(
                      useExpanded: false,
                      borderRadius: BorderRadius.circular(22),
                      width: 44,
                      height: 44,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showSortBottomSheet(context, ref, title, l10n);
                      },
                      child: const Icon(
                        LucideIcons.arrowUpDown,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
