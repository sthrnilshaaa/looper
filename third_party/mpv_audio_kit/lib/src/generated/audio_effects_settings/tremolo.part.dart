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

/// Configuration for the `tremolo` audio effect.
///
/// Sinusoidal amplitude modulation.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [d]: Depth of modulation as a percentage. Range is 0.0 - 1.0. Default value is 0.5. (range 0.0..1.0, default 0.5)
/// - [f]: Modulation frequency in Hertz. Modulation frequencies in the subharmonic range (20 Hz or lower) will result in a tremolo effect. This filter may also be used as a ring modulator by specifying a modulation frequency higher than 20 Hz. Range is 0.1 - 20000.0. Default value is 5.0 Hz. (range 0.1..20000.0, default 5.0)
final class TremoloEffect extends AudioEffect {
  /// Default value for [d].
  static const double dDefault = 0.5;

  /// Minimum value for [d].
  static const double dMin = 0.0;

  /// Maximum value for [d].
  static const double dMax = 1.0;

  /// Default value for [f].
  static const double fDefault = 5.0;

  /// Minimum value for [f].
  static const double fMin = 0.1;

  /// Maximum value for [f].
  static const double fMax = 20000.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set depth as percentage
  final double d;

  /// set frequency in hertz
  final double f;

  /// Creates an [TremoloEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const TremoloEffect({this.enabled = true, this.d = 0.5, this.f = 5.0});

  @override
  String get filterName => 'tremolo';

  @override
  AudioFilter get filter => AudioFilter.tremolo;

  /// Returns a copy of this [TremoloEffect] with the given fields replaced.
  TremoloEffect copyWith({bool? enabled, double? d, double? f}) =>
      TremoloEffect(
        enabled: enabled ?? this.enabled,
        d: d ?? this.d,
        f: f ?? this.f,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TremoloEffect &&
          other.enabled == enabled &&
          other.d == d &&
          other.f == f);

  @override
  int get hashCode => Object.hash(enabled, d, f);

  @override
  String toString() => 'TremoloEffect(enabled: $enabled, d: $d, f: $f)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(d >= dMin, 'tremolo.d must be >= 0.0');
    assert(d <= dMax, 'tremolo.d must be <= 1.0');
    assert(f >= fMin, 'tremolo.f must be >= 0.1');
    assert(f <= fMax, 'tremolo.f must be <= 20000.0');
    final parts = <String>[];
    if (d != 0.5) parts.add('d=' + _wireDouble(d));
    if (f != 5.0) parts.add('f=' + _wireDouble(f));
    return parts.isEmpty ? 'lavfi-tremolo' : 'lavfi-tremolo=' + parts.join(':');
  }
}
