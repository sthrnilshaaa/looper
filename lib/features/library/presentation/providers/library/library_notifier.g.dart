// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Library)
final libraryProvider = LibraryProvider._();

final class LibraryProvider extends $NotifierProvider<Library, LibraryState> {
  LibraryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryHash();

  @$internal
  @override
  Library create() => Library();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LibraryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LibraryState>(value),
    );
  }
}

String _$libraryHash() => r'5a718aa2965c108d27123035adad9a70e489fd3e';

abstract class _$Library extends $Notifier<LibraryState> {
  LibraryState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<LibraryState, LibraryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LibraryState, LibraryState>,
              LibraryState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Last 10 played songs for the Home dashboard. Distinct from
/// [recentlyPlayedScreenProvider] (smart_views.dart, limit 50) which backs the
/// dedicated "Recently Played" screen - keep these two names distinct rather
/// than both being `recentlyPlayedProvider`, since any file that ever imports
/// both `library_notifier.dart` and `smart_views.dart` unprefixed would hit an
/// ambiguous-import error the moment it referenced the bare name.

@ProviderFor(dashboardRecentlyPlayed)
final dashboardRecentlyPlayedProvider = DashboardRecentlyPlayedProvider._();

/// Last 10 played songs for the Home dashboard. Distinct from
/// [recentlyPlayedScreenProvider] (smart_views.dart, limit 50) which backs the
/// dedicated "Recently Played" screen - keep these two names distinct rather
/// than both being `recentlyPlayedProvider`, since any file that ever imports
/// both `library_notifier.dart` and `smart_views.dart` unprefixed would hit an
/// ambiguous-import error the moment it referenced the bare name.

final class DashboardRecentlyPlayedProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Song>>,
          List<Song>,
          Stream<List<Song>>
        >
    with $FutureModifier<List<Song>>, $StreamProvider<List<Song>> {
  /// Last 10 played songs for the Home dashboard. Distinct from
  /// [recentlyPlayedScreenProvider] (smart_views.dart, limit 50) which backs the
  /// dedicated "Recently Played" screen - keep these two names distinct rather
  /// than both being `recentlyPlayedProvider`, since any file that ever imports
  /// both `library_notifier.dart` and `smart_views.dart` unprefixed would hit an
  /// ambiguous-import error the moment it referenced the bare name.
  DashboardRecentlyPlayedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardRecentlyPlayedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardRecentlyPlayedHash();

  @$internal
  @override
  $StreamProviderElement<List<Song>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Song>> create(Ref ref) {
    return dashboardRecentlyPlayed(ref);
  }
}

String _$dashboardRecentlyPlayedHash() =>
    r'f915fc3cbd22102643e80fe61c11b47508876db0';

@ProviderFor(topSongs)
final topSongsProvider = TopSongsProvider._();

final class TopSongsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Song>>,
          List<Song>,
          Stream<List<Song>>
        >
    with $FutureModifier<List<Song>>, $StreamProvider<List<Song>> {
  TopSongsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'topSongsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$topSongsHash();

  @$internal
  @override
  $StreamProviderElement<List<Song>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Song>> create(Ref ref) {
    return topSongs(ref);
  }
}

String _$topSongsHash() => r'd6cefbb86aa6f30a4b1b74e9648ffe7932971eaf';

/// Home tab's "Quick Picks" - same comparator (play count, most first) and
/// same 18-item cap as before.

@ProviderFor(homeQuickPicks)
final homeQuickPicksProvider = HomeQuickPicksProvider._();

/// Home tab's "Quick Picks" - same comparator (play count, most first) and
/// same 18-item cap as before.

final class HomeQuickPicksProvider
    extends $FunctionalProvider<List<Song>, List<Song>, List<Song>>
    with $Provider<List<Song>> {
  /// Home tab's "Quick Picks" - same comparator (play count, most first) and
  /// same 18-item cap as before.
  HomeQuickPicksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeQuickPicksProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeQuickPicksHash();

  @$internal
  @override
  $ProviderElement<List<Song>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Song> create(Ref ref) {
    return homeQuickPicks(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Song> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Song>>(value),
    );
  }
}

String _$homeQuickPicksHash() => r'0a2bbd82db765af89f570403d78bceaf8f804dc3';

/// Home tab's "Recently Added" section - same comparator (date added,
/// newest first) as before. Kept as the full sorted list, not just the
/// visible prefix, since tapping into this section queues it in full.

@ProviderFor(homeRecentlyAdded)
final homeRecentlyAddedProvider = HomeRecentlyAddedProvider._();

/// Home tab's "Recently Added" section - same comparator (date added,
/// newest first) as before. Kept as the full sorted list, not just the
/// visible prefix, since tapping into this section queues it in full.

final class HomeRecentlyAddedProvider
    extends $FunctionalProvider<List<Song>, List<Song>, List<Song>>
    with $Provider<List<Song>> {
  /// Home tab's "Recently Added" section - same comparator (date added,
  /// newest first) as before. Kept as the full sorted list, not just the
  /// visible prefix, since tapping into this section queues it in full.
  HomeRecentlyAddedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeRecentlyAddedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeRecentlyAddedHash();

  @$internal
  @override
  $ProviderElement<List<Song>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Song> create(Ref ref) {
    return homeRecentlyAdded(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Song> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Song>>(value),
    );
  }
}

String _$homeRecentlyAddedHash() => r'662271fb48d5b3833f5998bd5aaeb6fa73eca03b';

/// Every song grouped by its raw genre value (null for songs missing one).
/// The "Unknown" label itself is applied by the caller instead of here,
/// since it's localized and this provider has no BuildContext - see
/// GenresGridView.

@ProviderFor(songsByGenre)
final songsByGenreProvider = SongsByGenreProvider._();

/// Every song grouped by its raw genre value (null for songs missing one).
/// The "Unknown" label itself is applied by the caller instead of here,
/// since it's localized and this provider has no BuildContext - see
/// GenresGridView.

final class SongsByGenreProvider
    extends
        $FunctionalProvider<
          Map<String?, List<Song>>,
          Map<String?, List<Song>>,
          Map<String?, List<Song>>
        >
    with $Provider<Map<String?, List<Song>>> {
  /// Every song grouped by its raw genre value (null for songs missing one).
  /// The "Unknown" label itself is applied by the caller instead of here,
  /// since it's localized and this provider has no BuildContext - see
  /// GenresGridView.
  SongsByGenreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'songsByGenreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$songsByGenreHash();

  @$internal
  @override
  $ProviderElement<Map<String?, List<Song>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String?, List<Song>> create(Ref ref) {
    return songsByGenre(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String?, List<Song>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String?, List<Song>>>(value),
    );
  }
}

String _$songsByGenreHash() => r'198003eaf3ea446874fc3177151f34a1b1cbaa1e';

/// Every song grouped by its parent folder path.

@ProviderFor(songsByFolder)
final songsByFolderProvider = SongsByFolderProvider._();

/// Every song grouped by its parent folder path.

final class SongsByFolderProvider
    extends
        $FunctionalProvider<
          Map<String, List<Song>>,
          Map<String, List<Song>>,
          Map<String, List<Song>>
        >
    with $Provider<Map<String, List<Song>>> {
  /// Every song grouped by its parent folder path.
  SongsByFolderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'songsByFolderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$songsByFolderHash();

  @$internal
  @override
  $ProviderElement<Map<String, List<Song>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, List<Song>> create(Ref ref) {
    return songsByFolder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, List<Song>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, List<Song>>>(value),
    );
  }
}

