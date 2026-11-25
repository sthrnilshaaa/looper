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

/// Configuration for the `adeclip` audio effect.
///
/// Remove clipped samples from input audio.
///
/// Samples detected as clipped are replaced by interpolated samples using
/// autoregressive modelling.
///
/// Parameters:
/// - [arorder]: Set autoregression order, in percentage of window size. Allowed range is from `0` to `25`. Default value is `8` percent. This option also controls quality of interpolated samples using neighbour good samples. (range 0..25, default 8)
/// - [hsize]: Set size of histogram used to detect clips. Allowed range is from `100` to `9999`. Default value is `1000`. Higher values make clip detection less aggressive. (range 100..9999, default 1000)
/// - [method]: Set overlap method.  It accepts the following values: (range 0..1, default 0)
/// - [overlap]: Set window overlap, in percentage of window size. Allowed range is from `50` to `95`. Default value is `75` percent. (range 50..95, default 75)
/// - [threshold]: Set threshold value. Allowed range is from `1` to `100`. Default value is `10`. Higher values make clip detection less aggressive. (range 1..100, default 10)
/// - [window]: Set window size, in milliseconds. Allowed range is from `10` to `100`. Default value is `55` milliseconds. This sets size of window which will be processed at once. (range 10..100, default 55)
final class AdeclipEffect extends AudioEffect {
  /// Default value for [arorder].
  static const double arorderDefault = 8.0;

  /// Minimum value for [arorder].
  static const double arorderMin = 0.0;

  /// Maximum value for [arorder].
  static const double arorderMax = 25.0;

  /// Default value for [hsize].
  static const int hsizeDefault = 1000;

  /// Minimum value for [hsize].
  static const int hsizeMin = 100;

  /// Maximum value for [hsize].
  static const int hsizeMax = 9999;

  /// Default value for [overlap].
  static const double overlapDefault = 75.0;

  /// Minimum value for [overlap].
  static const double overlapMin = 50.0;

  /// Maximum value for [overlap].
  static const double overlapMax = 95.0;

  /// Default value for [threshold].
  static const double thresholdDefault = 10.0;

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

  /// set histogram size
  final int hsize;

  /// set overlap method
  final AdeclipM method;

  /// set window overlap
  final double overlap;

  /// set threshold
  final double threshold;

  /// set window size
  final double window;

  /// Creates an [AdeclipEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AdeclipEffect({
    this.enabled = true,
    this.arorder = 8.0,
    this.hsize = 1000,
    this.method = AdeclipM.add,
    this.overlap = 75.0,
    this.threshold = 10.0,
    this.window = 55.0,
  });

  @override
  String get filterName => 'adeclip';

  @override
  AudioFilter get filter => AudioFilter.adeclip;

  /// Returns a copy of this [AdeclipEffect] with the given fields replaced.
  AdeclipEffect copyWith({
    bool? enabled,
    double? arorder,
    int? hsize,
    AdeclipM? method,
    double? overlap,
    double? threshold,
    double? window,
  }) => AdeclipEffect(
    enabled: enabled ?? this.enabled,
    arorder: arorder ?? this.arorder,
    hsize: hsize ?? this.hsize,
    method: method ?? this.method,
    overlap: overlap ?? this.overlap,
    threshold: threshold ?? this.threshold,
    window: window ?? this.window,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdeclipEffect &&
          other.enabled == enabled &&
          other.arorder == arorder &&
          other.hsize == hsize &&
          other.method == method &&
          other.overlap == overlap &&
          other.threshold == threshold &&
          other.window == window);

  @override
  int get hashCode =>
      Object.hash(enabled, arorder, hsize, method, overlap, threshold, window);

  @override
  String toString() =>
      'AdeclipEffect(enabled: $enabled, arorder: $arorder, hsize: $hsize, method: $method, overlap: $overlap, threshold: $threshold, window: $window)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(arorder >= arorderMin, 'adeclip.arorder must be >= 0');
    assert(arorder <= arorderMax, 'adeclip.arorder must be <= 25');
    assert(hsize >= hsizeMin, 'adeclip.hsize must be >= 100');
    assert(hsize <= hsizeMax, 'adeclip.hsize must be <= 9999');
    assert(overlap >= overlapMin, 'adeclip.overlap must be >= 50');
    assert(overlap <= overlapMax, 'adeclip.overlap must be <= 95');
    assert(threshold >= thresholdMin, 'adeclip.threshold must be >= 1');
    assert(threshold <= thresholdMax, 'adeclip.threshold must be <= 100');
    assert(window >= windowMin, 'adeclip.window must be >= 10');
    assert(window <= windowMax, 'adeclip.window must be <= 100');
    final parts = <String>[];
    if (arorder != 8.0) parts.add('arorder=' + _wireDouble(arorder));
    if (hsize != 1000) parts.add('hsize=' + hsize.toString());
    if (method != AdeclipM.add) parts.add('method=' + method.mpvValue);
    if (overlap != 75.0) parts.add('overlap=' + _wireDouble(overlap));
    if (threshold != 10.0) parts.add('threshold=' + _wireDouble(threshold));
    if (window != 55.0) parts.add('window=' + _wireDouble(window));
    return parts.isEmpty ? 'lavfi-adeclip' : 'lavfi-adeclip=' + parts.join(':');
  }
}
