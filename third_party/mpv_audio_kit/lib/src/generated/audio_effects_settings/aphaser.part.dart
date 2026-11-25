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

/// Configuration for the `aphaser` audio effect.
///
/// Add a phasing effect to the input audio.
///
/// A phaser filter creates series of peaks and troughs in the frequency spectrum.
/// The position of the peaks and troughs are modulated so that they vary over time, creating a sweeping effect.
///
/// A description of the accepted parameters follows.
///
/// Parameters:
/// - [decay]: Set decay. Default is 0.4. (range 0...99, default .4)
/// - [delay]: Set delay in milliseconds. Default is 3.0. (range 0.1..5, default 3.)
/// - [inGain]: Set input gain. Default is 0.4. (range 0..1, default .4)
/// - [outGain]: Set output gain. Default is 0.74 (range 0..1e9, default .74)
/// - [speed]: Set modulation speed in Hz. Default is 0.5. (range .1..2, default .5)
/// - [type]: Set modulation type. Default is triangular.  It accepts the following values: (default WAVE_TRI)
final class AphaserEffect extends AudioEffect {
  /// Default value for [decay].
  static const double decayDefault = .4;

  /// Minimum value for [decay].
  static const double decayMin = 0.0;

  /// Maximum value for [decay].
  static const double decayMax = .99;

  /// Default value for [delay].
  static const double delayDefault = 3.0;

  /// Minimum value for [delay].
  static const double delayMin = 0.1;

  /// Maximum value for [delay].
  static const double delayMax = 5.0;

  /// Default value for [inGain].
  static const double inGainDefault = .4;

  /// Minimum value for [inGain].
  static const double inGainMin = 0.0;

  /// Maximum value for [inGain].
  static const double inGainMax = 1.0;

  /// Default value for [outGain].
  static const double outGainDefault = .74;

  /// Minimum value for [outGain].
  static const double outGainMin = 0.0;

  /// Maximum value for [outGain].
  static const double outGainMax = 1e9;

  /// Default value for [speed].
  static const double speedDefault = .5;

  /// Minimum value for [speed].
  static const double speedMin = .1;

  /// Maximum value for [speed].
  static const double speedMax = 2.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set decay
  final double decay;

  /// set delay in milliseconds
  final double delay;

  /// set input gain
  final double inGain;

  /// set output gain
  final double outGain;

  /// set modulation speed
  final double speed;

  /// set modulation type
  final AphaserType type;

  /// Creates an [AphaserEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AphaserEffect({
    this.enabled = true,
    this.decay = .4,
    this.delay = 3.0,
    this.inGain = .4,
    this.outGain = .74,
    this.speed = .5,
    this.type = AphaserType.triangular,
  });

  @override
  String get filterName => 'aphaser';

  @override
  AudioFilter get filter => AudioFilter.aphaser;

  /// Returns a copy of this [AphaserEffect] with the given fields replaced.
  AphaserEffect copyWith({
    bool? enabled,
    double? decay,
    double? delay,
    double? inGain,
    double? outGain,
    double? speed,
    AphaserType? type,
  }) => AphaserEffect(
    enabled: enabled ?? this.enabled,
    decay: decay ?? this.decay,
    delay: delay ?? this.delay,
    inGain: inGain ?? this.inGain,
    outGain: outGain ?? this.outGain,
    speed: speed ?? this.speed,
    type: type ?? this.type,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AphaserEffect &&
          other.enabled == enabled &&
          other.decay == decay &&
          other.delay == delay &&
          other.inGain == inGain &&
          other.outGain == outGain &&
          other.speed == speed &&
          other.type == type);

  @override
  int get hashCode =>
      Object.hash(enabled, decay, delay, inGain, outGain, speed, type);

  @override
  String toString() =>
      'AphaserEffect(enabled: $enabled, decay: $decay, delay: $delay, inGain: $inGain, outGain: $outGain, speed: $speed, type: $type)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(decay >= decayMin, 'aphaser.decay must be >= 0');
    assert(decay <= decayMax, 'aphaser.decay must be <= .99');
    assert(delay >= delayMin, 'aphaser.delay must be >= 0.1');
    assert(delay <= delayMax, 'aphaser.delay must be <= 5');
    assert(inGain >= inGainMin, 'aphaser.in_gain must be >= 0');
    assert(inGain <= inGainMax, 'aphaser.in_gain must be <= 1');
    assert(outGain >= outGainMin, 'aphaser.out_gain must be >= 0');
    assert(outGain <= outGainMax, 'aphaser.out_gain must be <= 1e9');
    assert(speed >= speedMin, 'aphaser.speed must be >= .1');
    assert(speed <= speedMax, 'aphaser.speed must be <= 2');
    final parts = <String>[];
    if (decay != .4) parts.add('decay=' + _wireDouble(decay));
    if (delay != 3.0) parts.add('delay=' + _wireDouble(delay));
    if (inGain != .4) parts.add('in_gain=' + _wireDouble(inGain));
    if (outGain != .74) parts.add('out_gain=' + _wireDouble(outGain));
    if (speed != .5) parts.add('speed=' + _wireDouble(speed));
    if (type != AphaserType.triangular) parts.add('type=' + type.mpvValue);
    return parts.isEmpty ? 'lavfi-aphaser' : 'lavfi-aphaser=' + parts.join(':');
  }
}
