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

/// Configuration for the `adenorm` audio effect.
///
/// Remedy denormals in audio by adding extremely low-level noise.
///
/// This filter shall be placed before any filter that can produce denormals.
///
/// A description of the accepted parameters follows.
///
/// Parameters:
/// - [level]: Set level of added noise in dB. Default is `-351`. Allowed range is from -451 to -90. (range -451..-90, default -351, runtime-tunable)
/// - [type]: Set type of added noise. (range 0..3, default DC_TYPE, runtime-tunable)
final class AdenormEffect extends AudioEffect {
  /// Default value for [level].
  static const double levelDefault = -351.0;

  /// Minimum value for [level].
  static const double levelMin = -451.0;

  /// Maximum value for [level].
  static const double levelMax = -90.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set level
  final double level;

  /// set type
  final AdenormType type;

  /// Creates an [AdenormEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AdenormEffect({
    this.enabled = true,
    this.level = -351.0,
    this.type = AdenormType.dc,
  });

  @override
  String get filterName => 'adenorm';

  @override
  AudioFilter get filter => AudioFilter.adenorm;

  /// Returns a copy of this [AdenormEffect] with the given fields replaced.
  AdenormEffect copyWith({bool? enabled, double? level, AdenormType? type}) =>
      AdenormEffect(
        enabled: enabled ?? this.enabled,
        level: level ?? this.level,
        type: type ?? this.type,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdenormEffect &&
          other.enabled == enabled &&
          other.level == level &&
          other.type == type);

  @override
  int get hashCode => Object.hash(enabled, level, type);

  @override
  String toString() =>
      'AdenormEffect(enabled: $enabled, level: $level, type: $type)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(level >= levelMin, 'adenorm.level must be >= -451');
    assert(level <= levelMax, 'adenorm.level must be <= -90');
    final parts = <String>[];
    if (level != -351.0) parts.add('level=' + _wireDouble(level));
    if (type != AdenormType.dc) parts.add('type=' + type.mpvValue);
    return parts.isEmpty ? 'lavfi-adenorm' : 'lavfi-adenorm=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AdenormEffect prev) {
    final out = <(String, String)>[];
    if (level != prev.level) {
      out.add(('level', _wireDouble(level)));
    }
    if (type != prev.type) {
      out.add(('type', type.mpvValue));
    }
    return out;
  }
}
