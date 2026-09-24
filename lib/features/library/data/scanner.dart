import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../core/db_service.dart';
import '../domain/models/models.dart';
import 'package:isar_community/isar.dart';
import '../../playback/data/metadata_service.dart';
import 'artwork_downloader_service.dart';
import 'saf_folder_service.dart';
import '../../../core/local_json_store.dart';

/// True if [filePath] falls inside one of [excludedFolders] - the user's
/// per-folder scan exclusions (e.g. a voice-memos subfolder living inside an
/// otherwise-wanted Music folder), which is a separate, finer-grained knob
/// than the blanket "include system & messaging audio" setting.
bool isUnderExcludedFolder(String filePath, List<String> excludedFolders) {
  for (final folder in excludedFolders) {
    if (folder.isEmpty) continue;
    final normalized = folder.endsWith('/') ? folder : '$folder/';
    if (filePath == folder || filePath.startsWith(normalized)) return true;
  }
  return false;
}

class ScanResult {
  final int songsCount;
  final Set<String> musicFolders;

  ScanResult({required this.songsCount, required this.musicFolders});
}

class ArtistParser {
  /// Splits strings like "Artist A feat. Artist B", "Artist A / Artist B", "Artist A; Artist B", "Artist A & Artist B"
  static List<String> parse(String? rawArtist) {
    if (rawArtist == null ||
        rawArtist.trim().isEmpty ||
        rawArtist.trim().toLowerCase() == 'unknown artist') {
      return ['Unknown Artist'];
    }

    final regex = RegExp(
      r'\s*(?:;|\/|\\|&|feat\.|ft\.|,|AND)\s*',
      caseSensitive: false,
    );
    final parts = rawArtist
        .split(regex)
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList();

    return parts.isNotEmpty ? parts : [rawArtist.trim()];
  }

  static String primaryArtist(String? rawArtist) {
    final parsed = parse(rawArtist);
    return parsed.first;
  }
}

@visibleForTesting
bool isIgnoredScanPath(
  String targetPath, {
  bool includeSystemAndMessagingAudio = false,
}) {
  final lower = targetPath.toLowerCase();
  final baseName = p.basename(lower);
  final segments = p
      .split(lower)
      .where((segment) => segment.isNotEmpty && segment != p.separator)
      .toList();

  if (baseName.startsWith('.') && baseName != '.') return true;
  if (lower.contains('/android/data/') ||
      lower.endsWith('/android/data') ||
      lower.contains('/android/obb/') ||
      lower.endsWith('/android/obb') ||
      segments.contains('.cache') ||
      baseName == '.nomedia') {
    return true;
  }

  if (includeSystemAndMessagingAudio) return false;

  // Ringtones, Notifications, Alarms
  if (segments.any(
        const {
          'ringtones',
          'ringtone',
          'notifications',
          'notification',
          'alarms',
          'alarm',
        }.contains,
      ) ||
      lower.contains('/system/media/audio')) {
    return true;
  }

  // WhatsApp & Messaging Voice Notes / Audio
  if (segments.any(
    (segment) =>
        segment == 'whatsapp' ||
        segment == 'whatsapp business' ||
        segment == 'whatsapp voice notes' ||
        segment == 'whatsapp audio' ||
        segment == 'telegram audio' ||
        segment == 'telegram voice',
  )) {
    return true;
  }

  // Common voice note filename prefixes (PTT, AUD)
  if (baseName.startsWith('ptt-') || baseName.startsWith('aud-')) {
    return true;
  }

  return false;
}

Future<List<String>> _isolatedDirectoryTraversal(
  Map<String, dynamic> params,
) async {
  final String rootPath = params['rootPath'] as String;
  final List<String> extensions = List<String>.from(
    params['extensions'] as List,
  );
  final int minSizeBytes = params['minSizeBytes'] as int;
  final bool includeSystemAndMessagingAudio =
      params['includeSystemAndMessagingAudio'] as bool? ?? false;

  final dir = Directory(rootPath);
  if (!dir.existsSync()) return [];

  final List<String> validFiles = [];

  void walk(Directory currentDir) {
    if (isIgnoredScanPath(
      currentDir.path,
      includeSystemAndMessagingAudio: includeSystemAndMessagingAudio,
    )) {
      return;
    }

    List<FileSystemEntity> entities = [];
    try {
      entities = currentDir.listSync(recursive: false, followLinks: false);
    } catch (_) {
      return;
    }

    for (final entity in entities) {
      if (isIgnoredScanPath(
        entity.path,
        includeSystemAndMessagingAudio: includeSystemAndMessagingAudio,
      )) {
        continue;
      }

      if (entity is File) {
        final ext = p.extension(entity.path).toLowerCase();
        if (extensions.contains(ext)) {
          try {
            if (entity.lengthSync() >= minSizeBytes) {
              validFiles.add(entity.path);
            }
          } catch (_) {}
        }
      } else if (entity is Directory) {
        walk(entity);
      }
    }
  }

  walk(dir);
  return validFiles;
}

