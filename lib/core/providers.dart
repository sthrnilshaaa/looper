import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'audio_service.dart';

part 'providers.g.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

@Riverpod(keepAlive: true)
AudioService audioService(Ref ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
}

@Riverpod(keepAlive: true)
String? startupFile(Ref ref) => null;

@Riverpod(keepAlive: true)
FocusNode searchFocusNode(Ref ref) {
  final node = FocusNode(debugLabel: 'SearchFocusNode');
  ref.onDispose(() => node.dispose());
  return node;
}

@Riverpod(keepAlive: true)
class OverlayMode extends _$OverlayMode {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

/// Whether at least one of the audio/storage/notification permissions was
/// already granted as of app startup - set once via
/// `startupPermissionsGrantedProvider.overrideWithValue(...)` in `main.dart`,
/// read here rather than overriding [ForceWelcome] itself directly so its
/// `build()` stays a plain override-free method.
@Riverpod(keepAlive: true)
bool startupPermissionsGranted(Ref ref) => true;

@Riverpod(keepAlive: true)
class ForceWelcome extends _$ForceWelcome {
  @override
  bool build() => !ref.watch(startupPermissionsGrantedProvider);

  void set(bool value) => state = value;
}

@Riverpod(keepAlive: true)
Future<String> appVersion(Ref ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  } catch (_) {
    return '2.3.0';
  }
}
