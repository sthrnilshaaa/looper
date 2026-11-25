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

/// Configuration for the `aemphasis` audio effect.
///
/// Audio emphasis filter creates or restores material directly taken from LPs or
/// emphased CDs with different filter curves. E.g. to store music on vinyl the
/// signal has to be altered by a filter first to even out the disadvantages of
/// this recording medium.
/// Once the material is played back the inverse filter has to be applied to
/// restore the distortion of the frequency response.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [levelIn]: Set input gain. (range 0..64, default 1, runtime-tunable)
/// - [levelOut]: Set output gain. (range 0..64, default 1, runtime-tunable)
/// - [mode]: Set filter mode. For restoring material use `reproduction` mode, otherwise use `production` mode. Default is `reproduction` mode. (range 0..1, default 0, runtime-tunable)
/// - [type]: Set filter type. Selects medium. Can be one of the following: (range 0..8, default 4, runtime-tunable)
final class AemphasisEffect extends AudioEffect {
  /// Default value for [levelIn].
  static const double levelInDefault = 1.0;

  /// Minimum value for [levelIn].
  static const double levelInMin = 0.0;

  /// Maximum value for [levelIn].
  static const double levelInMax = 64.0;

  /// Default value for [levelOut].
  static const double levelOutDefault = 1.0;

  /// Minimum value for [levelOut].
  static const double levelOutMin = 0.0;

  /// Maximum value for [levelOut].
  static const double levelOutMax = 64.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set input gain
  final double levelIn;

  /// set output gain
  final double levelOut;

  /// set filter mode
  final AemphasisMode mode;

  /// set filter type
  final AemphasisType type;

  /// Creates an [AemphasisEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AemphasisEffect({
    this.enabled = true,
    this.levelIn = 1.0,
    this.levelOut = 1.0,
    this.mode = AemphasisMode.reproduction,
    this.type = AemphasisType.cd,
  });

  @override
  String get filterName => 'aemphasis';

  @override
  AudioFilter get filter => AudioFilter.aemphasis;

  /// Returns a copy of this [AemphasisEffect] with the given fields replaced.
  AemphasisEffect copyWith({
    bool? enabled,
    double? levelIn,
    double? levelOut,
    AemphasisMode? mode,
    AemphasisType? type,
  }) => AemphasisEffect(
    enabled: enabled ?? this.enabled,
    levelIn: levelIn ?? this.levelIn,
    levelOut: levelOut ?? this.levelOut,
    mode: mode ?? this.mode,
    type: type ?? this.type,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AemphasisEffect &&
          other.enabled == enabled &&
          other.levelIn == levelIn &&
          other.levelOut == levelOut &&
          other.mode == mode &&
          other.type == type);

  @override
  int get hashCode => Object.hash(enabled, levelIn, levelOut, mode, type);

  @override
  String toString() =>
      'AemphasisEffect(enabled: $enabled, levelIn: $levelIn, levelOut: $levelOut, mode: $mode, type: $type)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(levelIn >= levelInMin, 'aemphasis.level_in must be >= 0');
    assert(levelIn <= levelInMax, 'aemphasis.level_in must be <= 64');
    assert(levelOut >= levelOutMin, 'aemphasis.level_out must be >= 0');
    assert(levelOut <= levelOutMax, 'aemphasis.level_out must be <= 64');
    final parts = <String>[];
    if (levelIn != 1.0) parts.add('level_in=' + _wireDouble(levelIn));
    if (levelOut != 1.0) parts.add('level_out=' + _wireDouble(levelOut));
    if (mode != AemphasisMode.reproduction) parts.add('mode=' + mode.mpvValue);
    if (type != AemphasisType.cd) parts.add('type=' + type.mpvValue);
    return parts.isEmpty
        ? 'lavfi-aemphasis'
        : 'lavfi-aemphasis=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AemphasisEffect prev) {
    final out = <(String, String)>[];
    if (levelIn != prev.levelIn) {
      out.add(('level_in', _wireDouble(levelIn)));
    }
    if (levelOut != prev.levelOut) {
      out.add(('level_out', _wireDouble(levelOut)));
    }
    if (mode != prev.mode) {
      out.add(('mode', mode.mpvValue));
    }
    if (type != prev.type) {
      out.add(('type', type.mpvValue));
    }
    return out;
  }
}
