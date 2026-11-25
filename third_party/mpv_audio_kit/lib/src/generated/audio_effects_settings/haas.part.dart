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

/// Configuration for the `haas` audio effect.
///
/// Apply Haas effect to audio.
///
/// Note that this makes most sense to apply on mono signals.
/// With this filter applied to mono signals it give some directionality and
/// stretches its stereo image.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [leftBalance]: set left balance (range -1..1, default -1.0)
/// - [leftDelay]: set left delay (range 0..40, default 2.05)
/// - [leftGain]: set left gain (range 0.015625..64, default 1)
/// - [leftPhase]: set left phase (range 0..1, default 0)
/// - [levelIn]: Set input level. By default is `1`, or 0dB (range 0.015625..64, default 1)
/// - [levelOut]: Set output level. By default is `1`, or 0dB. (range 0.015625..64, default 1)
/// - [middlePhase]: set middle phase (range 0..1, default 0)
/// - [middleSource]: Set kind of middle source. Can be one of the following: (range 0..3, default 2)
/// - [rightBalance]: set right balance (range -1..1, default 1)
/// - [rightDelay]: set right delay (range 0..40, default 2.12)
/// - [rightGain]: set right gain (range 0.015625..64, default 1)
/// - [rightPhase]: set right phase (range 0..1, default 1)
/// - [sideGain]: Set gain applied to side part of signal. By default is `1`. (range 0.015625..64, default 1)
final class HaasEffect extends AudioEffect {
  /// Default value for [leftBalance].
  static const double leftBalanceDefault = -1.0;

  /// Minimum value for [leftBalance].
  static const double leftBalanceMin = -1.0;

  /// Maximum value for [leftBalance].
  static const double leftBalanceMax = 1.0;

  /// Default value for [leftDelay].
  static const double leftDelayDefault = 2.05;

  /// Minimum value for [leftDelay].
  static const double leftDelayMin = 0.0;

  /// Maximum value for [leftDelay].
  static const double leftDelayMax = 40.0;

  /// Default value for [leftGain].
  static const double leftGainDefault = 1.0;

  /// Minimum value for [leftGain].
  static const double leftGainMin = 0.015625;

  /// Maximum value for [leftGain].
  static const double leftGainMax = 64.0;

  /// Default value for [levelIn].
  static const double levelInDefault = 1.0;

  /// Minimum value for [levelIn].
  static const double levelInMin = 0.015625;

  /// Maximum value for [levelIn].
  static const double levelInMax = 64.0;

  /// Default value for [levelOut].
  static const double levelOutDefault = 1.0;

  /// Minimum value for [levelOut].
  static const double levelOutMin = 0.015625;

  /// Maximum value for [levelOut].
  static const double levelOutMax = 64.0;

  /// Default value for [rightBalance].
  static const double rightBalanceDefault = 1.0;

  /// Minimum value for [rightBalance].
  static const double rightBalanceMin = -1.0;

  /// Maximum value for [rightBalance].
  static const double rightBalanceMax = 1.0;

  /// Default value for [rightDelay].
  static const double rightDelayDefault = 2.12;

  /// Minimum value for [rightDelay].
  static const double rightDelayMin = 0.0;

  /// Maximum value for [rightDelay].
  static const double rightDelayMax = 40.0;

  /// Default value for [rightGain].
  static const double rightGainDefault = 1.0;

  /// Minimum value for [rightGain].
  static const double rightGainMin = 0.015625;

  /// Maximum value for [rightGain].
  static const double rightGainMax = 64.0;

  /// Default value for [sideGain].
  static const double sideGainDefault = 1.0;

  /// Minimum value for [sideGain].
  static const double sideGainMin = 0.015625;

  /// Maximum value for [sideGain].
  static const double sideGainMax = 64.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set left balance
  final double leftBalance;

  /// set left delay
  final double leftDelay;

  /// set left gain
  final double leftGain;

  /// set left phase
  final bool leftPhase;

  /// set level in
  final double levelIn;

  /// set level out
  final double levelOut;

  /// set middle phase
  final bool middlePhase;

  /// set middle source
  final HaasSource middleSource;

  /// set right balance
  final double rightBalance;

  /// set right delay
  final double rightDelay;

  /// set right gain
  final double rightGain;

  /// set right phase
  final bool rightPhase;

  /// set side gain
  final double sideGain;

