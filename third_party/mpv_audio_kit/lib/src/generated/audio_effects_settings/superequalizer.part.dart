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

/// Configuration for the `superequalizer` audio effect.
///
/// Apply 18 band equalizer.
///
/// The filter accepts the following options:
///
/// Parameters whose names start with a digit, addressed by
/// their original key in the [params] map:
/// - `10b`: Set 1480Hz band gain. (range 0..20, default 1)
/// - `11b`: Set 2093Hz band gain. (range 0..20, default 1)
/// - `12b`: Set 2960Hz band gain. (range 0..20, default 1)
/// - `13b`: Set 4186Hz band gain. (range 0..20, default 1)
/// - `14b`: Set 5920Hz band gain. (range 0..20, default 1)
/// - `15b`: Set 8372Hz band gain. (range 0..20, default 1)
/// - `16b`: Set 11840Hz band gain. (range 0..20, default 1)
/// - `17b`: Set 16744Hz band gain. (range 0..20, default 1)
/// - `18b`: Set 20000Hz band gain. (range 0..20, default 1)
/// - `1b`: Set 65Hz band gain. (range 0..20, default 1)
/// - `2b`: Set 92Hz band gain. (range 0..20, default 1)
/// - `3b`: Set 131Hz band gain. (range 0..20, default 1)
/// - `4b`: Set 185Hz band gain. (range 0..20, default 1)
/// - `5b`: Set 262Hz band gain. (range 0..20, default 1)
/// - `6b`: Set 370Hz band gain. (range 0..20, default 1)
/// - `7b`: Set 523Hz band gain. (range 0..20, default 1)
/// - `8b`: Set 740Hz band gain. (range 0..20, default 1)
/// - `9b`: Set 1047Hz band gain. (range 0..20, default 1)
final class SuperequalizerEffect extends AudioEffect {
  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// Raw values for parameters whose names start with a digit,
  /// keyed by their original ffmpeg option name.
  final Map<String, double> params;

  /// Creates an [SuperequalizerEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const SuperequalizerEffect({
    this.enabled = true,
    this.params = const <String, double>{},
  });

  @override
  String get filterName => 'superequalizer';

  @override
  AudioFilter get filter => AudioFilter.superequalizer;

  /// Returns a copy of this [SuperequalizerEffect] with the given fields replaced.
  SuperequalizerEffect copyWith({bool? enabled, Map<String, double>? params}) =>
      SuperequalizerEffect(
        enabled: enabled ?? this.enabled,
        params: params ?? this.params,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SuperequalizerEffect &&
          other.enabled == enabled &&
          _mapEq(params, other.params));

  @override
  int get hashCode => Object.hash(
    enabled,
    Object.hashAllUnordered(
      params.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  @override
  String toString() =>
      'SuperequalizerEffect(enabled: $enabled, params: $params)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    final parts = <String>[];
    params.forEach((k, v) => parts.add(_wireKey(k) + '=' + _wireDouble(v)));
    return parts.isEmpty
        ? 'lavfi-superequalizer'
        : 'lavfi-superequalizer=' + parts.join(':');
  }
}
