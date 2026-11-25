// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

/// The sample encoding of a [PcmFormat]: interleaved, little endian.
enum PcmEncoding {
  /// Unsigned 8 bit.
  u8(1, 'u8'),

  /// Signed 16 bit, the usual speech and CD format.
  s16le(2, 's16le'),

  /// Signed 24 bit packed in 3 bytes.
  s24le(3, 's24le'),

  /// Signed 32 bit.
  s32le(4, 's32le'),

  /// 32 bit float, nominal range -1 to 1.
  f32le(4, 'floatle');

  const PcmEncoding(this.bytesPerSample, this.mpvValue);

  /// Bytes of one sample of one channel.
  final int bytesPerSample;

  /// The name mpv's raw audio demuxer uses (`demuxer-rawaudio-format`).
  final String mpvValue;
}

/// The layout of the raw PCM a [PcmSource] carries: no header, samples
/// interleaved by channel.
///
/// ```dart
/// const speech = PcmFormat(sampleRate: 24000, channels: 1);
/// const music = PcmFormat(
///   sampleRate: 48000,
///   channels: 2,
///   encoding: PcmEncoding.f32le,
/// );
/// ```
final class PcmFormat {
  /// A format of [sampleRate] Hz (1000 to 384000), [channels] channels
  /// (1 to 8) and [encoding] samples.
  const PcmFormat({
    required this.sampleRate,
    required this.channels,
    this.encoding = PcmEncoding.s16le,
  }) : assert(sampleRate >= 1000 && sampleRate <= 384000),
       assert(channels >= 1 && channels <= 8);

  /// Frames per second.
  final int sampleRate;

  /// Interleaved channels per frame.
  final int channels;

  /// The encoding of each sample.
  final PcmEncoding encoding;

  /// Bytes of one frame: one sample for every channel.
  int get bytesPerFrame => encoding.bytesPerSample * channels;

  /// Bytes of one second of audio.
  int get bytesPerSecond => bytesPerFrame * sampleRate;

  /// The playing time of [bytes] bytes, whole frames only.
  Duration durationOf(int bytes) => Duration(
    microseconds:
        (bytes ~/ bytesPerFrame) * Duration.microsecondsPerSecond ~/ sampleRate,
  );

  /// Throws [ArgumentError] when a field is out of range. The constructor
  /// is `const`, so release builds skip its asserts.
  @internal
  void validate() {
    RangeError.checkValueInInterval(sampleRate, 1000, 384000, 'sampleRate');
    RangeError.checkValueInInterval(channels, 1, 8, 'channels');
  }

  @override
  bool operator ==(Object other) =>
      other is PcmFormat &&
      other.sampleRate == sampleRate &&
      other.channels == channels &&
      other.encoding == encoding;

  @override
  int get hashCode => Object.hash(sampleRate, channels, encoding);

  @override
  String toString() =>
      'PcmFormat(sampleRate: $sampleRate, channels: $channels, '
      'encoding: ${encoding.name})';
}
