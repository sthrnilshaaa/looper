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

/// Configuration for the `highpass` audio effect.
///
/// Apply a high-pass filter with 3dB point frequency.
/// The filter can be either single-pole, or double-pole (the default).
/// The filter roll off at 6dB per pole per octave (20dB per pole per decade).
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [blocksize]: set the block size (range 0..32768, default 0)
/// - [channels]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [frequency]: Set frequency in Hz. Default is 3000. (range 0..999999, default 3000, runtime-tunable)
/// - [mix]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [normalize]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [poles]: Set number of poles. Default is 2. (range 1..2, default 2)
/// - [precision]: Set precision of filtering. (range -1..3, default -1)
/// - [transform]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [width]: Specify the band-width of a filter in width_type units. Applies only to double-pole filter. The default is 0.707q and gives a Butterworth response. (range 0..99999, default 0.707, runtime-tunable)
/// - [widthType]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
final class HighpassEffect extends AudioEffect {
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

  /// Default value for [poles].
  static const int polesDefault = 2;

  /// Minimum value for [poles].
  static const int polesMin = 1;

  /// Maximum value for [poles].
  static const int polesMax = 2;

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

  /// set the block size
  final int blocksize;

  /// set channels to filter
  final String channels;

  /// set frequency
  final double frequency;

  /// set mix
  final double mix;

  /// normalize coefficients
  final bool normalize;

  /// set number of poles
  final int poles;

  /// set filtering precision
  final HighpassPrecision precision;

  /// set transform type
  final HighpassTransformType transform;

  /// set width
  final double width;

  /// set filter-width type
  final HighpassWidthType widthType;

  /// Creates an [HighpassEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const HighpassEffect({
    this.enabled = true,
    this.blocksize = 0,
    this.channels = 'all',
    this.frequency = 3000.0,
    this.mix = 1.0,
    this.normalize = false,
    this.poles = 2,
    this.precision = HighpassPrecision.auto,
    this.transform = HighpassTransformType.di,
    this.width = 0.707,
    this.widthType = HighpassWidthType.q,
  });

  @override
  String get filterName => 'highpass';

  @override
  AudioFilter get filter => AudioFilter.highpass;

  /// Returns a copy of this [HighpassEffect] with the given fields replaced.
  HighpassEffect copyWith({
    bool? enabled,
    int? blocksize,
    String? channels,
    double? frequency,
    double? mix,
    bool? normalize,
    int? poles,
    HighpassPrecision? precision,
    HighpassTransformType? transform,
    double? width,
    HighpassWidthType? widthType,
  }) => HighpassEffect(
    enabled: enabled ?? this.enabled,
    blocksize: blocksize ?? this.blocksize,
    channels: channels ?? this.channels,
    frequency: frequency ?? this.frequency,
    mix: mix ?? this.mix,
    normalize: normalize ?? this.normalize,
    poles: poles ?? this.poles,
    precision: precision ?? this.precision,
    transform: transform ?? this.transform,
    width: width ?? this.width,
    widthType: widthType ?? this.widthType,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HighpassEffect &&
          other.enabled == enabled &&
          other.blocksize == blocksize &&
          other.channels == channels &&
          other.frequency == frequency &&
          other.mix == mix &&
          other.normalize == normalize &&
          other.poles == poles &&
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
    poles,
    precision,
    transform,
    width,
    widthType,
  );

  @override
  String toString() =>
      'HighpassEffect(enabled: $enabled, blocksize: $blocksize, channels: $channels, frequency: $frequency, mix: $mix, normalize: $normalize, poles: $poles, precision: $precision, transform: $transform, width: $width, widthType: $widthType)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(blocksize >= blocksizeMin, 'highpass.blocksize must be >= 0');
    assert(blocksize <= blocksizeMax, 'highpass.blocksize must be <= 32768');
    assert(frequency >= frequencyMin, 'highpass.frequency must be >= 0');
    assert(frequency <= frequencyMax, 'highpass.frequency must be <= 999999');
    assert(mix >= mixMin, 'highpass.mix must be >= 0');
    assert(mix <= mixMax, 'highpass.mix must be <= 1');
    assert(poles >= polesMin, 'highpass.poles must be >= 1');
    assert(poles <= polesMax, 'highpass.poles must be <= 2');
    assert(width >= widthMin, 'highpass.width must be >= 0');
    assert(width <= widthMax, 'highpass.width must be <= 99999');
    final parts = <String>[];
    if (blocksize != 0) parts.add('blocksize=' + blocksize.toString());
    if (channels != 'all') parts.add('channels=' + _wireString(channels));
    if (frequency != 3000.0) parts.add('frequency=' + _wireDouble(frequency));
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (normalize != false) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (poles != 2) parts.add('poles=' + poles.toString());
    if (precision != HighpassPrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (transform != HighpassTransformType.di)
      parts.add('transform=' + transform.mpvValue);
    if (width != 0.707) parts.add('width=' + _wireDouble(width));
    if (widthType != HighpassWidthType.q)
      parts.add('width_type=' + widthType.mpvValue);
    return parts.isEmpty
        ? 'lavfi-highpass'
        : 'lavfi-highpass=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant HighpassEffect prev) {
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
    if (poles != prev.poles) return null;
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
