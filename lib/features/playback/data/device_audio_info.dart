import 'dart:io';

import 'package:flutter/services.dart';

/// The kind of output device music is (most likely) playing through.
enum OutputDeviceKind { speaker, wired, bluetooth, usb, hdmi, hearingAid, dock }

class OutputDeviceInfo {
  final String? name;
  final OutputDeviceKind kind;

  /// Empty when the device accepts any rate.
  final List<int> sampleRates;
  final int maxChannels;

  /// Highest PCM bit depth the device advertises; 0 = not reported.
  final int maxBits;
  final bool supportsFloat;

  /// Android 14+ bit-perfect mixer mode (mostly USB DACs).
  final bool bitPerfect;
  final String? bluetoothCodec;

  const OutputDeviceInfo({
    this.name,
    required this.kind,
    this.sampleRates = const [],
    this.maxChannels = 0,
    this.maxBits = 0,
    this.supportsFloat = false,
    this.bitPerfect = false,
    this.bluetoothCodec,
  });

  factory OutputDeviceInfo.fromMap(Map<Object?, Object?> m) => OutputDeviceInfo(
    name: m['name'] as String?,
    kind: OutputDeviceKind.values.firstWhere(
      (k) => k.name == m['kind'],
      orElse: () => OutputDeviceKind.speaker,
    ),
    sampleRates: [
      for (final r in (m['sampleRates'] as List<Object?>? ?? const []))
        if (r is int) r,
    ]..sort(),
    maxChannels: m['maxChannels'] as int? ?? 0,
    maxBits: m['maxBits'] as int? ?? 0,
    supportsFloat: m['float'] as bool? ?? false,
    bitPerfect: m['bitPerfect'] as bool? ?? false,
    bluetoothCodec: m['bluetoothCodec'] as String?,
  );
}

/// Phone and output-device audio facts from the platform
/// (`AudioOutputInfo.kt`). Android only; null elsewhere or on failure.
class DeviceAudioInfo {
  final String manufacturer;
  final String model;
  final String androidVersion;
  final int sdkInt;
  final int? nativeSampleRate;
  final int? framesPerBuffer;
  final bool lowLatency;
  final bool proAudio;

  /// Null below Android 12L, where there's no Spatializer API.
  final bool? spatialAvailable;
  final bool? spatialEnabled;
  final OutputDeviceInfo? device;

  const DeviceAudioInfo({
    required this.manufacturer,
    required this.model,
    required this.androidVersion,
    required this.sdkInt,
    this.nativeSampleRate,
    this.framesPerBuffer,
    this.lowLatency = false,
    this.proAudio = false,
    this.spatialAvailable,
    this.spatialEnabled,
    this.device,
  });

  factory DeviceAudioInfo.fromMap(Map<Object?, Object?> m) {
    final device = m['device'];
    return DeviceAudioInfo(
      manufacturer: m['manufacturer'] as String? ?? '',
      model: m['model'] as String? ?? '',
      androidVersion: m['androidVersion'] as String? ?? '',
      sdkInt: m['sdkInt'] as int? ?? 0,
      nativeSampleRate: m['nativeSampleRate'] as int?,
      framesPerBuffer: m['framesPerBuffer'] as int?,
      lowLatency: m['lowLatency'] as bool? ?? false,
      proAudio: m['proAudio'] as bool? ?? false,
      spatialAvailable: m['spatialAvailable'] as bool?,
      spatialEnabled: m['spatialEnabled'] as bool?,
      device: device is Map<Object?, Object?>
          ? OutputDeviceInfo.fromMap(device)
          : null,
    );
  }

  /// Mixer buffer length in milliseconds, when both parts are known.
  double? get bufferMs {
    final rate = nativeSampleRate;
    final frames = framesPerBuffer;
    if (rate == null || frames == null || rate <= 0) return null;
    return frames * 1000 / rate;
  }

  static const _channel = MethodChannel('com.looper.player/audio_info');

  /// The last successful [fetch], so the quality dialog can open already
  /// laid out at its final size instead of growing when the channel
  /// answers mid-animation.
  static DeviceAudioInfo? cached;

  static Future<DeviceAudioInfo?> fetch() async {
    if (!Platform.isAndroid) return null;
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'getOutputInfo',
      );
      final info = map == null ? null : DeviceAudioInfo.fromMap(map);
      if (info != null) cached = info;
      return info;
    } catch (_) {
      return null;
    }
  }
}
