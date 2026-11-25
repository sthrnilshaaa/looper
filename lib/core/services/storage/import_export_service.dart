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
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/services/haptics/haptic_snack_bar.dart';
import 'package:looper_player/features/playlists/data/m3u_parser.dart';
import 'package:looper_player/features/playlists/data/playlist_formats.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';

class ImportExportService {
  // Bumped from 1 -> 2 to add play stats, custom EQ presets and excluded
  // folders. importLibraryData() still accepts a version-1 file - every new
  // section is optional there, defaulting to empty rather than failing.
  static const _backupVersion = 3;

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
              'lastPlayed': p.lastPlayed?.toIso8601String(),
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

      // 5. App settings (theme, player, EQ, pins...), as Isar exports them.
      final settingsJson = await DbService.isar.appSettings
          .where()
          .exportJson();

      // 6. Construct JSON structure
      final backup = {
        'version': _backupVersion,
        'favorites': favoritesJson,
        'playlists': playlistsJson,
        'playStats': statsJson,
        'customEqPresets': customEqPresets,
        'excludedFolders': excludedFolders,
        if (settingsJson.isNotEmpty) 'settings': _jsonSafe(settingsJson.first),
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
      messenger.showHapticSnackBar(
        AppHaptics.error,
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
      // Any type: shared or saved copies often lose the JSON MIME type, and
      // the picker then hides them. The content is checked below.
      final result = await FilePicker.pickFile();

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

      if (!const {1, 2, 3}.contains(backup['version'])) {
        throw 'Unsupported backup version: ${backup['version']}';
      }

      final favoritesMerged = await _importFavorites(backup);
      final playlistsCreated = await _importPlaylists(backup);
      final statsMerged = await _importPlayStats(backup);
      await _importCustomEqPresets(ref, backup);
      await _importExcludedFolders(ref, backup);
      final settings = backup['settings'];
      if (settings is Map<String, dynamic> &&
          context.mounted &&
          await _confirmRestoreSettings(context)) {
        await DbService.isar.writeTxn(
          () => DbService.isar.appSettings.importJson([
            {...settings, 'id': 0},
          ]),
        );
        ref.invalidate(settingsProvider);
        LoggerHelper.write('ImportExportService: Settings restored.');
      }

      // Trigger Library ref scan / updates to sync UI
      ref
          .read(libraryProvider.notifier)
          .scanSavedFolders(showVisualIndicator: false);
      messenger.showHapticSnackBar(
        AppHaptics.success,
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
      messenger.showHapticSnackBar(
        AppHaptics.error,
        SnackBar(
          content: Text(currentL10n().backupImportFailed),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Settings > Backups & Logs > Import Playlist, and the Playlists screen:
  /// each picked playlist file (any [PlaylistFormats] format) becomes a new
  /// playlist named after the file
  /// ("Road trip (2)" when that name is taken), holding the tracks that
  /// are in the library, in the file's order.
  static Future<void> importM3uPlaylists(BuildContext context) async {
    LoggerHelper.write('ImportExportService: Starting M3U playlist import...');
    final messenger = ScaffoldMessenger.of(context);
    try {
      // FileType.any, not a custom extension filter: Android has no MIME
      // type for .m3u8 on every version, which makes the filter throw.
      final picked = await FilePicker.pickFiles();
      final files = picked
          .where((f) => f.path != null && PlaylistFormats.isSupported(f.name))
          .toList();

      if (picked.isEmpty) {
        LoggerHelper.write('ImportExportService: M3U import cancelled.');
        return;
      }
      if (files.isEmpty) throw 'No playlist file selected';

      final songs = await DbService.isar.songs.where().findAll();
      final matcher = M3uSongMatcher(songs);
      final taken = (await DbService.isar.playlists.where().findAll())
          .map((p) => p.name)
          .toSet();

      final toPut = <Playlist>[];
      int found = 0;
      int total = 0;
      for (final m3u in files) {
        final file = File(m3u.path!);
        final entries = PlaylistFormats.parse(
          m3u.name,
          await file.readAsBytes(),
        );
        final paths = <String>[];
        for (final entry in entries) {
          final song = matcher.match(entry, playlistDir: file.parent.path);
          if (song != null && !paths.contains(song.path)) paths.add(song.path);
        }
        total += entries.length;
        found += paths.length;
        LoggerHelper.write(
          'ImportExportService: ${m3u.name}: matched ${paths.length} of '
          '${entries.length} entries.',
        );
        if (paths.isEmpty) continue;

        final dot = m3u.name.lastIndexOf('.');
        final baseName = m3u.name.substring(0, dot).trim();
        final name = uniquePlaylistName(
          baseName.isEmpty ? m3u.name : baseName,
          taken,
        );
        taken.add(name);
        final now = DateTime.now();
        toPut.add(
          Playlist()
            ..name = name
            ..songPaths = paths
            ..dateCreated = now
            ..dateModified = now,
        );
      }

      if (toPut.isEmpty) {
        messenger.showHapticSnackBar(
          AppHaptics.error,
          SnackBar(
            content: Text(currentL10n().m3uImportNoSongs),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      await DbService.isar.writeTxn(
        () => DbService.isar.playlists.putAll(toPut),
      );
      messenger.showHapticSnackBar(
        AppHaptics.success,
        SnackBar(
          content: Text(
            toPut.length == 1
                ? currentL10n().m3uImportedSummary(
                    toPut.first.name,
                    found,
                    total,
                  )
                : currentL10n().m3uImportedMany(toPut.length, found, total),
          ),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e, stack) {
      LoggerHelper.write(
        'ImportExportService: Failed to import M3U playlist',
        e,
        stack,
      );
      messenger.showHapticSnackBar(
        AppHaptics.error,
        SnackBar(
          content: Text(currentL10n().m3uImportFailed),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  static Future<bool> _confirmRestoreSettings(BuildContext context) async {
    final l10n = currentL10n();
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF161616),
            title: Text(l10n.restoreSettingsTitle),
            content: Text(l10n.restoreSettingsDesc),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.keepMySettings),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.restoreSettings),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// [json] without non-finite doubles, which JSON cannot hold (unset
  /// settings are NaN; Isar reads a missing key back as unset).
  static Object? _jsonSafe(Object? json) => switch (json) {
    final Map m => {
      for (final e in m.entries)
        if (!(e.value is double && !(e.value as double).isFinite))
          e.key: _jsonSafe(e.value),
    },
    final List l => [
      for (final v in l) v is double && !v.isFinite ? 0.0 : _jsonSafe(v),
    ],
    _ => json,
  };

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
      final lastPlayedStr = entry['lastPlayed'] as String?;
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
      final lastPlayed = lastPlayedStr != null
          ? DateTime.tryParse(lastPlayedStr)
          : null;
      if (lastPlayed != null &&
          (playlist.lastPlayed == null ||
              lastPlayed.isAfter(playlist.lastPlayed!))) {
        playlist.lastPlayed = lastPlayed;
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
