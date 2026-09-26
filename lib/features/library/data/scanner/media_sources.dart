part of 'scanner.dart';

extension _ScannerMediaSources on LibraryScanner {
  Future<List<Map<String, dynamic>>?> _queryMediaStoreNative({
    required bool includeSystemAndMessagingAudio,
  }) async {
    if (!Platform.isAndroid) return null;

    final cachedAt = LibraryScanner._cachedMediaStoreAt;
    if (cachedAt != null &&
        LibraryScanner._cachedMediaStoreFlag ==
            includeSystemAndMessagingAudio &&
        DateTime.now().difference(cachedAt) <
            LibraryScanner._mediaStoreCacheTtl) {
      return LibraryScanner._cachedMediaStoreItems;
    }

    try {
      final List<dynamic>? rawList = await LibraryScanner._broadcastChannel
          .invokeMethod<List<dynamic>>('queryMediaStore', {
            'minDurationMs': LibraryScanner.minDurationMs,
            'minSizeBytes': LibraryScanner.minSizeBytes,
            'includeSystemAndMessagingAudio': includeSystemAndMessagingAudio,
          });
      if (rawList == null) return null;
      final items = rawList
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      LibraryScanner._cachedMediaStoreItems = items;
      LibraryScanner._cachedMediaStoreFlag = includeSystemAndMessagingAudio;
      LibraryScanner._cachedMediaStoreAt = DateTime.now();
      return items;
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> _querySafFiles() async {
    if (!Platform.isAndroid) return const [];

    final cachedAt = LibraryScanner._cachedSafFilesAt;
    if (cachedAt != null &&
        DateTime.now().difference(cachedAt) <
            LibraryScanner._safFilesCacheTtl) {
      return LibraryScanner._cachedSafFiles ?? const [];
    }

    final files = await SafFolderService.listAudioFiles(supportedExtensions);
    LibraryScanner._cachedSafFiles = files;
    LibraryScanner._cachedSafFilesAt = DateTime.now();
    return files;
  }

  Future<List<String>> _loadExcludedFolders() async {
    final raw = await LocalJsonStore.read(LibraryScanner._excludedFoldersKey);
    if (raw is! List) return const [];
    return raw.whereType<String>().toList();
  }
}
