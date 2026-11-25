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

/// Configuration for the `crossfeed` audio effect.
///
/// Apply headphone crossfeed filter.
///
/// Crossfeed is the process of blending the left and right channels of stereo
/// audio recording.
/// It is mainly used to reduce extreme stereo separation of low frequencies.
///
/// The intent is to produce more speaker like sound to the listener.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [blockSize]: Set block size used for reverse IIR processing. If this value is set to high enough value (higher than impulse response length truncated when reaches near zero values) filtering will become linear phase otherwise if not big enough it will just produce nasty artifacts.  Note that filter delay will be exactly this many samples when set to non-zero value. (range 0..32768, default 0)
/// - [levelIn]: Set input gain. Default is 0.9. (range 0..1, default .9, runtime-tunable)
/// - [levelOut]: Set output gain. Default is 1. (range 0..1, default 1., runtime-tunable)
/// - [range]: Set soundstage wideness. Default is 0.5. Allowed range is from 0 to 1. This sets cut off frequency of low shelf filter. Default is cut off near 1550 Hz. With range set to 1 cut off frequency is set to 2100 Hz. (range 0..1, default .5, runtime-tunable)
/// - [slope]: Set curve slope of low shelf filter. Default is 0.5. Allowed range is from 0.01 to 1. (range .01..1, default .5, runtime-tunable)
/// - [strength]: Set strength of crossfeed. Default is 0.2. Allowed range is from 0 to 1. This sets gain of low shelf filter for side part of stereo image. Default is -6dB. Max allowed is -30db when strength is set to 1. (range 0..1, default .2, runtime-tunable)
final class CrossfeedEffect extends AudioEffect {
  /// Default value for [blockSize].
  static const int blockSizeDefault = 0;

  /// Minimum value for [blockSize].
  static const int blockSizeMin = 0;

  /// Maximum value for [blockSize].
  static const int blockSizeMax = 32768;

  /// Default value for [levelIn].
  static const double levelInDefault = .9;

  /// Minimum value for [levelIn].
  static const double levelInMin = 0.0;

  /// Maximum value for [levelIn].
  static const double levelInMax = 1.0;

  /// Default value for [levelOut].
  static const double levelOutDefault = 1.0;

  /// Minimum value for [levelOut].
  static const double levelOutMin = 0.0;

  /// Maximum value for [levelOut].
  static const double levelOutMax = 1.0;

  /// Default value for [range].
  static const double rangeDefault = .5;

  /// Minimum value for [range].
  static const double rangeMin = 0.0;

  /// Maximum value for [range].
  static const double rangeMax = 1.0;

  /// Default value for [slope].
  static const double slopeDefault = .5;

  /// Minimum value for [slope].
  static const double slopeMin = .01;

  /// Maximum value for [slope].
  static const double slopeMax = 1.0;

  /// Default value for [strength].
  static const double strengthDefault = .2;

  /// Minimum value for [strength].
  static const double strengthMin = 0.0;

  /// Maximum value for [strength].
  static const double strengthMax = 1.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set the block size
  final int blockSize;

  /// set level in
  final double levelIn;

  /// set level out
  final double levelOut;

  /// set soundstage wideness
  final double range;

  /// set curve slope
  final double slope;

  /// set crossfeed strength
  final double strength;

  /// Creates an [CrossfeedEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const CrossfeedEffect({
    this.enabled = true,
    this.blockSize = 0,
    this.levelIn = .9,
    this.levelOut = 1.0,
    this.range = .5,
    this.slope = .5,
    this.strength = .2,
  });

  @override
  String get filterName => 'crossfeed';

  @override
  AudioFilter get filter => AudioFilter.crossfeed;

  /// Returns a copy of this [CrossfeedEffect] with the given fields replaced.
  CrossfeedEffect copyWith({
    bool? enabled,
    int? blockSize,
    double? levelIn,
    double? levelOut,
    double? range,
    double? slope,
    double? strength,
  }) => CrossfeedEffect(
    enabled: enabled ?? this.enabled,
    blockSize: blockSize ?? this.blockSize,
    levelIn: levelIn ?? this.levelIn,
    levelOut: levelOut ?? this.levelOut,
    range: range ?? this.range,
    slope: slope ?? this.slope,
    strength: strength ?? this.strength,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CrossfeedEffect &&
          other.enabled == enabled &&
          other.blockSize == blockSize &&
          other.levelIn == levelIn &&
          other.levelOut == levelOut &&
          other.range == range &&
          other.slope == slope &&
          other.strength == strength);

  @override
  int get hashCode => Object.hash(
    enabled,
    blockSize,
    levelIn,
    levelOut,
    range,
    slope,
    strength,
  );

  @override
  String toString() =>
      'CrossfeedEffect(enabled: $enabled, blockSize: $blockSize, levelIn: $levelIn, levelOut: $levelOut, range: $range, slope: $slope, strength: $strength)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(blockSize >= blockSizeMin, 'crossfeed.block_size must be >= 0');
    assert(blockSize <= blockSizeMax, 'crossfeed.block_size must be <= 32768');
    assert(levelIn >= levelInMin, 'crossfeed.level_in must be >= 0');
    assert(levelIn <= levelInMax, 'crossfeed.level_in must be <= 1');
    assert(levelOut >= levelOutMin, 'crossfeed.level_out must be >= 0');
    assert(levelOut <= levelOutMax, 'crossfeed.level_out must be <= 1');
    assert(range >= rangeMin, 'crossfeed.range must be >= 0');
    assert(range <= rangeMax, 'crossfeed.range must be <= 1');
    assert(slope >= slopeMin, 'crossfeed.slope must be >= .01');
    assert(slope <= slopeMax, 'crossfeed.slope must be <= 1');
    assert(strength >= strengthMin, 'crossfeed.strength must be >= 0');
    assert(strength <= strengthMax, 'crossfeed.strength must be <= 1');
    final parts = <String>[];
    if (blockSize != 0) parts.add('block_size=' + blockSize.toString());
    if (levelIn != .9) parts.add('level_in=' + _wireDouble(levelIn));
    if (levelOut != 1.0) parts.add('level_out=' + _wireDouble(levelOut));
    if (range != .5) parts.add('range=' + _wireDouble(range));
    if (slope != .5) parts.add('slope=' + _wireDouble(slope));
    if (strength != .2) parts.add('strength=' + _wireDouble(strength));
    return parts.isEmpty
        ? 'lavfi-crossfeed'
        : 'lavfi-crossfeed=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant CrossfeedEffect prev) {
    final out = <(String, String)>[];
    if (blockSize != prev.blockSize) return null;
    if (levelIn != prev.levelIn) {
      out.add(('level_in', _wireDouble(levelIn)));
    }
    if (levelOut != prev.levelOut) {
      out.add(('level_out', _wireDouble(levelOut)));
    }
    if (range != prev.range) {
      out.add(('range', _wireDouble(range)));
    }
    if (slope != prev.slope) {
      out.add(('slope', _wireDouble(slope)));
    }
    if (strength != prev.strength) {
      out.add(('strength', _wireDouble(strength)));
    }
    return out;
  }
}
