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

/// Configuration for the `drmeter` audio effect.
///
/// Measure audio dynamic range.
///
/// DR values of 14 and higher is found in very dynamic material. DR of 8 to 13
/// is found in transition material. And anything less that 8 have very poor dynamics
/// and is very compressed.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [length]: Set window length in seconds used to split audio into segments of equal length. Default is 3 seconds. (range .01..10, default 3)
final class DrmeterEffect extends AudioEffect {
  /// Default value for [length].
  static const double lengthDefault = 3.0;

  /// Minimum value for [length].
  static const double lengthMin = .01;

  /// Maximum value for [length].
  static const double lengthMax = 10.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set the window length
  final double length;

  /// Creates an [DrmeterEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const DrmeterEffect({this.enabled = true, this.length = 3.0});

  @override
  String get filterName => 'drmeter';

  @override
  AudioFilter get filter => AudioFilter.drmeter;

  /// Returns a copy of this [DrmeterEffect] with the given fields replaced.
  DrmeterEffect copyWith({bool? enabled, double? length}) => DrmeterEffect(
    enabled: enabled ?? this.enabled,
    length: length ?? this.length,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DrmeterEffect &&
          other.enabled == enabled &&
          other.length == length);

  @override
  int get hashCode => Object.hash(enabled, length);

  @override
  String toString() => 'DrmeterEffect(enabled: $enabled, length: $length)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(length >= lengthMin, 'drmeter.length must be >= .01');
    assert(length <= lengthMax, 'drmeter.length must be <= 10');
    final parts = <String>[];
    if (length != 3.0) parts.add('length=' + _wireDouble(length));
    return parts.isEmpty ? 'lavfi-drmeter' : 'lavfi-drmeter=' + parts.join(':');
  }
}
