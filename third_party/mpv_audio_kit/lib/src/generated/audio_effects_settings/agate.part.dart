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

/// Configuration for the `agate` audio effect.
///
/// A gate is mainly used to reduce lower parts of a signal. This kind of signal
/// processing reduces disturbing noise between useful signals.
///
/// Gating is done by detecting the volume below a chosen level `threshold`
/// and dividing it by the factor set with `ratio`. The bottom of the noise
/// floor is set via `range`. Because an exact manipulation of the signal
/// would cause distortion of the waveform the reduction can be levelled over
/// time. This is done by setting `attack` and `release`.
///
/// `attack` determines how long the signal has to fall below the threshold
/// before any reduction will occur and `release` sets the time the signal
/// has to rise above the threshold to reduce the reduction again.
/// Shorter signals than the chosen attack time will be left untouched.
///
/// Parameters:
/// - [attack]: Amount of milliseconds the signal has to rise above the threshold before gain reduction stops. Default is 20 milliseconds. Allowed range is from 0.01 to 9000. (range 0.01..9000, default 20)
/// - [detection]: Choose if exact signal should be taken for detection or an RMS like one. Default is `rms`. Can be `peak` or `rms`. (range 0..1, default 1)
/// - [knee]: Curve the sharp knee around the threshold to enter gain reduction more softly. Default is 2.828427125. Allowed range is from 1 to 8. (range 1..8, default 2.828427125)
/// - [levelIn]: Set input level before filtering. Default is 1. Allowed range is from 0.015625 to 64. (range 0.015625..64, default 1, runtime-tunable)
/// - [levelSc]: set sidechain gain (range 0.015625..64, default 1, runtime-tunable)
/// - [link]: Choose if the average level between all channels or the louder channel affects the reduction. Default is `average`. Can be `average` or `maximum`. (range 0..1, default 0, runtime-tunable)
/// - [makeup]: Set amount of amplification of signal after processing. Default is 1. Allowed range is from 1 to 64. (range 1..64, default 1, runtime-tunable)
/// - [mode]: Set the mode of operation. Can be `upward` or `downward`. Default is `downward`. If set to `upward` mode, higher parts of signal will be amplified, expanding dynamic range in upward direction. Otherwise, in case of `downward` lower parts of signal will be reduced. (range 0..1, default 0, runtime-tunable)
/// - [range]: Set the level of gain reduction when the signal is below the threshold. Default is 0.06125. Allowed range is from 0 to 1. Setting this to 0 disables reduction and then filter behaves like expander. (range 0..1, default 0.06125, runtime-tunable)
/// - [ratio]: Set a ratio by which the signal is reduced. Default is 2. Allowed range is from 1 to 9000. (range 1..9000, default 2, runtime-tunable)
/// - [release]: Amount of milliseconds the signal has to fall below the threshold before the reduction is increased again. Default is 250 milliseconds. Allowed range is from 0.01 to 9000. (range 0.01..9000, default 250)
/// - [threshold]: If a signal rises above this level the gain reduction is released. Default is 0.125. Allowed range is from 0 to 1. (range 0..1, default 0.125)
final class AgateEffect extends AudioEffect {
  /// Default value for [attack].
  static const double attackDefault = 20.0;

  /// Minimum value for [attack].
  static const double attackMin = 0.01;

  /// Maximum value for [attack].
  static const double attackMax = 9000.0;

  /// Default value for [knee].
  static const double kneeDefault = 2.828427125;

  /// Minimum value for [knee].
  static const double kneeMin = 1.0;

  /// Maximum value for [knee].
  static const double kneeMax = 8.0;

  /// Default value for [levelIn].
  static const double levelInDefault = 1.0;

  /// Minimum value for [levelIn].
  static const double levelInMin = 0.015625;

  /// Maximum value for [levelIn].
  static const double levelInMax = 64.0;

  /// Default value for [levelSc].
  static const double levelScDefault = 1.0;

