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

/// Configuration for the `allpass` audio effect.
///
/// Apply a two-pole all-pass filter with central frequency (in Hz)
/// `frequency`, and filter-width `width`.
/// An all-pass filter changes the audio's frequency to phase relationship
/// without changing its frequency to amplitude relationship.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [channels]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [frequency]: Set frequency in Hz. (range 0..999999, default 3000, runtime-tunable)
/// - [mix]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [normalize]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [order]: Set the filter order, can be 1 or 2. Default is 2. (range 1..2, default 2, runtime-tunable)
/// - [precision]: Set precision of filtering. (range -1..3, default -1)
/// - [transform]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [width]: Specify the band-width of a filter in width_type units. (range 0..99999, default 0.707, runtime-tunable)
/// - [widthType]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
final class AllpassEffect extends AudioEffect {
  /// Default value for [frequency].
  static const double frequencyDefault = 3000.0;

  /// Minimum value for [frequency].
  static const double frequencyMin = 0.0;

  /// Maximum value for [frequency].
  static const double frequencyMax = 999999.0;

  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Default value for [order].
  static const int orderDefault = 2;

  /// Minimum value for [order].
  static const int orderMin = 1;

  /// Maximum value for [order].
  static const int orderMax = 2;

  /// Default value for [width].
  static const double widthDefault = 0.707;

  /// Minimum value for [width].
  static const double widthMin = 0.0;

  /// Maximum value for [width].
  static const double widthMax = 99999.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set channels to filter
  final String channels;

  /// set central frequency
  final double frequency;

  /// set mix
  final double mix;

  /// normalize coefficients
  final bool normalize;

  /// set filter order
  final int order;

  /// set filtering precision
  final AllpassPrecision precision;

  /// set transform type
  final AllpassTransformType transform;

  /// set width
  final double width;

  /// set filter-width type
  final AllpassWidthType widthType;

  /// Creates an [AllpassEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AllpassEffect({
    this.enabled = true,
    this.channels = 'all',
    this.frequency = 3000.0,
    this.mix = 1.0,
    this.normalize = false,
    this.order = 2,
    this.precision = AllpassPrecision.auto,
    this.transform = AllpassTransformType.di,
    this.width = 0.707,
    this.widthType = AllpassWidthType.q,
  });

  @override
  String get filterName => 'allpass';

  @override
  AudioFilter get filter => AudioFilter.allpass;

  /// Returns a copy of this [AllpassEffect] with the given fields replaced.
  AllpassEffect copyWith({
    bool? enabled,
    String? channels,
    double? frequency,
    double? mix,
    bool? normalize,
    int? order,
    AllpassPrecision? precision,
    AllpassTransformType? transform,
    double? width,
    AllpassWidthType? widthType,
  }) => AllpassEffect(
    enabled: enabled ?? this.enabled,
    channels: channels ?? this.channels,
    frequency: frequency ?? this.frequency,
    mix: mix ?? this.mix,
    normalize: normalize ?? this.normalize,
    order: order ?? this.order,
    precision: precision ?? this.precision,
    transform: transform ?? this.transform,
    width: width ?? this.width,
    widthType: widthType ?? this.widthType,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AllpassEffect &&
          other.enabled == enabled &&
          other.channels == channels &&
          other.frequency == frequency &&
          other.mix == mix &&
          other.normalize == normalize &&
          other.order == order &&
          other.precision == precision &&
          other.transform == transform &&
          other.width == width &&
          other.widthType == widthType);

  @override
  int get hashCode => Object.hash(
    enabled,
    channels,
    frequency,
    mix,
    normalize,
    order,
    precision,
    transform,
    width,
    widthType,
  );

  @override
  String toString() =>
      'AllpassEffect(enabled: $enabled, channels: $channels, frequency: $frequency, mix: $mix, normalize: $normalize, order: $order, precision: $precision, transform: $transform, width: $width, widthType: $widthType)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(frequency >= frequencyMin, 'allpass.frequency must be >= 0');
    assert(frequency <= frequencyMax, 'allpass.frequency must be <= 999999');
    assert(mix >= mixMin, 'allpass.mix must be >= 0');
    assert(mix <= mixMax, 'allpass.mix must be <= 1');
    assert(order >= orderMin, 'allpass.order must be >= 1');
    assert(order <= orderMax, 'allpass.order must be <= 2');
    assert(width >= widthMin, 'allpass.width must be >= 0');
    assert(width <= widthMax, 'allpass.width must be <= 99999');
    final parts = <String>[];
    if (channels != 'all') parts.add('channels=' + _wireString(channels));
    if (frequency != 3000.0) parts.add('frequency=' + _wireDouble(frequency));
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (normalize != false) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (order != 2) parts.add('order=' + order.toString());
    if (precision != AllpassPrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (transform != AllpassTransformType.di)
      parts.add('transform=' + transform.mpvValue);
    if (width != 0.707) parts.add('width=' + _wireDouble(width));
    if (widthType != AllpassWidthType.q)
      parts.add('width_type=' + widthType.mpvValue);
    return parts.isEmpty ? 'lavfi-allpass' : 'lavfi-allpass=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AllpassEffect prev) {
    final out = <(String, String)>[];
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (frequency != prev.frequency) {
      out.add(('frequency', _wireDouble(frequency)));
    }
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (normalize != prev.normalize) {
      out.add(('normalize', (normalize ? '1' : '0')));
    }
    if (order != prev.order) {
      out.add(('order', order.toString()));
    }
    if (precision != prev.precision) return null;
    if (transform != prev.transform) return null;
    if (width != prev.width) {
      out.add(('width', _wireDouble(width)));
    }
    if (widthType != prev.widthType) {
      out.add(('width_type', widthType.mpvValue));
    }
    return out;
  }
}
