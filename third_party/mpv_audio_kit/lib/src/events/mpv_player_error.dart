// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// `mpv_bindings.dart` defines its own integer-typed `MpvEndFileReason`
// (auto-generated FFI). The enum below shadows that name, so we hide
// the bindings symbol to keep the import free of name conflicts.
import '../mpv_bindings.dart' hide MpvEndFileReason;
import '../types/enums/log_level.dart';

/// Typed error events delivered on [PlayerStream.error]. A sealed union
/// over [MpvEndFileError] (playback failures) and [MpvLogError]
/// (`error` / `fatal` log lines from an mpv subsystem). Pattern-match on
/// the variant to distinguish them.
///
/// ```dart
/// player.stream.error.listen((error) {
///   switch (error) {
///     case MpvEndFileError():
///       print('Playback ended: reason=${error.reason}, code=${error.code}');
///     case MpvLogError():
///       print(error.message);
///   }
/// });
/// ```
sealed class MpvPlayerError {
  const MpvPlayerError();

  /// Human-readable error description.
  ///
  /// For [MpvEndFileError] this is the mpv-supplied error string; for
  /// [MpvLogError] it is `'[prefix] level: text'`.
  String get message;
}

/// Playback of a file ended with an error or unexpected EOF.
///
/// Emitted when mpv fires `MPV_EVENT_END_FILE` with a non-zero error code.
///
/// **Network note:** according to the mpv documentation, a network
/// disconnection mid-stream may report as [MpvEndFileReason.eof] rather
/// than [MpvEndFileReason.error]. Use `Player.stream.endFile` and compare
/// the player's position against duration to detect premature endings.
final class MpvEndFileError extends MpvPlayerError {
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
  const MpvEndFileError({
    required this.reason,
    required this.code,
    required this.message,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MpvEndFileError &&
          other.reason == reason &&
          other.code == code &&
          other.message == message);

  @override
  int get hashCode => Object.hash(reason, code, message);

  @override
  String toString() =>
      'MpvEndFileError(reason: $reason, code: $code, message: $message)';
}

/// A log message at `error` or `fatal` level from an mpv subsystem.
///
/// These are informational errors from mpv's internal logging — they don't
/// necessarily mean playback has stopped. For example, a codec warning or
/// a filter configuration issue.
final class MpvLogError extends MpvPlayerError {
  /// The mpv subsystem that produced the message (e.g. `'ffmpeg'`,
  /// `'demux'`, `'ao'`).
  final String prefix;

  /// The log level — either [LogLevel.error] or [LogLevel.fatal].
  final LogLevel level;

  /// Raw log text from the mpv subsystem.
  final String text;

  /// Creates a log-derived error from an `error` or `fatal` mpv log line.
  const MpvLogError({
    required this.prefix,
    required this.level,
    required this.text,
  });

  @override
  String get message => '[$prefix] ${level.mpvValue}: $text';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MpvLogError &&
          other.prefix == prefix &&
          other.level == level &&
          other.text == text);

  @override
  int get hashCode => Object.hash(prefix, level, text);

  @override
  String toString() =>
      'MpvLogError(prefix: $prefix, level: $level, text: $text)';
}

/// Convenience predicates for [MpvEndFileError].
extension MpvEndFileErrorX on MpvEndFileError {
  /// Whether this is likely a loading/network failure.
  bool get isLoadingError => code == MpvError.mpvErrorLoadingFailed;

  /// Whether the audio output failed to initialize.
  bool get isAudioOutputError => code == MpvError.mpvErrorAoInitFailed;

  /// Whether the file format is unknown or too broken to open.
  bool get isFormatError =>
      code == MpvError.mpvErrorUnknownFormat ||
      code == MpvError.mpvErrorNothingToPlay;
}

/// Emitted for **every** file-end event, regardless of whether an error occurred.
///
/// This is the typed Dart equivalent of mpv's `MPV_EVENT_END_FILE`.
/// Subscribe via `Player.stream.endFile` to detect both clean completions
/// and premature endings (e.g. a network stream that reports EOF
/// mid-playback without setting an error code).
///
/// ```dart
/// player.stream.endFile.listen((event) {
///   if (event.reason == MpvEndFileReason.eof) {
///     // Compare player.state.position vs player.state.duration
///     // to decide if this was a genuine completion or a network drop.
///   }
/// });
/// ```
final class MpvFileEndedEvent {
  /// Why the file ended.
  final MpvEndFileReason reason;

  /// mpv error code. Non-zero only when [reason] is [MpvEndFileReason.error].
  final int error;

  /// Creates a file-ended event with the given [reason] and [error] code.
  const MpvFileEndedEvent({required this.reason, required this.error});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MpvFileEndedEvent &&
          other.reason == reason &&
          other.error == error);

  @override
  int get hashCode => Object.hash(reason, error);

  @override
  String toString() => 'MpvFileEndedEvent(reason: $reason, error: $error)';
}

/// Whether the file ended naturally and not because of a stop, error, redirect,
/// or shutdown.
extension MpvFileEndedEventX on MpvFileEndedEvent {
  /// `true` when [reason] is [MpvEndFileReason.eof] — note that mpv also
  /// reports EOF on mid-stream network disconnects, so this is "natural end
  /// from mpv's POV", not "track played to completion".
  bool get reachedNaturalEnd => reason == MpvEndFileReason.eof;
}

/// Why a file ended — mirrors `mpv_end_file_reason` from the C API.
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

  /// An error caused playback to abort. The associated [MpvEndFileError.code]
  /// contains the specific mpv error code.
  error(MpvEndFileReason._error),

  /// The file was a playlist or redirect — its entries were appended to the
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
  static MpvEndFileReason fromValue(int value) => switch (value) {
        _eof => eof,
        _stop => stop,
        _quit => quit,
        _error => error,
        _redirect => redirect,
        _ => eof,
      };
}
