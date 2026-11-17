import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen on while any holder asks for it, so one screen letting
/// go (the lyrics closing) doesn't turn it off under another (the player's
/// lyric line).
abstract final class ScreenAwake {
  static final Set<Object> _holders = {};
  static bool _enabled = true;

  static bool get isEnabled => _enabled;

  static void setEnabled(bool enabled) {
    if (_enabled == enabled) return;
    _enabled = enabled;
    if (!_enabled && _holders.isNotEmpty) {
      WakelockPlus.disable().catchError((_) {});
    } else if (_enabled && _holders.isNotEmpty) {
      WakelockPlus.enable().catchError((_) {});
    }
  }

  static bool get isActive => _enabled && _holders.isNotEmpty;

  static bool holds(Object holder) => _holders.contains(holder);

  @visibleForTesting
  static void resetForTesting() {
    _holders.clear();
    _enabled = true;
  }

  static void set(Object holder, bool on) {
    final wasOn = _enabled && _holders.isNotEmpty;
    on ? _holders.add(holder) : _holders.remove(holder);
    final nowOn = _enabled && _holders.isNotEmpty;
    if (nowOn == wasOn) return;
    (nowOn ? WakelockPlus.enable() : WakelockPlus.disable()).catchError((_) {});
  }
}
