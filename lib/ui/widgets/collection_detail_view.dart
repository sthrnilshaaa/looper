import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:looper_player/core/responsive.dart';
import 'package:looper_player/ui/screens/android/widgets/premium_section.dart';
import 'package:looper_player/features/settings/presentation/settings_notifier.dart';
import 'package:looper_player/ui/widgets/optimized_image.dart';
import 'package:looper_player/ui/widgets/app_bottom_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/library/presentation/songs_list.dart';
import 'package:looper_player/features/playback/presentation/playback_notifier.dart';
import 'package:looper_player/features/playlists/presentation/playlist_view.dart';
import 'package:looper_player/features/playlists/data/playlist_service.dart';
import 'package:looper_player/core/db_service.dart';
import 'package:looper_player/core/navigation_provider.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/core/app_fonts.dart';
import 'package:looper_player/features/library/presentation/library_grids.dart';
import 'package:looper_player/ui/widgets/edit_album_sheet.dart';

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
        ? ref.watch(playlistProvider.select((list) => list.firstWhere((p) => p.id == playlist!.id, orElse: () => playlist!)))
        : null;

    // Reactively watch the album object if it is passed, so the header
    // (name/artist/artwork) updates live when the album is edited.
    // albumsProvider is a StreamProvider (AsyncValue), unlike playlistProvider
    // above which is a plain StateNotifierProvider<..., List<Playlist>>.
    final reactiveAlbum = album != null
        ? (ref.watch(albumsProvider).value?.firstWhere(
                (a) => a.id == album!.id,
                orElse: () => album!,
              ) ??
            album)
        : null;

    final titleToRender = reactivePlaylist?.name ?? reactiveAlbum?.name ?? title;
    // Fall back to the static nav-args only when there is no reactive album at
    // all - once one is present its own (possibly now-null) fields are the
    // source of truth, so clearing the artwork/artist in the edit sheet is
    // reflected instead of being masked by the stale value passed at nav time.
    final artToRender = reactiveAlbum != null ? reactiveAlbum.artPath : artPath;
    final subtitleToRender = reactiveAlbum != null ? reactiveAlbum.artist : subtitle;

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

    final sortOptionIndex = ref.watch(settingsProvider.select((s) => s.collectionSortOptionIndex));
    final sortOption = CollectionSortOption.values[sortOptionIndex.clamp(0, CollectionSortOption.values.length - 1)];
    final sortedSongs = List<Song>.from(songsToRender);
    switch (sortOption) {
      case CollectionSortOption.defaultOrder:
        break;
      case CollectionSortOption.titleAsc:
        sortedSongs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case CollectionSortOption.titleDesc:
        sortedSongs.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case CollectionSortOption.artistAsc:
        sortedSongs.sort((a, b) => (a.artist ?? '').toLowerCase().compareTo((b.artist ?? '').toLowerCase()));
        break;
      case CollectionSortOption.albumAsc:
        sortedSongs.sort((a, b) => (a.album ?? '').toLowerCase().compareTo((b.album ?? '').toLowerCase()));
        break;
      case CollectionSortOption.duration:
        sortedSongs.sort((a, b) => (a.duration ?? 0).compareTo(b.duration ?? 0));
        break;
      case CollectionSortOption.yearNewest:
        sortedSongs.sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
        break;
      case CollectionSortOption.yearOldest:
        sortedSongs.sort((a, b) => (a.year ?? 0).compareTo(b.year ?? 0));
        break;
    }

    final canReorderPlaylist =
        reactivePlaylist != null && sortOption == CollectionSortOption.defaultOrder;

    return Scaffold(
      // Not Colors.transparent - see the comment on CategoryDetailWrapper's
      // Scaffold in library_categories_views.dart for why.
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 450;
            final isLandscape = Responsive.isLandscape(MediaQuery.sizeOf(context));
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
                          onTap: () => ref.read(appNavigationProvider.notifier).goBack(),
                          child: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 20),
                        ),
                      ),
                      // Header - Now always a Row for cover and name
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: isNarrow
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(child: _buildArt(context, true, artToRender)),
                                  const SizedBox(height: 20),
                                  _buildInfo(context, ref, true, activeSong?.artPath, reactivePlaylist, reactiveAlbum, titleToRender, subtitleToRender, sortedSongs),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _buildArt(context, true, artToRender),
                                  const SizedBox(width: 20),
                                  Expanded(child: _buildInfo(context, ref, true, activeSong?.artPath, reactivePlaylist, reactiveAlbum, titleToRender, subtitleToRender, sortedSongs)),
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
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final song = sortedSongs[index];
                        final l10n = AppLocalizations.of(context)!;
                        return SongTile(
                          key: ValueKey(song.path),
                          song: song,
                          l10n: l10n,
                          songs: sortedSongs,
                          playlist: reactivePlaylist,
                        );
                      },
                      childCount: sortedSongs.length,
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 200), // Added padding to fix navbar overlap
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

  Widget _buildArt(BuildContext context, bool isNarrow, String? artOverride) {
    final double size = 140; // Unified size for a cleaner Row look
    return OptimizedImage(
      imagePath: artOverride,
      imageUrl: imageUrl,
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(16),
      placeholder: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          LucideIcons.music,
          size: 48,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context, WidgetRef ref, bool isNarrow, String? activeArtworkPath, Playlist? reactivePlaylist, Album? reactiveAlbum, String titleToRender, String? subtitleToRender, List<Song> songsToRender) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titleToRender,
          style: AppFonts.jostStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitleToRender != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitleToRender,
            style: AppFonts.jostStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            PremiumSection(
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 44,
              useExpanded: false,
              onTap: () {
                HapticFeedback.mediumImpact();
                ref.read(playbackProvider.notifier).setPlaylist(songsToRender);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context)!.playAll,
                    style: AppFonts.jostStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PremiumSection(
              borderRadius: BorderRadius.circular(12),
              width: 44,
              height: 44,
              useExpanded: false,
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(playbackProvider.notifier).toggleShuffle();
                ref.read(playbackProvider.notifier).setPlaylist(songsToRender);
              },
              child: const Icon(LucideIcons.shuffle, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
            PremiumSection(
              borderRadius: BorderRadius.circular(12),
              width: 44,
              height: 44,
              useExpanded: false,
              onTap: () {
                HapticFeedback.lightImpact();
                _showSortBottomSheet(context, ref);
              },
              child: const Icon(LucideIcons.arrowUpDown, size: 16, color: Colors.white),
            ),
            if (reactivePlaylist != null) ...[
              const SizedBox(width: 8),
              PremiumSection(
                borderRadius: BorderRadius.circular(12),
                width: 44,
                height: 44,
                useExpanded: false,
                onTap: () => _showPlaylistOptions(context, ref, reactivePlaylist),
                child: const Icon(LucideIcons.moreHorizontal, size: 18, color: Colors.white),
              ),
            ] else if (reactiveAlbum != null) ...[
              const SizedBox(width: 8),
              PremiumSection(
                borderRadius: BorderRadius.circular(12),
                width: 44,
                height: 44,
                useExpanded: false,
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showEditAlbumSheet(context, ref, reactiveAlbum);
                },
                child: const Icon(LucideIcons.edit2, size: 18, color: Colors.white),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _showSortBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        final bool isArtistCollection = (subtitle != null && (subtitle!.toLowerCase() == 'artist' || subtitle == l10n.artist)) ||
            (songs.isNotEmpty && songs.every((s) => s.artist?.toLowerCase() == title.toLowerCase()));

        return AppBottomSheetContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.sortBy,
                style: AppFonts.jostStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              PremiumSection(
                borderRadius: BorderRadius.circular(20),
                padding: EdgeInsets.zero,
                useExpanded: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSortItem(context, ref, l10n.sortDefault, CollectionSortOption.defaultOrder),
                    const Divider(color: Colors.white10, height: 1, indent: 20, endIndent: 20),
                    _buildSortItem(context, ref, l10n.sortAlphabeticalAZ, CollectionSortOption.titleAsc),
                    const Divider(color: Colors.white10, height: 1, indent: 20, endIndent: 20),
                    _buildSortItem(context, ref, l10n.sortAlphabeticalZA, CollectionSortOption.titleDesc),
                    if (!isArtistCollection) ...[
                      const Divider(color: Colors.white10, height: 1, indent: 20, endIndent: 20),
                      _buildSortItem(context, ref, l10n.sortArtistAsc, CollectionSortOption.artistAsc),
                    ],
                    const Divider(color: Colors.white10, height: 1, indent: 20, endIndent: 20),
                    _buildSortItem(context, ref, l10n.sortAlbumAsc, CollectionSortOption.albumAsc),
                    const Divider(color: Colors.white10, height: 1, indent: 20, endIndent: 20),
                    _buildSortItem(context, ref, l10n.sortDuration, CollectionSortOption.duration),
                    const Divider(color: Colors.white10, height: 1, indent: 20, endIndent: 20),
                    _buildSortItem(context, ref, l10n.sortYearNewest, CollectionSortOption.yearNewest),
                    const Divider(color: Colors.white10, height: 1, indent: 20, endIndent: 20),
                    _buildSortItem(context, ref, l10n.sortYearOldest, CollectionSortOption.yearOldest),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortItem(
    BuildContext context,
    WidgetRef ref,
    String label,
    CollectionSortOption value,
  ) {
    final settings = ref.watch(settingsProvider);
    final isSelected = settings.collectionSortOptionIndex == value.index;
    final accentColor = Color(settings.accentColor);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(settingsProvider.notifier).updateCollectionSortOptionIndex(value.index);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppFonts.jostStyle(
                color: isSelected ? accentColor : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
              ),
            ),
            if (isSelected)
              Icon(LucideIcons.check, color: accentColor, size: 20),
          ],
        ),
      ),
    );
  }

  void _showPlaylistOptions(BuildContext context, WidgetRef ref, Playlist playlist) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      isScrollControlled: true,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        final settings = ref.watch(settingsProvider);
        final useBlur = settings.enableDynamicTheming && !settings.disableBlur;
        final isPureBlack = settings.darkTheme;

        final sheetBg = isPureBlack
            ? Colors.black 
            : (useBlur ? Colors.black.withValues(alpha: 0.6) : const Color(0xFF1E1E1E));

        Widget sheetContent = Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isPureBlack ? Colors.white10 : Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.listMusic, size: 24, color: Colors.orangeAccent),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          playlist.name,
                          style: AppFonts.jostStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 8),
                PremiumSection(
                  borderRadius: BorderRadius.circular(20),
                  padding: EdgeInsets.zero,
                  useExpanded: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _showRenameDialog(context, ref, playlist);
                        },
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.edit2, size: 22, color: Colors.greenAccent),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  l10n.renamePlaylist,
                                  style: AppFonts.jostStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Icon(
                                LucideIcons.chevronRight,
                                color: Colors.white.withValues(alpha: 0.9),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(
                        height: 1,
                        thickness: 0.8,
                        color: Colors.white.withValues(alpha: 0.04),
                        indent: 20,
                        endIndent: 20,
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _showDeleteDialog(context, ref, playlist);
                        },
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.trash2, size: 22, color: Colors.redAccent),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  l10n.deletePlaylist,
                                  style: AppFonts.jostStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Icon(
                                LucideIcons.chevronRight,
                                color: Colors.white.withValues(alpha: 0.9),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );

        if (useBlur && !isPureBlack) {
          return RepaintBoundary(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: sheetContent,
              ),
            ),
          );
        }

        return sheetContent;
      },
    );
  }

  void _showEditAlbumSheet(BuildContext context, WidgetRef ref, Album album) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditAlbumSheet(album: album),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, Playlist playlist) {
    final controller = TextEditingController(text: playlist.name);
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          title: Text(l10n.renamePlaylist),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: l10n.newPlaylist),
            autofocus: true,
            style: AppFonts.jostStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                if (controller.text.isNotEmpty && controller.text != playlist.name) {
                  await DbService.isar.writeTxn(() async {
                    playlist.name = controller.text;
                    playlist.dateModified = DateTime.now();
                    await DbService.isar.playlists.put(playlist);
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(l10n.rename),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Playlist playlist) {
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          title: Text(l10n.deletePlaylist),
          content: Text(l10n.deletePlaylistConfirm(playlist.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                await DbService.isar.writeTxn(() => DbService.isar.playlists.delete(playlist.id));
                Navigator.pop(context); // Close dialog
                ref.read(appNavigationProvider.notifier).goBack(); // Go back using appNavigationProvider to stay in sync
              },
              child: Text(l10n.delete, style: AppFonts.jostStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }
}
