import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// A tiny per-key JSON file store for small, non-critical UI state that
/// doesn't belong in the Isar schema - custom EQ presets, excluded scan
/// folders, recent searches. Keeping this data here instead of adding
/// fields to the Isar `AppSettings` collection means it never needs a
/// schema migration; losing a file here (a fresh install, a cleared cache)
/// only costs a small convenience, never library data.
///
/// Mirrors the existing LyricsCache pattern: one file per key under the
/// app's documents directory, best-effort read/write.
class LocalJsonStore {
  static Directory? _dir;

  static Future<Directory> _getDir() async {
    if (_dir != null) return _dir!;
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'local_prefs'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return _dir = dir;
  }

  /// Reads the JSON value stored under [key], or null if it's missing or
  /// unreadable.
  static Future<dynamic> read(String key) async {
    try {
      final dir = await _getDir();
      final file = File(p.join(dir.path, '$key.json'));
      if (!await file.exists()) return null;
      return jsonDecode(await file.readAsString());
    } catch (e) {
      return null;
    }
  }

  /// Writes [value] (anything `jsonEncode` supports) under [key].
  static Future<void> write(String key, dynamic value) async {
    try {
      final dir = await _getDir();
      final file = File(p.join(dir.path, '$key.json'));
      await file.writeAsString(jsonEncode(value));
    } catch (e) {
      // Best-effort, like LyricsCache - losing a recent-search list or a
      // custom EQ preset isn't worth surfacing an error to the user for.
    }
  }
}
