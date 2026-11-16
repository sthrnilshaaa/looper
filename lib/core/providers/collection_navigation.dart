import 'package:isar_community/isar.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/features/library/data/services/artist_catalog.dart';

/// Opening an album or artist as a collection page: the song lookup and the
/// [AppNavigation.showCollection] call the album/artist cards all share.
extension CollectionNavigation on AppNavigation {
  /// Opens [album] with every song tagged with its name. [unknownArtist] is
  /// the subtitle when the album has no artist.
  Future<void> showAlbum(Album album, {required String unknownArtist}) async {
    final songs = await DbService.isar.songs
        .filter()
        .albumEqualTo(album.name)
        .findAll();
    showCollection(
      title: album.name,
      subtitle: album.artist ?? unknownArtist,
      art: album.artPath,
      songs: songs,
      album: album,
    );
  }

  /// Opens [artist] with every song that credits them, including shared
  /// and featured ones. A downloaded artist image is passed as the art, a
  /// remote one as the image URL; with neither, the artist's own art is used.
  Future<void> showArtist(Artist artist, {required String subtitle}) async {
    final songs = await ArtistCatalog.songsFor(artist.name);
    final imageUrl = artist.artistImageUrl;
    final bool isLocalImage = imageUrl != null && !imageUrl.startsWith('http');
    final bool isNetworkImage = imageUrl != null && imageUrl.startsWith('http');
    showCollection(
      title: artist.name,
      subtitle: subtitle,
      art: isLocalImage ? imageUrl : artist.artPath,
      imageUrl: isNetworkImage ? imageUrl : null,
      songs: songs,
      artist: artist,
    );
  }

  /// Opens the artist called [name] (any case). [fallbackArt] is shown when
  /// there is no stored entry for them yet.
  Future<void> showArtistNamed(
    String name, {
    required String subtitle,
    String? fallbackArt,
  }) async {
    final artist = await ArtistCatalog.find(name);
    if (artist != null) return showArtist(artist, subtitle: subtitle);
    showCollection(
      title: name,
      subtitle: subtitle,
      art: fallbackArt,
      songs: await ArtistCatalog.songsFor(name),
    );
  }
}
