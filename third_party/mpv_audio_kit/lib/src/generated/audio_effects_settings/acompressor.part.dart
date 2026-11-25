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

/// Configuration for the `acompressor` audio effect.
///
/// A compressor is mainly used to reduce the dynamic range of a signal.
/// Especially modern music is mostly compressed at a high ratio to
/// improve the overall loudness. It's done to get the highest attention
/// of a listener, "fatten" the sound and bring more "power" to the track.
/// If a signal is compressed too much it may sound dull or "dead"
/// afterwards or it may start to "pump" (which could be a powerful effect
/// but can also destroy a track completely).
/// The right compression is the key to reach a professional sound and is
/// the high art of mixing and mastering. Because of its complex settings
/// it may take a long time to get the right feeling for this kind of effect.
///
/// Compression is done by detecting the volume above a chosen level
/// `threshold` and dividing it by the factor set with `ratio`.
/// So if you set the threshold to -12dB and your signal reaches -6dB a ratio
/// of 2:1 will result in a signal at -9dB. Because an exact manipulation of
/// the signal would cause distortion of the waveform the reduction can be
/// levelled over the time. This is done by setting "Attack" and "Release".
/// `attack` determines how long the signal has to rise above the threshold
/// before any reduction will occur and `release` sets the time the signal
/// has to fall below the threshold to reduce the reduction again. Shorter signals
/// than the chosen attack time will be left untouched.
/// The overall reduction of the signal can be made up afterwards with the
/// `makeup` setting. So compressing the peaks of a signal about 6dB and
/// raising the makeup to this level results in a signal twice as loud than the
/// source. To gain a softer entry in the compression the `knee` flattens the
/// hard edge at the threshold in the range of the chosen decibels.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [attack]: Amount of milliseconds the signal has to rise above the threshold before gain reduction starts. Default is 20. Range is between 0.01 and 2000. (range 0.01..2000, default 20, runtime-tunable)
/// - [detection]: Should the exact signal be taken in case of `peak` or an RMS one in case of `rms`. Default is `rms` which is mostly smoother. (range 0..1, default 1, runtime-tunable)
/// - [knee]: Curve the sharp knee around the threshold to enter gain reduction more softly. Default is 2.82843. Range is between 1 and 8. (range 1..8, default 2.82843, runtime-tunable)
/// - [levelIn]: Set input gain. Default is 1. Range is between 0.015625 and 64. (range 0.015625..64, default 1, runtime-tunable)
/// - [levelSc]: set sidechain gain (range 0.015625..64, default 1, runtime-tunable)
/// - [link]: Choose if the `average` level between all channels of input stream or the louder(`maximum`) channel of input stream affects the reduction. Default is `average`. (range 0..1, default 0, runtime-tunable)
/// - [makeup]: Set the amount by how much signal will be amplified after processing. Default is 1. Range is from 1 to 64. (range 1..64, default 1, runtime-tunable)
/// - [mix]: How much to use compressed signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [mode]: Set mode of compressor operation. Can be `upward` or `downward`. Default is `downward`. (range 0..1, default 0, runtime-tunable)
/// - [ratio]: Set a ratio by which the signal is reduced. 1:2 means that if the level rose 4dB above the threshold, it will be only 2dB above after the reduction. Default is 2. Range is between 1 and 20. (range 1..20, default 2, runtime-tunable)
/// - [release]: Amount of milliseconds the signal has to fall below the threshold before reduction is decreased again. Default is 250. Range is between 0.01 and 9000. (range 0.01..9000, default 250, runtime-tunable)
/// - [threshold]: If a signal of stream rises above this level it will affect the gain reduction. By default it is 0.125. Range is between 0.00097563 and 1. (range 0.000976563..1, default 0.125, runtime-tunable)
final class AcompressorEffect extends AudioEffect {
  /// Default value for [attack].
  static const double attackDefault = 20.0;

  /// Minimum value for [attack].
  static const double attackMin = 0.01;

  /// Maximum value for [attack].
  static const double attackMax = 2000.0;

  /// Default value for [knee].
  static const double kneeDefault = 2.82843;

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

  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Default value for [ratio].
  static const double ratioDefault = 2.0;

  /// Minimum value for [ratio].
  static const double ratioMin = 1.0;

  /// Maximum value for [ratio].
  static const double ratioMax = 20.0;

  /// Default value for [release].
  static const double releaseDefault = 250.0;

  /// Minimum value for [release].
  static const double releaseMin = 0.01;

  /// Maximum value for [release].
  static const double releaseMax = 9000.0;

  /// Default value for [threshold].
  static const double thresholdDefault = 0.125;

  /// Minimum value for [threshold].
  static const double thresholdMin = 0.000976563;

  /// Maximum value for [threshold].
  static const double thresholdMax = 1.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set attack
  final double attack;

  /// set detection
  final AcompressorDetection detection;

  /// set knee
  final double knee;

  /// set input gain
  final double levelIn;

  /// set sidechain gain
  final double levelSc;

  /// set link type
  final AcompressorLink link;

  /// set make up gain
  final double makeup;

  /// set mix
  final double mix;

  /// set mode
  final AcompressorMode mode;

  /// set ratio
  final double ratio;

  /// set release
  final double release;

  /// set threshold
  final double threshold;

