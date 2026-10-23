import 'package:looper_player/features/library/data/services/artist_catalog.dart';
import 'package:flutter/material.dart';
import 'package:looper_player/ui/widgets/common/app_loading_indicator.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/ui/widgets/player/playing_overlay.dart';
import 'package:isar_community/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:looper_player/core/utils/l10n.dart';
import 'package:looper_player/ui/desktop/widgets/hover_card.dart';

part 'library_grids.g.dart';

// Providers for Albums and Artists
@Riverpod(keepAlive: true)
Stream<List<Album>> albums(Ref ref) {
  return DbService.isar.albums.where().sortByDateAddedDesc().watch(
    fireImmediately: true,
  );
}

@Riverpod(keepAlive: true)
Stream<List<Artist>> artists(Ref ref) {
  return DbService.isar.artists.where().sortByName().watch(
    fireImmediately: true,
  );
}

/// Reactively watches every song tagged with [albumName], so a
/// CollectionDetailView opened for an album updates live when that album
/// (or one of its songs) is edited, instead of showing a stale snapshot.
@Riverpod(keepAlive: true)
Stream<List<Song>> songsForAlbum(Ref ref, String albumName) {
  return DbService.isar.songs
      .filter()
      .albumEqualTo(albumName)
      .watch(fireImmediately: true);
}

class AlbumsGrid extends ConsumerWidget {
  const AlbumsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(albumsProvider);

    return albumsAsync.when(
      data: (albums) => GridView.builder(
        // The bottom inset keeps the last row clear of the player bar.
        padding: EdgeInsets.fromLTRB(24.s, 16.s, 24.s, 140),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200.s,
          childAspectRatio: 0.72,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemCount: albums.length,
        itemBuilder: (context, index) => _AlbumCard(album: albums[index]),
      ),
      loading: () => const AppLoadingIndicator(),
      error: (e, s) => Center(child: Text(context.l10n.errorWithDetails('$e'))),
    );
  }
}

class _AlbumCard extends ConsumerWidget {
  final Album album;
  const _AlbumCard({required this.album});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep identifying the current album while its song is paused.
    final isCurrentAlbum = ref.watch(
      playbackProvider.select((s) => s.currentSong?.album == album.name),
    );
    // Same reasoning as isCurrentAlbum above: select just whether THIS
    // album is the selected one, instead of watching the whole nav state
    // (which would rebuild every visible card on any navigation change).
    final isSelected = ref.watch(
      appNavigationProvider.select(
        (nav) =>
            nav.activeItem == NavItem.collectionDetail &&
            nav.collectionTitle == album.name,
      ),
    );

    return HoverCard(
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
              album: album,
            );
      },
      selected: isSelected,
      child: Padding(
        padding: EdgeInsets.all(12.s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  color: Colors.white.withValues(alpha: 0.05),
                ),
                child: PlayingOverlay(
                  isCurrent: isCurrentAlbum,
                  isPlaying:
                      isCurrentAlbum &&
                      ref.watch(playbackProvider.select((s) => s.isPlaying)),
                  borderRadius: 16,
                  child: album.artPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: OptimizedImage(
                            imagePath: album.artPath,
                            fit: BoxFit.cover,
                            placeholder: const Center(
                              child: Icon(
                                LucideIcons.disc,
                                size: 48,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            LucideIcons.disc,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.name,
                    style: AppFonts.jostStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 14.ts,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    album.artist ?? context.l10n.unknownArtist,
                    style: AppFonts.jostStyle(
                      color: Colors.grey[400],
                      fontSize: 12.ts,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ArtistsGrid extends ConsumerWidget {
  const ArtistsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistsAsync = ref.watch(artistsProvider);

    return artistsAsync.when(
      data: (artists) => GridView.builder(
        // The bottom inset keeps the last row clear of the player bar.
        padding: EdgeInsets.fromLTRB(24.s, 16.s, 24.s, 140),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 190.s,
          childAspectRatio: 0.82,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: artists.length,
        itemBuilder: (context, index) => _ArtistCard(artist: artists[index]),
      ),
      loading: () => const AppLoadingIndicator(),
      error: (e, s) => Center(child: Text(context.l10n.errorWithDetails('$e'))),
    );
  }
}

class _ArtistCard extends ConsumerWidget {
  final Artist artist;
  const _ArtistCard({required this.artist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Select just whether THIS artist is the selected one, instead of
    // watching the whole nav state (which would rebuild every visible card
    // on any navigation change).
    final isSelected = ref.watch(
      appNavigationProvider.select(
        (nav) =>
            nav.activeItem == NavItem.collectionDetail &&
            nav.collectionTitle == artist.name,
      ),
    );

    return HoverCard(
      onTap: () async {
        final songs = await ArtistCatalog.songsFor(artist.name);
        final isLocalImage =
            artist.artistImageUrl != null &&
            !artist.artistImageUrl!.startsWith('http');
        final isNetworkImage =
            artist.artistImageUrl != null &&
            artist.artistImageUrl!.startsWith('http');

        ref
            .read(appNavigationProvider.notifier)
            .showCollection(
              title: artist.name,
              art: isLocalImage ? artist.artistImageUrl : artist.artPath,
              imageUrl: isNetworkImage ? artist.artistImageUrl : null,
              songs: songs,
              artist: artist,
            );
      },
      selected: isSelected,
      child: Padding(
        padding: EdgeInsets.all(12.s),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  color: Colors.white.withValues(alpha: 0.05),
                ),
                child: ClipOval(
                  child: OptimizedImage(
                    imageUrl: artist.artistImageUrl,
                    imagePath: artist.artPath,
                    fit: BoxFit.cover,
                    placeholder: const Center(
                      child: Icon(
                        LucideIcons.user,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              artist.name,
              textAlign: TextAlign.center,
              style: AppFonts.jostStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14.ts,
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
