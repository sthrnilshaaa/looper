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

/// Configuration for the `aintegral` audio effect.
///
/// Compute derivative/integral of audio stream.
///
/// Applying both filters one after another produces original audio.
final class AintegralEffect extends AudioEffect {
  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// Creates an [AintegralEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AintegralEffect({this.enabled = true});

  @override
  String get filterName => 'aintegral';

  @override
  AudioFilter get filter => AudioFilter.aintegral;

  /// Returns a copy of this [AintegralEffect] with the given fields replaced.
  AintegralEffect copyWith({bool? enabled}) =>
      AintegralEffect(enabled: enabled ?? this.enabled);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AintegralEffect && other.enabled == enabled);

  @override
  int get hashCode => enabled.hashCode;

  @override
  String toString() => 'AintegralEffect(enabled: $enabled)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    return 'lavfi-aintegral';
  }
}
