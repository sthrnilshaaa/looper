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

/// Configuration for the `adynamicequalizer` audio effect.
///
/// Apply dynamic equalization to input audio stream.
///
/// A description of the accepted options follows.
///
/// Parameters:
/// - [attack]: Set the amount of milliseconds the signal from detection has to rise above the detection threshold before equalization starts. Default is 20. Allowed range is between 1 and 2000. (range 0.01..2000, default 20, runtime-tunable)
/// - [auto]: set auto threshold (range 1..4, default DET_OFF, runtime-tunable)
/// - [dfrequency]: Set the detection frequency in Hz used for detection filter used to trigger equalization. Default value is 1000 Hz. Allowed range is between 2 and 1000000 Hz. (range 2..1000000, default 1000, runtime-tunable)
/// - [dftype]: set detection filter type (range 0..3, default 0, runtime-tunable)
/// - [dqfactor]: Set the detection resonance factor for detection filter used to trigger equalization. Default value is 1. Allowed range is from 0.001 to 1000. (range 0.001..1000, default 1, runtime-tunable)
/// - [makeup]: Set the makeup offset by which the equalization gain is raised. Default is 0. Allowed range is between 0 and 100. (range 0..1000, default 0, runtime-tunable)
/// - [mode]: Set the mode of filter operation, can be one of the following: (range -1..3, default 0, runtime-tunable)
/// - [precision]: set processing precision (range 0..2, default 0)
/// - [range]: Set the max allowed cut/boost amount. Default is 50. Allowed range is from 1 to 200. (range 1..2000, default 50, runtime-tunable)
/// - [ratio]: Set the ratio by which the equalization gain is raised. Default is 1. Allowed range is between 0 and 30. (range 0..30, default 1, runtime-tunable)
/// - [release]: Set the amount of milliseconds the signal from detection has to fall below the detection threshold before equalization ends. Default is 200. Allowed range is between 1 and 2000. (range 0.01..2000, default 200, runtime-tunable)
/// - [tfrequency]: Set the target frequency of equalization filter. Default value is 1000 Hz. Allowed range is between 2 and 1000000 Hz. (range 2..1000000, default 1000, runtime-tunable)
/// - [tftype]: set target filter type (range 0..2, default 0, runtime-tunable)
/// - [threshold]: Set the detection threshold used to trigger equalization. Threshold detection is using detection filter. Default value is 0. Allowed range is from 0 to 100. (range 0..100, default 0, runtime-tunable)
/// - [tqfactor]: Set the target resonance factor for target equalization filter. Default value is 1. Allowed range is from 0.001 to 1000. (range 0.001..1000, default 1, runtime-tunable)
final class AdynamicequalizerEffect extends AudioEffect {
  /// Default value for [attack].
  static const double attackDefault = 20.0;

  /// Minimum value for [attack].
  static const double attackMin = 0.01;

  /// Maximum value for [attack].
  static const double attackMax = 2000.0;

  /// Default value for [dfrequency].
  static const double dfrequencyDefault = 1000.0;

  /// Minimum value for [dfrequency].
  static const double dfrequencyMin = 2.0;

  /// Maximum value for [dfrequency].
  static const double dfrequencyMax = 1000000.0;

  /// Default value for [dqfactor].
  static const double dqfactorDefault = 1.0;

  /// Minimum value for [dqfactor].
  static const double dqfactorMin = 0.001;

  /// Maximum value for [dqfactor].
  static const double dqfactorMax = 1000.0;

  /// Default value for [makeup].
  static const double makeupDefault = 0.0;

  /// Minimum value for [makeup].
  static const double makeupMin = 0.0;

  /// Maximum value for [makeup].
  static const double makeupMax = 1000.0;

  /// Default value for [range].
  static const double rangeDefault = 50.0;

  /// Minimum value for [range].
  static const double rangeMin = 1.0;

  /// Maximum value for [range].
  static const double rangeMax = 2000.0;

  /// Default value for [ratio].
  static const double ratioDefault = 1.0;

  /// Minimum value for [ratio].
  static const double ratioMin = 0.0;

  /// Maximum value for [ratio].
  static const double ratioMax = 30.0;

  /// Default value for [release].
  static const double releaseDefault = 200.0;

  /// Minimum value for [release].
  static const double releaseMin = 0.01;

  /// Maximum value for [release].
  static const double releaseMax = 2000.0;

  /// Default value for [tfrequency].
  static const double tfrequencyDefault = 1000.0;

  /// Minimum value for [tfrequency].
  static const double tfrequencyMin = 2.0;

  /// Maximum value for [tfrequency].
  static const double tfrequencyMax = 1000000.0;

  /// Default value for [threshold].
  static const double thresholdDefault = 0.0;

  /// Minimum value for [threshold].
  static const double thresholdMin = 0.0;

  /// Maximum value for [threshold].
  static const double thresholdMax = 100.0;

  /// Default value for [tqfactor].
  static const double tqfactorDefault = 1.0;

