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

/// Configuration for the `stereotools` audio effect.
///
/// This filter has some handy utilities to manage stereo signals, for converting
/// M/S stereo recordings to L/R signal while having control over the parameters
/// or spreading the stereo image of master track.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [balanceIn]: Set input balance between both channels. Default is 0. Allowed range is from -1 to 1. (range -1..1, default 0, runtime-tunable)
/// - [balanceOut]: Set output balance between both channels. Default is 0. Allowed range is from -1 to 1. (range -1..1, default 0, runtime-tunable)
/// - [base]: set stereo base (range -1..1, default 0, runtime-tunable)
/// - [bmodeIn]: set balance in mode (range 0..2, default 0, runtime-tunable)
/// - [bmodeOut]: set balance out mode (range 0..2, default 0, runtime-tunable)
/// - [delay]: set delay (range -20..20, default 0, runtime-tunable)
/// - [levelIn]: Set input level before filtering for both channels. Defaults is 1. Allowed range is from 0.015625 to 64. (range 0.015625..64, default 1, runtime-tunable)
/// - [levelOut]: Set output level after filtering for both channels. Defaults is 1. Allowed range is from 0.015625 to 64. (range 0.015625..64, default 1, runtime-tunable)
/// - [mlev]: set middle level (range 0.015625..64, default 1, runtime-tunable)
/// - [mode]: Set stereo mode. Available values are: (range 0..10, default 0, runtime-tunable)
/// - [mpan]: set middle pan (range -1..1, default 0, runtime-tunable)
/// - [mutel]: Mute the left channel. Disabled by default. (range 0..1, default 0, runtime-tunable)
/// - [muter]: Mute the right channel. Disabled by default. (range 0..1, default 0, runtime-tunable)
/// - [phase]: set stereo phase (range 0..360, default 0, runtime-tunable)
/// - [phasel]: Change the phase of the left channel. Disabled by default. (range 0..1, default 0, runtime-tunable)
/// - [phaser]: Change the phase of the right channel. Disabled by default. (range 0..1, default 0, runtime-tunable)
/// - [sbal]: set side balance (range -1..1, default 0, runtime-tunable)
/// - [sclevel]: set S/C level (range 1..100, default 1, runtime-tunable)
/// - [slev]: set side level (range 0.015625..64, default 1, runtime-tunable)
/// - [softclip]: Enable softclipping. Results in analog distortion instead of harsh digital 0dB clipping. Disabled by default. (range 0..1, default 0, runtime-tunable)
final class StereotoolsEffect extends AudioEffect {
  /// Default value for [balanceIn].
  static const double balanceInDefault = 0.0;

  /// Minimum value for [balanceIn].
  static const double balanceInMin = -1.0;

  /// Maximum value for [balanceIn].
  static const double balanceInMax = 1.0;

  /// Default value for [balanceOut].
  static const double balanceOutDefault = 0.0;

  /// Minimum value for [balanceOut].
  static const double balanceOutMin = -1.0;

  /// Maximum value for [balanceOut].
  static const double balanceOutMax = 1.0;

  /// Default value for [base].
  static const double baseDefault = 0.0;

  /// Minimum value for [base].
  static const double baseMin = -1.0;

  /// Maximum value for [base].
  static const double baseMax = 1.0;

  /// Default value for [delay].
  static const double delayDefault = 0.0;

  /// Minimum value for [delay].
  static const double delayMin = -20.0;

  /// Maximum value for [delay].
  static const double delayMax = 20.0;

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

  /// Default value for [mlev].
  static const double mlevDefault = 1.0;

  /// Minimum value for [mlev].
  static const double mlevMin = 0.015625;

  /// Maximum value for [mlev].
  static const double mlevMax = 64.0;

  /// Default value for [mpan].
  static const double mpanDefault = 0.0;

  /// Minimum value for [mpan].
  static const double mpanMin = -1.0;

  /// Maximum value for [mpan].
  static const double mpanMax = 1.0;

  /// Default value for [phase].
  static const double phaseDefault = 0.0;

  /// Minimum value for [phase].
  static const double phaseMin = 0.0;

