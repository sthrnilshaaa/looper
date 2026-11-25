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

/// Configuration for the `aresample` audio effect.
///
/// Resample the input audio to the specified parameters, using the
/// libswresample library. If none are specified then the filter will
/// automatically convert between its input and output.
///
/// This filter is also able to stretch/squeeze the audio data to make it match
/// the timestamps or to inject silence / cut out audio to make it match the
/// timestamps, do a combination of both or do neither.
///
/// The filter accepts the syntax
/// \[`sample_rate`:\]`resampler_options`, where `sample_rate`
/// expresses a sample rate and `resampler_options` is a list of
/// `key`=`value` pairs, separated by ":". See the
/// Resampler Options
/// for the complete list of supported options.
///
/// Resample the input audio to 44100Hz:
///
/// - Stretch/squeeze samples to the given timestamps, with a maximum of 1000
/// samples per second compensation:
///
/// Parameters:
/// - [sampleRate]:  (range 0..768000, default 0)
final class AresampleEffect extends AudioEffect {
  /// Default value for [sampleRate].
  static const int sampleRateDefault = 0;

  /// Minimum value for [sampleRate].
  static const int sampleRateMin = 0;

  /// Maximum value for [sampleRate].
  static const int sampleRateMax = 768000;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// The `sampleRate` parameter.
  final int sampleRate;

  /// Creates an [AresampleEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AresampleEffect({this.enabled = true, this.sampleRate = 0});

  @override
  String get filterName => 'aresample';

  @override
  AudioFilter get filter => AudioFilter.aresample;

  /// Returns a copy of this [AresampleEffect] with the given fields replaced.
  AresampleEffect copyWith({bool? enabled, int? sampleRate}) => AresampleEffect(
    enabled: enabled ?? this.enabled,
    sampleRate: sampleRate ?? this.sampleRate,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AresampleEffect &&
          other.enabled == enabled &&
          other.sampleRate == sampleRate);

  @override
  int get hashCode => Object.hash(enabled, sampleRate);

  @override
  String toString() =>
      'AresampleEffect(enabled: $enabled, sampleRate: $sampleRate)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(sampleRate >= sampleRateMin, 'aresample.sample_rate must be >= 0');
    assert(
      sampleRate <= sampleRateMax,
      'aresample.sample_rate must be <= 768000',
    );
    final parts = <String>[];
    if (sampleRate != 0) parts.add('sample_rate=' + sampleRate.toString());
    return parts.isEmpty
        ? 'lavfi-aresample'
        : 'lavfi-aresample=' + parts.join(':');
  }
}
