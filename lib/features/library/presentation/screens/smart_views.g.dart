// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_views.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(favorites)
final favoritesProvider = FavoritesProvider._();

final class FavoritesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Song>>,
          List<Song>,
          Stream<List<Song>>
        >
    with $FutureModifier<List<Song>>, $StreamProvider<List<Song>> {
  FavoritesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoritesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoritesHash();

  @$internal
  @override
  $StreamProviderElement<List<Song>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Song>> create(Ref ref) {
    return favorites(ref);
  }
}

String _$favoritesHash() => r'5d3439fcfd2acbc0381b91bb8f0a1d827915677f';

/// Last 50 played songs for the dedicated "Recently Played" screen. Distinct
/// from [dashboardRecentlyPlayedProvider] (library_notifier.dart, limit 10)
/// which backs the Home dashboard's smaller preview list.

@ProviderFor(recentlyPlayedScreen)
final recentlyPlayedScreenProvider = RecentlyPlayedScreenProvider._();

/// Last 50 played songs for the dedicated "Recently Played" screen. Distinct
/// from [dashboardRecentlyPlayedProvider] (library_notifier.dart, limit 10)
/// which backs the Home dashboard's smaller preview list.

final class RecentlyPlayedScreenProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Song>>,
          List<Song>,
          Stream<List<Song>>
        >
    with $FutureModifier<List<Song>>, $StreamProvider<List<Song>> {
  /// Last 50 played songs for the dedicated "Recently Played" screen. Distinct
  /// from [dashboardRecentlyPlayedProvider] (library_notifier.dart, limit 10)
  /// which backs the Home dashboard's smaller preview list.
  RecentlyPlayedScreenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentlyPlayedScreenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentlyPlayedScreenHash();

  @$internal
  @override
  $StreamProviderElement<List<Song>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Song>> create(Ref ref) {
    return recentlyPlayedScreen(ref);
  }
}

String _$recentlyPlayedScreenHash() =>
    r'e470ff5cd73cda349bbff244bda0c251f657f410';