  /// Creates an [AcompressorEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AcompressorEffect({
    this.enabled = true,
    this.attack = 20.0,
    this.detection = AcompressorDetection.rms,
    this.knee = 2.82843,
    this.levelIn = 1.0,
    this.levelSc = 1.0,
    this.link = AcompressorLink.average,
    this.makeup = 1.0,
    this.mix = 1.0,
    this.mode = AcompressorMode.downward,
    this.ratio = 2.0,
    this.release = 250.0,
    this.threshold = 0.125,
  });

  @override
  String get filterName => 'acompressor';

  @override
  AudioFilter get filter => AudioFilter.acompressor;

  /// Returns a copy of this [AcompressorEffect] with the given fields replaced.
  AcompressorEffect copyWith({
    bool? enabled,
    double? attack,
    AcompressorDetection? detection,
    double? knee,
    double? levelIn,
    double? levelSc,
    AcompressorLink? link,
    double? makeup,
    double? mix,
    AcompressorMode? mode,
    double? ratio,
    double? release,
    double? threshold,
  }) => AcompressorEffect(
    enabled: enabled ?? this.enabled,
    attack: attack ?? this.attack,
    detection: detection ?? this.detection,
    knee: knee ?? this.knee,
    levelIn: levelIn ?? this.levelIn,
    levelSc: levelSc ?? this.levelSc,
    link: link ?? this.link,
    makeup: makeup ?? this.makeup,
    mix: mix ?? this.mix,
    mode: mode ?? this.mode,
    ratio: ratio ?? this.ratio,
    release: release ?? this.release,
    threshold: threshold ?? this.threshold,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AcompressorEffect &&
          other.enabled == enabled &&
          other.attack == attack &&
          other.detection == detection &&
          other.knee == knee &&
          other.levelIn == levelIn &&
          other.levelSc == levelSc &&
          other.link == link &&
          other.makeup == makeup &&
          other.mix == mix &&
          other.mode == mode &&
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
    mix,
    mode,
    ratio,
    release,
    threshold,
  );

  @override
  String toString() =>
      'AcompressorEffect(enabled: $enabled, attack: $attack, detection: $detection, knee: $knee, levelIn: $levelIn, levelSc: $levelSc, link: $link, makeup: $makeup, mix: $mix, mode: $mode, ratio: $ratio, release: $release, threshold: $threshold)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(attack >= attackMin, 'acompressor.attack must be >= 0.01');
    assert(attack <= attackMax, 'acompressor.attack must be <= 2000');
    assert(knee >= kneeMin, 'acompressor.knee must be >= 1');
    assert(knee <= kneeMax, 'acompressor.knee must be <= 8');
    assert(levelIn >= levelInMin, 'acompressor.level_in must be >= 0.015625');
    assert(levelIn <= levelInMax, 'acompressor.level_in must be <= 64');
    assert(levelSc >= levelScMin, 'acompressor.level_sc must be >= 0.015625');
    assert(levelSc <= levelScMax, 'acompressor.level_sc must be <= 64');
    assert(makeup >= makeupMin, 'acompressor.makeup must be >= 1');
    assert(makeup <= makeupMax, 'acompressor.makeup must be <= 64');
    assert(mix >= mixMin, 'acompressor.mix must be >= 0');
    assert(mix <= mixMax, 'acompressor.mix must be <= 1');
    assert(ratio >= ratioMin, 'acompressor.ratio must be >= 1');
    assert(ratio <= ratioMax, 'acompressor.ratio must be <= 20');
    assert(release >= releaseMin, 'acompressor.release must be >= 0.01');
    assert(release <= releaseMax, 'acompressor.release must be <= 9000');
    assert(
      threshold >= thresholdMin,
      'acompressor.threshold must be >= 0.000976563',
    );
    assert(threshold <= thresholdMax, 'acompressor.threshold must be <= 1');
    final parts = <String>[];
    if (attack != 20.0) parts.add('attack=' + _wireDouble(attack));
    if (detection != AcompressorDetection.rms)
      parts.add('detection=' + detection.mpvValue);
    if (knee != 2.82843) parts.add('knee=' + _wireDouble(knee));
    if (levelIn != 1.0) parts.add('level_in=' + _wireDouble(levelIn));
    if (levelSc != 1.0) parts.add('level_sc=' + _wireDouble(levelSc));
    if (link != AcompressorLink.average) parts.add('link=' + link.mpvValue);
    if (makeup != 1.0) parts.add('makeup=' + _wireDouble(makeup));
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (mode != AcompressorMode.downward) parts.add('mode=' + mode.mpvValue);
    if (ratio != 2.0) parts.add('ratio=' + _wireDouble(ratio));
    if (release != 250.0) parts.add('release=' + _wireDouble(release));
    if (threshold != 0.125) parts.add('threshold=' + _wireDouble(threshold));
    return parts.isEmpty
        ? 'lavfi-acompressor'
        : 'lavfi-acompressor=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AcompressorEffect prev) {
    final out = <(String, String)>[];
    if (attack != prev.attack) {
      out.add(('attack', _wireDouble(attack)));
    }
    if (detection != prev.detection) {
      out.add(('detection', detection.mpvValue));
    }
    if (knee != prev.knee) {
      out.add(('knee', _wireDouble(knee)));
    }
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
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (mode != prev.mode) {
      out.add(('mode', mode.mpvValue));
    }
    if (ratio != prev.ratio) {
      out.add(('ratio', _wireDouble(ratio)));
    }
    if (release != prev.release) {
      out.add(('release', _wireDouble(release)));
    }
    if (threshold != prev.threshold) {
      out.add(('threshold', _wireDouble(threshold)));
    }
    return out;
  }
}
