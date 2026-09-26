import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:looper_player/core/services/storage/db_service.dart';
import 'lyrics_cache.dart';
import 'metadata_service.dart';
import 'lyrics_service.dart';

class LyricsFetcher {
  static final LyricsService _service = LyricsService();

  static final List<String> allProviders = [
    'LRCLIB',
    'GENIUS',
    'MUSIXMATCH',
    'AZLYRICS',
    'LYRICSMINT',
    'LYRICFIND',
  ];

  static Future<String?> fetchLyrics(Song song) async {
    String? lrc;
    final artist = (song.artist ?? 'Unknown Artist').trim();
    final title = song.title.trim();

    // Whether a previous run already cached "nothing found anywhere" for
    // this song. That's still worth honoring for the online step below (the
    // slow, rate-limited one) but NOT for skipping the embedded-metadata/
    // sidecar-file checks (steps 3-4): those are fast, local, no-network
    // re-checks, and a stale not-found here would otherwise be permanent -
    // e.g. Android's embedded-lyrics reader was added after some libraries
    // were already scanned and cached as not-found under the old code path.
    bool cachedAsNotFound = false;

    // 1. Try Song Database (Previously cached) - INSTANT, ZERO DELAY
    if (song.lyrics != null && song.lyrics!.isNotEmpty) {
      if (song.lyrics == '[source:not_found]') {
        cachedAsNotFound = true;
      } else if (!song.lyrics!.startsWith('[source:')) {
        // Self-heal legacy data: scanner.dart used to write embedded lyrics
        // into song.lyrics without a [source:embedded] tag (fixed above,
        // but that fix only applies going forward - a song scanned before
        // it doesn't get retroactively rescanned just because the app
        // updated). scanner.dart is the only place that ever wrote lyrics
        // here untagged, so any untagged value found now is exactly that:
        // real embedded lyrics with a missing tag, which otherwise shows
        // the lyrics correctly but permanently displays "No Lyrics Source"
        // for this song. Tag and persist it once, here, rather than
        // requiring a full library reset just to fix the label.
        final tagged = '[source:embedded]\n${song.lyrics}';
        await DbService.isar.writeTxn(() async {
          final dbSong = await DbService.isar.songs.get(song.id);
          if (dbSong != null) {
            dbSong.lyrics = tagged;
            await DbService.isar.songs.put(dbSong);
          }
        });
        return tagged;
      } else {
        return song.lyrics;
      }
    }

    // 2. Try Local Cache
    if (!cachedAsNotFound) {
      lrc = await LyricsCache.get(artist, title);
      if (lrc != null && lrc.isNotEmpty) {
        if (lrc == '[source:not_found]') {
          cachedAsNotFound = true;
        } else {
          // Save to database for faster next-time loading
          await DbService.isar.writeTxn(() async {
            final dbSong = await DbService.isar.songs.get(song.id);
            if (dbSong != null) {
              dbSong.lyrics = lrc;
              await DbService.isar.songs.put(dbSong);
            }
          });
          return lrc;
        }
      }
    }

    // 3. Try Embedded Metadata (Live check inside FLAC/MP3 etc.)
    lrc = await MetadataService.getEmbeddedLyrics(song.path);
    if (lrc != null && lrc.isNotEmpty) {
      final taggedLrc = '[source:embedded]\n$lrc';
      // Save to DB for instant future loading
      await DbService.isar.writeTxn(() async {
        final dbSong = await DbService.isar.songs.get(song.id);
        if (dbSong != null) {
          dbSong.lyrics = taggedLrc;
          await DbService.isar.songs.put(dbSong);
        }
      });
      return taggedLrc;
    }

    // 4. Try External Sidecar Files (LRC/TXT next to song file)
    final songFile = File(song.path);
    final songDir = songFile.parent.path;
    final songBaseName = p.basenameWithoutExtension(song.path);

    final searchPaths = [
      p.join(songDir, '$songBaseName.lrc'),
      p.join(songDir, '$songBaseName.txt'),
      p.join(songDir, 'lyrics', '$songBaseName.lrc'),
      p.join(songDir, 'lyrics', '$songBaseName.txt'),
      p.join(songDir, 'Lyrics', '$songBaseName.lrc'),
    ];

    for (final path in searchPaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          final content = await file.readAsString();
          if (content.isNotEmpty) {
            lrc = '[source:local]\n$content';
            break;
          }
        }
      } catch (_) {}
    }
    if (lrc != null) {
      // Save to DB for instant future loading
      await DbService.isar.writeTxn(() async {
        final dbSong = await DbService.isar.songs.get(song.id);
        if (dbSong != null) {
          dbSong.lyrics = lrc;
          await DbService.isar.songs.put(dbSong);
        }
      });
      return lrc;
    }

    // 5. Online service search - LAST FALLBACK. Skipped if a previous run
    // already checked online and found nothing (cachedAsNotFound): unlike
    // steps 3-4 this one is slow and rate-limited, so it's worth trusting
    // that cache rather than re-hitting it on every fetch.
    if (cachedAsNotFound) {
      return null;
    }

    final settings = await DbService.isar.appSettings.get(0);
    if (settings != null && !settings.enableInternet) {
      return lrc;
    }

    try {
      final primaryProvider = settings?.lyricsProvider ?? 'LRCLIB';
      final autoFallback = settings?.autoLyricsFallback ?? true;

      final providersToTry = <String>[primaryProvider];
      if (autoFallback) {
        for (final p in allProviders) {
          if (!providersToTry.contains(p)) {
            providersToTry.add(p);
          }
        }
      }

      for (final provider in providersToTry) {
        final response = await _service.getLyrics(
          trackName: title,
          artistName: artist,
          albumName: (song.album ?? '').trim(),
          durationSeconds: (song.duration ?? 0) ~/ 1000,
          provider: provider,
        );
        final raw = response?.syncedLyrics ?? response?.plainLyrics;

        if (raw != null && raw.isNotEmpty) {
          lrc = '[source:${provider.toLowerCase()}]\n$raw';
          break;
        }
      }

      if (lrc == null || lrc.isEmpty) {
        lrc = '[source:not_found]';
      }

      // Save to cache and DB
      await LyricsCache.save(artist, title, lrc);
      await DbService.isar.writeTxn(() async {
        final dbSong = await DbService.isar.songs.get(song.id);
        if (dbSong != null) {
          dbSong.lyrics = lrc;
          await DbService.isar.songs.put(dbSong);
        }
      });

      if (lrc == '[source:not_found]') return null;
    } catch (_) {
      // Ignore online error silently
    }

    return lrc;
  }
}
