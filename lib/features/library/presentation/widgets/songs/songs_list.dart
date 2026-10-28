import 'package:looper_player/core/motion/list_wave.dart';
import 'package:looper_player/core/motion/app_routes.dart';
import 'package:looper_player/core/motion/looper_scroll_physics.dart';
import 'package:looper_player/core/theme/app_fonts.dart';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/features/library/presentation/providers/library/library_notifier.dart';
import 'package:looper_player/ui/widgets/common/app_refresh_indicator.dart';
import 'package:looper_player/ui/widgets/sheets/app_bottom_sheet.dart';

import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/core/services/storage/media_store_write_service.dart';

import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/android/widgets/enrichment_indicator.dart';
import 'package:looper_player/ui/android/widgets/library_skeletons.dart';
import 'package:looper_player/ui/widgets/common/app_skeleton.dart';
import 'package:looper_player/ui/android/widgets/premium_section.dart';
import 'package:looper_player/features/playlists/data/services/playlist_service.dart';
import 'package:looper_player/features/playlists/presentation/screens/playlist_view.dart'
    show playlistProvider;
import 'package:looper_player/features/library/domain/song_full_plays.dart';
import 'package:looper_player/ui/widgets/common/fast_scroller.dart';
import 'package:looper_player/ui/widgets/common/momentum_scroll_controller.dart';

import 'song_tile.dart';

import 'package:looper_player/core/utils/ui_utils.dart';

import 'song_columns.dart';

import 'package:looper_player/core/utils/l10n.dart';
import 'package:looper_player/ui/widgets/sheets/add_to_playlist_sheet.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';

export 'song_tile.dart';
part 'sort_bottom_sheet.dart';

class SongsList extends ConsumerStatefulWidget {
  final List<Song> songs;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final String? searchQuery;
  final Playlist? playlist;
  final ScrollController? controller;
  final bool showEnrichmentIndicator;

  /// The library's songs are still loading at app start and [songs] is the
  /// part loaded so far: skeleton rows follow it (scrolling ends there),
  /// the header shows [totalCount], taps queue the whole list once it is in,
  /// and selection waits.
  final bool loading;
  final int? totalCount;

  const SongsList({
    super.key,
    required this.songs,
    this.shrinkWrap = false,
    this.physics,
    this.searchQuery,
    this.playlist,
    this.controller,
    this.showEnrichmentIndicator = false,
    this.loading = false,
    this.totalCount,
  });

  @override
  ConsumerState<SongsList> createState() => _SongsListState();
}

// Selection lives here as plain widget state rather than a provider: nothing
// outside this list needs to know which rows are checked, and it must reset
// itself for free whenever the list is torn down (switching tabs, closing a
// playlist) instead of leaking a stale selection into the next screen.
class _SongsListState extends ConsumerState<SongsList> {
  final Set<String> _selectedPaths = {};

  // The fast scroller needs the list's controller; lists embedded without
  // one get their own.
  ScrollController? _ownController;
  ScrollController get _scrollController =>
      widget.controller ?? (_ownController ??= MomentumScrollController());

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  bool get _isSelecting => _selectedPaths.isNotEmpty;

  /// Skeleton rows after the loaded part while [SongsList.loading].
  static const int _skeletonRows = 6;

  int get _rowCount =>
      widget.songs.length + (widget.loading ? _skeletonRows : 0);

  // Rows from this index on were skeletons until the last part arrived and
  // fade in when they are built.
  int _revealFrom = 1 << 30;

