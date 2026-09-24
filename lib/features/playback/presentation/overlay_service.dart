import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import '../../../core/providers.dart';

final overlayServiceProvider = Provider<OverlayService>((ref) {
  return OverlayService(ref);
});

class OverlayService {
  final Ref ref;
  Rect? _previousBounds;

  OverlayService(this.ref);

  Future<void> toggleOverlay() async {
    final isOverlay = ref.read(overlayModeProvider);
    if (isOverlay) {
      await exitOverlay();
    } else {
      await enterOverlay();
    }
  }

  Future<void> enterOverlay() async {
    _previousBounds = await windowManager.getBounds();

    // Switch state first to trigger UI rebuild
    ref.read(overlayModeProvider.notifier).set(true);

    await windowManager.setAsFrameless();
    await windowManager.setHasShadow(false);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setBackgroundColor(Colors.transparent);

    // Set to a smaller size suitable for lyrics
    await windowManager.setSize(const Size(400, 150));
    // Provide a small delay to ensure the OS has applied the borderless state
    // before the window is resized.
    await Future.delayed(const Duration(milliseconds: 50));
    await windowManager.setBackgroundColor(Colors.transparent);
  }

  Future<void> exitOverlay() async {
    // Switch state back to trigger UI rebuild
    ref.read(overlayModeProvider.notifier).set(false);

    await windowManager.setAlwaysOnTop(false);
    await windowManager.setHasShadow(true);

    // Revert styling
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);

    if (_previousBounds != null) {
      await windowManager.setBounds(_previousBounds);
    } else {
      await windowManager.setSize(const Size(1300, 700));
      await windowManager.center();
    }
  }
}