  /// Minimum value for [tqfactor].
  static const double tqfactorMin = 0.001;

  /// Maximum value for [tqfactor].
  static const double tqfactorMax = 1000.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set detection attack duration
  final double attack;

  /// set auto threshold
  final AdynamicequalizerAuto auto;

  /// set detection frequency
  final double dfrequency;

  /// set detection filter type
  final AdynamicequalizerDftype dftype;

  /// set detection Q factor
  final double dqfactor;

  /// set makeup gain
  final double makeup;

  /// set mode
  final AdynamicequalizerMode mode;

  /// set processing precision
  final AdynamicequalizerPrecision precision;

  /// set max gain
  final double range;

  /// set ratio factor
  final double ratio;

  /// set detection release duration
  final double release;

  /// set target frequency
  final double tfrequency;

  /// set target filter type
  final AdynamicequalizerTftype tftype;

  /// set detection threshold
  final double threshold;

  /// set target Q factor
  final double tqfactor;

  /// Creates an [AdynamicequalizerEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AdynamicequalizerEffect({
    this.enabled = true,
    this.attack = 20.0,
    this.auto = AdynamicequalizerAuto.off,
    this.dfrequency = 1000.0,
    this.dftype = AdynamicequalizerDftype.bandpass,
    this.dqfactor = 1.0,
    this.makeup = 0.0,
    this.mode = AdynamicequalizerMode.listen,
    this.precision = AdynamicequalizerPrecision.auto,
    this.range = 50.0,
    this.ratio = 1.0,
    this.release = 200.0,
    this.tfrequency = 1000.0,
    this.tftype = AdynamicequalizerTftype.bell,
    this.threshold = 0.0,
    this.tqfactor = 1.0,
  });

  @override
  String get filterName => 'adynamicequalizer';

  @override
  AudioFilter get filter => AudioFilter.adynamicequalizer;

  /// Returns a copy of this [AdynamicequalizerEffect] with the given fields replaced.
  AdynamicequalizerEffect copyWith({
    bool? enabled,
    double? attack,
    AdynamicequalizerAuto? auto,
    double? dfrequency,
    AdynamicequalizerDftype? dftype,
    double? dqfactor,
    double? makeup,
    AdynamicequalizerMode? mode,
    AdynamicequalizerPrecision? precision,
    double? range,
    double? ratio,
    double? release,
    double? tfrequency,
    AdynamicequalizerTftype? tftype,
    double? threshold,
    double? tqfactor,
  }) => AdynamicequalizerEffect(
    enabled: enabled ?? this.enabled,
    attack: attack ?? this.attack,
    auto: auto ?? this.auto,
    dfrequency: dfrequency ?? this.dfrequency,
    dftype: dftype ?? this.dftype,
    dqfactor: dqfactor ?? this.dqfactor,
    makeup: makeup ?? this.makeup,
    mode: mode ?? this.mode,
    precision: precision ?? this.precision,
    range: range ?? this.range,
    ratio: ratio ?? this.ratio,
    release: release ?? this.release,
    tfrequency: tfrequency ?? this.tfrequency,
    tftype: tftype ?? this.tftype,
    threshold: threshold ?? this.threshold,
    tqfactor: tqfactor ?? this.tqfactor,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdynamicequalizerEffect &&
          other.enabled == enabled &&
          other.attack == attack &&
          other.auto == auto &&
          other.dfrequency == dfrequency &&
          other.dftype == dftype &&
          other.dqfactor == dqfactor &&
          other.makeup == makeup &&
          other.mode == mode &&
          other.precision == precision &&
          other.range == range &&
          other.ratio == ratio &&
          other.release == release &&
          other.tfrequency == tfrequency &&
          other.tftype == tftype &&
          other.threshold == threshold &&
          other.tqfactor == tqfactor);

  @override
  int get hashCode => Object.hash(
    enabled,
    attack,
    auto,
    dfrequency,
    dftype,
    dqfactor,
    makeup,
    mode,
    precision,
    range,
    ratio,
    release,
    tfrequency,
    tftype,
    threshold,
    tqfactor,
  );

  @override
  String toString() =>
      'AdynamicequalizerEffect(enabled: $enabled, attack: $attack, auto: $auto, dfrequency: $dfrequency, dftype: $dftype, dqfactor: $dqfactor, makeup: $makeup, mode: $mode, precision: $precision, range: $range, ratio: $ratio, release: $release, tfrequency: $tfrequency, tftype: $tftype, threshold: $threshold, tqfactor: $tqfactor)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(attack >= attackMin, 'adynamicequalizer.attack must be >= 0.01');
    assert(attack <= attackMax, 'adynamicequalizer.attack must be <= 2000');
    assert(
      dfrequency >= dfrequencyMin,
      'adynamicequalizer.dfrequency must be >= 2',
    );
    assert(
      dfrequency <= dfrequencyMax,
      'adynamicequalizer.dfrequency must be <= 1000000',
    );
    assert(
      dqfactor >= dqfactorMin,
      'adynamicequalizer.dqfactor must be >= 0.001',
    );
    assert(
      dqfactor <= dqfactorMax,
      'adynamicequalizer.dqfactor must be <= 1000',
    );
    assert(makeup >= makeupMin, 'adynamicequalizer.makeup must be >= 0');
    assert(makeup <= makeupMax, 'adynamicequalizer.makeup must be <= 1000');
    assert(range >= rangeMin, 'adynamicequalizer.range must be >= 1');
    assert(range <= rangeMax, 'adynamicequalizer.range must be <= 2000');
    assert(ratio >= ratioMin, 'adynamicequalizer.ratio must be >= 0');
    assert(ratio <= ratioMax, 'adynamicequalizer.ratio must be <= 30');
    assert(release >= releaseMin, 'adynamicequalizer.release must be >= 0.01');
    assert(release <= releaseMax, 'adynamicequalizer.release must be <= 2000');
    assert(
      tfrequency >= tfrequencyMin,
      'adynamicequalizer.tfrequency must be >= 2',
    );
    assert(
      tfrequency <= tfrequencyMax,
      'adynamicequalizer.tfrequency must be <= 1000000',
    );
    assert(
      threshold >= thresholdMin,
      'adynamicequalizer.threshold must be >= 0',
    );
    assert(
      threshold <= thresholdMax,
      'adynamicequalizer.threshold must be <= 100',
    );
    assert(
      tqfactor >= tqfactorMin,
      'adynamicequalizer.tqfactor must be >= 0.001',
    );
    assert(
      tqfactor <= tqfactorMax,
      'adynamicequalizer.tqfactor must be <= 1000',
    );
    final parts = <String>[];
    if (attack != 20.0) parts.add('attack=' + _wireDouble(attack));
    if (auto != AdynamicequalizerAuto.off) parts.add('auto=' + auto.mpvValue);
    if (dfrequency != 1000.0)
      parts.add('dfrequency=' + _wireDouble(dfrequency));
    if (dftype != AdynamicequalizerDftype.bandpass)
      parts.add('dftype=' + dftype.mpvValue);
    if (dqfactor != 1.0) parts.add('dqfactor=' + _wireDouble(dqfactor));
    if (makeup != 0.0) parts.add('makeup=' + _wireDouble(makeup));
    if (mode != AdynamicequalizerMode.listen)
      parts.add('mode=' + mode.mpvValue);
    if (precision != AdynamicequalizerPrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (range != 50.0) parts.add('range=' + _wireDouble(range));
    if (ratio != 1.0) parts.add('ratio=' + _wireDouble(ratio));
    if (release != 200.0) parts.add('release=' + _wireDouble(release));
    if (tfrequency != 1000.0)
      parts.add('tfrequency=' + _wireDouble(tfrequency));
    if (tftype != AdynamicequalizerTftype.bell)
      parts.add('tftype=' + tftype.mpvValue);
    if (threshold != 0.0) parts.add('threshold=' + _wireDouble(threshold));
    if (tqfactor != 1.0) parts.add('tqfactor=' + _wireDouble(tqfactor));
    return parts.isEmpty
        ? 'lavfi-adynamicequalizer'
        : 'lavfi-adynamicequalizer=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AdynamicequalizerEffect prev) {
    final out = <(String, String)>[];
    if (attack != prev.attack) {
      out.add(('attack', _wireDouble(attack)));
    }
    if (auto != prev.auto) {
      out.add(('auto', auto.mpvValue));
    }
    if (dfrequency != prev.dfrequency) {
      out.add(('dfrequency', _wireDouble(dfrequency)));
    }
    if (dftype != prev.dftype) {
      out.add(('dftype', dftype.mpvValue));
    }
    if (dqfactor != prev.dqfactor) {
      out.add(('dqfactor', _wireDouble(dqfactor)));
    }
    if (makeup != prev.makeup) {
      out.add(('makeup', _wireDouble(makeup)));
    }
    if (mode != prev.mode) {
      out.add(('mode', mode.mpvValue));
    }
    if (precision != prev.precision) return null;
    if (range != prev.range) {
      out.add(('range', _wireDouble(range)));
    }
    if (ratio != prev.ratio) {
      out.add(('ratio', _wireDouble(ratio)));
    }
    if (release != prev.release) {
      out.add(('release', _wireDouble(release)));
    }
    if (tfrequency != prev.tfrequency) {
      out.add(('tfrequency', _wireDouble(tfrequency)));
    }
    if (tftype != prev.tftype) {
      out.add(('tftype', tftype.mpvValue));
    }
    if (threshold != prev.threshold) {
      out.add(('threshold', _wireDouble(threshold)));
    }
    if (tqfactor != prev.tqfactor) {
      out.add(('tqfactor', _wireDouble(tqfactor)));
    }
    return out;
  }
}
