import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:isar_community/isar.dart';
import 'db_service.dart';
import '../../utils/logger_helper.dart';
import 'local_json_store.dart';
import 'package:looper_player/features/library/presentation/providers/library/library_notifier.dart';
import 'package:looper_player/features/playback/presentation/providers/equalizer/equalizer_notifier.dart';
import 'package:looper_player/core/utils/l10n.dart';

class ImportExportService {
  // Bumped from 1 -> 2 to add play stats, custom EQ presets and excluded
  // folders. importLibraryData() still accepts a version-1 file - every new
  // section is optional there, defaulting to empty rather than failing.
  static const _backupVersion = 2;

  static Future<void> exportLibraryData(BuildContext context) async {
    LoggerHelper.write(
      'ImportExportService: Starting library backup export...',
    );
    final messenger = ScaffoldMessenger.of(context);
    try {
      // 1. Get all liked songs
      final likedSongs = await DbService.isar.songs
          .filter()
          .isFavoriteEqualTo(true)
          .findAll();
      final favoritesJson = likedSongs
          .map(
            (s) => {
              'path': s.path,
              'title': s.title,
              'artist': s.artist,
              'album': s.album,
            },
          )
          .toList();
      LoggerHelper.write(
        'ImportExportService: Found ${likedSongs.length} favorited songs to export.',
      );

      // 2. Get all playlists
      final playlists = await DbService.isar.playlists.where().findAll();
      final playlistsJson = playlists
          .map(
            (p) => {
              'name': p.name,
              'songPaths': p.songPaths,
              'dateCreated': p.dateCreated.toIso8601String(),
              'dateModified': p.dateModified.toIso8601String(),
            },
          )
          .toList();
      LoggerHelper.write(
        'ImportExportService: Found ${playlists.length} playlists to export.',
      );

      // 3. Play stats - without this, everything the Analyze tab shows
      // (play counts, listening time) silently resets on reinstall/device
      // switch, which was the biggest gap in what this backup covered.
      final playedSongs = await DbService.isar.songs
          .filter()
          .playCountGreaterThan(0)
          .findAll();
      final statsJson = playedSongs
          .map(
            (s) => {
              'path': s.path,
              'title': s.title,
              'artist': s.artist,
              'album': s.album,
              'playCount': s.playCount,
              'totalListenedMs': s.totalListenedMs,
            },
          )
          .toList();
      LoggerHelper.write(
        'ImportExportService: Found ${playedSongs.length} songs with play stats to export.',
      );

      // 4. Custom EQ presets and excluded scan folders - both already store
      // themselves as plain JSON (see LocalJsonStore), so they drop straight
      // into the backup as-is.
      final customEqPresets =
          await LocalJsonStore.read('custom_eq_presets') ?? [];
      final excludedFolders =
          await LocalJsonStore.read('excluded_folders') ?? [];

      // 5. Construct JSON structure
      final backup = {
        'version': _backupVersion,
        'favorites': favoritesJson,
        'playlists': playlistsJson,
        'playStats': statsJson,
        'customEqPresets': customEqPresets,
        'excludedFolders': excludedFolders,
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(backup);

      // 6. Write to temp directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/looper_player_backup.json');
      await file.writeAsString(jsonStr);
      LoggerHelper.write(
        'ImportExportService: Serialised backup written to: ${file.path}',
      );

      // 7. Native Share
      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'Looper Player Backup');
      LoggerHelper.write(
        'ImportExportService: Shared backup file successfully.',
      );
    } catch (e, stack) {
      LoggerHelper.write(
        'ImportExportService: Failed to export library data',
        e,
        stack,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(currentL10n().backupExportFailed),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  static Future<void> importLibraryData(
    BuildContext context,
    WidgetRef ref,
  ) async {
    LoggerHelper.write(
      'ImportExportService: Starting library backup import...',
    );
    final messenger = ScaffoldMessenger.of(context);
    try {
      // 1. Pick file
      final result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.path == null) {
        LoggerHelper.write(
          'ImportExportService: Import cancelled by user (no file selected).',
        );
        return;
      }

      final filePath = result.path!;
      LoggerHelper.write('ImportExportService: User selected file: $filePath');

      final file = File(filePath);
      final content = await file.readAsString();
      final Map<String, dynamic> backup = jsonDecode(content);

      if (backup['version'] != 1 && backup['version'] != 2) {
        throw 'Unsupported backup version: ${backup['version']}';
      }

      final favoritesMerged = await _importFavorites(backup);
      final playlistsCreated = await _importPlaylists(backup);
      final statsMerged = await _importPlayStats(backup);
      await _importCustomEqPresets(ref, backup);
      await _importExcludedFolders(ref, backup);

      // Trigger Library ref scan / updates to sync UI
      ref
          .read(libraryProvider.notifier)
          .scanSavedFolders(showVisualIndicator: false);

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            currentL10n().backupImportedSummary(
              favoritesMerged,
              statsMerged,
              playlistsCreated,
            ),
          ),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e, stack) {
      LoggerHelper.write(
        'ImportExportService: Failed to import library data',
        e,
        stack,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(currentL10n().backupImportFailed),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Finds the local song a backup entry refers to: by path first, falling
  /// back to title+artist since a restored/moved library can have drifted
  /// paths (different drive letter, re-mounted SD card, ...).
  static Future<Song?> _findSong(Map<String, dynamic> entry) async {
    final path = entry['path'] as String?;
    final title = entry['title'] as String?;
    final artist = entry['artist'] as String?;
    if (path == null) return null;

    final byPath = await DbService.isar.songs
        .filter()
        .pathEqualTo(path)
        .findFirst();
    if (byPath != null) return byPath;

    if (title != null && artist != null) {
      return DbService.isar.songs
          .filter()
          .titleEqualTo(title)
          .and()
          .artistEqualTo(artist)
          .findFirst();
    }
    return null;
  }

  static Future<int> _importFavorites(Map<String, dynamic> backup) async {
    final favorites = backup['favorites'] as List<dynamic>? ?? [];
    LoggerHelper.write(
      'ImportExportService: Parsing ${favorites.length} favorited songs from backup.',
    );

    // Collected into one batch instead of a writeTxn per song - each
    // separate transaction used to add up on a large backup for no benefit,
    // since nothing here depends on a previous entry's write succeeding.
    final toUpdate = <Song>[];
    for (final fav in favorites) {
      final song = await _findSong(fav as Map<String, dynamic>);
      if (song != null && !song.isFavorite) {
        song.isFavorite = true;
        toUpdate.add(song);
      }
    }
    if (toUpdate.isNotEmpty) {
      await DbService.isar.writeTxn(
        () => DbService.isar.songs.putAll(toUpdate),
      );
    }
    LoggerHelper.write(
      'ImportExportService: Merged ${toUpdate.length} favorites.',
    );
    return toUpdate.length;
  }

  static Future<int> _importPlaylists(Map<String, dynamic> backup) async {
    final playlists = backup['playlists'] as List<dynamic>? ?? [];
    LoggerHelper.write(
      'ImportExportService: Parsing ${playlists.length} playlists from backup.',
    );

    final toPut = <Playlist>[];
    for (final pl in playlists) {
      final entry = pl as Map<String, dynamic>;
      final name = entry['name'] as String?;
      final songPaths = List<String>.from(entry['songPaths'] ?? []);
      final dateCreatedStr = entry['dateCreated'] as String?;
      final dateModifiedStr = entry['dateModified'] as String?;
      if (name == null || name.isEmpty) continue;

      final dateCreated = dateCreatedStr != null
          ? DateTime.parse(dateCreatedStr)
          : DateTime.now();

      var playlist = await DbService.isar.playlists
          .filter()
          .nameEqualTo(name)
          .findFirst();
      if (playlist == null) {
        playlist = Playlist()
          ..name = name
          ..songPaths = songPaths
          ..dateCreated = dateCreated
          ..dateModified = dateModifiedStr != null
              ? DateTime.parse(dateModifiedStr)
              : DateTime.now();
      } else {
        final mergedPaths = Set<String>.from(playlist.songPaths)
          ..addAll(songPaths);
        playlist.songPaths = mergedPaths.toList();
        playlist.dateModified = DateTime.now();
      }
      toPut.add(playlist);
    }
    if (toPut.isNotEmpty) {
      await DbService.isar.writeTxn(
        () => DbService.isar.playlists.putAll(toPut),
      );
    }
    LoggerHelper.write(
      'ImportExportService: Synced ${toPut.length} playlists.',
    );
    return toPut.length;
  }

  static Future<int> _importPlayStats(Map<String, dynamic> backup) async {
    final stats = backup['playStats'] as List<dynamic>? ?? [];
    if (stats.isEmpty) return 0;
    LoggerHelper.write(
      'ImportExportService: Parsing ${stats.length} play-stat entries from backup.',
    );

    final toUpdate = <Song>[];
    for (final entry in stats) {
      final map = entry as Map<String, dynamic>;
      final song = await _findSong(map);
      if (song == null) continue;

      // Take the higher of the two rather than overwriting outright - a
      // restore should never make a song look *less* played than it
      // actually is on this device.
      final importedPlayCount = map['playCount'] as int? ?? 0;
      final importedListenedMs = map['totalListenedMs'] as int? ?? 0;
      final changed =
          importedPlayCount > song.playCount ||
          importedListenedMs > song.totalListenedMs;
      if (!changed) continue;

      song.playCount = importedPlayCount > song.playCount
          ? importedPlayCount
          : song.playCount;
      song.totalListenedMs = importedListenedMs > song.totalListenedMs
          ? importedListenedMs
          : song.totalListenedMs;
      toUpdate.add(song);
    }
    if (toUpdate.isNotEmpty) {
      await DbService.isar.writeTxn(
        () => DbService.isar.songs.putAll(toUpdate),
      );
    }
    LoggerHelper.write(
      'ImportExportService: Merged play stats for ${toUpdate.length} songs.',
    );
    return toUpdate.length;
  }

  static Future<void> _importCustomEqPresets(
    WidgetRef ref,
    Map<String, dynamic> backup,
  ) async {
    final raw = backup['customEqPresets'] as List<dynamic>? ?? [];
    if (raw.isEmpty) return;
    final imported = raw
        .whereType<Map<String, dynamic>>()
        .map(CustomEqPreset.fromJson)
        .toList();
    await ref.read(customEqPresetsProvider.notifier).mergeFrom(imported);
  }

  static Future<void> _importExcludedFolders(
    WidgetRef ref,
    Map<String, dynamic> backup,
  ) async {
    final raw = backup['excludedFolders'] as List<dynamic>? ?? [];
    if (raw.isEmpty) return;
    await ref
        .read(excludedFoldersProvider.notifier)
        .mergeFrom(raw.whereType<String>().toList());
  }
}
