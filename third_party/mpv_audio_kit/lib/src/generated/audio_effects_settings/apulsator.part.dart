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

/// Configuration for the `apulsator` audio effect.
///
/// Audio pulsator is something between an autopanner and a tremolo.
/// But it can produce funny stereo effects as well. Pulsator changes the volume
/// of the left and right channel based on a LFO (low frequency oscillator) with
/// different waveforms and shifted phases.
/// This filter have the ability to define an offset between left and right
/// channel. An offset of 0 means that both LFO shapes match each other.
/// The left and right channel are altered equally - a conventional tremolo.
/// An offset of 50% means that the shape of the right channel is exactly shifted
/// in phase (or moved backwards about half of the frequency) - pulsator acts as
/// an autopanner. At 1 both curves match again. Every setting in between moves the
/// phase shift gapless between all stages and produces some "bypassing" sounds with
/// sine and triangle waveforms. The more you set the offset near 1 (starting from
/// the 0.5) the faster the signal passes from the left to the right speaker.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [amount]: Set modulation. Define how much of original signal is affected by the LFO. (range 0..1, default 1)
/// - [bpm]: Set bpm. Default is 120. Allowed range is \[30 - 300\]. Only used if timing is set to bpm. (range 30..300, default 120)
/// - [hz]: Set frequency in Hz. Default is 2. Allowed range is \[0.01 - 100\]. Only used if timing is set to hz. (range 0.01..100, default 2)
/// - [levelIn]: Set input gain. By default it is 1. Range is \[0.015625 - 64\]. (range 0.015625..64, default 1)
/// - [levelOut]: Set output gain. By default it is 1. Range is \[0.015625 - 64\]. (range 0.015625..64, default 1)
/// - [mode]: Set waveform shape the LFO will use. Can be one of: sine, triangle, square, sawup or sawdown. Default is sine. (range 0..4, default SINE)
/// - [ms]: Set ms. Default is 500. Allowed range is \[10 - 2000\]. Only used if timing is set to ms. (range 10..2000, default 500)
/// - [offsetL]: Set left channel offset. Default is 0. Allowed range is \[0 - 1\]. (range 0..1, default 0)
/// - [offsetR]: Set right channel offset. Default is 0.5. Allowed range is \[0 - 1\]. (range 0..1, default .5)
/// - [timing]: Set possible timing mode. Can be one of: bpm, ms or hz. Default is hz. (range 0..2, default 2)
/// - [width]: Set pulse width. Default is 1. Allowed range is \[0 - 2\]. (range 0..2, default 1)
final class ApulsatorEffect extends AudioEffect {
  /// Default value for [amount].
  static const double amountDefault = 1.0;

  /// Minimum value for [amount].
  static const double amountMin = 0.0;

  /// Maximum value for [amount].
  static const double amountMax = 1.0;

  /// Default value for [bpm].
  static const double bpmDefault = 120.0;

  /// Minimum value for [bpm].
  static const double bpmMin = 30.0;

  /// Maximum value for [bpm].
  static const double bpmMax = 300.0;

  /// Default value for [hz].
  static const double hzDefault = 2.0;

  /// Minimum value for [hz].
  static const double hzMin = 0.01;

  /// Maximum value for [hz].
  static const double hzMax = 100.0;

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

  /// Default value for [ms].
  static const int msDefault = 500;

  /// Minimum value for [ms].
  static const int msMin = 10;

  /// Maximum value for [ms].
  static const int msMax = 2000;

  /// Default value for [offsetL].
  static const double offsetLDefault = 0.0;

  /// Minimum value for [offsetL].
  static const double offsetLMin = 0.0;

  /// Maximum value for [offsetL].
  static const double offsetLMax = 1.0;

  /// Default value for [offsetR].
  static const double offsetRDefault = .5;

  /// Minimum value for [offsetR].
  static const double offsetRMin = 0.0;

  /// Maximum value for [offsetR].
  static const double offsetRMax = 1.0;

  /// Default value for [width].
  static const double widthDefault = 1.0;

  /// Minimum value for [width].
  static const double widthMin = 0.0;

  /// Maximum value for [width].
  static const double widthMax = 2.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set modulation
  final double amount;

  /// set BPM
  final double bpm;

  /// set frequency
  final double hz;

  /// set input gain
  final double levelIn;

  /// set output gain
  final double levelOut;

  /// set mode
  final ApulsatorMode mode;

  /// set ms
  final int ms;

  /// set offset L
  final double offsetL;

  /// set offset R
  final double offsetR;

  /// set timing
  final ApulsatorTiming timing;

  /// set pulse width
  final double width;

