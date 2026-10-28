import 'package:flutter/widgets.dart';

/// Android memory policy for the app's decoded images, the biggest share of
/// its memory.
///
/// - Caps Flutter's image cache below its 100 MB / 1000-image default. Art is
///   decoded at display size (OptimizedImage, ResizeImage), so 64 MB still
///   holds several screens' worth of covers on a mid-range phone.
/// - When Android reports memory pressure (onTrimMemory, delivered to Flutter
///   as didHaveMemoryPressure), drops the cached images that nothing on
///   screen is using, instead of letting the system kill the app - images
///   still on screen stay, the rest re-decode on demand.
abstract final class MemoryManager {
  static const int imageCacheBytes = 64 << 20;
  static const int imageCacheCount = 400;

  static bool _installed = false;

  static void install() {
    if (_installed) return;
    _installed = true;
    final ImageCache cache = PaintingBinding.instance.imageCache;
    cache.maximumSizeBytes = imageCacheBytes;
    cache.maximumSize = imageCacheCount;
    WidgetsBinding.instance.addObserver(_PressureObserver());
  }
}

class _PressureObserver with WidgetsBindingObserver {
  @override
  void didHaveMemoryPressure() {
    // clear() evicts finished, unused entries; images currently shown are
    // held by their widgets and stay.
    PaintingBinding.instance.imageCache.clear();
  }
}
