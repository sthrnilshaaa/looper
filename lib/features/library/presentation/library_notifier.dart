import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:looper_player/core/logger_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:looper_player/features/library/data/scanner.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/core/db_service.dart';
import 'package:looper_player/features/library/data/artist_image_service.dart';
import 'package:isar_community/isar.dart';
import 'package:looper_player/features/settings/presentation/settings_notifier.dart';
import 'package:looper_player/features/playback/data/lyrics_fetcher.dart';
import 'package:looper_player/core/local_json_store.dart';
import 'package:looper_player/core/storage_access.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:async';

part 'library_notifier.g.dart';

enum SongSortStrategy {
  dateAdded,
  title,
  artist,
  album,
  duration,
  year,
  playCount,
  lastPlayed,
}

/// True for a broad storage root such as "/storage/emulated/0" or a raw SD
/// card mount point ("/storage/XXXX-XXXX") - the coarse roots scanned once
/// "all files access" is granted, as opposed to a real per-song folder like
/// "/storage/emulated/0/Music". These must never be recorded in
/// libraryFolders, since scanning them recursively finds songs from every
/// real folder underneath, making the root itself a misleading entry.
bool _isCoarseStorageRoot(String path) {
  final normalized = (path.length > 1 && path.endsWith('/'))
      ? path.substring(0, path.length - 1)
      : path;
  if (normalized == '/storage/emulated/0') return true;
  return RegExp(r'^/storage/[^/]+$').hasMatch(normalized);
}

/// Whether a fresh `findAll()` of the songs table is actually different from
/// what's already in state, for the one call site (the end of
/// scanSavedFolders) where publishing an unchanged list just forces every
/// widget watching `songs` (e.g. the Songs tab's ListView) to rebuild for no
/// visual change. Compares id plus the only fields a rescan of an existing
/// row can ever touch (see LibraryScanner - it only re-processes a
/// previously-seen path while needsEnrichment is still true), so this
/// can't mask a real change: fields the scanner never touches (favorite,
/// playCount, lyrics, ...) are always identical between the two lists here
/// regardless, since a rescan of an already-enriched song preserves them
/// (see _writeSongBatch) rather than writing them.
bool _songsUnchanged(List<Song> current, List<Song> fresh) {
  if (identical(current, fresh)) return true;
  if (current.length != fresh.length) return false;
  for (var i = 0; i < current.length; i++) {
    final a = current[i];
    final b = fresh[i];
    if (a.id != b.id ||
        a.artist != b.artist ||
        a.artPath != b.artPath ||
        a.title != b.title ||
        a.album != b.album) {
      return false;
    }
  }
  return true;
}

class LibraryState {
  final bool isScanning;
  final bool isInitialized;
  final List<Song> songs;
  final List<Artist> artists;
  final List<Album> albums;
  final List<Playlist> playlists;
  final SongSortStrategy sortStrategy;
  final bool isAscending;

  LibraryState({
    this.isScanning = false,
    this.isInitialized = false,
    this.songs = const [],
    this.artists = const [],
    this.albums = const [],
    this.playlists = const [],
    this.sortStrategy = SongSortStrategy.dateAdded,
    this.isAscending = false,
  });

  LibraryState copyWith({
    bool? isScanning,
    bool? isInitialized,
    List<Song>? songs,
    List<Artist>? artists,
    List<Album>? albums,
    List<Playlist>? playlists,
    SongSortStrategy? sortStrategy,
    bool? isAscending,
  }) {
    return LibraryState(
      isScanning: isScanning ?? this.isScanning,
      isInitialized: isInitialized ?? this.isInitialized,
      songs: songs ?? this.songs,
      artists: artists ?? this.artists,
      albums: albums ?? this.albums,
      playlists: playlists ?? this.playlists,
      sortStrategy: sortStrategy ?? this.sortStrategy,
      isAscending: isAscending ?? this.isAscending,
    );
  }
}

@Riverpod(keepAlive: true)
class Library extends _$Library {
  StreamSubscription<List<Song>>? _songsSubscription;
  StreamSubscription<List<Artist>>? _artistsSubscription;
  StreamSubscription<List<Album>>? _albumsSubscription;
  StreamSubscription<List<Playlist>>? _playlistsSubscription;
  bool _isFetchingArtistImages = false;
  bool _isScanRunning = false;
  DateTime? _lastScanAt;
  static const _lastScanAtKey = 'last_library_scan_at';

  // A resume-triggered refresh (see refreshIfStale) is skipped inside this
  // window of the last scan - without it, switching apps and back a few
  // times in a row (or a cold app relaunch shortly after the last one, now
  // that _lastScanAt survives restarts - see _init) would turn every switch
  // into a full rescan of every saved folder.
  static const _resumeRescanThreshold = Duration(minutes: 10);

  @override
  LibraryState build() {
    ref.onDispose(_pauseWatches);

    // Automatically clean up database and refresh songs whenever active library folders change!
    ref.listen<List<String>>(
      settingsProvider.select((s) => s.libraryFolders),
      (previous, next) async {
        if (previous != null && !listEquals(previous, next)) {
          await syncSongsWithFolders(next);
          // A scan in progress already reloads the watches itself once it
          // finishes (see scanSavedFolders) - doing it again here too would
          // just be a redundant extra full requery of every collection.
          if (!_isScanRunning) _loadLibrary();
        }
      },
      fireImmediately: false,
    );

    _init();
    return LibraryState();
  }

