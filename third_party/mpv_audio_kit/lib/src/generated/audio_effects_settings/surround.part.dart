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

/// Configuration for the `surround` audio effect.
///
/// Apply audio surround upmix filter.
///
/// This filter allows to produce multichannel output from audio stream.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [allx]: Set spread usage of stereo image across X axis for all channels. Allowed range is from `-1` to `15`. By default this value is negative `-1`, and thus unused. (range -1..15, default -1, runtime-tunable)
/// - [ally]: Set spread usage of stereo image across Y axis for all channels. Allowed range is from `-1` to `15`. By default this value is negative `-1`, and thus unused. (range -1..15, default -1, runtime-tunable)
/// - [angle]: Set angle of stereo surround transform, Allowed range is from `0` to `360`. Default is `90`. (range 0..360, default 90, runtime-tunable)
/// - [bcIn]: Set back center input volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [bcOut]: Set back center output volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [bcx]: Set spread usage of stereo image across X axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [bcy]: Set spread usage of stereo image across Y axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [blIn]: Set back left input volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [blOut]: Set back left output volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [blx]: Set spread usage of stereo image across X axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [bly]: Set spread usage of stereo image across Y axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [brIn]: Set back right input volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [brOut]: Set back right output volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [brx]: Set spread usage of stereo image across X axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [bry]: Set spread usage of stereo image across Y axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [chlIn]: Set input channel layout. By default, this is `stereo`.  See channel layout syntax for the required syntax. (range 0..0, default "stereo")
/// - [chlOut]: Set output channel layout. By default, this is `5.1`.  See channel layout syntax for the required syntax. (range 0..0, default "5.1")
/// - [fcIn]: Set front center input volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [fcOut]: Set front center output volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [fcx]: Set spread usage of stereo image across X axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [fcy]: Set spread usage of stereo image across Y axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [flIn]: Set front left input volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [flOut]: Set front left output volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [flx]: Set spread usage of stereo image across X axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [fly]: Set spread usage of stereo image across Y axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [focus]: Set focus of stereo surround transform, Allowed range is from `-1` to `1`. Default is `0`. (range -1..1, default 0, runtime-tunable)
/// - [frIn]: Set front right input volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [frOut]: Set front right output volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [frx]: Set spread usage of stereo image across X axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [fry]: Set spread usage of stereo image across Y axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [levelIn]: Set input volume level. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [levelOut]: Set output volume level. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [lfe]: Enable LFE channel output if output channel layout has it. By default, this is enabled. (range 0..1, default 1, runtime-tunable)
/// - [lfeHigh]: Set LFE high cut off frequency. By default, this is `256` Hz. (range 0..512, default 256)
/// - [lfeIn]: Set LFE input volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [lfeLow]: Set LFE low cut off frequency. By default, this is `128` Hz. (range 0..256, default 128)
/// - [lfeMode]: Set LFE mode, can be `add` or `sub`. Default is `add`. In `add` mode, LFE channel is created from input audio and added to output. In `sub` mode, LFE channel is created from input audio and added to output but also all non-LFE output channels are subtracted with output LFE channel. (range 0..1, default 0, runtime-tunable)
/// - [lfeOut]: Set LFE output volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [overlap]: set window overlap (range 0..1, default 0.5, runtime-tunable)
/// - [slIn]: Set side left input volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [slOut]: Set side left output volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [slx]: Set spread usage of stereo image across X axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [sly]: Set spread usage of stereo image across Y axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [smooth]: Set temporal smoothness strength, used to gradually change factors when transforming stereo sound in time. Allowed range is from `0.0` to `1.0`. Useful to improve output quality with `focus` option values greater than `0.0`. Default is `0.0`. Only values inside this range and without edges are effective. (range 0..1, default 0, runtime-tunable)
/// - [srIn]: Set side right input volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [srOut]: Set side right output volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [srx]: Set spread usage of stereo image across X axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [sry]: Set spread usage of stereo image across Y axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [winFunc]: Set window function.  It accepts the following values: (default WFUNC_HANNING)
/// - [winSize]: Set window size. Allowed range is from `1024` to `65536`. Default size is `4096`. (range 1024..65536, default 4096)
final class SurroundEffect extends AudioEffect {
  /// Default value for [allx].
  static const double allxDefault = -1.0;

  /// Minimum value for [allx].
  static const double allxMin = -1.0;

  /// Maximum value for [allx].
  static const double allxMax = 15.0;

  /// Default value for [ally].
  static const double allyDefault = -1.0;

  /// Minimum value for [ally].
  static const double allyMin = -1.0;

  /// Maximum value for [ally].
  static const double allyMax = 15.0;

  /// Default value for [angle].
  static const double angleDefault = 90.0;

  /// Minimum value for [angle].
  static const double angleMin = 0.0;

  /// Maximum value for [angle].
  static const double angleMax = 360.0;

  /// Default value for [bcIn].
  static const double bcInDefault = 1.0;

  /// Minimum value for [bcIn].
  static const double bcInMin = 0.0;

  /// Maximum value for [bcIn].
  static const double bcInMax = 10.0;

  /// Default value for [bcOut].
  static const double bcOutDefault = 1.0;

  /// Minimum value for [bcOut].
  static const double bcOutMin = 0.0;

