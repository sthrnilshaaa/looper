import 'dart:async';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';

/// The one spectrum preset for everything that reacts to the music (the
/// animated gradient, the artwork visualizer).
///
/// Light on purpose: a fraction of the plugin's default cost (2048-pt, 4x
/// overlap, 30 Hz), since the pipeline runs on the UI isolate. The plugin
/// only runs it while something listens to `player.stream.fft` (a broadcast
/// stream), so several listeners share one pipeline.
abstract final class PlayerSpectrum {
  static const SpectrumSettings settings = SpectrumSettings(
    fftSize: 1024,
    bandCount: 16,
    overlapFactor: 1,
    emitInterval: Duration(milliseconds: 50),
  );

  static bool _configured = false;

  /// Applies [settings] once per app run; call before listening.
  static void ensureConfigured(Player player) {
    if (_configured) return;
    _configured = true;
    player.setSpectrum(settings);
  }
}