  /// Maximum value for [phase].
  static const double phaseMax = 360.0;

  /// Default value for [sbal].
  static const double sbalDefault = 0.0;

  /// Minimum value for [sbal].
  static const double sbalMin = -1.0;

  /// Maximum value for [sbal].
  static const double sbalMax = 1.0;

  /// Default value for [sclevel].
  static const double sclevelDefault = 1.0;

  /// Minimum value for [sclevel].
  static const double sclevelMin = 1.0;

  /// Maximum value for [sclevel].
  static const double sclevelMax = 100.0;

  /// Default value for [slev].
  static const double slevDefault = 1.0;

  /// Minimum value for [slev].
  static const double slevMin = 0.015625;

  /// Maximum value for [slev].
  static const double slevMax = 64.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set balance in
  final double balanceIn;

  /// set balance out
  final double balanceOut;

  /// set stereo base
  final double base;

  /// set balance in mode
  final StereotoolsBmode bmodeIn;

  /// set balance out mode
  final StereotoolsBmode bmodeOut;

  /// set delay
  final double delay;

  /// set level in
  final double levelIn;

  /// set level out
  final double levelOut;

  /// set middle level
  final double mlev;

  /// set stereo mode
  final StereotoolsMode mode;

  /// set middle pan
  final double mpan;

  /// mute L
  final bool mutel;

  /// mute R
  final bool muter;

  /// set stereo phase
  final double phase;

  /// phase L
  final bool phasel;

  /// phase R
  final bool phaser;

  /// set side balance
  final double sbal;

  /// set S/C level
  final double sclevel;

  /// set side level
  final double slev;

  /// enable softclip
  final bool softclip;