  /// Maximum value for [bcOut].
  static const double bcOutMax = 10.0;

  /// Default value for [bcx].
  static const double bcxDefault = 0.5;

  /// Minimum value for [bcx].
  static const double bcxMin = .06;

  /// Maximum value for [bcx].
  static const double bcxMax = 15.0;

  /// Default value for [bcy].
  static const double bcyDefault = 0.5;

  /// Minimum value for [bcy].
  static const double bcyMin = .06;

  /// Maximum value for [bcy].
  static const double bcyMax = 15.0;

  /// Default value for [blIn].
  static const double blInDefault = 1.0;

  /// Minimum value for [blIn].
  static const double blInMin = 0.0;

  /// Maximum value for [blIn].
  static const double blInMax = 10.0;

  /// Default value for [blOut].
  static const double blOutDefault = 1.0;

  /// Minimum value for [blOut].
  static const double blOutMin = 0.0;

  /// Maximum value for [blOut].
  static const double blOutMax = 10.0;

  /// Default value for [blx].
  static const double blxDefault = 0.5;

  /// Minimum value for [blx].
  static const double blxMin = .06;

  /// Maximum value for [blx].
  static const double blxMax = 15.0;

  /// Default value for [bly].
  static const double blyDefault = 0.5;

  /// Minimum value for [bly].
  static const double blyMin = .06;

  /// Maximum value for [bly].
  static const double blyMax = 15.0;

  /// Default value for [brIn].
  static const double brInDefault = 1.0;

  /// Minimum value for [brIn].
  static const double brInMin = 0.0;

  /// Maximum value for [brIn].
  static const double brInMax = 10.0;

  /// Default value for [brOut].
  static const double brOutDefault = 1.0;

  /// Minimum value for [brOut].
  static const double brOutMin = 0.0;

  /// Maximum value for [brOut].
  static const double brOutMax = 10.0;

  /// Default value for [brx].
  static const double brxDefault = 0.5;

  /// Minimum value for [brx].
  static const double brxMin = .06;

  /// Maximum value for [brx].
  static const double brxMax = 15.0;

  /// Default value for [bry].
  static const double bryDefault = 0.5;

  /// Minimum value for [bry].
  static const double bryMin = .06;

  /// Maximum value for [bry].
  static const double bryMax = 15.0;

  /// Default value for [fcIn].
  static const double fcInDefault = 1.0;

  /// Minimum value for [fcIn].
  static const double fcInMin = 0.0;

  /// Maximum value for [fcIn].
  static const double fcInMax = 10.0;

  /// Default value for [fcOut].
  static const double fcOutDefault = 1.0;

  /// Minimum value for [fcOut].
  static const double fcOutMin = 0.0;

  /// Maximum value for [fcOut].
  static const double fcOutMax = 10.0;

  /// Default value for [fcx].
  static const double fcxDefault = 0.5;

  /// Minimum value for [fcx].
  static const double fcxMin = .06;

  /// Maximum value for [fcx].
  static const double fcxMax = 15.0;

  /// Default value for [fcy].
  static const double fcyDefault = 0.5;

  /// Minimum value for [fcy].
  static const double fcyMin = .06;

  /// Maximum value for [fcy].
  static const double fcyMax = 15.0;

  /// Default value for [flIn].
  static const double flInDefault = 1.0;

  /// Minimum value for [flIn].
  static const double flInMin = 0.0;

  /// Maximum value for [flIn].
  static const double flInMax = 10.0;

  /// Default value for [flOut].
  static const double flOutDefault = 1.0;

  /// Minimum value for [flOut].
  static const double flOutMin = 0.0;

  /// Maximum value for [flOut].
  static const double flOutMax = 10.0;

  /// Default value for [flx].
  static const double flxDefault = 0.5;

  /// Minimum value for [flx].
  static const double flxMin = .06;

  /// Maximum value for [flx].
  static const double flxMax = 15.0;

  /// Default value for [fly].
  static const double flyDefault = 0.5;

  /// Minimum value for [fly].
  static const double flyMin = .06;

  /// Maximum value for [fly].
  static const double flyMax = 15.0;

  /// Default value for [focus].
  static const double focusDefault = 0.0;

  /// Minimum value for [focus].
  static const double focusMin = -1.0;

  /// Maximum value for [focus].
  static const double focusMax = 1.0;

  /// Default value for [frIn].
  static const double frInDefault = 1.0;

  /// Minimum value for [frIn].
  static const double frInMin = 0.0;

  /// Maximum value for [frIn].
  static const double frInMax = 10.0;

  /// Default value for [frOut].
  static const double frOutDefault = 1.0;

  /// Minimum value for [frOut].
  static const double frOutMin = 0.0;

  /// Maximum value for [frOut].
  static const double frOutMax = 10.0;

  /// Default value for [frx].
  static const double frxDefault = 0.5;

  /// Minimum value for [frx].
  static const double frxMin = .06;

  /// Maximum value for [frx].
  static const double frxMax = 15.0;

  /// Default value for [fry].
  static const double fryDefault = 0.5;

  /// Minimum value for [fry].
  static const double fryMin = .06;

  /// Maximum value for [fry].
  static const double fryMax = 15.0;

  /// Default value for [levelIn].
  static const double levelInDefault = 1.0;

  /// Minimum value for [levelIn].
  static const double levelInMin = 0.0;

