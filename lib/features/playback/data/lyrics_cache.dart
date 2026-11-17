import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Per-song lyrics file cache, alongside song.lyrics. Entries (found lyrics
/// or '[source:not_found]') never expire - they last until [clear] or until
/// the user picks another provider for the song.
///
/// Every online provider's answer is also kept on its own
/// ([saveProvider]/[getProvider], under `by_provider/`), so switching
/// providers in the lyrics menu - and back - reuses what was already
/// downloaded instead of asking again. A provider that has nothing for the
/// song is remembered the same way ([saveProviderMiss]), so it isn't asked
/// a second time either.
class LyricsCache {
  /// Tests: the folder used instead of the app's documents folder.
  static Directory? debugDir;

  static Future<Directory> _getCacheDir() async {
    final appDir = debugDir ?? await getApplicationDocumentsDirectory();
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

  static Future<File> _providerFile(
    String artist,
    String title,
    String provider, {
    String extension = 'lrc',
  }) async {
    final dir = Directory(p.join((await _getCacheDir()).path, 'by_provider'));
    if (!await dir.exists()) await dir.create(recursive: true);
    final name = provider.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    return File(
      p.join(dir.path, '${_generateKey(artist, title)}.$name.$extension'),
    );
  }

  /// Remembers that [provider] was asked and has no lyrics for this song.
  static Future<void> saveProviderMiss(
    String artist,
    String title,
    String provider,
  ) async {
    try {
      final file = await _providerFile(
        artist,
        title,
        provider,
        extension: 'none',
      );
      await file.writeAsString('');
    } catch (e) {}
  }

  static Future<bool> isProviderMiss(
    String artist,
    String title,
    String provider,
  ) async {
    try {
      final file = await _providerFile(
        artist,
        title,
        provider,
        extension: 'none',
      );
      return await file.exists();
    } catch (e) {}
    return false;
  }

  /// Forgets every provider's "no lyrics" answer for this artist/title,
  /// so they are asked again. Found lyrics are kept.
  static Future<void> clearProviderMissesFor(
    String artist,
    String title,
  ) async {
    try {
      final dir = Directory(p.join((await _getCacheDir()).path, 'by_provider'));
      if (!await dir.exists()) return;
      final prefix = '${_generateKey(artist, title)}.';
      await for (final file in dir.list()) {
        final name = p.basename(file.path);
        if (file is File && name.startsWith(prefix) && name.endsWith('.none')) {
          await file.delete();
        }
      }
    } catch (_) {}
  }

  /// Drops the saved lyrics of this artist/title (not per-provider copies).
  static Future<void> forget(String artist, String title) async {
    try {
      final dir = await _getCacheDir();
      final file = File(p.join(dir.path, '${_generateKey(artist, title)}.lrc'));
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// Drops [provider]'s saved answer for this artist/title.
  static Future<void> forgetProvider(
    String artist,
    String title,
    String provider,
  ) async {
    try {
      final file = await _providerFile(artist, title, provider);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// Keeps [provider]'s source-tagged answer for this song.
  static Future<void> saveProvider(
    String artist,
    String title,
    String provider,
    String lrc,
  ) async {
    try {
      await (await _providerFile(artist, title, provider)).writeAsString(lrc);
    } catch (e) {}
  }

  static Future<String?> getProvider(
    String artist,
    String title,
    String provider,
  ) async {
    try {
      final file = await _providerFile(artist, title, provider);
      if (await file.exists()) return await file.readAsString();
    } catch (e) {}
    return null;
  }

  /// Moves this song's entries (main and per-provider) to a new
  /// artist/title after a tag edit, so they're still found.
  static Future<void> rename(
    String oldArtist,
    String oldTitle,
    String newArtist,
    String newTitle,
  ) async {
    final from = _generateKey(oldArtist, oldTitle);
    final to = _generateKey(newArtist, newTitle);
    if (from == to) return;
    try {
      final dir = await _getCacheDir();
      for (final folder in [dir, Directory(p.join(dir.path, 'by_provider'))]) {
        if (!await folder.exists()) continue;
        await for (final entry in folder.list()) {
          final name = p.basename(entry.path);
          if (entry is File && name.startsWith('$from.')) {
            await entry.rename(
              p.join(folder.path, '$to${name.substring(from.length)}'),
            );
          }
        }
      }
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

  /// Deletes every cached entry.
  static Future<void> clear() async {
    try {
      final dir = await _getCacheDir();
      await dir.delete(recursive: true);
    } catch (e) {}
  }
}
