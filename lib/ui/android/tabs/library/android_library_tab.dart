import 'package:looper_player/core/motion/looper_scroll_physics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:looper_player/features/playlists/presentation/widgets/playlist_artwork.dart';
import 'package:looper_player/ui/widgets/common/song_artwork.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';
import 'package:looper_player/features/library/presentation/providers/library/library_notifier.dart';
import 'package:looper_player/features/library/presentation/providers/library/paged_songs_notifier.dart';
import 'package:looper_player/ui/widgets/common/app_refresh_indicator.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/android/widgets/large_tab_header.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';

// Panel = the dark rounded group; tile = the lighter card inside it.
final _panelColor = Colors.white.withValues(alpha: 0.06);
final _tileColor = Colors.white.withValues(alpha: 0.11);
final _ghostColor = Colors.white.withValues(alpha: 0.16);

class AndroidLibraryTab extends ConsumerWidget {
  const AndroidLibraryTab({super.key});

  void _go(WidgetRef ref, NavItem item) {
    AppHaptics.light();
    ref.read(appNavigationProvider.notifier).setItem(item);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final favoriteArt = _arts(
      ref.watch(favoritesProvider).value?.map((s) => s.artPath),
    );
    final playlists = ref.watch(libraryProvider.select((s) => s.playlists));
    // Custom covers first, then the playlists' songs (read from the
    // database).
    final playlistArt = _arts([
      for (final p in playlists) p.coverPath,
      for (final p in playlists.take(4))
        ...?ref.watch(playlistArtworkProvider(p.songPaths)).value,
    ]);
    final albums = ref.watch(libraryProvider.select((s) => s.albums));
    final artists = ref.watch(libraryProvider.select((s) => s.artists));
    final folderCount = ref.watch(songsByFolderProvider).length;
    final genreCount = ref.watch(songsByGenreProvider).length;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LargeTabHeader(eyebrow: l10n.yourLibraryEyebrow, title: l10n.library),
          Expanded(
            child: TabHeaderFade(
              child: AppRefreshIndicator(
                onRefresh: () => ref
                    .read(libraryProvider.notifier)
                    .refreshLibrary(showVisualIndicator: true),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: LooperScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(17, 8, 17, 200),
                  children: [
                    _Panel(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RecentlyPlayed(
                        onOpen: () => _go(ref, NavItem.recentlyPlayed),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _Panel(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _CategoryTile(
                                title: l10n.favorites,
                                icon: Icons.bookmark_rounded,
                                svg: (
                                  'assets/icons/library/star.svg',
                                  right: -20,
                                  top: -29,
                                ),
                                onTap: () => _go(ref, NavItem.favorites),
                                bottom: _ArtStrip(paths: favoriteArt),
                              ),
                              const SizedBox(width: 8),
                              _CategoryTile(
                                title: l10n.playlists,
                                icon: Icons.queue_music_rounded,
                                svg: (
                                  'assets/icons/library/playlist.svg',
                                  right: -13.5,
                                  top: -13.8,
                                ),
                                onTap: () => _go(ref, NavItem.playlists),
                                bottom: _ArtStrip(paths: playlistArt),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _CategoryTile(
                                title: l10n.artists,
                                icon: Icons.mic_rounded,
                                svg: (
                                  'assets/icons/library/mic.svg',
                                  right: -6,
                                  top: -9,
                                ),
                                onTap: () => _go(ref, NavItem.artists),
                                count: artists.length,
                                bottom: _ArtStrip(
                                  paths: _arts(artists.map((a) => a.artPath)),
                                  circle: true,
                                  alignEnd: true,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _CategoryTile(
                                title: l10n.albums,
                                icon: Icons.album_rounded,
                                onTap: () => _go(ref, NavItem.albums),
                                bottom: _ArtStrip(
                                  paths: _arts(albums.map((a) => a.artPath)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    _Panel(
                      child: Row(
                        children: [
                          _CategoryTile(
                            title: l10n.folders,
                            icon: Icons.folder_copy_rounded,
                            iconAtBottom: true,
                            onTap: () => _go(ref, NavItem.folders),
                            count: folderCount,
                          ),
                          const SizedBox(width: 8),
                          _CategoryTile(
                            title: l10n.genres,
                            icon: Icons.apps_rounded,
                            iconAtBottom: true,
                            onTap: () => _go(ref, NavItem.genres),
                            count: genreCount,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// First few distinct, non-empty artwork paths.
  static List<String> _arts(Iterable<String?>? paths) =>
      (paths ?? const <String?>[])
          .whereType<String>()
          .where((p) => p.isNotEmpty)
          .toSet()
          .take(4)
          .toList();
}

class _Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _Panel({required this.child, this.padding = const EdgeInsets.all(8)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _RecentlyPlayed extends ConsumerWidget {
  final VoidCallback onOpen;

  const _RecentlyPlayed({required this.onOpen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final songs = ref.watch(dashboardRecentlyPlayedProvider).value ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onOpen,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -7,
                top: -18,
                child: SvgPicture.asset('assets/icons/library/recent.svg'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(17, 16, 17, 16),
                child: Row(
                  children: [
                    Text(
                      l10n.recentlyPlayed,
                      style: AppFonts.jostStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          thickness: 0.6,
          indent: 12,
          endIndent: 12,
          color: Colors.white.withValues(alpha: 0.1),
        ),
        const SizedBox(height: 10),
        if (songs.isEmpty)
          SizedBox(
            height: 50,
            child: Center(
              child: Text(
                l10n.noRecentlyPlayedTracks,
                style: AppFonts.jostStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 13,
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const LooperScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: songs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 7),
              itemBuilder: (context, i) => _RecentCard(
                song: songs[i],
                onTap: () {
                  AppHaptics.light();
                  ref
                      .read(playbackProvider.notifier)
                      .setPlaylist(songs, initialIndex: i);
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _RecentCard extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;

  const _RecentCard({required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _tileColor,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 164,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11),
            child: Row(
              children: [
                SongArtwork(
                  song: song,
                  size: 34,
                  borderRadius: BorderRadius.circular(4),
                  indicatorSize: 18,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.jostStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.15,
                        ),
                      ),
                      if (song.artist?.isNotEmpty == true)
                        Text(
                          song.artist!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.jostStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 13,
                            height: 1.15,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A hub card: title top-left, a faint oversized icon top-right (or
/// bottom-right), and optionally a big clipped count and/or [bottom] art.
class _CategoryTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final int? count;
  final Widget? bottom;
  final bool iconAtBottom;

  /// The design's icon (asset, offset from the tile's top-right), drawn
  /// instead of [icon].
  final (String, {double right, double top})? svg;

  const _CategoryTile({
    required this.title,
    required this.icon,
    required this.onTap,
    this.count,
    this.bottom,
    this.iconAtBottom = false,
    this.svg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: _tileColor,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: iconAtBottom ? 85 : 87,
            child: Stack(
              children: [
                if (svg case (final asset, :final right, :final top))
                  Positioned(
                    right: right,
                    top: top,
                    child: SvgPicture.asset(asset),
                  )
                else
                  Positioned(
                    right: iconAtBottom ? 4 : -6,
                    top: iconAtBottom ? null : -8,
                    bottom: iconAtBottom ? -12 : null,
                    child: Transform.rotate(
                      angle: iconAtBottom ? 0 : -0.35,
                      child: Icon(icon, size: 64, color: _ghostColor),
                    ),
                  ),
                if (count != null)
                  Positioned(
                    left: 14,
                    bottom: -26,
                    child: Text(
                      '$count',
                      style: AppFonts.jostStyle(
                        color: _ghostColor,
                        fontSize: 76,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                if (bottom != null)
                  Positioned(left: 14, right: 0, bottom: 0, child: bottom!),
                Positioned(
                  left: 14,
                  top: 16,
                  right: 48,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.jostStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Overlapping artworks whose lower part runs off the card's bottom edge.
class _ArtStrip extends StatelessWidget {
  final List<String> paths;
  final bool circle;
  final bool alignEnd;

  const _ArtStrip({
    required this.paths,
    this.circle = false,
    this.alignEnd = false,
  });

  static const double _size = 44;
  static const double _step = 28;
  static const double _visible = 30;

  @override
  Widget build(BuildContext context) {
    if (paths.isEmpty) return const SizedBox.shrink();
    final shown = alignEnd ? paths.take(3).toList() : paths;
    final width = _size + _step * (shown.length - 1);
    return Align(
      alignment: alignEnd ? Alignment.bottomRight : Alignment.bottomLeft,
      child: SizedBox(
        width: width,
        height: _visible,
        child: OverflowBox(
          alignment: Alignment.topLeft,
          maxHeight: _size,
          child: Stack(
            children: [
              for (var i = 0; i < shown.length; i++)
                Positioned(
                  left: _step * i,
                  top: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: circle ? BoxShape.circle : BoxShape.rectangle,
                      borderRadius: circle ? null : BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, blurRadius: 6),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        circle ? _size / 2 : 4,
                      ),
                      child: OptimizedImage(
                        imagePath: shown[i],
                        width: _size,
                        height: _size,
                        cacheWidth: 132,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _LinkRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: AppFonts.jostStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: Colors.white.withValues(alpha: 0.5),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
