import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class LyricsCache {
  static Future<Directory> _getCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(p.join(appDir.path, 'lyrics_cache'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  static String _generateKey(String artist, String title) {
    final input =
        '${artist.trim().toLowerCase()}_${title.trim().toLowerCase()}';
    final safeName = input.replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    return '${safeName}_${input.hashCode.abs()}';
  }

  static Future<void> save(String artist, String title, String lrc) async {
    try {
      final dir = await _getCacheDir();
      final key = _generateKey(artist, title);
      final file = File(p.join(dir.path, '$key.lrc'));
      await file.writeAsString(lrc);
    } catch (e) {}
  }

  static Future<String?> get(String artist, String title) async {
    try {
      final dir = await _getCacheDir();
      final key = _generateKey(artist, title);
      final file = File(p.join(dir.path, '$key.lrc'));
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {}
    return null;
  }
}
