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
