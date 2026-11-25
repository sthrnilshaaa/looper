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

/// Configuration for the `compand` audio effect.
///
/// Compress or expand the audio's dynamic range.
///
/// It accepts the following parameters:
///
/// Parameters:
/// - [attacks]: set time over which increase of volume is determined (range 0..0, default "0")
/// - [decays]: A list of times in seconds for each channel over which the instantaneous level of the input signal is averaged to determine its volume. `attacks` refers to increase of volume and `decays` refers to decrease of volume. For most situations, the attack time (response to the audio getting louder) should be shorter than the decay time, because the human ear is more sensitive to sudden loud audio than sudden soft audio. A typical value for attack is 0.3 seconds and a typical value for decay is 0.8 seconds. If specified number of attacks & decays is lower than number of channels, the last set attack/decay will be used for all remaining channels. (range 0..0, default "0.8")
/// - [delay]: Set a delay, in seconds. The input audio is analyzed immediately, but audio is delayed before being fed to the volume adjuster. Specifying a delay approximately equal to the attack/decay times allows the filter to effectively operate in predictive rather than reactive mode. It defaults to 0. (range 0..20, default 0)
/// - [gain]: Set the additional gain in dB to be applied at all points on the transfer function. This allows for easy adjustment of the overall gain. It defaults to 0. (range -900..900, default 0)
/// - [points]: A list of points for the transfer function, specified in dB relative to the maximum possible signal amplitude. Each key points list must be defined using the following syntax: `x0/y0|x1/y1|x2/y2|....` or `x0/y0 x1/y1 x2/y2 ....`  The input values must be in strictly increasing order but the transfer function does not have to be monotonically rising. The point `0/0` is assumed but may be overridden (by `0/out-dBn`). Typical values for the transfer function are `-70/-70|-60/-20|1/0`. (range 0..0, default "-70/-70|-60/-20|1/0")
/// - [volume]: Set an initial volume, in dB, to be assumed for each channel when filtering starts. This permits the user to supply a nominal level initially, so that, for example, a very large gain is not applied to initial signal levels before the companding has begun to operate. A typical value for audio which is initially quiet is -90 dB. It defaults to 0. (range -900..0, default 0)
///
/// Parameters whose names start with a digit, addressed by
/// their original key in the [params] map:
/// - `soft-knee`: Set the curve radius in dB for all joints. It defaults to 0.01. (range 0.01..900, default 0.01)
final class CompandEffect extends AudioEffect {
  /// Default value for [delay].
  static const double delayDefault = 0.0;

  /// Minimum value for [delay].
  static const double delayMin = 0.0;

  /// Maximum value for [delay].
  static const double delayMax = 20.0;

  /// Default value for [gain].
  static const double gainDefault = 0.0;

  /// Minimum value for [gain].
  static const double gainMin = -900.0;

  /// Maximum value for [gain].
  static const double gainMax = 900.0;

  /// Default value for [volume].
  static const double volumeDefault = 0.0;

  /// Minimum value for [volume].
  static const double volumeMin = -900.0;

  /// Maximum value for [volume].
  static const double volumeMax = 0.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set time over which increase of volume is determined
  final String attacks;

  /// set time over which decrease of volume is determined
  final String decays;

  /// set delay for samples before sending them to volume adjuster
  final double delay;

  /// set output gain
  final double gain;

  /// set points of transfer function
  final String points;

  /// set initial volume
  final double volume;

  /// Raw values for parameters whose names start with a digit,
  /// keyed by their original ffmpeg option name.
  final Map<String, double> params;

  /// Creates an [CompandEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const CompandEffect({
    this.enabled = true,
    this.attacks = '0',
    this.decays = '0.8',
    this.delay = 0.0,
    this.gain = 0.0,
    this.points = '-70/-70|-60/-20|1/0',
    this.volume = 0.0,
    this.params = const <String, double>{},
  });

  @override
  String get filterName => 'compand';

  @override
  AudioFilter get filter => AudioFilter.compand;

  /// Returns a copy of this [CompandEffect] with the given fields replaced.
  CompandEffect copyWith({
    bool? enabled,
    String? attacks,
    String? decays,
    double? delay,
    double? gain,
    String? points,
    double? volume,
    Map<String, double>? params,
  }) => CompandEffect(
    enabled: enabled ?? this.enabled,
    attacks: attacks ?? this.attacks,
    decays: decays ?? this.decays,
    delay: delay ?? this.delay,
    gain: gain ?? this.gain,
    points: points ?? this.points,
    volume: volume ?? this.volume,
    params: params ?? this.params,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompandEffect &&
          other.enabled == enabled &&
          other.attacks == attacks &&
          other.decays == decays &&
          other.delay == delay &&
          other.gain == gain &&
          other.points == points &&
          other.volume == volume &&
          _mapEq(params, other.params));

  @override
  int get hashCode => Object.hash(
    enabled,
    attacks,
    decays,
    delay,
    gain,
    points,
    volume,
    Object.hashAllUnordered(
      params.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  @override
  String toString() =>
      'CompandEffect(enabled: $enabled, attacks: $attacks, decays: $decays, delay: $delay, gain: $gain, points: $points, volume: $volume, params: $params)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(delay >= delayMin, 'compand.delay must be >= 0');
    assert(delay <= delayMax, 'compand.delay must be <= 20');
    assert(gain >= gainMin, 'compand.gain must be >= -900');
    assert(gain <= gainMax, 'compand.gain must be <= 900');
    assert(volume >= volumeMin, 'compand.volume must be >= -900');
    assert(volume <= volumeMax, 'compand.volume must be <= 0');
    final parts = <String>[];
    if (attacks != '0') parts.add('attacks=' + _wireString(attacks));
    if (decays != '0.8') parts.add('decays=' + _wireString(decays));
    if (delay != 0.0) parts.add('delay=' + _wireDouble(delay));
    if (gain != 0.0) parts.add('gain=' + _wireDouble(gain));
    if (points != '-70/-70|-60/-20|1/0')
      parts.add('points=' + _wireString(points));
    if (volume != 0.0) parts.add('volume=' + _wireDouble(volume));
    params.forEach((k, v) => parts.add(_wireKey(k) + '=' + _wireDouble(v)));
    return parts.isEmpty ? 'lavfi-compand' : 'lavfi-compand=' + parts.join(':');
  }
}
