// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_categories_views.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Memoized per sort option so switching screens/rebuilding this view
/// doesn't tear down and recreate the underlying Isar watch (which briefly
/// re-shows the loading state) - the previous inline `switch` in
/// AlbumsGridView.build() opened a brand-new Stream on every rebuild.

@ProviderFor(albumsSorted)
final albumsSortedProvider = AlbumsSortedFamily._();

/// Memoized per sort option so switching screens/rebuilding this view
/// doesn't tear down and recreate the underlying Isar watch (which briefly
/// re-shows the loading state) - the previous inline `switch` in
/// AlbumsGridView.build() opened a brand-new Stream on every rebuild.

final class AlbumsSortedProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Album>>,
          List<Album>,
          Stream<List<Album>>
        >
    with $FutureModifier<List<Album>>, $StreamProvider<List<Album>> {
  /// Memoized per sort option so switching screens/rebuilding this view
  /// doesn't tear down and recreate the underlying Isar watch (which briefly
  /// re-shows the loading state) - the previous inline `switch` in
  /// AlbumsGridView.build() opened a brand-new Stream on every rebuild.
  AlbumsSortedProvider._({
    required AlbumsSortedFamily super.from,
    required AlbumSortOption super.argument,
  }) : super(
         retry: null,
         name: r'albumsSortedProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$albumsSortedHash();

  @override
  String toString() {
    return r'albumsSortedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Album>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Album>> create(Ref ref) {
    final argument = this.argument as AlbumSortOption;
    return albumsSorted(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AlbumsSortedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$albumsSortedHash() => r'3ed974175a0ac4b5ba137178aca9408b906d93a7';

/// Memoized per sort option so switching screens/rebuilding this view
/// doesn't tear down and recreate the underlying Isar watch (which briefly
/// re-shows the loading state) - the previous inline `switch` in
/// AlbumsGridView.build() opened a brand-new Stream on every rebuild.

final class AlbumsSortedFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Album>>, AlbumSortOption> {
  AlbumsSortedFamily._()
    : super(
        retry: null,
        name: r'albumsSortedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Memoized per sort option so switching screens/rebuilding this view
  /// doesn't tear down and recreate the underlying Isar watch (which briefly
  /// re-shows the loading state) - the previous inline `switch` in
  /// AlbumsGridView.build() opened a brand-new Stream on every rebuild.

  AlbumsSortedProvider call(AlbumSortOption sortOption) =>
      AlbumsSortedProvider._(argument: sortOption, from: this);

  @override
  String toString() => r'albumsSortedProvider';
}

/// Memoized on the library's artist list + sort option, instead of
/// re-sorting the full artist list on every rebuild of ArtistsGridView.

@ProviderFor(artistsSorted)
final artistsSortedProvider = ArtistsSortedFamily._();

/// Memoized on the library's artist list + sort option, instead of
/// re-sorting the full artist list on every rebuild of ArtistsGridView.

final class ArtistsSortedProvider
    extends $FunctionalProvider<List<Artist>, List<Artist>, List<Artist>>
    with $Provider<List<Artist>> {
  /// Memoized on the library's artist list + sort option, instead of
  /// re-sorting the full artist list on every rebuild of ArtistsGridView.
  ArtistsSortedProvider._({
    required ArtistsSortedFamily super.from,
    required ArtistSortOption super.argument,
  }) : super(
         retry: null,
         name: r'artistsSortedProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$artistsSortedHash();

  @override
  String toString() {
    return r'artistsSortedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<Artist>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Artist> create(Ref ref) {
    final argument = this.argument as ArtistSortOption;
    return artistsSorted(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Artist> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Artist>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ArtistsSortedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$artistsSortedHash() => r'56e42a83502dfbd65a3959c4c5af3848f0bb1619';

/// Memoized on the library's artist list + sort option, instead of
/// re-sorting the full artist list on every rebuild of ArtistsGridView.

final class ArtistsSortedFamily extends $Family
    with $FunctionalFamilyOverride<List<Artist>, ArtistSortOption> {
  ArtistsSortedFamily._()
    : super(
        retry: null,
        name: r'artistsSortedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Memoized on the library's artist list + sort option, instead of
  /// re-sorting the full artist list on every rebuild of ArtistsGridView.

  ArtistsSortedProvider call(ArtistSortOption sortOption) =>
      ArtistsSortedProvider._(argument: sortOption, from: this);

  @override
  String toString() => r'artistsSortedProvider';
}
