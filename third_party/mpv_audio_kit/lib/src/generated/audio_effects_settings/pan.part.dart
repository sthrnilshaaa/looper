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

/// Configuration for the `pan` audio effect.
///
/// Mix channels with specific gain levels. The filter accepts the output
/// channel layout followed by a set of channels definitions.
///
/// This filter is also designed to efficiently remap the channels of an audio
/// stream.
///
/// The filter accepts parameters of the form:
/// "`l`|`outdef`|`outdef`|..."
///
/// Parameters:
/// - [args]:  (range 0..0, default "")
final class PanEffect extends AudioEffect {
  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// The `args` parameter.
  final String args;

  /// Creates an [PanEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const PanEffect({this.enabled = true, required this.args});

  @override
  String get filterName => 'pan';

  @override
  AudioFilter get filter => AudioFilter.pan;

  /// Returns a copy of this [PanEffect] with the given fields replaced.
  PanEffect copyWith({bool? enabled, String? args}) =>
      PanEffect(enabled: enabled ?? this.enabled, args: args ?? this.args);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PanEffect && other.enabled == enabled && other.args == args);

  @override
  int get hashCode => Object.hash(enabled, args);

  @override
  String toString() => 'PanEffect(enabled: $enabled, args: $args)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    final parts = <String>[];
    parts.add('args=' + _wireString(args));
    return parts.isEmpty ? 'lavfi-pan' : 'lavfi-pan=' + parts.join(':');
  }
}
