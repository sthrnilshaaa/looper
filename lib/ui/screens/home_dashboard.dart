
import 'package:flutter/material.dart';
import 'package:looper_player/core/ui_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/ui/widgets/optimized_image.dart';
import 'package:flutter_svg/svg.dart';
import 'package:looper_player/ui/widgets/global_playing_indicator.dart';
import 'package:looper_player/features/library/presentation/library_grids.dart';
import 'package:looper_player/features/settings/presentation/settings_notifier.dart';
import 'package:looper_player/ui/widgets/color_maper.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/library/presentation/library_notifier.dart';
import 'package:looper_player/features/playback/presentation/playback_notifier.dart';
import 'package:looper_player/core/navigation_provider.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/core/db_service.dart';
import 'package:isar_community/isar.dart';

class HomeDashboard extends ConsumerWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final bool isDynamic = settings.enableDynamicTheming;
    final library = ref.watch(libraryProvider);
    final l10n = AppLocalizations.of(context)!;

    final genresMap = <String, List<Song>>{};
    for (var song in library.songs) {
      final genre = song.genre ?? l10n.unknown;
      genresMap.putIfAbsent(genre, () => []).add(song);
    }
    final genres = genresMap.keys.toList()..sort();

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 600;
        final bool isMedium = constraints.maxWidth < 1000;
        final bool showLogo = MediaQuery.of(context).size.width < 800;

        final orderedChildren = <Widget>[];

        if (showLogo) {
          orderedChildren.add(
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 50.s,
                  child: SvgPicture.asset(
                    'assets/main_logo_transparent.svg',
                    fit: BoxFit.contain,
                    colorMapper: AccentColorMapper(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        }

        // Support desktop-specific helper rows at the very top
        orderedChildren.add(_buildRecentlyPlayed(ref, isNarrow, isDynamic, l10n));
        orderedChildren.add(const SizedBox(height: 16));
        orderedChildren.add(_buildAlbumsIfSmall(ref, isNarrow, isDynamic, l10n));
        orderedChildren.add(const SizedBox(height: 16));

        // Render sections dynamically in user's customized order
        for (final section in settings.homeSectionOrder) {
          if (section == 'quick_picks') {
            orderedChildren.add(_buildQuickPicks(ref, isNarrow, isMedium, isDynamic, l10n));
            orderedChildren.add(const SizedBox(height: 16));
          } else if (section == 'songs') {
            // Render Featured Artists and Albums for the "songs" slot on desktop
            orderedChildren.add(_buildTopArtists(ref, isNarrow, isDynamic, l10n));
            orderedChildren.add(const SizedBox(height: 16));
            orderedChildren.add(_buildFeaturedAlbums(ref, isNarrow, isDynamic, context));
            orderedChildren.add(const SizedBox(height: 16));
          } else if (section == 'artists') {
            if (settings.showHomeArtists && library.artists.isNotEmpty) {
              orderedChildren.add(
                _buildDesktopHorizontalSection(
                  title: l10n.artists,
                  l10n: l10n,
                  onViewAll: () => ref.read(appNavigationProvider.notifier).setItem(NavItem.artists),
                  itemCount: library.artists.length,
                  itemBuilder: (context, index) {
                    return _buildDesktopArtistItem(ref, library.artists[index], l10n);
                  },
                ),
              );
              orderedChildren.add(const SizedBox(height: 16));
            }
          } else if (section == 'albums') {
            if (settings.showHomeAlbums && library.albums.isNotEmpty) {
              orderedChildren.add(
                _buildDesktopHorizontalSection(
                  title: l10n.albums,
                  l10n: l10n,
                  onViewAll: () => ref.read(appNavigationProvider.notifier).setItem(NavItem.albums),
                  itemCount: library.albums.length,
                  itemBuilder: (context, index) {
                    return _buildDesktopAlbumItem(ref, library.albums[index], l10n);
                  },
                ),
              );
              orderedChildren.add(const SizedBox(height: 16));
            }
          } else if (section == 'genres') {
            if (settings.showHomeGenres && genres.isNotEmpty) {
              orderedChildren.add(
                _buildDesktopHorizontalSection(
                  title: l10n.genres,
                  l10n: l10n,
                  onViewAll: () => ref.read(appNavigationProvider.notifier).setItem(NavItem.genres),
                  itemCount: genres.length,
                  itemBuilder: (context, index) {
                    final genre = genres[index];
                    return _buildDesktopGenreItem(ref, genre, genresMap[genre]!, l10n);
                  },
                ),
              );
              orderedChildren.add(const SizedBox(height: 16));
            }
          }
        }

        orderedChildren.add(const SizedBox(height: 120));

        return ListView(
          padding: EdgeInsets.only(
            top: (isNarrow ? 4 : 8).s,
            left: (isNarrow ? 16 : 32).s,
            right: (isNarrow ? 16 : 32).s,
          ),
          children: orderedChildren,
        );
      },
    );
  }

  Widget _buildAlbumsIfSmall(WidgetRef ref, bool isNarrow, bool isDynamic, AppLocalizations l10n) {
    final albums = ref.watch(albumsProvider).value ?? [];
    if (albums.length >= 6 || albums.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.myAlbums,
          style: TextStyle(
            fontSize: (isNarrow ? 14 : 18).ts,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: isNarrow ? 200 : 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () async {
                    final songs = await DbService.isar.songs
                        .filter()
                        .albumEqualTo(album.name)
                        .findAll();
                    ref
                        .read(appNavigationProvider.notifier)
                        .showCollection(
                          title: album.name,
                          subtitle: album.artist,
                          art: album.artPath,
                          songs: songs,
                        );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: isNarrow ? 120 : 140,
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OptimizedImage(
                          imagePath: album.artPath,
                          height: isNarrow ? 104 : 124,
                          width: isNarrow ? 104 : 124,
                          borderRadius: BorderRadius.circular(12),
                          placeholder: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 
                                isDynamic ? 0.8 : 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(child: Icon(LucideIcons.disc)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          album.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          album.artist ?? 'Unknown',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentlyPlayed(WidgetRef ref, bool isNarrow, bool isDynamic, AppLocalizations l10n) {
    final recentSongs = ref.watch(dashboardRecentlyPlayedProvider).value ?? [];

    if (recentSongs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          //l10n.recentlyPlayed,
          "Played",
          style: TextStyle(
            fontSize: (isNarrow ? 14 : 18).ts,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: isNarrow ? 200 : 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentSongs.length.clamp(0, 10),
            itemBuilder: (context, index) {
              final song = recentSongs[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () => ref.read(playbackProvider.notifier).play(song),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: isNarrow ? 120 : 140,
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OptimizedImage(
                          imagePath: song.artPath,
                          height: isNarrow ? 104 : 124,
                          width: isNarrow ? 104 : 124,
                          borderRadius: BorderRadius.circular(12),
                          placeholder: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 
                                isDynamic ? 0.8 : 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(child: Icon(LucideIcons.music)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.artist ?? 'Unknown',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickPicks(
    WidgetRef ref,
    bool isNarrow,
    bool isMedium,
    bool isDynamic,
    AppLocalizations l10n,
  ) {
    final topSongsAsync = ref.watch(topSongsProvider);

    return topSongsAsync.when(
      data: (songs) {
        if (songs.isEmpty) return const SizedBox.shrink();

        int crossAxisCount = 4;
        if (isNarrow) {
          crossAxisCount = 2;
        } else if (isMedium) {
          crossAxisCount = 3;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.quickPicks,
              style: TextStyle(
                fontSize: isNarrow ? 14 : 18,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisExtent: 70,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                final isCurrent =
                    ref.watch(playbackProvider.select((s) => s.currentSong?.path == song.path));
                final isPlaying =
                    ref.watch(playbackProvider.select((s) => s.isPlaying));

                return InkWell(
                  onTap: () => ref.read(playbackProvider.notifier).play(song),
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        PlayingOverlay(
                          isPlaying: isCurrent && isPlaying,
                          borderRadius: 4,
                          child: OptimizedImage(
                            imagePath: song.artPath,
                            width: 54,
                            height: 54,
                            borderRadius: BorderRadius.circular(4),
                            placeholder: const Icon(LucideIcons.music, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                song.artist ?? 'Unknown',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
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
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildTopArtists(WidgetRef ref, bool isNarrow, bool isDynamic, AppLocalizations l10n) {
    final artistsAsync = ref.watch(artistsProvider);

    return artistsAsync.when(
      data: (artists) {
        if (artists.isEmpty) return const SizedBox.shrink();

        // Take a slice for featured artists
        final featuredArtists = artists.take(10).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.featuredArtists,
              style: TextStyle(
                fontSize: isNarrow ? 14 : 18,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: isNarrow ? 110 : 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: featuredArtists.length,
                itemBuilder: (context, index) {
                  final artist = featuredArtists[index];
                  return _FeaturedArtistCard(
                    artist: artist,
                    isNarrow: isNarrow,
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildFeaturedAlbums(WidgetRef ref, bool isNarrow, bool isDynamic, BuildContext context) {
    final albumsAsync = ref.watch(albumsProvider);
    final l10n = AppLocalizations.of(context)!;

    return albumsAsync.when(
      data: (albums) {
        if (albums.isEmpty) return const SizedBox.shrink();

        // Take a slice for featured albums (max 10)
        final featuredAlbums = albums.take(10).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.albums,
                  style: TextStyle(
                    fontSize: isNarrow ? 14 : 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(appNavigationProvider.notifier).setItem(NavItem.albums);
                  },
                  child: Text(
                    l10n.viewAll,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: isNarrow ? 200 : 230,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: featuredAlbums.length,
                itemBuilder: (context, index) {
                  final album = featuredAlbums[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: () async {
                        final songs = await DbService.isar.songs
                            .filter()
                            .albumEqualTo(album.name)
                            .findAll();
                        ref
                            .read(appNavigationProvider.notifier)
                            .showCollection(
                              title: album.name,
                              subtitle: album.artist,
                              art: album.artPath,
                              songs: songs,
                            );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: isNarrow ? 120 : 140,
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OptimizedImage(
                              imagePath: album.artPath,
                              height: isNarrow ? 104 : 124,
                              width: isNarrow ? 104 : 124,
                              borderRadius: BorderRadius.circular(12),
                              placeholder: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 
                                    isDynamic ? 0.8 : 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(child: Icon(LucideIcons.disc)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              album.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              album.artist ?? 'Unknown',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildDesktopHorizontalSection({
    required String title,
    required VoidCallback onViewAll,
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    required AppLocalizations l10n,
  }) {
    if (itemCount == 0) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              child: Row(
                children: [
                  Text(
                    l10n.viewAll,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(width: 4),
                  const Icon(LucideIcons.chevronRight, size: 16, color: Colors.white70),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: itemCount,
            itemBuilder: itemBuilder,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopArtistItem(WidgetRef ref, Artist artist, AppLocalizations l10n) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: () async {
          final songs = await DbService.isar.songs.filter().artistEqualTo(artist.name).findAll();
          ref.read(appNavigationProvider.notifier).showCollection(
            title: artist.name,
            subtitle: l10n.artist,
            art: artist.artPath,
            imageUrl: artist.artistImageUrl,
            songs: songs,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: ClipOval(
                child: OptimizedImage(
                  imageUrl: artist.artistImageUrl != null && artist.artistImageUrl!.startsWith('http') ? artist.artistImageUrl : null,
                  imagePath: artist.artistImageUrl != null && !artist.artistImageUrl!.startsWith('http') ? artist.artistImageUrl : artist.artPath,
                  fit: BoxFit.cover,
                  placeholder: Container(
                    color: Colors.white.withValues(alpha: 0.05),
                    child: const Center(
                      child: Icon(
                        LucideIcons.user,
                        size: 32,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              artist.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopAlbumItem(WidgetRef ref, Album album, AppLocalizations l10n) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 16),
      child: InkWell(
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
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: OptimizedImage(
                  imagePath: album.artPath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              album.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              album.artist ?? l10n.unknownArtist,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopGenreItem(WidgetRef ref, String genre, List<Song> genreSongs, AppLocalizations l10n) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: () {
          ref.read(appNavigationProvider.notifier).showCollection(
            title: genre,
            subtitle: l10n.genre,
            songs: genreSongs,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.music, color: Colors.blueAccent, size: 28),
              const SizedBox(height: 10),
              Text(
                genre,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '${genreSongs.length} ${l10n.songs}',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedArtistCard extends ConsumerWidget {
  final Artist artist;
  final bool isNarrow;

  const _FeaturedArtistCard({required this.artist, required this.isNarrow});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: () async {
          final artistSongs = await DbService.isar.songs
              .filter()
              .artistEqualTo(artist.name)
              .findAll();
          ref
              .read(appNavigationProvider.notifier)
              .showCollection(
                title: artist.name,
                subtitle: 'Artist',
                art: artist.artPath,
                imageUrl: artist.artistImageUrl,
                songs: artistSongs,
              );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: isNarrow ? 80 : 100,
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Container(
                width: isNarrow ? 64 : 80,
                height: isNarrow ? 64 : 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: OptimizedImage(
                    imageUrl: artist.artistImageUrl,
                    imagePath: artist.artPath,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      color: Colors.grey.withValues(alpha: 0.1),
                      child: const Icon(LucideIcons.user, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                artist.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
