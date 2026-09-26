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
}

enum ArtistSortOption { nameAsc, nameDesc }

enum GenreSortOption { nameAsc, nameDesc, songCountDesc, songCountAsc }

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
  }
}

/// Memoized on the library's artist list + sort option, instead of
/// re-sorting the full artist list on every rebuild of ArtistsGridView.
@Riverpod(keepAlive: true)
List<Artist> artistsSorted(Ref ref, ArtistSortOption sortOption) {
  final artists = ref.watch(libraryProvider.select((s) => s.artists));
  final sorted = List<Artist>.from(artists);
  if (sortOption == ArtistSortOption.nameAsc) {
    sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  } else {
    sorted.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
  }
  return sorted;
}
