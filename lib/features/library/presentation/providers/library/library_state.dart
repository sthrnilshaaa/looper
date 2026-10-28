part of 'library_notifier.dart';

enum SongSortStrategy {
  dateAdded,
  title,
  artist,
  album,
  duration,
  year,
  playCount,
  lastPlayed,

  /// Most listened all the way through (see [songFullPlays]). Appended last:
  /// the index is what settings store.
  fullPlays,
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

  /// The whole song list is loaded. Everything except the Home and Songs
  /// tabs waits for this, so nothing else ever sees a half-loaded library.
  final bool isInitialized;
  final List<Song> songs;

  // Cold-start loading in parts (see Library._loadSongsInParts). Only the
  // Home and Songs tabs read these, and only while [isInitialized] is false;
  // they are emptied once it turns true.

  /// The first small queries are done: the tabs can drop their full-screen
  /// skeleton and fill in part by part.
  final bool previewReady;

  /// The songs loaded so far, in the Songs tab's sort order.
  final List<Song> loadingSongs;

  /// Home's Quick Picks and Recently Added rows, from their own small
  /// queries, so they show before the whole list is loaded.
  final List<Song> previewQuickPicks;
  final List<Song> previewRecentlyAdded;

  /// How many songs the database holds, for the Songs tab's count.
  final int totalSongCount;
  final List<Artist> artists;
  final List<Album> albums;
  final List<Playlist> playlists;
  final SongSortStrategy sortStrategy;
  final bool isAscending;

  LibraryState({
    this.isScanning = false,
    this.isInitialized = false,
    this.songs = const [],
    this.previewReady = false,
    this.loadingSongs = const [],
    this.previewQuickPicks = const [],
    this.previewRecentlyAdded = const [],
    this.totalSongCount = 0,
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
    bool? previewReady,
    List<Song>? loadingSongs,
    List<Song>? previewQuickPicks,
    List<Song>? previewRecentlyAdded,
    int? totalSongCount,
    List<Artist>? artists,
    List<Album>? albums,
    List<Playlist>? playlists,
    SongSortStrategy? sortStrategy,
    bool? isAscending,
  }) {
    final bool initialized = isInitialized ?? this.isInitialized;
    return LibraryState(
      isScanning: isScanning ?? this.isScanning,
      isInitialized: initialized,
      songs: songs ?? this.songs,
      // The part-by-part lists are dropped as soon as the full list is in.
      previewReady: previewReady ?? this.previewReady,
      loadingSongs: initialized
          ? const []
          : (loadingSongs ?? this.loadingSongs),
      previewQuickPicks: initialized
          ? const []
          : (previewQuickPicks ?? this.previewQuickPicks),
      previewRecentlyAdded: initialized
          ? const []
          : (previewRecentlyAdded ?? this.previewRecentlyAdded),
      totalSongCount: totalSongCount ?? this.totalSongCount,
      artists: artists ?? this.artists,
      albums: albums ?? this.albums,
      playlists: playlists ?? this.playlists,
      sortStrategy: sortStrategy ?? this.sortStrategy,
      isAscending: isAscending ?? this.isAscending,
    );
  }
}
