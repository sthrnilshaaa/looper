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

/// Configuration for the `afreqshift` audio effect.
///
/// Apply frequency shift to input audio samples.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [level]: Set output gain applied to final output. Allowed range is from 0.0 to 1.0. Default value is 1.0. (range 0.0..1.0, default 1, runtime-tunable)
/// - [order]: Set filter order used for filtering. Allowed range is from 1 to 16. Default value is 8. (range 1..16, default 8)
/// - [shift]: Specify frequency shift. Allowed range is -INT_MAX to INT_MAX. Default value is 0.0. (range -2147483647..2147483647, default 0, runtime-tunable)
final class AfreqshiftEffect extends AudioEffect {
  /// Default value for [level].
  static const double levelDefault = 1.0;

  /// Minimum value for [level].
  static const double levelMin = 0.0;

  /// Maximum value for [level].
  static const double levelMax = 1.0;

  /// Default value for [order].
  static const int orderDefault = 8;

  /// Minimum value for [order].
  static const int orderMin = 1;

  /// Maximum value for [order].
  static const int orderMax = 16;

  /// Default value for [shift].
  static const double shiftDefault = 0.0;

  /// Minimum value for [shift].
  static const double shiftMin = -2147483647.0;

  /// Maximum value for [shift].
  static const double shiftMax = 2147483647.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set output level
  final double level;

  /// set filter order
  final int order;

  /// set frequency shift
  final double shift;

  /// Creates an [AfreqshiftEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AfreqshiftEffect({
    this.enabled = true,
    this.level = 1.0,
    this.order = 8,
    this.shift = 0.0,
  });

  @override
  String get filterName => 'afreqshift';

  @override
  AudioFilter get filter => AudioFilter.afreqshift;

  /// Returns a copy of this [AfreqshiftEffect] with the given fields replaced.
  AfreqshiftEffect copyWith({
    bool? enabled,
    double? level,
    int? order,
    double? shift,
  }) => AfreqshiftEffect(
    enabled: enabled ?? this.enabled,
    level: level ?? this.level,
    order: order ?? this.order,
    shift: shift ?? this.shift,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AfreqshiftEffect &&
          other.enabled == enabled &&
          other.level == level &&
          other.order == order &&
          other.shift == shift);

  @override
  int get hashCode => Object.hash(enabled, level, order, shift);

  @override
  String toString() =>
      'AfreqshiftEffect(enabled: $enabled, level: $level, order: $order, shift: $shift)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(level >= levelMin, 'afreqshift.level must be >= 0.0');
    assert(level <= levelMax, 'afreqshift.level must be <= 1.0');
    assert(order >= orderMin, 'afreqshift.order must be >= 1');
    assert(order <= orderMax, 'afreqshift.order must be <= 16');
    assert(shift >= shiftMin, 'afreqshift.shift must be >= -2147483647');
    assert(shift <= shiftMax, 'afreqshift.shift must be <= 2147483647');
    final parts = <String>[];
    if (level != 1.0) parts.add('level=' + _wireDouble(level));
    if (order != 8) parts.add('order=' + order.toString());
    if (shift != 0.0) parts.add('shift=' + _wireDouble(shift));
    return parts.isEmpty
        ? 'lavfi-afreqshift'
        : 'lavfi-afreqshift=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AfreqshiftEffect prev) {
    final out = <(String, String)>[];
    if (level != prev.level) {
      out.add(('level', _wireDouble(level)));
    }
    if (order != prev.order) return null;
    if (shift != prev.shift) {
      out.add(('shift', _wireDouble(shift)));
    }
    return out;
  }
}
