import 'package:isar_community/isar.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/features/library/domain/artist_names.dart';

/// Keeps the Artist collection in step with the songs' artist tags (one
/// entry per credited artist, see [ArtistNames]) and finds an artist's
/// songs, including ones they share or are featured on.
class ArtistCatalog {
  ArtistCatalog._();

  static ArtistNames? _names;

  /// The splitter for the current library, built on first use and refreshed
  /// by every [sync].
  static Future<ArtistNames> names() async => _names ??= ArtistNames.fromTags(
    await DbService.isar.songs.where().artistProperty().findAll(),
  );

  /// Rebuilds the artist list in its own write transaction.
  static Future<void> sync() => DbService.isar.writeTxn(syncInTxn);

  /// Rebuilds the artist list. Must run inside a write transaction.
  ///
  /// Adds an entry for every credited artist, removes entries no song
  /// credits any more (such as old combined "A / B" entries), and keeps the
  /// pictures of the ones that stay.
  static Future<void> syncInTxn() async {
    final isar = DbService.isar;
    final tags = await isar.songs.where().artistProperty().findAll();
    final titles = await isar.songs.where().titleProperty().findAll();
    final arts = await isar.songs.where().artPathProperty().findAll();
    final names = ArtistNames.fromTags(tags);
    _names = names;

    // Lower-cased name -> (name as first seen, first cover found).
    final wanted = <String, (String, String?)>{};
    for (var i = 0; i < tags.length; i++) {
      for (final name in names.namesFor(tags[i], titles[i])) {
        final key = name.toLowerCase();
        final current = wanted[key];
        if (current == null) {
          wanted[key] = (name, arts[i]);
        } else if (current.$2 == null && arts[i] != null) {
          wanted[key] = (current.$1, arts[i]);
        }
      }
    }

    final existing = await isar.artists.where().findAll();
    final toDelete = <int>[];
    final toPut = <Artist>[];
    for (final artist in existing) {
      final entry = wanted.remove(artist.name.toLowerCase());
      if (entry == null) {
        toDelete.add(artist.id);
      } else if (artist.artPath == null && entry.$2 != null) {
        toPut.add(artist..artPath = entry.$2);
      }
    }
    for (final (name, art) in wanted.values) {
      toPut.add(
        Artist()
          ..name = name
          ..artPath = art,
      );
    }
    if (toDelete.isNotEmpty) await isar.artists.deleteAll(toDelete);
    if (toPut.isNotEmpty) await isar.artists.putAll(toPut);
  }

  /// Every song that credits [artistName]: their own, shared ones, and ones
  /// they are featured on.
  static Future<List<Song>> songsFor(String artistName) async {
    final songs = DbService.isar.songs;
    if (artistName == ArtistNames.unknown) {
      final all = await songs
          .filter()
          .artistIsNull()
          .or()
          .artistIsEmpty()
          .or()
          .artistEqualTo(ArtistNames.unknown, caseSensitive: false)
          .findAll();
      return all.where((s) => ArtistNames.isUnknown(s.artist)).toList();
    }
    final candidates = await songs
        .filter()
        .artistContains(artistName, caseSensitive: false)
        .or()
        .titleContains(artistName, caseSensitive: false)
        .findAll();
    final names = await ArtistCatalog.names();
    return candidates
        .where((s) => names.credits(s.artist, s.title, artistName))
        .toList();
  }

  /// The artists credited on [song], main artists first.
  static Future<List<String>> namesForSong(Song song) async =>
      (await names()).namesFor(song.artist, song.title);

  /// The stored entry for [name], ignoring case.
  static Future<Artist?> find(String name) => DbService.isar.artists
      .filter()
      .nameEqualTo(name, caseSensitive: false)
      .findFirst();
}