  /// Minimum value for [levelSc].
  static const double levelScMin = 0.015625;

  /// Maximum value for [levelSc].
  static const double levelScMax = 64.0;

  /// Default value for [makeup].
  static const double makeupDefault = 1.0;

  /// Minimum value for [makeup].
  static const double makeupMin = 1.0;

  /// Maximum value for [makeup].
  static const double makeupMax = 64.0;

  /// Default value for [range].
  static const double rangeDefault = 0.06125;

  /// Minimum value for [range].
  static const double rangeMin = 0.0;

  /// Maximum value for [range].
  static const double rangeMax = 1.0;

  /// Default value for [ratio].
  static const double ratioDefault = 2.0;

  /// Minimum value for [ratio].
  static const double ratioMin = 1.0;

  /// Maximum value for [ratio].
  static const double ratioMax = 9000.0;

  /// Default value for [release].
  static const double releaseDefault = 250.0;

  /// Minimum value for [release].
  static const double releaseMin = 0.01;

  /// Maximum value for [release].
  static const double releaseMax = 9000.0;

  /// Default value for [threshold].
  static const double thresholdDefault = 0.125;

  /// Minimum value for [threshold].
  static const double thresholdMin = 0.0;

  /// Maximum value for [threshold].
  static const double thresholdMax = 1.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set attack
  final double attack;

  /// set detection
  final AgateDetection detection;

  /// set knee
  final double knee;

  /// set input level
  final double levelIn;

  /// set sidechain gain
  final double levelSc;

  /// set link
  final AgateLink link;

  /// set makeup gain
  final double makeup;

  /// set mode
  final AgateMode mode;

  /// set max gain reduction
  final double range;

  /// set ratio
  final double ratio;

  /// set release
  final double release;

  /// set threshold
  final double threshold;

