import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:looper_player/core/utils/responsive.dart';
import 'package:looper_player/ui/android/widgets/premium_section.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:looper_player/ui/widgets/common/song_favorite_button.dart';
import 'package:looper_player/ui/widgets/common/playlist_reorderable_listener.dart';
import 'package:looper_player/ui/widgets/common/song_playback_overlay.dart';
import 'package:looper_player/ui/widgets/common/collection_scroll_to_end.dart';
import 'package:looper_player/ui/widgets/collection_detail/collection_pinned_bar.dart';
import 'package:looper_player/ui/widgets/sheets/app_bottom_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/features/library/presentation/widgets/songs/songs_list.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/features/playlists/presentation/screens/playlist_view.dart';
import 'package:looper_player/features/playlists/presentation/widgets/playlist_artwork.dart';
import 'package:looper_player/features/playlists/data/services/playlist_service.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/library/presentation/widgets/library_grids.dart';
import 'package:looper_player/ui/widgets/sheets/edit_album_sheet.dart';
import 'package:looper_player/ui/widgets/sheets/edit_artist_sheet.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/utils/song_metadata.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:looper_player/features/library/presentation/providers/library/library_notifier.dart';
import 'package:looper_player/ui/widgets/sheets/song_options_bottom_sheet.dart';
part 'collection_header.dart';
part 'desktop_collection.dart';
part 'sort_sheet.dart';
part 'playlist_options.dart';

