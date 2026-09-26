part of 'home_dashboard.dart';

extension _DashboardSections on HomeDashboard {
  Widget _buildAlbumsIfSmall(
    WidgetRef ref,
    bool isNarrow,
    bool isDynamic,
    AppLocalizations l10n,
  ) {
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
                              color: Colors.grey.withValues(
                                alpha: isDynamic ? 0.8 : 0.1,
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
                          album.artist ?? context.l10n.unknown,
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

  Widget _buildRecentlyPlayed(
    WidgetRef ref,
    bool isNarrow,
    bool isDynamic,
    AppLocalizations l10n,
  ) {
    final recentSongs = ref.watch(dashboardRecentlyPlayedProvider).value ?? [];

    if (recentSongs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.playedLabel,
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
                              color: Colors.grey.withValues(
                                alpha: isDynamic ? 0.8 : 0.1,
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
                          song.artist ?? context.l10n.unknown,
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
                final isCurrent = ref.watch(
                  playbackProvider.select(
                    (s) => s.currentSong?.path == song.path,
                  ),
                );
                final isPlaying = ref.watch(
                  playbackProvider.select((s) => s.isPlaying),
                );

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
                            placeholder: const Icon(
                              LucideIcons.music,
                              size: 20,
                            ),
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
                                song.artist ?? context.l10n.unknown,
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

  Widget _buildTopArtists(
    WidgetRef ref,
    bool isNarrow,
    bool isDynamic,
    AppLocalizations l10n,
  ) {
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

  Widget _buildFeaturedAlbums(
    WidgetRef ref,
    bool isNarrow,
    bool isDynamic,
    BuildContext context,
  ) {
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
                    ref
                        .read(appNavigationProvider.notifier)
                        .setItem(NavItem.albums);
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
                                  color: Colors.grey.withValues(
                                    alpha: isDynamic ? 0.8 : 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Icon(LucideIcons.disc),
                                ),
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
                              album.artist ?? context.l10n.unknown,
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
}
