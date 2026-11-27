import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/features/library/presentation/providers/library/library_notifier.dart';
import 'package:isar_community/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
export 'category_detail_wrapper.dart';
export 'albums_grid_view.dart';
export 'artists_grid_view.dart';
export 'genres_grid_view.dart';
export 'folders_list_view.dart';

part 'library_categories_views.g.dart';

enum AlbumSortOption {
  nameAsc,
  nameDesc,
  dateAddedNewest,
  dateAddedOldest,
  yearNewest,
  yearOldest,
  songCountDesc,
  songCountAsc,
  mostPlayed,
  recentlyPlayed,
}

enum ArtistSortOption {
  nameAsc,
  nameDesc,
  songCountDesc,
  songCountAsc,
  dateAddedNewest,
  dateAddedOldest,
  mostPlayed,
  recentlyPlayed,
}

enum GenreSortOption {
  nameAsc,
  nameDesc,
  songCountDesc,
  songCountAsc,
  dateAddedNewest,
  dateAddedOldest,
  mostPlayed,
  recentlyPlayed,
}

typedef _SongStats = ({
  int count,
  int playCount,
  DateTime? lastPlayed,
  DateTime? latestAdded,
  DateTime? oldestAdded,
});

Map<String, _SongStats> _aggregateSongStats(
  List<Song> songs,
  String? Function(Song) keyOf,
) {
  final counts = <String, int>{};
  final plays = <String, int>{};
  final lastPlayed = <String, DateTime>{};
  final latestAdded = <String, DateTime>{};
  final oldestAdded = <String, DateTime>{};
  for (final s in songs) {
    final k = (keyOf(s) ?? '').trim().toLowerCase();
    if (k.isEmpty) continue;
    counts[k] = (counts[k] ?? 0) + 1;
    plays[k] = (plays[k] ?? 0) + s.playCount;
    final lp = s.lastPlayed;
    if (lp != null) {
      final cur = lastPlayed[k];
      if (cur == null || lp.isAfter(cur)) lastPlayed[k] = lp;
    }
    final da = s.dateAdded;
    final curMax = latestAdded[k];
    if (curMax == null || da.isAfter(curMax)) latestAdded[k] = da;
    final curMin = oldestAdded[k];
    if (curMin == null || da.isBefore(curMin)) oldestAdded[k] = da;
  }
  return {
    for (final k in counts.keys)
      k: (
        count: counts[k] ?? 0,
        playCount: plays[k] ?? 0,
        lastPlayed: lastPlayed[k],
        latestAdded: latestAdded[k],
        oldestAdded: oldestAdded[k],
      ),
  };
}

int _compareByDateDesc(DateTime? a, DateTime? b, String nameA, String nameB) {
  if (a == null && b == null) {
    return nameA.toLowerCase().compareTo(nameB.toLowerCase());
  }
  if (a == null) return 1;
  if (b == null) return -1;
  final cmp = b.compareTo(a);
  return cmp != 0 ? cmp : nameA.toLowerCase().compareTo(nameB.toLowerCase());
}

int _compareByDateAsc(DateTime? a, DateTime? b, String nameA, String nameB) {
  if (a == null && b == null) {
    return nameA.toLowerCase().compareTo(nameB.toLowerCase());
  }
  if (a == null) return 1;
  if (b == null) return -1;
  final cmp = a.compareTo(b);
  return cmp != 0 ? cmp : nameA.toLowerCase().compareTo(nameB.toLowerCase());
}

