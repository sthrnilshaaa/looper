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

/// Configuration for the `biquad` audio effect.
///
/// Apply a biquad IIR filter with the given coefficients.
/// Where `b0`, `b1`, `b2` and `a0`, `a1`, `a2`
/// are the numerator and denominator coefficients respectively.
/// and `channels`, `c` specify which channels to filter, by default all
/// available are filtered.
///
/// This filter supports the following commands:
///
/// Parameters:
/// - [a0]:  (range -2147483648..2147483647, default 1, runtime-tunable)
/// - [a1]:  (range -2147483648..2147483647, default 0, runtime-tunable)
/// - [a2]:  (range -2147483648..2147483647, default 0, runtime-tunable)
/// - [b0]:  (range -2147483648..2147483647, default 0, runtime-tunable)
/// - [b1]:  (range -2147483648..2147483647, default 0, runtime-tunable)
/// - [b2]: Change biquad parameter. Syntax for the command is : "`value`" (range -2147483648..2147483647, default 0, runtime-tunable)
/// - [blocksize]: set the block size (range 0..32768, default 0)
/// - [channels]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [mix]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [normalize]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [precision]: Set precision of filtering. (range -1..3, default -1)
/// - [transform]: Set transform type of IIR filter. (range 0..6, default DI)
final class BiquadEffect extends AudioEffect {
  /// Default value for [a0].
  static const double a0Default = 1.0;

  /// Minimum value for [a0].
  static const double a0Min = -2147483648.0;

  /// Maximum value for [a0].
  static const double a0Max = 2147483647.0;

  /// Default value for [a1].
  static const double a1Default = 0.0;

  /// Minimum value for [a1].
  static const double a1Min = -2147483648.0;

  /// Maximum value for [a1].
  static const double a1Max = 2147483647.0;

  /// Default value for [a2].
  static const double a2Default = 0.0;

  /// Minimum value for [a2].
  static const double a2Min = -2147483648.0;

  /// Maximum value for [a2].
  static const double a2Max = 2147483647.0;

  /// Default value for [b0].
  static const double b0Default = 0.0;

  /// Minimum value for [b0].
  static const double b0Min = -2147483648.0;

  /// Maximum value for [b0].
  static const double b0Max = 2147483647.0;

  /// Default value for [b1].
  static const double b1Default = 0.0;

  /// Minimum value for [b1].
  static const double b1Min = -2147483648.0;

  /// Maximum value for [b1].
  static const double b1Max = 2147483647.0;

  /// Default value for [b2].
  static const double b2Default = 0.0;

  /// Minimum value for [b2].
  static const double b2Min = -2147483648.0;

  /// Maximum value for [b2].
  static const double b2Max = 2147483647.0;

  /// Default value for [blocksize].
  static const int blocksizeDefault = 0;

  /// Minimum value for [blocksize].
  static const int blocksizeMin = 0;

  /// Maximum value for [blocksize].
  static const int blocksizeMax = 32768;

  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// The `a0` parameter.
  final double a0;

  /// The `a1` parameter.
  final double a1;

  /// The `a2` parameter.
  final double a2;

  /// The `b0` parameter.
  final double b0;

  /// The `b1` parameter.
  final double b1;

  /// The `b2` parameter.
  final double b2;

  /// set the block size
  final int blocksize;

  /// set channels to filter
  final String channels;

  /// set mix
  final double mix;

  /// normalize coefficients
  final bool normalize;

  /// set filtering precision
  final BiquadPrecision precision;

  /// set transform type
  final BiquadTransformType transform;

