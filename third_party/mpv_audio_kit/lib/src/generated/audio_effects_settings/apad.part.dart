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

/// Configuration for the `apad` audio effect.
///
/// Pad the end of an audio stream with silence.
///
/// This can be used together with @command{ffmpeg} @option{-shortest} to
/// extend audio streams to the same length as the video stream.
///
/// A description of the accepted options follows.
///
/// Parameters:
/// - [packetSize]: Set silence packet size. Default value is 4096. (range 0..2147483647, default 4096)
/// - [padDur]: Specify the duration of samples of silence to add. See time duration syntax for the accepted syntax. Used only if set to non-negative value. (range -1..9223372036854775807, default -1)
/// - [padLen]: Set the number of samples of silence to add to the end. After the value is reached, the stream is terminated. This option is mutually exclusive with @option{whole_len}. (range -1..9223372036854775807, default -1)
/// - [wholeDur]: Specify the minimum total duration in the output audio stream. See time duration syntax for the accepted syntax. Used only if set to non-negative value. If the value is longer than the input audio length, silence is added to the end, until the value is reached. This option is mutually exclusive with @option{pad_dur} (range -1..9223372036854775807, default -1)
/// - [wholeLen]: Set the minimum total number of samples in the output audio stream. If the value is longer than the input audio length, silence is added to the end, until the value is reached. This option is mutually exclusive with @option{pad_len}. (range -1..9223372036854775807, default -1)
final class ApadEffect extends AudioEffect {
  /// Default value for [packetSize].
  static const int packetSizeDefault = 4096;

  /// Minimum value for [packetSize].
  static const int packetSizeMin = 0;

  /// Maximum value for [packetSize].
  static const int packetSizeMax = 2147483647;

  /// Default value for [padLen].
  static const int padLenDefault = -1;

  /// Minimum value for [padLen].
  static const int padLenMin = -1;

  /// Maximum value for [padLen].
  static const int padLenMax = 9007199254740991 * 1024 + 1023;

  /// Default value for [wholeLen].
  static const int wholeLenDefault = -1;

  /// Minimum value for [wholeLen].
  static const int wholeLenMin = -1;

  /// Maximum value for [wholeLen].
  static const int wholeLenMax = 9007199254740991 * 1024 + 1023;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set silence packet size
  final int packetSize;

  /// set duration of silence to add
  final Duration padDur;

  /// set number of samples of silence to add
  final int padLen;

  /// set minimum target duration in the audio stream
  final Duration wholeDur;

  /// set minimum target number of samples in the audio stream
  final int wholeLen;

  /// Creates an [ApadEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const ApadEffect({
    this.enabled = true,
    this.packetSize = 4096,
    this.padDur = const Duration(microseconds: -1),
    this.padLen = -1,
    this.wholeDur = const Duration(microseconds: -1),
    this.wholeLen = -1,
  });

  @override
  String get filterName => 'apad';

  @override
  AudioFilter get filter => AudioFilter.apad;

  /// Returns a copy of this [ApadEffect] with the given fields replaced.
  ApadEffect copyWith({
    bool? enabled,
    int? packetSize,
    Duration? padDur,
    int? padLen,
    Duration? wholeDur,
    int? wholeLen,
  }) => ApadEffect(
    enabled: enabled ?? this.enabled,
    packetSize: packetSize ?? this.packetSize,
    padDur: padDur ?? this.padDur,
    padLen: padLen ?? this.padLen,
    wholeDur: wholeDur ?? this.wholeDur,
    wholeLen: wholeLen ?? this.wholeLen,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApadEffect &&
          other.enabled == enabled &&
          other.packetSize == packetSize &&
          other.padDur == padDur &&
          other.padLen == padLen &&
          other.wholeDur == wholeDur &&
          other.wholeLen == wholeLen);

  @override
  int get hashCode =>
      Object.hash(enabled, packetSize, padDur, padLen, wholeDur, wholeLen);

  @override
  String toString() =>
      'ApadEffect(enabled: $enabled, packetSize: $packetSize, padDur: $padDur, padLen: $padLen, wholeDur: $wholeDur, wholeLen: $wholeLen)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(packetSize >= packetSizeMin, 'apad.packet_size must be >= 0');
    assert(
      packetSize <= packetSizeMax,
      'apad.packet_size must be <= 2147483647',
    );
    assert(padLen >= padLenMin, 'apad.pad_len must be >= -1');
    assert(padLen <= padLenMax, 'apad.pad_len must be <= 9223372036854775807');
    assert(wholeLen >= wholeLenMin, 'apad.whole_len must be >= -1');
    assert(
      wholeLen <= wholeLenMax,
      'apad.whole_len must be <= 9223372036854775807',
    );
    final parts = <String>[];
    if (packetSize != 4096) parts.add('packet_size=' + packetSize.toString());
    if (padDur != const Duration(microseconds: -1))
      parts.add('pad_dur=' + _wireDuration(padDur));
    if (padLen != -1) parts.add('pad_len=' + padLen.toString());
    if (wholeDur != const Duration(microseconds: -1))
      parts.add('whole_dur=' + _wireDuration(wholeDur));
    if (wholeLen != -1) parts.add('whole_len=' + wholeLen.toString());
    return parts.isEmpty ? 'lavfi-apad' : 'lavfi-apad=' + parts.join(':');
  }
}
