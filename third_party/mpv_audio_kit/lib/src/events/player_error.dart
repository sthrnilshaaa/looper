// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// `mpv_constants.dart` defines its own integer-typed `MpvEndFileReason`
// (the libmpv constants). The enum below shadows that name, so we hide
// the constants symbol to keep the import free of name conflicts.
import '../models/media.dart';
import '../mpv_constants.dart' hide MpvEndFileReason;
import '../types/enums/log_level.dart';

/// Typed error events delivered on [PlayerStream.error]. A sealed union
/// over [EndFileError] (playback failures) and [LogError]
/// (`error` or `fatal` log lines from an mpv subsystem). Pattern-match on
/// the variant to distinguish them.
///
/// ```dart
/// player.stream.error.listen((error) {
///   switch (error) {
///     case EndFileError():
///       print('Playback ended: reason=${error.reason}, code=${error.code}');
///     case LogError():
///       print(error.message);
///   }
/// });
/// ```
///
/// {@category Errors and logs}
sealed class PlayerError {
  const PlayerError();

  /// Human-readable error description.
  ///
  /// For [EndFileError] this is the mpv-supplied error string; for
  /// [LogError] it is `'[prefix] level: text'`.
  String get message;
}

/// Playback of a file ended with an error or unexpected EOF.
///
/// Emitted when mpv fires `MPV_EVENT_END_FILE` with a non-zero error code.
///
/// **Network note:** a network disconnection mid-stream reports as
/// [MpvEndFileReason.eof] rather than [MpvEndFileReason.error], with no
/// error. `Player.stream.endFile` carries the position and duration of the
/// entry that ended, to tell such an end apart ([MpvFileEndedEvent]).
final class EndFileError extends PlayerError {
  /// Why the file ended.
  final MpvEndFileReason reason;

  /// mpv error code (one of [MpvError] constants, e.g.
  /// [MpvError.mpvErrorLoadingFailed]). Only meaningful when [reason]
  /// is [MpvEndFileReason.error]; otherwise `0`.
  final int code;

  /// Human-readable error description, supplied by mpv.
  @override
  final String message;

  /// Creates a playback-failure error from an mpv end-file event.
  const EndFileError({
    required this.reason,
    required this.code,
    required this.message,
  });

  /// Whether this is likely a loading or network failure.
  bool get isLoadingError => code == MpvError.mpvErrorLoadingFailed;

  /// Whether the audio output failed to initialize.
  bool get isAudioOutputError => code == MpvError.mpvErrorAoInitFailed;

  /// Whether the file format is unknown or too broken to open.
  bool get isFormatError =>
      code == MpvError.mpvErrorUnknownFormat ||
      code == MpvError.mpvErrorNothingToPlay;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EndFileError &&
          other.reason == reason &&
          other.code == code &&
          other.message == message);

  @override
  int get hashCode => Object.hash(reason, code, message);

  @override
  String toString() =>
      'EndFileError(reason: $reason, code: $code, message: $message)';
}

/// A log message at `error` or `fatal` level from an mpv subsystem.
///
/// These are informational errors from mpv's internal logging; they don't
/// necessarily mean playback has stopped. For example, a codec warning or
/// a filter configuration issue.
final class LogError extends PlayerError {
  /// The mpv subsystem that produced the message (e.g. `'ffmpeg'`,
  /// `'demux'`, `'ao'`).
  final String prefix;

  /// The log level: either [LogLevel.error] or [LogLevel.fatal].
  final LogLevel level;

  /// Raw log text from the mpv subsystem.
  final String text;

  /// Creates a log-derived error from an `error` or `fatal` mpv log line.
  const LogError({
    required this.prefix,
    required this.level,
    required this.text,
  });

  @override
  String get message => '[$prefix] ${level.mpvValue}: $text';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LogError &&
          other.prefix == prefix &&
          other.level == level &&
          other.text == text);

  @override
  int get hashCode => Object.hash(prefix, level, text);

  @override
  String toString() => 'LogError(prefix: $prefix, level: $level, text: $text)';
}

/// The predicates of [EndFileError], which are members of the class now.
/// The extension stays so that code naming it still compiles.
extension EndFileErrorX on EndFileError {
  /// See [EndFileError.isLoadingError].
  bool get isLoadingError => this.isLoadingError;

  /// See [EndFileError.isAudioOutputError].
  bool get isAudioOutputError => this.isAudioOutputError;

  /// See [EndFileError.isFormatError].
  bool get isFormatError => this.isFormatError;
}

/// Emitted for **every** file-end event, regardless of whether an error occurred.
///
/// This is the typed Dart equivalent of mpv's `MPV_EVENT_END_FILE`, with
/// what the player knew of the entry that ended: its [media], the
/// [position] its output reached and its [duration]. Read them here, not
/// from `Player.state`: when the event arrives the state can already
/// describe the next entry, or a stopped player.
///
/// The last entry of the playlist does not end at its end. The player
/// keeps it open on its last frame: `PlayerState.completed` turns true and
/// `PlayerState.position` holds where it ended. This event comes for it
/// when it is stopped or replaced, with [MpvEndFileReason.stop].
///
/// mpv reports a stream cut short as a normal end
/// ([MpvEndFileReason.eof] with [error] `0`), for example an HTTP
/// connection that dropped. [readError] and [skippedSegments] tell such a
/// cut from the end; [duration] can be an estimate, so comparing it with
/// [position] does not. See [MpvFileEndedEventX.reachedNaturalEnd].
///
/// ```dart
/// player.stream.endFile.listen((event) {
///   if (event.reason == MpvEndFileReason.eof &&
///       (event.readError == true || (event.skippedSegments ?? 0) > 0)) {
///     print('${event.media?.uri} ended early');
///   }
/// });
/// ```
final class MpvFileEndedEvent {
  /// Why the file ended.
  final MpvEndFileReason reason;

