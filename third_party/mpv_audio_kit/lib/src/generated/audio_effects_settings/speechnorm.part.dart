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

/// Configuration for the `speechnorm` audio effect.
///
/// Speech Normalizer.
///
/// This filter expands or compresses each half-cycle of audio samples
/// (local set of samples all above or all below zero and between two nearest zero crossings) depending
/// on threshold value, so audio reaches target peak value under conditions controlled by below options.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [channels]: Specify which channels to filter, by default all available channels are filtered. (range 0..0, default "all", runtime-tunable)
/// - [compression]: Set the maximum compression factor. Allowed range is from 1.0 to 50.0. Default value is 2.0. This option controls maximum local half-cycle of samples compression. This option is used only if @option{threshold} option is set to value greater than 0.0, then in such cases when local peak is lower or same as value set by @option{threshold} all samples belonging to that peak's half-cycle will be compressed by current compression factor. (range 1.0..50.0, default 2.0, runtime-tunable)
/// - [expansion]: Set the maximum expansion factor. Allowed range is from 1.0 to 50.0. Default value is 2.0. This option controls maximum local half-cycle of samples expansion. The maximum expansion would be such that local peak value reaches target peak value but never to surpass it and that ratio between new and previous peak value does not surpass this option value. (range 1.0..50.0, default 2.0, runtime-tunable)
/// - [fall]: Set the compression raising amount per each half-cycle of samples. Default value is 0.001. Allowed range is from 0.0 to 1.0. This controls how fast compression factor is raised per each new half-cycle until it reaches @option{compression} value. (range 0.0..1.0, default 0.001, runtime-tunable)
/// - [invert]: Enable inverted filtering, by default is disabled. This inverts interpretation of @option{threshold} option. When enabled any half-cycle of samples with their local peak value below or same as @option{threshold} option will be expanded otherwise it will be compressed. (range 0..1, default 0, runtime-tunable)
/// - [link]: Link channels when calculating gain applied to each filtered channel sample, by default is disabled. When disabled each filtered channel gain calculation is independent, otherwise when this option is enabled the minimum of all possible gains for each filtered channel is used. (range 0..1, default 0, runtime-tunable)
/// - [peak]: Set the expansion target peak value. This specifies the highest allowed absolute amplitude level for the normalized audio input. Default value is 0.95. Allowed range is from 0.0 to 1.0. (range 0.0..1.0, default 0.95, runtime-tunable)
/// - [raise]: Set the expansion raising amount per each half-cycle of samples. Default value is 0.001. Allowed range is from 0.0 to 1.0. This controls how fast expansion factor is raised per each new half-cycle until it reaches @option{expansion} value. Setting this options too high may lead to distortions. (range 0.0..1.0, default 0.001, runtime-tunable)
/// - [rms]: Set the expansion target RMS value. This specifies the highest allowed RMS level for the normalized audio input. Default value is 0.0, thus disabled. Allowed range is from 0.0 to 1.0. (range 0.0..1.0, default 0.0, runtime-tunable)
/// - [threshold]: Set the threshold value. Default value is 0.0. Allowed range is from 0.0 to 1.0. This option specifies which half-cycles of samples will be compressed and which will be expanded. Any half-cycle samples with their local peak value below or same as this option value will be compressed by current compression factor, otherwise, if greater than threshold value they will be expanded with expansion factor so that it could reach peak target value but never surpass it. (range 0.0..1.0, default 0, runtime-tunable)
final class SpeechnormEffect extends AudioEffect {
  /// Default value for [compression].
  static const double compressionDefault = 2.0;

  /// Minimum value for [compression].
  static const double compressionMin = 1.0;

  /// Maximum value for [compression].
  static const double compressionMax = 50.0;

  /// Default value for [expansion].
  static const double expansionDefault = 2.0;

  /// Minimum value for [expansion].
  static const double expansionMin = 1.0;

  /// Maximum value for [expansion].
  static const double expansionMax = 50.0;

  /// Default value for [fall].
  static const double fallDefault = 0.001;

  /// Minimum value for [fall].
  static const double fallMin = 0.0;

  /// Maximum value for [fall].
  static const double fallMax = 1.0;

  /// Default value for [peak].
  static const double peakDefault = 0.95;

  /// Minimum value for [peak].
  static const double peakMin = 0.0;

  /// Maximum value for [peak].
  static const double peakMax = 1.0;

  /// Default value for [raise].
  static const double raiseDefault = 0.001;

  /// Minimum value for [raise].
  static const double raiseMin = 0.0;

  /// Maximum value for [raise].
  static const double raiseMax = 1.0;

  /// Default value for [rms].
  static const double rmsDefault = 0.0;

  /// Minimum value for [rms].
  static const double rmsMin = 0.0;

  /// Maximum value for [rms].
  static const double rmsMax = 1.0;

  /// Default value for [threshold].
  static const double thresholdDefault = 0.0;

  /// Minimum value for [threshold].
  static const double thresholdMin = 0.0;

  /// Maximum value for [threshold].
  static const double thresholdMax = 1.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set channels to filter
  final String channels;

  /// set the max compression factor
  final double compression;

  /// set the max expansion factor
  final double expansion;

  /// set the compression raising amount
  final double fall;

  /// set inverted filtering
  final bool invert;

  /// set linked channels filtering
  final bool link;

  /// set the peak value
  final double peak;

