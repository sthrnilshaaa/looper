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

/// Configuration for the `compensationdelay` audio effect.
///
/// Compensation Delay Line is a metric based delay to compensate differing
/// positions of microphones or speakers.
///
/// For example, you have recorded guitar with two microphones placed in
/// different locations. Because the front of sound wave has fixed speed in
/// normal conditions, the phasing of microphones can vary and depends on
/// their location and interposition. The best sound mix can be achieved when
/// these microphones are in phase (synchronized). Note that a distance of
/// ~30 cm between microphones makes one microphone capture the signal in
/// antiphase to the other microphone. That makes the final mix sound moody.
/// This filter helps to solve phasing problems by adding different delays
/// to each microphone track and make them synchronized.
///
/// The best result can be reached when you take one track as base and
/// synchronize other tracks one by one with it.
/// Remember that synchronization/delay tolerance depends on sample rate, too.
/// Higher sample rates will give more tolerance.
///
/// The filter accepts the following parameters:
///
/// Parameters:
/// - [cm]: Set cm distance. This is compensation distance for tightening distance setup. Default is 0. (range 0..100, default 0, runtime-tunable)
/// - [dry]: Set dry amount. Amount of unprocessed (dry) signal. Default is 0. (range 0..1, default 0, runtime-tunable)
/// - [m]: Set meters distance. This is compensation distance for hard distance setup. Default is 0. (range 0..100, default 0, runtime-tunable)
/// - [mm]: Set millimeters distance. This is compensation distance for fine tuning. Default is 0. (range 0..10, default 0, runtime-tunable)
/// - [temp]: Set temperature in degrees Celsius. This is the temperature of the environment. Default is 20. (range -50..50, default 20, runtime-tunable)
/// - [wet]: Set wet amount. Amount of processed (wet) signal. Default is 1. (range 0..1, default 1, runtime-tunable)
final class CompensationdelayEffect extends AudioEffect {
  /// Default value for [cm].
  static const int cmDefault = 0;

  /// Minimum value for [cm].
  static const int cmMin = 0;

  /// Maximum value for [cm].
  static const int cmMax = 100;

  /// Default value for [dry].
  static const double dryDefault = 0.0;

  /// Minimum value for [dry].
  static const double dryMin = 0.0;

  /// Maximum value for [dry].
  static const double dryMax = 1.0;

  /// Default value for [m].
  static const int mDefault = 0;

  /// Minimum value for [m].
  static const int mMin = 0;

  /// Maximum value for [m].
  static const int mMax = 100;

  /// Default value for [mm].
  static const int mmDefault = 0;

  /// Minimum value for [mm].
  static const int mmMin = 0;

  /// Maximum value for [mm].
  static const int mmMax = 10;

  /// Default value for [temp].
  static const int tempDefault = 20;

  /// Minimum value for [temp].
  static const int tempMin = -50;

  /// Maximum value for [temp].
  static const int tempMax = 50;

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

  /// set cm distance
  final int cm;

  /// set dry amount
  final double dry;

  /// set meter distance
  final int m;

  /// set mm distance
  final int mm;

  /// set temperature °C
  final int temp;

  /// set wet amount
  final double wet;

  /// Creates an [CompensationdelayEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const CompensationdelayEffect({
    this.enabled = true,
    this.cm = 0,
    this.dry = 0.0,
    this.m = 0,
    this.mm = 0,
    this.temp = 20,
    this.wet = 1.0,
  });

  @override
  String get filterName => 'compensationdelay';

  @override
  AudioFilter get filter => AudioFilter.compensationdelay;

  /// Returns a copy of this [CompensationdelayEffect] with the given fields replaced.
  CompensationdelayEffect copyWith({
    bool? enabled,
    int? cm,
    double? dry,
    int? m,
    int? mm,
    int? temp,
    double? wet,
  }) => CompensationdelayEffect(
    enabled: enabled ?? this.enabled,
    cm: cm ?? this.cm,
    dry: dry ?? this.dry,
    m: m ?? this.m,
    mm: mm ?? this.mm,
    temp: temp ?? this.temp,
    wet: wet ?? this.wet,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompensationdelayEffect &&
          other.enabled == enabled &&
          other.cm == cm &&
          other.dry == dry &&
          other.m == m &&
          other.mm == mm &&
          other.temp == temp &&
          other.wet == wet);

  @override
  int get hashCode => Object.hash(enabled, cm, dry, m, mm, temp, wet);

  @override
  String toString() =>
      'CompensationdelayEffect(enabled: $enabled, cm: $cm, dry: $dry, m: $m, mm: $mm, temp: $temp, wet: $wet)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(cm >= cmMin, 'compensationdelay.cm must be >= 0');
    assert(cm <= cmMax, 'compensationdelay.cm must be <= 100');
    assert(dry >= dryMin, 'compensationdelay.dry must be >= 0');
    assert(dry <= dryMax, 'compensationdelay.dry must be <= 1');
    assert(m >= mMin, 'compensationdelay.m must be >= 0');
    assert(m <= mMax, 'compensationdelay.m must be <= 100');
    assert(mm >= mmMin, 'compensationdelay.mm must be >= 0');
    assert(mm <= mmMax, 'compensationdelay.mm must be <= 10');
    assert(temp >= tempMin, 'compensationdelay.temp must be >= -50');
    assert(temp <= tempMax, 'compensationdelay.temp must be <= 50');
    assert(wet >= wetMin, 'compensationdelay.wet must be >= 0');
    assert(wet <= wetMax, 'compensationdelay.wet must be <= 1');
    final parts = <String>[];
    if (cm != 0) parts.add('cm=' + cm.toString());
    if (dry != 0.0) parts.add('dry=' + _wireDouble(dry));
    if (m != 0) parts.add('m=' + m.toString());
    if (mm != 0) parts.add('mm=' + mm.toString());
    if (temp != 20) parts.add('temp=' + temp.toString());
    if (wet != 1.0) parts.add('wet=' + _wireDouble(wet));
    return parts.isEmpty
        ? 'lavfi-compensationdelay'
        : 'lavfi-compensationdelay=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant CompensationdelayEffect prev) {
    final out = <(String, String)>[];
    if (cm != prev.cm) {
      out.add(('cm', cm.toString()));
    }
    if (dry != prev.dry) {
      out.add(('dry', _wireDouble(dry)));
    }
    if (m != prev.m) {
      out.add(('m', m.toString()));
    }
    if (mm != prev.mm) {
      out.add(('mm', mm.toString()));
    }
    if (temp != prev.temp) {
      out.add(('temp', temp.toString()));
    }
    if (wet != prev.wet) {
      out.add(('wet', _wireDouble(wet)));
    }
    return out;
  }
}
