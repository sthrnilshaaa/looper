part of 'android_home_tab.dart';

extension _HomeTabSections on _AndroidHomeTabState {
  Widget _buildHorizontalSection({
    required String title,
    required String actionText,
    required VoidCallback onActionTap,
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    double listHeight = 170,
    String? label,
    // Artist rows page with ← → instead of a View All pill.
    bool arrows = false,
    // App start: the section's data isn't in yet, so it shows card bones
    // (circles for artists) and cross-fades to the cards when it arrives.
    bool loading = false,
    bool circleSkeleton = false,
  }) {
    if (!loading && itemCount == 0) return const SizedBox.shrink();
    return SliverToBoxAdapter(
      // Keyed so the skeleton-to-cards fade stays with its own section when
      // another section appears above it during loading.
      key: ValueKey('home-section-$title'),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, ?current],
        ),
        child: loading
            ? HomeCardRowSkeleton(
                key: const ValueKey('skeleton'),
                circle: circleSkeleton,
              )
            : _horizontalSectionBody(
                title: title,
                actionText: actionText,
                onActionTap: onActionTap,
                itemCount: itemCount,
                itemBuilder: itemBuilder,
                listHeight: listHeight,
                label: label,
                arrows: arrows,
              ),
      ),
    );
  }

  Widget _horizontalSectionBody({
    required String title,
    required String actionText,
    required VoidCallback onActionTap,
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    required double listHeight,
    String? label,
    bool arrows = false,
  }) {
    return KeyedSubtree(
      key: const ValueKey('content'),
      child: ScrollControllerScope(
        builder: (context, controller) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeSectionHeader(
              title: title,
              label: label,
              trailing: arrows
                  ? HomeRowArrows(controller: controller)
                  : HomeViewAllPill(label: actionText, onTap: onActionTap),
            ),
            SizedBox(
              height: listHeight,
              child: ListView.builder(
                controller: controller,
                scrollDirection: Axis.horizontal,
                physics: const LooperScrollPhysics(),
                // Cards' own margins bring the first one to x = 23.
                padding: const EdgeInsets.symmetric(horizontal: 14.5),
                itemCount: itemCount,
                itemBuilder: itemBuilder,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _homeSectionHeader({
    required String title,
    required VoidCallback onViewAll,
  }) => HomeSectionHeader(
    title: title,
    trailing: HomeViewAllPill(
      label: AppLocalizations.of(context)!.viewAll,
      onTap: onViewAll,
    ),
  );

  /// "For You": the mix in columns of 4 rows (42px cover, title, artist,
  /// menu), paged sideways like the design.
  Widget _buildPicksPager(
    List<Song> picks,
    AppLocalizations l10n, {
    required bool showAlbum,
  }) {
    const rows = 4, rowHeight = 56.0, columnWidth = 312.0;
    final columns = (picks.length / rows).ceil();
    return SizedBox(
      height: rows * rowHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const LooperScrollPhysics(),
        padding: const EdgeInsets.only(left: 25, right: 8),
        itemCount: columns,
        itemExtent: columnWidth,
        itemBuilder: (context, c) => Column(
          children: [
            for (
              var i = c * rows;
              i < math.min((c + 1) * rows, picks.length);
              i++
            )
              SizedBox(
                height: rowHeight,
                child: _PickRow(
                  song: picks[i],
                  subtitle: artistAlbumLabel(
                    picks[i],
                    l10n,
                    showAlbum: showAlbum,
                  ),
                  onTap: () => ref
                      .read(playbackProvider.notifier)
                      .setPlaylist(picks, initialIndex: i),
                  onMore: () => _showSongOptions(context, picks[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistItem(Artist artist, AppLocalizations l10n) {
    return Container(
      width: 90,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () async {
          AppHaptics.light();
          await ref
              .read(appNavigationProvider.notifier)
              .showArtist(artist, subtitle: l10n.artist);
        },
        borderRadius: BorderRadius.circular(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
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
                        size: 22,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              artist.name,
              style: AppFonts.jostStyle(color: Colors.white, fontSize: 14),
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
      width: 128,
      margin: const EdgeInsets.symmetric(horizontal: 8.5),
      child: InkWell(
        onTap: () async {
          AppHaptics.light();
          await ref
              .read(appNavigationProvider.notifier)
              .showAlbum(album, unknownArtist: l10n.unknownArtist);
        },
        borderRadius: BorderRadius.circular(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: OptimizedImage(
                  imagePath: album.artPath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Text(
                album.name,
                style: homeCardTitle(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Text(
                // The design's album cards show the year under the name.
                album.year?.toString() ?? album.artist ?? l10n.unknownArtist,
                style: homeCardSub(size: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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

  Widget _buildViewAllEndCard({
    required VoidCallback onTap,
    required AppLocalizations l10n,
    double width = 120,
    bool circle = false,
  }) {
    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        onTap: () {
          AppHaptics.light();
          onTap();
        },
        borderRadius: BorderRadius.circular(circle ? 30 : 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: circle ? 60 : width,
              height: circle ? 60 : (width > 140 ? _genreCardHeight : width),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: circle ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: circle ? null : BorderRadius.circular(5),
                border: Border.all(color: Colors.white12),
              ),
              child: const Center(
                child: Icon(
                  LucideIcons.arrowRight,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.viewAll,
              style: AppFonts.jostStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreItem(String genre, List<Song> genreSongs) {
    return Container(
      width: _genreCardWidth,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: GenreCard(genre: genre, songs: genreSongs, hapticOnTap: true),
    );
  }
}

class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.song,
    required this.subtitle,
    required this.onTap,
    required this.onMore,
  });

  final Song song;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: () {
        AppHaptics.medium();
        onMore();
      },
      borderRadius: BorderRadius.circular(5),
      child: Row(
        children: [
          SongArtwork(
            song: song,
            size: 42,
            borderRadius: BorderRadius.circular(5),
            indicatorSize: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: homeCardTitle(),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: homeCardSub(),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onMore,
            tooltip: MaterialLocalizations.of(context).showMenuTooltip,
            icon: const Icon(
              Icons.more_vert_rounded,
              size: 22,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