class LibraryScanner {
  final List<String> supportedExtensions = [
    '.mp3',
    '.flac',
    '.opus',
    '.aac',
    '.m4a',
    '.m4b',
    '.wav',
    '.ogg',
    '.aiff',
    '.alac',
    '.wma',
    '.ape',
    '.wv',
    '.tta',
    '.dsf',
    '.dff',
  ];

  static const int minDurationMs = 0; // Skipped filter as requested
  static const int minSizeBytes = 0; // Skipped filter as requested

  static const MethodChannel _broadcastChannel = MethodChannel(
    'com.looper.player/broadcast',
  );
  final Map<String, String?> _folderArtCache = {};

  // A full-storage-discovery scan calls scanDirectory() once per candidate
  // folder (Music, Download, DCIM, ...), and without All Files Access every
  // one of those calls needs the *entire* device-wide MediaStore audio index
  // (see the merge logic below). Re-running that native query per-folder was
  // pure waste, so the most recent result is memoized briefly and shared
  // across every LibraryScanner instance created during one scan pass.
  static List<Map<String, dynamic>>? _cachedMediaStoreItems;
  static bool? _cachedMediaStoreFlag;
  static DateTime? _cachedMediaStoreAt;
  static const Duration _mediaStoreCacheTtl = Duration(seconds: 15);

  Future<List<Map<String, dynamic>>?> _queryMediaStoreNative({
    required bool includeSystemAndMessagingAudio,
  }) async {
    if (!Platform.isAndroid) return null;

    final cachedAt = _cachedMediaStoreAt;
    if (cachedAt != null &&
        _cachedMediaStoreFlag == includeSystemAndMessagingAudio &&
        DateTime.now().difference(cachedAt) < _mediaStoreCacheTtl) {
      return _cachedMediaStoreItems;
    }

    try {
      final List<dynamic>? rawList = await _broadcastChannel
          .invokeMethod<List<dynamic>>('queryMediaStore', {
            'minDurationMs': minDurationMs,
            'minSizeBytes': minSizeBytes,
            'includeSystemAndMessagingAudio': includeSystemAndMessagingAudio,
          });
      if (rawList == null) return null;
      final items = rawList
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _cachedMediaStoreItems = items;
      _cachedMediaStoreFlag = includeSystemAndMessagingAudio;
      _cachedMediaStoreAt = DateTime.now();
      return items;
    } catch (_) {
      return null;
    }
  }

  /// Drops the memoized MediaStore listing - same reasoning as
  /// invalidateSafCache: a scan run shortly before this one (e.g. the
  /// welcome screen's common-folder auto-scan, moments before the user
  /// grants Music & Audio access and adds a custom folder) can leave this
  /// cache holding a stale or permission-less snapshot for up to
  /// [_mediaStoreCacheTtl], making an explicit "Add Folder" scan miss songs
  /// MediaStore already knows about elsewhere on the device.
  static void invalidateMediaStoreCache() {
    _cachedMediaStoreItems = null;
    _cachedMediaStoreAt = null;
  }

  // Same memoization idea as the MediaStore cache above, for the SAF
  // (Storage Access Framework) folder listing: it's also device-wide (every
  // currently-granted "Add folder" folder, not just the one being scanned),
  // so without this it would get re-walked once per candidate folder during
  // a full scan.
  static List<String>? _cachedSafFiles;
  static DateTime? _cachedSafFilesAt;
  static const Duration _safFilesCacheTtl = Duration(seconds: 15);

  Future<List<String>> _querySafFiles() async {
    if (!Platform.isAndroid) return const [];

    final cachedAt = _cachedSafFilesAt;
    if (cachedAt != null &&
        DateTime.now().difference(cachedAt) < _safFilesCacheTtl) {
      return _cachedSafFiles ?? const [];
    }

    final files = await SafFolderService.listAudioFiles(supportedExtensions);
    _cachedSafFiles = files;
    _cachedSafFilesAt = DateTime.now();
    return files;
  }

  /// Drops the memoized SAF file listing so the very next scan re-queries
  /// it instead of reusing a result from before a folder grant existed.
  /// Without this, a scan that runs (e.g. the welcome screen's automatic
  /// common-folder scan) within [_safFilesCacheTtl] of a brand-new "Add
  /// Folder" pick would keep serving the pre-grant (often empty) listing,
  /// making the just-granted folder look like it has no songs.
  static void invalidateSafCache() {
    _cachedSafFiles = null;
    _cachedSafFilesAt = null;
  }

  static const _excludedFoldersKey = 'excluded_folders';

