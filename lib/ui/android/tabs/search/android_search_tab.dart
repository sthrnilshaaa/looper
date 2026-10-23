import 'package:looper_player/features/library/data/services/artist_catalog.dart';
import 'package:looper_player/core/providers/collection_navigation.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';
import 'package:looper_player/core/providers/providers.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/l10n.dart';
import 'package:looper_player/ui/widgets/sheets/add_to_playlist_sheet.dart';
import 'package:looper_player/core/utils/motion.dart';
import 'package:looper_player/features/library/presentation/widgets/songs/song_tile.dart';
import 'package:looper_player/features/playback/presentation/providers/lyrics/lyrics_search_provider.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/features/playlists/data/services/playlist_service.dart';
import 'package:looper_player/features/playlists/presentation/screens/playlist_view.dart'
    show playlistProvider;
import 'package:looper_player/features/search/domain/artist_credits.dart';
import 'package:looper_player/features/search/domain/lyric_snippet.dart';
import 'package:looper_player/features/search/presentation/screens/search_view.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/common/app_loading_indicator.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

part 'search_actions.dart';
part 'search_header.dart';
part 'search_idle.dart';
part 'search_result_widgets.dart';
part 'search_results.dart';

/// Which kind of result the screen is narrowed to. [all] is the mixed
/// overview; the rest list one kind in full.
enum _SearchKind { all, songs, artists, albums, playlists, genres }

/// The Android search screen: a back arrow and search field, recent searches
/// while the field is empty, and filterable results once it is not. Songs in
/// the results can be multi-selected and sent to a playlist in one go.
class AndroidSearchTab extends ConsumerStatefulWidget {
  const AndroidSearchTab({super.key});

  @override
  ConsumerState<AndroidSearchTab> createState() => _AndroidSearchTabState();
}

class _AndroidSearchTabState extends ConsumerState<AndroidSearchTab> {
  late final TextEditingController _controller;
  Timer? _debounce;
  _SearchKind _kind = _SearchKind.all;
  final Set<String> _selected = {};
  // The results last delivered for a non-empty query. They stay on screen
  // while the next keystroke's query is still loading, so the list updates
  // in place instead of blinking to a spinner.
  SearchResults? _shown;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(searchQueryProvider));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(searchFocusNodeProvider).requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryProvider.notifier).set(value);
    });
  }

  void _clearQuery() {
    _debounce?.cancel();
    _controller.clear();
    ref.read(searchQueryProvider.notifier).set('');
    ref.read(searchFocusNodeProvider).requestFocus();
  }

  void _back() {
    FocusManager.instance.primaryFocus?.unfocus();
    ref.read(appNavigationProvider.notifier).goBack();
  }

  /// Saves the current query to Recent Searches. Called when the user acts on
  /// it (keyboard search key, or opening/playing a result), never per
  /// keystroke.
  void _remember() =>
      ref.read(recentSearchesProvider.notifier).add(_controller.text);

  void _toggle(Song song) {
    AppHaptics.selection();
    setState(() {
      if (!_selected.remove(song.path)) _selected.add(song.path);
    });
  }

  void _selectAll(List<Song> songs) {
    AppHaptics.selection();
    setState(() => _selected.addAll(songs.map((s) => s.path)));
  }

  void _clearSelection() => setState(_selected.clear);

  Future<void> _addSelectedToPlaylist(List<Song> songs) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final playlistName = await showAddToPlaylistSheet(
      context,
      songs.where((s) => _selected.contains(s.path)).toList(),
      suggestedName: _controller.text.trim(),
    );
    if (playlistName == null || !mounted) return;
    AppHaptics.success();
    _remember();
    _clearSelection();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.addedTo(playlistName)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);

    // Keeps the field in sync when the query changes from outside it (a
    // Recent Searches chip). A new query also means a new result set, so any
    // selection made in the old one is dropped.
    ref.listen(searchQueryProvider, (previous, next) {
      if (_controller.text != next) _controller.text = next;
      if (_selected.isNotEmpty) _clearSelection();
    });

    if (query.isEmpty) {
      _shown = null;
    } else if (resultsAsync case AsyncData(
      :final value,
    ) when !resultsAsync.isLoading) {
      _shown = value;
    }
    final results = _shown;
    final selecting = _selected.isNotEmpty && results != null;

    final Widget body;
    if (query.isEmpty) {
      body = const _SearchIdle();
    } else if (results == null) {
      body = resultsAsync.hasError
          ? Center(child: Text(l10n.errorWithDetails('${resultsAsync.error}')))
          : const AppLoadingIndicator();
    } else if (results.isEmpty) {
      body = _NoResults(query: query);
    } else {
      final counts = _countsOf(results);
      // A selection is always shown against the full song list, and a kind
      // whose matches vanished on the last keystroke falls back to All.
      final kind = selecting
          ? _SearchKind.songs
          : (counts.containsKey(_kind) ? _kind : _SearchKind.all);
      body = Column(
        children: [
          if (!selecting)
            _KindChips(
              counts: counts,
              selected: kind,
              onSelected: (next) {
                AppHaptics.selection();
                setState(() => _kind = next);
              },
            ),
          Expanded(
            child: _SearchResultsBody(
              results: results,
              query: query,
              kind: kind,
              selected: _selected,
              onShowKind: (next) => setState(() => _kind = next),
              onToggle: _toggle,
              onSelectAll: () => _selectAll(results.songs),
              onRemember: _remember,
            ),
          ),
        ],
      );
    }

    // Scaffold with an explicit opaque background, not a bare SafeArea:
    // this screen is reached via a non-opaque PageRoute (_createPremiumRoute)
    // meant to let the black root screen underneath show through, but that
    // compositing isn't reliable on every device/renderer combo (seen as a
    // white/native-window-background flash on some devices).
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            AnimatedSwitcher(
              duration: Motion.reducedOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              child: selecting
                  ? _SelectionBar(
                      key: const ValueKey('search-selection-bar'),
                      count: _selected.length,
                      onCancel: _clearSelection,
                      onSelectAll: () => _selectAll(results.songs),
                      onAddToPlaylist: () =>
                          _addSelectedToPlaylist(results.songs),
                    )
                  : _SearchHeader(
                      key: const ValueKey('search-header'),
                      controller: _controller,
                      focusNode: ref.watch(searchFocusNodeProvider),
                      onChanged: _onChanged,
                      onSubmitted: (_) => _remember(),
                      onClear: _clearQuery,
                      onBack: _back,
                    ),
            ),
            SizedBox(
              height: 2,
              child: results != null && resultsAsync.isLoading
                  ? const LinearProgressIndicator(
                      minHeight: 2,
                      backgroundColor: Colors.transparent,
                    )
                  : null,
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

/// The kinds that have matches in [results], in chip order, with how many.
/// [_SearchKind.all] is always present.
Map<_SearchKind, int> _countsOf(SearchResults results) => {
  _SearchKind.all: 0,
  if (results.songs.isNotEmpty) _SearchKind.songs: results.songs.length,
  if (results.artists.isNotEmpty) _SearchKind.artists: results.artists.length,
  if (results.albums.isNotEmpty) _SearchKind.albums: results.albums.length,
  if (results.playlists.isNotEmpty)
    _SearchKind.playlists: results.playlists.length,
  if (results.genres.isNotEmpty) _SearchKind.genres: results.genres.length,
};