  /// Creates an [AgateEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AgateEffect({
    this.enabled = true,
    this.attack = 20.0,
    this.detection = AgateDetection.rms,
    this.knee = 2.828427125,
    this.levelIn = 1.0,
    this.levelSc = 1.0,
    this.link = AgateLink.average,
    this.makeup = 1.0,
    this.mode = AgateMode.downward,
    this.range = 0.06125,
    this.ratio = 2.0,
    this.release = 250.0,
    this.threshold = 0.125,
  });

  @override
  String get filterName => 'agate';

  @override
  AudioFilter get filter => AudioFilter.agate;

  /// Returns a copy of this [AgateEffect] with the given fields replaced.
  AgateEffect copyWith({
    bool? enabled,
    double? attack,
    AgateDetection? detection,
    double? knee,
    double? levelIn,
    double? levelSc,
    AgateLink? link,
    double? makeup,
    AgateMode? mode,
    double? range,
    double? ratio,
    double? release,
    double? threshold,
  }) => AgateEffect(
    enabled: enabled ?? this.enabled,
    attack: attack ?? this.attack,
    detection: detection ?? this.detection,
    knee: knee ?? this.knee,
    levelIn: levelIn ?? this.levelIn,
    levelSc: levelSc ?? this.levelSc,
    link: link ?? this.link,
    makeup: makeup ?? this.makeup,
    mode: mode ?? this.mode,
    range: range ?? this.range,
    ratio: ratio ?? this.ratio,
    release: release ?? this.release,
    threshold: threshold ?? this.threshold,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgateEffect &&
          other.enabled == enabled &&
          other.attack == attack &&
          other.detection == detection &&
          other.knee == knee &&
          other.levelIn == levelIn &&
          other.levelSc == levelSc &&
          other.link == link &&
          other.makeup == makeup &&
          other.mode == mode &&
          other.range == range &&
          other.ratio == ratio &&
          other.release == release &&
          other.threshold == threshold);

  @override
  int get hashCode => Object.hash(
    enabled,
    attack,
    detection,
    knee,
    levelIn,
    levelSc,
    link,
    makeup,
    mode,
    range,
    ratio,
    release,
    threshold,
  );

  @override
  String toString() =>
      'AgateEffect(enabled: $enabled, attack: $attack, detection: $detection, knee: $knee, levelIn: $levelIn, levelSc: $levelSc, link: $link, makeup: $makeup, mode: $mode, range: $range, ratio: $ratio, release: $release, threshold: $threshold)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(attack >= attackMin, 'agate.attack must be >= 0.01');
    assert(attack <= attackMax, 'agate.attack must be <= 9000');
    assert(knee >= kneeMin, 'agate.knee must be >= 1');
    assert(knee <= kneeMax, 'agate.knee must be <= 8');
    assert(levelIn >= levelInMin, 'agate.level_in must be >= 0.015625');
    assert(levelIn <= levelInMax, 'agate.level_in must be <= 64');
    assert(levelSc >= levelScMin, 'agate.level_sc must be >= 0.015625');
    assert(levelSc <= levelScMax, 'agate.level_sc must be <= 64');
    assert(makeup >= makeupMin, 'agate.makeup must be >= 1');
    assert(makeup <= makeupMax, 'agate.makeup must be <= 64');
    assert(range >= rangeMin, 'agate.range must be >= 0');
    assert(range <= rangeMax, 'agate.range must be <= 1');
    assert(ratio >= ratioMin, 'agate.ratio must be >= 1');
    assert(ratio <= ratioMax, 'agate.ratio must be <= 9000');
    assert(release >= releaseMin, 'agate.release must be >= 0.01');
    assert(release <= releaseMax, 'agate.release must be <= 9000');
    assert(threshold >= thresholdMin, 'agate.threshold must be >= 0');
    assert(threshold <= thresholdMax, 'agate.threshold must be <= 1');
    final parts = <String>[];
    if (attack != 20.0) parts.add('attack=' + _wireDouble(attack));
    if (detection != AgateDetection.rms)
      parts.add('detection=' + detection.mpvValue);
    if (knee != 2.828427125) parts.add('knee=' + _wireDouble(knee));
    if (levelIn != 1.0) parts.add('level_in=' + _wireDouble(levelIn));
    if (levelSc != 1.0) parts.add('level_sc=' + _wireDouble(levelSc));
    if (link != AgateLink.average) parts.add('link=' + link.mpvValue);
    if (makeup != 1.0) parts.add('makeup=' + _wireDouble(makeup));
    if (mode != AgateMode.downward) parts.add('mode=' + mode.mpvValue);
    if (range != 0.06125) parts.add('range=' + _wireDouble(range));
    if (ratio != 2.0) parts.add('ratio=' + _wireDouble(ratio));
    if (release != 250.0) parts.add('release=' + _wireDouble(release));
    if (threshold != 0.125) parts.add('threshold=' + _wireDouble(threshold));
    return parts.isEmpty ? 'lavfi-agate' : 'lavfi-agate=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AgateEffect prev) {
    final out = <(String, String)>[];
    if (attack != prev.attack) return null;
    if (detection != prev.detection) return null;
    if (knee != prev.knee) return null;
    if (levelIn != prev.levelIn) {
      out.add(('level_in', _wireDouble(levelIn)));
    }
    if (levelSc != prev.levelSc) {
      out.add(('level_sc', _wireDouble(levelSc)));
    }
    if (link != prev.link) {
      out.add(('link', link.mpvValue));
    }
    if (makeup != prev.makeup) {
      out.add(('makeup', _wireDouble(makeup)));
    }
    if (mode != prev.mode) {
      out.add(('mode', mode.mpvValue));
    }
    if (range != prev.range) {
      out.add(('range', _wireDouble(range)));
    }
    if (ratio != prev.ratio) {
      out.add(('ratio', _wireDouble(ratio)));
    }
    if (release != prev.release) return null;
    if (threshold != prev.threshold) return null;
    return out;
  }
}
