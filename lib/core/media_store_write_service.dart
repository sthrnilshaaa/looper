import 'package:flutter/services.dart';

/// Thin wrapper around the native MediaStore write bridge used on Android to
/// delete, rename, or tag-edit audio files under scoped storage (Android 10+)
/// without the MANAGE_EXTERNAL_STORAGE permission Play Store disallows for a
/// media-player app. Each call may surface a one-time system consent dialog
/// (a RecoverableSecurityException's action intent for a single file, or
/// MediaStore.createDeleteRequest's single batch dialog on API 30+) - see
/// MainActivity.kt's deleteMediaFile/deleteMediaFilesBatch/renameMediaFile/
/// writeMediaTags for the native side of this.
class MediaStoreWriteService {
  static const MethodChannel _channel = MethodChannel(
    'com.looper.player/broadcast',
  );

  /// Deletes a single audio file. Returns false if the user declined the
  /// system consent prompt, or the delete otherwise failed.
  static Future<bool> deleteFile(String path) async {
    try {
      final result = await _channel.invokeMethod<bool>('deleteMediaFile', {
        'path': path,
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Attempts to delete every path in [paths], ideally with a single system
  /// consent dialog (API 30+ only - on API 29 only files this app already
  /// owns are deleted here). Returns the subset of [paths] that were NOT
  /// deleted, for the caller to retry individually via [deleteFile].
  static Future<List<String>> deleteFilesBatch(List<String> paths) async {
    if (paths.isEmpty) return const [];
    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'deleteMediaFiles',
        {'paths': paths},
      );
      return result?.cast<String>() ?? paths;
    } catch (_) {
      return paths;
    }
  }

  /// Renames the underlying file to [newDisplayName] (including extension).
  /// Returns the new absolute path on success, or null if declined/failed.
  static Future<String?> renameFile(
    String path,
    String newDisplayName,
  ) async {
    try {
      return await _channel.invokeMethod<String>('renameMediaFile', {
        'path': path,
        'newDisplayName': newDisplayName,
      });
    } catch (_) {
      return null;
    }
  }

  /// Writes ID3/Vorbis Comment/MP4 tags directly into the audio file. Any
  /// field left null is left untouched. Returns false if declined,
  /// unsupported for the file's format, or otherwise failed - callers should
  /// treat that as a soft failure (the DB-side edit can still stand alone).
  static Future<bool> writeTags(
    String path, {
    String? title,
    String? artist,
    String? album,
    String? genre,
    int? year,
    String? lyrics,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('writeMediaTags', {
        'path': path,
        'title': title,
        'artist': artist,
        'album': album,
        'genre': genre,
        'year': year,
        'lyrics': lyrics,
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
