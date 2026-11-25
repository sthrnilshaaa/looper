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

/// Configuration for the `aiir` audio effect.
///
/// Apply an arbitrary Infinite Impulse Response filter.
///
/// It accepts the following parameters:
///
/// Parameters:
/// - [channel]: set IR channel to display frequency response (range 0..1024, default 0)
/// - [dry]: set dry gain (range 0..1, default 1)
/// - [format]: Set coefficients format. (range -2..4, default 1)
/// - [gains]: Set channels gains. (range 0..0, default "1|1")
/// - [mix]: set mix (range 0..1, default 1)
/// - [normalize]: normalize coefficients (range 0..1, default 1)
/// - [poles]: Set A/denominator/poles/ladder coefficients. (range 0..0, default "1+0i 1-0i")
/// - [precision]: set filtering precision (range 0..3, default 0)
/// - [process]: set kind of processing (range 0..2, default 1)
/// - [rate]: set video rate (range 0..2147483647, default "25")
/// - [response]: show IR frequency response (range 0..1, default 0)
/// - [size]: set video size (range 0..0, default "hd720")
/// - [wet]: set wet gain (range 0..1, default 1)
/// - [zeros]: Set B/numerator/zeros/reflection coefficients. (range 0..0, default "1+0i 1-0i")
final class AiirEffect extends AudioEffect {
  /// Default value for [channel].
  static const int channelDefault = 0;

  /// Minimum value for [channel].
  static const int channelMin = 0;

  /// Maximum value for [channel].
  static const int channelMax = 1024;

  /// Default value for [dry].
  static const double dryDefault = 1.0;

  /// Minimum value for [dry].
  static const double dryMin = 0.0;

  /// Maximum value for [dry].
  static const double dryMax = 1.0;

  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Default value for [wet].
  static const double wetDefault = 1.0;

  /// Minimum value for [wet].
  static const double wetMin = 0.0;

  /// Maximum value for [wet].
  static const double wetMax = 1.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set IR channel to display frequency response
  final int channel;

  /// set dry gain
  final double dry;

  /// set coefficients format
  final AiirFormat format;

  /// set channels gains
  final String gains;

  /// set mix
  final double mix;

  /// normalize coefficients
  final bool normalize;

  /// set A/denominator/poles/ladder coefficients
  final String poles;

  /// set filtering precision
  final AiirPrecision precision;

  /// set kind of processing
  final AiirProcess process;

  /// set video rate
  final String rate;

  /// show IR frequency response
  final bool response;

  /// set video size
  final String size;

  /// set wet gain
  final double wet;

  /// set B/numerator/zeros/reflection coefficients
  final String zeros;

  /// Creates an [AiirEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AiirEffect({
    this.enabled = true,
    this.channel = 0,
    this.dry = 1.0,
    this.format = AiirFormat.zp,
    this.gains = '1|1',
    this.mix = 1.0,
    this.normalize = true,
    this.poles = '1+0i 1-0i',
    this.precision = AiirPrecision.dbl,
    this.process = AiirProcess.s,
    this.rate = '25',
    this.response = false,
    this.size = 'hd720',
    this.wet = 1.0,
    this.zeros = '1+0i 1-0i',
  });

  @override
  String get filterName => 'aiir';

  @override
  AudioFilter get filter => AudioFilter.aiir;

  /// Returns a copy of this [AiirEffect] with the given fields replaced.
  AiirEffect copyWith({
    bool? enabled,
    int? channel,
    double? dry,
    AiirFormat? format,
    String? gains,
    double? mix,
    bool? normalize,
    String? poles,
    AiirPrecision? precision,
    AiirProcess? process,
    String? rate,
    bool? response,
    String? size,
    double? wet,
    String? zeros,
  }) => AiirEffect(
    enabled: enabled ?? this.enabled,
    channel: channel ?? this.channel,
    dry: dry ?? this.dry,
    format: format ?? this.format,
    gains: gains ?? this.gains,
    mix: mix ?? this.mix,
    normalize: normalize ?? this.normalize,
    poles: poles ?? this.poles,
    precision: precision ?? this.precision,
    process: process ?? this.process,
    rate: rate ?? this.rate,
    response: response ?? this.response,
    size: size ?? this.size,
    wet: wet ?? this.wet,
    zeros: zeros ?? this.zeros,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiirEffect &&
          other.enabled == enabled &&
          other.channel == channel &&
          other.dry == dry &&
          other.format == format &&
          other.gains == gains &&
          other.mix == mix &&
          other.normalize == normalize &&
          other.poles == poles &&
          other.precision == precision &&
          other.process == process &&
          other.rate == rate &&
          other.response == response &&
          other.size == size &&
          other.wet == wet &&
          other.zeros == zeros);

  @override
  int get hashCode => Object.hash(
    enabled,
    channel,
    dry,
    format,
    gains,
    mix,
    normalize,
    poles,
    precision,
    process,
    rate,
    response,
    size,
    wet,
    zeros,
  );

  @override
  String toString() =>
      'AiirEffect(enabled: $enabled, channel: $channel, dry: $dry, format: $format, gains: $gains, mix: $mix, normalize: $normalize, poles: $poles, precision: $precision, process: $process, rate: $rate, response: $response, size: $size, wet: $wet, zeros: $zeros)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(channel >= channelMin, 'aiir.channel must be >= 0');
    assert(channel <= channelMax, 'aiir.channel must be <= 1024');
    assert(dry >= dryMin, 'aiir.dry must be >= 0');
    assert(dry <= dryMax, 'aiir.dry must be <= 1');
    assert(mix >= mixMin, 'aiir.mix must be >= 0');
    assert(mix <= mixMax, 'aiir.mix must be <= 1');
    assert(wet >= wetMin, 'aiir.wet must be >= 0');
    assert(wet <= wetMax, 'aiir.wet must be <= 1');
    final parts = <String>[];
    if (channel != 0) parts.add('channel=' + channel.toString());
    if (dry != 1.0) parts.add('dry=' + _wireDouble(dry));
    if (format != AiirFormat.zp) parts.add('format=' + format.mpvValue);
    if (gains != '1|1') parts.add('gains=' + _wireString(gains));
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (normalize != true) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (poles != '1+0i 1-0i') parts.add('poles=' + _wireString(poles));
    if (precision != AiirPrecision.dbl)
      parts.add('precision=' + precision.mpvValue);
    if (process != AiirProcess.s) parts.add('process=' + process.mpvValue);
    if (rate != '25') parts.add('rate=' + _wireString(rate));
    if (response != false) parts.add('response=' + (response ? '1' : '0'));
    if (size != 'hd720') parts.add('size=' + _wireString(size));
    if (wet != 1.0) parts.add('wet=' + _wireDouble(wet));
    if (zeros != '1+0i 1-0i') parts.add('zeros=' + _wireString(zeros));
    return parts.isEmpty ? 'lavfi-aiir' : 'lavfi-aiir=' + parts.join(':');
  }
}
