import 'package:flutter/services.dart';

/// Thin wrapper around the native Storage Access Framework (SAF) bridge used
/// on Android to let users add an arbitrary folder (including SD cards and
/// custom subfolders) to their library without the MANAGE_EXTERNAL_STORAGE
/// permission, which Play Store policy does not allow for a media-player app.
///
/// The picked folder's read grant is persisted by the OS
/// (ContentResolver.takePersistableUriPermission) and survives app restarts
/// and reboots, so nothing needs to be tracked on the Dart side - every scan
/// simply asks the native side to walk whatever folders are currently
/// granted. See scanner.dart's `_querySafFiles` for how this is merged into
/// a scan alongside the MediaStore query.
class SafFolderService {
  static const MethodChannel _channel = MethodChannel(
    'com.looper.player/broadcast',
  );

  /// Opens the system folder picker (ACTION_OPEN_DOCUMENT_TREE). Returns the
  /// resolved absolute path of the chosen folder, or null if the user
  /// cancelled. Throws a [PlatformException] with code `UNSUPPORTED_PROVIDER`
  /// if the folder picked isn't backed by local/SD storage (e.g. a cloud
  /// provider), since there's no raw path to hand back to the rest of the
  /// scanning pipeline in that case.
  static Future<String?> pickFolder() {
    return _channel.invokeMethod<String>('pickSafFolder');
  }

  /// Recursively lists every file matching [extensions] (e.g. `.mp3`) across
  /// every folder previously granted via [pickFolder], regardless of when
  /// they were added.
  static Future<List<String>> listAudioFiles(List<String> extensions) async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'listSafAudioFiles',
        {'extensions': extensions},
      );
      return result?.cast<String>() ?? const [];
    } catch (_) {
      return const [];
    }
  }

  /// Releases the persisted access grant for a previously-added SAF folder,
  /// e.g. when the user removes it from Settings > Library Folders.
  static Future<void> releaseFolder(String path) async {
    try {
      await _channel.invokeMethod('releaseSafFolder', {'path': path});
    } catch (_) {}
  }
}