  Future<void> _init() async {
    // Wait for settings to load
    await ref.read(settingsProvider.notifier).initialization;

    // Load initial sort strategy and order from persisted settings
    final initialSettings = ref.read(settingsProvider);
    state = state.copyWith(
      sortStrategy: SongSortStrategy.values[initialSettings.sortStrategyIndex],
      isAscending: initialSettings.sortAscending,
    );

    // _lastScanAt otherwise starts every cold launch as null, which
    // refreshIfStale reads as "never scanned" - making the very first
    // Songs-tab visit of every single app open trigger a full rescan of
    // every saved folder, even seconds after the last one. Restoring it
    // from disk here means refreshIfStale's freshness window actually
    // spans across app restarts, not just within one running process.
    final rawLastScan = await LocalJsonStore.read(_lastScanAtKey);
    if (rawLastScan is int) {
      _lastScanAt = DateTime.fromMillisecondsSinceEpoch(rawLastScan);
    }

    _loadLibrary();

    // Independent of the rescan-staleness check above: a previous session's
    // Pass 2 (see LibraryScanner.enrichPendingSongs) can be left mid-way
    // through - the app closed, a hung/slow file stalled a batch, whatever -
    // leaving needsEnrichment rows behind with nothing actively working on
    // them. Those otherwise sit stuck forever, since enrichment is normally
    // only ever kicked off as a side effect of a folder scan, and
    // refreshIfStale intentionally skips that scan when one ran recently.
    // This check is cheap (a no-op past the first Isar count() query once
    // nothing's pending) and runs every launch regardless, so leftover work
    // always gets retried instead of only on the next real rescan.
    unawaited(_enrichPendingSongs());
  }

  void _loadLibrary() {
    _watchSongs();
    _watchArtists();
    _watchAlbums();
    _watchPlaylists();
  }

  /// Cancels every live collection watch without replacing them - used
  /// while a scan is writing to Isar (see scanSavedFolders) so a big scan's
  /// many small write transactions don't each independently trigger a full
  /// requery + resort + state update + widget rebuild of the whole library.
  /// scanSavedFolders already does one clean, explicit refresh (and calls
  /// _loadLibrary() to resubscribe) once it's done, so nothing is missed -
  /// this only removes redundant, immediately-superseded intermediate ones.
  void _pauseWatches() {
    _songsSubscription?.cancel();
    _artistsSubscription?.cancel();
    _albumsSubscription?.cancel();
    _playlistsSubscription?.cancel();
  }

  void setSortStrategy(SongSortStrategy strategy) {
    if (state.sortStrategy == strategy) {
      // Toggle direction if same strategy
      final newAsc = !state.isAscending;
      state = state.copyWith(isAscending: newAsc);
      ref.read(settingsProvider.notifier).updateSortAscending(newAsc);
    } else {
      state = state.copyWith(sortStrategy: strategy);
      ref.read(settingsProvider.notifier).updateSortStrategy(strategy.index);
    }
    _watchSongs();
  }

  void toggleSortOrder() {
    final newAsc = !state.isAscending;
    state = state.copyWith(isAscending: newAsc);
    ref.read(settingsProvider.notifier).updateSortAscending(newAsc);
    _watchSongs();
  }

  QueryBuilder<Song, Song, QAfterSortBy> _buildSongsQuery() {
    final isAsc = state.isAscending;
    switch (state.sortStrategy) {
      case SongSortStrategy.title:
        return isAsc
            ? DbService.isar.songs.where().sortByTitle()
            : DbService.isar.songs.where().sortByTitleDesc();
      case SongSortStrategy.artist:
        return isAsc
            ? DbService.isar.songs.where().sortByArtist().thenByTitle()
            : DbService.isar.songs.where().sortByArtistDesc().thenByTitle();
      case SongSortStrategy.album:
        return isAsc
            ? DbService.isar.songs.where().sortByAlbum().thenByTrackNumber()
            : DbService.isar.songs
                  .where()
                  .sortByAlbumDesc()
                  .thenByTrackNumber();
      case SongSortStrategy.duration:
        return isAsc
            ? DbService.isar.songs.where().sortByDuration()
            : DbService.isar.songs.where().sortByDurationDesc();
      case SongSortStrategy.year:
        return isAsc
            ? DbService.isar.songs.where().sortByYear()
            : DbService.isar.songs.where().sortByYearDesc();
      case SongSortStrategy.playCount:
        return isAsc
            ? DbService.isar.songs.where().sortByPlayCount()
            : DbService.isar.songs.where().sortByPlayCountDesc();
      case SongSortStrategy.lastPlayed:
        return isAsc
            ? DbService.isar.songs.where().sortByLastPlayed()
            : DbService.isar.songs.where().sortByLastPlayedDesc();
      case SongSortStrategy.dateAdded:
      default:
        return isAsc
            ? DbService.isar.songs.where().sortByDateAdded()
            : DbService.isar.songs.where().sortByDateAddedDesc();
    }
  }

  void _watchSongs() {
    _songsSubscription?.cancel();
    _songsSubscription = _buildSongsQuery().watch(fireImmediately: true).listen(
      (songs) {
        state = state.copyWith(songs: songs, isInitialized: true);
      },
    );
  }

  void _watchArtists() {
    _artistsSubscription?.cancel();
    _artistsSubscription = DbService.isar.artists
        .where()
        .sortByName()
        .watch(fireImmediately: true)
        .listen((artists) {
          state = state.copyWith(artists: artists);
          _fetchMissingArtistImages();
        });
  }

  void _watchAlbums() {
    _albumsSubscription?.cancel();
    _albumsSubscription = DbService.isar.albums
        .where()
        .sortByName()
        .watch(fireImmediately: true)
        .listen((albums) {
          state = state.copyWith(albums: albums);
        });
  }

