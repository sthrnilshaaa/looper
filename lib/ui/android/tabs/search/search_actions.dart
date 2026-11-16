part of 'android_search_tab.dart';

/// Every song [artistName] is credited on: their own, shared ones, and ones
/// where they are a featured guest on someone else's track.
Future<List<Song>> _songsCrediting(String artistName) async {
  final credited = await ArtistCatalog.songsFor(artistName);
  if (credited.isNotEmpty) return credited;
  // A tag the credit splitter can't read still gets the exact-tag match,
  // rather than an empty page.
  return DbService.isar.songs.filter().artistEqualTo(artistName).findAll();
}

Future<void> _openArtist(
  WidgetRef ref,
  AppLocalizations l10n,
  Artist artist,
) async {
  final navigation = ref.read(appNavigationProvider.notifier);
  final songs = await _songsCrediting(artist.name);
  navigation.showCollection(
    title: artist.name,
    subtitle: l10n.artist,
    songs: songs,
    art: artist.artPath,
  );
}

Future<void> _openAlbum(WidgetRef ref, AppLocalizations l10n, Album album) =>
    ref
        .read(appNavigationProvider.notifier)
        .showAlbum(album, unknownArtist: l10n.unknownArtist);

Future<void> _openPlaylist(
  WidgetRef ref,
  AppLocalizations l10n,
  Playlist playlist,
) async {
  final navigation = ref.read(appNavigationProvider.notifier);
  final songs = await DbService.isar.songs
      .filter()
      .anyOf(playlist.songPaths, (q, path) => q.pathEqualTo(path))
      .findAll();
  // Keep the playlist's own order, as the Playlists screen does.
  final songMap = {for (final s in songs) s.path: s};
  navigation.showCollection(
    title: playlist.name,
    subtitle: l10n.playlist,
    songs: playlist.songPaths
        .map((path) => songMap[path])
        .whereType<Song>()
        .toList(),
    playlist: playlist,
  );
}

Future<void> _openGenre(
  WidgetRef ref,
  AppLocalizations l10n,
  String genre,
) async {
  final navigation = ref.read(appNavigationProvider.notifier);
  final songs = await DbService.isar.songs
      .filter()
      .genreEqualTo(genre, caseSensitive: false)
      .findAll();
  if (songs.isEmpty) return;
  final withArt = songs.firstWhere(
    (s) => s.artPath != null,
    orElse: () => songs.first,
  );
  navigation.showCollection(
    title: genre,
    subtitle: l10n.genre,
    art: withArt.artPath,
    songs: songs,
  );
}

/// Asks which playlist [songs] should go to - an existing one or a new one,
/// whose name starts out as [suggestedName] - and adds them. Returns the
/// playlist's name, or null if the user backed out.
