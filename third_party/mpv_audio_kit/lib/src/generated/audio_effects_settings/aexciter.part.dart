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

/// Configuration for the `aexciter` audio effect.
///
/// An exciter is used to produce high sound that is not present in the
/// original signal. This is done by creating harmonic distortions of the
/// signal which are restricted in range and added to the original signal.
/// An Exciter raises the upper end of an audio signal without simply raising
/// the higher frequencies like an equalizer would do to create a more
/// "crisp" or "brilliant" sound.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [amount]: Set the amount of harmonics added to original signal. Allowed range is from 0 to 64. Default value is 1. (range 0..64, default 1, runtime-tunable)
/// - [blend]: Set the octave of newly created harmonics. Allowed range is from -10 to 10. Default value is 0. (range -10..10, default 0, runtime-tunable)
/// - [ceil]: Set the upper frequency limit of producing harmonics. Allowed range is from 9999 to 20000 Hz. If value is lower than 10000 Hz no limit is applied. (range 9999..20000, default 9999, runtime-tunable)
/// - [drive]: Set the amount of newly created harmonics. Allowed range is from 0.1 to 10. Default value is 8.5. (range 0.1..10, default 8.5, runtime-tunable)
/// - [freq]: Set the lower frequency limit of producing harmonics in Hz. Allowed range is from 2000 to 12000 Hz. Default is 7500 Hz. (range 2000..12000, default 7500, runtime-tunable)
/// - [levelIn]: Set input level prior processing of signal. Allowed range is from 0 to 64. Default value is 1. (range 0..64, default 1, runtime-tunable)
/// - [levelOut]: Set output level after processing of signal. Allowed range is from 0 to 64. Default value is 1. (range 0..64, default 1, runtime-tunable)
/// - [listen]: Mute the original signal and output only added harmonics. By default is disabled. (range 0..1, default 0, runtime-tunable)
final class AexciterEffect extends AudioEffect {
  /// Default value for [amount].
  static const double amountDefault = 1.0;

  /// Minimum value for [amount].
  static const double amountMin = 0.0;

  /// Maximum value for [amount].
  static const double amountMax = 64.0;

  /// Default value for [blend].
  static const double blendDefault = 0.0;

  /// Minimum value for [blend].
  static const double blendMin = -10.0;

  /// Maximum value for [blend].
  static const double blendMax = 10.0;

  /// Default value for [ceil].
  static const double ceilDefault = 9999.0;

  /// Minimum value for [ceil].
  static const double ceilMin = 9999.0;

  /// Maximum value for [ceil].
  static const double ceilMax = 20000.0;

  /// Default value for [drive].
  static const double driveDefault = 8.5;

  /// Minimum value for [drive].
  static const double driveMin = 0.1;

  /// Maximum value for [drive].
  static const double driveMax = 10.0;

  /// Default value for [freq].
  static const double freqDefault = 7500.0;

  /// Minimum value for [freq].
  static const double freqMin = 2000.0;

  /// Maximum value for [freq].
  static const double freqMax = 12000.0;

  /// Default value for [levelIn].
  static const double levelInDefault = 1.0;

  /// Minimum value for [levelIn].
  static const double levelInMin = 0.0;

  /// Maximum value for [levelIn].
  static const double levelInMax = 64.0;

  /// Default value for [levelOut].
  static const double levelOutDefault = 1.0;

  /// Minimum value for [levelOut].
  static const double levelOutMin = 0.0;

  /// Maximum value for [levelOut].
  static const double levelOutMax = 64.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set amount
  final double amount;

  /// set blend harmonics
  final double blend;

  /// set ceiling
  final double ceil;

  /// set harmonics
  final double drive;

  /// set scope
  final double freq;

  /// set level in
  final double levelIn;

  /// set level out
  final double levelOut;

  /// enable listen mode
  final bool listen;

