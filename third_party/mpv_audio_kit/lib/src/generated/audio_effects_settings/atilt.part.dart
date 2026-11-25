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

/// Configuration for the `atilt` audio effect.
///
/// Apply spectral tilt filter to audio stream.
///
/// This filter apply any spectral roll-off slope over any specified frequency band.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [freq]: Set central frequency of tilt in Hz. Default is 10000 Hz. (range 20..192000, default 10000, runtime-tunable)
/// - [level]: Set input volume level. Allowed range is from 0 to 4. Default is 1. (range 0.0..4.0, default 1., runtime-tunable)
/// - [order]: Set order of tilt filter. (range 2..30, default 5, runtime-tunable)
/// - [slope]: Set slope direction of tilt. Default is 0. Allowed range is from -1 to 1. (range -1..1, default 0, runtime-tunable)
/// - [width]: Set width of tilt. Default is 1000. Allowed range is from 100 to 10000. (range 100..10000, default 1000, runtime-tunable)
final class AtiltEffect extends AudioEffect {
  /// Default value for [freq].
  static const double freqDefault = 10000.0;

  /// Minimum value for [freq].
  static const double freqMin = 20.0;

  /// Maximum value for [freq].
  static const double freqMax = 192000.0;

  /// Default value for [level].
  static const double levelDefault = 1.0;

  /// Minimum value for [level].
  static const double levelMin = 0.0;

  /// Maximum value for [level].
  static const double levelMax = 4.0;

  /// Default value for [order].
  static const int orderDefault = 5;

  /// Minimum value for [order].
  static const int orderMin = 2;

  /// Maximum value for [order].
  static const int orderMax = 30;

  /// Default value for [slope].
  static const double slopeDefault = 0.0;

  /// Minimum value for [slope].
  static const double slopeMin = -1.0;

  /// Maximum value for [slope].
  static const double slopeMax = 1.0;

  /// Default value for [width].
  static const double widthDefault = 1000.0;

  /// Minimum value for [width].
  static const double widthMin = 100.0;

  /// Maximum value for [width].
  static const double widthMax = 10000.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set central frequency
  final double freq;

  /// set input level
  final double level;

  /// set filter order
  final int order;

  /// set filter slope
  final double slope;

  /// set filter width
  final double width;

  /// Creates an [AtiltEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AtiltEffect({
    this.enabled = true,
    this.freq = 10000.0,
    this.level = 1.0,
    this.order = 5,
    this.slope = 0.0,
    this.width = 1000.0,
  });

  @override
  String get filterName => 'atilt';

  @override
  AudioFilter get filter => AudioFilter.atilt;

  /// Returns a copy of this [AtiltEffect] with the given fields replaced.
  AtiltEffect copyWith({
    bool? enabled,
    double? freq,
    double? level,
    int? order,
    double? slope,
    double? width,
  }) => AtiltEffect(
    enabled: enabled ?? this.enabled,
    freq: freq ?? this.freq,
    level: level ?? this.level,
    order: order ?? this.order,
    slope: slope ?? this.slope,
    width: width ?? this.width,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AtiltEffect &&
          other.enabled == enabled &&
          other.freq == freq &&
          other.level == level &&
          other.order == order &&
          other.slope == slope &&
          other.width == width);

  @override
  int get hashCode => Object.hash(enabled, freq, level, order, slope, width);

  @override
  String toString() =>
      'AtiltEffect(enabled: $enabled, freq: $freq, level: $level, order: $order, slope: $slope, width: $width)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(freq >= freqMin, 'atilt.freq must be >= 20');
    assert(freq <= freqMax, 'atilt.freq must be <= 192000');
    assert(level >= levelMin, 'atilt.level must be >= 0.0');
    assert(level <= levelMax, 'atilt.level must be <= 4.0');
    assert(order >= orderMin, 'atilt.order must be >= 2');
    assert(order <= orderMax, 'atilt.order must be <= 30');
    assert(slope >= slopeMin, 'atilt.slope must be >= -1');
    assert(slope <= slopeMax, 'atilt.slope must be <= 1');
    assert(width >= widthMin, 'atilt.width must be >= 100');
    assert(width <= widthMax, 'atilt.width must be <= 10000');
    final parts = <String>[];
    if (freq != 10000.0) parts.add('freq=' + _wireDouble(freq));
    if (level != 1.0) parts.add('level=' + _wireDouble(level));
    if (order != 5) parts.add('order=' + order.toString());
    if (slope != 0.0) parts.add('slope=' + _wireDouble(slope));
    if (width != 1000.0) parts.add('width=' + _wireDouble(width));
    return parts.isEmpty ? 'lavfi-atilt' : 'lavfi-atilt=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AtiltEffect prev) {
    final out = <(String, String)>[];
    if (freq != prev.freq) {
      out.add(('freq', _wireDouble(freq)));
    }
    if (level != prev.level) {
      out.add(('level', _wireDouble(level)));
    }
    if (order != prev.order) {
      out.add(('order', order.toString()));
    }
    if (slope != prev.slope) {
      out.add(('slope', _wireDouble(slope)));
    }
    if (width != prev.width) {
      out.add(('width', _wireDouble(width)));
    }
    return out;
  }
}
