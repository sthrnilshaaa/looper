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

/// Configuration for the `chorus` audio effect.
///
/// Add a chorus effect to the audio.
///
/// Can make a single vocal sound like a chorus, but can also be applied to instrumentation.
///
/// Chorus resembles an echo effect with a short delay, but whereas with echo the delay is
/// constant, with chorus, it is varied using sinusoidal or triangular modulation.
/// The modulation depth defines the range the modulated delay is played before or after
/// the delay. Hence the delayed sound will sound slower or faster, that is the delayed
/// sound tuned around the original one, like in a chorus where some vocals are slightly
/// off key.
///
/// It accepts the following parameters:
///
/// Parameters:
/// - [decays]: Set decays. (range 0..0, default "")
/// - [delays]: Set delays. A typical delay is around 40ms to 60ms. (range 0..0, default "")
/// - [depths]: Set depths. (range 0..0, default "")
/// - [inGain]: Set input gain. Default is 0.4. (range 0..1, default .4)
/// - [outGain]: Set output gain. Default is 0.4. (range 0..1, default .4)
/// - [speeds]: Set speeds. (range 0..0, default "")
final class ChorusEffect extends AudioEffect {
  /// Default value for [inGain].
  static const double inGainDefault = .4;

  /// Minimum value for [inGain].
  static const double inGainMin = 0.0;

  /// Maximum value for [inGain].
  static const double inGainMax = 1.0;

  /// Default value for [outGain].
  static const double outGainDefault = .4;

  /// Minimum value for [outGain].
  static const double outGainMin = 0.0;

  /// Maximum value for [outGain].
  static const double outGainMax = 1.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set decays
  final String decays;

  /// set delays
  final String delays;

  /// set depths
  final String depths;

  /// set input gain
  final double inGain;

  /// set output gain
  final double outGain;

  /// set speeds
  final String speeds;

  /// Creates an [ChorusEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const ChorusEffect({
    this.enabled = true,
    required this.decays,
    required this.delays,
    required this.depths,
    this.inGain = .4,
    this.outGain = .4,
    required this.speeds,
  });

  @override
  String get filterName => 'chorus';

  @override
  AudioFilter get filter => AudioFilter.chorus;

  /// Returns a copy of this [ChorusEffect] with the given fields replaced.
  ChorusEffect copyWith({
    bool? enabled,
    String? decays,
    String? delays,
    String? depths,
    double? inGain,
    double? outGain,
    String? speeds,
  }) => ChorusEffect(
    enabled: enabled ?? this.enabled,
    decays: decays ?? this.decays,
    delays: delays ?? this.delays,
    depths: depths ?? this.depths,
    inGain: inGain ?? this.inGain,
    outGain: outGain ?? this.outGain,
    speeds: speeds ?? this.speeds,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChorusEffect &&
          other.enabled == enabled &&
          other.decays == decays &&
          other.delays == delays &&
          other.depths == depths &&
          other.inGain == inGain &&
          other.outGain == outGain &&
          other.speeds == speeds);

  @override
  int get hashCode =>
      Object.hash(enabled, decays, delays, depths, inGain, outGain, speeds);

  @override
  String toString() =>
      'ChorusEffect(enabled: $enabled, decays: $decays, delays: $delays, depths: $depths, inGain: $inGain, outGain: $outGain, speeds: $speeds)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(inGain >= inGainMin, 'chorus.in_gain must be >= 0');
    assert(inGain <= inGainMax, 'chorus.in_gain must be <= 1');
    assert(outGain >= outGainMin, 'chorus.out_gain must be >= 0');
    assert(outGain <= outGainMax, 'chorus.out_gain must be <= 1');
    final parts = <String>[];
    parts.add('decays=' + _wireString(decays));
    parts.add('delays=' + _wireString(delays));
    parts.add('depths=' + _wireString(depths));
    if (inGain != .4) parts.add('in_gain=' + _wireDouble(inGain));
    if (outGain != .4) parts.add('out_gain=' + _wireDouble(outGain));
    parts.add('speeds=' + _wireString(speeds));
    return parts.isEmpty ? 'lavfi-chorus' : 'lavfi-chorus=' + parts.join(':');
  }
}
