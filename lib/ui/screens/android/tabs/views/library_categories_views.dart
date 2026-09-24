import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/ui/widgets/app_loading_indicator.dart';
import 'package:looper_player/ui/widgets/app_refresh_indicator.dart';
import 'package:looper_player/core/db_service.dart';
import 'package:looper_player/core/navigation_provider.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/library/presentation/library_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/screens/android/widgets/premium_section.dart';
import 'package:looper_player/ui/widgets/optimized_image.dart';
import 'package:looper_player/ui/widgets/app_bottom_sheet.dart';
import 'package:looper_player/ui/widgets/empty_state_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:isar_community/isar.dart';
import 'package:looper_player/features/settings/presentation/settings_notifier.dart';
import 'package:looper_player/core/app_fonts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_categories_views.g.dart';

enum AlbumSortOption { nameAsc, nameDesc, dateAddedNewest, dateAddedOldest, yearNewest, yearOldest }
enum ArtistSortOption { nameAsc, nameDesc }
enum GenreSortOption { nameAsc, nameDesc, songCountDesc, songCountAsc }

/// Memoized per sort option so switching screens/rebuilding this view
/// doesn't tear down and recreate the underlying Isar watch (which briefly
/// re-shows the loading state) - the previous inline `switch` in
/// AlbumsGridView.build() opened a brand-new Stream on every rebuild.
@Riverpod(keepAlive: true)
Stream<List<Album>> albumsSorted(Ref ref, AlbumSortOption sortOption) {
  switch (sortOption) {
    case AlbumSortOption.nameAsc:
      return DbService.isar.albums.where().sortByName().watch(fireImmediately: true);
    case AlbumSortOption.nameDesc:
      return DbService.isar.albums.where().sortByNameDesc().watch(fireImmediately: true);
    case AlbumSortOption.dateAddedNewest:
      return DbService.isar.albums.where().sortByDateAddedDesc().watch(fireImmediately: true);
    case AlbumSortOption.dateAddedOldest:
      return DbService.isar.albums.where().sortByDateAdded().watch(fireImmediately: true);
    case AlbumSortOption.yearNewest:
      return DbService.isar.albums.where().sortByYearDesc().watch(fireImmediately: true);
    case AlbumSortOption.yearOldest:
      return DbService.isar.albums.where().sortByYear().watch(fireImmediately: true);
  }
}

/// Memoized on the library's artist list + sort option, instead of
/// re-sorting the full artist list on every rebuild of ArtistsGridView.
@Riverpod(keepAlive: true)
List<Artist> artistsSorted(Ref ref, ArtistSortOption sortOption) {
  final artists = ref.watch(libraryProvider.select((s) => s.artists));
  final sorted = List<Artist>.from(artists);
  if (sortOption == ArtistSortOption.nameAsc) {
    sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  } else {
    sorted.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
  }
  return sorted;
}

class CategoryDetailWrapper extends ConsumerWidget {
  final String title;
  final Widget child;
  const CategoryDetailWrapper({super.key, required this.title, required this.child});

