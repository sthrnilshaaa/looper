// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_view.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PlaylistList)
final playlistProvider = PlaylistListProvider._();

final class PlaylistListProvider
    extends $NotifierProvider<PlaylistList, List<Playlist>> {
  PlaylistListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playlistProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playlistListHash();

  @$internal
  @override
  PlaylistList create() => PlaylistList();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Playlist> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Playlist>>(value),
    );
  }
}

String _$playlistListHash() => r'ed38f4c4ed7511221e70dac57657eaee1433158b';

abstract class _$PlaylistList extends $Notifier<List<Playlist>> {
  List<Playlist> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<Playlist>, List<Playlist>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<Playlist>, List<Playlist>>,
              List<Playlist>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(dashboardPlaylists)
final dashboardPlaylistsProvider = DashboardPlaylistsProvider._();

final class DashboardPlaylistsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Playlist>>,
          List<Playlist>,
          Stream<List<Playlist>>
        >
    with $FutureModifier<List<Playlist>>, $StreamProvider<List<Playlist>> {
  DashboardPlaylistsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardPlaylistsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardPlaylistsHash();

  @$internal
  @override
  $StreamProviderElement<List<Playlist>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Playlist>> create(Ref ref) {
    return dashboardPlaylists(ref);
  }
}

String _$dashboardPlaylistsHash() =>
    r'3d698d767bf388411a6bed4876347f467ad63bbc';

@ProviderFor(playlistSongs)
final playlistSongsProvider = PlaylistSongsFamily._();

final class PlaylistSongsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Song>>,
          List<Song>,
          Stream<List<Song>>
        >
    with $FutureModifier<List<Song>>, $StreamProvider<List<Song>> {
  PlaylistSongsProvider._({
    required PlaylistSongsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'playlistSongsProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$playlistSongsHash();

  @override
  String toString() {
    return r'playlistSongsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Song>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Song>> create(Ref ref) {
    final argument = this.argument as int;
    return playlistSongs(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlaylistSongsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$playlistSongsHash() => r'6a52d6d31ff51b2f7c40515ed9a25671e0d48e52';

final class PlaylistSongsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Song>>, int> {
  PlaylistSongsFamily._()
    : super(
        retry: null,
        name: r'playlistSongsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  PlaylistSongsProvider call(int playlistId) =>
      PlaylistSongsProvider._(argument: playlistId, from: this);

  @override
  String toString() => r'playlistSongsProvider';
}
