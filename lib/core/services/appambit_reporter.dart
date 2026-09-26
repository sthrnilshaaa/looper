import 'dart:io';

import 'package:appambit_sdk_flutter/appambit_sdk_flutter.dart';
import 'package:flutter/widgets.dart';

/// Keeps AppAmbit traffic bounded and avoids starting it in keyless builds.
class AppAmbitReporter {
  static const _appKey = String.fromEnvironment('APPAMBIT_APP_KEY');
  static const _enabled = bool.fromEnvironment(
    'APPAMBIT_ENABLED',
    defaultValue: true,
  );
  static const _navigationEnabled = bool.fromEnvironment(
    'APPAMBIT_NAVIGATION_ENABLED',
    defaultValue: false,
  );
  static const _maxErrorsPerHour = int.fromEnvironment(
    'APPAMBIT_MAX_ERRORS_PER_HOUR',
    defaultValue: 5,
  );
  static const _duplicateWindow = Duration(minutes: 15);
  static const _budgetWindow = Duration(hours: 1);

  static final List<DateTime> _reportedAt = [];
  static final Map<String, DateTime> _lastReportByFingerprint = {};
  static bool _started = false;

  static bool get isStarted => _started;

  static List<NavigatorObserver> get navigatorObservers =>
      _started && _navigationEnabled
      ? <NavigatorObserver>[AppAmbitSdk()]
      : const [];

  static Future<void> start() async {
    if (!_enabled ||
        _appKey.trim().isEmpty ||
        !(Platform.isAndroid || Platform.isIOS)) {
      return;
    }

    await AppAmbitSdk.start(appKey: _appKey.trim());
    _started = true;
  }

  static Future<void> reportError({
    required String message,
    dynamic exception,
    StackTrace? stackTrace,
  }) async {
    if (!_started || _maxErrorsPerHour <= 0) return;

    final now = DateTime.now();
    final budgetCutoff = now.subtract(_budgetWindow);
    _reportedAt.removeWhere((timestamp) => timestamp.isBefore(budgetCutoff));
    if (_reportedAt.length >= _maxErrorsPerHour) return;

    final fingerprint = _fingerprint(message, exception);
    final lastReport = _lastReportByFingerprint[fingerprint];
    if (lastReport != null && now.difference(lastReport) < _duplicateWindow) {
      return;
    }

    // Reserve the slot before the asynchronous platform call so simultaneous
    // failures cannot race past the request budget.
    _reportedAt.add(now);
    _lastReportByFingerprint[fingerprint] = now;
    _lastReportByFingerprint.removeWhere(
      (_, timestamp) => timestamp.isBefore(now.subtract(_duplicateWindow)),
    );

    try {
      await AppAmbitSdk.logError(
        message: message,
        exception: exception,
        stackTrace: stackTrace ?? StackTrace.current,
      );
    } catch (_) {
      // Telemetry must never affect playback or app startup.
    }
  }

  static String _fingerprint(String message, dynamic exception) {
    final errorType = exception?.runtimeType.toString() ?? 'unknown';
    final normalizedMessage = message.replaceAll(RegExp(r'\d+'), '#');
    return '$errorType:$normalizedMessage';
  }
}