  void _showSortBottomSheet(BuildContext context, WidgetRef ref, String title, AppLocalizations l10n) {
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
                      _buildSortItem(context, ref, l10n.sortAlphabeticalAZ, AlbumSortOption.nameAsc.index, 'album'),
                      const Divider(color: Colors.white10, height: 1, indent: 20, endIndent: 20),
                      _buildSortItem(context, ref, l10n.sortAlphabeticalZA, AlbumSortOption.nameDesc.index, 'album'),
                      const Divider(color: Colors.white10, height: 1, indent: 20, endIndent: 20),
                      _buildSortItem(context, ref, l10n.sortRecentlyAdded, AlbumSortOption.dateAddedNewest.index, 'album'),
                      const Divider(color: Colors.white10, height: 1, indent: 20, endIndent: 20),
                      _buildSortItem(context, ref, l10n.sortOldestAdded, AlbumSortOption.dateAddedOldest.index, 'album'),
                      const Divider(color: Colors.white10, height: 1, indent: 20, endIndent: 20),
                      _buildSortItem(context, ref, l10n.sortYearNewest, AlbumSortOption.yearNewest.index, 'album'),
                      const Divider(color: Colors.white10, height: 1, indent: 20, endIndent: 20),
                      _buildSortItem(context, ref, l10n.sortYearOldest, AlbumSortOption.yearOldest.index, 'album'),
                    ] else if (title == 'Artists') ...[
                      _buildSortItem(context, ref, l10n.sortAlphabeticalAZ, ArtistSortOption.nameAsc.index, 'artist'),
                      const Divider(color: Colors.white10, height: 1, indent: 20, endIndent: 20),
                      _buildSortItem(context, ref, l10n.sortAlphabeticalZA, ArtistSortOption.nameDesc.index, 'artist'),
                    ] else if (title == 'Genres') ...[
                      _buildSortItem(context, ref, l10n.sortAlphabeticalAZ, GenreSortOption.nameAsc.index, 'genre'),
                      const Divider(color: Colors.white10, height: 1, indent: 20, endIndent: 20),
                      _buildSortItem(context, ref, l10n.sortAlphabeticalZA, GenreSortOption.nameDesc.index, 'genre'),
                      const Divider(color: Colors.white10, height: 1, indent: 20, endIndent: 20),
                      _buildSortItem(context, ref, l10n.sortMostSongs, GenreSortOption.songCountDesc.index, 'genre'),
                      const Divider(color: Colors.white10, height: 1, indent: 20, endIndent: 20),
                      _buildSortItem(context, ref, l10n.sortLeastSongs, GenreSortOption.songCountAsc.index, 'genre'),
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
          ref.read(settingsProvider.notifier).updateAlbumSortOptionIndex(valueIndex);
        } else if (categoryType == 'artist') {
          ref.read(settingsProvider.notifier).updateArtistSortOptionIndex(valueIndex);
        } else {
          ref.read(settingsProvider.notifier).updateGenreSortOptionIndex(valueIndex);
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
    }

    final showSortButton = title == 'Albums' || title == 'Artists' || title == 'Genres';

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
                    onTap: () => ref.read(appNavigationProvider.notifier).goBack(),
                    child: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      translatedTitle,
                      style: AppFonts.jostStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white),
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
                      child: const Icon(LucideIcons.arrowUpDown, color: Colors.white, size: 18),
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

class AlbumsGridView extends ConsumerWidget {
  const AlbumsGridView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sortOptionIndex = ref.watch(settingsProvider.select((s) => s.albumSortOptionIndex));
    final sortOption = AlbumSortOption.values[sortOptionIndex.clamp(0, AlbumSortOption.values.length - 1)];
    final albumsAsync = ref.watch(albumsSortedProvider(sortOption));

