import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/appambit_reporter.dart';

class LoggerHelper {
  static File? _logFile;
  static bool _initialized = false;

  // Every file operation (append, rotate, clear) is chained onto this so only
  // one is in flight at a time. Dart's FileMode.append is not O_APPEND: each
  // writeAsString opens the file and seeks to the end as it was at that
  // moment, so overlapping un-awaited writes (mpv's log callback alone can
  // fire several per millisecond) land on the same offset and overwrite each
  // other, leaving torn lines like "arting..." in the log.
  static Future<void> _fileQueue = Future.value();

  static Future<void> _enqueue(Future<void> Function() task) {
    final result = _fileQueue.then((_) => task());
    // The chain itself never carries an error: one failed operation must not
    // wedge every later write. The caller still sees it via `result`.
    _fileQueue = result.catchError((_) {});
    return result;
  }

  static Future<void> init() async {
    if (_initialized) return;
    try {
      final dir = await getApplicationSupportDirectory();
      _logFile = File('${dir.path}/app_logs.txt');
      _initialized = true;

      // Log rotation check (cap at 5MB). Queued rather than run inline
      // because _initialized is already true, so other callers may be
      // appending while this renames the file out from under them.
      await _enqueue(() => _rotateIfNeeded(dir));

      await write('--- Session Started ---');
    } catch (e) {
      debugPrint('Failed to initialize LoggerHelper: $e');
    }
  }

  static Future<void> _rotateIfNeeded(Directory dir) async {
    if (await _logFile!.exists()) {
      final size = await _logFile!.length();
      if (size > 5 * 1024 * 1024) {
        // Keep a backup of the previous log and clear the main one
        final backupFile = File('${dir.path}/app_logs_old.txt');
        if (await backupFile.exists()) {
          await backupFile.delete();
        }
        await _logFile!.rename(backupFile.path);
        _logFile = File('${dir.path}/app_logs.txt');
      }
    }
  }

  static Future<void> write(
    String message, [
    dynamic error,
    StackTrace? stack,
  ]) async {
    await _write(message, error, stack, reportRemotely: true);
  }

  /// Writes an error locally when another crash handler already reports it.
  static Future<void> writeLocal(
    String message, [
    dynamic error,
    StackTrace? stack,
  ]) async {
    await _write(message, error, stack, reportRemotely: false);
  }

  static Future<void> _write(
    String message,
    dynamic error,
    StackTrace? stack, {
    required bool reportRemotely,
  }) async {
    final timestamp = DateTime.now().toIso8601String();
    final logLine =
        '[$timestamp] $message${error != null ? '\nError: $error' : ''}${stack != null ? '\nStacktrace:\n$stack' : ''}\n';

    debugPrint(logLine.trim());

    // Queued before the remote report is awaited (not after, as it used to
    // be) so a slow report can't reorder lines relative to other callers, and
    // one that throws can't skip the local write.
    Future<void>? localWrite;
    if (_initialized && _logFile != null) {
      localWrite = _enqueue(() async {
        try {
          await _logFile!.writeAsString(
            logLine,
            mode: FileMode.append,
            flush: true,
          );
        } catch (e) {
          debugPrint('LoggerHelper: Failed to write log: $e');
        }
      });
    }

    if (reportRemotely && (error != null || stack != null)) {
      await AppAmbitReporter.reportError(
        message: message,
        exception: error,
        stackTrace: stack,
      );
    }

    await localWrite;
  }

  static Future<File?> getLogFile() async {
    if (!_initialized) await init();
    // Let queued appends land first so an export/share reads a complete file.
    await _fileQueue;
    return _logFile;
  }

  static Future<void> exportLogs() async {
    try {
      final file = await getLogFile();
      if (file != null && await file.exists()) {
        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Looper Player Diagnostic Logs');
      }
    } catch (e) {
      write('Failed to export logs', e);
    }
  }

  static Future<void> clearLogs() async {
    try {
      final file = await getLogFile();
      if (file != null && await file.exists()) {
        await _enqueue(
          () => file.writeAsString('', mode: FileMode.write, flush: true),
        );
        await write('--- Logs Cleared ---');
      }
    } catch (e) {
      write('Failed to clear logs', e);
    }
  }

  static Future<String> saveCrashLog(String error, StackTrace? stack) async {
    final timestamp = DateTime.now().toIso8601String();
    final crashContent =
        '=== LOOPER PLAYER CRASH REPORT ===\n'
        'Timestamp: $timestamp\n'
        'OS: ${Platform.operatingSystem} (${Platform.operatingSystemVersion})\n'
        'Error: $error\n'
        'Stacktrace:\n$stack\n'
        '==================================\n';

    // Target 1: Public Download folder on Android/Linux
    try {
      String? downloadDirPath;
      if (Platform.isAndroid) {
        downloadDirPath = '/storage/emulated/0/Download';
      } else {
        final dir = await getDownloadsDirectory();
        downloadDirPath = dir?.path;
      }

      if (downloadDirPath != null) {
        final downloadDir = Directory(downloadDirPath);
        if (await downloadDir.exists()) {
          final file = File('$downloadDirPath/looper_player_crash-logs.txt');
          await file.writeAsString(
            crashContent,
            mode: FileMode.write,
            flush: true,
          );
          return file.path;
        }
      }
    } catch (e) {
      debugPrint('Failed to save crash log to Downloads: $e');
    }

    // Target 2: External Storage (Android specific app folder)
    try {
      if (Platform.isAndroid) {
        final dir = await getExternalStorageDirectory();
        if (dir != null) {
          final file = File('${dir.path}/looper_player_crash-logs.txt');
          await file.writeAsString(
            crashContent,
            mode: FileMode.write,
            flush: true,
          );
          return file.path;
        }
      }
    } catch (e) {
      debugPrint('Failed to save crash log to External Storage: $e');
    }

    // Target 3: App Support Directory (Private, always works)
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/looper_player_crash-logs.txt');
      await file.writeAsString(crashContent, mode: FileMode.write, flush: true);
      return file.path;
    } catch (e) {
      debugPrint('Failed to save crash log to App Support: $e');
      return '';
    }
  }

  static Future<void> shareCrashLog(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Looper Player Crash Log');
      }
    } catch (e) {
      write('Failed to share crash log', e);
    }
  }
}
