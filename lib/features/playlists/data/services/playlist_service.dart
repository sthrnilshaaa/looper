import 'dart:io';

import 'package:isar_community/isar.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:looper_player/core/services/storage/db_service.dart';

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

  /// Creates a playlist called [name] already holding [songs], in one
  /// write. Duplicate songs are kept once, in their first position.
  static Future<Playlist> createWithSongs(String name, List<Song> songs) async {
    final now = DateTime.now();
    final playlist = Playlist()
      ..name = name
      ..songPaths = {for (final song in songs) song.path}.toList()
      ..dateCreated = now
      ..dateModified = now;
    await DbService.isar.writeTxn(() => DbService.isar.playlists.put(playlist));
    return playlist;
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

  /// Sets [playlist]'s cover to a copy of [sourcePath] (the picker's copy
  /// can be cleaned up by the system), or back to song covers when null.
  /// A fresh file name each time so image caches never show the old one.
  static Future<bool> setCover(Playlist playlist, String? sourcePath) async {
    String? newPath;
    if (sourcePath != null) {
      try {
        final dir = Directory(
          p.join(
            (await getApplicationSupportDirectory()).path,
            'playlist_covers',
          ),
        );
        await dir.create(recursive: true);
        final ext = p.extension(sourcePath).isEmpty
            ? '.jpg'
            : p.extension(sourcePath);
        newPath = p.join(
          dir.path,
          '${playlist.id}_${DateTime.now().millisecondsSinceEpoch}$ext',
        );
        await File(sourcePath).copy(newPath);
      } catch (_) {
        return false;
      }
    }
    final old = playlist.coverPath;
    await DbService.isar.writeTxn(() async {
      playlist.coverPath = newPath;
      playlist.dateModified = DateTime.now();
      await DbService.isar.playlists.put(playlist);
    });
    await deleteCoverFile(old);
    return true;
  }

  static Future<void> deleteCoverFile(String? path) async {
    if (path == null) return;
    try {
      await File(path).delete();
    } catch (_) {}
  }
}
