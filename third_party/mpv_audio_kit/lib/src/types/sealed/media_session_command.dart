// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../enums/loop.dart';

/// A command issued by the operating system's media session — pressed
/// on the lockscreen, sent by a Bluetooth headset, triggered by Siri
/// / Google Assistant, or forwarded by Android Auto / CarPlay.
///
/// Sealed because [MediaSessionCommandSeekTo] and
/// [MediaSessionCommandSeekBy] carry [Duration] payloads that plain
/// enums can't model. Pattern-match exhaustively in
/// [PlayerStream.mediaSessionCommands] subscribers:
///
/// ```dart
/// player.stream.mediaSessionCommands.listen((command) {
///   switch (command) {
///     case MediaSessionCommandPlay():     analytics.log('lockscreen-play');
///     case MediaSessionCommandSeekTo(:final position):
///       logging.info('user scrubbed to $position');
///     case _: break;
///   }
/// });
/// ```
///
/// Commands are also auto-applied to the [Player] by default — the
/// stream above is for analytics / interception only. The package
/// routes [next] / [previous] to mpv's playlist when it holds more than
/// one entry; otherwise the command is emit-only (the consumer's queue
/// logic handles it).
sealed class MediaSessionCommand {
  const MediaSessionCommand._();

  /// Start or resume playback.
  static const MediaSessionCommand play = MediaSessionCommandPlay._();

  /// Pause playback.
  static const MediaSessionCommand pause = MediaSessionCommandPause._();

  /// Toggle between play and pause. Sent by single-button hardware
  /// (most Bluetooth headsets, macOS spacebar key).
  static const MediaSessionCommand playPause = MediaSessionCommandPlayPause._();

  /// Stop playback and clear the now-playing entry.
  static const MediaSessionCommand stop = MediaSessionCommandStop._();

  /// Skip to the next track.
  static const MediaSessionCommand next = MediaSessionCommandNext._();

  /// Skip to the previous track.
  static const MediaSessionCommand previous = MediaSessionCommandPrevious._();

  /// Seek to an absolute position in the current track.
  const factory MediaSessionCommand.seekTo(Duration position) =
      MediaSessionCommandSeekTo._;

  /// Seek by a relative offset from the current position. Negative
  /// offsets rewind.
  const factory MediaSessionCommand.seekBy(Duration offset) =
      MediaSessionCommandSeekBy._;

  /// Change the repeat mode (cycled through off / file / playlist by
  /// the OS UI). Auto-applied to [Player.setLoop].
  const factory MediaSessionCommand.setRepeatMode(Loop loop) =
      MediaSessionCommandSetRepeatMode._;

  /// Toggle shuffle. Auto-applied to [Player.setShuffle].
  const factory MediaSessionCommand.setShuffle(bool shuffle) =
      MediaSessionCommandSetShuffle._;

  /// Change playback rate (e.g. 1.0 / 1.5 / 2.0). Auto-applied to
  /// [Player.setRate]. The selectable rates are governed by
  /// [MediaSession.supportedPlaybackRates].
  const factory MediaSessionCommand.setPlaybackRate(double rate) =
      MediaSessionCommandSetPlaybackRate._;

  /// The "like" / favourite control was pressed (advertise it with
  /// [MediaAction.like]). **Emit-only:** NOT auto-applied — there is no
  /// built-in favourite concept, so react to it on
  /// [PlayerStream.mediaSessionCommands] and reflect the new state back via
  /// [MediaSession.isFavorite] (fills/empties the star).
  static const MediaSessionCommand like = MediaSessionCommandLike._();
}

/// The [MediaSessionCommand.play] variant — start or resume playback.
final class MediaSessionCommandPlay extends MediaSessionCommand {
  const MediaSessionCommandPlay._() : super._();

  @override
  String toString() => 'MediaSessionCommand.play';
}

/// The [MediaSessionCommand.pause] variant — pause playback.
final class MediaSessionCommandPause extends MediaSessionCommand {
  const MediaSessionCommandPause._() : super._();

  @override
  String toString() => 'MediaSessionCommand.pause';
}

/// The [MediaSessionCommand.playPause] variant — toggle between play and
/// pause.
final class MediaSessionCommandPlayPause extends MediaSessionCommand {
  const MediaSessionCommandPlayPause._() : super._();

