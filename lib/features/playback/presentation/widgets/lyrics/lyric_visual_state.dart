import 'package:flutter/material.dart';

/// Unified visual state for a single lyric line.
///
/// Computed once per build from [relativeIndex] and [isActive],
/// then consumed by animations in [AdvancedLyricLine].
/// This mirrors Apple Music's internal per-line state interpolation.
class LyricVisualState {
  final double opacity;
  final double scale;
  final double blur;
  final double yOffset;
  final FontWeight fontWeight;

  const LyricVisualState({
    required this.opacity,
    required this.scale,
    required this.blur,
    required this.yOffset,
    required this.fontWeight,
  });

  /// Calculates the visual state for a lyric line.
  ///
  /// [relativeIndex] — distance from the active line (0 = active).
  /// [isActive]      — whether this line is the currently playing line.
  /// [progress]      — playback progress within the active line (0.0–1.0).
  factory LyricVisualState.calculate({
    required int relativeIndex,
    required bool isActive,
    double progress = 0.0,
    int activeWeightDelta = 0,
    int inactiveWeightDelta = 0,
  }) {
    final distance = relativeIndex.abs().toDouble();

    // Depth opacity: falls off with distance, floors at 0.20
    // The recent inactive line (distance = 1) must be as grey as the 2nd inactive line (distance = 2)
    final effectiveDistance = distance == 1.0 ? 2.0 : distance;
    final baseOpacity = (0.35 - (effectiveDistance * 0.03)).clamp(0.20, 0.32);

    // Scale hierarchy: active = full size, each step away shrinks ~3.5%
    final baseScale = (1.0 - (distance * 0.035)).clamp(0.90, 1.0);

    // Blur: inactive lines get progressively more out-of-focus
    final blur = (distance * 0.8).clamp(0.0, 6.0);

    // Signed relative index for correct direction of flow
    final double dir = relativeIndex.toDouble();

    // Proportional visual translation shift to create a physical accordion rubber-band slide cascade!
    final clampedDistance = distance.clamp(0.0, 5.0);
    final yOffset = isActive ? 0.0 : dir * (clampedDistance * 5.0);

    final baseIndex = isActive ? 8 : 4; // w900 for active, w500 for inactive
    final delta = isActive ? activeWeightDelta : inactiveWeightDelta;
    final adjustedIndex = (baseIndex + delta).clamp(0, 8);
    final weight = FontWeight.values[adjustedIndex];

    return LyricVisualState(
      opacity: isActive ? 1.0 : baseOpacity,
      scale: isActive ? 1.0 : baseScale,
      blur: isActive ? 0.0 : blur,
      yOffset: yOffset,
      fontWeight: weight,
    );
  }
}
