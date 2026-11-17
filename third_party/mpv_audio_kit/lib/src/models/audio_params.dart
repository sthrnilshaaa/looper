// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../internals/unset_sentinel.dart';
import '../types/enums/format.dart';
import '../types/sealed/channels.dart';

/// Audio format parameters reported by mpv. Used both for the decoder
/// side (`audio-params` + `audio-codec*`) and for the hardware output
/// side (`audio-out-params`).
final class AudioParams {
  /// Sample format reported by mpv. `null` when no audio is currently
  /// being decoded. mpv occasionally emits a format string the wrapper
  /// doesn't recognise (e.g. a future-version sample type) — those fall
  /// back to [Format.auto] via [Format.fromMpv].
  final Format? format;

  /// Sample rate in Hz.
  final int? sampleRate;

  /// Channel layout reported by mpv. `null` when no audio is currently
  /// being decoded. Unknown layouts fall back to [Channels.custom] via
  /// [Channels.fromMpv].
  final Channels? channels;

  /// Number of audio channels.
  final int? channelCount;

  /// Human-readable channel layout description.
  final String? hrChannels;

  /// Raw value of mpv's `audio-codec` property. The exact form
  /// (short id vs descriptive name) varies by mpv build and codec
  /// (`mp3` vs `mp3float`, `aac` vs `aac_lc`, `FLAC` vs
  /// `FLAC (Free Lossless Audio Codec)`); treat as an opaque hint.
  /// For reliable codec-family matching, do a case-insensitive
  /// substring check against BOTH [codec] and [codecName].
  final String? codec;

  /// Raw value of mpv's `audio-codec-name` property. Same volatility
  /// caveat as [codec] — the short/descriptive split is not stable
  /// across mpv versions, and one of the two may be absent on a
  /// given file.
  final String? codecName;

  /// Creates an audio-format descriptor. Every field is nullable because
  /// mpv reports them only while audio is being decoded or output.
  const AudioParams({
    this.format,
    this.sampleRate,
    this.channels,
    this.channelCount,
    this.hrChannels,
    this.codec,
    this.codecName,
  });

  /// Returns a copy with the given fields replaced. Pass `null` explicitly
  /// to clear a field; omitted fields keep their current value.
  AudioParams copyWith({
    Object? format = unset,
    Object? sampleRate = unset,
    Object? channels = unset,
    Object? channelCount = unset,
    Object? hrChannels = unset,
    Object? codec = unset,
    Object? codecName = unset,
  }) =>
      AudioParams(
        format: identical(format, unset) ? this.format : format as Format?,
        sampleRate:
            identical(sampleRate, unset) ? this.sampleRate : sampleRate as int?,
        channels:
            identical(channels, unset) ? this.channels : channels as Channels?,
        channelCount: identical(channelCount, unset)
            ? this.channelCount
            : channelCount as int?,
        hrChannels: identical(hrChannels, unset)
            ? this.hrChannels
            : hrChannels as String?,
        codec: identical(codec, unset) ? this.codec : codec as String?,
        codecName:
            identical(codecName, unset) ? this.codecName : codecName as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AudioParams &&
          other.format == format &&
          other.sampleRate == sampleRate &&
          other.channels == channels &&
          other.channelCount == channelCount &&
          other.hrChannels == hrChannels &&
          other.codec == codec &&
          other.codecName == codecName);

  @override
  int get hashCode => Object.hash(
        format,
        sampleRate,
        channels,
        channelCount,
        hrChannels,
        codec,
        codecName,
      );

  @override
  String toString() =>
      'AudioParams(format: ${format?.mpvValue}, sampleRate: $sampleRate, '
      'channels: $channels, channelCount: $channelCount, '
      'hrChannels: $hrChannels, codec: $codec, codecName: $codecName)';
}
