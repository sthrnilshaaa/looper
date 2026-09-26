part of 'android_home_tab.dart';

extension _HomeTabSections on _AndroidHomeTabState {
  Widget _buildHorizontalSection({
    required String title,
    required String actionText,
    required VoidCallback onActionTap,
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
  }) {
    if (itemCount == 0) return const SizedBox.shrink();
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppFonts.jostStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                PremiumSection(
                  borderRadius: BorderRadius.circular(32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  height: 36,
                  useExpanded: false,
                  onTap: onActionTap,
                  useBlur: true,
                  forceNoBlur: true,
                  backgroundColor: Colors.white.withValues(alpha: 0.04),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionText,
                        style: AppFonts.jostStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        LucideIcons.arrowRight,
                        size: 14,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 170,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: itemCount,
              itemBuilder: itemBuilder,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistItem(Artist artist, AppLocalizations l10n) {
    return Container(
      width: 110,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        onTap: () async {
          HapticFeedback.lightImpact();
          final songs = await DbService.isar.songs
              .filter()
              .artistEqualTo(artist.name)
              .findAll();
          final imageUrl = artist.artistImageUrl;
          final bool isLocalImage =
              imageUrl != null && !imageUrl.startsWith('http');
          final bool isNetworkImage =
              imageUrl != null && imageUrl.startsWith('http');
          ref
              .read(appNavigationProvider.notifier)
              .showCollection(
                title: artist.name,
                subtitle: l10n.artist,

                art: isLocalImage ? imageUrl : artist.artPath,
                imageUrl: isNetworkImage ? imageUrl : null,

                songs: songs,
              );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 92,
              height: 92,
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
                        size: 28,
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
              style: AppFonts.jostStyle(
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

  Widget _buildAlbumItem(Album album, AppLocalizations l10n) {
    return Container(
      width: 120,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        onTap: () async {
          HapticFeedback.lightImpact();
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
              style: AppFonts.jostStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              album.artist ?? l10n.unknownArtist,
              style: AppFonts.jostStyle(color: Colors.white38, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreItem(
    String genre,
    List<Song> genreSongs,
    AppLocalizations l10n,
  ) {
    // Hash the genre string to produce a consistent vibrant color gradient
    final int hash = genre.hashCode;
    final double hue = (hash.abs() % 360).toDouble();
    final Color startColor = HSLColor.fromAHSL(1.0, hue, 0.70, 0.35).toColor();
    final Color endColor = HSLColor.fromAHSL(
      1.0,
      (hue + 45) % 360,
      0.80,
      0.18,
    ).toColor();

    // Get first song with art if available
    final firstSongWithArt = genreSongs.firstWhere(
      (s) => s.artPath != null,
      orElse: () => genreSongs.first,
    );

    return Container(
      width: 200,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          final firstWithArt = genreSongs.firstWhere(
            (s) => s.artPath != null,
            orElse: () => genreSongs.first,
          );
          ref
              .read(appNavigationProvider.notifier)
              .showCollection(
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
                right:
                    56, // Leave room so text doesn't overlap the album art too much
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
      ),
    );
  }

  // Recent played row, matching the pill style used in the Library tab.
  Widget _buildRecentPlayedRow(List<Song> recentSongs) {
    final row1Songs = <Song>[];
    final row2Songs = <Song>[];
    for (int i = 0; i < recentSongs.length; i++) {
      if (i % 2 == 0) {
        row1Songs.add(recentSongs[i]);
      } else {
        row2Songs.add(recentSongs[i]);
      }
    }

    final hasTwoRows = recentSongs.length > 1;

    return SizedBox(
      height: hasTwoRows ? 100 : 50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: row1Songs.map((song) {
                final globalIndex = recentSongs.indexOf(song);
                return _buildRecentPill(song, recentSongs, globalIndex);
              }).toList(),
            ),
            if (hasTwoRows) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: row2Songs.map((song) {
                  final globalIndex = recentSongs.indexOf(song);
                  return _buildRecentPill(song, recentSongs, globalIndex);
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPill(Song song, List<Song> recentSongs, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: PremiumSection(
        borderRadius: BorderRadius.circular(36),
        useExpanded: false,
        onTap: () {
          HapticFeedback.lightImpact();
          ref
              .read(playbackProvider.notifier)
              .setPlaylist(recentSongs, initialIndex: index);
        },
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 24,
                height: 24,
                child: OptimizedImage(
                  imagePath: song.artPath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              song.title,
              style: AppFonts.jostStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