  /// Creates an [ApulsatorEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const ApulsatorEffect({
    this.enabled = true,
    this.amount = 1.0,
    this.bpm = 120.0,
    this.hz = 2.0,
    this.levelIn = 1.0,
    this.levelOut = 1.0,
    this.mode = ApulsatorMode.sine,
    this.ms = 500,
    this.offsetL = 0.0,
    this.offsetR = .5,
    this.timing = ApulsatorTiming.hz,
    this.width = 1.0,
  });

  @override
  String get filterName => 'apulsator';

  @override
  AudioFilter get filter => AudioFilter.apulsator;

  /// Returns a copy of this [ApulsatorEffect] with the given fields replaced.
  ApulsatorEffect copyWith({
    bool? enabled,
    double? amount,
    double? bpm,
    double? hz,
    double? levelIn,
    double? levelOut,
    ApulsatorMode? mode,
    int? ms,
    double? offsetL,
    double? offsetR,
    ApulsatorTiming? timing,
    double? width,
  }) => ApulsatorEffect(
    enabled: enabled ?? this.enabled,
    amount: amount ?? this.amount,
    bpm: bpm ?? this.bpm,
    hz: hz ?? this.hz,
    levelIn: levelIn ?? this.levelIn,
    levelOut: levelOut ?? this.levelOut,
    mode: mode ?? this.mode,
    ms: ms ?? this.ms,
    offsetL: offsetL ?? this.offsetL,
    offsetR: offsetR ?? this.offsetR,
    timing: timing ?? this.timing,
    width: width ?? this.width,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApulsatorEffect &&
          other.enabled == enabled &&
          other.amount == amount &&
          other.bpm == bpm &&
          other.hz == hz &&
          other.levelIn == levelIn &&
          other.levelOut == levelOut &&
          other.mode == mode &&
          other.ms == ms &&
          other.offsetL == offsetL &&
          other.offsetR == offsetR &&
          other.timing == timing &&
          other.width == width);

  @override
  int get hashCode => Object.hash(
    enabled,
    amount,
    bpm,
    hz,
    levelIn,
    levelOut,
    mode,
    ms,
    offsetL,
    offsetR,
    timing,
    width,
  );

  @override
  String toString() =>
      'ApulsatorEffect(enabled: $enabled, amount: $amount, bpm: $bpm, hz: $hz, levelIn: $levelIn, levelOut: $levelOut, mode: $mode, ms: $ms, offsetL: $offsetL, offsetR: $offsetR, timing: $timing, width: $width)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(amount >= amountMin, 'apulsator.amount must be >= 0');
    assert(amount <= amountMax, 'apulsator.amount must be <= 1');
    assert(bpm >= bpmMin, 'apulsator.bpm must be >= 30');
    assert(bpm <= bpmMax, 'apulsator.bpm must be <= 300');
    assert(hz >= hzMin, 'apulsator.hz must be >= 0.01');
    assert(hz <= hzMax, 'apulsator.hz must be <= 100');
    assert(levelIn >= levelInMin, 'apulsator.level_in must be >= 0.015625');
    assert(levelIn <= levelInMax, 'apulsator.level_in must be <= 64');
    assert(levelOut >= levelOutMin, 'apulsator.level_out must be >= 0.015625');
    assert(levelOut <= levelOutMax, 'apulsator.level_out must be <= 64');
    assert(ms >= msMin, 'apulsator.ms must be >= 10');
    assert(ms <= msMax, 'apulsator.ms must be <= 2000');
    assert(offsetL >= offsetLMin, 'apulsator.offset_l must be >= 0');
    assert(offsetL <= offsetLMax, 'apulsator.offset_l must be <= 1');
    assert(offsetR >= offsetRMin, 'apulsator.offset_r must be >= 0');
    assert(offsetR <= offsetRMax, 'apulsator.offset_r must be <= 1');
    assert(width >= widthMin, 'apulsator.width must be >= 0');
    assert(width <= widthMax, 'apulsator.width must be <= 2');
    final parts = <String>[];
    if (amount != 1.0) parts.add('amount=' + _wireDouble(amount));
    if (bpm != 120.0) parts.add('bpm=' + _wireDouble(bpm));
    if (hz != 2.0) parts.add('hz=' + _wireDouble(hz));
    if (levelIn != 1.0) parts.add('level_in=' + _wireDouble(levelIn));
    if (levelOut != 1.0) parts.add('level_out=' + _wireDouble(levelOut));
    if (mode != ApulsatorMode.sine) parts.add('mode=' + mode.mpvValue);
    if (ms != 500) parts.add('ms=' + ms.toString());
    if (offsetL != 0.0) parts.add('offset_l=' + _wireDouble(offsetL));
    if (offsetR != .5) parts.add('offset_r=' + _wireDouble(offsetR));
    if (timing != ApulsatorTiming.hz) parts.add('timing=' + timing.mpvValue);
    if (width != 1.0) parts.add('width=' + _wireDouble(width));
    return parts.isEmpty
        ? 'lavfi-apulsator'
        : 'lavfi-apulsator=' + parts.join(':');
  }
}
