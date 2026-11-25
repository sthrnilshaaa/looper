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

/// Configuration for the `apsyclip` audio effect.
///
/// Apply Psychoacoustic clipper to input audio stream.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [adaptive]: Set strength of adaptive distortion applied. Default value is 0.5. Allowed range is from 0 to 1. (range 0..1, default 0.5, runtime-tunable)
/// - [clip]: Set the clipping start value. Default value is 0dBFS or 1. (range .015625..1, default 1, runtime-tunable)
/// - [diff]: Output only difference samples, useful to hear introduced distortions. By default is disabled. (range 0..1, default 0, runtime-tunable)
/// - [iterations]: Set number of iterations of psychoacoustic clipper. Allowed range is from 1 to 20. Default value is 10. (range 1..20, default 10, runtime-tunable)
/// - [level]: Auto level output signal. Default is disabled. This normalizes audio back to 0dBFS if enabled. (range 0..1, default 0, runtime-tunable)
/// - [levelIn]: Set input gain. By default it is 1. Range is \[0.015625 - 64\]. (range .015625..64, default 1, runtime-tunable)
/// - [levelOut]: Set output gain. By default it is 1. Range is \[0.015625 - 64\]. (range .015625..64, default 1, runtime-tunable)
final class ApsyclipEffect extends AudioEffect {
  /// Default value for [adaptive].
  static const double adaptiveDefault = 0.5;

  /// Minimum value for [adaptive].
  static const double adaptiveMin = 0.0;

  /// Maximum value for [adaptive].
  static const double adaptiveMax = 1.0;

  /// Default value for [clip].
  static const double clipDefault = 1.0;

  /// Minimum value for [clip].
  static const double clipMin = .015625;

  /// Maximum value for [clip].
  static const double clipMax = 1.0;

  /// Default value for [iterations].
  static const int iterationsDefault = 10;

  /// Minimum value for [iterations].
  static const int iterationsMin = 1;

  /// Maximum value for [iterations].
  static const int iterationsMax = 20;

  /// Default value for [levelIn].
  static const double levelInDefault = 1.0;

  /// Minimum value for [levelIn].
  static const double levelInMin = .015625;

  /// Maximum value for [levelIn].
  static const double levelInMax = 64.0;

  /// Default value for [levelOut].
  static const double levelOutDefault = 1.0;

  /// Minimum value for [levelOut].
  static const double levelOutMin = .015625;

  /// Maximum value for [levelOut].
  static const double levelOutMax = 64.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set adaptive distortion
  final double adaptive;

  /// set clip level
  final double clip;

  /// enable difference
  final bool diff;

  /// set iterations
  final int iterations;

  /// set auto level
  final bool level;

  /// set input level
  final double levelIn;

  /// set output level
  final double levelOut;

  /// Creates an [ApsyclipEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const ApsyclipEffect({
    this.enabled = true,
    this.adaptive = 0.5,
    this.clip = 1.0,
    this.diff = false,
    this.iterations = 10,
    this.level = false,
    this.levelIn = 1.0,
    this.levelOut = 1.0,
  });

  @override
  String get filterName => 'apsyclip';

  @override
  AudioFilter get filter => AudioFilter.apsyclip;

  /// Returns a copy of this [ApsyclipEffect] with the given fields replaced.
  ApsyclipEffect copyWith({
    bool? enabled,
    double? adaptive,
    double? clip,
    bool? diff,
    int? iterations,
    bool? level,
    double? levelIn,
    double? levelOut,
  }) => ApsyclipEffect(
    enabled: enabled ?? this.enabled,
    adaptive: adaptive ?? this.adaptive,
    clip: clip ?? this.clip,
    diff: diff ?? this.diff,
    iterations: iterations ?? this.iterations,
    level: level ?? this.level,
    levelIn: levelIn ?? this.levelIn,
    levelOut: levelOut ?? this.levelOut,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApsyclipEffect &&
          other.enabled == enabled &&
          other.adaptive == adaptive &&
          other.clip == clip &&
          other.diff == diff &&
          other.iterations == iterations &&
          other.level == level &&
          other.levelIn == levelIn &&
          other.levelOut == levelOut);

  @override
  int get hashCode => Object.hash(
    enabled,
    adaptive,
    clip,
    diff,
    iterations,
    level,
    levelIn,
    levelOut,
  );

  @override
  String toString() =>
      'ApsyclipEffect(enabled: $enabled, adaptive: $adaptive, clip: $clip, diff: $diff, iterations: $iterations, level: $level, levelIn: $levelIn, levelOut: $levelOut)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(adaptive >= adaptiveMin, 'apsyclip.adaptive must be >= 0');
    assert(adaptive <= adaptiveMax, 'apsyclip.adaptive must be <= 1');
    assert(clip >= clipMin, 'apsyclip.clip must be >= .015625');
    assert(clip <= clipMax, 'apsyclip.clip must be <= 1');
    assert(iterations >= iterationsMin, 'apsyclip.iterations must be >= 1');
    assert(iterations <= iterationsMax, 'apsyclip.iterations must be <= 20');
    assert(levelIn >= levelInMin, 'apsyclip.level_in must be >= .015625');
    assert(levelIn <= levelInMax, 'apsyclip.level_in must be <= 64');
    assert(levelOut >= levelOutMin, 'apsyclip.level_out must be >= .015625');
    assert(levelOut <= levelOutMax, 'apsyclip.level_out must be <= 64');
    final parts = <String>[];
    if (adaptive != 0.5) parts.add('adaptive=' + _wireDouble(adaptive));
    if (clip != 1.0) parts.add('clip=' + _wireDouble(clip));
    if (diff != false) parts.add('diff=' + (diff ? '1' : '0'));
    if (iterations != 10) parts.add('iterations=' + iterations.toString());
    if (level != false) parts.add('level=' + (level ? '1' : '0'));
    if (levelIn != 1.0) parts.add('level_in=' + _wireDouble(levelIn));
    if (levelOut != 1.0) parts.add('level_out=' + _wireDouble(levelOut));
    return parts.isEmpty
        ? 'lavfi-apsyclip'
        : 'lavfi-apsyclip=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant ApsyclipEffect prev) {
    final out = <(String, String)>[];
    if (adaptive != prev.adaptive) {
      out.add(('adaptive', _wireDouble(adaptive)));
    }
    if (clip != prev.clip) {
      out.add(('clip', _wireDouble(clip)));
    }
    if (diff != prev.diff) {
      out.add(('diff', (diff ? '1' : '0')));
    }
    if (iterations != prev.iterations) {
      out.add(('iterations', iterations.toString()));
    }
    if (level != prev.level) {
      out.add(('level', (level ? '1' : '0')));
    }
    if (levelIn != prev.levelIn) {
      out.add(('level_in', _wireDouble(levelIn)));
    }
    if (levelOut != prev.levelOut) {
      out.add(('level_out', _wireDouble(levelOut)));
    }
    return out;
  }
}
