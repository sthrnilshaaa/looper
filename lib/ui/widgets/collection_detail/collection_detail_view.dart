import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:looper_player/core/utils/responsive.dart';
import 'package:looper_player/ui/android/widgets/premium_section.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:looper_player/ui/widgets/sheets/app_bottom_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/features/library/presentation/widgets/songs/songs_list.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/features/playlists/presentation/screens/playlist_view.dart';
import 'package:looper_player/features/playlists/data/services/playlist_service.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/library/presentation/widgets/library_grids.dart';
import 'package:looper_player/ui/widgets/sheets/edit_album_sheet.dart';
part 'collection_header.dart';
part 'sort_sheet.dart';
part 'playlist_options.dart';

// Persistent collection sorting is stored in settings.collectionSortOptionIndex

enum CollectionSortOption {
  defaultOrder,
  titleAsc,
  titleDesc,
  artistAsc,
  albumAsc,
  duration,
  yearNewest,
  yearOldest,
}

class CollectionDetailView extends ConsumerWidget {
  final String title;
  final String? subtitle;
  final String? artPath;
  final String? imageUrl;
  final List<Song> songs;
  final Playlist? playlist;
  final Album? album;

  const CollectionDetailView({
    super.key,
    required this.title,
    this.subtitle,
    this.artPath,
    this.imageUrl,
    required this.songs,
    this.playlist,
    this.album,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSong = ref.watch(playbackProvider.select((s) => s.currentSong));

    // Reactively watch the playlist object if it is passed, so the title updates when renamed
    final reactivePlaylist = playlist != null
        ? ref.watch(
            playlistProvider.select(
              (list) => list.firstWhere(
                (p) => p.id == playlist!.id,
                orElse: () => playlist!,
              ),
            ),
          )
        : null;

    // Reactively watch the album object if it is passed, so the header
    // (name/artist/artwork) updates live when the album is edited.
    // albumsProvider is a StreamProvider (AsyncValue), unlike playlistProvider
    // above which is a plain StateNotifierProvider<..., List<Playlist>>.
    final reactiveAlbum = album != null
        ? (ref
                  .watch(albumsProvider)
                  .value
                  ?.firstWhere(
                    (a) => a.id == album!.id,
                    orElse: () => album!,
                  ) ??
              album)
        : null;

    final titleToRender =
        reactivePlaylist?.name ?? reactiveAlbum?.name ?? title;
    // Fall back to the static nav-args only when there is no reactive album at
    // all - once one is present its own (possibly now-null) fields are the
    // source of truth, so clearing the artwork/artist in the edit sheet is
    // reflected instead of being masked by the stale value passed at nav time.
    final artToRender = reactiveAlbum != null ? reactiveAlbum.artPath : artPath;
    final subtitleToRender = reactiveAlbum != null
        ? reactiveAlbum.artist
        : subtitle;

    // Reactively watch songs of this playlist/album using their respective providers
    final playlistSongsAsync = playlist != null
        ? ref.watch(playlistSongsProvider(playlist!.id))
        : null;
    final albumSongsAsync = reactiveAlbum != null
        ? ref.watch(songsForAlbumProvider(reactiveAlbum.name))
        : null;

    final songsToRender = playlistSongsAsync != null
        ? (playlistSongsAsync.value ?? <Song>[])
        : albumSongsAsync != null
        ? (albumSongsAsync.value ?? <Song>[])
        : songs;

    final sortOptionIndex = ref.watch(
      settingsProvider.select((s) => s.collectionSortOptionIndex),
    );
    final sortOption =
        CollectionSortOption.values[sortOptionIndex.clamp(
          0,
          CollectionSortOption.values.length - 1,
        )];
    final sortedSongs = List<Song>.from(songsToRender);
    switch (sortOption) {
      case CollectionSortOption.defaultOrder:
        break;
      case CollectionSortOption.titleAsc:
        sortedSongs.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case CollectionSortOption.titleDesc:
        sortedSongs.sort(
          (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
        break;
      case CollectionSortOption.artistAsc:
        sortedSongs.sort(
          (a, b) => (a.artist ?? '').toLowerCase().compareTo(
            (b.artist ?? '').toLowerCase(),
          ),
        );
        break;
      case CollectionSortOption.albumAsc:
        sortedSongs.sort(
          (a, b) => (a.album ?? '').toLowerCase().compareTo(
            (b.album ?? '').toLowerCase(),
          ),
        );
        break;
      case CollectionSortOption.duration:
        sortedSongs.sort(
          (a, b) => (a.duration ?? 0).compareTo(b.duration ?? 0),
        );
        break;
      case CollectionSortOption.yearNewest:
        sortedSongs.sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
        break;
      case CollectionSortOption.yearOldest:
        sortedSongs.sort((a, b) => (a.year ?? 0).compareTo(b.year ?? 0));
        break;
    }

    final canReorderPlaylist =
        reactivePlaylist != null &&
        sortOption == CollectionSortOption.defaultOrder;

    return Scaffold(
      // Not Colors.transparent - see the comment on CategoryDetailWrapper's
      // Scaffold in library_categories_views.dart for why.
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 450;
            final isLandscape = Responsive.isLandscape(
              MediaQuery.sizeOf(context),
            );
            final scrollView = CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                        child: PremiumSection(
                          useExpanded: false,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(32),
                            bottomLeft: Radius.circular(32),
                            topRight: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                          width: 44,
                          height: 44,
                          onTap: () =>
                              ref.read(appNavigationProvider.notifier).goBack(),
                          child: const Icon(
                            LucideIcons.chevronLeft,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      // Header - Now always a Row for cover and name
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: isNarrow
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: _buildArt(
                                      context,
                                      true,
                                      artToRender,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _buildInfo(
                                    context,
                                    ref,
                                    true,
                                    activeSong?.artPath,
                                    reactivePlaylist,
                                    reactiveAlbum,
                                    titleToRender,
                                    subtitleToRender,
                                    sortedSongs,
                                  ),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _buildArt(context, true, artToRender),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: _buildInfo(
                                      context,
                                      ref,
                                      true,
                                      activeSong?.artPath,
                                      reactivePlaylist,
                                      reactiveAlbum,
                                      titleToRender,
                                      subtitleToRender,
                                      sortedSongs,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
                if (sortedSongs.isNotEmpty)
                  // Dragging to reorder only makes sense while sortedSongs is
                  // actually the playlist's own saved order - once a sort
                  // option (title/artist/duration/...) is applied, a row's
                  // on-screen position no longer corresponds to a slot in
                  // playlist.songPaths that dragging could sensibly write to.
                  if (canReorderPlaylist)
                    SliverReorderableList(
                      itemBuilder: (context, index) {
                        final song = sortedSongs[index];
                        final l10n = AppLocalizations.of(context)!;
                        return SongTile(
                          key: ValueKey(song.path),
                          song: song,
                          l10n: l10n,
                          songs: sortedSongs,
                          playlist: reactivePlaylist,
                          reorderIndex: index,
                        );
                      },
                      itemCount: sortedSongs.length,
                      onReorder: (oldIndex, newIndex) {
                        PlaylistService.reorderSong(
                          reactivePlaylist,
                          oldIndex,
                          newIndex,
                        );
                      },
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final song = sortedSongs[index];
                        final l10n = AppLocalizations.of(context)!;
                        return SongTile(
                          key: ValueKey(song.path),
                          song: song,
                          l10n: l10n,
                          songs: sortedSongs,
                          playlist: reactivePlaylist,
                        );
                      }, childCount: sortedSongs.length),
                    ),
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 200,
                  ), // Added padding to fix navbar overlap
                ),
              ],
            );
            // In landscape, cap the reading width and center it instead of
            // stretching the song list edge-to-edge across the whole window.
            return isLandscape
                ? Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: scrollView,
                    ),
                  )
                : scrollView;
          },
        ),
      ),
    );
  }
}
