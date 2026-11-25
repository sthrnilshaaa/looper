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

/// Configuration for the `afftfilt` audio effect.
///
/// Apply arbitrary expressions to samples in frequency domain.
///
/// Parameters:
/// - [imag]: Set frequency domain imaginary expression for each separate channel separated by '|'. Default is "im".  Each expression in `real` and `imag` can contain the following constants and functions: (range 0..0, default "im")
/// - [overlap]: set window overlap (range 0..1, default 0.75)
/// - [real]: Set frequency domain real expression for each separate channel separated by '|'. Default is "re". If the number of input channels is greater than the number of expressions, the last specified expression is used for the remaining output channels. (range 0..0, default "re")
/// - [winFunc]: Set window function.  It accepts the following values: (default WFUNC_HANNING)
/// - [winSize]: Set window size. Allowed range is from 16 to 131072. Default is `4096` (range 16..131072, default 4096)
final class AfftfiltEffect extends AudioEffect {
  /// Default value for [overlap].
  static const double overlapDefault = 0.75;

  /// Minimum value for [overlap].
  static const double overlapMin = 0.0;

  /// Maximum value for [overlap].
  static const double overlapMax = 1.0;

  /// Default value for [winSize].
  static const int winSizeDefault = 4096;

  /// Minimum value for [winSize].
  static const int winSizeMin = 16;

  /// Maximum value for [winSize].
  static const int winSizeMax = 131072;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set channels imaginary expressions
  final String imag;

  /// set window overlap
  final double overlap;

  /// set channels real expressions
  final String real;

  /// set window function
  final AfftfiltWinFunc winFunc;

  /// set window size
  final int winSize;

  /// Creates an [AfftfiltEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AfftfiltEffect({
    this.enabled = true,
    this.imag = 'im',
    this.overlap = 0.75,
    this.real = 're',
    this.winFunc = AfftfiltWinFunc.hann,
    this.winSize = 4096,
  });

  @override
  String get filterName => 'afftfilt';

  @override
  AudioFilter get filter => AudioFilter.afftfilt;

  /// Returns a copy of this [AfftfiltEffect] with the given fields replaced.
  AfftfiltEffect copyWith({
    bool? enabled,
    String? imag,
    double? overlap,
    String? real,
    AfftfiltWinFunc? winFunc,
    int? winSize,
  }) => AfftfiltEffect(
    enabled: enabled ?? this.enabled,
    imag: imag ?? this.imag,
    overlap: overlap ?? this.overlap,
    real: real ?? this.real,
    winFunc: winFunc ?? this.winFunc,
    winSize: winSize ?? this.winSize,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AfftfiltEffect &&
          other.enabled == enabled &&
          other.imag == imag &&
          other.overlap == overlap &&
          other.real == real &&
          other.winFunc == winFunc &&
          other.winSize == winSize);

  @override
  int get hashCode =>
      Object.hash(enabled, imag, overlap, real, winFunc, winSize);

  @override
  String toString() =>
      'AfftfiltEffect(enabled: $enabled, imag: $imag, overlap: $overlap, real: $real, winFunc: $winFunc, winSize: $winSize)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(overlap >= overlapMin, 'afftfilt.overlap must be >= 0');
    assert(overlap <= overlapMax, 'afftfilt.overlap must be <= 1');
    assert(winSize >= winSizeMin, 'afftfilt.win_size must be >= 16');
    assert(winSize <= winSizeMax, 'afftfilt.win_size must be <= 131072');
    final parts = <String>[];
    if (imag != 'im') parts.add('imag=' + _wireString(imag));
    if (overlap != 0.75) parts.add('overlap=' + _wireDouble(overlap));
    if (real != 're') parts.add('real=' + _wireString(real));
    if (winFunc != AfftfiltWinFunc.hann)
      parts.add('win_func=' + winFunc.mpvValue);
    if (winSize != 4096) parts.add('win_size=' + winSize.toString());
    return parts.isEmpty
        ? 'lavfi-afftfilt'
        : 'lavfi-afftfilt=' + parts.join(':');
  }
}
