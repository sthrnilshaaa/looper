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

/// Configuration for the `bandpass` audio effect.
///
/// Apply a two-pole Butterworth band-pass filter with central
/// frequency `frequency`, and (3dB-point) band-width width.
/// The `csg` option selects a constant skirt gain (peak gain = Q)
/// instead of the default: constant 0dB peak gain.
/// The filter roll off at 6dB per octave (20dB per decade).
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [blocksize]: set the block size (range 0..32768, default 0)
/// - [channels]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [csg]: Constant skirt gain if set to 1. Defaults to 0. (range 0..1, default 0, runtime-tunable)
/// - [frequency]: Set the filter's central frequency. Default is `3000`. (range 0..999999, default 3000, runtime-tunable)
/// - [mix]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [normalize]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [precision]: Set precision of filtering. (range -1..3, default -1)
/// - [transform]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [width]: Specify the band-width of a filter in width_type units. (range 0..99999, default 0.5, runtime-tunable)
/// - [widthType]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
final class BandpassEffect extends AudioEffect {
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

  /// use constant skirt gain
  final bool csg;

  /// set central frequency
  final double frequency;

  /// set mix
  final double mix;

  /// normalize coefficients
  final bool normalize;

  /// set filtering precision
  final BandpassPrecision precision;

  /// set transform type
  final BandpassTransformType transform;

  /// set width
  final double width;

  /// set filter-width type
  final BandpassWidthType widthType;

  /// Creates an [BandpassEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const BandpassEffect({
    this.enabled = true,
    this.blocksize = 0,
    this.channels = 'all',
    this.csg = false,
    this.frequency = 3000.0,
    this.mix = 1.0,
    this.normalize = false,
    this.precision = BandpassPrecision.auto,
    this.transform = BandpassTransformType.di,
    this.width = 0.5,
    this.widthType = BandpassWidthType.q,
  });

  @override
  String get filterName => 'bandpass';

  @override
  AudioFilter get filter => AudioFilter.bandpass;

  /// Returns a copy of this [BandpassEffect] with the given fields replaced.
  BandpassEffect copyWith({
    bool? enabled,
    int? blocksize,
    String? channels,
    bool? csg,
    double? frequency,
    double? mix,
    bool? normalize,
    BandpassPrecision? precision,
    BandpassTransformType? transform,
    double? width,
    BandpassWidthType? widthType,
  }) => BandpassEffect(
    enabled: enabled ?? this.enabled,
    blocksize: blocksize ?? this.blocksize,
    channels: channels ?? this.channels,
    csg: csg ?? this.csg,
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
      (other is BandpassEffect &&
          other.enabled == enabled &&
          other.blocksize == blocksize &&
          other.channels == channels &&
          other.csg == csg &&
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
    csg,
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
      'BandpassEffect(enabled: $enabled, blocksize: $blocksize, channels: $channels, csg: $csg, frequency: $frequency, mix: $mix, normalize: $normalize, precision: $precision, transform: $transform, width: $width, widthType: $widthType)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(blocksize >= blocksizeMin, 'bandpass.blocksize must be >= 0');
    assert(blocksize <= blocksizeMax, 'bandpass.blocksize must be <= 32768');
    assert(frequency >= frequencyMin, 'bandpass.frequency must be >= 0');
    assert(frequency <= frequencyMax, 'bandpass.frequency must be <= 999999');
    assert(mix >= mixMin, 'bandpass.mix must be >= 0');
    assert(mix <= mixMax, 'bandpass.mix must be <= 1');
    assert(width >= widthMin, 'bandpass.width must be >= 0');
    assert(width <= widthMax, 'bandpass.width must be <= 99999');
    final parts = <String>[];
    if (blocksize != 0) parts.add('blocksize=' + blocksize.toString());
    if (channels != 'all') parts.add('channels=' + _wireString(channels));
    if (csg != false) parts.add('csg=' + (csg ? '1' : '0'));
    if (frequency != 3000.0) parts.add('frequency=' + _wireDouble(frequency));
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (normalize != false) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (precision != BandpassPrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (transform != BandpassTransformType.di)
      parts.add('transform=' + transform.mpvValue);
    if (width != 0.5) parts.add('width=' + _wireDouble(width));
    if (widthType != BandpassWidthType.q)
      parts.add('width_type=' + widthType.mpvValue);
    return parts.isEmpty
        ? 'lavfi-bandpass'
        : 'lavfi-bandpass=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant BandpassEffect prev) {
    final out = <(String, String)>[];
    if (blocksize != prev.blocksize) return null;
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (csg != prev.csg) {
      out.add(('csg', (csg ? '1' : '0')));
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