void sortGenresList(
  List<String> genres,
  Map<String, List<Song>> genresMap,
  GenreSortOption sortOption,
) {
  switch (sortOption) {
    case GenreSortOption.nameAsc:
      genres.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    case GenreSortOption.nameDesc:
      genres.sort((a, b) => b.toLowerCase().compareTo(a.toLowerCase()));
    case GenreSortOption.songCountDesc:
      genres.sort(
        (a, b) => genresMap[b]!.length.compareTo(genresMap[a]!.length),
      );
    case GenreSortOption.songCountAsc:
      genres.sort(
        (a, b) => genresMap[a]!.length.compareTo(genresMap[b]!.length),
      );
    case GenreSortOption.dateAddedNewest:
      DateTime latest(String g) => genresMap[g]!
          .map((s) => s.dateAdded)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      genres.sort((a, b) => latest(b).compareTo(latest(a)));
    case GenreSortOption.dateAddedOldest:
      DateTime oldest(String g) => genresMap[g]!
          .map((s) => s.dateAdded)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      genres.sort((a, b) => oldest(a).compareTo(oldest(b)));
    case GenreSortOption.mostPlayed:
      int plays(String g) =>
          genresMap[g]!.fold(0, (sum, s) => sum + s.playCount);
      genres.sort((a, b) => plays(b).compareTo(plays(a)));
    case GenreSortOption.recentlyPlayed:
      DateTime? last(String g) => genresMap[g]!
          .map((s) => s.lastPlayed)
          .whereType<DateTime>()
          .fold<DateTime?>(
            null,
            (cur, d) => cur == null || d.isAfter(cur) ? d : cur,
          );
      genres.sort((a, b) => _compareByDateDesc(last(a), last(b), a, b));
  }
}

void sortAlbumsList(
  List<Album> albums,
  List<Song> songs,
  AlbumSortOption sortOption,
) {
  switch (sortOption) {
    case AlbumSortOption.nameAsc:
      albums.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    case AlbumSortOption.nameDesc:
      albums.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    case AlbumSortOption.dateAddedNewest:
      albums.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    case AlbumSortOption.dateAddedOldest:
      albums.sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
    case AlbumSortOption.yearNewest:
      albums.sort((a, b) {
        if (a.year == null && b.year == null) return 0;
        if (a.year == null) return 1;
        if (b.year == null) return -1;
        return b.year!.compareTo(a.year!);
      });
    case AlbumSortOption.yearOldest:
      albums.sort((a, b) {
        if (a.year == null && b.year == null) return 0;
        if (a.year == null) return 1;
        if (b.year == null) return -1;
        return a.year!.compareTo(b.year!);
      });
    case AlbumSortOption.songCountDesc:
    case AlbumSortOption.songCountAsc:
    case AlbumSortOption.mostPlayed:
    case AlbumSortOption.recentlyPlayed:
      final stats = _aggregateSongStats(songs, (s) => s.album);
      albums.sort((a, b) {
        final sa = stats[a.name.trim().toLowerCase()];
        final sb = stats[b.name.trim().toLowerCase()];
        return switch (sortOption) {
          AlbumSortOption.songCountDesc => (sb?.count ?? 0) != (sa?.count ?? 0)
              ? (sb?.count ?? 0).compareTo(sa?.count ?? 0)
              : a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          AlbumSortOption.songCountAsc => (sa?.count ?? 0) != (sb?.count ?? 0)
              ? (sa?.count ?? 0).compareTo(sb?.count ?? 0)
              : a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          AlbumSortOption.mostPlayed => (sb?.playCount ?? 0) !=
                  (sa?.playCount ?? 0)
              ? (sb?.playCount ?? 0).compareTo(sa?.playCount ?? 0)
              : a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          AlbumSortOption.recentlyPlayed => _compareByDateDesc(
              sa?.lastPlayed,
              sb?.lastPlayed,
              a.name,
              b.name,
            ),
          _ => 0,
        };
      });
  }
}

