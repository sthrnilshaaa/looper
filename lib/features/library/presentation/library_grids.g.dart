// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_grids.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(albums)
final albumsProvider = AlbumsProvider._();

final class AlbumsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Album>>,
          List<Album>,
          Stream<List<Album>>
        >
    with $FutureModifier<List<Album>>, $StreamProvider<List<Album>> {
  AlbumsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'albumsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$albumsHash();

  @$internal
  @override
  $StreamProviderElement<List<Album>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Album>> create(Ref ref) {
    return albums(ref);
  }
}

String _$albumsHash() => r'bf069d55ad6c116751857bc1600775561f03e3e8';

@ProviderFor(artists)
final artistsProvider = ArtistsProvider._();

final class ArtistsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Artist>>,
          List<Artist>,
          Stream<List<Artist>>
        >
    with $FutureModifier<List<Artist>>, $StreamProvider<List<Artist>> {
  ArtistsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'artistsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$artistsHash();

  @$internal
  @override
  $StreamProviderElement<List<Artist>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Artist>> create(Ref ref) {
    return artists(ref);
  }
}

String _$artistsHash() => r'ae6d2ee6e5b7d850acdb0dff78597f2251373692';

/// Reactively watches every song tagged with [albumName], so a
/// CollectionDetailView opened for an album updates live when that album
/// (or one of its songs) is edited, instead of showing a stale snapshot.

@ProviderFor(songsForAlbum)
final songsForAlbumProvider = SongsForAlbumFamily._();

/// Reactively watches every song tagged with [albumName], so a
/// CollectionDetailView opened for an album updates live when that album
/// (or one of its songs) is edited, instead of showing a stale snapshot.

final class SongsForAlbumProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Song>>,
          List<Song>,
          Stream<List<Song>>
        >
    with $FutureModifier<List<Song>>, $StreamProvider<List<Song>> {
  /// Reactively watches every song tagged with [albumName], so a
  /// CollectionDetailView opened for an album updates live when that album
  /// (or one of its songs) is edited, instead of showing a stale snapshot.
  SongsForAlbumProvider._({
    required SongsForAlbumFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'songsForAlbumProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$songsForAlbumHash();

  @override
  String toString() {
    return r'songsForAlbumProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Song>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Song>> create(Ref ref) {
    final argument = this.argument as String;
    return songsForAlbum(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SongsForAlbumProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$songsForAlbumHash() => r'9c2e7b4c39e33c1865fac058088ba021b72f11d9';

/// Reactively watches every song tagged with [albumName], so a
/// CollectionDetailView opened for an album updates live when that album
/// (or one of its songs) is edited, instead of showing a stale snapshot.

final class SongsForAlbumFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Song>>, String> {
  SongsForAlbumFamily._()
    : super(
        retry: null,
        name: r'songsForAlbumProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Reactively watches every song tagged with [albumName], so a
  /// CollectionDetailView opened for an album updates live when that album
  /// (or one of its songs) is edited, instead of showing a stale snapshot.

  SongsForAlbumProvider call(String albumName) =>
      SongsForAlbumProvider._(argument: albumName, from: this);

  @override
  String toString() => r'songsForAlbumProvider';
}
