import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

class QualityReport {
  final String verdict;
  final String confidence;
  final String integrity;
  final String bitDepth;
  final int cutoffHz;
  final String lossyCodec;

  const QualityReport({
    required this.verdict,
    required this.confidence,
    required this.integrity,
    required this.bitDepth,
    required this.cutoffHz,
    required this.lossyCodec,
  });

  static const inconclusive = QualityReport(
    verdict: 'inconclusive',
    confidence: '',
    integrity: 'unverified',
    bitDepth: 'unmeasured',
    cutoffHz: 0,
    lossyCodec: '',
  );

  factory QualityReport.fromJson(Map<String, dynamic> json) => QualityReport(
        verdict: json['verdict']?.toString() ?? 'inconclusive',
        confidence: json['confidence']?.toString() ?? '',
        integrity: json['integrity']?.toString() ?? 'unverified',
        bitDepth: json['bit_depth']?.toString() ?? 'unmeasured',
        cutoffHz: (json['cutoff_hz'] as num?)?.toInt() ?? 0,
        lossyCodec: json['lossy_codec']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'verdict': verdict,
        'confidence': confidence,
        'integrity': integrity,
        'bit_depth': bitDepth,
        'cutoff_hz': cutoffHz,
        'lossy_codec': lossyCodec,
      };
}

typedef _CheckQualityNative = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8> path, ffi.Bool full);
typedef _CheckQualityDart = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8> path, bool full);
typedef _FreeStringNative = ffi.Void Function(ffi.Pointer<Utf8> ptr);
typedef _FreeStringDart = void Function(ffi.Pointer<Utf8> ptr);

ffi.DynamicLibrary? _openLib() {
  try {
    if (Platform.isAndroid || Platform.isLinux) {
      return ffi.DynamicLibrary.open('libmetadata_god.so');
    }
    if (Platform.isWindows) {
      return ffi.DynamicLibrary.open('metadata_god.dll');
    }
    if (Platform.isMacOS || Platform.isIOS) {
      return ffi.DynamicLibrary.process();
    }
  } catch (_) {}
  return null;
}

QualityReport _checkQualitySync(String path, bool full) {
  final lib = _openLib();
  if (lib == null) return QualityReport.inconclusive;
  try {
    final check =
        lib.lookupFunction<_CheckQualityNative, _CheckQualityDart>(
            'looper_check_quality');
    final freeStr = lib
        .lookupFunction<_FreeStringNative, _FreeStringDart>(
            'looper_free_c_string');
    final pathPtr = path.toNativeUtf8();
    try {
      final resPtr = check(pathPtr, full);
      if (resPtr == ffi.nullptr) return QualityReport.inconclusive;
      try {
        final raw = resPtr.toDartString();
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return QualityReport.fromJson(decoded);
        }
      } finally {
        freeStr(resPtr);
      }
    } finally {
      calloc.free(pathPtr);
    }
  } catch (_) {}
  return QualityReport.inconclusive;
}

Future<QualityReport> checkQualityNative(String path, {bool full = false}) =>
    Isolate.run(() => _checkQualitySync(path, full));
