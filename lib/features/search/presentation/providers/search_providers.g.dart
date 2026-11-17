// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SearchQuery)
final searchQueryProvider = SearchQueryProvider._();

final class SearchQueryProvider extends $NotifierProvider<SearchQuery, String> {
  SearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchQueryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchQueryHash();

  @$internal
  @override
  SearchQuery create() => SearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$searchQueryHash() => r'f8e1f7273d9bc18e96717bfb4fd4fffd0cd0c5a6';

abstract class _$SearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Search terms the user has actually submitted (keyboard "search" action),
/// not every partial string typed while the live-filter results were
/// updating - most-recent first, deduplicated, capped so the list stays a
/// quick-glance shortlist rather than a full search log.

@ProviderFor(RecentSearches)
final recentSearchesProvider = RecentSearchesProvider._();

/// Search terms the user has actually submitted (keyboard "search" action),
/// not every partial string typed while the live-filter results were
/// updating - most-recent first, deduplicated, capped so the list stays a
/// quick-glance shortlist rather than a full search log.
final class RecentSearchesProvider
    extends $NotifierProvider<RecentSearches, List<String>> {
  /// Search terms the user has actually submitted (keyboard "search" action),
  /// not every partial string typed while the live-filter results were
  /// updating - most-recent first, deduplicated, capped so the list stays a
  /// quick-glance shortlist rather than a full search log.
  RecentSearchesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentSearchesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentSearchesHash();

  @$internal
  @override
  RecentSearches create() => RecentSearches();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$recentSearchesHash() => r'd92420449fdf5e3cc0b3de7b9a9256ac6da1e3ec';

/// Search terms the user has actually submitted (keyboard "search" action),
/// not every partial string typed while the live-filter results were
/// updating - most-recent first, deduplicated, capped so the list stays a
/// quick-glance shortlist rather than a full search log.

abstract class _$RecentSearches extends $Notifier<List<String>> {
  List<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<String>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<String>, List<String>>,
              List<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
