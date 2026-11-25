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

/// Configuration for the `asubcut` audio effect.
///
/// Cut subwoofer frequencies.
///
/// This filter allows to set custom, steeper
/// roll off than highpass filter, and thus is able to more attenuate
/// frequency content in stop-band.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [cutoff]: Set cutoff frequency in Hertz. Allowed range is 2 to 200. Default value is 20. (range 2..200, default 20, runtime-tunable)
/// - [level]: Set input gain level. Allowed range is from 0 to 1. Default value is 1. (range 0.0..1.0, default 1., runtime-tunable)
/// - [order]: Set filter order. Available values are from 3 to 20. Default value is 10. (range 3..20, default 10, runtime-tunable)
final class AsubcutEffect extends AudioEffect {
  /// Default value for [cutoff].
  static const double cutoffDefault = 20.0;

  /// Minimum value for [cutoff].
  static const double cutoffMin = 2.0;

  /// Maximum value for [cutoff].
  static const double cutoffMax = 200.0;

  /// Default value for [level].
  static const double levelDefault = 1.0;

  /// Minimum value for [level].
  static const double levelMin = 0.0;

  /// Maximum value for [level].
  static const double levelMax = 1.0;

  /// Default value for [order].
  static const int orderDefault = 10;

  /// Minimum value for [order].
  static const int orderMin = 3;

  /// Maximum value for [order].
  static const int orderMax = 20;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set cutoff frequency
  final double cutoff;

  /// set input level
  final double level;

  /// set filter order
  final int order;

  /// Creates an [AsubcutEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AsubcutEffect({
    this.enabled = true,
    this.cutoff = 20.0,
    this.level = 1.0,
    this.order = 10,
  });

  @override
  String get filterName => 'asubcut';

  @override
  AudioFilter get filter => AudioFilter.asubcut;

  /// Returns a copy of this [AsubcutEffect] with the given fields replaced.
  AsubcutEffect copyWith({
    bool? enabled,
    double? cutoff,
    double? level,
    int? order,
  }) => AsubcutEffect(
    enabled: enabled ?? this.enabled,
    cutoff: cutoff ?? this.cutoff,
    level: level ?? this.level,
    order: order ?? this.order,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AsubcutEffect &&
          other.enabled == enabled &&
          other.cutoff == cutoff &&
          other.level == level &&
          other.order == order);

  @override
  int get hashCode => Object.hash(enabled, cutoff, level, order);

  @override
  String toString() =>
      'AsubcutEffect(enabled: $enabled, cutoff: $cutoff, level: $level, order: $order)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(cutoff >= cutoffMin, 'asubcut.cutoff must be >= 2');
    assert(cutoff <= cutoffMax, 'asubcut.cutoff must be <= 200');
    assert(level >= levelMin, 'asubcut.level must be >= 0.0');
    assert(level <= levelMax, 'asubcut.level must be <= 1.0');
    assert(order >= orderMin, 'asubcut.order must be >= 3');
    assert(order <= orderMax, 'asubcut.order must be <= 20');
    final parts = <String>[];
    if (cutoff != 20.0) parts.add('cutoff=' + _wireDouble(cutoff));
    if (level != 1.0) parts.add('level=' + _wireDouble(level));
    if (order != 10) parts.add('order=' + order.toString());
    return parts.isEmpty ? 'lavfi-asubcut' : 'lavfi-asubcut=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AsubcutEffect prev) {
    final out = <(String, String)>[];
    if (cutoff != prev.cutoff) {
      out.add(('cutoff', _wireDouble(cutoff)));
    }
    if (level != prev.level) {
      out.add(('level', _wireDouble(level)));
    }
    if (order != prev.order) {
      out.add(('order', order.toString()));
    }
    return out;
  }
}
