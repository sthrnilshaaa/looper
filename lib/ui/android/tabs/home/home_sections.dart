part of 'android_home_tab.dart';

extension _HomeTabSections on _AndroidHomeTabState {
  Widget _buildHorizontalSection({
    required String title,
    required String actionText,
    required VoidCallback onActionTap,
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    double listHeight = 170,
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
            height: listHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const LooperScrollPhysics(),
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
          AppHaptics.light();
          await ref
              .read(appNavigationProvider.notifier)
              .showArtist(artist, subtitle: l10n.artist);
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
          AppHaptics.light();
          await ref
              .read(appNavigationProvider.notifier)
              .showAlbum(album, unknownArtist: l10n.unknownArtist);
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

  /// Same size and shape as a card on the Genres screen (two columns on a
  /// phone, 1.35 wide to tall).
  static const double _genreCardWidth = 172;
  static const double _genreCardHeight = _genreCardWidth / 1.35;
  static const double genreRowHeight = _genreCardHeight + 16;

  Widget _buildGenreItem(String genre, List<Song> genreSongs) {
    return Container(
      width: _genreCardWidth,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: GenreCard(genre: genre, songs: genreSongs, hapticOnTap: true),
    );
  }
}