  /// Maximum value for [levelIn].
  static const double levelInMax = 10.0;

  /// Default value for [levelOut].
  static const double levelOutDefault = 1.0;

  /// Minimum value for [levelOut].
  static const double levelOutMin = 0.0;

  /// Maximum value for [levelOut].
  static const double levelOutMax = 10.0;

  /// Default value for [lfeHigh].
  static const int lfeHighDefault = 256;

  /// Minimum value for [lfeHigh].
  static const int lfeHighMin = 0;

  /// Maximum value for [lfeHigh].
  static const int lfeHighMax = 512;

  /// Default value for [lfeIn].
  static const double lfeInDefault = 1.0;

  /// Minimum value for [lfeIn].
  static const double lfeInMin = 0.0;

  /// Maximum value for [lfeIn].
  static const double lfeInMax = 10.0;

  /// Default value for [lfeLow].
  static const int lfeLowDefault = 128;

  /// Minimum value for [lfeLow].
  static const int lfeLowMin = 0;

  /// Maximum value for [lfeLow].
  static const int lfeLowMax = 256;

  /// Default value for [lfeOut].
  static const double lfeOutDefault = 1.0;

  /// Minimum value for [lfeOut].
  static const double lfeOutMin = 0.0;

  /// Maximum value for [lfeOut].
  static const double lfeOutMax = 10.0;

  /// Default value for [overlap].
  static const double overlapDefault = 0.5;

  /// Minimum value for [overlap].
  static const double overlapMin = 0.0;

  /// Maximum value for [overlap].
  static const double overlapMax = 1.0;

  /// Default value for [slIn].
  static const double slInDefault = 1.0;

  /// Minimum value for [slIn].
  static const double slInMin = 0.0;

  /// Maximum value for [slIn].
  static const double slInMax = 10.0;

  /// Default value for [slOut].
  static const double slOutDefault = 1.0;

  /// Minimum value for [slOut].
  static const double slOutMin = 0.0;

  /// Maximum value for [slOut].
  static const double slOutMax = 10.0;

  /// Default value for [slx].
  static const double slxDefault = 0.5;

  /// Minimum value for [slx].
  static const double slxMin = .06;

  /// Maximum value for [slx].
  static const double slxMax = 15.0;

  /// Default value for [sly].
  static const double slyDefault = 0.5;

  /// Minimum value for [sly].
  static const double slyMin = .06;

  /// Maximum value for [sly].
  static const double slyMax = 15.0;

  /// Default value for [smooth].
  static const double smoothDefault = 0.0;

  /// Minimum value for [smooth].
  static const double smoothMin = 0.0;

  /// Maximum value for [smooth].
  static const double smoothMax = 1.0;

  /// Default value for [srIn].
  static const double srInDefault = 1.0;

  /// Minimum value for [srIn].
  static const double srInMin = 0.0;

  /// Maximum value for [srIn].
  static const double srInMax = 10.0;

  /// Default value for [srOut].
  static const double srOutDefault = 1.0;

  /// Minimum value for [srOut].
  static const double srOutMin = 0.0;

  /// Maximum value for [srOut].
  static const double srOutMax = 10.0;

  /// Default value for [srx].
  static const double srxDefault = 0.5;

  /// Minimum value for [srx].
  static const double srxMin = .06;

  /// Maximum value for [srx].
  static const double srxMax = 15.0;

  /// Default value for [sry].
  static const double sryDefault = 0.5;

  /// Minimum value for [sry].
  static const double sryMin = .06;

  /// Maximum value for [sry].
  static const double sryMax = 15.0;

  /// Default value for [winSize].
  static const int winSizeDefault = 4096;

  /// Minimum value for [winSize].
  static const int winSizeMin = 1024;

  /// Maximum value for [winSize].
  static const int winSizeMax = 65536;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set all channel's x spread
  final double allx;

  /// set all channel's y spread
  final double ally;

  /// set soundfield transform angle
  final double angle;

  /// set back center channel input level
  final double bcIn;

  /// set back center channel output level
  final double bcOut;

  /// set back center channel x spread
  final double bcx;

  /// set back center channel y spread
  final double bcy;

  /// set back left channel input level
  final double blIn;

  /// set back left channel output level
  final double blOut;

  /// set back left channel x spread
  final double blx;

  /// set back left channel y spread
  final double bly;

  /// set back right channel input level
  final double brIn;

  /// set back right channel output level
  final double brOut;

  /// set back right channel x spread
  final double brx;

  /// set back right channel y spread
  final double bry;

  /// set input channel layout
  final String chlIn;

  /// set output channel layout
  final String chlOut;

  /// set front center channel input level
  final double fcIn;

  /// set front center channel output level
  final double fcOut;

  /// set front center channel x spread
  final double fcx;

  /// set front center channel y spread
  final double fcy;

  /// set front left channel input level
  final double flIn;

  /// set front left channel output level
  final double flOut;

  /// set front left channel x spread
  final double flx;

  /// set front left channel y spread
  final double fly;

  /// set soundfield transform focus
  final double focus;

  /// set front right channel input level
  final double frIn;

  /// set front right channel output level
  final double frOut;

  /// set front right channel x spread
  final double frx;

  /// set front right channel y spread
  final double fry;

  /// set input level
  final double levelIn;

  /// set output level
  final double levelOut;