  void _watchPlaylists() {
    _playlistsSubscription?.cancel();
    _playlistsSubscription = DbService.isar.playlists
        .where()
        .sortByName()
        .watch(fireImmediately: true)
        .listen((playlists) {
          state = state.copyWith(playlists: playlists);
        });
  }

  Future<void> _fetchMissingArtistImages() async {
    if (_isFetchingArtistImages) return;
    if (state.isScanning) return;

    _isFetchingArtistImages = true;
    try {
      final allArtists = await DbService.isar.artists.where().findAll();
      final artists = allArtists
          .where((a) => a.artistImageUrl == null)
          .toList();
      final service = ArtistImageService();

      for (final artist in artists) {
        // Yield/stop fetching immediately if a library scan starts
        if (state.isScanning) break;
        if (artist.name == 'Unknown Artist') continue;

        final localPath = await service.getArtistImage(artist.name);
        if (localPath != null) {
          await DbService.isar.writeTxn(() async {
            artist.artistImageUrl = localPath;
            await DbService.isar.artists.put(artist);
          });
        }

        // Wait 2.0 seconds between queries to prevent high CPU, power, and bandwidth usage,
        // and to fully comply with Deezer API rate limits.
        await Future.delayed(const Duration(milliseconds: 2000));
      }
    } finally {
      _isFetchingArtistImages = false;
    }
  }

  Future<void> prefetchLibraryLyrics() async {
    final songs = await DbService.isar.songs.where().findAll();
    // Also retries songs previously cached as "not found": LyricsFetcher
    // itself skips the slow/rate-limited online re-check for those (see its
    // cachedAsNotFound handling) but still re-tries the fast, local,
    // no-network embedded-metadata/sidecar-file checks - worth doing here
    // too, since e.g. Android's embedded-lyrics reader didn't exist when
    // some libraries were first scanned.
    final songsToFetch = songs
        .where(
          (s) =>
              s.lyrics == null ||
              s.lyrics!.isEmpty ||
              s.lyrics == '[source:not_found]',
        )
        .toList();

    if (songsToFetch.isEmpty) return;

    state = state.copyWith(isScanning: true);

    // Use a small concurrency limit to avoid overwhelming services
    const int batchSize = 5;
    for (int i = 0; i < songsToFetch.length; i += batchSize) {
      final end = (i + batchSize < songsToFetch.length)
          ? i + batchSize
          : songsToFetch.length;
      final batch = songsToFetch.sublist(i, end);

      await Future.wait(batch.map((song) => LyricsFetcher.fetchLyrics(song)));
    }

    state = state.copyWith(isScanning: false);
  }

  Future<bool> _requestPermissions() async {
    if (!Platform.isAndroid) return true;

    int sdkInt = 0;
    try {
      final sdkMatch = RegExp(
        r'API\s+(\d+)',
      ).firstMatch(Platform.operatingSystemVersion);
      if (sdkMatch != null) {
        sdkInt = int.parse(sdkMatch.group(1)!);
      }
    } catch (_) {}

    // Check if the standard media/storage permission is already granted to
    // bypass a slow OS request dialogue.
    final bool hasAudio = await Permission.audio.isGranted;
    final bool hasStorage = sdkInt < 33 && await Permission.storage.isGranted;

    if (hasAudio || hasStorage) {
      return true;
    }

    // github flavor only (always false on the Play build - see
    // StorageAccess): All Files Access alone is enough to scan, so don't
    // prompt for audio on top of it.
    if (await StorageAccess.hasAllFilesAccess()) {
      return true;
    }

    if (sdkInt >= 33) {
      return await Permission.audio.request().isGranted;
    } else {
      return await Permission.storage.request().isGranted;
    }
  }

  Future<void> scanSavedFolders({
    bool showVisualIndicator = true,
    bool fullStorageDiscovery = false,
  }) async {
    if (_isScanRunning || state.isScanning) {
      LoggerHelper.write(
        'Library.scanSavedFolders: Scan already in progress, ignoring.',
      );
      return;
    }
    await _runScanSavedFolders(
      showVisualIndicator: showVisualIndicator,
      fullStorageDiscovery: fullStorageDiscovery,
    );
  }