  /// Creates an [HaasEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const HaasEffect({
    this.enabled = true,
    this.leftBalance = -1.0,
    this.leftDelay = 2.05,
    this.leftGain = 1.0,
    this.leftPhase = false,
    this.levelIn = 1.0,
    this.levelOut = 1.0,
    this.middlePhase = false,
    this.middleSource = HaasSource.mid,
    this.rightBalance = 1.0,
    this.rightDelay = 2.12,
    this.rightGain = 1.0,
    this.rightPhase = true,
    this.sideGain = 1.0,
  });

  @override
  String get filterName => 'haas';

  @override
  AudioFilter get filter => AudioFilter.haas;

  /// Returns a copy of this [HaasEffect] with the given fields replaced.
  HaasEffect copyWith({
    bool? enabled,
    double? leftBalance,
    double? leftDelay,
    double? leftGain,
    bool? leftPhase,
    double? levelIn,
    double? levelOut,
    bool? middlePhase,
    HaasSource? middleSource,
    double? rightBalance,
    double? rightDelay,
    double? rightGain,
    bool? rightPhase,
    double? sideGain,
  }) => HaasEffect(
    enabled: enabled ?? this.enabled,
    leftBalance: leftBalance ?? this.leftBalance,
    leftDelay: leftDelay ?? this.leftDelay,
    leftGain: leftGain ?? this.leftGain,
    leftPhase: leftPhase ?? this.leftPhase,
    levelIn: levelIn ?? this.levelIn,
    levelOut: levelOut ?? this.levelOut,
    middlePhase: middlePhase ?? this.middlePhase,
    middleSource: middleSource ?? this.middleSource,
    rightBalance: rightBalance ?? this.rightBalance,
    rightDelay: rightDelay ?? this.rightDelay,
    rightGain: rightGain ?? this.rightGain,
    rightPhase: rightPhase ?? this.rightPhase,
    sideGain: sideGain ?? this.sideGain,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HaasEffect &&
          other.enabled == enabled &&
          other.leftBalance == leftBalance &&
          other.leftDelay == leftDelay &&
          other.leftGain == leftGain &&
          other.leftPhase == leftPhase &&
          other.levelIn == levelIn &&
          other.levelOut == levelOut &&
          other.middlePhase == middlePhase &&
          other.middleSource == middleSource &&
          other.rightBalance == rightBalance &&
          other.rightDelay == rightDelay &&
          other.rightGain == rightGain &&
          other.rightPhase == rightPhase &&
          other.sideGain == sideGain);

  @override
  int get hashCode => Object.hash(
    enabled,
    leftBalance,
    leftDelay,
    leftGain,
    leftPhase,
    levelIn,
    levelOut,
    middlePhase,
    middleSource,
    rightBalance,
    rightDelay,
    rightGain,
    rightPhase,
    sideGain,
  );

  @override
  String toString() =>
      'HaasEffect(enabled: $enabled, leftBalance: $leftBalance, leftDelay: $leftDelay, leftGain: $leftGain, leftPhase: $leftPhase, levelIn: $levelIn, levelOut: $levelOut, middlePhase: $middlePhase, middleSource: $middleSource, rightBalance: $rightBalance, rightDelay: $rightDelay, rightGain: $rightGain, rightPhase: $rightPhase, sideGain: $sideGain)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(leftBalance >= leftBalanceMin, 'haas.left_balance must be >= -1');
    assert(leftBalance <= leftBalanceMax, 'haas.left_balance must be <= 1');
    assert(leftDelay >= leftDelayMin, 'haas.left_delay must be >= 0');
    assert(leftDelay <= leftDelayMax, 'haas.left_delay must be <= 40');
    assert(leftGain >= leftGainMin, 'haas.left_gain must be >= 0.015625');
    assert(leftGain <= leftGainMax, 'haas.left_gain must be <= 64');
    assert(levelIn >= levelInMin, 'haas.level_in must be >= 0.015625');
    assert(levelIn <= levelInMax, 'haas.level_in must be <= 64');
    assert(levelOut >= levelOutMin, 'haas.level_out must be >= 0.015625');
    assert(levelOut <= levelOutMax, 'haas.level_out must be <= 64');
    assert(rightBalance >= rightBalanceMin, 'haas.right_balance must be >= -1');
    assert(rightBalance <= rightBalanceMax, 'haas.right_balance must be <= 1');
    assert(rightDelay >= rightDelayMin, 'haas.right_delay must be >= 0');
    assert(rightDelay <= rightDelayMax, 'haas.right_delay must be <= 40');
    assert(rightGain >= rightGainMin, 'haas.right_gain must be >= 0.015625');
    assert(rightGain <= rightGainMax, 'haas.right_gain must be <= 64');
    assert(sideGain >= sideGainMin, 'haas.side_gain must be >= 0.015625');
    assert(sideGain <= sideGainMax, 'haas.side_gain must be <= 64');
    final parts = <String>[];
    if (leftBalance != -1.0)
      parts.add('left_balance=' + _wireDouble(leftBalance));
    if (leftDelay != 2.05) parts.add('left_delay=' + _wireDouble(leftDelay));
    if (leftGain != 1.0) parts.add('left_gain=' + _wireDouble(leftGain));
    if (leftPhase != false) parts.add('left_phase=' + (leftPhase ? '1' : '0'));
    if (levelIn != 1.0) parts.add('level_in=' + _wireDouble(levelIn));
    if (levelOut != 1.0) parts.add('level_out=' + _wireDouble(levelOut));
    if (middlePhase != false)
      parts.add('middle_phase=' + (middlePhase ? '1' : '0'));
    if (middleSource != HaasSource.mid)
      parts.add('middle_source=' + middleSource.mpvValue);
    if (rightBalance != 1.0)
      parts.add('right_balance=' + _wireDouble(rightBalance));
    if (rightDelay != 2.12) parts.add('right_delay=' + _wireDouble(rightDelay));
    if (rightGain != 1.0) parts.add('right_gain=' + _wireDouble(rightGain));
    if (rightPhase != true)
      parts.add('right_phase=' + (rightPhase ? '1' : '0'));
    if (sideGain != 1.0) parts.add('side_gain=' + _wireDouble(sideGain));
    return parts.isEmpty ? 'lavfi-haas' : 'lavfi-haas=' + parts.join(':');
  }
}