void sortArtistsList(
  List<Artist> artists,
  List<Song> songs,
  ArtistSortOption sortOption,
) {
  if (sortOption == ArtistSortOption.nameAsc) {
    artists.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return;
  }
  if (sortOption == ArtistSortOption.nameDesc) {
    artists.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    return;
  }
  final stats = _aggregateSongStats(songs, (s) => s.artist);
  artists.sort((a, b) {
    final sa = stats[a.name.trim().toLowerCase()];
    final sb = stats[b.name.trim().toLowerCase()];
    return switch (sortOption) {
      ArtistSortOption.songCountDesc => (sb?.count ?? 0) != (sa?.count ?? 0)
          ? (sb?.count ?? 0).compareTo(sa?.count ?? 0)
          : a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      ArtistSortOption.songCountAsc => (sa?.count ?? 0) != (sb?.count ?? 0)
          ? (sa?.count ?? 0).compareTo(sb?.count ?? 0)
          : a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      ArtistSortOption.dateAddedNewest => _compareByDateDesc(
          sa?.latestAdded,
          sb?.latestAdded,
          a.name,
          b.name,
        ),
      ArtistSortOption.dateAddedOldest => _compareByDateAsc(
          sa?.oldestAdded,
          sb?.oldestAdded,
          a.name,
          b.name,
        ),
      ArtistSortOption.mostPlayed => (sb?.playCount ?? 0) !=
              (sa?.playCount ?? 0)
          ? (sb?.playCount ?? 0).compareTo(sa?.playCount ?? 0)
          : a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      ArtistSortOption.recentlyPlayed => _compareByDateDesc(
          sa?.lastPlayed,
          sb?.lastPlayed,
          a.name,
          b.name,
        ),
      _ => 0,
    };
  });
}

/// Memoized per sort option so switching screens/rebuilding this view
/// doesn't tear down and recreate the underlying Isar watch (which briefly
/// re-shows the loading state) - the previous inline `switch` in
/// AlbumsGridView.build() opened a brand-new Stream on every rebuild.
@Riverpod(keepAlive: true)
Stream<List<Album>> albumsSorted(Ref ref, AlbumSortOption sortOption) {
  switch (sortOption) {
    case AlbumSortOption.nameAsc:
      return DbService.isar.albums.where().sortByName().watch(
        fireImmediately: true,
      );
    case AlbumSortOption.nameDesc:
      return DbService.isar.albums.where().sortByNameDesc().watch(
        fireImmediately: true,
      );
    case AlbumSortOption.dateAddedNewest:
      return DbService.isar.albums.where().sortByDateAddedDesc().watch(
        fireImmediately: true,
      );
    case AlbumSortOption.dateAddedOldest:
      return DbService.isar.albums.where().sortByDateAdded().watch(
        fireImmediately: true,
      );
    case AlbumSortOption.yearNewest:
      return DbService.isar.albums.where().sortByYearDesc().watch(
        fireImmediately: true,
      );
    case AlbumSortOption.yearOldest:
      return DbService.isar.albums.where().sortByYear().watch(
        fireImmediately: true,
      );
    case AlbumSortOption.songCountDesc:
    case AlbumSortOption.songCountAsc:
    case AlbumSortOption.mostPlayed:
    case AlbumSortOption.recentlyPlayed:
      final songs = ref.watch(libraryProvider.select((s) => s.songs));
      return DbService.isar.albums.where().watch(fireImmediately: true).map((
        list,
      ) {
        final sorted = List<Album>.from(list);
        sortAlbumsList(sorted, songs, sortOption);
        return sorted;
      });
  }
}

/// Memoized on the library's artist list + sort option, instead of
/// re-sorting the full artist list on every rebuild of ArtistsGridView.
@Riverpod(keepAlive: true)
List<Artist> artistsSorted(Ref ref, ArtistSortOption sortOption) {
  final artists = ref.watch(libraryProvider.select((s) => s.artists));
  final sorted = List<Artist>.from(artists);
  final songs =
      (sortOption == ArtistSortOption.nameAsc ||
          sortOption == ArtistSortOption.nameDesc)
      ? const <Song>[]
      : ref.watch(libraryProvider.select((s) => s.songs));
  sortArtistsList(sorted, songs, sortOption);
  return sorted;
}
