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

/// Configuration for the `firequalizer` audio effect.
///
/// Apply FIR Equalization using arbitrary frequency response.
///
/// The filter accepts the following option:
///
/// Parameters:
/// - [accuracy]: Set filter accuracy in Hz. Lower value means more accurate. Default is `5`. (range 3..1e10, default 5.0)
/// - [delay]: Set filter delay in seconds. Higher value means more accurate. Default is `0.01`. (range 0.0..1e10, default 0.01)
/// - [dumpfile]: Set file for dumping, suitable for gnuplot. (range 0..0, default "")
/// - [dumpscale]: Set scale for dumpfile. Acceptable values are same with scale option. Default is linlog. (range 0..3, default SCALE_LINLOG)
/// - [fft2]: Enable 2-channel convolution using complex FFT. This improves speed significantly. Default is disabled. (range 0..1, default 0)
/// - [fixed]: If enabled, use fixed number of audio samples. This improves speed when filtering with large delay. Default is disabled. (range 0..1, default 0)
/// - [gain]: Set gain curve equation (in dB). The expression can contain variables: (range 0..0, default "gain_interpolate(f)", runtime-tunable)
/// - [gainEntry]: Set gain entry for gain_interpolate function. The expression can contain functions: (range 0..0, default "", runtime-tunable)
/// - [minPhase]: Enable minimum phase impulse response. Default is disabled. (range 0..1, default 0)
/// - [multi]: Enable multichannels evaluation on gain. Default is disabled. (range 0..1, default 0)
/// - [scale]: Set scale used by gain. Acceptable values are: (range 0..3, default SCALE_LINLOG)
/// - [wfunc]: Set window function. Acceptable values are: (range 0..9, default WFUNC_HANN)
/// - [zeroPhase]: Enable zero phase mode by subtracting timestamp to compensate delay. Default is disabled. (range 0..1, default 0)
final class FirequalizerEffect extends AudioEffect {
  /// Default value for [accuracy].
  static const double accuracyDefault = 5.0;

  /// Minimum value for [accuracy].
  static const double accuracyMin = 3.0;

  /// Maximum value for [accuracy].
  static const double accuracyMax = 1e10;

  /// Default value for [delay].
  static const double delayDefault = 0.01;

  /// Minimum value for [delay].
  static const double delayMin = 0.0;

  /// Maximum value for [delay].
  static const double delayMax = 1e10;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set accuracy
  final double accuracy;

  /// set delay
  final double delay;

  /// set dump file
  final String dumpfile;

  /// set dump scale
  final FirequalizerScale dumpscale;

  /// set 2-channels fft
  final bool fft2;

  /// set fixed frame samples
  final bool fixed;

  /// set gain curve
  final String gain;

  /// set gain entry
  final String gainEntry;

  /// set minimum phase mode
  final bool minPhase;

  /// set multi channels mode
  final bool multi;

  /// set gain scale
  final FirequalizerScale scale;

  /// set window function
  final FirequalizerWfunc wfunc;

  /// set zero phase mode
  final bool zeroPhase;

