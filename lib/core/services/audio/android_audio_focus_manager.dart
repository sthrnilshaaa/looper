import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import '../../utils/logger_helper.dart';

final androidAudioFocusManagerProvider = Provider<AndroidAudioFocusManager>((
  ref,
) {
  return AndroidAudioFocusManager(ref);
});

/// Audio-route events from the native AudioFocusManager.kt: headphones
/// unplugged ("becoming noisy") and Bluetooth audio connecting.
///
/// Audio focus itself is owned solely by mpv_audio_kit (its
/// AudioFocusController), whose focus reactions reach the app as ordinary
/// media-session play/pause commands - see AudioService. This class must
/// never request focus: a second focus request from the same app steals
/// focus from the plugin's listener and pauses playback.
class AndroidAudioFocusManager {
  final Ref _ref;
  static const _channel = MethodChannel('com.looper.player/audio_focus');

  AndroidAudioFocusManager(this._ref) {
    if (Platform.isAndroid) {
      _channel.setMethodCallHandler(_handleMethodCall);
      _syncSettings();
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    final playback = _ref.read(playbackProvider.notifier);
    final settings = _ref.read(settingsProvider);

    switch (call.method) {
      case 'onBecomingNoisy':
        LoggerHelper.write('AndroidAudioFocusManager: onBecomingNoisy');
        playback.onBecomingNoisy();
        break;

      case 'onBluetoothConnected':
        LoggerHelper.write('AndroidAudioFocusManager: onBluetoothConnected');
        if (settings.resumeOnBluetoothConnect) {
          await playback.resumeOnBluetoothConnect();
        }
        break;
    }
  }

  Future<void> syncSettings() async {
    if (!Platform.isAndroid) return;
    await _syncSettings();
  }

  Future<void> _syncSettings() async {
    final settings = _ref.read(settingsProvider);
    try {
      await _channel.invokeMethod('syncSettings', {
        'resumeOnBluetoothConnect': settings.resumeOnBluetoothConnect,
      });
    } catch (e) {
      LoggerHelper.write(
        'AndroidAudioFocusManager: Error syncing settings: $e',
      );
    }
  }
}
