// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license
// that can be found in the LICENSE file.
//
// AUTO-GENERATED: do not edit by hand.
//
// The descriptions of the filters and of their options in the
// documentation comments are FFmpeg's (doc/filters.texi and the option
// help of libavfilter, https://ffmpeg.org) and keep FFmpeg's licenses: the
// LGPL, version 2.1 or later (FFmpeg's LICENSE.md), and for the option help of
// deesser, arnndn and hdcd the MIT or BSD terms of their source files; the BSD
// 3-Clause license above covers the rest of this file.
// ignore_for_file: unnecessary_ignore, non_constant_identifier_names, constant_identifier_names, camel_case_types, curly_braces_in_flow_control_structures, prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings

part of '../audio_effects_settings.dart';

/// Configuration for the `flanger` audio effect.
///
/// Apply a flanging effect to the audio.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [delay]: Set base delay in milliseconds. Range from 0 to 30. Default value is 0. (range 0..30, default 0)
/// - [depth]: Set added sweep delay in milliseconds. Range from 0 to 10. Default value is 2. (range 0..10, default 2)
/// - [interp]: Set delay-line interpolation, `linear` or `quadratic`. Default is `linear`. (range 0..1, default 0)
/// - [phase]: Set swept wave percentage-shift for multi channel. Range from 0 to 100. Default value is 25. (range 0..100, default 25)
/// - [regen]: Set percentage regeneration (delayed signal feedback). Range from -95 to 95. Default value is 0. (range -95..95, default 0)
/// - [shape]: Set swept wave shape, can be `triangular` or `sinusoidal`. Default value is `sinusoidal`. (default WAVE_SIN)
/// - [speed]: Set sweeps per second (Hz). Range from 0.1 to 10. Default value is 0.5. (range 0.1..10, default 0.5)
/// - [width]: Set percentage of delayed signal mixed with original. Range from 0 to 100. Default value is 71. (range 0..100, default 71)
final class FlangerEffect extends AudioEffect {
  /// Default value for [delay].
  static const double delayDefault = 0.0;

  /// Minimum value for [delay].
  static const double delayMin = 0.0;

  /// Maximum value for [delay].
  static const double delayMax = 30.0;

  /// Default value for [depth].
  static const double depthDefault = 2.0;

  /// Minimum value for [depth].
  static const double depthMin = 0.0;

  /// Maximum value for [depth].
  static const double depthMax = 10.0;

  /// Default value for [phase].
  static const double phaseDefault = 25.0;

  /// Minimum value for [phase].
  static const double phaseMin = 0.0;

  /// Maximum value for [phase].
  static const double phaseMax = 100.0;

  /// Default value for [regen].
  static const double regenDefault = 0.0;

  /// Minimum value for [regen].
  static const double regenMin = -95.0;

  /// Maximum value for [regen].
  static const double regenMax = 95.0;

  /// Default value for [speed].
  static const double speedDefault = 0.5;

  /// Minimum value for [speed].
  static const double speedMin = 0.1;

  /// Maximum value for [speed].
  static const double speedMax = 10.0;

  /// Default value for [width].
  static const double widthDefault = 71.0;

  /// Minimum value for [width].
  static const double widthMin = 0.0;

  /// Maximum value for [width].
  static const double widthMax = 100.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// base delay in milliseconds
  final double delay;

  /// added swept delay in milliseconds
  final double depth;

  /// delay-line interpolation
  final FlangerItype interp;

  /// swept wave percentage phase-shift for multi-channel
  final double phase;

  /// percentage regeneration (delayed signal feedback)
  final double regen;

  /// swept wave shape
  final FlangerType shape;

  /// sweeps per second (Hz)
  final double speed;

  /// percentage of delayed signal mixed with original
  final double width;

  /// Creates an [FlangerEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const FlangerEffect({
    this.enabled = true,
    this.delay = 0.0,
    this.depth = 2.0,
    this.interp = FlangerItype.linear,
    this.phase = 25.0,
    this.regen = 0.0,
    this.shape = FlangerType.sinusoidal,
    this.speed = 0.5,
    this.width = 71.0,
  });

  @override
  String get filterName => 'flanger';

  @override
  AudioFilter get filter => AudioFilter.flanger;

  /// Returns a copy of this [FlangerEffect] with the given fields replaced.
  FlangerEffect copyWith({
    bool? enabled,
    double? delay,
    double? depth,
    FlangerItype? interp,
    double? phase,
    double? regen,
    FlangerType? shape,
    double? speed,
    double? width,
  }) => FlangerEffect(
    enabled: enabled ?? this.enabled,
    delay: delay ?? this.delay,
    depth: depth ?? this.depth,
    interp: interp ?? this.interp,
    phase: phase ?? this.phase,
    regen: regen ?? this.regen,
    shape: shape ?? this.shape,
    speed: speed ?? this.speed,
    width: width ?? this.width,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlangerEffect &&
          other.enabled == enabled &&
          other.delay == delay &&
          other.depth == depth &&
          other.interp == interp &&
          other.phase == phase &&
          other.regen == regen &&
          other.shape == shape &&
          other.speed == speed &&
          other.width == width);

  @override
  int get hashCode => Object.hash(
    enabled,
    delay,
    depth,
    interp,
    phase,
    regen,
    shape,
    speed,
    width,
  );

  @override
  String toString() =>
      'FlangerEffect(enabled: $enabled, delay: $delay, depth: $depth, interp: $interp, phase: $phase, regen: $regen, shape: $shape, speed: $speed, width: $width)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(delay >= delayMin, 'flanger.delay must be >= 0');
    assert(delay <= delayMax, 'flanger.delay must be <= 30');
    assert(depth >= depthMin, 'flanger.depth must be >= 0');
    assert(depth <= depthMax, 'flanger.depth must be <= 10');
    assert(phase >= phaseMin, 'flanger.phase must be >= 0');
    assert(phase <= phaseMax, 'flanger.phase must be <= 100');
    assert(regen >= regenMin, 'flanger.regen must be >= -95');
    assert(regen <= regenMax, 'flanger.regen must be <= 95');
    assert(speed >= speedMin, 'flanger.speed must be >= 0.1');
    assert(speed <= speedMax, 'flanger.speed must be <= 10');
    assert(width >= widthMin, 'flanger.width must be >= 0');
    assert(width <= widthMax, 'flanger.width must be <= 100');
    final parts = <String>[];
    if (delay != 0.0) parts.add('delay=' + _wireDouble(delay));
    if (depth != 2.0) parts.add('depth=' + _wireDouble(depth));
    if (interp != FlangerItype.linear) parts.add('interp=' + interp.mpvValue);
    if (phase != 25.0) parts.add('phase=' + _wireDouble(phase));
    if (regen != 0.0) parts.add('regen=' + _wireDouble(regen));
    if (shape != FlangerType.sinusoidal) parts.add('shape=' + shape.mpvValue);
    if (speed != 0.5) parts.add('speed=' + _wireDouble(speed));
    if (width != 71.0) parts.add('width=' + _wireDouble(width));
    return parts.isEmpty ? 'lavfi-flanger' : 'lavfi-flanger=' + parts.join(':');
  }
}
