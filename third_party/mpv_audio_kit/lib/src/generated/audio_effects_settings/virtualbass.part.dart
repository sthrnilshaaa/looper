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

/// Configuration for the `virtualbass` audio effect.
///
/// Apply audio Virtual Bass filter.
///
/// This filter accepts stereo input and produce stereo with LFE (2.1) channels output.
/// The newly produced LFE channel have enhanced virtual bass originally obtained from both stereo channels.
/// This filter outputs front left and front right channels unchanged as available in stereo input.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [cutoff]: Set the virtual bass cutoff frequency. Default value is 250 Hz. Allowed range is from 100 to 500 Hz. (range 100..500, default 250)
/// - [strength]: Set the virtual bass strength. Allowed range is from 0.5 to 3. Default value is 3. (range 0.5..3, default 3, runtime-tunable)
final class VirtualbassEffect extends AudioEffect {
  /// Default value for [cutoff].
  static const double cutoffDefault = 250.0;

  /// Minimum value for [cutoff].
  static const double cutoffMin = 100.0;

  /// Maximum value for [cutoff].
  static const double cutoffMax = 500.0;

  /// Default value for [strength].
  static const double strengthDefault = 3.0;

  /// Minimum value for [strength].
  static const double strengthMin = 0.5;

  /// Maximum value for [strength].
  static const double strengthMax = 3.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set virtual bass cutoff
  final double cutoff;

  /// set virtual bass strength
  final double strength;

  /// Creates an [VirtualbassEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const VirtualbassEffect({
    this.enabled = true,
    this.cutoff = 250.0,
    this.strength = 3.0,
  });

  @override
  String get filterName => 'virtualbass';

  @override
  AudioFilter get filter => AudioFilter.virtualbass;

  /// Returns a copy of this [VirtualbassEffect] with the given fields replaced.
  VirtualbassEffect copyWith({
    bool? enabled,
    double? cutoff,
    double? strength,
  }) => VirtualbassEffect(
    enabled: enabled ?? this.enabled,
    cutoff: cutoff ?? this.cutoff,
    strength: strength ?? this.strength,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VirtualbassEffect &&
          other.enabled == enabled &&
          other.cutoff == cutoff &&
          other.strength == strength);

  @override
  int get hashCode => Object.hash(enabled, cutoff, strength);

  @override
  String toString() =>
      'VirtualbassEffect(enabled: $enabled, cutoff: $cutoff, strength: $strength)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(cutoff >= cutoffMin, 'virtualbass.cutoff must be >= 100');
    assert(cutoff <= cutoffMax, 'virtualbass.cutoff must be <= 500');
    assert(strength >= strengthMin, 'virtualbass.strength must be >= 0.5');
    assert(strength <= strengthMax, 'virtualbass.strength must be <= 3');
    final parts = <String>[];
    if (cutoff != 250.0) parts.add('cutoff=' + _wireDouble(cutoff));
    if (strength != 3.0) parts.add('strength=' + _wireDouble(strength));
    return parts.isEmpty
        ? 'lavfi-virtualbass'
        : 'lavfi-virtualbass=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant VirtualbassEffect prev) {
    final out = <(String, String)>[];
    if (cutoff != prev.cutoff) return null;
    if (strength != prev.strength) {
      out.add(('strength', _wireDouble(strength)));
    }
    return out;
  }
}