  /// The scan itself, without scanSavedFolders' re-entrancy guard - for a
  /// caller (resetAndRescan) that has already claimed `isScanning` itself
  /// and would otherwise be turned away by that very flag.
  Future<void> _runScanSavedFolders({
    required bool showVisualIndicator,
    required bool fullStorageDiscovery,
  }) async {
    _isScanRunning = true;
    _lastScanAt = DateTime.now();
    unawaited(
      LocalJsonStore.write(_lastScanAtKey, _lastScanAt!.millisecondsSinceEpoch),
    );
    try {
      if (!await _requestPermissions()) {
        return;
      }
      await Future.delayed(const Duration(milliseconds: 100));

      final settings = ref.read(settingsProvider);
      final savedFolders = settings.libraryFolders;
      List<String> scanRoots = [];

      // Whole-storage discovery is explicit. App startup only refreshes
      // already indexed/default folders and must never start a full scan.
      if (fullStorageDiscovery) {
        if (Platform.isAndroid) {
          try {
            const MethodChannel(
              'com.looper.player/broadcast',
            ).invokeMethod('rescanMedia', {'path': '/storage/emulated/0'});
          } catch (_) {}

          // With All Files Access (github flavor only - see
          // StorageAccess) the whole storage root and SD cards are walked
          // directly; _isCoarseStorageRoot keeps those roots themselves out
          // of libraryFolders after the scan.
          if (await StorageAccess.hasAllFilesAccess()) {
            for (final root in await StorageAccess.wholeStorageRoots()) {
              if (!scanRoots.contains(root)) scanRoots.add(root);
            }
          }

          // Without All Files Access (always the case on the Play build)
          // raw traversal can't reach an arbitrary/whole-storage root or SD
          // cards - see AndroidManifest.xml. Scoped storage
          // still allows raw listing of these specific top-level public
          // directories with just READ_MEDIA_AUDIO/READ_EXTERNAL_STORAGE;
          // everything else (custom folders, SD cards, formats MediaStore
          // doesn't index) is covered by the MediaStore + SAF merges inside
          // LibraryScanner.scanDirectory() instead, not by walking more
          // scanRoots here.
          final List<String> commonPaths = [
            '/storage/emulated/0/Music',
            '/storage/emulated/0/Download',
            '/storage/emulated/0/Documents',
            '/storage/emulated/0/Audiobooks',
            '/storage/emulated/0/Podcasts',
            '/storage/emulated/0/DCIM',
            '/storage/emulated/0/Recordings',
            '/storage/emulated/0/Bluetooth',
          ];
          if (scanRoots.isEmpty) {
            for (final cp in commonPaths) {
              if (Directory(cp).existsSync() && !scanRoots.contains(cp)) {
                scanRoots.add(cp);
              }
            }
          }
        } else if (Platform.isLinux) {
          String defaultPath = '${Platform.environment['HOME']}/Music';
          try {
            final result = await Process.run('xdg-user-dir', ['MUSIC']);
            if (result.exitCode == 0 &&
                result.stdout.toString().trim().isNotEmpty) {
              defaultPath = result.stdout.toString().trim();
            }
          } catch (_) {}
          scanRoots.add(defaultPath);
        }

        for (final f in savedFolders) {
          if (Directory(f).existsSync() && !scanRoots.contains(f)) {
            scanRoots.add(f);
          }
        }
      } else {
        // Standard refresh / Pull-to-refresh / Rescan Library: Scan ONLY saved folders (or defaults if none saved)
        if (savedFolders.isNotEmpty) {
          for (final f in savedFolders) {
            if (Directory(f).existsSync() && !scanRoots.contains(f)) {
              scanRoots.add(f);
            }
          }
        } else {
          // Default fallback if savedFolders is empty
          if (Platform.isAndroid) {
            final List<String> commonPaths = [
              '/storage/emulated/0/Music',
              '/storage/emulated/0/Download',
              '/storage/emulated/0/Documents',
            ];
            for (final cp in commonPaths) {
              if (Directory(cp).existsSync()) {
                scanRoots.add(cp);
              }
            }
          } else if (Platform.isLinux) {
            scanRoots.add('${Platform.environment['HOME']}/Music');
          }
        }
      }

      if (scanRoots.isEmpty) {
        scanRoots.add('/storage/emulated/0');
      }

      if (showVisualIndicator) {
        state = state.copyWith(isScanning: true);
      }

      // Paused for the rest of this scan, resumed in the inner finally
      // below - see _pauseWatches for why a scan's many small write
      // transactions shouldn't each independently trigger a full
      // requery/resort/rebuild of the whole library while it's running.
      _pauseWatches();
      try {
        final Set<String> allDiscoveredFolders = Set<String>.from(savedFolders);

        for (final path in scanRoots) {
          if (Directory(path).existsSync()) {
            final result = await LibraryScanner().scanDirectory(path);
            if (result.songsCount > 0) {
              allDiscoveredFolders.addAll(result.musicFolders);
            }
          }
        }

        // Execute Post-Scan Cleanup Filter
        await LibraryScanner().cleanupFilteredAudio(
          includeSystemAndMessagingAudio:
              settings.includeSystemAndMessagingAudio,
        );

        // Rebuild libraryFolders from allDiscoveredFolders (previously-saved
        // folders + the real per-song folders LibraryScanner just found),
        // dropping any that no longer exist/contain songs, and dropping any
        // broad storage-root entries (e.g. "/storage/emulated/0" recorded by
        // an older buggy scan) in favor of the actual folders inside them.
        final candidateFolders = allDiscoveredFolders.where(
          (f) => !_isCoarseStorageRoot(f),
        );
        if (candidateFolders.isNotEmpty) {
          final List<String> validFolders = [];
          for (final folder in candidateFolders) {
            final prefix = folder.endsWith('/') ? folder : '$folder/';
            final hasSongs =
                await DbService.isar.songs
                    .filter()
                    .pathStartsWith(prefix)
                    .or()
                    .pathEqualTo(folder)
                    .count() >
                0;
            // Not gated on Directory(folder).existsSync(): a folder added via
            // the SAF picker is a real path, but scoped storage's raw stat()
            // can still deny it even with a valid persisted SAF grant (that
            // grant is only honored through the ContentResolver/DocumentsContract
            // door, not dart:io's). hasSongs alone is sufficient - it already
            // naturally drops to 0 once a folder's songs stop being discovered
            // on a later scan pass.
            if (hasSongs) {
              validFolders.add(folder);
            }
          }
          await ref
              .read(settingsProvider.notifier)
              .updateLibraryFolders(validFolders);
        }

        // Fetch fresh songs, albums, artists, and playlists directly from Isar DB
        final freshSongs = await _buildSongsQuery().findAll();
        final freshAlbums = await DbService.isar.albums
            .where()
            .sortByName()
            .findAll();
        final freshArtists = await DbService.isar.artists
            .where()
            .sortByName()
            .findAll();
        final freshPlaylists = await DbService.isar.playlists
            .where()
            .sortByName()
            .findAll();

        state = state.copyWith(
          songs: _songsUnchanged(state.songs, freshSongs) ? null : freshSongs,
          albums: freshAlbums,
          artists: freshArtists,
          playlists: freshPlaylists,
          isScanning: false,
          isInitialized: true,
        );
      } finally {
        // Always resubscribe, even if the scan above threw - otherwise the
        // library would silently stop reacting to any further DB change at
        // all until some other, unrelated call happened to reload it.
        if (state.isScanning) {
          state = state.copyWith(isScanning: false);
        }
        _loadLibrary();
      }
    } finally {
      _isScanRunning = false;
    }
    // Pass 2 (see LibraryScanner.enrichPendingSongs) - deliberately not
    // awaited: pass 1's quick-inserted songs are already visible and
    // scanSavedFolders callers (pull-to-refresh, the welcome screen's
    // "scan complete" state, ...) shouldn't sit waiting for the slow
    // tag/art/lyrics work too. _loadLibrary() above already resubscribed
    // the live watches, so each write below reaches the UI the same way
    // any other library change does - no separate plumbing needed.
    unawaited(_enrichPendingSongs());
  }