  Future<List<String>> _loadExcludedFolders() async {
    final raw = await LocalJsonStore.read(_excludedFoldersKey);
    if (raw is! List) return const [];
    return raw.whereType<String>().toList();
  }

  Future<ScanResult> scanDirectory(
    String path, {
    bool addFolderToSettings = false,
  }) async {
    final List<File> filesToProcess = [];
    final Set<String> musicFolders = {};

    final Set<String> discoveredPaths = {};

    final Map<String, Map<String, dynamic>> mediaStoreMap = {};
    final settings = await DbService.isar.appSettings.get(0);
    final includeSystemAndMessagingAudio =
        settings?.includeSystemAndMessagingAudio ?? false;
    final excludedFolders = await _loadExcludedFolders();

    // 1. Direct Background Isolate Directory Traversal for full disk coverage
    if (Directory(path).existsSync()) {
      final List<String> filePaths =
          await compute(_isolatedDirectoryTraversal, {
            'rootPath': path,
            'extensions': supportedExtensions,
            'minSizeBytes': minSizeBytes,
            'includeSystemAndMessagingAudio': includeSystemAndMessagingAudio,
          });
      discoveredPaths.addAll(filePaths);
    }

    // 2. Native Android MediaStore Query - the primary discovery source.
    // Without MANAGE_EXTERNAL_STORAGE (removed for Play Store compliance,
    // see AndroidManifest.xml) raw filesystem traversal can no longer reach
    // arbitrary folders on its own, so every MediaStore-indexed track is
    // always merged in here regardless of which root this particular scan
    // pass is scoped to.
    if (Platform.isAndroid) {
      final mediaStoreItems = await _queryMediaStoreNative(
        includeSystemAndMessagingAudio: includeSystemAndMessagingAudio,
      );
      if (mediaStoreItems != null && mediaStoreItems.isNotEmpty) {
        for (final item in mediaStoreItems) {
          final filePath = item['path'] as String?;
          if (filePath != null && filePath.isNotEmpty) {
            mediaStoreMap[filePath] = item;
            mediaStoreMap[p.canonicalize(filePath)] = item;
            final ext = p.extension(filePath).toLowerCase();
            if (supportedExtensions.contains(ext)) {
              discoveredPaths.add(filePath);
            }
          }
        }
      }
    }

    // 3. Native SAF (Storage Access Framework) query - covers files inside
    // manually-added folders ("Add folder") that raw traversal can no longer
    // reach without MANAGE_EXTERNAL_STORAGE, and formats MediaStore doesn't
    // index (e.g. .ape, .wv, .tta, .dsf, .dff), for as long as they live
    // inside a folder the user explicitly granted access to.
    if (Platform.isAndroid) {
      final safFiles = await _querySafFiles();
      for (final filePath in safFiles) {
        final ext = p.extension(filePath).toLowerCase();
        if (supportedExtensions.contains(ext)) {
          discoveredPaths.add(filePath);
        }
      }
    }

    // Applied once here, after all three discovery sources (raw traversal,
    // MediaStore, SAF) are merged, so an exclusion holds regardless of which
    // of them happened to find a given file.
    if (excludedFolders.isNotEmpty) {
      discoveredPaths.removeWhere(
        (fp) => isUnderExcludedFolder(fp, excludedFolders),
      );
    }

    for (final fp in discoveredPaths) {
      filesToProcess.add(File(fp));
      musicFolders.add(p.dirname(fp));
    }

    if (filesToProcess.isEmpty) {
      await DbService.isar.writeTxn(() async {
        final prefix = path.endsWith('/') ? path : '$path/';
        final toDelete = await DbService.isar.songs
            .filter()
            .pathStartsWith(prefix)
            .or()
            .pathEqualTo(path)
            .findAll();
        final idsToDelete = toDelete.map((s) => s.id).toList();
        if (idsToDelete.isNotEmpty) {
          await DbService.isar.songs.deleteAll(idsToDelete);
        }
      });
      return ScanResult(songsCount: 0, musicFolders: {});
    }

    // Existing songs scoped to this folder - used below to know what may
    // need deleting (files under `path` that disappeared).
    final prefix = path.endsWith('/') ? path : '$path/';
    final songsInPathDb = await DbService.isar.songs
        .filter()
        .pathStartsWith(prefix)
        .or()
        .pathEqualTo(path)
        .findAll();

    // "Already known" lookup used to decide which discovered files still
    // need metadata extraction. This must be built from the WHOLE database,
    // not just `songsInPathDb`: without All Files Access the MediaStore
    // merge above intentionally pulls in every indexed audio file regardless
    // of `path` (scoped filesystem access can't be trusted to see
    // everything), so a single full-storage-discovery pass calls
    // scanDirectory() once per candidate folder (Music, Download, DCIM, ...)
    // with the SAME device-wide file list each time. Scoping this map to
    // `path` made every song look "new" on every folder pass but the one it
    // physically lives in, so its metadata (tag parsing, embedded art,
    // lyrics, even artwork downloads) was re-extracted once per folder -
    // easily 10x+ redundant work, which is why "Music and audio" scans were
    // so much slower than "All files" ones (a single-root scan).
    final allDbSongs = await DbService.isar.songs.where().findAll();
    final Map<String, Song> dbSongsMap = {};
    for (final s in allDbSongs) {
      dbSongsMap[s.path] = s;
      dbSongsMap[p.canonicalize(s.path)] = s;
    }

    final Set<String> currentFilePaths = filesToProcess
        .map((f) => f.path)
        .toSet();
    final Set<String> currentCanonicalPaths = filesToProcess
        .map((f) => p.canonicalize(f.path))
        .toSet();

    final List<int> idsToDelete = [];
    for (final song in songsInPathDb) {
      if (!currentFilePaths.contains(song.path) &&
          !currentCanonicalPaths.contains(p.canonicalize(song.path))) {
        idsToDelete.add(song.id);
      }
    }

    if (idsToDelete.isNotEmpty) {
      await DbService.isar.writeTxn(() async {
        await DbService.isar.songs.deleteAll(idsToDelete);
      });
    }

    final List<File> newFilesToProcess = filesToProcess.where((f) {
      final dbSong = dbSongsMap[f.path] ?? dbSongsMap[p.canonicalize(f.path)];
      // A song genuinely tagged "Unknown Artist" (or with no art anywhere to
      // find) is not incomplete - it's already been through pass 2 and this
      // is its real result. Re-flagging it here on every routine scan used
      // to mean any such song was perpetually rewritten from scratch (see
      // needsEnrichment's doc comment - that flag is exactly this
      // "still needs the slow pass" state, so trust it instead of guessing
      // from the data shape).
      return dbSong == null || dbSong.needsEnrichment;
    }).toList();

    if (newFilesToProcess.isNotEmpty) {
      // Pass 1 of 2 (see enrichPendingSongs for pass 2): insert every new/
      // incomplete file immediately using only what MediaStore already
      // indexed (or a filename guess) - title/artist/duration, no tag-file
      // parsing, no embedded art, no lyrics lookup. That's what actually
      // took the time on a big first scan (hundreds of MetadataGod/native
      // calls before a single song became visible); this way songs appear
      // right away and the slow part happens in the background afterward.
      final results = newFilesToProcess
          .map(
            (f) => _quickSongFrom(
              f,
              mediaStoreMap[f.path] ?? mediaStoreMap[p.canonicalize(f.path)],
            ),
          )
          .toList();

      final maps = await _loadNameMaps();
      await _writeSongBatch(results, dbSongsMap, maps.albums, maps.artists);
    }

    return ScanResult(
      songsCount: filesToProcess.length,
      musicFolders: musicFolders,
    );
  }

