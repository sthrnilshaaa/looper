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

/// Configuration for the `dcshift` audio effect.
///
/// Apply a DC shift to the audio.
///
/// This can be useful to remove a DC offset (caused perhaps by a hardware problem
/// in the recording chain) from the audio. The effect of a DC offset is reduced
/// headroom and hence volume. The astats filter can be used to determine if
/// a signal has a DC offset.
///
/// Parameters:
/// - [limitergain]: Optional. It should have a value much less than 1 (e.g. 0.05 or 0.02) and is used to prevent clipping. (range 0..1, default 0)
/// - [shift]: Set the DC shift, allowed range is \[-1, 1\]. It indicates the amount to shift the audio. (range -1..1, default 0)
final class DcshiftEffect extends AudioEffect {
  /// Default value for [limitergain].
  static const double limitergainDefault = 0.0;

  /// Minimum value for [limitergain].
  static const double limitergainMin = 0.0;

  /// Maximum value for [limitergain].
  static const double limitergainMax = 1.0;

  /// Default value for [shift].
  static const double shiftDefault = 0.0;

  /// Minimum value for [shift].
  static const double shiftMin = -1.0;

  /// Maximum value for [shift].
  static const double shiftMax = 1.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set limiter gain
  final double limitergain;

  /// set DC shift
  final double shift;

  /// Creates an [DcshiftEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const DcshiftEffect({
    this.enabled = true,
    this.limitergain = 0.0,
    this.shift = 0.0,
  });

  @override
  String get filterName => 'dcshift';

  @override
  AudioFilter get filter => AudioFilter.dcshift;

  /// Returns a copy of this [DcshiftEffect] with the given fields replaced.
  DcshiftEffect copyWith({bool? enabled, double? limitergain, double? shift}) =>
      DcshiftEffect(
        enabled: enabled ?? this.enabled,
        limitergain: limitergain ?? this.limitergain,
        shift: shift ?? this.shift,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DcshiftEffect &&
          other.enabled == enabled &&
          other.limitergain == limitergain &&
          other.shift == shift);

  @override
  int get hashCode => Object.hash(enabled, limitergain, shift);

  @override
  String toString() =>
      'DcshiftEffect(enabled: $enabled, limitergain: $limitergain, shift: $shift)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(limitergain >= limitergainMin, 'dcshift.limitergain must be >= 0');
    assert(limitergain <= limitergainMax, 'dcshift.limitergain must be <= 1');
    assert(shift >= shiftMin, 'dcshift.shift must be >= -1');
    assert(shift <= shiftMax, 'dcshift.shift must be <= 1');
    final parts = <String>[];
    if (limitergain != 0.0)
      parts.add('limitergain=' + _wireDouble(limitergain));
    if (shift != 0.0) parts.add('shift=' + _wireDouble(shift));
    return parts.isEmpty ? 'lavfi-dcshift' : 'lavfi-dcshift=' + parts.join(':');
  }
}
