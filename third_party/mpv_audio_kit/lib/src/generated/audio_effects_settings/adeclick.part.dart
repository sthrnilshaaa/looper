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

/// Configuration for the `adeclick` audio effect.
///
/// Remove impulsive noise from input audio.
///
/// Samples detected as impulsive noise are replaced by interpolated samples using
/// autoregressive modelling.
///
/// Parameters:
/// - [arorder]: Set autoregression order, in percentage of window size. Allowed range is from `0` to `25`. Default value is `2` percent. This option also controls quality of interpolated samples using neighbour good samples. (range 0..25, default 2)
/// - [burst]: Set burst fusion, in percentage of window size. Allowed range is `0` to `10`. Default value is `2`. If any two samples detected as noise are spaced less than this value then any sample between those two samples will be also detected as noise. (range 0..10, default 2)
/// - [method]: Set overlap method.  It accepts the following values: (range 0..1, default 0)
/// - [overlap]: Set window overlap, in percentage of window size. Allowed range is from `50` to `95`. Default value is `75` percent. Setting this to a very high value increases impulsive noise removal but makes whole process much slower. (range 50..95, default 75)
/// - [threshold]: Set threshold value. Allowed range is from `1` to `100`. Default value is `2`. This controls the strength of impulsive noise which is going to be removed. The lower value, the more samples will be detected as impulsive noise. (range 1..100, default 2)
/// - [window]: Set window size, in milliseconds. Allowed range is from `10` to `100`. Default value is `55` milliseconds. This sets size of window which will be processed at once. (range 10..100, default 55)
final class AdeclickEffect extends AudioEffect {
  /// Default value for [arorder].
  static const double arorderDefault = 2.0;

  /// Minimum value for [arorder].
  static const double arorderMin = 0.0;

  /// Maximum value for [arorder].
  static const double arorderMax = 25.0;

  /// Default value for [burst].
  static const double burstDefault = 2.0;

  /// Minimum value for [burst].
  static const double burstMin = 0.0;

  /// Maximum value for [burst].
  static const double burstMax = 10.0;

  /// Default value for [overlap].
  static const double overlapDefault = 75.0;

  /// Minimum value for [overlap].
  static const double overlapMin = 50.0;

  /// Maximum value for [overlap].
  static const double overlapMax = 95.0;

  /// Default value for [threshold].
  static const double thresholdDefault = 2.0;

  /// Minimum value for [threshold].
  static const double thresholdMin = 1.0;

  /// Maximum value for [threshold].
  static const double thresholdMax = 100.0;

  /// Default value for [window].
  static const double windowDefault = 55.0;

  /// Minimum value for [window].
  static const double windowMin = 10.0;

  /// Maximum value for [window].
  static const double windowMax = 100.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set autoregression order
  final double arorder;

  /// set burst fusion
  final double burst;

  /// set overlap method
  final AdeclickM method;

  /// set window overlap
  final double overlap;

  /// set threshold
  final double threshold;

  /// set window size
  final double window;

  /// Creates an [AdeclickEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AdeclickEffect({
    this.enabled = true,
    this.arorder = 2.0,
    this.burst = 2.0,
    this.method = AdeclickM.add,
    this.overlap = 75.0,
    this.threshold = 2.0,
    this.window = 55.0,
  });

  @override
  String get filterName => 'adeclick';

  @override
  AudioFilter get filter => AudioFilter.adeclick;

  /// Returns a copy of this [AdeclickEffect] with the given fields replaced.
  AdeclickEffect copyWith({
    bool? enabled,
    double? arorder,
    double? burst,
    AdeclickM? method,
    double? overlap,
    double? threshold,
    double? window,
  }) => AdeclickEffect(
    enabled: enabled ?? this.enabled,
    arorder: arorder ?? this.arorder,
    burst: burst ?? this.burst,
    method: method ?? this.method,
    overlap: overlap ?? this.overlap,
    threshold: threshold ?? this.threshold,
    window: window ?? this.window,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdeclickEffect &&
          other.enabled == enabled &&
          other.arorder == arorder &&
          other.burst == burst &&
          other.method == method &&
          other.overlap == overlap &&
          other.threshold == threshold &&
          other.window == window);

  @override
  int get hashCode =>
      Object.hash(enabled, arorder, burst, method, overlap, threshold, window);

  @override
  String toString() =>
      'AdeclickEffect(enabled: $enabled, arorder: $arorder, burst: $burst, method: $method, overlap: $overlap, threshold: $threshold, window: $window)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(arorder >= arorderMin, 'adeclick.arorder must be >= 0');
    assert(arorder <= arorderMax, 'adeclick.arorder must be <= 25');
    assert(burst >= burstMin, 'adeclick.burst must be >= 0');
    assert(burst <= burstMax, 'adeclick.burst must be <= 10');
    assert(overlap >= overlapMin, 'adeclick.overlap must be >= 50');
    assert(overlap <= overlapMax, 'adeclick.overlap must be <= 95');
    assert(threshold >= thresholdMin, 'adeclick.threshold must be >= 1');
    assert(threshold <= thresholdMax, 'adeclick.threshold must be <= 100');
    assert(window >= windowMin, 'adeclick.window must be >= 10');
    assert(window <= windowMax, 'adeclick.window must be <= 100');
    final parts = <String>[];
    if (arorder != 2.0) parts.add('arorder=' + _wireDouble(arorder));
    if (burst != 2.0) parts.add('burst=' + _wireDouble(burst));
    if (method != AdeclickM.add) parts.add('method=' + method.mpvValue);
    if (overlap != 75.0) parts.add('overlap=' + _wireDouble(overlap));
    if (threshold != 2.0) parts.add('threshold=' + _wireDouble(threshold));
    if (window != 55.0) parts.add('window=' + _wireDouble(window));
    return parts.isEmpty
        ? 'lavfi-adeclick'
        : 'lavfi-adeclick=' + parts.join(':');
  }
}
