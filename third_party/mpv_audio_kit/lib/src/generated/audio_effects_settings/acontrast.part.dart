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

/// Configuration for the `acontrast` audio effect.
///
/// Simple audio dynamic range compression/expansion filter.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [contrast]: Set contrast. Default is 33. Allowed range is between 0 and 100. (range 0..100, default 33)
final class AcontrastEffect extends AudioEffect {
  /// Default value for [contrast].
  static const double contrastDefault = 33.0;

  /// Minimum value for [contrast].
  static const double contrastMin = 0.0;

  /// Maximum value for [contrast].
  static const double contrastMax = 100.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set contrast
  final double contrast;

  /// Creates an [AcontrastEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AcontrastEffect({this.enabled = true, this.contrast = 33.0});

  @override
  String get filterName => 'acontrast';

  @override
  AudioFilter get filter => AudioFilter.acontrast;

  /// Returns a copy of this [AcontrastEffect] with the given fields replaced.
  AcontrastEffect copyWith({bool? enabled, double? contrast}) =>
      AcontrastEffect(
        enabled: enabled ?? this.enabled,
        contrast: contrast ?? this.contrast,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AcontrastEffect &&
          other.enabled == enabled &&
          other.contrast == contrast);

  @override
  int get hashCode => Object.hash(enabled, contrast);

  @override
  String toString() =>
      'AcontrastEffect(enabled: $enabled, contrast: $contrast)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(contrast >= contrastMin, 'acontrast.contrast must be >= 0');
    assert(contrast <= contrastMax, 'acontrast.contrast must be <= 100');
    final parts = <String>[];
    if (contrast != 33.0) parts.add('contrast=' + _wireDouble(contrast));
    return parts.isEmpty
        ? 'lavfi-acontrast'
        : 'lavfi-acontrast=' + parts.join(':');
  }
}