  /// Builds a minimal Song from whatever MediaStore already knows (or a
  /// filename guess) - no file I/O, no tag parsing. Same shape as
  /// _extractMetadata's return value so both can flow through
  /// _writeSongBatch, but flagged needsEnrichment: true since none of the
  /// slow stuff (real tags, embedded art, lyrics) has run yet.
  Map<String, dynamic> _quickSongFrom(
    File file,
    Map<String, dynamic>? mediaStoreData,
  ) {
    final filename = p.basenameWithoutExtension(file.path);
    String? title = mediaStoreData?['title'] as String?;
    String? artist = mediaStoreData?['artist'] as String?;
    final album = mediaStoreData?['album'] as String?;
    final durationMs = (mediaStoreData?['duration'] as num?)?.toInt();
    final trackNumber = (mediaStoreData?['track'] as num?)?.toInt();
    final year = (mediaStoreData?['year'] as num?)?.toInt();

    if (artist == null ||
        artist.trim().isEmpty ||
        artist.trim().toLowerCase() == 'unknown artist') {
      if (filename.contains(' - ')) {
        final parts = filename.split(' - ');
        if (parts.length >= 2) {
          artist = parts[0].trim();
          if (title == null || title.trim().isEmpty || title == filename) {
            title = parts.sublist(1).join(' - ').trim();
          }
        }
      }
    }

    final cleanTitle = (title != null && title.trim().isNotEmpty)
        ? title.trim()
        : filename;
    final cleanArtist = (artist != null && artist.trim().isNotEmpty)
        ? artist.trim()
        : 'Unknown Artist';
    final cleanAlbum = (album != null && album.trim().isNotEmpty)
        ? album.trim()
        : 'Unknown Album';

    final song = Song()
      ..path = file.path
      ..title = cleanTitle
      ..artist = cleanArtist
      ..album = cleanAlbum
      ..duration = durationMs
      ..trackNumber = trackNumber
      ..year = year
      ..dateAdded = DateTime.now()
      ..needsEnrichment = true;

    return {
      'song': song,
      'metadata': Metadata(
        title: cleanTitle,
        artist: cleanArtist,
        album: cleanAlbum,
      ),
      'artPath': null,
    };
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

  /// Writes a batch of _extractMetadata/_quickSongFrom results in one
  /// transaction, deduping albums/artists against the maps passed in
  /// (which the caller keeps across calls so a name discovered in an
  /// earlier batch of the same run is recognized, not re-inserted).
  Future<void> _writeSongBatch(
    List<Map<String, dynamic>?> results,
    Map<String, Song> dbSongsMap,
    Map<String, Album> albumByName,
    Map<String, Artist> artistByName,
  ) async {
    final songsToPut = <Song>[];
    final albumsToPut = <Album>{};
    final artistsToPut = <Artist>{};

    for (final data in results) {
      if (data == null) continue;
      final song = data['song'] as Song;
      final metadata = data['metadata'] as Metadata;
      final artPath = data['artPath'] as String?;

      final existingDbSong =
          dbSongsMap[song.path] ?? dbSongsMap[p.canonicalize(song.path)];
      if (existingDbSong != null) {
        song.id = existingDbSong.id;
        // song here is a brand-new Song() from _quickSongFrom/_extractMetadata
        // that only ever set the fields it actually discovered - putAll()
        // below replaces the whole row, so anything not copied across here
        // would be silently reset to its default (favorite unset, play
        // count/listening history zeroed, custom equalizer cleared) every
        // time this path is reprocessed, not just the first time it's seen.
        song.playCount = existingDbSong.playCount;
        song.lastPlayed = existingDbSong.lastPlayed;
        song.totalListenedMs = existingDbSong.totalListenedMs;
        song.lastPositionMs = existingDbSong.lastPositionMs;
        song.isFavorite = existingDbSong.isFavorite;
        song.hasCustomEqualizer = existingDbSong.hasCustomEqualizer;
        song.equalizerGains = existingDbSong.equalizerGains;
        song.lyrics ??= existingDbSong.lyrics;
      }
      songsToPut.add(song);

      if (metadata.album != null) {
        final existingAlbum = albumByName[metadata.album!];
        if (existingAlbum == null) {
          final album = Album()
            ..name = metadata.album!
            ..artist = metadata.artist
            ..artPath = artPath
            ..dateAdded = DateTime.now();
          albumByName[album.name] = album;
          albumsToPut.add(album);
        } else if (existingAlbum.artPath == null && artPath != null) {
          existingAlbum.artPath = artPath;
          albumsToPut.add(existingAlbum);
        }
      }

      final primaryArtistName = ArtistParser.primaryArtist(metadata.artist);
      final existingArtist = artistByName[primaryArtistName];
      if (existingArtist == null) {
        final artistObj = Artist()
          ..name = primaryArtistName
          ..artPath = artPath;
        artistByName[artistObj.name] = artistObj;
        artistsToPut.add(artistObj);
      } else if (existingArtist.artPath == null && artPath != null) {
        existingArtist.artPath = artPath;
        artistsToPut.add(existingArtist);
      }
    }

    if (songsToPut.isEmpty) return;
    await DbService.isar.writeTxn(() async {
      await DbService.isar.songs.putAll(songsToPut);
      if (albumsToPut.isNotEmpty) {
        await DbService.isar.albums.putAll(albumsToPut.toList());
      }
      if (artistsToPut.isNotEmpty) {
        await DbService.isar.artists.putAll(artistsToPut.toList());
      }
    });
  }

  /// Pass 2 of 2: the slow part deferred by scanDirectory's quick insert -
  /// real tag parsing, embedded art, lyrics - for every song still flagged
  /// needsEnrichment, across the whole library at once regardless of which
  /// folder(s) were just scanned (see the dbSongsMap comment above for why
  /// per-folder would mean redundant repeat work). Writes in small batches
  /// rather than one giant transaction at the end so the pending count
  /// (and therefore the "Enriching…" indicator) visibly counts down as it
  /// goes, via the same live Isar watch the rest of the library list uses.
  Future<void> enrichPendingSongs() async {
    final settings = await DbService.isar.appSettings.get(0);
    final downloadIfMissing =
        (settings?.downloadArtwork ?? false) &&
        (settings?.enableInternet ?? true);
    final includeSystemAndMessagingAudio =
        settings?.includeSystemAndMessagingAudio ?? false;

    final pending = await DbService.isar.songs
        .filter()
        .needsEnrichmentEqualTo(true)
        .findAll();
    if (pending.isEmpty) return;

    final mediaStoreItems = await _queryMediaStoreNative(
      includeSystemAndMessagingAudio: includeSystemAndMessagingAudio,
    );
    final mediaStoreMap = <String, Map<String, dynamic>>{};
    if (mediaStoreItems != null) {
      for (final item in mediaStoreItems) {
        final filePath = item['path'] as String?;
        if (filePath != null && filePath.isNotEmpty) {
          mediaStoreMap[filePath] = item;
          mediaStoreMap[p.canonicalize(filePath)] = item;
        }
      }
    }

    final dbSongsMap = {for (final s in pending) s.path: s};
    final maps = await _loadNameMaps();

    Future<Map<String, dynamic>?> enrichOne(
      Song song, {
      bool retry = false,
    }) async {
      final file = File(song.path);
      if (!await file.exists()) return null;
      return _extractMetadata(
        file,
        mediaStoreData:
            mediaStoreMap[song.path] ??
            mediaStoreMap[p.canonicalize(song.path)],
        downloadArtworkIfMissing: downloadIfMissing,
        retry: retry,
      );
    }

    // Two separate knobs. writeBatchSize is how many rows share one Isar
    // transaction - each write fires the library's live watches, so fewer,
    // larger ones mean fewer rebuilds of whatever's on screen (Home's Quick
    // Picks / Recently Added re-sort, etc) while the pill counts down.
    // extractionConcurrency is how many songs have their tags/art read at
    // once, and is deliberately far smaller: firing a whole write batch's
    // worth at once (as this used to) queued dozens of embedded-picture
    // reads and tag parses behind each other, which both starved the UI of
    // frames and pushed the later ones past their timeouts - a timed-out
    // picture read looked exactly like "this song has no artwork".
    const int writeBatchSize = 25;
    const int extractionConcurrency = 3;
    for (int i = 0; i < pending.length; i += writeBatchSize) {
      final batch = pending.sublist(
        i,
        (i + writeBatchSize < pending.length)
            ? i + writeBatchSize
            : pending.length,
      );

      final results = await _mapWithConcurrency<Song, Map<String, dynamic>?>(
        batch,
        extractionConcurrency,
        enrichOne,
      );

      // A song whose tag/art read timed out (rather than genuinely having
      // none) gets one more attempt, one at a time with longer timeouts,
      // before being written as final - the row is marked done either way,
      // so without this a single slow read permanently meant no artwork.
      for (var j = 0; j < batch.length; j++) {
        if (results[j]?['transient'] == true) {
          results[j] = await enrichOne(batch[j], retry: true);
        }
      }

      // A file that vanished between the quick insert and now (deleted,
      // ejected SD card, ...) has no result to enrich with - drop the
      // placeholder row rather than leaving it stuck flagged forever.
      final goneIds = <int>[];
      for (var j = 0; j < batch.length; j++) {
        if (results[j] == null) goneIds.add(batch[j].id);
      }

      await _writeSongBatch(results, dbSongsMap, maps.albums, maps.artists);
      if (goneIds.isNotEmpty) {
        await DbService.isar.writeTxn(() async {
          await DbService.isar.songs.deleteAll(goneIds);
        });
      }

      // Lets the frames queued up behind that write's watch-driven rebuild
      // actually render before the next batch's reads start competing again.
      await Future.delayed(const Duration(milliseconds: 40));
    }
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

  /// Removes excluded system/messaging audio after the setting is disabled.
  /// Short duration alone is not a reason to delete a legitimate track.
  Future<int> cleanupFilteredAudio({
    required bool includeSystemAndMessagingAudio,
  }) async {
    int removedCount = 0;
    try {
      await DbService.isar.writeTxn(() async {
        final allSongs = await DbService.isar.songs.where().findAll();
        final idsToDelete = <int>[];

        for (final song in allSongs) {
          final isIgnoredPath = isIgnoredScanPath(
            song.path,
            includeSystemAndMessagingAudio: includeSystemAndMessagingAudio,
          );

          if (isIgnoredPath) {
            idsToDelete.add(song.id);
          }
        }

        if (idsToDelete.isNotEmpty) {
          await DbService.isar.songs.deleteAll(idsToDelete);
          removedCount = idsToDelete.length;
        }

        // Cleanup orphaned albums
        final allAlbums = await DbService.isar.albums.where().findAll();
        for (final album in allAlbums) {
          final count = await DbService.isar.songs
              .filter()
              .albumEqualTo(album.name)
              .count();
          if (count == 0) {
            await DbService.isar.albums.delete(album.id);
          }
        }

        // Cleanup orphaned artists
        final allArtists = await DbService.isar.artists.where().findAll();
        for (final artist in allArtists) {
          final count = await DbService.isar.songs
              .filter()
              .artistEqualTo(artist.name)
              .count();
          if (count == 0) {
            await DbService.isar.artists.delete(artist.id);
          }
        }
      });
    } catch (_) {}
    return removedCount;
  }

  /// Throws [TimeoutException] (rather than returning null) if the native
  /// side doesn't answer in time, so the caller can tell "slow" apart from
  /// "this file genuinely has no embedded picture" - see _extractMetadata's
  /// transient flag. Any other failure is a real "no picture" and is null.
  ///
  /// Returns the bytes as the Uint8List they arrive as: an earlier
  /// `.toList()` here turned a multi-MB picture into a boxed `List<int>` - one
  /// object per byte - on the main isolate, for every song, which was a
  /// large frame-dropping copy for no benefit (File.writeAsBytes takes the
  /// Uint8List directly).
  Future<Uint8List?> _fetchNativeEmbeddedPicture(
    String path, {
    required Duration timeout,
  }) async {
    if (!Platform.isAndroid) return null;
    try {
      return await _broadcastChannel
          .invokeMethod<Uint8List>('getEmbeddedPicture', {'path': path})
          .timeout(timeout);
    } on TimeoutException {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _findFolderArtwork(String songFilePath) async {
    final dirPath = p.dirname(songFilePath);
    if (_folderArtCache.containsKey(dirPath)) {
      return _folderArtCache[dirPath];
    }
    try {
      // A stalled/ejected SD card or a slow scoped-storage FUSE path can
      // hang any of the dart:io calls below (dir.exists(), the per-
      // candidate File.exists() checks, dir.list()) - and since this runs
      // inside enrichPendingSongs' batched Future.wait (see
      // _fetchNativeEmbeddedPicture's doc comment for the same reasoning),
      // one folder that hangs stalls every song batched alongside it, not
      // just this one's artwork lookup.
      return await _findFolderArtworkUncached(
        dirPath,
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Not cached: a transient stall/timeout shouldn't permanently record
      // "no artwork" for a folder that may genuinely have some - only a
      // real, completed search result (found or not) gets cached below.
      return null;
    }
  }

  Future<String?> _findFolderArtworkUncached(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        _folderArtCache[dirPath] = null;
        return null;
      }
      final candidates = [
        'cover.jpg',
        'cover.png',
        'cover.jpeg',
        'cover.webp',
        'folder.jpg',
        'folder.png',
        'folder.jpeg',
        'folder.webp',
        'front.jpg',
        'front.png',
        'front.jpeg',
        'front.webp',
        'album.jpg',
        'album.png',
        'album.jpeg',
        'album.webp',
        'art.jpg',
        'art.png',
        'art.jpeg',
        'art.webp',
      ];
      for (final candidate in candidates) {
        final f = File(p.join(dirPath, candidate));
        if (await f.exists()) {
          _folderArtCache[dirPath] = f.path;
          return f.path;
        }
      }
      final entities = await dir
          .list(recursive: false, followLinks: false)
          .toList();
      for (final entity in entities) {
        if (entity is File) {
          final base = p.basename(entity.path).toLowerCase();
          if (base.contains('cover') ||
              base.contains('folder') ||
              base.contains('front') ||
              base.contains('album')) {
            final ext = p.extension(base);
            if (['.jpg', '.jpeg', '.png', '.webp'].contains(ext)) {
              _folderArtCache[dirPath] = entity.path;
              return entity.path;
            }
          }
        }
      }
      _folderArtCache[dirPath] = null;
    } catch (_) {}
    return null;
  }

  /// [retry] is the second, one-at-a-time attempt enrichPendingSongs makes
  /// for a song whose first attempt reported `'transient': true` in its
  /// result - i.e. a tag or embedded-picture read timed out, which is not
  /// the same as the file having nothing to read - and uses longer timeouts.
  Future<Map<String, dynamic>?> _extractMetadata(
    File file, {
    Map<String, dynamic>? mediaStoreData,
    bool downloadArtworkIfMissing = false,
    bool retry = false,
  }) async {
    final tagTimeout = Duration(seconds: retry ? 10 : 4);
    final pictureTimeout = Duration(seconds: retry ? 20 : 8);
    var transient = false;

    try {
      Metadata? metadata;
      try {
        metadata = await MetadataGod.readMetadata(
          file: file.path,
        ).timeout(tagTimeout);
      } on TimeoutException {
        transient = true;
      } catch (_) {}

      String? title = metadata?.title;
      String? artist = metadata?.artist;
      String? album = metadata?.album;
      String? genre = metadata?.genre;
      int? durationMs = metadata?.durationMs?.toInt();
      int? trackNumber = metadata?.trackNumber;
      int? year = metadata?.year;
      List<int>? pictureData = metadata?.picture?.data;

      // Use native MediaStore fallbacks if MetadataGod fields are null or empty
      if (mediaStoreData != null) {
        if (title == null || title.trim().isEmpty) {
          title = mediaStoreData['title'] as String?;
        }
        if (artist == null || artist.trim().isEmpty) {
          artist = mediaStoreData['artist'] as String?;
        }
        if (album == null || album.trim().isEmpty) {
          album = mediaStoreData['album'] as String?;
        }
        if (durationMs == null || durationMs == 0) {
          durationMs = (mediaStoreData['duration'] as num?)?.toInt();
        }
        if (trackNumber == null || trackNumber == 0) {
          trackNumber = (mediaStoreData['track'] as num?)?.toInt();
        }
        if (year == null || year == 0) {
          year = (mediaStoreData['year'] as num?)?.toInt();
        }
      }

      if (durationMs != null && durationMs < LibraryScanner.minDurationMs) {
        return null;
      }

      if (pictureData == null && Platform.isAndroid) {
        try {
          pictureData = await _fetchNativeEmbeddedPicture(
            file.path,
            timeout: pictureTimeout,
          );
        } on TimeoutException {
          transient = true;
        }
      }

      final filename = p.basenameWithoutExtension(file.path);

      if (artist == null ||
          artist.trim().isEmpty ||
          artist.trim().toLowerCase() == 'unknown artist') {
        if (filename.contains(' - ')) {
          final parts = filename.split(' - ');
          if (parts.length >= 2) {
            artist = parts[0].trim();
            if (title == null || title.trim().isEmpty || title == filename) {
              title = parts.sublist(1).join(' - ').trim();
            }
          }
        }
      }

      String? artPath;
      if (pictureData != null && pictureData.isNotEmpty) {
        artPath = await saveAlbumArt(album ?? 'unknown', pictureData);
      }

      artPath ??= await _findFolderArtwork(file.path);

      String? lyrics;
      try {
        final embeddedLyrics = await MetadataService.getEmbeddedLyrics(
          file.path,
        );
        // Tag with the same [source:embedded] prefix LyricsFetcher/
        // LyricsNotifier use for an embedded-metadata hit, so the lyrics
        // screen's source pill can identify it - untagged text here read
        // back as a null source later ("No Lyrics Source" shown even though
        // lyrics were actually displayed, since scanning is usually what
        // populates song.lyrics first).
        if (embeddedLyrics != null && embeddedLyrics.isNotEmpty) {
          lyrics = '[source:embedded]\n$embeddedLyrics';
        }
      } catch (_) {}

      DateTime fileDate;
      try {
        fileDate = await file.lastModified();
      } catch (_) {
        fileDate = DateTime.now();
      }

      final cleanTitle = (title != null && title.trim().isNotEmpty)
          ? title.trim()
          : filename;
      final cleanArtist = (artist != null && artist.trim().isNotEmpty)
          ? artist.trim()
          : 'Unknown Artist';
      final cleanAlbum = (album != null && album.trim().isNotEmpty)
          ? album.trim()
          : 'Unknown Album';

      final song = Song()
        ..path = file.path
        ..title = cleanTitle
        ..artist = cleanArtist
        ..album = cleanAlbum
        ..genre = genre
        ..duration = durationMs
        ..trackNumber = trackNumber
        ..year = year
        ..artPath = artPath
        ..lyrics = lyrics
        ..dateAdded = fileDate;

      if (artPath == null && downloadArtworkIfMissing) {
        try {
          artPath = await ArtworkDownloaderService().downloadArtworkForSong(
            song,
          );
          song.artPath = artPath;
        } catch (_) {}
      }

      return {
        'song': song,
        'metadata':
            metadata ??
            Metadata(title: cleanTitle, artist: cleanArtist, album: cleanAlbum),
        'artPath': artPath,
        'transient': transient,
      };
    } catch (e) {
      try {
        final filename = p.basenameWithoutExtension(file.path);
        DateTime fileDate;
        try {
          fileDate = file.lastModifiedSync();
        } catch (_) {
          fileDate = DateTime.now();
        }
        final folderArt = await _findFolderArtwork(file.path);
        final song = Song()
          ..path = file.path
          ..title = filename
          ..artist = 'Unknown Artist'
          ..album = 'Unknown Album'
          ..artPath = folderArt
          ..dateAdded = fileDate;
        return {
          'song': song,
          'metadata': Metadata(
            title: filename,
            artist: 'Unknown Artist',
            album: 'Unknown Album',
          ),
          'artPath': folderArt,
        };
      } catch (_) {
        return null;
      }
    }
  }

  Future<String?> saveAlbumArt(String albumName, List<int> data) async {
    try {
      final appDir = await getApplicationSupportDirectory();
      final artDir = Directory(p.join(appDir.path, 'album_art'));
      if (!await artDir.exists()) await artDir.create(recursive: true);

      final hash =
          data.length.toString() +
          data.take(10).join() +
          data.reversed.take(10).join();
      final fileName =
          '${albumName.replaceAll(RegExp(r'[^\w\s]+'), '')}_${hash.hashCode}.jpg';

      final file = File(p.join(artDir.path, fileName));
      if (!await file.exists()) {
        await file.writeAsBytes(data);
      }
      return file.path;
    } catch (e) {
      return null;
    }
  }
}