  @override
  String toString() => 'MediaSessionCommand.playPause';
}

/// The [MediaSessionCommand.stop] variant — stop playback and clear the
/// now-playing entry.
final class MediaSessionCommandStop extends MediaSessionCommand {
  const MediaSessionCommandStop._() : super._();

  @override
  String toString() => 'MediaSessionCommand.stop';
}

/// The [MediaSessionCommand.next] variant — skip to the next track.
final class MediaSessionCommandNext extends MediaSessionCommand {
  const MediaSessionCommandNext._() : super._();

  @override
  String toString() => 'MediaSessionCommand.next';
}

/// The [MediaSessionCommand.previous] variant — skip to the previous
/// track.
final class MediaSessionCommandPrevious extends MediaSessionCommand {
  const MediaSessionCommandPrevious._() : super._();

  @override
  String toString() => 'MediaSessionCommand.previous';
}

/// The [MediaSessionCommand.like] variant — the favourite/like control was
/// pressed. Emit-only (no built-in player effect).
final class MediaSessionCommandLike extends MediaSessionCommand {
  const MediaSessionCommandLike._() : super._();

  @override
  String toString() => 'MediaSessionCommand.like';
}

/// The [MediaSessionCommand.seekTo] variant — seek to an absolute
/// position, carrying the target [position].
final class MediaSessionCommandSeekTo extends MediaSessionCommand {
  /// Absolute position to seek to.
  final Duration position;

  const MediaSessionCommandSeekTo._(this.position) : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaSessionCommandSeekTo && other.position == position;

  @override
  int get hashCode => Object.hash(MediaSessionCommandSeekTo, position);

  @override
  String toString() => 'MediaSessionCommand.seekTo($position)';
}

/// The [MediaSessionCommand.seekBy] variant — seek by a relative
/// [offset]. Negative offsets rewind.
final class MediaSessionCommandSeekBy extends MediaSessionCommand {
  /// Relative offset to seek by. Negative offsets rewind.
  final Duration offset;

  const MediaSessionCommandSeekBy._(this.offset) : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaSessionCommandSeekBy && other.offset == offset;

  @override
  int get hashCode => Object.hash(MediaSessionCommandSeekBy, offset);

  @override
  String toString() => 'MediaSessionCommand.seekBy($offset)';
}

/// The [MediaSessionCommand.setRepeatMode] variant — change the repeat
/// mode to the carried [loop].
final class MediaSessionCommandSetRepeatMode extends MediaSessionCommand {
  /// Repeat mode requested by the OS UI. The package auto-applies it
  /// via [Player.setLoop].
  final Loop loop;

  const MediaSessionCommandSetRepeatMode._(this.loop) : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaSessionCommandSetRepeatMode && other.loop == loop;

  @override
  int get hashCode => Object.hash(MediaSessionCommandSetRepeatMode, loop);

  @override
  String toString() => 'MediaSessionCommand.setRepeatMode($loop)';
}

/// The [MediaSessionCommand.setShuffle] variant — toggle shuffle to the
/// carried [shuffle] state.
final class MediaSessionCommandSetShuffle extends MediaSessionCommand {
  /// New shuffle state requested by the OS UI. The package
  /// auto-applies it via [Player.setShuffle].
  final bool shuffle;

  const MediaSessionCommandSetShuffle._(this.shuffle) : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaSessionCommandSetShuffle && other.shuffle == shuffle;

  @override
  int get hashCode => Object.hash(MediaSessionCommandSetShuffle, shuffle);

  @override
  String toString() => 'MediaSessionCommand.setShuffle($shuffle)';
}

/// The [MediaSessionCommand.setPlaybackRate] variant — change playback
/// speed to the carried [rate].
final class MediaSessionCommandSetPlaybackRate extends MediaSessionCommand {
  /// New playback rate requested by the OS UI (typically one of
  /// [MediaSession.supportedPlaybackRates]). Auto-applied to
  /// [Player.setRate].
  final double rate;

  const MediaSessionCommandSetPlaybackRate._(this.rate) : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaSessionCommandSetPlaybackRate && other.rate == rate;

  @override
  int get hashCode => Object.hash(MediaSessionCommandSetPlaybackRate, rate);

  @override
  String toString() => 'MediaSessionCommand.setPlaybackRate($rate)';
}
