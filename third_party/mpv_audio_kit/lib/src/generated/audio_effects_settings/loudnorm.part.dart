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

/// Configuration for the `loudnorm` audio effect.
///
/// EBU R128 loudness normalization. Includes both dynamic and linear normalization modes.
/// Support for both single pass (livestreams, files) and double pass (files) modes.
/// This algorithm can target IL, LRA, and maximum true peak. In dynamic mode, to accurately
/// detect true peaks, the audio stream will be upsampled to 192 kHz.
/// Use the `-ar` option or `aresample` filter to explicitly set an output sample rate.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [dualMono]: Treat mono input files as "dual-mono". If a mono file is intended for playback on a stereo system, its EBU R128 measurement will be perceptually incorrect. If set to `true`, this option will compensate for this effect. Multi-channel input files are not affected by this option. Options are true or false. Default is false. (range 0..1, default 0)
/// - [i]: Set integrated loudness target. Range is -70.0 - -5.0. Default value is -24.0. (range -70.0..-5.0, default -24.)
/// - [linear]: Normalize by linearly scaling the source audio. `measured_I`, `measured_LRA`, `measured_TP`, and `measured_thresh` must all be specified. Target LRA shouldn't be lower than source LRA and the change in integrated loudness shouldn't result in a true peak which exceeds the target TP. If any of these conditions aren't met, normalization mode will revert to `dynamic`. Options are `true` or `false`. Default is `true`. (range 0..1, default 1)
/// - [lra]: Set loudness range target. Range is 1.0 - 50.0. Default value is 7.0. (range 1.0..50.0, default 7.)
/// - [measuredI]: Measured IL of input file. Range is -99.0 - +0.0. (range -99.0..0.0, default 0.)
/// - [measuredLra]: Measured LRA of input file. Range is  0.0 - 99.0. (range 0.0..99.0, default 0.)
/// - [measuredThresh]: Measured threshold of input file. Range is -99.0 - +0.0. (range -99.0..0.0, default -70.)
/// - [measuredTp]: Measured true peak of input file. Range is  -99.0 - +99.0. (range -99.0..99.0, default 99.)
/// - [offset]: Set offset gain. Gain is applied before the true-peak limiter. Range is  -99.0 - +99.0. Default is +0.0. (range -99.0..99.0, default 0.)
/// - [printFormat]: Set print format for stats. Options are summary, json, or none. Default value is none. (range 0..2, default NONE)
/// - [statsFile]: Write stats to specified file. Format is controlled by @option{print_format}, which must be set. Specify `-` to write to standard output. Default is unset. (range 0..0, default "")
/// - [tp]: Set maximum true peak. Range is -9.0 - +0.0. Default value is -2.0. (range -9.0..0.0, default -2.)
final class LoudnormEffect extends AudioEffect {
  /// Default value for [i].
  static const double iDefault = -24.0;

  /// Minimum value for [i].
  static const double iMin = -70.0;

  /// Maximum value for [i].
  static const double iMax = -5.0;

  /// Default value for [lra].
  static const double lraDefault = 7.0;

  /// Minimum value for [lra].
  static const double lraMin = 1.0;

  /// Maximum value for [lra].
  static const double lraMax = 50.0;

  /// Default value for [measuredI].
  static const double measuredIDefault = 0.0;

  /// Minimum value for [measuredI].
  static const double measuredIMin = -99.0;

  /// Maximum value for [measuredI].
  static const double measuredIMax = 0.0;

  /// Default value for [measuredLra].
  static const double measuredLraDefault = 0.0;

  /// Minimum value for [measuredLra].
  static const double measuredLraMin = 0.0;

  /// Maximum value for [measuredLra].
  static const double measuredLraMax = 99.0;

  /// Default value for [measuredThresh].
  static const double measuredThreshDefault = -70.0;

  /// Minimum value for [measuredThresh].
  static const double measuredThreshMin = -99.0;

  /// Maximum value for [measuredThresh].
  static const double measuredThreshMax = 0.0;

  /// Default value for [measuredTp].
  static const double measuredTpDefault = 99.0;

  /// Minimum value for [measuredTp].
  static const double measuredTpMin = -99.0;

  /// Maximum value for [measuredTp].
  static const double measuredTpMax = 99.0;

  /// Default value for [offset].
  static const double offsetDefault = 0.0;

  /// Minimum value for [offset].
  static const double offsetMin = -99.0;

  /// Maximum value for [offset].
  static const double offsetMax = 99.0;

  /// Default value for [tp].
  static const double tpDefault = -2.0;

  /// Minimum value for [tp].
  static const double tpMin = -9.0;

  /// Maximum value for [tp].
  static const double tpMax = 0.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// treat mono input as dual-mono
  final bool dualMono;

  /// set integrated loudness target
  final double i;

  /// normalize linearly if possible
  final bool linear;

  /// set loudness range target
  final double lra;

  /// measured IL of input file
  final double measuredI;

  /// measured LRA of input file
  final double measuredLra;

  /// measured threshold of input file
  final double measuredThresh;

  /// measured true peak of input file
  final double measuredTp;

  /// set offset gain
  final double offset;

  /// set print format for stats
  final LoudnormPrintFormat printFormat;

  /// set stats output file
  final String statsFile;

  /// set maximum true peak
  final double tp;

