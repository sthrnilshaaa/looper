import 'dart:io';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// "All files access" (MANAGE_EXTERNAL_STORAGE) for the Android `github`
/// flavor only. The permission is declared in
/// android/app/src/github/AndroidManifest.xml, never in main/ or play/, so
/// the Play build can't request it. A build without a flavor (appFlavor ==
/// null) is treated like Play.
class StorageAccess {
  static bool get supportsAllFilesAccess =>
      Platform.isAndroid && appFlavor == 'github';

  static int _sdkInt() {
    try {
      final sdkMatch = RegExp(
        r'API\s+(\d+)',
      ).firstMatch(Platform.operatingSystemVersion);
      if (sdkMatch != null) return int.parse(sdkMatch.group(1)!);
    } catch (_) {}
    return 0;
  }

  /// Whether the welcome screen should offer the All Files Access row. The
  /// permission only exists on Android 11+ (API 30); on Android 10 the github
  /// manifest's requestLegacyExternalStorage covers the same need.
  static bool get canRequestAllFilesAccess =>
      supportsAllFilesAccess && _sdkInt() >= 30;

  /// True when raw dart:io traversal of the whole storage root and SD cards
  /// is allowed.
  static Future<bool> hasAllFilesAccess() async {
    if (!supportsAllFilesAccess) return false;
    try {
      if (_sdkInt() < 30) return await Permission.storage.isGranted;
      return await Permission.manageExternalStorage.isGranted;
    } catch (_) {
      return false;
    }
  }

  /// Opens the system "All files access" page for this app. The caller should
  /// re-check hasAllFilesAccess() once the app is resumed.
  static Future<void> requestAllFilesAccess() async {
    if (!canRequestAllFilesAccess) return;
    try {
      await Permission.manageExternalStorage.request();
    } catch (_) {}
  }

  /// Whole-storage roots to scan when hasAllFilesAccess() is true: internal
  /// storage plus every mounted SD card / USB volume under /storage.
  static Future<List<String>> wholeStorageRoots() async {
    final roots = <String>['/storage/emulated/0'];
    try {
      final storageDir = Directory('/storage');
      if (await storageDir.exists()) {
        await for (final entity in storageDir.list()) {
          final name = entity.path.split('/').last;
          if (entity is Directory &&
              name != 'emulated' &&
              name != 'self' &&
              name != 'knox-emulated' &&
              !roots.contains(entity.path)) {
            roots.add(entity.path);
          }
        }
      }
    } catch (_) {}
    return roots;
  }
}
