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

/// Configuration for the `aeval` audio effect.
///
/// Modify an audio signal according to the specified expressions.
///
/// This filter accepts one or more expressions (one for each channel),
/// which are evaluated and used to modify a corresponding audio signal.
///
/// It accepts the following parameters:
///
/// Parameters:
/// - [channelLayout]: Set output channel layout. If not specified, the channel layout is specified by the number of expressions. If set to `same`, it will use by default the same input channel layout. (range 0..0, default "")
/// - [exprs]: Set the '|'-separated expressions list for each separate channel. If the number of input channels is greater than the number of expressions, the last specified expression is used for the remaining output channels. (default "")
final class AevalEffect extends AudioEffect {
  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set channel layout
  final String channelLayout;

  /// set the '|'-separated list of channels expressions
  final String exprs;

  /// Creates an [AevalEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AevalEffect({
    this.enabled = true,
    this.channelLayout = '',
    required this.exprs,
  });

  @override
  String get filterName => 'aeval';

  @override
  AudioFilter get filter => AudioFilter.aeval;

  /// Returns a copy of this [AevalEffect] with the given fields replaced.
  AevalEffect copyWith({bool? enabled, String? channelLayout, String? exprs}) =>
      AevalEffect(
        enabled: enabled ?? this.enabled,
        channelLayout: channelLayout ?? this.channelLayout,
        exprs: exprs ?? this.exprs,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AevalEffect &&
          other.enabled == enabled &&
          other.channelLayout == channelLayout &&
          other.exprs == exprs);

  @override
  int get hashCode => Object.hash(enabled, channelLayout, exprs);

  @override
  String toString() =>
      'AevalEffect(enabled: $enabled, channelLayout: $channelLayout, exprs: $exprs)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    final parts = <String>[];
    if (channelLayout != '')
      parts.add('channel_layout=' + _wireString(channelLayout));
    parts.add('exprs=' + _wireString(exprs));
    return parts.isEmpty ? 'lavfi-aeval' : 'lavfi-aeval=' + parts.join(':');
  }
}
