import 'dart:io';

import 'package:looper_player/core/services/storage/local_json_store.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:metadata_god/metadata_god.dart';

/// Runs and caches Doc 15's Rust fake-lossless check for local FLAC files.
///
/// Never runs on the playback path; invoked on demand from the quality sheet,
/// song menu, or after a download finishes.
class QualityCheckService {
  static const String _storeKey = 'quality_reports';
  static final Map<String, QualityReport> _memory = {};

  static bool isCheckableFlac(String path) =>
      path.toLowerCase().endsWith('.flac') &&
      !path.startsWith('http://') &&
      !path.startsWith('https://') &&
      !path.startsWith('yt:') &&
      !path.startsWith('src:') &&
      !path.startsWith('content://');

  static Future<String?> _cacheKey(String path) async {
    try {
      final stat = await File(path).stat();
      if (stat.type == FileSystemEntityType.notFound) return null;
      return '$path|${stat.size}|${stat.modified.millisecondsSinceEpoch}';
    } catch (_) {
      return null;
    }
  }

  /// Fast in-memory lookup for badges without touching disk or running Rust.
  static QualityReport? cachedSync(String path) => _memory[path];

  static Future<QualityReport?> loadCached(String path) async {
    final mem = _memory[path];
    if (mem != null) return mem;
    if (!isCheckableFlac(path)) return null;
    final key = await _cacheKey(path);
    if (key == null) return null;
    final store = await LocalJsonStore.read(_storeKey);
    if (store is Map && store[key] is Map) {
      final report = QualityReport.fromJson(
        Map<String, dynamic>.from(store[key] as Map),
      );
      _memory[path] = report;
      return report;
    }
    return null;
  }

  static Future<QualityReport> check(
    String path, {
    bool full = false,
  }) async {
    if (!isCheckableFlac(path)) return QualityReport.inconclusive;
    final key = await _cacheKey(path);
    if (key == null) return QualityReport.inconclusive;

    final rawStore = await LocalJsonStore.read(_storeKey);
    final store = rawStore is Map
        ? Map<String, dynamic>.from(rawStore)
        : <String, dynamic>{};

    final existing = store[key];
    if (existing is Map && (!full || existing['full'] == true)) {
      final report = QualityReport.fromJson(
        Map<String, dynamic>.from(existing),
      );
      _memory[path] = report;
      return report;
    }

    final report = await MetadataGod.checkQuality(path, full: full);
    _memory[path] = report;
    store[key] = {...report.toJson(), 'full': full};
    await LocalJsonStore.write(_storeKey, store);
    return report;
  }

  static bool isSuspect(QualityReport? report) =>
      report != null &&
      (report.verdict == 'lossy' || report.verdict == 'upscaled');

  static String describe(QualityReport report, AppLocalizations l10n) {
    switch (report.verdict) {
      case 'clean':
        return l10n.qualityCheckClean;
      case 'lossy':
        final codec = report.lossyCodec.toUpperCase();
        final cutoff = report.cutoffHz > 0
            ? '${(report.cutoffHz / 1000).toStringAsFixed(0)} kHz'
            : '';
        if (codec.isNotEmpty && cutoff.isNotEmpty) {
          return l10n.qualityCheckLossyCodecCutoff(codec, cutoff);
        }
        if (codec.isNotEmpty) {
          return l10n.qualityCheckLossyCodec(codec);
        }
        return l10n.qualityCheckSuspect;
      case 'upscaled':
        if (report.bitDepth == 'padded' || report.bitDepth == 'near_16bit') {
          return l10n.qualityCheckPadded24;
        }
        return l10n.qualityCheckSuspect;
      case 'suspect':
        return l10n.qualityCheckSuspect;
      case 'limited':
        if (report.cutoffHz > 0) {
          final cutoff = '${(report.cutoffHz / 1000).toStringAsFixed(0)} kHz';
          return l10n.qualityCheckLimitedCutoff(cutoff);
        }
        return l10n.qualityCheckLimited;
      case 'corrupt':
        return l10n.qualityCheckCorrupt;
      default:
        return l10n.qualityCheckInconclusive;
    }
  }
}
