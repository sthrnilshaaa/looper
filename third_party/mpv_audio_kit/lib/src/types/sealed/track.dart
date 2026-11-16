// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// How [Player.setAudioTrack] should resolve mpv's `aid` property.
///
/// Sealed because [Track.id] carries an `int` payload that plain
/// enums can't model. Use the [auto] / [off] static fields and the
/// [id] factory at call-site:
///
/// ```dart
/// await player.setAudioTrack(Track.auto);
/// await player.setAudioTrack(Track.off);
/// await player.setAudioTrack(Track.id(2));
/// ```
sealed class Track {
  const Track._();

  /// Defer to mpv's automatic track choice (the container's
  /// default-flagged track, or the first audio track if none is
  /// flagged). Equivalent to mpv's `aid=auto`.
  static const Track auto = TrackAuto._();

  /// Disable audio output entirely. Equivalent to mpv's `aid=no`.
  /// Useful for files where you want only metadata / cover art without
  /// playing audio.
  static const Track off = TrackOff._();

  /// Select the audio track with the given mpv [trackId]. IDs match
  /// `MpvTrack.id` entries in `PlayerState.tracks`.
  const factory Track.id(int trackId) = TrackId._;

  /// The wire-level string mpv expects for the `aid` property.
  String get mpvValue => switch (this) {
        TrackAuto() => 'auto',
        TrackOff() => 'no',
        TrackId(:final trackId) => trackId.toString(),
      };
}

/// The [Track.auto] variant — defer to mpv's automatic track choice.
final class TrackAuto extends Track {
  const TrackAuto._() : super._();
}

/// The [Track.off] variant — disable audio output entirely.
final class TrackOff extends Track {
  const TrackOff._() : super._();
}

/// The [Track.id] variant — select a specific track by mpv track id.
final class TrackId extends Track {
  /// The mpv track id to select, matching an entry's `MpvTrack.id`.
  final int trackId;
  const TrackId._(this.trackId) : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TrackId && other.trackId == trackId;

  @override
  int get hashCode => Object.hash(TrackId, trackId);

  @override
  String toString() => 'Track.id($trackId)';
}
