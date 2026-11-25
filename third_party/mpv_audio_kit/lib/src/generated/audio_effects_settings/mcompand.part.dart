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

/// Configuration for the `mcompand` audio effect.
///
/// Multiband Compress or expand the audio's dynamic range.
///
/// The input audio is divided into bands using 4th order Linkwitz-Riley IIRs.
/// This is akin to the crossover of a loudspeaker, and results in flat frequency
/// response when absent compander action.
///
/// It accepts the following parameters:
///
/// Parameters:
/// - [args]: This option syntax is: attack,decay,\[attack,decay..\] soft-knee points crossover_frequency \[delay \[initial_volume \[gain\]\]\] | attack,decay ... For explanation of each item refer to compand filter documentation. (range 0..0, default "0.005,0.1 6 -47/-40,-34/-34,-17/-33 100 | 0.003,0.05 6 -47/-40,-34/-34,-17/-33 400 | 0.000625,0.0125 6 -47/-40,-34/-34,-15/-33 1600 | 0.0001,0.025 6 -47/-40,-34/-34,-31/-31,-0/-30 6400 | 0,0.025 6 -38/-31,-28/-28,-0/-25 22000")
final class McompandEffect extends AudioEffect {
  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set parameters for each band
  final String args;

  /// Creates an [McompandEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const McompandEffect({
    this.enabled = true,
    this.args =
        '0.005,0.1 6 -47/-40,-34/-34,-17/-33 100 | 0.003,0.05 6 -47/-40,-34/-34,-17/-33 400 | 0.000625,0.0125 6 -47/-40,-34/-34,-15/-33 1600 | 0.0001,0.025 6 -47/-40,-34/-34,-31/-31,-0/-30 6400 | 0,0.025 6 -38/-31,-28/-28,-0/-25 22000',
  });

  @override
  String get filterName => 'mcompand';

  @override
  AudioFilter get filter => AudioFilter.mcompand;

  /// Returns a copy of this [McompandEffect] with the given fields replaced.
  McompandEffect copyWith({bool? enabled, String? args}) =>
      McompandEffect(enabled: enabled ?? this.enabled, args: args ?? this.args);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is McompandEffect &&
          other.enabled == enabled &&
          other.args == args);

  @override
  int get hashCode => Object.hash(enabled, args);

  @override
  String toString() => 'McompandEffect(enabled: $enabled, args: $args)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    final parts = <String>[];
    if (args !=
        '0.005,0.1 6 -47/-40,-34/-34,-17/-33 100 | 0.003,0.05 6 -47/-40,-34/-34,-17/-33 400 | 0.000625,0.0125 6 -47/-40,-34/-34,-15/-33 1600 | 0.0001,0.025 6 -47/-40,-34/-34,-31/-31,-0/-30 6400 | 0,0.025 6 -38/-31,-28/-28,-0/-25 22000')
      parts.add('args=' + _wireString(args));
    return parts.isEmpty
        ? 'lavfi-mcompand'
        : 'lavfi-mcompand=' + parts.join(':');
  }
}
