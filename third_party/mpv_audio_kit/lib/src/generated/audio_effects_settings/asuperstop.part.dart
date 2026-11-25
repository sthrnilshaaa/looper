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

/// Configuration for the `asuperstop` audio effect.
///
/// Apply high order Butterworth band-stop filter.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [centerf]: Set center frequency in Hertz. Allowed range is 2 to 999999. Default value is 1000. (range 2..999999, default 1000, runtime-tunable)
/// - [level]: Set input gain level. Allowed range is from 0 to 2. Default value is 1. (range 0.0..2.0, default 1., runtime-tunable)
/// - [order]: Set filter order. Available values are from 4 to 20. Default value is 4. (range 4..20, default 4, runtime-tunable)
/// - [qfactor]: Set Q-factor. Allowed range is from 0.01 to 100. Default value is 1. (range 0.01..100.0, default 1., runtime-tunable)
final class AsuperstopEffect extends AudioEffect {
  /// Default value for [centerf].
  static const double centerfDefault = 1000.0;

  /// Minimum value for [centerf].
  static const double centerfMin = 2.0;

  /// Maximum value for [centerf].
  static const double centerfMax = 999999.0;

  /// Default value for [level].
  static const double levelDefault = 1.0;

  /// Minimum value for [level].
  static const double levelMin = 0.0;

  /// Maximum value for [level].
  static const double levelMax = 2.0;

  /// Default value for [order].
  static const int orderDefault = 4;

  /// Minimum value for [order].
  static const int orderMin = 4;

  /// Maximum value for [order].
  static const int orderMax = 20;

  /// Default value for [qfactor].
  static const double qfactorDefault = 1.0;

  /// Minimum value for [qfactor].
  static const double qfactorMin = 0.01;

  /// Maximum value for [qfactor].
  static const double qfactorMax = 100.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set center frequency
  final double centerf;

  /// set input level
  final double level;

  /// set filter order
  final int order;

  /// set Q-factor
  final double qfactor;

  /// Creates an [AsuperstopEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AsuperstopEffect({
    this.enabled = true,
    this.centerf = 1000.0,
    this.level = 1.0,
    this.order = 4,
    this.qfactor = 1.0,
  });

  @override
  String get filterName => 'asuperstop';

  @override
  AudioFilter get filter => AudioFilter.asuperstop;

  /// Returns a copy of this [AsuperstopEffect] with the given fields replaced.
  AsuperstopEffect copyWith({
    bool? enabled,
    double? centerf,
    double? level,
    int? order,
    double? qfactor,
  }) => AsuperstopEffect(
    enabled: enabled ?? this.enabled,
    centerf: centerf ?? this.centerf,
    level: level ?? this.level,
    order: order ?? this.order,
    qfactor: qfactor ?? this.qfactor,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AsuperstopEffect &&
          other.enabled == enabled &&
          other.centerf == centerf &&
          other.level == level &&
          other.order == order &&
          other.qfactor == qfactor);

  @override
  int get hashCode => Object.hash(enabled, centerf, level, order, qfactor);

  @override
  String toString() =>
      'AsuperstopEffect(enabled: $enabled, centerf: $centerf, level: $level, order: $order, qfactor: $qfactor)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(centerf >= centerfMin, 'asuperstop.centerf must be >= 2');
    assert(centerf <= centerfMax, 'asuperstop.centerf must be <= 999999');
    assert(level >= levelMin, 'asuperstop.level must be >= 0.0');
    assert(level <= levelMax, 'asuperstop.level must be <= 2.0');
    assert(order >= orderMin, 'asuperstop.order must be >= 4');
    assert(order <= orderMax, 'asuperstop.order must be <= 20');
    assert(qfactor >= qfactorMin, 'asuperstop.qfactor must be >= 0.01');
    assert(qfactor <= qfactorMax, 'asuperstop.qfactor must be <= 100.0');
    final parts = <String>[];
    if (centerf != 1000.0) parts.add('centerf=' + _wireDouble(centerf));
    if (level != 1.0) parts.add('level=' + _wireDouble(level));
    if (order != 4) parts.add('order=' + order.toString());
    if (qfactor != 1.0) parts.add('qfactor=' + _wireDouble(qfactor));
    return parts.isEmpty
        ? 'lavfi-asuperstop'
        : 'lavfi-asuperstop=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AsuperstopEffect prev) {
    final out = <(String, String)>[];
    if (centerf != prev.centerf) {
      out.add(('centerf', _wireDouble(centerf)));
    }
    if (level != prev.level) {
      out.add(('level', _wireDouble(level)));
    }
    if (order != prev.order) {
      out.add(('order', order.toString()));
    }
    if (qfactor != prev.qfactor) {
      out.add(('qfactor', _wireDouble(qfactor)));
    }
    return out;
  }
}
