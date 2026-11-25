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

/// Configuration for the `aformat` audio effect.
///
/// Set output format constraints for the input audio. The framework will
/// negotiate the most appropriate format to minimize conversions.
///
/// It accepts the following parameters:
///
/// Parameters:
/// - [channelLayouts]: A '|'-separated list of requested channel layouts.  See channel layout syntax for the required syntax. (array, base=AV_OPT_TYPE_CHLAYOUT, sep='|')
/// - [sampleFmts]: A '|'-separated list of requested sample formats. (array, base=AV_OPT_TYPE_SAMPLE_FMT, sep='|')
/// - [sampleRates]: A '|'-separated list of requested sample rates. (range 1..2147483647, array, base=AV_OPT_TYPE_INT, sep='|')
final class AformatEffect extends AudioEffect {
  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// A '|'-separated list of channel layouts.
  final String? channelLayouts;

  /// A '|'-separated list of sample formats.
  final String? sampleFmts;

  /// A '|'-separated list of sample rates.
  final String? sampleRates;

  /// Creates an [AformatEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AformatEffect({
    this.enabled = true,
    this.channelLayouts,
    this.sampleFmts,
    this.sampleRates,
  });

  @override
  String get filterName => 'aformat';

  @override
  AudioFilter get filter => AudioFilter.aformat;

  /// Returns a copy of this [AformatEffect] with the given fields replaced.
  AformatEffect copyWith({
    bool? enabled,
    Object? channelLayouts = unset,
    Object? sampleFmts = unset,
    Object? sampleRates = unset,
  }) => AformatEffect(
    enabled: enabled ?? this.enabled,
    channelLayouts: identical(channelLayouts, unset)
        ? this.channelLayouts
        : channelLayouts as String?,
    sampleFmts: identical(sampleFmts, unset)
        ? this.sampleFmts
        : sampleFmts as String?,
    sampleRates: identical(sampleRates, unset)
        ? this.sampleRates
        : sampleRates as String?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AformatEffect &&
          other.enabled == enabled &&
          other.channelLayouts == channelLayouts &&
          other.sampleFmts == sampleFmts &&
          other.sampleRates == sampleRates);

  @override
  int get hashCode =>
      Object.hash(enabled, channelLayouts, sampleFmts, sampleRates);

  @override
  String toString() =>
      'AformatEffect(enabled: $enabled, channelLayouts: $channelLayouts, sampleFmts: $sampleFmts, sampleRates: $sampleRates)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    final parts = <String>[];
    if (channelLayouts != null)
      parts.add('channel_layouts=' + _wireString(channelLayouts!));
    if (sampleFmts != null)
      parts.add('sample_fmts=' + _wireString(sampleFmts!));
    if (sampleRates != null)
      parts.add('sample_rates=' + _wireString(sampleRates!));
    return parts.isEmpty ? 'lavfi-aformat' : 'lavfi-aformat=' + parts.join(':');
  }
}
