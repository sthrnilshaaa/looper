import 'package:isar_community/isar.dart';
import 'package:looper_player/core/db_service.dart';
import 'package:looper_player/features/library/domain/models/models.dart';

class PlaylistService {
  static Future<void> addSongToPlaylist(Playlist playlist, Song song) async {
    if (playlist.songPaths.contains(song.path)) return;

    final updatedPaths = List<String>.from(playlist.songPaths)..add(song.path);

    await DbService.isar.writeTxn(() async {
      playlist.songPaths = updatedPaths;
      playlist.dateModified = DateTime.now();
      await DbService.isar.playlists.put(playlist);
    });
  }

  /// Bulk form of [addSongToPlaylist] for multi-select: one write for the
  /// whole batch instead of one per song.
  static Future<void> addSongsToPlaylist(
    Playlist playlist,
    List<Song> songs,
  ) async {
    final existing = playlist.songPaths.toSet();
    // Set.add() returns false for a path already seen, so this filters out
    // both paths already in the playlist and duplicates within `songs`
    // itself in one pass instead of a separate dedupe step.
    final newPaths = songs
        .map((s) => s.path)
        .where((path) => existing.add(path))
        .toList();
    if (newPaths.isEmpty) return;

    final updatedPaths = List<String>.from(playlist.songPaths)
      ..addAll(newPaths);

    await DbService.isar.writeTxn(() async {
      playlist.songPaths = updatedPaths;
      playlist.dateModified = DateTime.now();
      await DbService.isar.playlists.put(playlist);
    });
  }

  static Future<void> removeSongFromPlaylist(
    Playlist playlist,
    Song song,
  ) async {
    final updatedPaths = List<String>.from(playlist.songPaths)
      ..remove(song.path);

    await DbService.isar.writeTxn(() async {
      playlist.songPaths = updatedPaths;
      playlist.dateModified = DateTime.now();
      await DbService.isar.playlists.put(playlist);
    });
  }

  /// Moves the song at [oldIndex] to [newIndex] within [playlist]'s order.
  static Future<void> reorderSong(
    Playlist playlist,
    int oldIndex,
    int newIndex,
  ) async {
    if (oldIndex < 0 || oldIndex >= playlist.songPaths.length) return;
    // ReorderableListView reports newIndex as if the dragged item were
    // still in the list, so shift it back by one when moving downward -
    // the same adjustment PlaybackNotifier.reorderQueue applies for the
    // queue's own drag-to-reorder.
    if (newIndex > oldIndex) newIndex -= 1;

    final updatedPaths = List<String>.from(playlist.songPaths);
    final path = updatedPaths.removeAt(oldIndex);
    updatedPaths.insert(newIndex, path);

    await DbService.isar.writeTxn(() async {
      playlist.songPaths = updatedPaths;
      playlist.dateModified = DateTime.now();
      await DbService.isar.playlists.put(playlist);
    });
  }

  static Future<List<Playlist>> getAllPlaylists() async {
    return await DbService.isar.playlists
        .where()
        .sortByDateModifiedDesc()
        .findAll();
  }
}