  /// set the expansion raising amount
  final double raise;

  /// set the RMS value
  final double rms;

  /// set the threshold value
  final double threshold;

  /// Creates an [SpeechnormEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const SpeechnormEffect({
    this.enabled = true,
    this.channels = 'all',
    this.compression = 2.0,
    this.expansion = 2.0,
    this.fall = 0.001,
    this.invert = false,
    this.link = false,
    this.peak = 0.95,
    this.raise = 0.001,
    this.rms = 0.0,
    this.threshold = 0.0,
  });

  @override
  String get filterName => 'speechnorm';

  @override
  AudioFilter get filter => AudioFilter.speechnorm;

  /// Returns a copy of this [SpeechnormEffect] with the given fields replaced.
  SpeechnormEffect copyWith({
    bool? enabled,
    String? channels,
    double? compression,
    double? expansion,
    double? fall,
    bool? invert,
    bool? link,
    double? peak,
    double? raise,
    double? rms,
    double? threshold,
  }) => SpeechnormEffect(
    enabled: enabled ?? this.enabled,
    channels: channels ?? this.channels,
    compression: compression ?? this.compression,
    expansion: expansion ?? this.expansion,
    fall: fall ?? this.fall,
    invert: invert ?? this.invert,
    link: link ?? this.link,
    peak: peak ?? this.peak,
    raise: raise ?? this.raise,
    rms: rms ?? this.rms,
    threshold: threshold ?? this.threshold,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SpeechnormEffect &&
          other.enabled == enabled &&
          other.channels == channels &&
          other.compression == compression &&
          other.expansion == expansion &&
          other.fall == fall &&
          other.invert == invert &&
          other.link == link &&
          other.peak == peak &&
          other.raise == raise &&
          other.rms == rms &&
          other.threshold == threshold);

  @override
  int get hashCode => Object.hash(
    enabled,
    channels,
    compression,
    expansion,
    fall,
    invert,
    link,
    peak,
    raise,
    rms,
    threshold,
  );

  @override
  String toString() =>
      'SpeechnormEffect(enabled: $enabled, channels: $channels, compression: $compression, expansion: $expansion, fall: $fall, invert: $invert, link: $link, peak: $peak, raise: $raise, rms: $rms, threshold: $threshold)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(
      compression >= compressionMin,
      'speechnorm.compression must be >= 1.0',
    );
    assert(
      compression <= compressionMax,
      'speechnorm.compression must be <= 50.0',
    );
    assert(expansion >= expansionMin, 'speechnorm.expansion must be >= 1.0');
    assert(expansion <= expansionMax, 'speechnorm.expansion must be <= 50.0');
    assert(fall >= fallMin, 'speechnorm.fall must be >= 0.0');
    assert(fall <= fallMax, 'speechnorm.fall must be <= 1.0');
    assert(peak >= peakMin, 'speechnorm.peak must be >= 0.0');
    assert(peak <= peakMax, 'speechnorm.peak must be <= 1.0');
    assert(raise >= raiseMin, 'speechnorm.raise must be >= 0.0');
    assert(raise <= raiseMax, 'speechnorm.raise must be <= 1.0');
    assert(rms >= rmsMin, 'speechnorm.rms must be >= 0.0');
    assert(rms <= rmsMax, 'speechnorm.rms must be <= 1.0');
    assert(threshold >= thresholdMin, 'speechnorm.threshold must be >= 0.0');
    assert(threshold <= thresholdMax, 'speechnorm.threshold must be <= 1.0');
    final parts = <String>[];
    if (channels != 'all') parts.add('channels=' + _wireString(channels));
    if (compression != 2.0)
      parts.add('compression=' + _wireDouble(compression));
    if (expansion != 2.0) parts.add('expansion=' + _wireDouble(expansion));
    if (fall != 0.001) parts.add('fall=' + _wireDouble(fall));
    if (invert != false) parts.add('invert=' + (invert ? '1' : '0'));
    if (link != false) parts.add('link=' + (link ? '1' : '0'));
    if (peak != 0.95) parts.add('peak=' + _wireDouble(peak));
    if (raise != 0.001) parts.add('raise=' + _wireDouble(raise));
    if (rms != 0.0) parts.add('rms=' + _wireDouble(rms));
    if (threshold != 0.0) parts.add('threshold=' + _wireDouble(threshold));
    return parts.isEmpty
        ? 'lavfi-speechnorm'
        : 'lavfi-speechnorm=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant SpeechnormEffect prev) {
    final out = <(String, String)>[];
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (compression != prev.compression) {
      out.add(('compression', _wireDouble(compression)));
    }
    if (expansion != prev.expansion) {
      out.add(('expansion', _wireDouble(expansion)));
    }
    if (fall != prev.fall) {
      out.add(('fall', _wireDouble(fall)));
    }
    if (invert != prev.invert) {
      out.add(('invert', (invert ? '1' : '0')));
    }
    if (link != prev.link) {
      out.add(('link', (link ? '1' : '0')));
    }
    if (peak != prev.peak) {
      out.add(('peak', _wireDouble(peak)));
    }
    if (raise != prev.raise) {
      out.add(('raise', _wireDouble(raise)));
    }
    if (rms != prev.rms) {
      out.add(('rms', _wireDouble(rms)));
    }
    if (threshold != prev.threshold) {
      out.add(('threshold', _wireDouble(threshold)));
    }
    return out;
  }
}