/// The big title of each open collection, which [CollectionPinnedBar]
/// watches to know when to show its own small one.
final _collectionTitleKeys = Expando<GlobalKey>();

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
  final Artist? artist;

  const CollectionDetailView({
    super.key,
    required this.title,
    this.subtitle,
    this.artPath,
    this.imageUrl,
    required this.songs,
    this.playlist,
    this.album,
    this.artist,
  });

  String _durationLabel(List<Song> songs, AppLocalizations l10n) {
    if (songs.any((song) => (song.duration ?? 0) <= 0)) return l10n.unknown;
    final totalMs = songs.fold<int>(
      0,
      (sum, song) => sum + (song.duration ?? 0),
    );
    final minutes = (totalMs / 60000).round();
    return minutes >= 60
        ? l10n.durationHoursMinutes(minutes ~/ 60, minutes % 60)
        : l10n.minutesShort(minutes);
  }

  Widget _buildCollectionSubtitle(
    String? label,
    List<Song> songs,
    AppLocalizations l10n, {
    bool songsLoading = false,
    required double fontSize,
    required Color color,
  }) {
    final hasLabel = label?.trim().isNotEmpty == true;
    final style = AppFonts.jostStyle(fontSize: fontSize, color: color);
    // Keep all of the metadata readable when the header is narrow or text is
    // enlarged. A single Text wraps within the column's available width.
    return Text(
      '${hasLabel ? '$label • ' : ''}${l10n.songsCount(songs.length)} • ${songsLoading ? l10n.unknown : _durationLabel(songs, l10n)}',
      style: style,
    );
  }

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

    // Same for an artist, so a picture changed in the edit sheet shows here
    // straight away.
    final reactiveArtist = artist != null && album == null
        ? (ref
                  .watch(artistsProvider)
                  .value
                  ?.firstWhere(
                    (a) => a.id == artist!.id,
                    orElse: () => artist!,
                  ) ??
              artist)
        : null;
    final artistImage = reactiveArtist?.artistImageUrl;
    final artistImageIsUrl = artistImage?.startsWith('http') ?? false;

    final titleToRender =
        reactivePlaylist?.name ?? reactiveAlbum?.name ?? title;
    // Fall back to the static nav-args only when there is no reactive album at
    // all - once one is present its own (possibly now-null) fields are the
    // source of truth, so clearing the artwork/artist in the edit sheet is
    // reflected instead of being masked by the stale value passed at nav time.
    final artToRender = reactiveAlbum != null
        ? reactiveAlbum.artPath
        : reactiveArtist != null
        ? (artistImage != null && !artistImageIsUrl
              ? artistImage
              : reactiveArtist.artPath)
        : artPath;
    final imageUrlToRender = reactiveArtist != null
        ? (artistImageIsUrl ? artistImage : null)
        : imageUrl;
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

    final songsLoading = playlistSongsAsync != null
        ? !playlistSongsAsync.hasValue
        : albumSongsAsync != null && !albumSongsAsync.hasValue;

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

    if (UiUtils.isDesktop) {
      return _buildDesktop(
        context,
        ref,
        title: titleToRender,
        subtitle: subtitleToRender,
        art: artToRender,
        imageUrl: imageUrlToRender,
        songs: sortedSongs,
        songsLoading: songsLoading,
        reactivePlaylist: reactivePlaylist,
        reactiveAlbum: reactiveAlbum,
        reactiveArtist: reactiveArtist,
        canReorder: canReorderPlaylist && sortedSongs.isNotEmpty,
        activePath: activeSong?.path,
      );
    }

    // One key per screen: the scroll controller lives as long as it does.
    GlobalKey titleKey(ScrollController controller) =>
        _collectionTitleKeys[controller] ??= GlobalKey();

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
            Widget songRow(int index, {int? reorderIndex}) => SongTile(
              key: ValueKey((sortedSongs[index].path, index)),
              song: sortedSongs[index],
              l10n: AppLocalizations.of(context)!,
              songs: sortedSongs,
              playlist: reactivePlaylist,
              collectionIndex: index,
              reorderIndex: reorderIndex,
            );
            final songDelegate = SliverChildBuilderDelegate(
              (context, index) => songRow(index),
              childCount: sortedSongs.length,
            );
            Widget buildScrollView(
              ScrollController controller,
            ) => CustomScrollView(
              controller: controller,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: CollectionPinnedBar(
                    controller: controller,
                    titleKey: titleKey(controller),
                    title: titleToRender,
                    art: artToRender,
                    imageUrl: imageUrlToRender,
                    playlist: reactivePlaylist,
                    onBack: () =>
                        ref.read(appNavigationProvider.notifier).goBack(),
                    onAdd: reactivePlaylist != null
                        ? () => _showAddSongsHint(context)
                        : null,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                      playlist: reactivePlaylist,
                                      imageUrl: imageUrlToRender,
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
                                    songsLoading: songsLoading,
                                    canReorder:
                                        canReorderPlaylist &&
                                        sortedSongs.length > 1,
                                    titleKey: titleKey(controller),
                                    reactiveArtist: reactiveArtist,
                                  ),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _buildArt(
                                    context,
                                    true,
                                    artToRender,
                                    playlist: reactivePlaylist,
                                    imageUrl: imageUrlToRender,
                                  ),
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
                                      songsLoading: songsLoading,
                                      canReorder:
                                          canReorderPlaylist &&
                                          sortedSongs.length > 1,
                                      titleKey: titleKey(controller),
                                      reactiveArtist: reactiveArtist,
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
                      // Equal-height rows let Flutter jump without laying out
                      // every intervening song. Measure one for text scaling.
                      prototypeItem: TickerMode(
                        enabled: false,
                        child: songRow(0),
                      ),
                      itemBuilder: (context, index) =>
                          songRow(index, reorderIndex: index),
                      itemCount: sortedSongs.length,
                      onReorderStart: (_) => AppHaptics.medium(),
                      onReorder: (oldIndex, newIndex) {
                        PlaylistService.reorderSong(
                          reactivePlaylist,
                          oldIndex,
                          newIndex,
                        );
                      },
                    )
                  else
                    SliverPrototypeExtentList(
                      prototypeItem: TickerMode(
                        enabled: false,
                        child: songRow(0),
                      ),
                      delegate: songDelegate,
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
            return CollectionScrollToEnd(
              bottomPadding: activeSong != null ? 100 : 16,
              builder: (controller) => isLandscape
                  ? Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 700),
                        child: buildScrollView(controller),
                      ),
                    )
                  : buildScrollView(controller),
            );
          },
        ),
      ),
    );
  }
}