  /// Creates an [StereotoolsEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const StereotoolsEffect({
    this.enabled = true,
    this.balanceIn = 0.0,
    this.balanceOut = 0.0,
    this.base = 0.0,
    this.bmodeIn = StereotoolsBmode.balance,
    this.bmodeOut = StereotoolsBmode.balance,
    this.delay = 0.0,
    this.levelIn = 1.0,
    this.levelOut = 1.0,
    this.mlev = 1.0,
    this.mode = StereotoolsMode.lrToLr,
    this.mpan = 0.0,
    this.mutel = false,
    this.muter = false,
    this.phase = 0.0,
    this.phasel = false,
    this.phaser = false,
    this.sbal = 0.0,
    this.sclevel = 1.0,
    this.slev = 1.0,
    this.softclip = false,
  });

  @override
  String get filterName => 'stereotools';

  @override
  AudioFilter get filter => AudioFilter.stereotools;

  /// Returns a copy of this [StereotoolsEffect] with the given fields replaced.
  StereotoolsEffect copyWith({
    bool? enabled,
    double? balanceIn,
    double? balanceOut,
    double? base,
    StereotoolsBmode? bmodeIn,
    StereotoolsBmode? bmodeOut,
    double? delay,
    double? levelIn,
    double? levelOut,
    double? mlev,
    StereotoolsMode? mode,
    double? mpan,
    bool? mutel,
    bool? muter,
    double? phase,
    bool? phasel,
    bool? phaser,
    double? sbal,
    double? sclevel,
    double? slev,
    bool? softclip,
  }) => StereotoolsEffect(
    enabled: enabled ?? this.enabled,
    balanceIn: balanceIn ?? this.balanceIn,
    balanceOut: balanceOut ?? this.balanceOut,
    base: base ?? this.base,
    bmodeIn: bmodeIn ?? this.bmodeIn,
    bmodeOut: bmodeOut ?? this.bmodeOut,
    delay: delay ?? this.delay,
    levelIn: levelIn ?? this.levelIn,
    levelOut: levelOut ?? this.levelOut,
    mlev: mlev ?? this.mlev,
    mode: mode ?? this.mode,
    mpan: mpan ?? this.mpan,
    mutel: mutel ?? this.mutel,
    muter: muter ?? this.muter,
    phase: phase ?? this.phase,
    phasel: phasel ?? this.phasel,
    phaser: phaser ?? this.phaser,
    sbal: sbal ?? this.sbal,
    sclevel: sclevel ?? this.sclevel,
    slev: slev ?? this.slev,
    softclip: softclip ?? this.softclip,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StereotoolsEffect &&
          other.enabled == enabled &&
          other.balanceIn == balanceIn &&
          other.balanceOut == balanceOut &&
          other.base == base &&
          other.bmodeIn == bmodeIn &&
          other.bmodeOut == bmodeOut &&
          other.delay == delay &&
          other.levelIn == levelIn &&
          other.levelOut == levelOut &&
          other.mlev == mlev &&
          other.mode == mode &&
          other.mpan == mpan &&
          other.mutel == mutel &&
          other.muter == muter &&
          other.phase == phase &&
          other.phasel == phasel &&
          other.phaser == phaser &&
          other.sbal == sbal &&
          other.sclevel == sclevel &&
          other.slev == slev &&
          other.softclip == softclip);

  @override
  int get hashCode => Object.hashAll([
    enabled,
    balanceIn,
    balanceOut,
    base,
    bmodeIn,
    bmodeOut,
    delay,
    levelIn,
    levelOut,
    mlev,
    mode,
    mpan,
    mutel,
    muter,
    phase,
    phasel,
    phaser,
    sbal,
    sclevel,
    slev,
    softclip,
  ]);

  @override
  String toString() =>
      'StereotoolsEffect(enabled: $enabled, balanceIn: $balanceIn, balanceOut: $balanceOut, base: $base, bmodeIn: $bmodeIn, bmodeOut: $bmodeOut, delay: $delay, levelIn: $levelIn, levelOut: $levelOut, mlev: $mlev, mode: $mode, mpan: $mpan, mutel: $mutel, muter: $muter, phase: $phase, phasel: $phasel, phaser: $phaser, sbal: $sbal, sclevel: $sclevel, slev: $slev, softclip: $softclip)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(balanceIn >= balanceInMin, 'stereotools.balance_in must be >= -1');
    assert(balanceIn <= balanceInMax, 'stereotools.balance_in must be <= 1');
    assert(
      balanceOut >= balanceOutMin,
      'stereotools.balance_out must be >= -1',
    );
    assert(balanceOut <= balanceOutMax, 'stereotools.balance_out must be <= 1');
    assert(base >= baseMin, 'stereotools.base must be >= -1');
    assert(base <= baseMax, 'stereotools.base must be <= 1');
    assert(delay >= delayMin, 'stereotools.delay must be >= -20');
    assert(delay <= delayMax, 'stereotools.delay must be <= 20');
    assert(levelIn >= levelInMin, 'stereotools.level_in must be >= 0.015625');
    assert(levelIn <= levelInMax, 'stereotools.level_in must be <= 64');
    assert(
      levelOut >= levelOutMin,
      'stereotools.level_out must be >= 0.015625',
    );
    assert(levelOut <= levelOutMax, 'stereotools.level_out must be <= 64');
    assert(mlev >= mlevMin, 'stereotools.mlev must be >= 0.015625');
    assert(mlev <= mlevMax, 'stereotools.mlev must be <= 64');
    assert(mpan >= mpanMin, 'stereotools.mpan must be >= -1');
    assert(mpan <= mpanMax, 'stereotools.mpan must be <= 1');
    assert(phase >= phaseMin, 'stereotools.phase must be >= 0');
    assert(phase <= phaseMax, 'stereotools.phase must be <= 360');
    assert(sbal >= sbalMin, 'stereotools.sbal must be >= -1');
    assert(sbal <= sbalMax, 'stereotools.sbal must be <= 1');
    assert(sclevel >= sclevelMin, 'stereotools.sclevel must be >= 1');
    assert(sclevel <= sclevelMax, 'stereotools.sclevel must be <= 100');
    assert(slev >= slevMin, 'stereotools.slev must be >= 0.015625');
    assert(slev <= slevMax, 'stereotools.slev must be <= 64');
    final parts = <String>[];
    if (balanceIn != 0.0) parts.add('balance_in=' + _wireDouble(balanceIn));
    if (balanceOut != 0.0) parts.add('balance_out=' + _wireDouble(balanceOut));
    if (base != 0.0) parts.add('base=' + _wireDouble(base));
    if (bmodeIn != StereotoolsBmode.balance)
      parts.add('bmode_in=' + bmodeIn.mpvValue);
    if (bmodeOut != StereotoolsBmode.balance)
      parts.add('bmode_out=' + bmodeOut.mpvValue);
    if (delay != 0.0) parts.add('delay=' + _wireDouble(delay));
    if (levelIn != 1.0) parts.add('level_in=' + _wireDouble(levelIn));
    if (levelOut != 1.0) parts.add('level_out=' + _wireDouble(levelOut));
    if (mlev != 1.0) parts.add('mlev=' + _wireDouble(mlev));
    if (mode != StereotoolsMode.lrToLr) parts.add('mode=' + mode.mpvValue);
    if (mpan != 0.0) parts.add('mpan=' + _wireDouble(mpan));
    if (mutel != false) parts.add('mutel=' + (mutel ? '1' : '0'));
    if (muter != false) parts.add('muter=' + (muter ? '1' : '0'));
    if (phase != 0.0) parts.add('phase=' + _wireDouble(phase));
    if (phasel != false) parts.add('phasel=' + (phasel ? '1' : '0'));
    if (phaser != false) parts.add('phaser=' + (phaser ? '1' : '0'));
    if (sbal != 0.0) parts.add('sbal=' + _wireDouble(sbal));
    if (sclevel != 1.0) parts.add('sclevel=' + _wireDouble(sclevel));
    if (slev != 1.0) parts.add('slev=' + _wireDouble(slev));
    if (softclip != false) parts.add('softclip=' + (softclip ? '1' : '0'));
    return parts.isEmpty
        ? 'lavfi-stereotools'
        : 'lavfi-stereotools=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant StereotoolsEffect prev) {
    final out = <(String, String)>[];
    if (balanceIn != prev.balanceIn) {
      out.add(('balance_in', _wireDouble(balanceIn)));
    }
    if (balanceOut != prev.balanceOut) {
      out.add(('balance_out', _wireDouble(balanceOut)));
    }
    if (base != prev.base) {
      out.add(('base', _wireDouble(base)));
    }
    if (bmodeIn != prev.bmodeIn) {
      out.add(('bmode_in', bmodeIn.mpvValue));
    }
    if (bmodeOut != prev.bmodeOut) {
      out.add(('bmode_out', bmodeOut.mpvValue));
    }
    if (delay != prev.delay) {
      out.add(('delay', _wireDouble(delay)));
    }
    if (levelIn != prev.levelIn) {
      out.add(('level_in', _wireDouble(levelIn)));
    }
    if (levelOut != prev.levelOut) {
      out.add(('level_out', _wireDouble(levelOut)));
    }
    if (mlev != prev.mlev) {
      out.add(('mlev', _wireDouble(mlev)));
    }
    if (mode != prev.mode) {
      out.add(('mode', mode.mpvValue));
    }
    if (mpan != prev.mpan) {
      out.add(('mpan', _wireDouble(mpan)));
    }
    if (mutel != prev.mutel) {
      out.add(('mutel', (mutel ? '1' : '0')));
    }
    if (muter != prev.muter) {
      out.add(('muter', (muter ? '1' : '0')));
    }
    if (phase != prev.phase) {
      out.add(('phase', _wireDouble(phase)));
    }
    if (phasel != prev.phasel) {
      out.add(('phasel', (phasel ? '1' : '0')));
    }
    if (phaser != prev.phaser) {
      out.add(('phaser', (phaser ? '1' : '0')));
    }
    if (sbal != prev.sbal) {
      out.add(('sbal', _wireDouble(sbal)));
    }
    if (sclevel != prev.sclevel) {
      out.add(('sclevel', _wireDouble(sclevel)));
    }
    if (slev != prev.slev) {
      out.add(('slev', _wireDouble(slev)));
    }
    if (softclip != prev.softclip) {
      out.add(('softclip', (softclip ? '1' : '0')));
    }
    return out;
  }
}
