part of 'scanner.dart';

extension _ScannerMetadata on LibraryScanner {
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