  /// mpv error code. Non-zero only when [reason] is [MpvEndFileReason.error].
  final int error;

  /// The [Media] the entry was loaded with. `null` for an entry the player
  /// did not load itself: one of a playlist file
  /// (`Player.openPlaylistFile`) or of a raw command.
  final Media? media;

  /// The position of the entry when it ended: where its output was. `null`
  /// when mpv knew none, as for a file that failed to open.
  ///
  /// With gapless playback (the default) mpv ends an entry once its decoder
  /// is done, while the output still plays what it buffered. The position
  /// then trails the end of the file by about that buffer: the one of
  /// `Player.setAudioBuffer` (0.2 s by default) plus the audio output's
  /// own.
  final Duration? position;

  /// The duration of the entry as mpv knew it when it ended. `null` when
  /// mpv knew none, as for a live stream.
  ///
  /// It can be an estimate: for an MP3 without a Xing or VBRI header, and
  /// for some HLS streams, mpv derives it from the bitrate, and a file that
  /// played to its end can stop seconds away from it.
  final Duration? duration;

  /// Whether the entry stopped reading on an error instead of at its end:
  /// a dropped connection, a server that closed before the length it
  /// announced or refused the resume, a live stream closed without its
  /// last chunk. mpv still ends such an entry with [MpvEndFileReason.eof]
  /// and [error] `0`. `false` when the entry was read to its end, also
  /// when a seek after the error read it on to the end.
  ///
  /// A local file always reads to its end. A response with neither a
  /// length nor chunks, from a server without range support, ends where the
  /// connection closes, and reads as an error even when it was whole.
  ///
  /// Always set for an event of the player; `null` only in an event built
  /// by hand.
  final bool? readError;

  /// How many HLS or DASH segments the entry lost to errors since it
  /// opened, whole (one that did not open) or in part (a read that broke
  /// off). `0` for every other format. The segments a live stream drops
  /// because the player fell behind do not count.
  ///
  /// Always set for an event of the player; `null` only in an event built
  /// by hand.
  final int? skippedSegments;

  /// Creates a file-ended event with the given [reason] and [error] code,
  /// and the [media], [position], [duration], [readError] and
  /// [skippedSegments] of the entry that ended.
  const MpvFileEndedEvent({
    required this.reason,
    required this.error,
    this.media,
    this.position,
    this.duration,
    this.readError,
    this.skippedSegments,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MpvFileEndedEvent &&
          other.reason == reason &&
          other.error == error &&
          other.media == media &&
          other.position == position &&
          other.duration == duration &&
          other.readError == readError &&
          other.skippedSegments == skippedSegments);

  @override
  int get hashCode => Object.hash(
    reason,
    error,
    media,
    position,
    duration,
    readError,
    skippedSegments,
  );

  /// `true` when [reason] is [MpvEndFileReason.eof].
  ///
  /// mpv also reports EOF when a network stream drops, so this means the
  /// demuxer ran out of data, not that the track played to completion.
  /// [readError] and [skippedSegments] tell such ends apart.
  bool get reachedNaturalEnd => reason == MpvEndFileReason.eof;

  @override
  String toString() =>
      'MpvFileEndedEvent(reason: $reason, error: $error, media: $media, '
      'position: $position, duration: $duration, readError: $readError, '
      'skippedSegments: $skippedSegments)';
}

/// [MpvFileEndedEvent.reachedNaturalEnd], which is a member of the class
/// now. The extension stays so that code naming it still compiles.
extension MpvFileEndedEventX on MpvFileEndedEvent {
  /// See [MpvFileEndedEvent.reachedNaturalEnd].
  bool get reachedNaturalEnd => this.reachedNaturalEnd;
}

/// Why a file ended: mirrors `mpv_end_file_reason` from the C API.
///
/// See the [mpv documentation](https://mpv.io/manual/master/) for details.
enum MpvEndFileReason {
  /// Playback ended naturally (reached end of file).
  ///
  /// **Important:** this is also reported when a network connection is
  /// interrupted mid-stream. Do not assume this always means the file
  /// played to completion.
  eof(MpvEndFileReason._eof),

  /// Playback was stopped by an external action (e.g. playlist-next).
  stop(MpvEndFileReason._stop),

  /// The player is quitting.
  quit(MpvEndFileReason._quit),

  /// An error caused playback to abort. The associated [EndFileError.code]
  /// contains the specific mpv error code.
  error(MpvEndFileReason._error),

  /// The file was a playlist or redirect; its entries were appended to the
  /// playlist and this entry was removed.
  redirect(MpvEndFileReason._redirect);

  const MpvEndFileReason(this.value);

  /// The raw integer value matching the C API constant.
  final int value;

  // Private constants matching mpv_end_file_reason values.
  static const _eof = 0;
  static const _stop = 2;
  static const _quit = 3;
  static const _error = 4;
  static const _redirect = 5;

  /// Converts a raw mpv integer reason code to the corresponding enum value.
  /// A code this version does not know gives [error], so an unknown end
  /// never reads as the natural end of the file.
  static MpvEndFileReason fromValue(int value) {
    for (final reason in values) {
      if (reason.value == value) return reason;
    }
    return error;
  }
}