  bool _isEnriching = false;

  Future<void> _enrichPendingSongs() async {
    if (_isEnriching) return;
    _isEnriching = true;
    try {
      await LibraryScanner().enrichPendingSongs();
    } catch (e, s) {
      LoggerHelper.write('Library._enrichPendingSongs failed', e, s);
    } finally {
      _isEnriching = false;
    }
  }

  /// Rescans only if it's been a while since the last one - meant for an app
  /// resume, so a song added/removed outside the app (file manager, USB
  /// transfer, another app freeing space) shows up without the user having
  /// to know to pull-to-refresh, without turning every quick app switch
  /// into a full rescan.
  Future<void> refreshIfStale() async {
    final lastScan = _lastScanAt;
    if (lastScan != null &&
        DateTime.now().difference(lastScan) < _resumeRescanThreshold) {
      return;
    }
    await scanSavedFolders(showVisualIndicator: false);
  }

  Future<void> clearAllData() async {
    await DbService.isar.writeTxn(() async {
      await DbService.isar.songs.clear();
      await DbService.isar.albums.clear();
      await DbService.isar.artists.clear();
      await DbService.isar.playlists.clear();
    });
    await ref.read(settingsProvider.notifier).updateLibraryFolders([]);
    await ref.read(settingsProvider.notifier).updateLastPlayedSong(null);
  }

  Future<void> resetAndRescan() async {
    if (!await _requestPermissions()) return;

    // Checked before anything is wiped: if a scan (or a lyrics prefetch,
    // which also holds isScanning) is already running, the rescan below
    // couldn't start either, and the library would be left emptied.
    if (_isScanRunning || state.isScanning) {
      LoggerHelper.write(
        'Library.resetAndRescan: Scan already in progress, ignoring.',
      );
      return;
    }
    state = state.copyWith(isScanning: true);
    try {
      await DbService.isar.writeTxn(() async {
        await DbService.isar.songs.clear();
        await DbService.isar.albums.clear();
        await DbService.isar.artists.clear();
      });
      await ref.read(settingsProvider.notifier).updateLastPlayedSong(null);

      // Not scanSavedFolders(): it refuses to start while isScanning is set,
      // and the flag set above is what keeps the UI on its scanning state
      // through the wipe. Going through it left the library emptied, no
      // rescan run, and isScanning stuck on - so every later scan was
      // ignored until the app was restarted.
      await _runScanSavedFolders(
        showVisualIndicator: true,
        fullStorageDiscovery: true,
      );
    } finally {
      // The scan clears this itself on every normal path; this covers an
      // early return (permission revoked mid-reset) or a throw in the wipe.
      if (state.isScanning) {
        state = state.copyWith(isScanning: false);
      }
    }
  }

  Future<int> scanLibrary(
    String path, {
    bool updateIsScanning = true,
    // False for a broad/coarse root (e.g. the whole internal storage root
    // scanned once "all files access" is granted) - recording that root
    // itself in libraryFolders would show the user "0" / "/storage/emulated/0"
    // instead of the actual folders their music lives in. Use
    // recordActualLibraryFolders() afterwards to record the real folders.
    bool recordFolder = true,
  }) async {
    if (!await _requestPermissions()) return 0;

    LibraryScanner.invalidateSafCache();
    LibraryScanner.invalidateMediaStoreCache();

    if (updateIsScanning) {
      state = state.copyWith(isScanning: true);
    }

    final totalSongsFound = await _scanSingleFolder(
      path,
      recordFolder: recordFolder,
    );

    if (updateIsScanning) {
      state = state.copyWith(isScanning: false);
    }

    // Without this, a song scanLibrary just quick-inserted stays flagged
    // needsEnrichment forever with no pass 2 ever scheduled to clear it -
    // scanSavedFolders triggers its own copy of this at the end of every
    // full sweep, but scanLibrary is also called on its own (Settings'
    // single-folder "Add Folder", the welcome screen's custom-folder pick,
    // re-adding a previously-excluded folder), and none of those go through
    // scanSavedFolders at all. Every caller of scanLibrary otherwise showed
    // an "Enriching N songs…" indicator that never counted down until some
    // unrelated later action happened to run a full scanSavedFolders sweep.
    unawaited(_enrichPendingSongs());

    return totalSongsFound;
  }

