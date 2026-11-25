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

/// Configuration for the `hdcd` audio effect.
///
/// Decodes High Definition Compatible Digital (HDCD) data. A 16-bit PCM stream with
/// embedded HDCD codes is expanded into a 20-bit PCM stream.
///
/// The filter supports the Peak Extend and Low-level Gain Adjustment features
/// of HDCD, and detects the Transient Filter flag.
///
/// When using the filter with wav, note the default encoding for wav is 16-bit,
/// so the resulting 20-bit stream will be truncated back to 16-bit. Use something
/// like @command{-acodec pcm_s24le} after the filter to get 24-bit PCM output.
///
/// ffmpeg -i HDCD16.wav -af hdcd -c:a pcm_s24le OUT24.wav
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [analyzeMode]: Replace audio with a solid tone and adjust the amplitude to signal some specific aspect of the decoding process. The output file can be loaded in an audio editor alongside the original to aid analysis.  `analyze_mode=pe:force_pe=true` can be used to see all samples above the PE level.  Modes are: (range 0..4, default HDCD_ANA_OFF)
/// - [bitsPerSample]: Valid bits per sample (location of the true LSB). (range 16..24, default 16)
/// - [cdtMs]: Set the code detect timer period in ms. (range 100..60000, default 2000)
/// - [disableAutoconvert]: Disable any automatic format conversion or resampling in the filter graph. (range 0..1, default 1)
/// - [forcePe]: Always extend peaks above -3dBFS even if PE isn't signaled. (range 0..1, default 0)
/// - [processStereo]: Process the stereo channels together. If target_gain does not match between channels, consider it invalid and use the last valid target_gain. (range 0..1, default HDCD_PROCESS_STEREO_DEFAULT)
final class HdcdEffect extends AudioEffect {
  /// Default value for [cdtMs].
  static const int cdtMsDefault = 2000;

  /// Minimum value for [cdtMs].
  static const int cdtMsMin = 100;

  /// Maximum value for [cdtMs].
  static const int cdtMsMax = 60000;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// Replace audio with solid tone and signal some processing aspect in the amplitude.
  final HdcdAnalyzeMode analyzeMode;

  /// Valid bits per sample (location of the true LSB).
  final HdcdBitsPerSample bitsPerSample;

  /// Code detect timer period in ms.
  final int cdtMs;

  /// Disable any format conversion or resampling in the filter graph.
  final bool disableAutoconvert;

  /// Always extend peaks above -3dBFS even when PE is not signaled.
  final bool forcePe;

  /// Process stereo channels together. Only apply target_gain when both channels match.
  final bool processStereo;

  /// Creates an [HdcdEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const HdcdEffect({
    this.enabled = true,
    this.analyzeMode = HdcdAnalyzeMode.off,
    this.bitsPerSample = HdcdBitsPerSample.n16,
    this.cdtMs = 2000,
    this.disableAutoconvert = true,
    this.forcePe = false,
    this.processStereo = false,
  });

  @override
  String get filterName => 'hdcd';

  @override
  AudioFilter get filter => AudioFilter.hdcd;

  /// Returns a copy of this [HdcdEffect] with the given fields replaced.
  HdcdEffect copyWith({
    bool? enabled,
    HdcdAnalyzeMode? analyzeMode,
    HdcdBitsPerSample? bitsPerSample,
    int? cdtMs,
    bool? disableAutoconvert,
    bool? forcePe,
    bool? processStereo,
  }) => HdcdEffect(
    enabled: enabled ?? this.enabled,
    analyzeMode: analyzeMode ?? this.analyzeMode,
    bitsPerSample: bitsPerSample ?? this.bitsPerSample,
    cdtMs: cdtMs ?? this.cdtMs,
    disableAutoconvert: disableAutoconvert ?? this.disableAutoconvert,
    forcePe: forcePe ?? this.forcePe,
    processStereo: processStereo ?? this.processStereo,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HdcdEffect &&
          other.enabled == enabled &&
          other.analyzeMode == analyzeMode &&
          other.bitsPerSample == bitsPerSample &&
          other.cdtMs == cdtMs &&
          other.disableAutoconvert == disableAutoconvert &&
          other.forcePe == forcePe &&
          other.processStereo == processStereo);

  @override
  int get hashCode => Object.hash(
    enabled,
    analyzeMode,
    bitsPerSample,
    cdtMs,
    disableAutoconvert,
    forcePe,
    processStereo,
  );

  @override
  String toString() =>
      'HdcdEffect(enabled: $enabled, analyzeMode: $analyzeMode, bitsPerSample: $bitsPerSample, cdtMs: $cdtMs, disableAutoconvert: $disableAutoconvert, forcePe: $forcePe, processStereo: $processStereo)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(cdtMs >= cdtMsMin, 'hdcd.cdt_ms must be >= 100');
    assert(cdtMs <= cdtMsMax, 'hdcd.cdt_ms must be <= 60000');
    final parts = <String>[];
    if (analyzeMode != HdcdAnalyzeMode.off)
      parts.add('analyze_mode=' + analyzeMode.mpvValue);
    if (bitsPerSample != HdcdBitsPerSample.n16)
      parts.add('bits_per_sample=' + bitsPerSample.mpvValue);
    if (cdtMs != 2000) parts.add('cdt_ms=' + cdtMs.toString());
    if (disableAutoconvert != true)
      parts.add('disable_autoconvert=' + (disableAutoconvert ? '1' : '0'));
    if (forcePe != false) parts.add('force_pe=' + (forcePe ? '1' : '0'));
    if (processStereo != false)
      parts.add('process_stereo=' + (processStereo ? '1' : '0'));
    return parts.isEmpty ? 'lavfi-hdcd' : 'lavfi-hdcd=' + parts.join(':');
  }
}
