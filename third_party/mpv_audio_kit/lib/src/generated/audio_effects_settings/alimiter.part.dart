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

/// Configuration for the `alimiter` audio effect.
///
/// The limiter prevents an input signal from rising over a desired threshold.
/// This limiter uses lookahead technology to prevent your signal from distorting.
/// It means that there is a small delay after the signal is processed. Keep in mind
/// that the delay it produces is the attack time you set.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [asc]: When gain reduction is always needed ASC takes care of releasing to an average reduction level rather than reaching a reduction of 0 in the release time. (range 0..1, default 0, runtime-tunable)
/// - [ascLevel]: Select how much the release time is affected by ASC, 0 means nearly no changes in release time while 1 produces higher release times. (range 0..1, default 0.5)
/// - [attack]: The limiter will reach its attenuation level in this amount of time in milliseconds. Default is 5 milliseconds. (range 0.1..80, default 5)
/// - [latency]: Compensate the delay introduced by using the lookahead buffer set with attack parameter. Also flush the valid audio data in the lookahead buffer when the stream hits EOF. (range 0..1, default 0)
/// - [level]: Auto level output signal. Default is enabled. This normalizes audio back to 0dB if enabled. (range 0..1, default 1, runtime-tunable)
/// - [levelIn]: Set input gain. Default is 1. (range .015625..64, default 1, runtime-tunable)
/// - [levelOut]: Set output gain. Default is 1. (range .015625..64, default 1, runtime-tunable)
/// - [limit]: Don't let signals above this level pass the limiter. Default is 1. (range 0.0625..1, default 1, runtime-tunable)
/// - [release]: Come back from limiting to attenuation 1.0 in this amount of milliseconds. Default is 50 milliseconds. (range 1..8000, default 50)
final class AlimiterEffect extends AudioEffect {
  /// Default value for [ascLevel].
  static const double ascLevelDefault = 0.5;

  /// Minimum value for [ascLevel].
  static const double ascLevelMin = 0.0;

  /// Maximum value for [ascLevel].
  static const double ascLevelMax = 1.0;

  /// Default value for [attack].
  static const double attackDefault = 5.0;

  /// Minimum value for [attack].
  static const double attackMin = 0.1;

  /// Maximum value for [attack].
  static const double attackMax = 80.0;

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

  /// Default value for [limit].
  static const double limitDefault = 1.0;

  /// Minimum value for [limit].
  static const double limitMin = 0.0625;

  /// Maximum value for [limit].
  static const double limitMax = 1.0;

  /// Default value for [release].
  static const double releaseDefault = 50.0;

  /// Minimum value for [release].
  static const double releaseMin = 1.0;

  /// Maximum value for [release].
  static const double releaseMax = 8000.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// enable asc
  final bool asc;

  /// set asc level
  final double ascLevel;

  /// set attack
  final double attack;

  /// compensate delay
  final bool latency;

  /// auto level
  final bool level;

  /// set input level
  final double levelIn;

  /// set output level
  final double levelOut;

  /// set limit
  final double limit;

  /// set release
  final double release;