  /// Creates an [AexciterEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AexciterEffect({
    this.enabled = true,
    this.amount = 1.0,
    this.blend = 0.0,
    this.ceil = 9999.0,
    this.drive = 8.5,
    this.freq = 7500.0,
    this.levelIn = 1.0,
    this.levelOut = 1.0,
    this.listen = false,
  });

  @override
  String get filterName => 'aexciter';

  @override
  AudioFilter get filter => AudioFilter.aexciter;

  /// Returns a copy of this [AexciterEffect] with the given fields replaced.
  AexciterEffect copyWith({
    bool? enabled,
    double? amount,
    double? blend,
    double? ceil,
    double? drive,
    double? freq,
    double? levelIn,
    double? levelOut,
    bool? listen,
  }) => AexciterEffect(
    enabled: enabled ?? this.enabled,
    amount: amount ?? this.amount,
    blend: blend ?? this.blend,
    ceil: ceil ?? this.ceil,
    drive: drive ?? this.drive,
    freq: freq ?? this.freq,
    levelIn: levelIn ?? this.levelIn,
    levelOut: levelOut ?? this.levelOut,
    listen: listen ?? this.listen,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AexciterEffect &&
          other.enabled == enabled &&
          other.amount == amount &&
          other.blend == blend &&
          other.ceil == ceil &&
          other.drive == drive &&
          other.freq == freq &&
          other.levelIn == levelIn &&
          other.levelOut == levelOut &&
          other.listen == listen);

  @override
  int get hashCode => Object.hash(
    enabled,
    amount,
    blend,
    ceil,
    drive,
    freq,
    levelIn,
    levelOut,
    listen,
  );

  @override
  String toString() =>
      'AexciterEffect(enabled: $enabled, amount: $amount, blend: $blend, ceil: $ceil, drive: $drive, freq: $freq, levelIn: $levelIn, levelOut: $levelOut, listen: $listen)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(amount >= amountMin, 'aexciter.amount must be >= 0');
    assert(amount <= amountMax, 'aexciter.amount must be <= 64');
    assert(blend >= blendMin, 'aexciter.blend must be >= -10');
    assert(blend <= blendMax, 'aexciter.blend must be <= 10');
    assert(ceil >= ceilMin, 'aexciter.ceil must be >= 9999');
    assert(ceil <= ceilMax, 'aexciter.ceil must be <= 20000');
    assert(drive >= driveMin, 'aexciter.drive must be >= 0.1');
    assert(drive <= driveMax, 'aexciter.drive must be <= 10');
    assert(freq >= freqMin, 'aexciter.freq must be >= 2000');
    assert(freq <= freqMax, 'aexciter.freq must be <= 12000');
    assert(levelIn >= levelInMin, 'aexciter.level_in must be >= 0');
    assert(levelIn <= levelInMax, 'aexciter.level_in must be <= 64');
    assert(levelOut >= levelOutMin, 'aexciter.level_out must be >= 0');
    assert(levelOut <= levelOutMax, 'aexciter.level_out must be <= 64');
    final parts = <String>[];
    if (amount != 1.0) parts.add('amount=' + _wireDouble(amount));
    if (blend != 0.0) parts.add('blend=' + _wireDouble(blend));
    if (ceil != 9999.0) parts.add('ceil=' + _wireDouble(ceil));
    if (drive != 8.5) parts.add('drive=' + _wireDouble(drive));
    if (freq != 7500.0) parts.add('freq=' + _wireDouble(freq));
    if (levelIn != 1.0) parts.add('level_in=' + _wireDouble(levelIn));
    if (levelOut != 1.0) parts.add('level_out=' + _wireDouble(levelOut));
    if (listen != false) parts.add('listen=' + (listen ? '1' : '0'));
    return parts.isEmpty
        ? 'lavfi-aexciter'
        : 'lavfi-aexciter=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AexciterEffect prev) {
    final out = <(String, String)>[];
    if (amount != prev.amount) {
      out.add(('amount', _wireDouble(amount)));
    }
    if (blend != prev.blend) {
      out.add(('blend', _wireDouble(blend)));
    }
    if (ceil != prev.ceil) {
      out.add(('ceil', _wireDouble(ceil)));
    }
    if (drive != prev.drive) {
      out.add(('drive', _wireDouble(drive)));
    }
    if (freq != prev.freq) {
      out.add(('freq', _wireDouble(freq)));
    }
    if (levelIn != prev.levelIn) {
      out.add(('level_in', _wireDouble(levelIn)));
    }
    if (levelOut != prev.levelOut) {
      out.add(('level_out', _wireDouble(levelOut)));
    }
    if (listen != prev.listen) {
      out.add(('listen', (listen ? '1' : '0')));
    }
    return out;
  }
}