  /// Scans several folders as one batch, e.g. the welcome screen's ~12
  /// common-folder auto-scan - live collection watches are paused once for
  /// the whole batch (see _pauseWatches/_loadLibrary) instead of once per
  /// folder the way looping scanLibrary() calls would, and _isScanRunning
  /// suppresses the libraryFolders-change listener's own extra
  /// _loadLibrary() call on every single folder added mid-batch too. Without
  /// this, that many-small-writes-each-triggering-a-full-requery problem
  /// scanSavedFolders already solves for itself was still happening for
  /// every caller that scanned more than one folder in a row - up to ~24
  /// full library requery+rebuild cycles stacked into the few seconds right
  /// as the welcome screen hands off to Home.
  Future<int> scanMultipleFolders(
    List<String> paths, {
    bool recordFolder = true,
  }) async {
    if (!await _requestPermissions()) return 0;

    LibraryScanner.invalidateSafCache();
    LibraryScanner.invalidateMediaStoreCache();

    state = state.copyWith(isScanning: true);
    _isScanRunning = true;
    _pauseWatches();

    int totalSongsFound = 0;
    try {
      for (final path in paths) {
        totalSongsFound += await _scanSingleFolder(
          path,
          recordFolder: recordFolder,
        );
      }
    } finally {
      _isScanRunning = false;
      _loadLibrary();
      state = state.copyWith(isScanning: false);
    }

    unawaited(_enrichPendingSongs());
    return totalSongsFound;
  }

  /// Core single-folder scan shared by scanLibrary and scanMultipleFolders -
  /// everything except permission checks, cache invalidation, isScanning
  /// toggling, watch pausing and the enrichment trigger, which differ
  /// between a single explicit "Add Folder" call and a batch of them.
  Future<int> _scanSingleFolder(
    String path, {
    required bool recordFolder,
  }) async {
    // A path explicitly scanned here overrides a previous exclusion of that
    // exact path - otherwise re-adding a folder the user had removed (or
    // directly excluded) would silently find nothing, since the scanner
    // filters excluded paths out regardless of how they were discovered.
    // No-op if `path` isn't currently excluded.
    await ref.read(excludedFoldersProvider.notifier).removeQuietly(path);

    int totalSongsFound = 0;
    try {
      // Not gated on Directory(path).existsSync(): a folder added via the
      // SAF picker is a real path, but scoped storage's raw stat() can deny
      // it even with a valid persisted SAF grant (dart:io never goes through
      // the ContentResolver/DocumentsContract door that grant is honored
      // through). scanDirectory() already degrades gracefully for a path it
      // can't list directly - the MediaStore + SAF merges inside it still
      // find the folder's songs regardless.
      final result = await LibraryScanner().scanDirectory(path);
      totalSongsFound = result.songsCount;

      // Recorded regardless of totalSongsFound: every later rescan (resume,
      // pull-to-refresh, cold launch) only ever looks at libraryFolders, so
      // a folder that isn't added here becomes permanently unreachable the
      // moment this first attempt returns 0 - which a transient SAF/
      // MediaStore hiccup right after granting access can easily cause even
      // though the folder genuinely has songs. A folder that's actually
      // empty is pruned back out automatically by scanSavedFolders' own
      // post-scan "hasSongs" cleanup, so recording it here unconditionally
      // doesn't leave dead entries behind.
      final settings = ref.read(settingsProvider);
      final newFolders = Set<String>.from(settings.libraryFolders);
      if (recordFolder) {
        newFolders.add(path);
      } else {
        newFolders.addAll(result.musicFolders);
      }
      if (!setEquals(newFolders, settings.libraryFolders.toSet())) {
        await ref
            .read(settingsProvider.notifier)
            .updateLibraryFolders(newFolders.toList());
      }
    } catch (e) {
      LoggerHelper.write(
        'Library._scanSingleFolder: error scanning path $path',
        e,
      );
    }

    return totalSongsFound;
  }

  /// Recomputes libraryFolders from the actual parent folder of every song
  /// currently in the library, merging them into the existing list. Use this
  /// after a coarse/broad root scan (scanLibrary(..., recordFolder: false))
  /// so the "Library Folders" list shows the real folders songs live in
  /// (e.g. "Music", "Songs") instead of the broad root that was scanned.
  Future<void> recordActualLibraryFolders() async {
    final songs = await DbService.isar.songs.where().findAll();
    if (songs.isEmpty) return;

    final settings = ref.read(settingsProvider);
    final newFolders = Set<String>.from(settings.libraryFolders);
    for (final song in songs) {
      newFolders.add(Directory(song.path).parent.path);
    }

    if (newFolders.length != settings.libraryFolders.length) {
      await ref
          .read(settingsProvider.notifier)
          .updateLibraryFolders(newFolders.toList());
    }
  }

  Future<void> toggleFavorite(Song song) async {
    await DbService.isar.writeTxn(() async {
      // Direct ID lookup is safer to ensure we're updating the correct record
      final dbSong = await DbService.isar.songs.get(song.id);
      if (dbSong != null) {
        dbSong.isFavorite = !dbSong.isFavorite;
        await DbService.isar.songs.put(dbSong);
      } else {
        // Fallback for songs not yet in DB (e.g. played from file)
        song.isFavorite = !song.isFavorite;
        await DbService.isar.songs.put(song);
      }
    });
  }

  /// Sets (rather than toggles) [value] on every song in [songs] in one
  /// transaction - used by multi-select bulk actions, where opening a
  /// separate write transaction per song would get slow for a large
  /// selection and "toggle" is ambiguous once songs start in different
  /// favorite states.
  Future<void> setFavorite(List<Song> songs, bool value) async {
    if (songs.isEmpty) return;
    await DbService.isar.writeTxn(() async {
      final ids = songs.map((s) => s.id).toList();
      final dbSongs = await DbService.isar.songs.getAll(ids);
      final toUpdate = <Song>[];
      for (final dbSong in dbSongs) {
        if (dbSong != null && dbSong.isFavorite != value) {
          dbSong.isFavorite = value;
          toUpdate.add(dbSong);
        }
      }
      if (toUpdate.isNotEmpty) {
        await DbService.isar.songs.putAll(toUpdate);
      }
    });
  }

