// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:mpv_audio_kit/src/types/enums/replay_gain.dart';

/// Aggregate of mpv's four ReplayGain properties (`replaygain`,
/// `replaygain-preamp`, `replaygain-clip`, `replaygain-fallback`).
///
/// Apply atomically via [Player.setReplayGain]. For one-off tweaks
/// use `state.replayGain.copyWith(preamp: -3)`. Read the current
/// configuration via [PlayerState.replayGain] or observe live changes
/// via [PlayerStream.replayGain].
final class ReplayGainSettings {
  /// Normalization mode (off / per-track / per-album).
  final ReplayGain mode;

  /// Pre-amplification in dB applied before normalization.
  final double preamp;

  /// Whether to allow output clipping when normalizing loud tracks.
  final bool clip;

  /// Gain in dB applied to files without ReplayGain tags.
  final double fallback;

  /// Creates a ReplayGain configuration. Each default mirrors the
  /// corresponding mpv property default (normalization off).
  const ReplayGainSettings({
    this.mode = ReplayGain.no,
    this.preamp = 0.0,
    this.clip = false,
    this.fallback = 0.0,
  });

  /// Returns a copy with the given fields replaced. Omitted fields keep
  /// their current value.
  ReplayGainSettings copyWith({
    ReplayGain? mode,
    double? preamp,
    bool? clip,
    double? fallback,
  }) =>
      ReplayGainSettings(
        mode: mode ?? this.mode,
        preamp: preamp ?? this.preamp,
        clip: clip ?? this.clip,
        fallback: fallback ?? this.fallback,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReplayGainSettings &&
          other.mode == mode &&
          other.preamp == preamp &&
          other.clip == clip &&
          other.fallback == fallback);

  @override
  int get hashCode => Object.hash(mode, preamp, clip, fallback);

  @override
  String toString() => 'ReplayGainSettings(mode: $mode, preamp: $preamp, '
      'clip: $clip, fallback: $fallback)';
}
