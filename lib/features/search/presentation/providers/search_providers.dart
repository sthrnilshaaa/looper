import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:looper_player/core/services/storage/local_json_store.dart';

part 'search_providers.g.dart';

@Riverpod(keepAlive: true)
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void set(String value) => state = value;
}

/// Search terms the user has actually submitted (keyboard "search" action),
/// not every partial string typed while the live-filter results were
/// updating - most-recent first, deduplicated, capped so the list stays a
/// quick-glance shortlist rather than a full search log.
@Riverpod(keepAlive: true)
class RecentSearches extends _$RecentSearches {
  static const _storeKey = 'recent_searches';
  static const _maxEntries = 10;

  @override
  List<String> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final raw = await LocalJsonStore.read(_storeKey);
    if (raw is! List) return;
    state = raw.whereType<String>().toList();
  }

  Future<void> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    state = [
      trimmed,
      ...state.where((q) => q.toLowerCase() != trimmed.toLowerCase()),
    ].take(_maxEntries).toList();
    await LocalJsonStore.write(_storeKey, state);
  }

  Future<void> remove(String query) async {
    state = state.where((q) => q != query).toList();
    await LocalJsonStore.write(_storeKey, state);
  }

  Future<void> clear() async {
    state = [];
    await LocalJsonStore.write(_storeKey, state);
  }
}