String _$songsByFolderHash() => r'42b359671470401916b31b9291b4f1a92e603c9d';

/// How many songs are still awaiting Pass 2 (tag/art/lyrics) enrichment -
/// derived from the already-reactive songs list rather than a separate
/// Isar watch, so it updates for free as LibraryScanner.enrichPendingSongs
/// writes each batch.

@ProviderFor(songsNeedingEnrichment)
final songsNeedingEnrichmentProvider = SongsNeedingEnrichmentProvider._();

/// How many songs are still awaiting Pass 2 (tag/art/lyrics) enrichment -
/// derived from the already-reactive songs list rather than a separate
/// Isar watch, so it updates for free as LibraryScanner.enrichPendingSongs
/// writes each batch.

final class SongsNeedingEnrichmentProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// How many songs are still awaiting Pass 2 (tag/art/lyrics) enrichment -
  /// derived from the already-reactive songs list rather than a separate
  /// Isar watch, so it updates for free as LibraryScanner.enrichPendingSongs
  /// writes each batch.
  SongsNeedingEnrichmentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'songsNeedingEnrichmentProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$songsNeedingEnrichmentHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return songsNeedingEnrichment(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$songsNeedingEnrichmentHash() =>
    r'fd62785647f9aebbf607716e291432384c7b1639';

/// Per-folder scan exclusions, e.g. a voice-memos subfolder living inside an
/// otherwise-wanted Music folder. Kept in a local JSON file (see
/// LocalJsonStore) rather than the Isar `AppSettings` schema, and read
/// directly by LibraryScanner using the same store key - see
/// isUnderExcludedFolder in scanner.dart.

@ProviderFor(ExcludedFolders)
final excludedFoldersProvider = ExcludedFoldersProvider._();

/// Per-folder scan exclusions, e.g. a voice-memos subfolder living inside an
/// otherwise-wanted Music folder. Kept in a local JSON file (see
/// LocalJsonStore) rather than the Isar `AppSettings` schema, and read
/// directly by LibraryScanner using the same store key - see
/// isUnderExcludedFolder in scanner.dart.
final class ExcludedFoldersProvider
    extends $NotifierProvider<ExcludedFolders, List<String>> {
  /// Per-folder scan exclusions, e.g. a voice-memos subfolder living inside an
  /// otherwise-wanted Music folder. Kept in a local JSON file (see
  /// LocalJsonStore) rather than the Isar `AppSettings` schema, and read
  /// directly by LibraryScanner using the same store key - see
  /// isUnderExcludedFolder in scanner.dart.
  ExcludedFoldersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'excludedFoldersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$excludedFoldersHash();

  @$internal
  @override
  ExcludedFolders create() => ExcludedFolders();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$excludedFoldersHash() => r'c2c5d1f9fdde0e7ef3df9a6a84130a8b762dcb5e';

/// Per-folder scan exclusions, e.g. a voice-memos subfolder living inside an
/// otherwise-wanted Music folder. Kept in a local JSON file (see
/// LocalJsonStore) rather than the Isar `AppSettings` schema, and read
/// directly by LibraryScanner using the same store key - see
/// isUnderExcludedFolder in scanner.dart.

abstract class _$ExcludedFolders extends $Notifier<List<String>> {
  List<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<String>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<String>, List<String>>,
              List<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
