import 'dart:io';

import 'package:flutter/services.dart';

/// Hides and shows the Android system bars without leaving edge-to-edge,
/// via MainActivity - Flutter's SystemChrome modes switch edge-to-edge off
/// and use the legacy flags, which newer target SDKs ignore.
///
/// Two independent requests are combined here so screens stacked on each
/// other never show the bars over one another: [setHidden] (the lyrics
/// screen hiding just the navigation bar with its controls) and
/// [setFullscreen] (landscape player / lyrics hiding both bars, held per
/// owner). No-op on other platforms.
class SystemNavigationBar {
  SystemNavigationBar._();

  static const _channel = MethodChannel('com.looper.player/system_ui');

  static bool _navHidden = false;
  static final Set<Object> _fullscreen = {};
  static (bool, bool)? _sent;

  /// Whether some screen currently holds both bars hidden.
  static bool get isFullscreen => _fullscreen.isNotEmpty;

  static Future<void> setHidden(bool hidden) {
    _navHidden = hidden;
    return _apply();
  }

  static Future<void> setFullscreen(Object owner, bool fullscreen) {
    fullscreen ? _fullscreen.add(owner) : _fullscreen.remove(owner);
    return _apply();
  }

  static Future<void> _apply() async {
    if (!Platform.isAndroid) return;
    final (bool, bool) next = (_navHidden || isFullscreen, isFullscreen);
    if (next == _sent) return;
    _sent = next;
    try {
      await _channel.invokeMethod('setSystemBarsHidden', {
        'navigation': next.$1,
        'status': next.$2,
      });
    } catch (_) {}
  }
}