  /// output LFE
  final bool lfe;

  /// LFE high cut off
  final int lfeHigh;

  /// set lfe channel input level
  final double lfeIn;

  /// LFE low cut off
  final int lfeLow;

  /// set LFE channel mode
  final SurroundLfeMode lfeMode;

  /// set lfe channel output level
  final double lfeOut;

  /// set window overlap
  final double overlap;

  /// set side left channel input level
  final double slIn;

  /// set side left channel output level
  final double slOut;

  /// set side left channel x spread
  final double slx;

  /// set side left channel y spread
  final double sly;

  /// set temporal smoothness strength
  final double smooth;

  /// set side right channel input level
  final double srIn;

  /// set side right channel output level
  final double srOut;

  /// set side right channel x spread
  final double srx;

  /// set side right channel y spread
  final double sry;

  /// set window function
  final SurroundWinFunc winFunc;

  /// set window size
  final int winSize;

  /// Creates an [SurroundEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const SurroundEffect({
    this.enabled = true,
    this.allx = -1.0,
    this.ally = -1.0,
    this.angle = 90.0,
    this.bcIn = 1.0,
    this.bcOut = 1.0,
    this.bcx = 0.5,
    this.bcy = 0.5,
    this.blIn = 1.0,
    this.blOut = 1.0,
    this.blx = 0.5,
    this.bly = 0.5,
    this.brIn = 1.0,
    this.brOut = 1.0,
    this.brx = 0.5,
    this.bry = 0.5,
    this.chlIn = 'stereo',
    this.chlOut = '5.1',
    this.fcIn = 1.0,
    this.fcOut = 1.0,
    this.fcx = 0.5,
    this.fcy = 0.5,
    this.flIn = 1.0,
    this.flOut = 1.0,
    this.flx = 0.5,
    this.fly = 0.5,
    this.focus = 0.0,
    this.frIn = 1.0,
    this.frOut = 1.0,
    this.frx = 0.5,
    this.fry = 0.5,
    this.levelIn = 1.0,
    this.levelOut = 1.0,
    this.lfe = true,
    this.lfeHigh = 256,
    this.lfeIn = 1.0,
    this.lfeLow = 128,
    this.lfeMode = SurroundLfeMode.add,
    this.lfeOut = 1.0,
    this.overlap = 0.5,
    this.slIn = 1.0,
    this.slOut = 1.0,
    this.slx = 0.5,
    this.sly = 0.5,
    this.smooth = 0.0,
    this.srIn = 1.0,
    this.srOut = 1.0,
    this.srx = 0.5,
    this.sry = 0.5,
    this.winFunc = SurroundWinFunc.hann,
    this.winSize = 4096,
  });

  @override
  String get filterName => 'surround';

  @override
  AudioFilter get filter => AudioFilter.surround;

  /// Returns a copy of this [SurroundEffect] with the given fields replaced.
  SurroundEffect copyWith({
    bool? enabled,
    double? allx,
    double? ally,
    double? angle,
    double? bcIn,
    double? bcOut,
    double? bcx,
    double? bcy,
    double? blIn,
    double? blOut,
    double? blx,
    double? bly,
    double? brIn,
    double? brOut,
    double? brx,
    double? bry,
    String? chlIn,
    String? chlOut,
    double? fcIn,
    double? fcOut,
    double? fcx,
    double? fcy,
    double? flIn,
    double? flOut,
    double? flx,
    double? fly,
    double? focus,
    double? frIn,
    double? frOut,
    double? frx,
    double? fry,
    double? levelIn,
    double? levelOut,
    bool? lfe,
    int? lfeHigh,
    double? lfeIn,
    int? lfeLow,
    SurroundLfeMode? lfeMode,
    double? lfeOut,
    double? overlap,
    double? slIn,
    double? slOut,
    double? slx,
    double? sly,
    double? smooth,
    double? srIn,
    double? srOut,
    double? srx,
    double? sry,
    SurroundWinFunc? winFunc,
    int? winSize,
  }) => SurroundEffect(
    enabled: enabled ?? this.enabled,
    allx: allx ?? this.allx,
    ally: ally ?? this.ally,
    angle: angle ?? this.angle,
    bcIn: bcIn ?? this.bcIn,
    bcOut: bcOut ?? this.bcOut,
    bcx: bcx ?? this.bcx,
    bcy: bcy ?? this.bcy,
    blIn: blIn ?? this.blIn,
    blOut: blOut ?? this.blOut,
    blx: blx ?? this.blx,
    bly: bly ?? this.bly,
    brIn: brIn ?? this.brIn,
    brOut: brOut ?? this.brOut,
    brx: brx ?? this.brx,
    bry: bry ?? this.bry,
    chlIn: chlIn ?? this.chlIn,
    chlOut: chlOut ?? this.chlOut,
    fcIn: fcIn ?? this.fcIn,
    fcOut: fcOut ?? this.fcOut,
    fcx: fcx ?? this.fcx,
    fcy: fcy ?? this.fcy,
    flIn: flIn ?? this.flIn,
    flOut: flOut ?? this.flOut,
    flx: flx ?? this.flx,
    fly: fly ?? this.fly,
    focus: focus ?? this.focus,
    frIn: frIn ?? this.frIn,
    frOut: frOut ?? this.frOut,
    frx: frx ?? this.frx,
    fry: fry ?? this.fry,
    levelIn: levelIn ?? this.levelIn,
    levelOut: levelOut ?? this.levelOut,
    lfe: lfe ?? this.lfe,
    lfeHigh: lfeHigh ?? this.lfeHigh,
    lfeIn: lfeIn ?? this.lfeIn,
    lfeLow: lfeLow ?? this.lfeLow,
    lfeMode: lfeMode ?? this.lfeMode,
    lfeOut: lfeOut ?? this.lfeOut,
    overlap: overlap ?? this.overlap,
    slIn: slIn ?? this.slIn,
    slOut: slOut ?? this.slOut,
    slx: slx ?? this.slx,
    sly: sly ?? this.sly,
    smooth: smooth ?? this.smooth,
    srIn: srIn ?? this.srIn,
    srOut: srOut ?? this.srOut,
    srx: srx ?? this.srx,
    sry: sry ?? this.sry,
    winFunc: winFunc ?? this.winFunc,
    winSize: winSize ?? this.winSize,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SurroundEffect &&
          other.enabled == enabled &&
          other.allx == allx &&
          other.ally == ally &&
          other.angle == angle &&
          other.bcIn == bcIn &&
          other.bcOut == bcOut &&
          other.bcx == bcx &&
          other.bcy == bcy &&
          other.blIn == blIn &&
          other.blOut == blOut &&
          other.blx == blx &&
          other.bly == bly &&
          other.brIn == brIn &&
          other.brOut == brOut &&
          other.brx == brx &&
          other.bry == bry &&
          other.chlIn == chlIn &&
          other.chlOut == chlOut &&
          other.fcIn == fcIn &&
          other.fcOut == fcOut &&
          other.fcx == fcx &&
          other.fcy == fcy &&
          other.flIn == flIn &&
          other.flOut == flOut &&
          other.flx == flx &&
          other.fly == fly &&
          other.focus == focus &&
          other.frIn == frIn &&
          other.frOut == frOut &&
          other.frx == frx &&
          other.fry == fry &&
          other.levelIn == levelIn &&
          other.levelOut == levelOut &&
          other.lfe == lfe &&
          other.lfeHigh == lfeHigh &&
          other.lfeIn == lfeIn &&
          other.lfeLow == lfeLow &&
          other.lfeMode == lfeMode &&
          other.lfeOut == lfeOut &&
          other.overlap == overlap &&
          other.slIn == slIn &&
          other.slOut == slOut &&
          other.slx == slx &&
          other.sly == sly &&
          other.smooth == smooth &&
          other.srIn == srIn &&
          other.srOut == srOut &&
          other.srx == srx &&
          other.sry == sry &&
          other.winFunc == winFunc &&
          other.winSize == winSize);

  @override
  int get hashCode => Object.hashAll([
    enabled,
    allx,
    ally,
    angle,
    bcIn,
    bcOut,
    bcx,
    bcy,
    blIn,
    blOut,
    blx,
    bly,
    brIn,
    brOut,
    brx,
    bry,
    chlIn,
    chlOut,
    fcIn,
    fcOut,
    fcx,
    fcy,
    flIn,
    flOut,
    flx,
    fly,
    focus,
    frIn,
    frOut,
    frx,
    fry,
    levelIn,
    levelOut,
    lfe,
    lfeHigh,
    lfeIn,
    lfeLow,
    lfeMode,
    lfeOut,
    overlap,
    slIn,
    slOut,
    slx,
    sly,
    smooth,
    srIn,
    srOut,
    srx,
    sry,
    winFunc,
    winSize,
  ]);

  @override
  String toString() =>
      'SurroundEffect(enabled: $enabled, allx: $allx, ally: $ally, angle: $angle, bcIn: $bcIn, bcOut: $bcOut, bcx: $bcx, bcy: $bcy, blIn: $blIn, blOut: $blOut, blx: $blx, bly: $bly, brIn: $brIn, brOut: $brOut, brx: $brx, bry: $bry, chlIn: $chlIn, chlOut: $chlOut, fcIn: $fcIn, fcOut: $fcOut, fcx: $fcx, fcy: $fcy, flIn: $flIn, flOut: $flOut, flx: $flx, fly: $fly, focus: $focus, frIn: $frIn, frOut: $frOut, frx: $frx, fry: $fry, levelIn: $levelIn, levelOut: $levelOut, lfe: $lfe, lfeHigh: $lfeHigh, lfeIn: $lfeIn, lfeLow: $lfeLow, lfeMode: $lfeMode, lfeOut: $lfeOut, overlap: $overlap, slIn: $slIn, slOut: $slOut, slx: $slx, sly: $sly, smooth: $smooth, srIn: $srIn, srOut: $srOut, srx: $srx, sry: $sry, winFunc: $winFunc, winSize: $winSize)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(allx >= allxMin, 'surround.allx must be >= -1');
    assert(allx <= allxMax, 'surround.allx must be <= 15');
    assert(ally >= allyMin, 'surround.ally must be >= -1');
    assert(ally <= allyMax, 'surround.ally must be <= 15');
    assert(angle >= angleMin, 'surround.angle must be >= 0');
    assert(angle <= angleMax, 'surround.angle must be <= 360');
    assert(bcIn >= bcInMin, 'surround.bc_in must be >= 0');
    assert(bcIn <= bcInMax, 'surround.bc_in must be <= 10');
    assert(bcOut >= bcOutMin, 'surround.bc_out must be >= 0');
    assert(bcOut <= bcOutMax, 'surround.bc_out must be <= 10');
    assert(bcx >= bcxMin, 'surround.bcx must be >= .06');
    assert(bcx <= bcxMax, 'surround.bcx must be <= 15');
    assert(bcy >= bcyMin, 'surround.bcy must be >= .06');
    assert(bcy <= bcyMax, 'surround.bcy must be <= 15');
    assert(blIn >= blInMin, 'surround.bl_in must be >= 0');
    assert(blIn <= blInMax, 'surround.bl_in must be <= 10');
    assert(blOut >= blOutMin, 'surround.bl_out must be >= 0');
    assert(blOut <= blOutMax, 'surround.bl_out must be <= 10');
    assert(blx >= blxMin, 'surround.blx must be >= .06');
    assert(blx <= blxMax, 'surround.blx must be <= 15');
    assert(bly >= blyMin, 'surround.bly must be >= .06');
    assert(bly <= blyMax, 'surround.bly must be <= 15');
    assert(brIn >= brInMin, 'surround.br_in must be >= 0');
    assert(brIn <= brInMax, 'surround.br_in must be <= 10');
    assert(brOut >= brOutMin, 'surround.br_out must be >= 0');
    assert(brOut <= brOutMax, 'surround.br_out must be <= 10');
    assert(brx >= brxMin, 'surround.brx must be >= .06');
    assert(brx <= brxMax, 'surround.brx must be <= 15');
    assert(bry >= bryMin, 'surround.bry must be >= .06');
    assert(bry <= bryMax, 'surround.bry must be <= 15');
    assert(fcIn >= fcInMin, 'surround.fc_in must be >= 0');
    assert(fcIn <= fcInMax, 'surround.fc_in must be <= 10');
    assert(fcOut >= fcOutMin, 'surround.fc_out must be >= 0');
    assert(fcOut <= fcOutMax, 'surround.fc_out must be <= 10');
    assert(fcx >= fcxMin, 'surround.fcx must be >= .06');
    assert(fcx <= fcxMax, 'surround.fcx must be <= 15');
    assert(fcy >= fcyMin, 'surround.fcy must be >= .06');
    assert(fcy <= fcyMax, 'surround.fcy must be <= 15');
    assert(flIn >= flInMin, 'surround.fl_in must be >= 0');
    assert(flIn <= flInMax, 'surround.fl_in must be <= 10');
    assert(flOut >= flOutMin, 'surround.fl_out must be >= 0');
    assert(flOut <= flOutMax, 'surround.fl_out must be <= 10');
    assert(flx >= flxMin, 'surround.flx must be >= .06');
    assert(flx <= flxMax, 'surround.flx must be <= 15');
    assert(fly >= flyMin, 'surround.fly must be >= .06');
    assert(fly <= flyMax, 'surround.fly must be <= 15');
    assert(focus >= focusMin, 'surround.focus must be >= -1');
    assert(focus <= focusMax, 'surround.focus must be <= 1');
    assert(frIn >= frInMin, 'surround.fr_in must be >= 0');
    assert(frIn <= frInMax, 'surround.fr_in must be <= 10');
    assert(frOut >= frOutMin, 'surround.fr_out must be >= 0');
    assert(frOut <= frOutMax, 'surround.fr_out must be <= 10');
    assert(frx >= frxMin, 'surround.frx must be >= .06');
    assert(frx <= frxMax, 'surround.frx must be <= 15');
    assert(fry >= fryMin, 'surround.fry must be >= .06');
    assert(fry <= fryMax, 'surround.fry must be <= 15');
    assert(levelIn >= levelInMin, 'surround.level_in must be >= 0');
    assert(levelIn <= levelInMax, 'surround.level_in must be <= 10');
    assert(levelOut >= levelOutMin, 'surround.level_out must be >= 0');
    assert(levelOut <= levelOutMax, 'surround.level_out must be <= 10');
    assert(lfeHigh >= lfeHighMin, 'surround.lfe_high must be >= 0');
    assert(lfeHigh <= lfeHighMax, 'surround.lfe_high must be <= 512');
    assert(lfeIn >= lfeInMin, 'surround.lfe_in must be >= 0');
    assert(lfeIn <= lfeInMax, 'surround.lfe_in must be <= 10');
    assert(lfeLow >= lfeLowMin, 'surround.lfe_low must be >= 0');
    assert(lfeLow <= lfeLowMax, 'surround.lfe_low must be <= 256');
    assert(lfeOut >= lfeOutMin, 'surround.lfe_out must be >= 0');
    assert(lfeOut <= lfeOutMax, 'surround.lfe_out must be <= 10');
    assert(overlap >= overlapMin, 'surround.overlap must be >= 0');
    assert(overlap <= overlapMax, 'surround.overlap must be <= 1');
    assert(slIn >= slInMin, 'surround.sl_in must be >= 0');
    assert(slIn <= slInMax, 'surround.sl_in must be <= 10');
    assert(slOut >= slOutMin, 'surround.sl_out must be >= 0');
    assert(slOut <= slOutMax, 'surround.sl_out must be <= 10');
    assert(slx >= slxMin, 'surround.slx must be >= .06');
    assert(slx <= slxMax, 'surround.slx must be <= 15');
    assert(sly >= slyMin, 'surround.sly must be >= .06');
    assert(sly <= slyMax, 'surround.sly must be <= 15');
    assert(smooth >= smoothMin, 'surround.smooth must be >= 0');
    assert(smooth <= smoothMax, 'surround.smooth must be <= 1');
    assert(srIn >= srInMin, 'surround.sr_in must be >= 0');
    assert(srIn <= srInMax, 'surround.sr_in must be <= 10');
    assert(srOut >= srOutMin, 'surround.sr_out must be >= 0');
    assert(srOut <= srOutMax, 'surround.sr_out must be <= 10');
    assert(srx >= srxMin, 'surround.srx must be >= .06');
    assert(srx <= srxMax, 'surround.srx must be <= 15');
    assert(sry >= sryMin, 'surround.sry must be >= .06');
    assert(sry <= sryMax, 'surround.sry must be <= 15');
    assert(winSize >= winSizeMin, 'surround.win_size must be >= 1024');
    assert(winSize <= winSizeMax, 'surround.win_size must be <= 65536');
    final parts = <String>[];
    if (allx != -1.0) parts.add('allx=' + _wireDouble(allx));
    if (ally != -1.0) parts.add('ally=' + _wireDouble(ally));
    if (angle != 90.0) parts.add('angle=' + _wireDouble(angle));
    if (bcIn != 1.0) parts.add('bc_in=' + _wireDouble(bcIn));
    if (bcOut != 1.0) parts.add('bc_out=' + _wireDouble(bcOut));
    if (bcx != 0.5) parts.add('bcx=' + _wireDouble(bcx));
    if (bcy != 0.5) parts.add('bcy=' + _wireDouble(bcy));
    if (blIn != 1.0) parts.add('bl_in=' + _wireDouble(blIn));
    if (blOut != 1.0) parts.add('bl_out=' + _wireDouble(blOut));
    if (blx != 0.5) parts.add('blx=' + _wireDouble(blx));
    if (bly != 0.5) parts.add('bly=' + _wireDouble(bly));
    if (brIn != 1.0) parts.add('br_in=' + _wireDouble(brIn));
    if (brOut != 1.0) parts.add('br_out=' + _wireDouble(brOut));
    if (brx != 0.5) parts.add('brx=' + _wireDouble(brx));
    if (bry != 0.5) parts.add('bry=' + _wireDouble(bry));
    if (chlIn != 'stereo') parts.add('chl_in=' + _wireString(chlIn));
    if (chlOut != '5.1') parts.add('chl_out=' + _wireString(chlOut));
    if (fcIn != 1.0) parts.add('fc_in=' + _wireDouble(fcIn));
    if (fcOut != 1.0) parts.add('fc_out=' + _wireDouble(fcOut));
    if (fcx != 0.5) parts.add('fcx=' + _wireDouble(fcx));
    if (fcy != 0.5) parts.add('fcy=' + _wireDouble(fcy));
    if (flIn != 1.0) parts.add('fl_in=' + _wireDouble(flIn));
    if (flOut != 1.0) parts.add('fl_out=' + _wireDouble(flOut));
    if (flx != 0.5) parts.add('flx=' + _wireDouble(flx));
    if (fly != 0.5) parts.add('fly=' + _wireDouble(fly));
    if (focus != 0.0) parts.add('focus=' + _wireDouble(focus));
    if (frIn != 1.0) parts.add('fr_in=' + _wireDouble(frIn));
    if (frOut != 1.0) parts.add('fr_out=' + _wireDouble(frOut));
    if (frx != 0.5) parts.add('frx=' + _wireDouble(frx));
    if (fry != 0.5) parts.add('fry=' + _wireDouble(fry));
    if (levelIn != 1.0) parts.add('level_in=' + _wireDouble(levelIn));
    if (levelOut != 1.0) parts.add('level_out=' + _wireDouble(levelOut));
    if (lfe != true) parts.add('lfe=' + (lfe ? '1' : '0'));
    if (lfeHigh != 256) parts.add('lfe_high=' + lfeHigh.toString());
    if (lfeIn != 1.0) parts.add('lfe_in=' + _wireDouble(lfeIn));
    if (lfeLow != 128) parts.add('lfe_low=' + lfeLow.toString());
    if (lfeMode != SurroundLfeMode.add)
      parts.add('lfe_mode=' + lfeMode.mpvValue);
    if (lfeOut != 1.0) parts.add('lfe_out=' + _wireDouble(lfeOut));
    if (overlap != 0.5) parts.add('overlap=' + _wireDouble(overlap));
    if (slIn != 1.0) parts.add('sl_in=' + _wireDouble(slIn));
    if (slOut != 1.0) parts.add('sl_out=' + _wireDouble(slOut));
    if (slx != 0.5) parts.add('slx=' + _wireDouble(slx));
    if (sly != 0.5) parts.add('sly=' + _wireDouble(sly));
    if (smooth != 0.0) parts.add('smooth=' + _wireDouble(smooth));
    if (srIn != 1.0) parts.add('sr_in=' + _wireDouble(srIn));
    if (srOut != 1.0) parts.add('sr_out=' + _wireDouble(srOut));
    if (srx != 0.5) parts.add('srx=' + _wireDouble(srx));
    if (sry != 0.5) parts.add('sry=' + _wireDouble(sry));
    if (winFunc != SurroundWinFunc.hann)
      parts.add('win_func=' + winFunc.mpvValue);
    if (winSize != 4096) parts.add('win_size=' + winSize.toString());
    return parts.isEmpty
        ? 'lavfi-surround'
        : 'lavfi-surround=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant SurroundEffect prev) {
    final out = <(String, String)>[];
    if (allx != prev.allx) {
      out.add(('allx', _wireDouble(allx)));
    }
    if (ally != prev.ally) {
      out.add(('ally', _wireDouble(ally)));
    }
    if (angle != prev.angle) {
      out.add(('angle', _wireDouble(angle)));
    }
    if (bcIn != prev.bcIn) {
      out.add(('bc_in', _wireDouble(bcIn)));
    }
    if (bcOut != prev.bcOut) {
      out.add(('bc_out', _wireDouble(bcOut)));
    }
    if (bcx != prev.bcx) {
      out.add(('bcx', _wireDouble(bcx)));
    }
    if (bcy != prev.bcy) {
      out.add(('bcy', _wireDouble(bcy)));
    }
    if (blIn != prev.blIn) {
      out.add(('bl_in', _wireDouble(blIn)));
    }
    if (blOut != prev.blOut) {
      out.add(('bl_out', _wireDouble(blOut)));
    }
    if (blx != prev.blx) {
      out.add(('blx', _wireDouble(blx)));
    }
    if (bly != prev.bly) {
      out.add(('bly', _wireDouble(bly)));
    }
    if (brIn != prev.brIn) {
      out.add(('br_in', _wireDouble(brIn)));
    }
    if (brOut != prev.brOut) {
      out.add(('br_out', _wireDouble(brOut)));
    }
    if (brx != prev.brx) {
      out.add(('brx', _wireDouble(brx)));
    }
    if (bry != prev.bry) {
      out.add(('bry', _wireDouble(bry)));
    }
    if (chlIn != prev.chlIn) return null;
    if (chlOut != prev.chlOut) return null;
    if (fcIn != prev.fcIn) {
      out.add(('fc_in', _wireDouble(fcIn)));
    }
    if (fcOut != prev.fcOut) {
      out.add(('fc_out', _wireDouble(fcOut)));
    }
    if (fcx != prev.fcx) {
      out.add(('fcx', _wireDouble(fcx)));
    }
    if (fcy != prev.fcy) {
      out.add(('fcy', _wireDouble(fcy)));
    }
    if (flIn != prev.flIn) {
      out.add(('fl_in', _wireDouble(flIn)));
    }
    if (flOut != prev.flOut) {
      out.add(('fl_out', _wireDouble(flOut)));
    }
    if (flx != prev.flx) {
      out.add(('flx', _wireDouble(flx)));
    }
    if (fly != prev.fly) {
      out.add(('fly', _wireDouble(fly)));
    }
    if (focus != prev.focus) {
      out.add(('focus', _wireDouble(focus)));
    }
    if (frIn != prev.frIn) {
      out.add(('fr_in', _wireDouble(frIn)));
    }
    if (frOut != prev.frOut) {
      out.add(('fr_out', _wireDouble(frOut)));
    }
    if (frx != prev.frx) {
      out.add(('frx', _wireDouble(frx)));
    }
    if (fry != prev.fry) {
      out.add(('fry', _wireDouble(fry)));
    }
    if (levelIn != prev.levelIn) {
      out.add(('level_in', _wireDouble(levelIn)));
    }
    if (levelOut != prev.levelOut) {
      out.add(('level_out', _wireDouble(levelOut)));
    }
    if (lfe != prev.lfe) {
      out.add(('lfe', (lfe ? '1' : '0')));
    }
    if (lfeHigh != prev.lfeHigh) return null;
    if (lfeIn != prev.lfeIn) {
      out.add(('lfe_in', _wireDouble(lfeIn)));
    }
    if (lfeLow != prev.lfeLow) return null;
    if (lfeMode != prev.lfeMode) {
      out.add(('lfe_mode', lfeMode.mpvValue));
    }
    if (lfeOut != prev.lfeOut) {
      out.add(('lfe_out', _wireDouble(lfeOut)));
    }
    if (overlap != prev.overlap) {
      out.add(('overlap', _wireDouble(overlap)));
    }
    if (slIn != prev.slIn) {
      out.add(('sl_in', _wireDouble(slIn)));
    }
    if (slOut != prev.slOut) {
      out.add(('sl_out', _wireDouble(slOut)));
    }
    if (slx != prev.slx) {
      out.add(('slx', _wireDouble(slx)));
    }
    if (sly != prev.sly) {
      out.add(('sly', _wireDouble(sly)));
    }
    if (smooth != prev.smooth) {
      out.add(('smooth', _wireDouble(smooth)));
    }
    if (srIn != prev.srIn) {
      out.add(('sr_in', _wireDouble(srIn)));
    }
    if (srOut != prev.srOut) {
      out.add(('sr_out', _wireDouble(srOut)));
    }
    if (srx != prev.srx) {
      out.add(('srx', _wireDouble(srx)));
    }
    if (sry != prev.sry) {
      out.add(('sry', _wireDouble(sry)));
    }
    if (winFunc != prev.winFunc) return null;
    if (winSize != prev.winSize) return null;
    return out;
  }
}