    return Builder(
      builder: (context) {
        if (!albumsAsync.hasValue) return const AppLoadingIndicator();
        final albums = albumsAsync.requireValue;
        if (albums.isEmpty) {
          return EmptyStateCard(icon: LucideIcons.disc, title: l10n.noAlbumsFound);
        }

        // A plain `childAspectRatio` sizes the *whole* card (art + text) to a fixed
        // ratio, so the art itself ends up a hair taller or shorter than it is wide
        // depending on screen width -- that's what read as "not symmetric". Instead
        // compute the column width ourselves, force the art to a true 1:1 square,
        // and give every card the exact same fixed text-block height below it.
        return LayoutBuilder(
          builder: (context, constraints) {
            const crossAxisSpacing = 24.0;
            const horizontalPadding = 24.0;
            const textBlockHeight = 54.0; // 12 gap + title line + subtitle line
            // Was a fixed 2 columns regardless of width - on a landscape
            // phone/tablet that leaves only 2 needlessly huge cards instead
            // of using the extra width for more columns. Same target column
            // width (~200) as the equivalent grid in library_grids.dart, but
            // as a computed crossAxisCount (at least 2) rather than a fixed
            // maxCrossAxisExtent delegate, so the mainAxisExtent below can
            // still force a true 1:1 square art + fixed text block.
            const targetColumnWidth = 200.0;
            final availableWidth = constraints.maxWidth - horizontalPadding * 2;
            final crossAxisCount = math.max(
              2,
              ((availableWidth + crossAxisSpacing) /
                      (targetColumnWidth + crossAxisSpacing))
                  .floor(),
            );
            final itemWidth =
                (availableWidth - crossAxisSpacing * (crossAxisCount - 1)) /
                    crossAxisCount;

            return GridView.builder(
              padding: const EdgeInsets.only(left: horizontalPadding, right: horizontalPadding, top: 24, bottom: 200),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 24,
                crossAxisSpacing: crossAxisSpacing,
                mainAxisExtent: itemWidth + textBlockHeight,
              ),
              itemCount: albums.length,
              itemBuilder: (context, index) {
                final album = albums[index];
                return InkWell(
                  onTap: () async {
                    final songs = await DbService.isar.songs.filter().albumEqualTo(album.name).findAll();
                    ref.read(appNavigationProvider.notifier).showCollection(
                      title: album.name,
                      subtitle: album.artist ?? l10n.unknownArtist,
                      art: album.artPath,
                      songs: songs,
                      album: album,
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: OptimizedImage(
                            imagePath: album.artPath,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(album.name, style: AppFonts.jostStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(album.artist ?? l10n.unknownArtist, style: AppFonts.jostStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class ArtistsGridView extends ConsumerWidget {
  const ArtistsGridView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sortOptionIndex = ref.watch(settingsProvider.select((s) => s.artistSortOptionIndex));
    final sortOption = ArtistSortOption.values[sortOptionIndex.clamp(0, ArtistSortOption.values.length - 1)];
    final sortedArtists = ref.watch(artistsSortedProvider(sortOption));

    if (sortedArtists.isEmpty) {
      return EmptyStateCard(icon: LucideIcons.user, title: l10n.noArtistsFound);
    }

    return GridView.builder(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 200),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        childAspectRatio: 0.8,
      ),
      itemCount: sortedArtists.length,
      itemBuilder: (context, index) {
        final artist = sortedArtists[index];
        return InkWell(
          onTap: () async {
            final songs = await DbService.isar.songs.filter().artistEqualTo(artist.name).findAll();
            // Correctly distinguish between a local downloaded image and a remote URL
            final imageUrl = artist.artistImageUrl;
            final bool isLocalImage = imageUrl != null && !imageUrl.startsWith('http');
            final bool isNetworkImage = imageUrl != null && imageUrl.startsWith('http');
            ref.read(appNavigationProvider.notifier).showCollection(
              title: artist.name,
              subtitle: l10n.artist,
              art: isLocalImage ? imageUrl : artist.artPath,
              imageUrl: isNetworkImage ? imageUrl : null,
              songs: songs,
            );
          },
          child: Column(
            children: [
              Expanded(
                child: ClipOval(
                  child: OptimizedImage(
                    imageUrl: artist.artistImageUrl != null && artist.artistImageUrl!.startsWith('http') ? artist.artistImageUrl : null,
                    imagePath: artist.artistImageUrl != null && !artist.artistImageUrl!.startsWith('http') ? artist.artistImageUrl : artist.artPath,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      color: Colors.white10,
                      child: const Center(
                        child: Icon(
                          LucideIcons.user,
                          size: 40,
                          color: Colors.white38,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(artist.name, style: AppFonts.jostStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      },
    );
  }
}

class GenresGridView extends ConsumerWidget {
  const GenresGridView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Isar doesn't have a distinct query easily for genres if they are just
    // strings in Songs, so the grouping itself is cached in
    // songsByGenreProvider (memoized on the song list, not this screen's
    // build cycle) - only the localized "Unknown" label is applied here.
    final l10n = AppLocalizations.of(context)!;
    final songsByGenre = ref.watch(songsByGenreProvider);
    final genresMap = <String, List<Song>>{};
    for (final entry in songsByGenre.entries) {
      final genre = entry.key ?? l10n.unknown;
      genresMap.putIfAbsent(genre, () => []).addAll(entry.value);
    }

    final sortOptionIndex = ref.watch(settingsProvider.select((s) => s.genreSortOptionIndex));
    final sortOption = GenreSortOption.values[sortOptionIndex.clamp(0, GenreSortOption.values.length - 1)];
    final genres = genresMap.keys.toList();
    switch (sortOption) {
      case GenreSortOption.nameAsc:
        genres.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        break;
      case GenreSortOption.nameDesc:
        genres.sort((a, b) => b.toLowerCase().compareTo(a.toLowerCase()));
        break;
      case GenreSortOption.songCountDesc:
        genres.sort((a, b) => genresMap[b]!.length.compareTo(genresMap[a]!.length));
        break;
      case GenreSortOption.songCountAsc:
        genres.sort((a, b) => genresMap[a]!.length.compareTo(genresMap[b]!.length));
        break;
    }

    return GridView.builder(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 200),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.35,
      ),
      itemCount: genres.length,
      itemBuilder: (context, index) {
        final genre = genres[index];
        final genreSongs = genresMap[genre]!;
        
        // Hash the genre string to produce a consistent vibrant color gradient
        final int hash = genre.hashCode;
        final double hue = (hash.abs() % 360).toDouble();
        final Color startColor = HSLColor.fromAHSL(1.0, hue, 0.70, 0.35).toColor();
        final Color endColor = HSLColor.fromAHSL(1.0, (hue + 45) % 360, 0.80, 0.18).toColor();

        // Get first song with art if available
        final firstSongWithArt = genreSongs.firstWhere(
          (s) => s.artPath != null,
          orElse: () => genreSongs.first,
        );

        return InkWell(
          onTap: () {
            // Pick the first song with art as the genre cover
            final firstWithArt = genreSongs.firstWhere(
              (s) => s.artPath != null,
              orElse: () => genreSongs.first,
            );
            ref.read(appNavigationProvider.notifier).showCollection(
              title: genre,
              subtitle: l10n.genre,
              art: firstWithArt.artPath,
              songs: genreSongs,
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [startColor, endColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Rotated Album Art in the bottom right corner
                if (firstSongWithArt.artPath != null)
                  Positioned(
                    bottom: -12,
                    right: -12,
                    child: Transform.rotate(
                      angle: 0.25,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(2, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: OptimizedImage(
                            imagePath: firstSongWithArt.artPath,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Positioned(
                    bottom: -10,
                    right: -10,
                    child: Transform.rotate(
                      angle: 0.25,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          LucideIcons.music,
                          size: 28,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                
                // Genre info on the left side
                Positioned(
                  left: 16,
                  top: 16,
                  bottom: 16,
                  right: 56, // Leave room so text doesn't overlap the album art too much
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        genre,
                        style: AppFonts.jostStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${genreSongs.length} ${l10n.songs}',
                        style: AppFonts.jostStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class FoldersListView extends ConsumerWidget {
  const FoldersListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // Grouping is cached in songsByFolderProvider (memoized on the song
    // list, not this screen's build cycle) instead of redone here inline.
    final foldersMap = ref.watch(songsByFolderProvider);
    final folders = foldersMap.keys.toList()..sort();

    return AppRefreshIndicator(
      onRefresh: () => ref.read(libraryProvider.notifier).scanSavedFolders(showVisualIndicator: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 200),
        itemCount: folders.length,
        itemBuilder: (context, index) {
          final folderPath = folders[index];
          final folderName = folderPath.split(Platform.pathSeparator).last;
          final folderSongs = foldersMap[folderPath]!;
          return Material(
            color: Colors.transparent,
            child: ListTile(
              leading: const Icon(LucideIcons.folder, color: Colors.amberAccent),
              title: Text(folderName),
              subtitle: Text(folderPath, style: AppFonts.jostStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text('${folderSongs.length} ${l10n.songs}'),
              onTap: () => ref.read(appNavigationProvider.notifier).showCollection(
                title: folderName,
                subtitle: folderPath,
                songs: folderSongs,
              ),
            ),
          );
        },
      ),
    );
  }
}
