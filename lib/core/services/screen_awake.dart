import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen on while any holder asks for it, so one screen letting
/// go (the lyrics closing) doesn't turn it off under another (the player's
/// lyric line).
abstract final class ScreenAwake {
  static final Set<Object> _holders = {};

  static void set(Object holder, bool on) {
    final wasOn = _holders.isNotEmpty;
    on ? _holders.add(holder) : _holders.remove(holder);
    if (_holders.isNotEmpty == wasOn) return;
    (wasOn ? WakelockPlus.disable() : WakelockPlus.enable()).catchError((_) {});
  }
}
