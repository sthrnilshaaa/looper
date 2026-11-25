// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Every exception a [Player] method throws when libmpv, a source or the
/// OS media session fails or refuses.
/// Switch on it to handle each case:
///
/// ```dart
/// try {
///   await player.seek(position);
/// } on PlayerException catch (e) {
///   switch (e) {
///     case PlayerDisposedException():
///     case PlayerInitException(:final message, :final cause):
///     case MpvCommandException(:final name, :final code):
///     case SourceException(:final uri):
///     case MediaSessionException(:final reason):
///   }
/// }
/// ```
///
/// Invalid arguments are programming errors and throw [ArgumentError] or
/// [RangeError] instead, before anything is written to libmpv (a playlist
/// index is checked against mpv's own playlist count). On the web,
/// [Player.setAudioSampleRate] throws a [StateError] for a rate the browser
/// refuses.
sealed class PlayerException implements Exception {
  const PlayerException();
}

/// The [Player] was disposed before the call, or before it finished
/// starting (a call waiting for the start throws too). A call past that
/// point when [Player.dispose] runs completes without effect instead.
final class PlayerDisposedException extends PlayerException {
  /// Creates the exception thrown by a call on a disposed player.
  const PlayerDisposedException();

  @override
  String toString() => 'PlayerDisposedException: the Player has been disposed';
}

/// The [Player] could not start: libmpv failed to load or initialize, is
/// not of the release this package pins, or the page cannot run it. Every
/// call on that player throws it.
final class PlayerInitException extends PlayerException {
  /// Creates the exception with the reason bring-up failed, and the error
  /// behind it when there is one.
  const PlayerInitException(this.message, {this.cause});

  /// Why bring-up failed, as reported by the loader, the release check or
  /// libmpv.
  final String message;

  /// The error bring-up failed with, when one was caught: on the web, what
  /// the load of the module or the calls into it threw. `null` when
  /// [message] is all there is (a libmpv of another release, an
  /// `mpv_initialize` that returned an error).
  final Object? cause;

  @override
  String toString() => 'PlayerInitException: $message';
}

/// libmpv rejected a command or a property write: an unknown property or
/// command, a value it refuses, or a command with nothing to act on (a
/// seek with no file loaded).
final class MpvCommandException extends PlayerException {
  /// Creates the exception for a request libmpv rejected.
  const MpvCommandException({
    required this.name,
    required this.code,
    required this.message,
  });

  /// The property (`'volume'`) or command (`'seek'`) that was rejected.
  final String name;

  /// The negative mpv error code, see `MpvError` for the known ones.
  final int code;

  /// mpv's description of [code], from `mpv_error_string`.
  final String message;

  @override
  String toString() => 'MpvCommandException($name): $message (code=$code)';
}

/// A media source could not be prepared for playback before reaching
/// libmpv: a missing `asset://`, or an Android `content://` URI the app
/// cannot read. Failures inside libmpv (a 404, an unsupported format)
/// arrive on `stream.error` instead, since playback is asynchronous.
final class SourceException extends PlayerException {
  /// Creates the exception for [uri] with the reason it failed.
  const SourceException(this.uri, this.message);

  /// The URI as passed to the player.
  final String uri;

  /// Why the source could not be prepared.
  final String message;

  @override
  String toString() => 'SourceException($uri): $message';
}

/// Why [Player.setMediaSession] refused to publish a [Player].
enum MediaSessionRefusal {
  /// The [Player] lives in another isolate than the root one, the only
  /// one the OS sends the commands of its media session to.
  notRootIsolate,

  /// Another [Player] of this isolate owns the session: it is one per
  /// process.
  otherPlayer,

  /// Another Flutter engine of this process (add-to-app, a second window)
  /// owns the session.
  otherEngine,
}

/// [Player.setMediaSession] could not publish the [Player] to the OS media
/// session. The state goes back to no session.
final class MediaSessionException extends PlayerException {
  /// Creates the exception for a session refused for [reason].
  const MediaSessionException(this.reason, this.message);

  /// Why the session was refused.
  final MediaSessionRefusal reason;

  /// What to do about it.
  final String message;

  @override
  String toString() => 'MediaSessionException(${reason.name}): $message';
}
