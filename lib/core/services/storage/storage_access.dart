import 'dart:io';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// "All files access" (MANAGE_EXTERNAL_STORAGE) for the Android `github`
/// flavor only. The permission is declared in
/// android/app/src/github/AndroidManifest.xml, never in main/ or play/.
///
/// Two independent gates keep it off the Play build: the Dart flavor
/// (appFlavor == 'github'; null/unflavored counts as Play) and the installed
/// manifest itself, read natively via getAllFilesAccessInfo - a build whose
/// manifest doesn't declare the permission can never offer or request it.
class StorageAccess {
  static const _channel = MethodChannel('com.looper.player/broadcast');

  static bool get _isGithubFlavor =>
      Platform.isAndroid && appFlavor == 'github';

  /// Native facts: real SDK_INT (Dart's Platform.operatingSystemVersion is
  /// the kernel version on Android and carries no API level), whether the
  /// installed manifest declares the permission, and whether it's granted.
  static Future<({int sdkInt, bool declared, bool granted})> _info() async {
    if (!_isGithubFlavor) return (sdkInt: 0, declared: false, granted: false);
    try {
      final info = await _channel.invokeMapMethod<String, dynamic>(
        'getAllFilesAccessInfo',
      );
      return (
        sdkInt: (info?['sdkInt'] as int?) ?? 0,
        declared: info?['declared'] == true,
        granted: info?['granted'] == true,
      );
    } catch (_) {
      return (sdkInt: 0, declared: false, granted: false);
    }
  }

  /// Both welcome-screen facts from a single native round-trip.
  static Future<({bool canOffer, bool granted})> allFilesStatus() async {
    final info = await _info();
    return (
      canOffer: info.declared && info.sdkInt >= 30,
      granted: await _grantedFrom(info),
    );
  }

  /// Whether the welcome screen should offer the All Files Access row. The
  /// permission only exists on Android 11+ (API 30); on Android 10 the github
  /// manifest's requestLegacyExternalStorage covers the same need.
  static Future<bool> canRequestAllFilesAccess() async {
    final info = await _info();
    return info.declared && info.sdkInt >= 30;
  }

  /// True when raw dart:io traversal of the whole storage root and SD cards
  /// is allowed.
  static Future<bool> hasAllFilesAccess() async => _grantedFrom(await _info());

  static Future<bool> _grantedFrom(
    ({int sdkInt, bool declared, bool granted}) info,
  ) async {
    if (!info.declared) return false;
    if (info.sdkInt >= 30) return info.granted;
    try {
      // Android 10: legacy storage + READ_EXTERNAL_STORAGE.
      return await Permission.storage.isGranted;
    } catch (_) {
      return false;
    }
  }

  /// Opens the system "All files access" page for this app. The caller should
  /// re-check hasAllFilesAccess() once the app is resumed.
  static Future<void> requestAllFilesAccess() async {
    if (!await canRequestAllFilesAccess()) return;
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
