import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:looper_player/core/services/storage/db_service.dart';

enum PagedQueryKind { favorites, history }

class PagedSongs {
  final List<Song> items;
  final int total;

  /// Favorites / History show one page at a time.
  final int page;

  const PagedSongs({required this.items, required this.total, this.page = 0});

  int get pageCount => (total / PagedSongsNotifier.pageSize).ceil();
}

final pagedSongsProvider =
    AsyncNotifierProvider.family<
      PagedSongsNotifier,
      PagedSongs,
      PagedQueryKind
    >(PagedSongsNotifier.new);

class PagedSongsNotifier extends AsyncNotifier<PagedSongs> {
  PagedSongsNotifier(this.kind);
  final PagedQueryKind kind;

  static const int pageSize = 100;
  StreamSubscription? _sub;
  Timer? _debounce;
  bool _disposed = false;
  int _page = 0;

  QueryBuilder<Song, Song, QAfterFilterCondition> _filterQuery({
    String? search,
  }) {
    var q = switch (kind) {
      PagedQueryKind.favorites =>
        DbService.isar.songs.filter().isFavoriteEqualTo(true),
      PagedQueryKind.history =>
        DbService.isar.songs.filter().lastPlayedIsNotNull(),
    };
    if (search != null && search.trim().isNotEmpty) {
      final term = search.trim();
      q = q.and().group(
        (g) => g
            .titleContains(term, caseSensitive: false)
            .or()
            .artistContains(term, caseSensitive: false),
      );
    }
    return q;
  }

  QueryBuilder<Song, Song, QAfterSortBy> _sortedQuery({String? search}) {
    final filtered = _filterQuery(search: search);
    return switch (kind) {
      PagedQueryKind.favorites => filtered.sortByTitle(),
      PagedQueryKind.history => filtered.sortByLastPlayedDesc(),
    };
  }

  /// The current page.
  Future<PagedSongs> _load() async {
    final total = await _filterQuery().count();
    _page = _page.clamp(0, math.max(0, (total - 1) ~/ pageSize));
    final items = await _sortedQuery()
        .offset(_page * pageSize)
        .limit(pageSize)
        .findAll();
    return PagedSongs(items: items, total: total, page: _page);
  }

  @override
  Future<PagedSongs> build() async {
    ref.onDispose(() {
      _disposed = true;
      _sub?.cancel();
      _debounce?.cancel();
    });

    _sub ??= DbService.isar.songs.watchLazy().listen((_) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        if (!_disposed) {
          unawaited(refresh());
        }
      });
    });
    return _load();
  }

  Future<void> refresh() async {
    final page = _page;
    final next = await _load();
    // A newer page change already replaced this result.
    if (_disposed || page != _page) return;
    state = AsyncData(next);
  }

  Future<void> goToPage(int page) async {
    _page = page;
    await refresh();
  }

  /// Every song of the current filter, for the play queue.
  Future<List<Song>> fetchAll({String? search}) =>
      _sortedQuery(search: search).findAll();
}

/// Backwards compatibility provider for [favorites].
final favoritesProvider = Provider.autoDispose<AsyncValue<List<Song>>>((ref) {
  return ref
      .watch(pagedSongsProvider(PagedQueryKind.favorites))
      .whenData((p) => p.items);
});

/// Backwards compatibility provider for [recentlyPlayedScreen].
final recentlyPlayedScreenProvider =
    Provider.autoDispose<AsyncValue<List<Song>>>((ref) {
      return ref
          .watch(pagedSongsProvider(PagedQueryKind.history))
          .whenData((p) => p.items);
    });