  Future<void> syncSongsWithFolders(List<String> activeFolders) async {
    await DbService.isar.writeTxn(() async {
      // Find all songs in the DB
      final allSongs = await DbService.isar.songs.where().findAll();

      // Filter songs that do NOT belong to any of the active folders.
      // Every other folder-prefix comparison in this file/scanner.dart
      // normalizes with a trailing slash first - this one didn't, so
      // "/Music" would also match "/MusicVideos/x.mp3" (over-matching,
      // not under-matching, but still wrong).
      final songsToDelete = allSongs.where((song) {
        return !activeFolders.any((folder) {
          final prefix = folder.endsWith('/') ? folder : '$folder/';
          return song.path == folder || song.path.startsWith(prefix);
        });
      }).toList();

      if (songsToDelete.isNotEmpty) {
        final idsToDelete = songsToDelete.map((s) => s.id).toList();
        await DbService.isar.songs.deleteAll(idsToDelete);

        // Clean up empty albums & artists
        final remainingSongs = await DbService.isar.songs.where().findAll();
        final activeAlbumNames = remainingSongs.map((s) => s.album).toSet();
        final activeArtistNames = remainingSongs.map((s) => s.artist).toSet();

        // Load all albums and artists
        final allAlbums = await DbService.isar.albums.where().findAll();
        final albumsToDelete = allAlbums
            .where((a) => !activeAlbumNames.contains(a.name))
            .map((a) => a.id)
            .toList();
        if (albumsToDelete.isNotEmpty) {
          await DbService.isar.albums.deleteAll(albumsToDelete);
        }

        final allArtists = await DbService.isar.artists.where().findAll();
        final artistsToDelete = allArtists
            .where((art) => !activeArtistNames.contains(art.name))
            .map((art) => art.id)
            .toList();
        if (artistsToDelete.isNotEmpty) {
          await DbService.isar.artists.deleteAll(artistsToDelete);
        }
      }
    });
  }

  /// Edits an album's metadata (name, artist, year, artwork) and cascades the
  /// change to every song currently tagged with this album, since songs only
  /// reference their album by name rather than a foreign key. Does NOT touch
  /// the physical files — only the DB records (same contract as
  /// [PlaybackNotifier.editSongMetadata] for individual songs).
  Future<bool> editAlbumMetadata(
    Album album, {
    String? name,
    String? artist,
    int? year,
    String? artPath, // null = unchanged, '' = cleared, '/path' = new artwork
  }) async {
    try {
      await DbService.isar.writeTxn(() async {
        final songs = await DbService.isar.songs
            .filter()
            .albumEqualTo(album.name)
            .findAll();

        final newName = (name != null && name.trim().isNotEmpty)
            ? name.trim()
            : null;

        // Renaming onto another existing album's name merges into that
        // album (adopting its identity) instead of colliding with the
        // unique name index or leaving two entries for the same album.
        Album target = album;
        if (newName != null && newName != album.name) {
          final existing = await DbService.isar.albums
              .filter()
              .nameEqualTo(newName)
              .findFirst();
          if (existing != null && existing.id != album.id) {
            await DbService.isar.albums.delete(album.id);
            target = existing;
          }
        }

        target.name = newName ?? target.name;
        if (artist != null) {
          target.artist = artist.trim().isEmpty ? null : artist.trim();
        }
        if (year != null) target.year = year == 0 ? null : year;
        if (artPath != null) {
          target.artPath = artPath.trim().isEmpty ? null : artPath.trim();
        }
        await DbService.isar.albums.put(target);

        // Cascade name/artist/year to every song that belonged to the (old)
        // album so the library's text metadata stays consistent. Artwork is
        // deliberately NOT cascaded: a song's own artPath is what the mini
        // player, queue and song lists show for it, and songs can carry
        // their own custom/embedded art independent of the album cover -
        // overwriting it here made picking a new album cover silently
        // replace every song's picture too.
        for (final song in songs) {
          song.album = target.name;
          if (artist != null) song.artist = target.artist;
          if (year != null) song.year = target.year;
        }
        if (songs.isNotEmpty) {
          await DbService.isar.songs.putAll(songs);
        }
      });
      return true;
    } catch (e) {
      return false;
    }
  }

}

/// Last 10 played songs for the Home dashboard. Distinct from
/// [recentlyPlayedScreenProvider] (smart_views.dart, limit 50) which backs the
/// dedicated "Recently Played" screen - keep these two names distinct rather
/// than both being `recentlyPlayedProvider`, since any file that ever imports
/// both `library_notifier.dart` and `smart_views.dart` unprefixed would hit an
/// ambiguous-import error the moment it referenced the bare name.
@Riverpod(keepAlive: true)
Stream<List<Song>> dashboardRecentlyPlayed(Ref ref) {
  return DbService.isar.songs
      .where()
      .filter()
      .lastPlayedIsNotNull()
      .sortByLastPlayedDesc()
      .limit(10)
      .watch(fireImmediately: true);
}

@Riverpod(keepAlive: true)
Stream<List<Song>> topSongs(Ref ref) {
  return DbService.isar.songs
      .where()
      .sortByPlayCountDesc()
      .limit(8)
      .watch(fireImmediately: true);
}