  @override
  void didUpdateWidget(SongsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loading && widget.songs.length > oldWidget.songs.length) {
      _revealFrom = oldWidget.songs.length;
    }
  }

  List<Song> get _selectedSongs =>
      widget.songs.where((s) => _selectedPaths.contains(s.path)).toList();

  void _enterSelection(Song song) {
    setState(() => _selectedPaths.add(song.path));
  }

  void _toggleSelected(Song song) {
    setState(() {
      if (!_selectedPaths.remove(song.path)) {
        _selectedPaths.add(song.path);
      }
    });
  }

  void _clearSelection() => setState(_selectedPaths.clear);

  void _selectAll() {
    setState(() => _selectedPaths.addAll(widget.songs.map((s) => s.path)));
  }

  Future<void> _bulkFavorite() async {
    final selected = _selectedSongs;
    // Mixed selections favorite everything rather than toggling each song
    // independently - a per-song toggle would be unpredictable to the user
    // when some of the picked songs are already favorites and some aren't.
    final makeFavorite = selected.any((s) => !s.isFavorite);
    await ref
        .read(libraryProvider.notifier)
        .setFavorite(selected, makeFavorite);
    _clearSelection();
  }

  Future<void> _bulkAddToPlaylist(AppLocalizations l10n) async {
    final selected = _selectedSongs;
    final chosen = await showAddToPlaylistSheet(context, selected);
    if (chosen == null) return;
    if (!mounted) return;
    _clearSelection();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.addedTo(chosen)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _bulkShare() {
    ref.read(playbackProvider.notifier).shareSongs(_selectedSongs);
    _clearSelection();
  }

  Future<void> _bulkDelete(AppLocalizations l10n) async {
    final selected = _selectedSongs;
    final confirmed = await showTaskDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteSong),
        content: Text('${l10n.deleteSongConfirm} (${selected.length})'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              l10n.delete,
              style: AppFonts.jostStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    if (Platform.isAndroid) {
      // One MediaStore consent dialog covering every selected file at once
      // (API 30+) instead of the per-song dialog deleteSong() below would
      // otherwise trigger for each one. Whatever this can't cover (no batch
      // consent API before Android 11, or a file it couldn't resolve) is
      // simply left on disk for deleteSong() to prompt for individually.
      await MediaStoreWriteService.deleteFilesBatch(
        selected.map((s) => s.path).toList(),
      );
    }

    final notifier = ref.read(playbackProvider.notifier);
    // Sequential, reusing the same single-song path deleteSong() already
    // takes (file removal, DB row, queue/orphan bookkeeping) - a bulk-only
    // fast path isn't worth duplicating that logic for what's normally a
    // handful of songs at a time.
    for (final song in selected) {
      await notifier.deleteSong(song);
    }
    if (!mounted) return;
    _clearSelection();
  }

  Widget _buildSelectionBar(AppLocalizations l10n) {
    final accentColor = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.x, size: 20),
            onPressed: _clearSelection,
            tooltip: l10n.cancel,
          ),
          Expanded(
            child: Text(
              '${_selectedPaths.length}',
              style: AppFonts.jostStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: _selectAll,
            child: Text(context.l10n.selectAll),
          ),
          IconButton(
            icon: const Icon(LucideIcons.heart, size: 20),
            color: accentColor,
            tooltip: l10n.addToFavorites,
            onPressed: _bulkFavorite,
          ),
          IconButton(
            icon: const Icon(LucideIcons.listMusic, size: 20),
            color: accentColor,
            tooltip: l10n.addToPlaylists,
            onPressed: () => _bulkAddToPlaylist(l10n),
          ),
          IconButton(
            icon: const Icon(LucideIcons.share2, size: 20),
            color: accentColor,
            tooltip: l10n.share,
            onPressed: _bulkShare,
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, size: 20),
            color: Colors.redAccent,
            tooltip: l10n.delete,
            onPressed: () => _bulkDelete(l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    if (_isSelecting) return _buildSelectionBar(l10n);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${widget.loading ? (widget.totalCount ?? widget.songs.length) : widget.songs.length} ${l10n.songs}',
            style: AppFonts.jostStyle(color: Colors.grey, fontSize: 13),
          ),
          if (widget.showEnrichmentIndicator)
            const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: EnrichmentIndicator(),
                  ),
                ),
              ),
            ),
          Row(
            children: [
              IconButton(
                onPressed: () => _showSortBottomSheet(context, ref, l10n),
                icon: const Icon(LucideIcons.listFilter, size: 18),
                tooltip: l10n.sortBy,
                style: IconButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The list every platform had before two-column mode; moved here
  /// unchanged so the desktop path can choose between it and the grid.
  Widget _buildSingleColumnList(AppLocalizations l10n) {
    if (!UiUtils.isDesktop) {
      // Touch screens have no scrollbar to grab, so a long list gets a
      // draggable thumb; desktop keeps its own scrollbar.
      return FastScroller(
        controller: _scrollController,
        itemCount: _rowCount,
        labelBuilder: _scrollLabelBuilder(),
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 180),
        child: _buildSingleColumnListView(l10n, _scrollController),
      );
    }
    return _buildSingleColumnListView(l10n, widget.controller);
  }

  /// The fast scroller's bubble text for a row - only where the order makes
  /// one meaningful: the library's own list, sorted by a name, year or play
  /// count.
  String? Function(int index)? _scrollLabelBuilder() {
    final library = ref.read(libraryProvider);
    if (!identical(widget.songs, library.songs)) return null;
    final songs = widget.songs;
    String? at(int i, String? Function(Song s) label) =>
        i < songs.length ? label(songs[i]) : null;
    return switch (library.sortStrategy) {
      SongSortStrategy.title => (i) => at(i, (s) => fastScrollLetter(s.title)),
      SongSortStrategy.artist => (i) => at(
        i,
        (s) => fastScrollLetter(s.artist),
      ),
      SongSortStrategy.album => (i) => at(i, (s) => fastScrollLetter(s.album)),
      SongSortStrategy.year => (i) => at(i, (s) => s.year?.toString() ?? '#'),
      SongSortStrategy.playCount => (i) => at(i, (s) => '${s.playCount}'),
      SongSortStrategy.fullPlays => (i) => at(
        i,
        (s) => songFullPlays(s).toStringAsFixed(1),
      ),
      _ => null,
    };
  }

  Widget _buildSingleColumnListView(
    AppLocalizations l10n,
    ScrollController? controller,
  ) {
    return ListView.builder(
      controller: controller,
      shrinkWrap: false,
      physics:
          widget.physics ??
          const AlwaysScrollableScrollPhysics(parent: LooperScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 180),
      itemCount: _rowCount,
      // Every row is the same fixed-height SongTile, so give the
      // sliver one real instance to measure once instead of
      // re-measuring each row as it scrolls into view - this is
      // the list a fast fling scroll actually has to keep up with.
      prototypeItem: _buildPrototypeRow(l10n),
      itemBuilder: (context, index) => _buildRow(index, l10n),
    );
  }

  /// One real, inert row for a list's `prototypeItem` to measure.
  Widget _buildPrototypeRow(AppLocalizations l10n) => SongTile(
    showAlbum: true,
    song: widget.songs.first,
    l10n: l10n,
    songs: widget.songs,
    searchQuery: widget.searchQuery,
    playlist: widget.playlist,
    selectionMode: false,
    selected: false,
    onToggleSelect: () {},
    onEnterSelection: () {},
  );

  Widget _buildRow(int index, AppLocalizations l10n) {
    if (index >= widget.songs.length) {
      return AppSkeleton(child: SongRowSkeleton(index: index));
    }
    final song = widget.songs[index];
    final tile = WaveItem(
      key: ValueKey(song.path),
      child: SongTile(
        showAlbum: true,
        song: song,
        l10n: l10n,
        songs: widget.songs,
        searchQuery: widget.searchQuery,
        playlist: widget.playlist,
        selectionMode: _isSelecting,
        selected: _selectedPaths.contains(song.path),
        onToggleSelect: () => _toggleSelected(song),
        onEnterSelection: widget.loading ? null : () => _enterSelection(song),
        resolveQueue: widget.loading
            ? ref.read(libraryProvider.notifier).loadedSongs
            : null,
      ),
    );
    return _RowReveal(
      key: ValueKey(song.path),
      animate: widget.loading && index >= _revealFrom,
      child: tile,
    );
  }

  /// Desktop only: the same rows laid out two across. 64 is the height of
  /// a two-line SongTile.
  Widget _buildTwoColumnGrid(AppLocalizations l10n) {
    return GridView.builder(
      controller: widget.controller,
      physics:
          widget.physics ??
          const AlwaysScrollableScrollPhysics(parent: LooperScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 180),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 64,
        crossAxisSpacing: 24,
      ),
      itemCount: widget.songs.length,
      itemBuilder: (context, index) => _buildRow(index, l10n),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Rows arrive as one wave when the list first appears on screen.
    return ListWave(
      child: Column(
        children: [
          _buildHeader(context, l10n),
          if (widget.shrinkWrap)
            ListView.builder(
              controller: widget.controller,
              shrinkWrap: true,
              physics: widget.physics ?? const LooperScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 180),
              itemCount: widget.songs.length,
              // Every row is the same fixed-height SongTile, so give the
              // sliver one real instance to measure once instead of
              // re-measuring each row as it scrolls into view.
              prototypeItem: _buildPrototypeRow(l10n),
              itemBuilder: (context, index) => _buildRow(index, l10n),
            )
          else
            Expanded(
              child: AppRefreshIndicator(
                onRefresh: () => ref
                    .read(libraryProvider.notifier)
                    .refreshLibrary(showVisualIndicator: false),
                child: UiUtils.isDesktop
                    ? LayoutBuilder(
                        builder: (context, constraints) =>
                            songColumnsFor(
                                  constraints.maxWidth,
                                  desktop: true,
                                  searching:
                                      widget.searchQuery?.isNotEmpty ?? false,
                                ) ==
                                2
                            ? _buildTwoColumnGrid(l10n)
                            : _buildSingleColumnList(l10n),
                      )
                    : _buildSingleColumnList(l10n),
              ),
            ),
        ],
      ),
    );
  }
}

/// Fades a row in when it replaces a loading skeleton row; otherwise it is
/// just [child]. Decided once, when the row is first built.
class _RowReveal extends StatefulWidget {
  const _RowReveal({super.key, required this.animate, required this.child});

  final bool animate;
  final Widget child;

  @override
  State<_RowReveal> createState() => _RowRevealState();
}

class _RowRevealState extends State<_RowReveal>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 260),
      )..forward();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return widget.child;
    return FadeTransition(
      opacity: CurvedAnimation(parent: controller, curve: Curves.easeOut),
      child: widget.child,
    );
  }
}
