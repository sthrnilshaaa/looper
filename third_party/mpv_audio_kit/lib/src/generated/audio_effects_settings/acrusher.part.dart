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

/// Configuration for the `acrusher` audio effect.
///
/// Reduce audio bit resolution.
///
/// This filter is bit crusher with enhanced functionality. A bit crusher
/// is used to audibly reduce number of bits an audio signal is sampled
/// with. This doesn't change the bit depth at all, it just produces the
/// effect. Material reduced in bit depth sounds more harsh and "digital".
/// This filter is able to even round to continuous values instead of discrete
/// bit depths.
/// Additionally it has a D/C offset which results in different crushing of
/// the lower and the upper half of the signal.
/// An Anti-Aliasing setting is able to produce "softer" crushing sounds.
///
/// Another feature of this filter is the logarithmic mode.
/// This setting switches from linear distances between bits to logarithmic ones.
/// The result is a much more "natural" sounding crusher which doesn't gate low
/// signals for example. The human ear has a logarithmic perception,
/// so this kind of crushing is much more pleasant.
/// Logarithmic crushing is also able to get anti-aliased.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [aa]: Set anti-aliasing. (range 0..1, default .5, runtime-tunable)
/// - [bits]: Set bit reduction. (range 1..64, default 8, runtime-tunable)
/// - [dc]: Set DC. (range .25..4, default 1, runtime-tunable)
/// - [levelIn]: Set level in. (range 0.015625..64, default 1, runtime-tunable)
/// - [levelOut]: Set level out. (range 0.015625..64, default 1, runtime-tunable)
/// - [lfo]: Enable LFO. By default disabled. (range 0..1, default 0, runtime-tunable)
/// - [lforange]: Set LFO range. (range 1..250, default 20, runtime-tunable)
/// - [lforate]: Set LFO rate. (range .01..200, default .3, runtime-tunable)
/// - [mix]: Set mixing amount. (range 0..1, default .5, runtime-tunable)
/// - [mode]: Can be linear: `lin` or logarithmic: `log`. (range 0..1, default 0, runtime-tunable)
/// - [samples]: Set sample reduction. (range 1..250, default 1, runtime-tunable)
final class AcrusherEffect extends AudioEffect {
  /// Default value for [aa].
  static const double aaDefault = .5;

  /// Minimum value for [aa].
  static const double aaMin = 0.0;

  /// Maximum value for [aa].
  static const double aaMax = 1.0;

  /// Default value for [bits].
  static const double bitsDefault = 8.0;

  /// Minimum value for [bits].
  static const double bitsMin = 1.0;

  /// Maximum value for [bits].
  static const double bitsMax = 64.0;

  /// Default value for [dc].
  static const double dcDefault = 1.0;

  /// Minimum value for [dc].
  static const double dcMin = .25;

  /// Maximum value for [dc].
  static const double dcMax = 4.0;

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

  /// Default value for [lforange].
  static const double lforangeDefault = 20.0;

  /// Minimum value for [lforange].
  static const double lforangeMin = 1.0;

  /// Maximum value for [lforange].
  static const double lforangeMax = 250.0;

  /// Default value for [lforate].
  static const double lforateDefault = .3;

  /// Minimum value for [lforate].
  static const double lforateMin = .01;

  /// Maximum value for [lforate].
  static const double lforateMax = 200.0;

  /// Default value for [mix].
  static const double mixDefault = .5;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Default value for [samples].
  static const double samplesDefault = 1.0;

  /// Minimum value for [samples].
  static const double samplesMin = 1.0;

  /// Maximum value for [samples].
  static const double samplesMax = 250.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set anti-aliasing
  final double aa;

  /// set bit reduction
  final double bits;

  /// set DC
  final double dc;

  /// set level in
  final double levelIn;

  /// set level out
  final double levelOut;

  /// enable LFO
  final bool lfo;

  /// set LFO depth
  final double lforange;

  /// set LFO rate
  final double lforate;

  /// set mix
  final double mix;

  /// set mode
  final AcrusherMode mode;

  /// set sample reduction
  final double samples;