  /// Creates an [AlimiterEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AlimiterEffect({
    this.enabled = true,
    this.asc = false,
    this.ascLevel = 0.5,
    this.attack = 5.0,
    this.latency = false,
    this.level = true,
    this.levelIn = 1.0,
    this.levelOut = 1.0,
    this.limit = 1.0,
    this.release = 50.0,
  });

  @override
  String get filterName => 'alimiter';

  @override
  AudioFilter get filter => AudioFilter.alimiter;

  /// Returns a copy of this [AlimiterEffect] with the given fields replaced.
  AlimiterEffect copyWith({
    bool? enabled,
    bool? asc,
    double? ascLevel,
    double? attack,
    bool? latency,
    bool? level,
    double? levelIn,
    double? levelOut,
    double? limit,
    double? release,
  }) => AlimiterEffect(
    enabled: enabled ?? this.enabled,
    asc: asc ?? this.asc,
    ascLevel: ascLevel ?? this.ascLevel,
    attack: attack ?? this.attack,
    latency: latency ?? this.latency,
    level: level ?? this.level,
    levelIn: levelIn ?? this.levelIn,
    levelOut: levelOut ?? this.levelOut,
    limit: limit ?? this.limit,
    release: release ?? this.release,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlimiterEffect &&
          other.enabled == enabled &&
          other.asc == asc &&
          other.ascLevel == ascLevel &&
          other.attack == attack &&
          other.latency == latency &&
          other.level == level &&
          other.levelIn == levelIn &&
          other.levelOut == levelOut &&
          other.limit == limit &&
          other.release == release);

  @override
  int get hashCode => Object.hash(
    enabled,
    asc,
    ascLevel,
    attack,
    latency,
    level,
    levelIn,
    levelOut,
    limit,
    release,
  );

  @override
  String toString() =>
      'AlimiterEffect(enabled: $enabled, asc: $asc, ascLevel: $ascLevel, attack: $attack, latency: $latency, level: $level, levelIn: $levelIn, levelOut: $levelOut, limit: $limit, release: $release)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(ascLevel >= ascLevelMin, 'alimiter.asc_level must be >= 0');
    assert(ascLevel <= ascLevelMax, 'alimiter.asc_level must be <= 1');
    assert(attack >= attackMin, 'alimiter.attack must be >= 0.1');
    assert(attack <= attackMax, 'alimiter.attack must be <= 80');
    assert(levelIn >= levelInMin, 'alimiter.level_in must be >= .015625');
    assert(levelIn <= levelInMax, 'alimiter.level_in must be <= 64');
    assert(levelOut >= levelOutMin, 'alimiter.level_out must be >= .015625');
    assert(levelOut <= levelOutMax, 'alimiter.level_out must be <= 64');
    assert(limit >= limitMin, 'alimiter.limit must be >= 0.0625');
    assert(limit <= limitMax, 'alimiter.limit must be <= 1');
    assert(release >= releaseMin, 'alimiter.release must be >= 1');
    assert(release <= releaseMax, 'alimiter.release must be <= 8000');
    final parts = <String>[];
    if (asc != false) parts.add('asc=' + (asc ? '1' : '0'));
    if (ascLevel != 0.5) parts.add('asc_level=' + _wireDouble(ascLevel));
    if (attack != 5.0) parts.add('attack=' + _wireDouble(attack));
    if (latency != false) parts.add('latency=' + (latency ? '1' : '0'));
    if (level != true) parts.add('level=' + (level ? '1' : '0'));
    if (levelIn != 1.0) parts.add('level_in=' + _wireDouble(levelIn));
    if (levelOut != 1.0) parts.add('level_out=' + _wireDouble(levelOut));
    if (limit != 1.0) parts.add('limit=' + _wireDouble(limit));
    if (release != 50.0) parts.add('release=' + _wireDouble(release));
    return parts.isEmpty
        ? 'lavfi-alimiter'
        : 'lavfi-alimiter=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AlimiterEffect prev) {
    final out = <(String, String)>[];
    if (asc != prev.asc) {
      out.add(('asc', (asc ? '1' : '0')));
    }
    if (ascLevel != prev.ascLevel) return null;
    if (attack != prev.attack) return null;
    if (latency != prev.latency) return null;
    if (level != prev.level) {
      out.add(('level', (level ? '1' : '0')));
    }
    if (levelIn != prev.levelIn) {
      out.add(('level_in', _wireDouble(levelIn)));
    }
    if (levelOut != prev.levelOut) {
      out.add(('level_out', _wireDouble(levelOut)));
    }
    if (limit != prev.limit) {
      out.add(('limit', _wireDouble(limit)));
    }
    if (release != prev.release) return null;
    return out;
  }
}
