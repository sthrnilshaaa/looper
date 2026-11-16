part of 'scanner.dart';

extension _ScannerMetadata on LibraryScanner {
  Future<void> _repairMissingDurations(
    List<Song> songs,
    Map<String, Map<String, dynamic>> mediaStoreMap,
  ) async {
    await _mapWithConcurrency<Song, void>(songs, 3, (song) async {
      final item =
          mediaStoreMap[song.path] ?? mediaStoreMap[p.canonicalize(song.path)];
      int? duration = (item?['duration'] as num?)?.toInt();
      if ((duration ?? 0) <= 0) {
        try {
          duration = (await _metadataReader(
            song.path,
          ).timeout(const Duration(seconds: 10))).durationMs?.toInt();
        } catch (_) {}
      }
      if ((duration ?? 0) <= 0 && Platform.isLinux) {
        try {
          duration = (await LinuxTagReader.read(
            song.path,
            timeout: const Duration(seconds: 10),
          ))?.durationMs;
        } catch (_) {}
      }
      if ((duration ?? 0) <= 0) return;
      await DbService.isar.writeTxn(() async {
        // Re-read inside the transaction: enrichment and playback may have
        // updated this row while the file was being probed.
        final current = await DbService.isar.songs.get(song.id);
        if (current == null ||
            current.path != song.path ||
            (current.duration ?? 0) > 0) {
          return;
        }
        current.duration = duration;
        await DbService.isar.songs.put(current);
      });
    });
  }

  Future<({Map<String, Album> albums, Map<String, Artist> artists})>
  _loadNameMaps() async {
    return (
      albums: {
        for (final a in await DbService.isar.albums.where().findAll())
          a.name: a,
      },
      artists: {
        for (final a in await DbService.isar.artists.where().findAll())
          a.name: a,
      },
    );
  }

  /// Runs [fn] over [items] with at most [concurrency] in flight at once,
  /// returning results in the same order as [items].
  Future<List<R>> _mapWithConcurrency<T, R>(
    List<T> items,
    int concurrency,
    Future<R> Function(T item) fn,
  ) async {
    final results = List<R?>.filled(items.length, null);
    var next = 0;

    Future<void> worker() async {
      while (true) {
        final index = next++;
        if (index >= items.length) return;
        results[index] = await fn(items[index]);
      }
    }

    final workerCount = concurrency < items.length ? concurrency : items.length;
    await Future.wait([for (var w = 0; w < workerCount; w++) worker()]);
    return [for (final r in results) r as R];
  }
}

/// ID3v1 genre names (plus the Winamp extensions) by numeric code - some
/// taggers store just the code, e.g. "17" or "(17)" for Rock.
const List<String> _id3v1Genres = [
  'Blues',
  'Classic Rock',
  'Country',
  'Dance',
  'Disco',
  'Funk',
  'Grunge',
  'Hip-Hop',
  'Jazz',
  'Metal',
  'New Age',
  'Oldies',
  'Other',
  'Pop',
  'R&B',
  'Rap',
  'Reggae',
  'Rock',
  'Techno',
  'Industrial',
  'Alternative',
  'Ska',
  'Death Metal',
  'Pranks',
  'Soundtrack',
  'Euro-Techno',
  'Ambient',
  'Trip-Hop',
  'Vocal',
  'Jazz+Funk',
  'Fusion',
  'Trance',
  'Classical',
  'Instrumental',
  'Acid',
  'House',
  'Game',
  'Sound Clip',
  'Gospel',
  'Noise',
  'Alternative Rock',
  'Bass',
  'Soul',
  'Punk',
  'Space',
  'Meditative',
  'Instrumental Pop',
  'Instrumental Rock',
  'Ethnic',
  'Gothic',
  'Darkwave',
  'Techno-Industrial',
  'Electronic',
  'Pop-Folk',
  'Eurodance',
  'Dream',
  'Southern Rock',
  'Comedy',
  'Cult',
  'Gangsta',
  'Top 40',
  'Christian Rap',
  'Pop/Funk',
  'Jungle',
  'Native American',
  'Cabaret',
  'New Wave',
  'Psychedelic',
  'Rave',
  'Showtunes',
  'Trailer',
  'Lo-Fi',
  'Tribal',
  'Acid Punk',
  'Acid Jazz',
  'Polka',
  'Retro',
  'Musical',
  'Rock & Roll',
  'Hard Rock',
  'Folk',
  'Folk-Rock',
  'National Folk',
  'Swing',
  'Fast Fusion',
  'Bebop',
  'Latin',
  'Revival',
  'Celtic',
  'Bluegrass',
  'Avantgarde',
  'Gothic Rock',
  'Progressive Rock',
  'Psychedelic Rock',
  'Symphonic Rock',
  'Slow Rock',
  'Big Band',
  'Chorus',
  'Easy Listening',
  'Acoustic',
  'Humour',
  'Speech',
  'Chanson',
  'Opera',
  'Chamber Music',
  'Sonata',
  'Symphony',
  'Booty Bass',
  'Primus',
  'Porn Groove',
  'Satire',
  'Slow Jam',
  'Club',
  'Tango',
  'Samba',
  'Folklore',
  'Ballad',
  'Power Ballad',
  'Rhythmic Soul',
  'Freestyle',
  'Duet',
  'Punk Rock',
  'Drum Solo',
  'A Cappella',
  'Euro-House',
  'Dance Hall',
  'Goa',
  'Drum & Bass',
  'Club-House',
  'Hardcore Techno',
  'Terror',
  'Indie',
  'BritPop',
  'Afro-Punk',
  'Polsk Punk',
  'Beat',
  'Christian Gangsta Rap',
  'Heavy Metal',
  'Black Metal',
  'Crossover',
  'Contemporary Christian',
  'Christian Rock',
  'Merengue',
  'Salsa',
  'Thrash Metal',
  'Anime',
  'J-Pop',
  'Synthpop',
];
