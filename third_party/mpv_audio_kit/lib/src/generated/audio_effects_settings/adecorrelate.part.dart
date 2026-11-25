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

/// Configuration for the `adecorrelate` audio effect.
///
/// Apply decorrelation to input audio stream.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [seed]: Set random seed used for setting delay in samples across channels. (range -1..4294967295, default -1)
/// - [stages]: Set decorrelation stages of filtering. Allowed range is from 1 to 16. Default value is 6. (range 1..16, default 6)
final class AdecorrelateEffect extends AudioEffect {
  /// Default value for [seed].
  static const int seedDefault = -1;

  /// Minimum value for [seed].
  static const int seedMin = -1;

  /// Maximum value for [seed].
  static const int seedMax = 4294967295;

  /// Default value for [stages].
  static const int stagesDefault = 6;

  /// Minimum value for [stages].
  static const int stagesMin = 1;

  /// Maximum value for [stages].
  static const int stagesMax = 16;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set random seed
  final int seed;

  /// set filtering stages
  final int stages;

  /// Creates an [AdecorrelateEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AdecorrelateEffect({
    this.enabled = true,
    this.seed = -1,
    this.stages = 6,
  });

  @override
  String get filterName => 'adecorrelate';

  @override
  AudioFilter get filter => AudioFilter.adecorrelate;

  /// Returns a copy of this [AdecorrelateEffect] with the given fields replaced.
  AdecorrelateEffect copyWith({bool? enabled, int? seed, int? stages}) =>
      AdecorrelateEffect(
        enabled: enabled ?? this.enabled,
        seed: seed ?? this.seed,
        stages: stages ?? this.stages,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdecorrelateEffect &&
          other.enabled == enabled &&
          other.seed == seed &&
          other.stages == stages);

  @override
  int get hashCode => Object.hash(enabled, seed, stages);

  @override
  String toString() =>
      'AdecorrelateEffect(enabled: $enabled, seed: $seed, stages: $stages)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(seed >= seedMin, 'adecorrelate.seed must be >= -1');
    assert(seed <= seedMax, 'adecorrelate.seed must be <= 4294967295');
    assert(stages >= stagesMin, 'adecorrelate.stages must be >= 1');
    assert(stages <= stagesMax, 'adecorrelate.stages must be <= 16');
    final parts = <String>[];
    if (seed != -1) parts.add('seed=' + seed.toString());
    if (stages != 6) parts.add('stages=' + stages.toString());
    return parts.isEmpty
        ? 'lavfi-adecorrelate'
        : 'lavfi-adecorrelate=' + parts.join(':');
  }
}
