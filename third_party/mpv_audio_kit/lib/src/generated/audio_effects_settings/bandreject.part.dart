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

/// Configuration for the `bandreject` audio effect.
///
/// Apply a two-pole Butterworth band-reject filter with central
/// frequency `frequency`, and (3dB-point) band-width `width`.
/// The filter roll off at 6dB per octave (20dB per decade).
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [blocksize]: set the block size (range 0..32768, default 0)
/// - [channels]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [frequency]: Set the filter's central frequency. Default is `3000`. (range 0..999999, default 3000, runtime-tunable)
/// - [mix]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [normalize]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [precision]: Set precision of filtering. (range -1..3, default -1)
/// - [transform]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [width]: Specify the band-width of a filter in width_type units. (range 0..99999, default 0.5, runtime-tunable)
/// - [widthType]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
final class BandrejectEffect extends AudioEffect {
  /// Default value for [blocksize].
  static const int blocksizeDefault = 0;

  /// Minimum value for [blocksize].
  static const int blocksizeMin = 0;

  /// Maximum value for [blocksize].
  static const int blocksizeMax = 32768;

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

  /// Default value for [width].
  static const double widthDefault = 0.5;

  /// Minimum value for [width].
  static const double widthMin = 0.0;

  /// Maximum value for [width].
  static const double widthMax = 99999.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set the block size
  final int blocksize;

  /// set channels to filter
  final String channels;

  /// set central frequency
  final double frequency;

  /// set mix
  final double mix;

  /// normalize coefficients
  final bool normalize;

  /// set filtering precision
  final BandrejectPrecision precision;

  /// set transform type
  final BandrejectTransformType transform;

  /// set width
  final double width;

  /// set filter-width type
  final BandrejectWidthType widthType;

  /// Creates an [BandrejectEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const BandrejectEffect({
    this.enabled = true,
    this.blocksize = 0,
    this.channels = 'all',
    this.frequency = 3000.0,
    this.mix = 1.0,
    this.normalize = false,
    this.precision = BandrejectPrecision.auto,
    this.transform = BandrejectTransformType.di,
    this.width = 0.5,
    this.widthType = BandrejectWidthType.q,
  });

  @override
  String get filterName => 'bandreject';

  @override
  AudioFilter get filter => AudioFilter.bandreject;

  /// Returns a copy of this [BandrejectEffect] with the given fields replaced.
  BandrejectEffect copyWith({
    bool? enabled,
    int? blocksize,
    String? channels,
    double? frequency,
    double? mix,
    bool? normalize,
    BandrejectPrecision? precision,
    BandrejectTransformType? transform,
    double? width,
    BandrejectWidthType? widthType,
  }) => BandrejectEffect(
    enabled: enabled ?? this.enabled,
    blocksize: blocksize ?? this.blocksize,
    channels: channels ?? this.channels,
    frequency: frequency ?? this.frequency,
    mix: mix ?? this.mix,
    normalize: normalize ?? this.normalize,
    precision: precision ?? this.precision,
    transform: transform ?? this.transform,
    width: width ?? this.width,
    widthType: widthType ?? this.widthType,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BandrejectEffect &&
          other.enabled == enabled &&
          other.blocksize == blocksize &&
          other.channels == channels &&
          other.frequency == frequency &&
          other.mix == mix &&
          other.normalize == normalize &&
          other.precision == precision &&
          other.transform == transform &&
          other.width == width &&
          other.widthType == widthType);

  @override
  int get hashCode => Object.hash(
    enabled,
    blocksize,
    channels,
    frequency,
    mix,
    normalize,
    precision,
    transform,
    width,
    widthType,
  );

  @override
  String toString() =>
      'BandrejectEffect(enabled: $enabled, blocksize: $blocksize, channels: $channels, frequency: $frequency, mix: $mix, normalize: $normalize, precision: $precision, transform: $transform, width: $width, widthType: $widthType)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(blocksize >= blocksizeMin, 'bandreject.blocksize must be >= 0');
    assert(blocksize <= blocksizeMax, 'bandreject.blocksize must be <= 32768');
    assert(frequency >= frequencyMin, 'bandreject.frequency must be >= 0');
    assert(frequency <= frequencyMax, 'bandreject.frequency must be <= 999999');
    assert(mix >= mixMin, 'bandreject.mix must be >= 0');
    assert(mix <= mixMax, 'bandreject.mix must be <= 1');
    assert(width >= widthMin, 'bandreject.width must be >= 0');
    assert(width <= widthMax, 'bandreject.width must be <= 99999');
    final parts = <String>[];
    if (blocksize != 0) parts.add('blocksize=' + blocksize.toString());
    if (channels != 'all') parts.add('channels=' + _wireString(channels));
    if (frequency != 3000.0) parts.add('frequency=' + _wireDouble(frequency));
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (normalize != false) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (precision != BandrejectPrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (transform != BandrejectTransformType.di)
      parts.add('transform=' + transform.mpvValue);
    if (width != 0.5) parts.add('width=' + _wireDouble(width));
    if (widthType != BandrejectWidthType.q)
      parts.add('width_type=' + widthType.mpvValue);
    return parts.isEmpty
        ? 'lavfi-bandreject'
        : 'lavfi-bandreject=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant BandrejectEffect prev) {
    final out = <(String, String)>[];
    if (blocksize != prev.blocksize) return null;
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