  /// Creates an [BiquadEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const BiquadEffect({
    this.enabled = true,
    this.a0 = 1.0,
    this.a1 = 0.0,
    this.a2 = 0.0,
    this.b0 = 0.0,
    this.b1 = 0.0,
    this.b2 = 0.0,
    this.blocksize = 0,
    this.channels = 'all',
    this.mix = 1.0,
    this.normalize = false,
    this.precision = BiquadPrecision.auto,
    this.transform = BiquadTransformType.di,
  });

  @override
  String get filterName => 'biquad';

  @override
  AudioFilter get filter => AudioFilter.biquad;

  /// Returns a copy of this [BiquadEffect] with the given fields replaced.
  BiquadEffect copyWith({
    bool? enabled,
    double? a0,
    double? a1,
    double? a2,
    double? b0,
    double? b1,
    double? b2,
    int? blocksize,
    String? channels,
    double? mix,
    bool? normalize,
    BiquadPrecision? precision,
    BiquadTransformType? transform,
  }) => BiquadEffect(
    enabled: enabled ?? this.enabled,
    a0: a0 ?? this.a0,
    a1: a1 ?? this.a1,
    a2: a2 ?? this.a2,
    b0: b0 ?? this.b0,
    b1: b1 ?? this.b1,
    b2: b2 ?? this.b2,
    blocksize: blocksize ?? this.blocksize,
    channels: channels ?? this.channels,
    mix: mix ?? this.mix,
    normalize: normalize ?? this.normalize,
    precision: precision ?? this.precision,
    transform: transform ?? this.transform,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BiquadEffect &&
          other.enabled == enabled &&
          other.a0 == a0 &&
          other.a1 == a1 &&
          other.a2 == a2 &&
          other.b0 == b0 &&
          other.b1 == b1 &&
          other.b2 == b2 &&
          other.blocksize == blocksize &&
          other.channels == channels &&
          other.mix == mix &&
          other.normalize == normalize &&
          other.precision == precision &&
          other.transform == transform);

  @override
  int get hashCode => Object.hash(
    enabled,
    a0,
    a1,
    a2,
    b0,
    b1,
    b2,
    blocksize,
    channels,
    mix,
    normalize,
    precision,
    transform,
  );

  @override
  String toString() =>
      'BiquadEffect(enabled: $enabled, a0: $a0, a1: $a1, a2: $a2, b0: $b0, b1: $b1, b2: $b2, blocksize: $blocksize, channels: $channels, mix: $mix, normalize: $normalize, precision: $precision, transform: $transform)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(a0 >= a0Min, 'biquad.a0 must be >= -2147483648');
    assert(a0 <= a0Max, 'biquad.a0 must be <= 2147483647');
    assert(a1 >= a1Min, 'biquad.a1 must be >= -2147483648');
    assert(a1 <= a1Max, 'biquad.a1 must be <= 2147483647');
    assert(a2 >= a2Min, 'biquad.a2 must be >= -2147483648');
    assert(a2 <= a2Max, 'biquad.a2 must be <= 2147483647');
    assert(b0 >= b0Min, 'biquad.b0 must be >= -2147483648');
    assert(b0 <= b0Max, 'biquad.b0 must be <= 2147483647');
    assert(b1 >= b1Min, 'biquad.b1 must be >= -2147483648');
    assert(b1 <= b1Max, 'biquad.b1 must be <= 2147483647');
    assert(b2 >= b2Min, 'biquad.b2 must be >= -2147483648');
    assert(b2 <= b2Max, 'biquad.b2 must be <= 2147483647');
    assert(blocksize >= blocksizeMin, 'biquad.blocksize must be >= 0');
    assert(blocksize <= blocksizeMax, 'biquad.blocksize must be <= 32768');
    assert(mix >= mixMin, 'biquad.mix must be >= 0');
    assert(mix <= mixMax, 'biquad.mix must be <= 1');
    final parts = <String>[];
    if (a0 != 1.0) parts.add('a0=' + _wireDouble(a0));
    if (a1 != 0.0) parts.add('a1=' + _wireDouble(a1));
    if (a2 != 0.0) parts.add('a2=' + _wireDouble(a2));
    if (b0 != 0.0) parts.add('b0=' + _wireDouble(b0));
    if (b1 != 0.0) parts.add('b1=' + _wireDouble(b1));
    if (b2 != 0.0) parts.add('b2=' + _wireDouble(b2));
    if (blocksize != 0) parts.add('blocksize=' + blocksize.toString());
    if (channels != 'all') parts.add('channels=' + _wireString(channels));
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (normalize != false) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (precision != BiquadPrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (transform != BiquadTransformType.di)
      parts.add('transform=' + transform.mpvValue);
    return parts.isEmpty ? 'lavfi-biquad' : 'lavfi-biquad=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant BiquadEffect prev) {
    final out = <(String, String)>[];
    if (a0 != prev.a0) {
      out.add(('a0', _wireDouble(a0)));
    }
    if (a1 != prev.a1) {
      out.add(('a1', _wireDouble(a1)));
    }
    if (a2 != prev.a2) {
      out.add(('a2', _wireDouble(a2)));
    }
    if (b0 != prev.b0) {
      out.add(('b0', _wireDouble(b0)));
    }
    if (b1 != prev.b1) {
      out.add(('b1', _wireDouble(b1)));
    }
    if (b2 != prev.b2) {
      out.add(('b2', _wireDouble(b2)));
    }
    if (blocksize != prev.blocksize) return null;
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (normalize != prev.normalize) {
      out.add(('normalize', (normalize ? '1' : '0')));
    }
    if (precision != prev.precision) return null;
    if (transform != prev.transform) return null;
    return out;
  }
}
