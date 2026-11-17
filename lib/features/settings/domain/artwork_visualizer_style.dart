import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/settings/domain/app_defaults.dart';

/// The effect drawn around/over the Now Playing artwork, driven by the
/// music's spectrum. The stored index is the enum index, so only append.
enum ArtworkVisualizerType { none, aura, ring, wave, bars, breathing }

/// How strongly the effect reacts.
enum ArtworkVisualizerIntensity { subtle, normal, strong }

/// Where the effect's colors come from.
enum ArtworkVisualizerColors { artwork, theme, white }

class ArtworkVisualizerStyle {
  final ArtworkVisualizerType type;
  final ArtworkVisualizerIntensity intensity;
  final ArtworkVisualizerColors colors;

  /// Delay between the audio being analysed and the effect showing it.
  /// The analysis taps the audio before the output buffer, so without it
  /// the effect runs ahead of the sound.
  final int syncMs;

  static const int defaultSyncMs = AppDefaults.artworkVisualizerSyncMs;
  static const int minSyncMs = 0;
  static const int maxSyncMs = 600;

  const ArtworkVisualizerStyle({
    this.type = ArtworkVisualizerType.none,
    this.intensity = ArtworkVisualizerIntensity.normal,
    this.colors = ArtworkVisualizerColors.artwork,
    this.syncMs = defaultSyncMs,
  });

  factory ArtworkVisualizerStyle.fromSettings(AppSettings s) =>
      ArtworkVisualizerStyle(
        type: _at(ArtworkVisualizerType.values, s.artworkVisualizer, 0),
        intensity: _at(
          ArtworkVisualizerIntensity.values,
          s.artworkVisualizerIntensity,
          1,
        ),
        colors: _at(
          ArtworkVisualizerColors.values,
          s.artworkVisualizerColors,
          0,
        ),
        syncMs: (s.artworkVisualizerSyncMs ?? defaultSyncMs).clamp(
          minSyncMs,
          maxSyncMs,
        ),
      );

  ArtworkVisualizerStyle copyWith({int? syncMs}) => ArtworkVisualizerStyle(
    type: type,
    intensity: intensity,
    colors: colors,
    syncMs: syncMs ?? this.syncMs,
  );

  static T _at<T>(List<T> values, int? i, int fallback) =>
      i != null && i >= 0 && i < values.length ? values[i] : values[fallback];

  /// Multiplier applied to every audio-driven amount.
  double get gain => switch (intensity) {
    ArtworkVisualizerIntensity.subtle => 0.6,
    ArtworkVisualizerIntensity.normal => 1.0,
    ArtworkVisualizerIntensity.strong => 1.5,
  };

  @override
  bool operator ==(Object other) =>
      other is ArtworkVisualizerStyle &&
      other.type == type &&
      other.intensity == intensity &&
      other.colors == colors &&
      other.syncMs == syncMs;

  @override
  int get hashCode => Object.hash(type, intensity, colors, syncMs);
}
