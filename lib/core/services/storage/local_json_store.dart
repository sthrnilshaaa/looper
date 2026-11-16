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
  static final Map<String, dynamic> _memoryCache = {};

  static Future<Directory> _getDir() async {
    if (_dir != null) return _dir!;
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'local_prefs'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return _dir = dir;
  }

  /// Initializes the store and preloads critical startup keys into memory.
  static Future<void> init([List<String> preloadKeys = const []]) async {
    try {
      final dir = await _getDir();
      for (final key in preloadKeys) {
        final file = File(p.join(dir.path, '$key.json'));
        if (await file.exists()) {
          try {
            final content = await file.readAsString();
            _memoryCache[key] = jsonDecode(content);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  /// Synchronous read from memory cache if preloaded or previously read/written.
  static dynamic readSync(String key) => _memoryCache[key];

  /// Reads the JSON value stored under [key], or null if it's missing or
  /// unreadable. Checks in-memory cache first.
  static Future<dynamic> read(String key) async {
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key];
    }
    try {
      final dir = await _getDir();
      final file = File(p.join(dir.path, '$key.json'));
      if (!await file.exists()) return null;
      final val = jsonDecode(await file.readAsString());
      _memoryCache[key] = val;
      return val;
    } catch (e) {
      return null;
    }
  }

  /// Writes [value] (anything `jsonEncode` supports) under [key].
  static Future<void> write(String key, dynamic value) async {
    _memoryCache[key] = value;
    try {
      final dir = await _getDir();
      final file = File(p.join(dir.path, '$key.json'));
      await file.writeAsString(jsonEncode(value));
    } catch (e) {
      // Best-effort, like LyricsCache - losing a recent-search list or a
      // custom EQ preset isn't worth surfacing an error to the user for.
    }
  }

  /// Deletes the file stored under [key].
  static Future<void> delete(String key) async {
    _memoryCache.remove(key);
    try {
      final dir = await _getDir();
      final file = File(p.join(dir.path, '$key.json'));
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
