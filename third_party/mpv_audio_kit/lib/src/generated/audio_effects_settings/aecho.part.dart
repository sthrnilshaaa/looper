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

/// Configuration for the `aecho` audio effect.
///
/// Apply echoing to the input audio.
///
/// Echoes are reflected sound and can occur naturally amongst mountains
/// (and sometimes large buildings) when talking or shouting; digital echo
/// effects emulate this behaviour and are often used to help fill out the
/// sound of a single instrument or vocal. The time difference between the
/// original signal and the reflection is the `delay`, and the
/// loudness of the reflected signal is the `decay`.
/// Multiple echoes can have different delays and decays.
///
/// A description of the accepted parameters follows.
///
/// Parameters:
/// - [decays]: Set list of loudness of reflected signals separated by '|'. Allowed range for each `decay` is `(0 - 1.0]`. Default is `0.5`. (range 0..0, default "0.5")
/// - [delays]: Set list of time intervals in milliseconds between original signal and reflections separated by '|'. Allowed range for each `delay` is `(0 - 90000.0]`. Default is `1000`. (range 0..0, default "1000")
/// - [inGain]: Set input gain of reflected signal. Default is `0.6`. (range 0..1, default 0.6)
/// - [outGain]: Set output gain of reflected signal. Default is `0.3`. (range 0..1, default 0.3)
final class AechoEffect extends AudioEffect {
  /// Default value for [inGain].
  static const double inGainDefault = 0.6;

  /// Minimum value for [inGain].
  static const double inGainMin = 0.0;

  /// Maximum value for [inGain].
  static const double inGainMax = 1.0;

  /// Default value for [outGain].
  static const double outGainDefault = 0.3;

  /// Minimum value for [outGain].
  static const double outGainMin = 0.0;

  /// Maximum value for [outGain].
  static const double outGainMax = 1.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set list of signal decays
  final String decays;

  /// set list of signal delays
  final String delays;

  /// set signal input gain
  final double inGain;

  /// set signal output gain
  final double outGain;

  /// Creates an [AechoEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AechoEffect({
    this.enabled = true,
    this.decays = '0.5',
    this.delays = '1000',
    this.inGain = 0.6,
    this.outGain = 0.3,
  });

  @override
  String get filterName => 'aecho';

  @override
  AudioFilter get filter => AudioFilter.aecho;

  /// Returns a copy of this [AechoEffect] with the given fields replaced.
  AechoEffect copyWith({
    bool? enabled,
    String? decays,
    String? delays,
    double? inGain,
    double? outGain,
  }) => AechoEffect(
    enabled: enabled ?? this.enabled,
    decays: decays ?? this.decays,
    delays: delays ?? this.delays,
    inGain: inGain ?? this.inGain,
    outGain: outGain ?? this.outGain,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AechoEffect &&
          other.enabled == enabled &&
          other.decays == decays &&
          other.delays == delays &&
          other.inGain == inGain &&
          other.outGain == outGain);

  @override
  int get hashCode => Object.hash(enabled, decays, delays, inGain, outGain);

  @override
  String toString() =>
      'AechoEffect(enabled: $enabled, decays: $decays, delays: $delays, inGain: $inGain, outGain: $outGain)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(inGain >= inGainMin, 'aecho.in_gain must be >= 0');
    assert(inGain <= inGainMax, 'aecho.in_gain must be <= 1');
    assert(outGain >= outGainMin, 'aecho.out_gain must be >= 0');
    assert(outGain <= outGainMax, 'aecho.out_gain must be <= 1');
    final parts = <String>[];
    if (decays != '0.5') parts.add('decays=' + _wireString(decays));
    if (delays != '1000') parts.add('delays=' + _wireString(delays));
    if (inGain != 0.6) parts.add('in_gain=' + _wireDouble(inGain));
    if (outGain != 0.3) parts.add('out_gain=' + _wireDouble(outGain));
    return parts.isEmpty ? 'lavfi-aecho' : 'lavfi-aecho=' + parts.join(':');
  }
}
