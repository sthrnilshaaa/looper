import 'package:flutter/services.dart';
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
import 'package:looper_player/ui/android/widgets/premium_section.dart';
import 'package:looper_player/features/playlists/data/services/playlist_service.dart';
import 'package:looper_player/features/playlists/presentation/screens/playlist_view.dart'
    show playlistProvider;
import 'song_tile.dart';
import 'package:looper_player/core/utils/l10n.dart';
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

  const SongsList({
    super.key,
    required this.songs,
    this.shrinkWrap = false,
    this.physics,
    this.searchQuery,
    this.playlist,
    this.controller,
    this.showEnrichmentIndicator = false,
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

  bool get _isSelecting => _selectedPaths.isNotEmpty;

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
    final playlists = ref.read(playlistProvider);
    final chosen = await showDialog<Playlist>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).colorScheme.surfaceContainer,
        title: Text(l10n.addToPlaylists),
        content: playlists.isEmpty
            ? Text(l10n.noPlaylistsCreated)
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final p = playlists[index];
                    return ListTile(
                      leading: const Icon(LucideIcons.listMusic),
                      title: Text(p.name),
                      onTap: () => Navigator.pop(dialogContext, p),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
    if (chosen == null) return;
    await PlaylistService.addSongsToPlaylist(chosen, selected);
    if (!mounted) return;
    _clearSelection();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.addedTo(chosen.name)),
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
    final confirmed = await showDialog<bool>(
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
            '${widget.songs.length} ${l10n.songs}',
            style: AppFonts.jostStyle(color: Colors.grey, fontSize: 13),
          ),
          if (widget.showEnrichmentIndicator) const EnrichmentIndicator(),
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
              if (!Platform.isAndroid)
                TextButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10n.resetLibrary),
                        content: Text(l10n.resetLibraryConfirm),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(l10n.cancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              l10n.reset,
                              style: AppFonts.jostStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(libraryProvider.notifier).resetAndRescan();
                    }
                  },
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: Text(
                    l10n.resetLibrary,
                    style: AppFonts.jostStyle(fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    foregroundColor: Colors.red[300],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _buildHeader(context, l10n),
        if (widget.shrinkWrap)
          ListView.builder(
            controller: widget.controller,
            shrinkWrap: true,
            physics: widget.physics ?? const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 180),
            itemCount: widget.songs.length,
            // Every row is the same fixed-height SongTile, so give the
            // sliver one real instance to measure once instead of
            // re-measuring each row as it scrolls into view.
            prototypeItem: SongTile(
              song: widget.songs.first,
              l10n: l10n,
              songs: widget.songs,
              searchQuery: widget.searchQuery,
              playlist: widget.playlist,
              selectionMode: false,
              selected: false,
              onToggleSelect: () {},
              onEnterSelection: () {},
            ),
            itemBuilder: (context, index) {
              final song = widget.songs[index];
              return SongTile(
                key: ValueKey(song.path),
                song: song,
                l10n: l10n,
                songs: widget.songs,
                searchQuery: widget.searchQuery,
                playlist: widget.playlist,
                selectionMode: _isSelecting,
                selected: _selectedPaths.contains(song.path),
                onToggleSelect: () => _toggleSelected(song),
                onEnterSelection: () => _enterSelection(song),
              );
            },
          )
        else
          Expanded(
            child: AppRefreshIndicator(
              onRefresh: () => ref
                  .read(libraryProvider.notifier)
                  .scanSavedFolders(showVisualIndicator: false),
              child: ListView.builder(
                controller: widget.controller,
                shrinkWrap: false,
                physics:
                    widget.physics ??
                    const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 180),
                itemCount: widget.songs.length,
                // Every row is the same fixed-height SongTile, so give the
                // sliver one real instance to measure once instead of
                // re-measuring each row as it scrolls into view - this is
                // the list a fast fling scroll actually has to keep up with.
                prototypeItem: SongTile(
                  song: widget.songs.first,
                  l10n: l10n,
                  songs: widget.songs,
                  searchQuery: widget.searchQuery,
                  playlist: widget.playlist,
                  selectionMode: false,
                  selected: false,
                  onToggleSelect: () {},
                  onEnterSelection: () {},
                ),
                itemBuilder: (context, index) {
                  final song = widget.songs[index];
                  return SongTile(
                    key: ValueKey(song.path),
                    song: song,
                    l10n: l10n,
                    songs: widget.songs,
                    searchQuery: widget.searchQuery,
                    playlist: widget.playlist,
                    selectionMode: _isSelecting,
                    selected: _selectedPaths.contains(song.path),
                    onToggleSelect: () => _toggleSelected(song),
                    onEnterSelection: () => _enterSelection(song),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
