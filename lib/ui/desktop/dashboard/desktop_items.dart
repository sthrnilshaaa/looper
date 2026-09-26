part of 'home_dashboard.dart';

extension _DashboardDesktopItems on HomeDashboard {
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
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: Colors.white70,
                  ),
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

  Widget _buildDesktopArtistItem(
    WidgetRef ref,
    Artist artist,
    AppLocalizations l10n,
  ) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: () async {
          final songs = await DbService.isar.songs
              .filter()
              .artistEqualTo(artist.name)
              .findAll();
          ref
              .read(appNavigationProvider.notifier)
              .showCollection(
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
                  imageUrl:
                      artist.artistImageUrl != null &&
                          artist.artistImageUrl!.startsWith('http')
                      ? artist.artistImageUrl
                      : null,
                  imagePath:
                      artist.artistImageUrl != null &&
                          !artist.artistImageUrl!.startsWith('http')
                      ? artist.artistImageUrl
                      : artist.artPath,
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

  Widget _buildDesktopAlbumItem(
    WidgetRef ref,
    Album album,
    AppLocalizations l10n,
  ) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 16),
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
              style: const TextStyle(color: Colors.white38, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopGenreItem(
    WidgetRef ref,
    String genre,
    List<Song> genreSongs,
    AppLocalizations l10n,
  ) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: () {
          ref
              .read(appNavigationProvider.notifier)
              .showCollection(
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
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