  /// Creates an [LoudnormEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const LoudnormEffect({
    this.enabled = true,
    this.dualMono = false,
    this.i = -24.0,
    this.linear = true,
    this.lra = 7.0,
    this.measuredI = 0.0,
    this.measuredLra = 0.0,
    this.measuredThresh = -70.0,
    this.measuredTp = 99.0,
    this.offset = 0.0,
    this.printFormat = LoudnormPrintFormat.none,
    this.statsFile = '',
    this.tp = -2.0,
  });

  @override
  String get filterName => 'loudnorm';

  @override
  AudioFilter get filter => AudioFilter.loudnorm;

  /// Returns a copy of this [LoudnormEffect] with the given fields replaced.
  LoudnormEffect copyWith({
    bool? enabled,
    bool? dualMono,
    double? i,
    bool? linear,
    double? lra,
    double? measuredI,
    double? measuredLra,
    double? measuredThresh,
    double? measuredTp,
    double? offset,
    LoudnormPrintFormat? printFormat,
    String? statsFile,
    double? tp,
  }) => LoudnormEffect(
    enabled: enabled ?? this.enabled,
    dualMono: dualMono ?? this.dualMono,
    i: i ?? this.i,
    linear: linear ?? this.linear,
    lra: lra ?? this.lra,
    measuredI: measuredI ?? this.measuredI,
    measuredLra: measuredLra ?? this.measuredLra,
    measuredThresh: measuredThresh ?? this.measuredThresh,
    measuredTp: measuredTp ?? this.measuredTp,
    offset: offset ?? this.offset,
    printFormat: printFormat ?? this.printFormat,
    statsFile: statsFile ?? this.statsFile,
    tp: tp ?? this.tp,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoudnormEffect &&
          other.enabled == enabled &&
          other.dualMono == dualMono &&
          other.i == i &&
          other.linear == linear &&
          other.lra == lra &&
          other.measuredI == measuredI &&
          other.measuredLra == measuredLra &&
          other.measuredThresh == measuredThresh &&
          other.measuredTp == measuredTp &&
          other.offset == offset &&
          other.printFormat == printFormat &&
          other.statsFile == statsFile &&
          other.tp == tp);

  @override
  int get hashCode => Object.hash(
    enabled,
    dualMono,
    i,
    linear,
    lra,
    measuredI,
    measuredLra,
    measuredThresh,
    measuredTp,
    offset,
    printFormat,
    statsFile,
    tp,
  );

  @override
  String toString() =>
      'LoudnormEffect(enabled: $enabled, dualMono: $dualMono, i: $i, linear: $linear, lra: $lra, measuredI: $measuredI, measuredLra: $measuredLra, measuredThresh: $measuredThresh, measuredTp: $measuredTp, offset: $offset, printFormat: $printFormat, statsFile: $statsFile, tp: $tp)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(i >= iMin, 'loudnorm.i must be >= -70.0');
    assert(i <= iMax, 'loudnorm.i must be <= -5.0');
    assert(lra >= lraMin, 'loudnorm.lra must be >= 1.0');
    assert(lra <= lraMax, 'loudnorm.lra must be <= 50.0');
    assert(measuredI >= measuredIMin, 'loudnorm.measured_i must be >= -99.0');
    assert(measuredI <= measuredIMax, 'loudnorm.measured_i must be <= 0.0');
    assert(
      measuredLra >= measuredLraMin,
      'loudnorm.measured_lra must be >= 0.0',
    );
    assert(
      measuredLra <= measuredLraMax,
      'loudnorm.measured_lra must be <= 99.0',
    );
    assert(
      measuredThresh >= measuredThreshMin,
      'loudnorm.measured_thresh must be >= -99.0',
    );
    assert(
      measuredThresh <= measuredThreshMax,
      'loudnorm.measured_thresh must be <= 0.0',
    );
    assert(
      measuredTp >= measuredTpMin,
      'loudnorm.measured_tp must be >= -99.0',
    );
    assert(measuredTp <= measuredTpMax, 'loudnorm.measured_tp must be <= 99.0');
    assert(offset >= offsetMin, 'loudnorm.offset must be >= -99.0');
    assert(offset <= offsetMax, 'loudnorm.offset must be <= 99.0');
    assert(tp >= tpMin, 'loudnorm.tp must be >= -9.0');
    assert(tp <= tpMax, 'loudnorm.tp must be <= 0.0');
    final parts = <String>[];
    if (dualMono != false) parts.add('dual_mono=' + (dualMono ? '1' : '0'));
    if (i != -24.0) parts.add('i=' + _wireDouble(i));
    if (linear != true) parts.add('linear=' + (linear ? '1' : '0'));
    if (lra != 7.0) parts.add('lra=' + _wireDouble(lra));
    if (measuredI != 0.0) parts.add('measured_i=' + _wireDouble(measuredI));
    if (measuredLra != 0.0)
      parts.add('measured_lra=' + _wireDouble(measuredLra));
    if (measuredThresh != -70.0)
      parts.add('measured_thresh=' + _wireDouble(measuredThresh));
    if (measuredTp != 99.0) parts.add('measured_tp=' + _wireDouble(measuredTp));
    if (offset != 0.0) parts.add('offset=' + _wireDouble(offset));
    if (printFormat != LoudnormPrintFormat.none)
      parts.add('print_format=' + printFormat.mpvValue);
    if (statsFile != '') parts.add('stats_file=' + _wireString(statsFile));
    if (tp != -2.0) parts.add('tp=' + _wireDouble(tp));
    return parts.isEmpty
        ? 'lavfi-loudnorm'
        : 'lavfi-loudnorm=' + parts.join(':');
  }
}
