import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:isar_community/isar.dart';
import 'package:looper_player/core/app_fonts.dart';
import 'package:looper_player/core/app_icons.dart';
import 'package:looper_player/core/db_service.dart';
import 'package:looper_player/core/navigation_provider.dart';
import 'package:looper_player/core/responsive.dart';
import 'package:looper_player/features/library/presentation/library_notifier.dart';
import 'package:looper_player/features/library/presentation/songs_list.dart';
import 'package:looper_player/features/playback/presentation/playback_notifier.dart';
import 'package:looper_player/features/settings/presentation/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/app_refresh_indicator.dart';
import 'package:looper_player/ui/widgets/optimized_image.dart';
import 'package:looper_player/ui/widgets/selected_avatar.dart';
import 'package:looper_player/ui/widgets/song_options_bottom_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../widgets/empty_library_view.dart';
import '../widgets/enrichment_indicator.dart';
import '../widgets/premium_loading_view.dart';
import '../widgets/premium_section.dart';
import 'views/library_categories_views.dart';

class AndroidHomeTab extends ConsumerStatefulWidget {
  const AndroidHomeTab({super.key});

  @override
  ConsumerState<AndroidHomeTab> createState() => _AndroidHomeTabState();
}

class _AndroidHomeTabState extends ConsumerState<AndroidHomeTab> {
  int _currentQuickPickPage = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showSongOptions(BuildContext context, Song song) {
    showSongOptionsBottomSheet(context: context, ref: ref, song: song, showEqualizerAndTechnicalInfoOptions: false);
  }

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
                  style: AppFonts.jostStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                PremiumSection(
                  borderRadius: BorderRadius.circular(32),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        style: AppFonts.jostStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      const Icon(LucideIcons.arrowRight, size: 14, color: Colors.white),
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
          final songs = await DbService.isar.songs.filter().artistEqualTo(artist.name).findAll();
          final imageUrl = artist.artistImageUrl;
          final bool isLocalImage = imageUrl != null && !imageUrl.startsWith('http');
          final bool isNetworkImage = imageUrl != null && imageUrl.startsWith('http');
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
                  imageUrl: artist.artistImageUrl != null && artist.artistImageUrl!.startsWith('http')
                      ? artist.artistImageUrl
                      : null,
                  imagePath: artist.artistImageUrl != null && !artist.artistImageUrl!.startsWith('http')
                      ? artist.artistImageUrl
                      : artist.artPath,
                  fit: BoxFit.cover,
                  placeholder: Container(
                    color: Colors.white.withValues(alpha: 0.05),
                    child: const Center(child: Icon(LucideIcons.user, size: 28, color: Colors.white38)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              artist.name,
              style: AppFonts.jostStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
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
          final songs = await DbService.isar.songs.filter().albumEqualTo(album.name).findAll();
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
                child: OptimizedImage(imagePath: album.artPath, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              album.name,
              style: AppFonts.jostStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
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

  Widget _buildGenreItem(String genre, List<Song> genreSongs, AppLocalizations l10n) {
    // Hash the genre string to produce a consistent vibrant color gradient
    final int hash = genre.hashCode;
    final double hue = (hash.abs() % 360).toDouble();
    final Color startColor = HSLColor.fromAHSL(1.0, hue, 0.70, 0.35).toColor();
    final Color endColor = HSLColor.fromAHSL(1.0, (hue + 45) % 360, 0.80, 0.18).toColor();

    // Get first song with art if available
    final firstSongWithArt = genreSongs.firstWhere((s) => s.artPath != null, orElse: () => genreSongs.first);

    return Container(
      width: 200,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          final firstWithArt = genreSongs.firstWhere((s) => s.artPath != null, orElse: () => genreSongs.first);
          ref
              .read(appNavigationProvider.notifier)
              .showCollection(title: genre, subtitle: l10n.genre, art: firstWithArt.artPath, songs: genreSongs);
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
              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4)),
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
                        child: OptimizedImage(imagePath: firstSongWithArt.artPath, fit: BoxFit.cover),
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
                      child: const Icon(LucideIcons.music, size: 28, color: Colors.white70),
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
          ref.read(playbackProvider.notifier).setPlaylist(recentSongs, initialIndex: index);
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
                child: OptimizedImage(imagePath: song.artPath, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              song.title,
              style: AppFonts.jostStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This tab is now permanently mounted alongside Songs/Library (see
    // AndroidMainScreen) instead of being torn down on every tab switch, so
    // an unscoped watch of the entire LibraryState/AppSettings objects meant
    // it silently rebuilt this whole (large, image-heavy) tab in the
    // background on every unrelated settings tweak or library write - e.g.
    // every darkness slider drag, or the ~20s listen-time checkpoint during
    // any playback - even while a different tab was on screen. Select just
    // the fields this tab actually renders.
    final (songs, rawArtists, rawAlbums, isInitialized, isScanning) = ref.watch(
      libraryProvider.select((s) => (s.songs, s.artists, s.albums, s.isInitialized, s.isScanning)),
    );
    final l10n = AppLocalizations.of(context)!;
    final (
      albumSortOptionIndex,
      artistSortOptionIndex,
      genreSortOptionIndex,
      disableBlur,
      enableDynamicTheming,
      homeSectionOrder,
      showHomeArtists,
      showHomeAlbums,
      showHomeGenres,
      showHomeRecent,
    ) = ref.watch(
      settingsProvider.select(
        (s) => (
          s.albumSortOptionIndex,
          s.artistSortOptionIndex,
          s.genreSortOptionIndex,
          s.disableBlur,
          s.enableDynamicTheming,
          s.homeSectionOrder,
          s.showHomeArtists,
          s.showHomeAlbums,
          s.showHomeGenres,
          s.showHomeRecent,
        ),
      ),
    );
    final recentSongs = ref.watch(dashboardRecentlyPlayedProvider).value ?? [];

    final albumSort = AlbumSortOption.values[albumSortOptionIndex.clamp(0, AlbumSortOption.values.length - 1)];
    final artistSort = ArtistSortOption.values[artistSortOptionIndex.clamp(0, ArtistSortOption.values.length - 1)];
    final genreSort = GenreSortOption.values[genreSortOptionIndex.clamp(0, GenreSortOption.values.length - 1)];

    final genresMap = <String, List<Song>>{};
    for (var song in songs) {
      final genre = song.genre ?? l10n.unknown;
      genresMap.putIfAbsent(genre, () => []).add(song);
    }

    final genres = genresMap.keys.toList();
    switch (genreSort) {
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

    final artists = List<Artist>.from(rawArtists);
    if (artistSort == ArtistSortOption.nameAsc) {
      artists.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else {
      artists.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    }

    final albums = List<Album>.from(rawAlbums);
    switch (albumSort) {
      case AlbumSortOption.nameAsc:
        albums.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case AlbumSortOption.nameDesc:
        albums.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case AlbumSortOption.dateAddedNewest:
        albums.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        break;
      case AlbumSortOption.dateAddedOldest:
        albums.sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
        break;
      case AlbumSortOption.yearNewest:
        albums.sort((a, b) {
          if (a.year == null && b.year == null) return 0;
          if (a.year == null) return 1;
          if (b.year == null) return -1;
          return b.year!.compareTo(a.year!);
        });
        break;
      case AlbumSortOption.yearOldest:
        albums.sort((a, b) {
          if (a.year == null && b.year == null) return 0;
          if (a.year == null) return 1;
          if (b.year == null) return -1;
          return a.year!.compareTo(b.year!);
        });
        break;
    }

    if (!isInitialized || (isScanning && songs.isEmpty)) {
      return const PremiumLoadingView();
    }

    if (songs.isEmpty) {
      return SafeArea(child: EmptyLibraryView(title: l10n.noSongsFound));
    }

    // Quick Picks (most played, up to 18 for 3 pages of 6) and Recently
    // Added (newest first) are computed in memoized providers instead of
    // inline here - same sort, same output, just not redone on every
    // rebuild of this screen. See their doc comments in library_notifier.dart.
    final allQuickPicks = ref.watch(homeQuickPicksProvider);
    final dateAddedSongs = ref.watch(homeRecentlyAddedProvider);

    final useBlur = enableDynamicTheming && !disableBlur;

    final orderedSlivers = <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Centered independently of the Stack below so it stays put
              // regardless of how wide the avatar or the icon buttons are.
              const Center(child: EnrichmentIndicator()),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 38, width: 40, child: SelectedAvatar()),
                  Row(
                    children: [
                      PremiumSection(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          bottomLeft: Radius.circular(32),
                          topRight: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                        width: 48,
                        height: 48,
                        useExpanded: false,
                        useBlur: useBlur,
                        forceNoBlur: true,
                        backgroundColor: Colors.white.withValues(alpha: 0.04),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ref.read(appNavigationProvider.notifier).setItem(NavItem.search);
                        },
                        child: const Icon(LucideIcons.search, color: Colors.white, size: 20),
                      ),
                      SizedBox(width: 5),
                      PremiumSection(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          bottomLeft: Radius.circular(10),
                          topRight: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                        width: 48,
                        height: 48,
                        useExpanded: false,
                        useBlur: useBlur,
                        backgroundColor: Colors.white.withValues(alpha: 0.04),
                        forceNoBlur: true,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ref.read(appNavigationProvider.notifier).setItem(NavItem.settings);
                        },
                        child: const Icon(LucideIcons.settings, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ];

    for (final section in homeSectionOrder) {
      if (section == 'quick_picks') {
        orderedSlivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.quickPicks,
                        style: AppFonts.jostStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        l10n.todayMixForYou,
                        style: AppFonts.jostStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  PremiumSection(
                    borderRadius: BorderRadius.circular(32),
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    height: 40,
                    useExpanded: false,
                    useBlur: useBlur,
                    backgroundColor: Colors.white.withValues(alpha: 0.04),
                    forceNoBlur: true,
                    onTap: () {
                      if (allQuickPicks.isNotEmpty) {
                        HapticFeedback.mediumImpact();
                        final shuffledPicks = List<Song>.from(allQuickPicks)..shuffle();
                        ref.read(playbackProvider.notifier).setPlaylist(shuffledPicks, initialIndex: 0);
                      }
                    },
                    child: SvgPicture.asset(AppIcons.shuffleHome, width: 40),
                    // Row(
                    //   mainAxisSize: MainAxisSize.min,
                    //   children: [
                    //     const Icon(LucideIcons.shuffle, size: 16, color: Colors.white),
                    //     const SizedBox(width: 8),
                    //     Text(
                    //       l10n.play,
                    //       style: AppFonts.jostStyle(
                    //         color: Colors.white,
                    //         fontWeight: FontWeight.w600,
                    //       ),
                    //     ),
                    //   ],
                    // ),
                  ),
                ],
              ),
            ),
          ),
        );

        orderedSlivers.add(
          SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = (constraints.maxWidth - 32).clamp(0.0, double.infinity);
                // Portrait keeps the original fixed 3 columns exactly as it
                // was. In landscape there's a lot more width to use - fit as
                // many ~110dp columns as the width allows (never fewer than
                // 3) instead of stretching 3 tiles needlessly wide.
                final isLandscape = Responsive.isLandscape(
                  MediaQuery.sizeOf(context),
                );
                final crossAxisCount = isLandscape
                    ? math.max(3, ((availableWidth + 8) / (110 + 8)).floor())
                    : 3;
                final itemWidth = ((availableWidth - 8 * (crossAxisCount - 1)) /
                        crossAxisCount)
                    .clamp(0.0, double.infinity);
                final gridHeight = ((itemWidth * 2) + 8).clamp(8.0, double.infinity);
                final itemsPerPage = crossAxisCount * 2;

                final pageCount = (allQuickPicks.length / itemsPerPage).ceil();
                final validPageCount = pageCount == 0 ? 1 : pageCount;

                return Column(
                  children: [
                    SizedBox(
                      height: gridHeight,
                      child: PageView.builder(
                        onPageChanged: (index) {
                          setState(() {
                            _currentQuickPickPage = index;
                          });
                        },
                        itemCount: validPageCount,
                        itemBuilder: (context, pageIndex) {
                          final startIndex = pageIndex * itemsPerPage;
                          if (startIndex >= allQuickPicks.length && allQuickPicks.isNotEmpty) {
                            return const SizedBox();
                          }

                          final pageItems = allQuickPicks.skip(startIndex).take(itemsPerPage).toList();

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: GridView.builder(
                              padding: EdgeInsets.zero,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                childAspectRatio: 1.0,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: pageItems.length,
                              itemBuilder: (context, index) {
                                final song = pageItems[index];

                                return GestureDetector(
                                  onTap: () {
                                    ref
                                        .read(playbackProvider.notifier)
                                        .setPlaylist(allQuickPicks, initialIndex: startIndex + index);
                                  },
                                  onLongPress: () {
                                    HapticFeedback.mediumImpact();
                                    _showSongOptions(context, song);
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: OptimizedImage(
                                            imagePath: song.artPath,
                                            width: itemWidth,
                                            height: itemWidth,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [Colors.transparent, Colors.black54],
                                                stops: [0.5, 1.0],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 8,
                                          bottom: 8,
                                          right: 8,
                                          child: Text(
                                            song.title,
                                            style: AppFonts.jostStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: Consumer(
                                            builder: (context, ref, _) {
                                              // Scoped watch: only this tile rebuilds on
                                              // playback ticks, instead of the whole home
                                              // tab (which also re-sorts the entire
                                              // library) re-rendering on every play/pause.
                                              final isNowPlayingHere = ref.watch(
                                                playbackProvider.select(
                                                  (s) => s.isPlaying && s.currentSong?.path == song.path,
                                                ),
                                              );
                                              // Animated GIF frame decoding
                                              // doesn't respect TickerMode - skip
                                              // mounting it while this tab is
                                              // offstage (see AndroidMainScreen),
                                              // where it wouldn't be visible
                                              // anyway.
                                              if (!isNowPlayingHere || !TickerMode.of(context)) {
                                                return const SizedBox.shrink();
                                              }
                                              return Container(
                                                color: Colors.black.withValues(alpha: 0.5),
                                                child: Center(
                                                  child: Image.asset(
                                                    'assets/android_icons/Playing.gif',
                                                    width: 32,
                                                    height: 32,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(validPageCount, (index) {
                        final isActive = _currentQuickPickPage == index;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isActive ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isActive ? Colors.white : Colors.white24,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        );
        orderedSlivers.add(const SliverToBoxAdapter(child: SizedBox(height: 16)));
      } else if (section == 'songs') {
        orderedSlivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.songs,
                    style: AppFonts.jostStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  PremiumSection(
                    borderRadius: BorderRadius.circular(32),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    height: 40,
                    useExpanded: false,
                    useBlur: useBlur,
                    forceNoBlur: true,
                    backgroundColor: Colors.white.withValues(alpha: 0.04),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref.read(appNavigationProvider.notifier).setItem(NavItem.songs);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.viewAll,
                          style: AppFonts.jostStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        const Icon(LucideIcons.arrowRight, size: 16, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        orderedSlivers.add(
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final song = dateAddedSongs[index];
              return SongTile(key: ValueKey(song.path), song: song, l10n: l10n, songs: dateAddedSongs);
            }, childCount: dateAddedSongs.length > 10 ? 10 : dateAddedSongs.length),
          ),
        );
        orderedSlivers.add(const SliverToBoxAdapter(child: SizedBox(height: 16)));
      } else if (section == 'artists') {
        if (showHomeArtists && artists.isNotEmpty) {
          orderedSlivers.add(
            _buildHorizontalSection(
              title: l10n.artists,
              actionText: l10n.viewAll,
              onActionTap: () {
                HapticFeedback.mediumImpact();
                ref.read(appNavigationProvider.notifier).setItem(NavItem.artists);
              },
              itemCount: artists.length,
              itemBuilder: (context, index) {
                return _buildArtistItem(artists[index], l10n);
              },
            ),
          );
        }
      } else if (section == 'albums') {
        if (showHomeAlbums && albums.isNotEmpty) {
          orderedSlivers.add(
            _buildHorizontalSection(
              title: l10n.albums,
              actionText: l10n.viewAll,
              onActionTap: () {
                HapticFeedback.mediumImpact();
                ref.read(appNavigationProvider.notifier).setItem(NavItem.albums);
              },
              itemCount: albums.length,
              itemBuilder: (context, index) {
                return _buildAlbumItem(albums[index], l10n);
              },
            ),
          );
        }
      } else if (section == 'genres') {
        if (showHomeGenres && genres.isNotEmpty) {
          orderedSlivers.add(
            _buildHorizontalSection(
              title: l10n.genres,
              actionText: l10n.viewAll,
              onActionTap: () {
                HapticFeedback.mediumImpact();
                ref.read(appNavigationProvider.notifier).setItem(NavItem.genres);
              },
              itemCount: genres.length,
              itemBuilder: (context, index) {
                final genre = genres[index];
                return _buildGenreItem(genre, genresMap[genre]!, l10n);
              },
            ),
          );
        }
      } else if (section == 'recent') {
        if (showHomeRecent && recentSongs.isNotEmpty) {
          orderedSlivers.add(
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.recentPlayed,
                      style: AppFonts.jostStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    PremiumSection(
                      borderRadius: BorderRadius.circular(32),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      height: 40,
                      useExpanded: false,
                      useBlur: useBlur,
                      forceNoBlur: true,
                      backgroundColor: Colors.white.withValues(alpha: 0.04),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ref.read(appNavigationProvider.notifier).setItem(NavItem.history);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.viewAll,
                            style: AppFonts.jostStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 4),
                          const Icon(LucideIcons.arrowRight, size: 16, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

          orderedSlivers.add(SliverToBoxAdapter(child: _buildRecentPlayedRow(recentSongs)));
          orderedSlivers.add(const SliverToBoxAdapter(child: SizedBox(height: 16)));
        }
      }
    }

    orderedSlivers.add(const SliverToBoxAdapter(child: SizedBox(height: 200)));

    return SafeArea(
      child: AppRefreshIndicator(
        onRefresh: () => ref.read(libraryProvider.notifier).scanSavedFolders(showVisualIndicator: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: orderedSlivers,
        ),
      ),
    );
  }
}