  /// Creates an [AcrusherEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AcrusherEffect({
    this.enabled = true,
    this.aa = .5,
    this.bits = 8.0,
    this.dc = 1.0,
    this.levelIn = 1.0,
    this.levelOut = 1.0,
    this.lfo = false,
    this.lforange = 20.0,
    this.lforate = .3,
    this.mix = .5,
    this.mode = AcrusherMode.lin,
    this.samples = 1.0,
  });

  @override
  String get filterName => 'acrusher';

  @override
  AudioFilter get filter => AudioFilter.acrusher;

  /// Returns a copy of this [AcrusherEffect] with the given fields replaced.
  AcrusherEffect copyWith({
    bool? enabled,
    double? aa,
    double? bits,
    double? dc,
    double? levelIn,
    double? levelOut,
    bool? lfo,
    double? lforange,
    double? lforate,
    double? mix,
    AcrusherMode? mode,
    double? samples,
  }) => AcrusherEffect(
    enabled: enabled ?? this.enabled,
    aa: aa ?? this.aa,
    bits: bits ?? this.bits,
    dc: dc ?? this.dc,
    levelIn: levelIn ?? this.levelIn,
    levelOut: levelOut ?? this.levelOut,
    lfo: lfo ?? this.lfo,
    lforange: lforange ?? this.lforange,
    lforate: lforate ?? this.lforate,
    mix: mix ?? this.mix,
    mode: mode ?? this.mode,
    samples: samples ?? this.samples,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AcrusherEffect &&
          other.enabled == enabled &&
          other.aa == aa &&
          other.bits == bits &&
          other.dc == dc &&
          other.levelIn == levelIn &&
          other.levelOut == levelOut &&
          other.lfo == lfo &&
          other.lforange == lforange &&
          other.lforate == lforate &&
          other.mix == mix &&
          other.mode == mode &&
          other.samples == samples);

  @override
  int get hashCode => Object.hash(
    enabled,
    aa,
    bits,
    dc,
    levelIn,
    levelOut,
    lfo,
    lforange,
    lforate,
    mix,
    mode,
    samples,
  );

  @override
  String toString() =>
      'AcrusherEffect(enabled: $enabled, aa: $aa, bits: $bits, dc: $dc, levelIn: $levelIn, levelOut: $levelOut, lfo: $lfo, lforange: $lforange, lforate: $lforate, mix: $mix, mode: $mode, samples: $samples)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(aa >= aaMin, 'acrusher.aa must be >= 0');
    assert(aa <= aaMax, 'acrusher.aa must be <= 1');
    assert(bits >= bitsMin, 'acrusher.bits must be >= 1');
    assert(bits <= bitsMax, 'acrusher.bits must be <= 64');
    assert(levelIn >= levelInMin, 'acrusher.level_in must be >= 0.015625');
    assert(levelIn <= levelInMax, 'acrusher.level_in must be <= 64');
    assert(levelOut >= levelOutMin, 'acrusher.level_out must be >= 0.015625');
    assert(levelOut <= levelOutMax, 'acrusher.level_out must be <= 64');
    assert(lforange >= lforangeMin, 'acrusher.lforange must be >= 1');
    assert(lforange <= lforangeMax, 'acrusher.lforange must be <= 250');
    assert(lforate >= lforateMin, 'acrusher.lforate must be >= .01');
    assert(lforate <= lforateMax, 'acrusher.lforate must be <= 200');
    assert(mix >= mixMin, 'acrusher.mix must be >= 0');
    assert(mix <= mixMax, 'acrusher.mix must be <= 1');
    assert(samples >= samplesMin, 'acrusher.samples must be >= 1');
    assert(samples <= samplesMax, 'acrusher.samples must be <= 250');
    final parts = <String>[];
    if (aa != .5) parts.add('aa=' + _wireDouble(aa));
    if (bits != 8.0) parts.add('bits=' + _wireDouble(bits));
    if (dc != 1.0) parts.add('dc=' + _wireDouble(dc));
    if (levelIn != 1.0) parts.add('level_in=' + _wireDouble(levelIn));
    if (levelOut != 1.0) parts.add('level_out=' + _wireDouble(levelOut));
    if (lfo != false) parts.add('lfo=' + (lfo ? '1' : '0'));
    if (lforange != 20.0) parts.add('lforange=' + _wireDouble(lforange));
    if (lforate != .3) parts.add('lforate=' + _wireDouble(lforate));
    if (mix != .5) parts.add('mix=' + _wireDouble(mix));
    if (mode != AcrusherMode.lin) parts.add('mode=' + mode.mpvValue);
    if (samples != 1.0) parts.add('samples=' + _wireDouble(samples));
    return parts.isEmpty
        ? 'lavfi-acrusher'
        : 'lavfi-acrusher=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AcrusherEffect prev) {
    final out = <(String, String)>[];
    if (aa != prev.aa) {
      out.add(('aa', _wireDouble(aa)));
    }
    if (bits != prev.bits) {
      out.add(('bits', _wireDouble(bits)));
    }
    if (dc != prev.dc) {
      out.add(('dc', _wireDouble(dc)));
    }
    if (levelIn != prev.levelIn) {
      out.add(('level_in', _wireDouble(levelIn)));
    }
    if (levelOut != prev.levelOut) {
      out.add(('level_out', _wireDouble(levelOut)));
    }
    if (lfo != prev.lfo) {
      out.add(('lfo', (lfo ? '1' : '0')));
    }
    if (lforange != prev.lforange) {
      out.add(('lforange', _wireDouble(lforange)));
    }
    if (lforate != prev.lforate) {
      out.add(('lforate', _wireDouble(lforate)));
    }
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (mode != prev.mode) {
      out.add(('mode', mode.mpvValue));
    }
    if (samples != prev.samples) {
      out.add(('samples', _wireDouble(samples)));
    }
    return out;
  }
}
