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

/// Configuration for the `deesser` audio effect.
///
/// Apply de-essing to the audio samples.
///
/// Parameters:
/// - [f]: How much of original frequency content to keep when de-essing. Allowed range is from 0 to 1. Default is 0.5. (range 0.0..1.0, default 0.5)
/// - [i]: Set intensity for triggering de-essing. Allowed range is from 0 to 1. Default is 0. (range 0.0..1.0, default 0.0)
/// - [m]: Set amount of ducking on treble part of sound. Allowed range is from 0 to 1. Default is 0.5. (range 0.0..1.0, default 0.5)
/// - [s]: Set the output mode.  It accepts the following values: (range 0..2, default OUT_MODE)
final class DeesserEffect extends AudioEffect {
  /// Default value for [f].
  static const double fDefault = 0.5;

  /// Minimum value for [f].
  static const double fMin = 0.0;

  /// Maximum value for [f].
  static const double fMax = 1.0;

  /// Default value for [i].
  static const double iDefault = 0.0;

  /// Minimum value for [i].
  static const double iMin = 0.0;

  /// Maximum value for [i].
  static const double iMax = 1.0;

  /// Default value for [m].
  static const double mDefault = 0.5;

  /// Minimum value for [m].
  static const double mMin = 0.0;

  /// Maximum value for [m].
  static const double mMax = 1.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set frequency
  final double f;

  /// set intensity
  final double i;

  /// set max deessing
  final double m;

  /// set output mode
  final DeesserMode s;

  /// Creates an [DeesserEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const DeesserEffect({
    this.enabled = true,
    this.f = 0.5,
    this.i = 0.0,
    this.m = 0.5,
    this.s = DeesserMode.o,
  });

  @override
  String get filterName => 'deesser';

  @override
  AudioFilter get filter => AudioFilter.deesser;

  /// Returns a copy of this [DeesserEffect] with the given fields replaced.
  DeesserEffect copyWith({
    bool? enabled,
    double? f,
    double? i,
    double? m,
    DeesserMode? s,
  }) => DeesserEffect(
    enabled: enabled ?? this.enabled,
    f: f ?? this.f,
    i: i ?? this.i,
    m: m ?? this.m,
    s: s ?? this.s,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeesserEffect &&
          other.enabled == enabled &&
          other.f == f &&
          other.i == i &&
          other.m == m &&
          other.s == s);

  @override
  int get hashCode => Object.hash(enabled, f, i, m, s);

  @override
  String toString() =>
      'DeesserEffect(enabled: $enabled, f: $f, i: $i, m: $m, s: $s)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(f >= fMin, 'deesser.f must be >= 0.0');
    assert(f <= fMax, 'deesser.f must be <= 1.0');
    assert(i >= iMin, 'deesser.i must be >= 0.0');
    assert(i <= iMax, 'deesser.i must be <= 1.0');
    assert(m >= mMin, 'deesser.m must be >= 0.0');
    assert(m <= mMax, 'deesser.m must be <= 1.0');
    final parts = <String>[];
    if (f != 0.5) parts.add('f=' + _wireDouble(f));
    if (i != 0.0) parts.add('i=' + _wireDouble(i));
    if (m != 0.5) parts.add('m=' + _wireDouble(m));
    if (s != DeesserMode.o) parts.add('s=' + s.mpvValue);
    return parts.isEmpty ? 'lavfi-deesser' : 'lavfi-deesser=' + parts.join(':');
  }
}