  /// Creates an [FirequalizerEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const FirequalizerEffect({
    this.enabled = true,
    this.accuracy = 5.0,
    this.delay = 0.01,
    this.dumpfile = '',
    this.dumpscale = FirequalizerScale.linlog,
    this.fft2 = false,
    this.fixed = false,
    this.gain = 'gain_interpolate(f)',
    this.gainEntry = '',
    this.minPhase = false,
    this.multi = false,
    this.scale = FirequalizerScale.linlog,
    this.wfunc = FirequalizerWfunc.hann,
    this.zeroPhase = false,
  });

  @override
  String get filterName => 'firequalizer';

  @override
  AudioFilter get filter => AudioFilter.firequalizer;

  /// Returns a copy of this [FirequalizerEffect] with the given fields replaced.
  FirequalizerEffect copyWith({
    bool? enabled,
    double? accuracy,
    double? delay,
    String? dumpfile,
    FirequalizerScale? dumpscale,
    bool? fft2,
    bool? fixed,
    String? gain,
    String? gainEntry,
    bool? minPhase,
    bool? multi,
    FirequalizerScale? scale,
    FirequalizerWfunc? wfunc,
    bool? zeroPhase,
  }) => FirequalizerEffect(
    enabled: enabled ?? this.enabled,
    accuracy: accuracy ?? this.accuracy,
    delay: delay ?? this.delay,
    dumpfile: dumpfile ?? this.dumpfile,
    dumpscale: dumpscale ?? this.dumpscale,
    fft2: fft2 ?? this.fft2,
    fixed: fixed ?? this.fixed,
    gain: gain ?? this.gain,
    gainEntry: gainEntry ?? this.gainEntry,
    minPhase: minPhase ?? this.minPhase,
    multi: multi ?? this.multi,
    scale: scale ?? this.scale,
    wfunc: wfunc ?? this.wfunc,
    zeroPhase: zeroPhase ?? this.zeroPhase,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FirequalizerEffect &&
          other.enabled == enabled &&
          other.accuracy == accuracy &&
          other.delay == delay &&
          other.dumpfile == dumpfile &&
          other.dumpscale == dumpscale &&
          other.fft2 == fft2 &&
          other.fixed == fixed &&
          other.gain == gain &&
          other.gainEntry == gainEntry &&
          other.minPhase == minPhase &&
          other.multi == multi &&
          other.scale == scale &&
          other.wfunc == wfunc &&
          other.zeroPhase == zeroPhase);

  @override
  int get hashCode => Object.hash(
    enabled,
    accuracy,
    delay,
    dumpfile,
    dumpscale,
    fft2,
    fixed,
    gain,
    gainEntry,
    minPhase,
    multi,
    scale,
    wfunc,
    zeroPhase,
  );

  @override
  String toString() =>
      'FirequalizerEffect(enabled: $enabled, accuracy: $accuracy, delay: $delay, dumpfile: $dumpfile, dumpscale: $dumpscale, fft2: $fft2, fixed: $fixed, gain: $gain, gainEntry: $gainEntry, minPhase: $minPhase, multi: $multi, scale: $scale, wfunc: $wfunc, zeroPhase: $zeroPhase)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(accuracy >= accuracyMin, 'firequalizer.accuracy must be >= 3');
    assert(accuracy <= accuracyMax, 'firequalizer.accuracy must be <= 1e10');
    assert(delay >= delayMin, 'firequalizer.delay must be >= 0.0');
    assert(delay <= delayMax, 'firequalizer.delay must be <= 1e10');
    final parts = <String>[];
    if (accuracy != 5.0) parts.add('accuracy=' + _wireDouble(accuracy));
    if (delay != 0.01) parts.add('delay=' + _wireDouble(delay));
    if (dumpfile != '') parts.add('dumpfile=' + _wireString(dumpfile));
    if (dumpscale != FirequalizerScale.linlog)
      parts.add('dumpscale=' + dumpscale.mpvValue);
    if (fft2 != false) parts.add('fft2=' + (fft2 ? '1' : '0'));
    if (fixed != false) parts.add('fixed=' + (fixed ? '1' : '0'));
    if (gain != 'gain_interpolate(f)') parts.add('gain=' + _wireString(gain));
    if (gainEntry != '') parts.add('gain_entry=' + _wireString(gainEntry));
    if (minPhase != false) parts.add('min_phase=' + (minPhase ? '1' : '0'));
    if (multi != false) parts.add('multi=' + (multi ? '1' : '0'));
    if (scale != FirequalizerScale.linlog) parts.add('scale=' + scale.mpvValue);
    if (wfunc != FirequalizerWfunc.hann) parts.add('wfunc=' + wfunc.mpvValue);
    if (zeroPhase != false) parts.add('zero_phase=' + (zeroPhase ? '1' : '0'));
    return parts.isEmpty
        ? 'lavfi-firequalizer'
        : 'lavfi-firequalizer=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant FirequalizerEffect prev) {
    final out = <(String, String)>[];
    if (accuracy != prev.accuracy) return null;
    if (delay != prev.delay) return null;
    if (dumpfile != prev.dumpfile) return null;
    if (dumpscale != prev.dumpscale) return null;
    if (fft2 != prev.fft2) return null;
    if (fixed != prev.fixed) return null;
    if (gain != prev.gain) {
      out.add(('gain', gain));
    }
    if (gainEntry != prev.gainEntry) {
      out.add(('gain_entry', gainEntry));
    }
    if (minPhase != prev.minPhase) return null;
    if (multi != prev.multi) return null;
    if (scale != prev.scale) return null;
    if (wfunc != prev.wfunc) return null;
    if (zeroPhase != prev.zeroPhase) return null;
    return out;
  }
}
