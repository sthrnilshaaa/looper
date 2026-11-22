import 'dart:io';
import 'package:flutter/services.dart';
import 'package:looper_player/core/services/update/linux_updater.dart';

/// Outcome of handing an APK to the system installer.
enum ApkInstallStatus { success, aborted, storage, failed }

/// Dart side of the github flavor's native APK installer
/// (android/app/src/github/.../InAppUpdater.kt). The Play build has no such
/// code, so everything here is gated on [supported].
class ApkInstaller {
  static const _channel = MethodChannel('com.looper.player/updates');

  /// Builds that install their own updates: the Android `github` flavor and
  /// released Linux packages.
  static bool get supported =>
      (Platform.isAndroid && appFlavor == 'github') ||
      (Platform.isLinux && LinuxUpdater.kind != null);

  /// The device's ABIs, most preferred first.
  static Future<List<String>> supportedAbis() async {
    try {
      return await _channel.invokeListMethod<String>('getSupportedAbis') ??
          const [];
    } catch (_) {
      return const [];
    }
  }

  /// Opens the system install dialog for the APK at [path] and completes when
  /// the user answers it or the install fails.
  static Future<({ApkInstallStatus status, String? message})> install(
    String path,
  ) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'installApk',
        {'path': path},
      );
      final status = switch (result?['status']) {
        'success' => ApkInstallStatus.success,
        'aborted' => ApkInstallStatus.aborted,
        'storage' => ApkInstallStatus.storage,
        _ => ApkInstallStatus.failed,
      };
      return (status: status, message: result?['message'] as String?);
    } catch (e) {
      return (status: ApkInstallStatus.failed, message: e.toString());
    }
  }
}
