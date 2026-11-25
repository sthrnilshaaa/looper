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

/// Configuration for the `anequalizer` audio effect.
///
/// High-order parametric multiband equalizer for each channel.
///
/// It accepts the following parameters:
///
/// Parameters:
/// - [colors]: set channels curves colors (range 0..0, default "red|green|blue|yellow|orange|lime|pink|magenta|brown")
/// - [curves]: draw frequency response curves (range 0..1, default 0)
/// - [fscale]: set frequency scale (range 0..1, default 1)
/// - [mgain]: set max gain (range -900..900, default 60)
/// - [params]: This option string is in format: "c`chn` f=`cf` w=`w` g=`g` t=`f` | ..." Each equalizer band is separated by '|'. (range 0..0, default "")
/// - [size]: set video size (range 0..0, default "hd720")
final class AnequalizerEffect extends AudioEffect {
  /// Default value for [mgain].
  static const double mgainDefault = 60.0;

  /// Minimum value for [mgain].
  static const double mgainMin = -900.0;

  /// Maximum value for [mgain].
  static const double mgainMax = 900.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set channels curves colors
  final String colors;

  /// draw frequency response curves
  final bool curves;

  /// set frequency scale
  final AnequalizerFscale fscale;

  /// set max gain
  final double mgain;

  /// Raw values for parameters whose names start with a digit,
  /// keyed by their original ffmpeg option name.
  final String params;

  /// set video size
  final String size;

  /// Creates an [AnequalizerEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AnequalizerEffect({
    this.enabled = true,
    this.colors = 'red|green|blue|yellow|orange|lime|pink|magenta|brown',
    this.curves = false,
    this.fscale = AnequalizerFscale.log,
    this.mgain = 60.0,
    this.params = '',
    this.size = 'hd720',
  });

  @override
  String get filterName => 'anequalizer';

  @override
  AudioFilter get filter => AudioFilter.anequalizer;

  /// Returns a copy of this [AnequalizerEffect] with the given fields replaced.
  AnequalizerEffect copyWith({
    bool? enabled,
    String? colors,
    bool? curves,
    AnequalizerFscale? fscale,
    double? mgain,
    String? params,
    String? size,
  }) => AnequalizerEffect(
    enabled: enabled ?? this.enabled,
    colors: colors ?? this.colors,
    curves: curves ?? this.curves,
    fscale: fscale ?? this.fscale,
    mgain: mgain ?? this.mgain,
    params: params ?? this.params,
    size: size ?? this.size,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnequalizerEffect &&
          other.enabled == enabled &&
          other.colors == colors &&
          other.curves == curves &&
          other.fscale == fscale &&
          other.mgain == mgain &&
          other.params == params &&
          other.size == size);

  @override
  int get hashCode =>
      Object.hash(enabled, colors, curves, fscale, mgain, params, size);

  @override
  String toString() =>
      'AnequalizerEffect(enabled: $enabled, colors: $colors, curves: $curves, fscale: $fscale, mgain: $mgain, params: $params, size: $size)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(mgain >= mgainMin, 'anequalizer.mgain must be >= -900');
    assert(mgain <= mgainMax, 'anequalizer.mgain must be <= 900');
    final parts = <String>[];
    if (colors != 'red|green|blue|yellow|orange|lime|pink|magenta|brown')
      parts.add('colors=' + _wireString(colors));
    if (curves != false) parts.add('curves=' + (curves ? '1' : '0'));
    if (fscale != AnequalizerFscale.log) parts.add('fscale=' + fscale.mpvValue);
    if (mgain != 60.0) parts.add('mgain=' + _wireDouble(mgain));
    if (params != '') parts.add('params=' + _wireString(params));
    if (size != 'hd720') parts.add('size=' + _wireString(size));
    return parts.isEmpty
        ? 'lavfi-anequalizer'
        : 'lavfi-anequalizer=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AnequalizerEffect prev) {
    final out = <(String, String)>[];
    if (colors != prev.colors) return null;
    if (curves != prev.curves) return null;
    if (fscale != prev.fscale) return null;
    if (mgain != prev.mgain) return null;
    if (params != prev.params) return null;
    if (size != prev.size) return null;
    return out;
  }
}
