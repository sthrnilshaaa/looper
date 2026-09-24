import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:looper_player/core/app_links.dart';
import 'package:looper_player/core/local_json_store.dart';
import 'package:looper_player/core/providers.dart';

import 'package:package_info_plus/package_info_plus.dart';

class UpdateService {
  static const repoUrl = AppLinks.githubReleasesApi;
  static const fallbackHtmlUrl = AppLinks.githubReleasesWeb;

  static const _channel = MethodChannel('com.looper.player/updates');
  static const _notifiedVersionKey = 'update_notified_version';

  static bool _restartPromptShowing = false;

  /// Checks for a newer release, using whichever source this build is
  /// distributed through:
  ///  - Play build (Android `play` flavor): Google Play's In-App Updates API.
  ///    It never contacts GitHub.
  ///  - GitHub build (Android `github` flavor, and Linux): the latest GitHub
  ///    release. The native side answers 'unsupported' for this flavor.
  static Future<void> checkForUpdates() async {
    if (Platform.isAndroid) {
      _channel.setMethodCallHandler(_onNativeCall);
      if (await _checkPlayUpdate()) return;
    }
    await _checkGitHub();
  }

  static Future<void> _onNativeCall(MethodCall call) async {
    if (call.method == 'onUpdateDownloaded') _showRestartSnackbar();
  }

  /// Runs the Play flow. Returns false only when this build has no Play
  /// integration (github flavor), so the caller should check GitHub instead;
  /// any other outcome - including errors - is final, because a Play build
  /// must not fall back to GitHub.
  static Future<bool> _checkPlayUpdate() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'checkPlayUpdate',
      );
      switch (result?['status']) {
        case 'unsupported':
          return false;
        case 'downloaded':
          _showRestartSnackbar();
        case 'notAllowed' || 'failed':
          // Play won't run its in-app flow here, so point the user at the
          // store listing instead. ('declined' is deliberately silent - the
          // user just said no.)
          await _announce(
            key: 'play:${result?['versionCode']}',
            message: 'A new version is available on Google Play.',
            url: AppLinks.playStoreWeb,
          );
      }
    } catch (e) {}
    return true;
  }

  static Future<void> _checkGitHub() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await http.get(Uri.parse(repoUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String tagName = data['tag_name'] ?? '';
        final String htmlUrl = data['html_url'] ?? fallbackHtmlUrl;

        if (tagName.isNotEmpty && _isUpdateAvailable(currentVersion, tagName)) {
          await _announce(
            key: tagName,
            message: 'Version $tagName is available on GitHub.',
            url: htmlUrl,
          );
        }
      }
    } catch (e) {}
  }

  /// Tells the user an update exists. On Android that is a system
  /// notification, posted once per [key] (a release) so it doesn't repeat on
  /// every launch; if notifications are off, or on the desktop, it falls back
  /// to the snackbar.
  static Future<void> _announce({
    required String key,
    required String message,
    required String url,
  }) async {
    if (Platform.isAndroid) {
      if (await LocalJsonStore.read(_notifiedVersionKey) == key) return;

      final posted = await _channel.invokeMethod<bool>(
        'showUpdateNotification',
        {'title': 'Update available', 'body': message, 'url': url},
      );
      if (posted == true) {
        await LocalJsonStore.write(_notifiedVersionKey, key);
        return;
      }
    }
    _showSnackbar(
      title: 'Update Available!',
      message: message,
      actionLabel: 'VISIT',
      onAction: () async {
        try {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } catch (e) {}
      },
    );
  }

  /// Play finished downloading an update; it takes effect after a restart.
  static void _showRestartSnackbar() {
    if (_restartPromptShowing) return; // resume + launch check can both fire
    _restartPromptShowing = true;
    final controller = _showSnackbar(
      title: 'Update downloaded',
      message: 'Restart Looper Player to install it.',
      actionLabel: 'RESTART',
      duration: const Duration(seconds: 30),
      onAction: () async {
        try {
          await _channel.invokeMethod('completePlayUpdate');
        } catch (e) {}
      },
    );
    if (controller == null) {
      _restartPromptShowing = false;
    } else {
      controller.closed.then((_) => _restartPromptShowing = false);
    }
  }

  static bool _isUpdateAvailable(String current, String latest) {
    // Extract version prefix starting with a number (e.g. 'v1.2.3-rc.1' -> '1.2.3-rc.1', 'release-2.0.0' -> '2.0.0')
    final startVersionRegex = RegExp(r'^\D*(\d+\..*)');
    final currentMatch = startVersionRegex.firstMatch(current);
    final latestMatch = startVersionRegex.firstMatch(latest);

    String cleanCurrent = currentMatch != null
        ? currentMatch.group(1)!
        : current;
    String cleanLatest = latestMatch != null ? latestMatch.group(1)! : latest;

    // Discard build metadata and pre-release identifiers
    cleanCurrent = cleanCurrent.split('+')[0].split('-')[0];
    cleanLatest = cleanLatest.split('+')[0].split('-')[0];

    // Remove any remaining non-digit, non-dot characters
    cleanCurrent = cleanCurrent.replaceAll(RegExp(r'[^0-9.]'), '');
    cleanLatest = cleanLatest.replaceAll(RegExp(r'[^0-9.]'), '');

    List<int> currentParts = cleanCurrent
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    List<int> latestParts = cleanLatest
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();

    int maxLength = currentParts.length > latestParts.length
        ? currentParts.length
        : latestParts.length;
    while (currentParts.length < maxLength) {
      currentParts.add(0);
    }
    while (latestParts.length < maxLength) {
      latestParts.add(0);
    }

    for (int i = 0; i < maxLength; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>?
  _showSnackbar({
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    Duration duration = const Duration(seconds: 10),
  }) {
    final state = scaffoldMessengerKey.currentState;
    if (state == null) return null;

    return state.showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E1E1C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: duration,
        content: Row(
          children: [
            const Icon(Icons.system_update_alt, color: Color(0xFF41C25E)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: actionLabel,
          textColor: const Color(0xFF41C25E),
          onPressed: onAction,
        ),
      ),
    );
  }
}
