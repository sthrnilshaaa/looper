import 'package:flutter/material.dart';
import 'package:looper_player/features/settings/presentation/screens/account_view.dart'
    show headerProfilePhoto;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/android/widgets/premium_section.dart';
import 'package:looper_player/ui/widgets/sheets/sort_menu_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/ui/android/widgets/large_tab_header.dart';
import 'package:looper_player/features/library/presentation/providers/library/library_notifier.dart';
import 'package:looper_player/features/library/presentation/providers/library/paged_songs_notifier.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'library_categories_views.dart';
import 'package:looper_player/features/library/presentation/widgets/songs/songs_list.dart'
    show showSongSortSheet;
import 'package:looper_player/core/services/haptics/app_haptics.dart';

class CategoryDetailWrapper extends ConsumerWidget {
  final String title;
  final Widget child;
  const CategoryDetailWrapper({
    super.key,
    required this.title,
    required this.child,
  });

  void _showSortBottomSheet(
    BuildContext context,
    WidgetRef ref,
    String title,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final settings = ref.watch(settingsProvider);
          final notifier = ref.read(settingsProvider.notifier);
          final (int current, void Function(int) set) = switch (title) {
            'Albums' => (
              settings.albumSortOptionIndex,
              notifier.updateAlbumSortOptionIndex,
            ),
            'Artists' => (
              settings.artistSortOptionIndex,
              notifier.updateArtistSortOptionIndex,
            ),
            _ => (
              settings.genreSortOptionIndex,
              notifier.updateGenreSortOptionIndex,
            ),
          };
          SortMenuItem item(String label, IconData icon, int index) =>
              SortMenuItem(
                label: label,
                icon: icon,
                selected: current == index,
                onTap: () => set(index),
              );

          return SortMenuSheet(
            title: l10n.sortBy,
            items: [
              if (title == 'Albums') ...[
                item(
                  l10n.sortAlphabeticalAZ,
                  LucideIcons.arrowDownAZ,
                  AlbumSortOption.nameAsc.index,
                ),
                item(
                  l10n.sortAlphabeticalZA,
                  LucideIcons.arrowUpZA,
                  AlbumSortOption.nameDesc.index,
                ),
                item(
                  l10n.sortRecentlyAdded,
                  LucideIcons.calendarPlus,
                  AlbumSortOption.dateAddedNewest.index,
                ),
                item(
                  l10n.sortOldestAdded,
                  LucideIcons.calendar,
                  AlbumSortOption.dateAddedOldest.index,
                ),
                item(
                  l10n.sortYearNewest,
                  LucideIcons.calendarArrowDown,
                  AlbumSortOption.yearNewest.index,
                ),
                item(
                  l10n.sortYearOldest,
                  LucideIcons.calendarArrowUp,
                  AlbumSortOption.yearOldest.index,
                ),
                item(
                  l10n.sortMostSongs,
                  LucideIcons.arrowDownWideNarrow,
                  AlbumSortOption.songCountDesc.index,
                ),
                item(
                  l10n.sortLeastSongs,
                  LucideIcons.arrowUpNarrowWide,
                  AlbumSortOption.songCountAsc.index,
                ),
                item(
                  l10n.mostPlayed,
                  LucideIcons.trendingUp,
                  AlbumSortOption.mostPlayed.index,
                ),
                item(
                  l10n.recentlyPlayed,
                  LucideIcons.history,
                  AlbumSortOption.recentlyPlayed.index,
                ),
              ] else if (title == 'Artists') ...[
                item(
                  l10n.sortAlphabeticalAZ,
                  LucideIcons.arrowDownAZ,
                  ArtistSortOption.nameAsc.index,
                ),
                item(
                  l10n.sortAlphabeticalZA,
                  LucideIcons.arrowUpZA,
                  ArtistSortOption.nameDesc.index,
                ),
                item(
                  l10n.sortMostSongs,
                  LucideIcons.arrowDownWideNarrow,
                  ArtistSortOption.songCountDesc.index,
                ),
                item(
                  l10n.sortLeastSongs,
                  LucideIcons.arrowUpNarrowWide,
                  ArtistSortOption.songCountAsc.index,
                ),
                item(
                  l10n.sortRecentlyAdded,
                  LucideIcons.calendarPlus,
                  ArtistSortOption.dateAddedNewest.index,
                ),
                item(
                  l10n.sortOldestAdded,
                  LucideIcons.calendar,
                  ArtistSortOption.dateAddedOldest.index,
                ),
                item(
                  l10n.mostPlayed,
                  LucideIcons.trendingUp,
                  ArtistSortOption.mostPlayed.index,
                ),
                item(
                  l10n.recentlyPlayed,
                  LucideIcons.history,
                  ArtistSortOption.recentlyPlayed.index,
                ),
              ] else if (title == 'Genres') ...[
                item(
                  l10n.sortAlphabeticalAZ,
                  LucideIcons.arrowDownAZ,
                  GenreSortOption.nameAsc.index,
                ),
                item(
                  l10n.sortAlphabeticalZA,
                  LucideIcons.arrowUpZA,
                  GenreSortOption.nameDesc.index,
                ),
                item(
                  l10n.sortMostSongs,
                  LucideIcons.arrowDownWideNarrow,
                  GenreSortOption.songCountDesc.index,
                ),
                item(
                  l10n.sortLeastSongs,
                  LucideIcons.arrowUpNarrowWide,
                  GenreSortOption.songCountAsc.index,
                ),
                item(
                  l10n.sortRecentlyAdded,
                  LucideIcons.calendarPlus,
                  GenreSortOption.dateAddedNewest.index,
                ),
                item(
                  l10n.sortOldestAdded,
                  LucideIcons.calendar,
                  GenreSortOption.dateAddedOldest.index,
                ),
                item(
                  l10n.mostPlayed,
                  LucideIcons.trendingUp,
                  GenreSortOption.mostPlayed.index,
                ),
                item(
                  l10n.recentlyPlayed,
                  LucideIcons.history,
                  GenreSortOption.recentlyPlayed.index,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    String translatedTitle = title;
    switch (title) {
      case 'Albums':
        translatedTitle = l10n.albums;
        break;
      case 'Artists':
        translatedTitle = l10n.artists;
        break;
      case 'Genres':
        translatedTitle = l10n.genres;
        break;
      case 'Folders':
        translatedTitle = l10n.folders;
        break;
      case 'Queue':
        translatedTitle = l10n.queue;
        break;
      case 'History':
        translatedTitle = l10n.history;
        break;
      case 'Favorites':
        translatedTitle = l10n.favorites;
        break;
      case 'Playlists':
        translatedTitle = l10n.playlists;
        break;
      case 'Recently Played':
        translatedTitle = l10n.recentlyPlayed;
        break;
    }

    final songSort = const {
      'Favorites',
      'Recently Played',
      'History',
    }.contains(title);
    final showSortButton =
        songSort ||
        title == 'Albums' ||
        title == 'Artists' ||
        title == 'Genres';

    return _CategoryScaffold(
      title: title,
      label: translatedTitle,
      onSort: showSortButton
          ? () {
              AppHaptics.light();
              songSort
                  ? showSongSortSheet(context, ref, l10n)
                  : _showSortBottomSheet(context, ref, title, l10n);
            }
          : null,
      child: child,
    );
  }
}

/// The in-screen search text of the enclosing [CategoryDetailWrapper];
/// lists below it filter their own items by it.
class CategorySearch extends InheritedNotifier<ValueNotifier<String>> {
  const CategorySearch({
    super.key,
    required ValueNotifier<String> super.notifier,
    required super.child,
  });

  /// The trimmed, lower-cased query; '' when not searching. Rebuilds the
  /// caller when it changes.
  static String of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<CategorySearch>()
          ?.notifier
          ?.value
          .trim()
          .toLowerCase() ??
      '';

  /// Whether [context] is inside a category screen.
  static bool inScope(BuildContext context) =>
      context.getInheritedWidgetOfExactType<CategorySearch>() != null;

  /// Whether any of [fields] contains [query] (already lower-cased).
  static bool matches(String query, Iterable<String?> fields) =>
      query.isEmpty ||
      fields.any((f) => f != null && f.toLowerCase().contains(query));
}

const _heroIcons = <String, IconData>{
  'Favorites': Icons.star_rounded,
  'Playlists': Icons.queue_music_rounded,
  'Albums': Icons.album_rounded,
  'Artists': Icons.mic_rounded,
  'Folders': Icons.folder_rounded,
  'Genres': Icons.apps_rounded,
  'Queue': Icons.format_list_bulleted_rounded,
  'Recently Played': Icons.history_rounded,
  'History': Icons.history_rounded,
};

class _CategoryScaffold extends ConsumerStatefulWidget {
  final String title;
  final String label;
  final VoidCallback? onSort;
  final Widget child;

  const _CategoryScaffold({
    required this.title,
    required this.label,
    required this.onSort,
    required this.child,
  });

  @override
  ConsumerState<_CategoryScaffold> createState() => _CategoryScaffoldState();
}

class _CategoryScaffoldState extends ConsumerState<_CategoryScaffold> {
  final _query = ValueNotifier<String>('');
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _searching = false;

  /// 0 = full hero, 1 = collapsed to the pinned button bar.
  final _collapse = ValueNotifier<double>(0);
  static const _fullHeight = 250.0;
  static const _barHeight = 66.0;
  static const _range = _fullHeight - _barHeight;

  /// Follows the list's scroll position, like Home's header. The hero
  /// shrinks rather than scrolls because each list keeps its own scroll
  /// view (fast scroller, refresh, reorder).
  bool _onScroll(ScrollMetrics m, int depth) {
    if (depth != 0 || m.axis != Axis.vertical) return false;
    final t = _collapse.value;
    // Content length doesn't change as the hero resizes; only collapse when
    // the list stays scrollable by the full range once collapsed, or a
    // short list would flicker between the two states.
    final content = m.maxScrollExtent - m.minScrollExtent + m.viewportDimension;
    final collapsedViewport = m.viewportDimension + _range * (1 - t);
    _collapse.value = content - collapsedViewport >= _range
        ? ((m.pixels - m.minScrollExtent) / _range).clamp(0.0, 1.0)
        : 0.0;
    return false;
  }

  @override
  void dispose() {
    _collapse.dispose();
    _query.dispose();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _setSearching(bool on) {
    AppHaptics.light();
    setState(() => _searching = on);
    if (on) {
      _focus.requestFocus();
    } else {
      _controller.clear();
      _query.value = '';
      _focus.unfocus();
    }
  }

  /// "143 Songs · 438 Min" / "12 Albums" for the hero.
  String _stats(AppLocalizations l10n) {
    String songs(int n, int ms) {
      final min = (ms / 60000).round();
      return min > 0 ? '$n ${l10n.songs} · $min Min' : '$n ${l10n.songs}';
    }

    String paged(PagedQueryKind kind) {
      final p = ref.watch(pagedSongsProvider(kind)).value;
      return p == null ? '' : songs(p.total, p.totalMs);
    }

    switch (widget.title) {
      case 'Favorites':
        return paged(PagedQueryKind.favorites);
      case 'Recently Played':
      case 'History':
        return paged(PagedQueryKind.history);
      case 'Queue':
        final queue = ref.watch(playbackProvider.select((s) => s.queue));
        return songs(
          queue.length,
          queue.fold<int>(0, (t, s) => t + (s.duration ?? 0)),
        );
      case 'Albums':
        final n = ref.watch(libraryProvider.select((s) => s.albums.length));
        return '$n ${l10n.albums}';
      case 'Artists':
        final n = ref.watch(libraryProvider.select((s) => s.artists.length));
        return '$n ${l10n.artists}';
      case 'Playlists':
        final n = ref.watch(libraryProvider.select((s) => s.playlists.length));
        return '$n ${l10n.playlists}';
      case 'Genres':
        return '${ref.watch(songsByGenreProvider).length} ${l10n.genres}';
      case 'Folders':
        return '${ref.watch(songsByFolderProvider).length} ${l10n.folders}';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final surface = Theme.of(context).colorScheme.surface;
    final stats = _stats(l10n);
    final top = MediaQuery.paddingOf(context).top;

    Widget topRow(double t) => SizedBox(
      height: 42,
      child: Row(
        children: [
          RoundIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onTap: () {
              AppHaptics.light();
              ref.read(appNavigationProvider.notifier).goBack();
            },
          ),
          const SizedBox(width: 8),
          if (_searching) ...[
            Expanded(
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(21),
                ),
                alignment: Alignment.centerLeft,
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  onChanged: (v) => _query.value = v,
                  textInputAction: TextInputAction.search,
                  cursorColor: Colors.white,
                  style: AppFonts.jostStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration.collapsed(
                    hintText: '${l10n.search} ${widget.label}',
                    hintStyle: AppFonts.jostStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            RoundIconButton(
              icon: Icons.close_rounded,
              tooltip: l10n.cancel,
              onTap: () => _setSearching(false),
            ),
          ] else ...[
            // The screen name moves up here as the hero collapses.
            Expanded(
              child: Opacity(
                opacity: ((t - 0.6) / 0.4).clamp(0.0, 1.0),
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.jostStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (widget.onSort != null && t > 0.6) ...[
              Opacity(
                opacity: ((t - 0.6) / 0.4).clamp(0.0, 1.0),
                child: RoundIconButton(
                  icon: Icons.filter_list_rounded,
                  tooltip: l10n.sortBy,
                  onTap: widget.onSort!,
                ),
              ),
              const SizedBox(width: 6),
            ],
            RoundIconButton(
              icon: Icons.search_rounded,
              tooltip: l10n.search,
              onTap: () => _setSearching(true),
            ),
            const SizedBox(width: 6),
            RoundIconButton(
              icon: Icons.person_rounded,
              child: headerProfilePhoto(ref, 36),
              onTap: () {
                AppHaptics.light();
                ref
                    .read(appNavigationProvider.notifier)
                    .setItem(NavItem.account);
              },
            ),
          ],
        ],
      ),
    );

    Widget hero(double t) {
      // The big title block and icon fade out over the first part.
      final fade = (1 - t / 0.6).clamp(0.0, 1.0);
      return SizedBox(
        height: top + _fullHeight - _range * t,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Tinted wash that fades into the page colour.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFA48CE8).withValues(alpha: 0.9 - 0.5 * t),
                      const Color(0xFF7A7A7A).withValues(alpha: 0.8 - 0.5 * t),
                      const Color(0xFFE08E8E).withValues(alpha: 0.9 - 0.5 * t),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0, 0.25, 1],
                    colors: [
                      surface.withValues(alpha: 0),
                      surface.withValues(alpha: 0.2),
                      surface,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: top + 20 - 60 * t,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: fade,
                child: Icon(
                  _heroIcons[widget.title] ?? Icons.library_music_rounded,
                  size: 200,
                  color: const Color(0xFF151515),
                  shadows: const [
                    Shadow(color: Colors.black54, blurRadius: 30),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 22,
              right: 20,
              bottom: 8,
              child: Opacity(
                opacity: fade,
                child: IgnorePointer(
                  ignoring: fade == 0,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.yourLibraryEyebrow,
                              style: AppFonts.jostStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                height: 1.05,
                              ),
                            ),
                            Text(
                              widget.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.jostStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                            if (stats.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                stats,
                                style: AppFonts.jostStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (widget.onSort != null)
                        RoundIconButton(
                          icon: Icons.filter_list_rounded,
                          tooltip: l10n.sortBy,
                          onTap: widget.onSort!,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Last, so it stays tappable over the fading title block.
            Positioned(top: top + 12, left: 22, right: 20, child: topRow(t)),
          ],
        ),
      );
    }

    return Scaffold(
      // Not Colors.transparent: this screen is reached via a non-opaque
      // PageRoute (_createPremiumRoute) and that compositing isn't reliable
      // on every device (white flash seen on some), so paint it opaque.
      backgroundColor: surface,
      body: CategorySearch(
        notifier: _query,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValueListenableBuilder<double>(
              valueListenable: _collapse,
              builder: (context, t, _) => hero(t),
            ),
            Expanded(
              child: NotificationListener<ScrollMetricsNotification>(
                onNotification: (n) => _onScroll(n.metrics, n.depth),
                child: NotificationListener<ScrollUpdateNotification>(
                  onNotification: (n) => _onScroll(n.metrics, n.depth),
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