// The four providers below are memoized copies of derived views that used to
// be recomputed inline inside a widget's build() - a full sort or an O(n)
// grouping pass over every song in the library, every single rebuild of
// that screen, even for rebuilds that had nothing to do with the song list
// itself (a settings change, a navigation transition, ...). Reading
// `songs` through .select here means Riverpod only reruns the computation
// when the song list itself actually changes, instead of every time the
// watching widget happens to rebuild. Each keeps the exact same algorithm
// and comparator as the code it replaced, so the output - and therefore
// the UI - is unchanged; only when the work happens is different.

/// Home tab's "Quick Picks" - same comparator (play count, most first) and
/// same 18-item cap as before.
@Riverpod(keepAlive: true)
List<Song> homeQuickPicks(Ref ref) {
  final songs = ref.watch(libraryProvider.select((s) => s.songs));
  final sorted = List<Song>.from(songs)
    ..sort((a, b) => b.playCount.compareTo(a.playCount));
  return sorted.take(18).toList();
}

/// Home tab's "Recently Added" section - same comparator (date added,
/// newest first) as before. Kept as the full sorted list, not just the
/// visible prefix, since tapping into this section queues it in full.
@Riverpod(keepAlive: true)
List<Song> homeRecentlyAdded(Ref ref) {
  final songs = ref.watch(libraryProvider.select((s) => s.songs));
  return List<Song>.from(songs)
    ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
}

/// Every song grouped by its raw genre value (null for songs missing one).
/// The "Unknown" label itself is applied by the caller instead of here,
/// since it's localized and this provider has no BuildContext - see
/// GenresGridView.
@Riverpod(keepAlive: true)
Map<String?, List<Song>> songsByGenre(Ref ref) {
  final songs = ref.watch(libraryProvider.select((s) => s.songs));
  final map = <String?, List<Song>>{};
  for (final song in songs) {
    map.putIfAbsent(song.genre, () => []).add(song);
  }
  return map;
}

/// Every song grouped by its parent folder path.
@Riverpod(keepAlive: true)
Map<String, List<Song>> songsByFolder(Ref ref) {
  final songs = ref.watch(libraryProvider.select((s) => s.songs));
  final map = <String, List<Song>>{};
  for (final song in songs) {
    final folder = Directory(song.path).parent.path;
    map.putIfAbsent(folder, () => []).add(song);
  }
  return map;
}

/// How many songs are still awaiting Pass 2 (tag/art/lyrics) enrichment -
/// derived from the already-reactive songs list rather than a separate
/// Isar watch, so it updates for free as LibraryScanner.enrichPendingSongs
/// writes each batch.
@Riverpod(keepAlive: true)
int songsNeedingEnrichment(Ref ref) {
  final songs = ref.watch(libraryProvider.select((s) => s.songs));
  return songs.where((s) => s.needsEnrichment).length;
}

/// Per-folder scan exclusions, e.g. a voice-memos subfolder living inside an
/// otherwise-wanted Music folder. Kept in a local JSON file (see
/// LocalJsonStore) rather than the Isar `AppSettings` schema, and read
/// directly by LibraryScanner using the same store key - see
/// isUnderExcludedFolder in scanner.dart.
@Riverpod(keepAlive: true)
class ExcludedFolders extends _$ExcludedFolders {
  static const _storeKey = 'excluded_folders';

  @override
  List<String> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final raw = await LocalJsonStore.read(_storeKey);
    if (raw is! List) return;
    state = raw.whereType<String>().toList();
  }

  Future<void> _persist() => LocalJsonStore.write(_storeKey, state);

  Future<void> add(String folder) async {
    if (state.contains(folder)) return;
    state = [...state, folder];
    await _persist();
    // Excluding never needs a rescan - nothing there could have become
    // newly discoverable, so directly dropping what's already indexed
    // under it is both correct and a lot cheaper than a full library
    // rescan just to re-arrive at the same result.
    await _deleteSongsUnderFolder(folder);
  }

  Future<void> remove(String folder) async {
    await removeQuietly(folder);
    // Un-excluding does need a scan to (re)discover what's in there, but
    // only of this one folder, the same as "Add Folder" - not a full
    // scanSavedFolders() pass over every saved folder.
    await ref
        .read(libraryProvider.notifier)
        .scanLibrary(folder, recordFolder: false);
  }

  /// Same as [remove] but without triggering its own scan - for callers
  /// that are about to scan the folder themselves right after (scanLibrary
  /// uses this so a deliberate "Add Folder" on a previously-removed path
  /// always works, instead of the folder staying silently excluded forever
  /// because [remove]'s own scan would recurse right back into this call).
  Future<void> removeQuietly(String folder) async {
    if (!state.contains(folder)) return;
    state = state.where((f) => f != folder).toList();
    await _persist();
  }

  Future<void> _deleteSongsUnderFolder(String folder) async {
    final prefix = folder.endsWith('/') ? folder : '$folder/';
    await DbService.isar.writeTxn(() async {
      final toDelete = await DbService.isar.songs
          .filter()
          .pathStartsWith(prefix)
          .or()
          .pathEqualTo(folder)
          .findAll();
      if (toDelete.isNotEmpty) {
        await DbService.isar.songs.deleteAll(
          toDelete.map((s) => s.id).toList(),
        );
      }
    });
  }

  /// Merges in folders from a restored backup and persists once, without
  /// rescanning itself - used by backup restore, which already triggers one
  /// rescan of its own after every section is merged.
  Future<void> mergeFrom(List<String> imported) async {
    final merged = {...state, ...imported}.toList();
    if (merged.length == state.length) return;
    state = merged;
    await LocalJsonStore.write(_storeKey, state);
  }
}
