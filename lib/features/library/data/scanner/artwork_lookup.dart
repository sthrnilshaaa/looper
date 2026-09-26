part of 'scanner.dart';

extension _ScannerArtwork on LibraryScanner {
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
}
