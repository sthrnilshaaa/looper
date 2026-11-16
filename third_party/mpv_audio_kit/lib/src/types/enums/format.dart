// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Audio sample format passed to mpv's `audio-format` property.
///
/// Set via [Player.setAudioFormat]; reset to mpv's auto-pick with
/// [Format.auto]. The wire-level value mpv expects is exposed via
/// [mpvValue]. Unknown / empty values map back to [auto].
enum Format {
  /// Let mpv pick the format (mpv's `no` / unset). Default.
  auto('no'),

  /// 8-bit unsigned integer (interleaved).
  u8('u8'),

  /// 8-bit unsigned integer (planar).
  u8Planar('u8p'),

  /// 16-bit signed integer (interleaved).
  s16('s16'),

  /// 16-bit signed integer (planar).
  s16Planar('s16p'),

  /// 32-bit signed integer (interleaved).
  s32('s32'),

  /// 32-bit signed integer (planar).
  s32Planar('s32p'),

  /// 64-bit signed integer (interleaved).
  s64('s64'),

  /// 64-bit signed integer (planar).
  s64Planar('s64p'),

  /// 32-bit float (interleaved).
  float32('float'),

  /// 32-bit float (planar).
  float32Planar('floatp'),

  /// 64-bit float (interleaved).
  float64('double'),

  /// 64-bit float (planar).
  float64Planar('doublep');

  const Format(this.mpvValue);

  /// The wire-level string mpv expects on the `audio-format` property.
  final String mpvValue;

  /// Maps a raw mpv-side value back to the enum. Unknown / empty → [auto].
  static Format fromMpv(String raw) => switch (raw) {
        '' || 'no' => auto,
        'u8' => u8,
        'u8p' => u8Planar,
        's16' => s16,
        's16p' => s16Planar,
        's32' => s32,
        's32p' => s32Planar,
        's64' => s64,
        's64p' => s64Planar,
        'float' => float32,
        'floatp' => float32Planar,
        'double' => float64,
        'doublep' => float64Planar,
        _ => auto,
      };
}
