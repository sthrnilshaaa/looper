// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../events/player_exception.dart';
import '../models/cover_art.dart';
import '../models/media_session.dart';
import '../types/enums/loop.dart';
import '../types/sealed/media_session_command.dart';

/// Effective metadata snapshot pushed to native, already resolved
/// (override > mpv-derived). The controller computes this and hands it
/// to the channel; the channel just serialises and ships.
@internal
class MediaSessionMetadataSnapshot {
  final String? title;
  final String? artist;
  final String? album;

  /// The artwork as image bytes: the embedded cover, a
  /// [MediaSessionArtwork.custom] image, or the image of an artwork URL
  /// ([MediaSessionArtwork.uri] or `extras['art']`) the package loaded. No
  /// URL ever reaches the native side.
  final CoverArt? artwork;
  final Duration? duration;

  /// Rich tags, mpv-derived (no per-field override). Surfaced where the OS
  /// supports them: Apple `MPMediaItemProperty*`, Android `MediaMetadata`,
  /// Linux MPRIS `xesam:*`.
  final int? trackNumber;
  final int? discNumber;
  final String? albumArtist;
  final String? genre;

  /// Source URI of the current item (MPRIS `xesam:url`).
  final String? url;

  /// On the web only: an artwork URL the package could not load (no CORS
  /// on the server), which the browser loads as an image itself. `null`
  /// on the other platforms, where no URL ever reaches the native side.
  final String? artworkUrl;

  const MediaSessionMetadataSnapshot({
    this.title,
    this.artist,
    this.album,
    this.artwork,
    this.duration,
    this.trackNumber,
    this.discNumber,
    this.albumArtist,
    this.genre,
    this.url,
    this.artworkUrl,
  });

  // Value equality so the controller can dedup unchanged snapshots before
  // re-shipping. The byte [artwork] compares by reference identity: the
  // resolver returns a stable [CoverArt] until the cover genuinely changes,
  // so the (multi-MB) bytes are never walked here.
  @override
  bool operator ==(Object other) =>
      other is MediaSessionMetadataSnapshot &&
      other.title == title &&
      other.artist == artist &&
      other.album == album &&
      other.duration == duration &&
      identical(other.artwork, artwork) &&
      other.trackNumber == trackNumber &&
      other.discNumber == discNumber &&
      other.albumArtist == albumArtist &&
      other.genre == genre &&
      other.url == url &&
      other.artworkUrl == artworkUrl;

  @override
  int get hashCode => Object.hash(
    title,
    artist,
    album,
    duration,
    identityHashCode(artwork),
    trackNumber,
    discNumber,
    albumArtist,
    genre,
    url,
    artworkUrl,
  );
}

/// Effective playback snapshot pushed to native. The OS extrapolates
/// [position] forward using [rate] from receipt time, so this is pushed
/// on state changes (play, pause, seek), not on every `time-pos` tick.
/// [seekable] mirrors mpv's `seekable`: the native side gates the OS
/// scrubber on it and treats a non-seekable source as a live stream.
@internal
class MediaSessionPlaybackSnapshot {
  final bool playing;
  final Duration position;
  final double rate;
  final bool seekable;
  final Loop loop;
  final bool shuffle;

  /// End-of-content reached ([PlaybackState.completed]: `eof-reached` on the
  /// last playlist entry with no loop on). Three native sides map it to a
  /// terminal state instead of leaving a finished track parked as "Paused
  /// at full length" on the OS surface:
  ///
  /// | Platform | What it does with `completed` |
  /// | :--- | :--- |
  /// | Android | `STATE_ENDED` |
  /// | Linux | MPRIS `PlaybackStatus=Stopped` with empty `Metadata` |
  /// | OHOS | AVSession `PLAYBACK_STATE_COMPLETED` |
  /// | Apple | not read: no "ended" state, the entry parks as paused |
  /// | Windows | not read: the SMTC entry stays `Paused` |
  /// | Web | not read: `playbackState` stays `paused` |
  final bool completed;

  /// The player stopped ([Player.stop]) and nothing loaded or played since.
  ///
  /// | Platform | What it does with `stopped` |
  /// | :--- | :--- |
  /// | Linux | MPRIS `PlaybackStatus=Stopped` with empty `Metadata` |
  /// | OHOS | AVSession `PLAYBACK_STATE_STOP` |
  /// | Android, Apple, Windows, Web | not read |
  final bool stopped;

  /// The playlist has entries: stopped or at the end, Play has something
  /// to start.
  ///
  /// | Platform | What it does with `queued` |
  /// | :--- | :--- |
  /// | Linux | MPRIS `CanPlay` while stopped or at the end, with no title |
  /// | Android, Apple, Windows, Web, OHOS | not read |
  final bool queued;

  /// This snapshot originates from a seek landing (PLAYBACK_RESTART), as
  /// opposed to a plain play, pause or rate change. Linux MPRIS uses it to emit
  /// the `Seeked` signal deterministically, even for a sub-second scrub that
  /// a magnitude heuristic would miss, which otherwise leaves the OS slider
  /// snapped back to the pre-seek position.
  final bool seek;

  /// Actual audio output (`core-idle` inverted), distinct from [playing]
  /// (which is the intent the OS button binds to). Where a native side
  /// reads it, the scrub bar advances by extrapolation only while this is
  /// true, so the slider doesn't keep moving during a buffer stall or a
  /// seek transient. Where none does, the position the OS shows follows
  /// [playing] and [rate] alone: on Apple and the web the slider keeps
  /// moving through a stall, until the next push (a seek landing, a pause)
  /// sets it right.
  ///
  /// | Platform | What it does with `actualPlaying` |
  /// | :--- | :--- |
  /// | Android | the position advances only while it is true |
  /// | Linux | the MPRIS `Position` advances only while it is true |
  /// | Apple | not read: the published rate follows [playing] |
  /// | Windows | not read: the SMTC timeline carries the pushed position |
  /// | Web | not read: `setPositionState` follows [playing] and [rate] |
  /// | OHOS | not read: the AVSession position follows [rate] |
  final bool actualPlaying;

  /// Buffering or loading. Mapped to a loading state where the OS has one
  /// and the native side reads it:
  ///
  /// | Platform | What it does with `buffering` |
  /// | :--- | :--- |
  /// | Android | `STATE_BUFFERING` |
  /// | Windows | SMTC `PlaybackStatus` `Changing` |
  /// | OHOS | AVSession `PLAYBACK_STATE_BUFFERING` |
  /// | Apple | not read |
  /// | Linux | not read: MPRIS has no such status |
  /// | Web | not read |
  final bool buffering;

  /// Whether next or previous navigation is available right now. For a real
  /// multi-item mpv playlist these reflect the actual bounds (respecting
  /// `loop == playlist` wrap); for a single item they stay `true` so a
  /// consumer driving an external queue still receives the command. The OS
  /// greys the skip buttons out when false (Windows, Linux and Apple).
  final bool hasNext;
  final bool hasPrevious;

  /// The pauses and stops the app made since the session was enabled, not
  /// those of the session's own commands. Android disarms the resume of a
  /// call when it changes: during the call the player is already paused,
  /// so a pause of the app changes nothing else.
  final int appPauses;

  const MediaSessionPlaybackSnapshot({
    required this.playing,
    required this.position,
    required this.rate,
    required this.seekable,
    required this.loop,
    required this.shuffle,
    this.completed = false,
    this.stopped = false,
    this.queued = false,
    this.seek = false,
    this.actualPlaying = false,
    this.buffering = false,
    this.hasNext = true,
    this.hasPrevious = true,
    this.appPauses = 0,
  });
}

/// Two platform channels: a method channel (`mpv_audio_kit/media_session`, Dart
/// → native: `enable`, `update*` and `disable`) and an event channel
/// (`.../commands`, native → Dart: the OS remote commands). Method calls
/// swallow [MissingPluginException] and [PlatformException] so an unwired
/// platform is a no-op, not a crash; Dart-side state stays correct. The one
/// exception is an `enable` refused because another Flutter engine of the
/// process owns the session: it throws a [MediaSessionException]. Only `enable`
/// does: an update or a `disable` is sent without anyone awaiting it.
///
/// The event channel has no such net: Flutter reports a listen on a
/// channel without a native side as a [FlutterError]. So [enable] says
/// whether a native side answered, and the controller listens to
/// [commandStream] only when one did (Tizen and webOS have none; OHOS has
/// the AVSession of ohos/, under Flutter-OH).
@internal
class MediaSessionChannel {
  static const String _methodName = 'mpv_audio_kit/media_session';
  static const String _eventName = 'mpv_audio_kit/media_session/commands';

  static const MethodChannel _method = MethodChannel(_methodName);
  static const EventChannel _events = EventChannel(_eventName);

  // One subscription to the event channel, shared by every derived stream:
  // the native side has a single sink, and a second receiveBroadcastStream
  // would take it over.
  late final Stream<dynamic> _raw = _events.receiveBroadcastStream();

  /// Broadcast stream of remote commands issued by the OS media
  /// session. Lazily wires the underlying [EventChannel] on the first
  /// listener.
  late final Stream<MediaSessionCommand> commandStream = _raw
      .map<MediaSessionCommand?>(_decodeCommand)
      .where((c) => c != null)
      .cast<MediaSessionCommand>();

  /// Fires when the OS brought the audio session back but the player's
  /// audio output did not come with it (iOS: after an interruption under
  /// the `keepPlaying` interruption policy, and after a media services
  /// reset).
  /// The player reopens its output in response.
  late final Stream<void> audioOutputResets = _raw
      .where((raw) => raw is Map && raw['type'] == _reloadAudioOutput)
      .map<void>((_) {});

  static const String _reloadAudioOutput = 'reloadAudioOutput';

  /// Enable the OS media session with the full state up front. Called
  /// once on `setMediaSession(non-null)` to bootstrap the native side.
  ///
  /// Completes with whether the platform has a native side at all: `false`
  /// where no plugin answers the channel (Tizen, webOS), `true` anywhere
  /// else, a native side that reported a failure included.
  Future<bool> enable({
    required MediaSession session,
    required MediaSessionMetadataSnapshot metadata,
    required MediaSessionPlaybackSnapshot playback,
  }) => _invoke('enable', <String, Object?>{
    'config': _encodeConfig(session),
    'metadata': _encodeMetadata(metadata),
    'playback': _encodePlayback(playback),
  }, throwsAlreadyOwned: true);

  /// Push a new configuration to the native side: actions, artwork
  /// source, audio-interruption flags. Called when the consumer
  /// reconfigures via `setMediaSession(newSession)` while the session
  /// is already enabled.
  Future<void> updateConfig(MediaSession session) =>
      _invoke('updateConfig', _encodeConfig(session));

  /// Push a fresh metadata snapshot to the native side: title,
  /// artist, album, artwork and duration. Called on metadata or
  /// cover-art changes.
  Future<void> updateMetadata(MediaSessionMetadataSnapshot metadata) =>
      _invoke('updateMetadata', _encodeMetadata(metadata));

  /// Push a fresh playback state to the native side: playing,
  /// position and rate. Called on play-pause transitions, seek
  /// completion, rate changes. NOT on every `time-pos` tick: the OS
  /// extrapolates from the last update's `(position, rate, timestamp)`.
  Future<void> updatePlayback(MediaSessionPlaybackSnapshot playback) =>
      _invoke('updatePlayback', _encodePlayback(playback));

  /// Tear down the OS media session entirely. Called on
  /// `setMediaSession(null)` and on `Player.dispose()`.
  Future<void> disable() => _invoke('disable', null);

  /// The error code of an `enable` the native side refuses: the session
  /// is one per process, and the first engine to enable keeps it until it
  /// disables or detaches.
  static const String _alreadyOwned = 'already_owned';

  /// Whether a native side answered [method], with a result or an error.
  Future<bool> _invoke(
    String method,
    Object? args, {
    bool throwsAlreadyOwned = false,
  }) async {
    try {
      await _method.invokeMethod<void>(method, args);
    } on MissingPluginException {
      // Native side not yet wired on this platform; Dart-side state
      // is still consistent, only the OS lockscreen entry is absent.
      return false;
    } on PlatformException catch (e) {
      if (throwsAlreadyOwned && e.code == _alreadyOwned) {
        throw const MediaSessionException(
          MediaSessionRefusal.otherEngine,
          'Another Flutter engine of this process owns the OS media '
          'session. It is one per process: it stays with the engine that '
          'enabled it until that engine sets it to null, disposes its '
          'Player or is destroyed.',
        );
      }
      // Native side reported a failure: swallow so a misbehaving
      // platform implementation can't take down the Dart isolate. The
      // next state-change push re-syncs: pushes are event-driven, so a
      // dropped one self-heals on the following change.
    }
    return true;
  }

  /// Serialises [MediaSession] config fields (everything that is
  /// *not* a metadata override) to a codec-friendly Map.
  Map<String, Object?> _encodeConfig(MediaSession s) {
    final config = <String, Object?>{
      'actions': [for (final a in s.actions) a.name],
      'isFavorite': s.isFavorite,
      'interruptionPolicy': s.interruptionPolicy.name,
      'fastForwardIntervalMs': s.fastForwardInterval.inMilliseconds,
      'rewindIntervalMs': s.rewindInterval.inMilliseconds,
      // A plain list: the codec writes a Float64List as typed data, which
      // the native sides do not read as a list of doubles.
      'supportedPlaybackRates': List<double>.of(s.supportedPlaybackRates),
    };
    // `appName` is consumed by Windows SMTC (the process AUMID) and Linux MPRIS
    // (Identity and bus name); macOS, iOS and Android use the system app
    // identity.
    // The app icon bytes are NOT read by any native side (Windows derives the
    // SMTC icon from the AUMID; MPRIS has no per-player icon beyond
    // DesktopEntry), so they are never shipped across the channel.
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      config['appName'] = s.appName;
    }
    // `desktopEntry` resolves the MPRIS app icon (Linux only).
    if (defaultTargetPlatform == TargetPlatform.linux) {
      config['desktopEntry'] = s.desktopEntry;
    }
    return config;
  }

  Map<String, Object?> _encodeMetadata(MediaSessionMetadataSnapshot m) =>
      <String, Object?>{
        'title': m.title,
        'artist': m.artist,
        'album': m.album,
        'artworkBytes': m.artwork?.bytes,
        'artworkMime': m.artwork?.mimeType,
        'durationMs': m.duration?.inMilliseconds,
        'trackNumber': m.trackNumber,
        'discNumber': m.discNumber,
        'albumArtist': m.albumArtist,
        'genre': m.genre,
        'url': m.url,
        if (m.artworkUrl != null) 'artworkUrl': m.artworkUrl,
      };

  // The keys of the three maps are the contract with every native side,
  // which reads them by name: channel_encode_test pins the set. Not every
  // side reads every key (see [MediaSessionPlaybackSnapshot]).
  Map<String, Object?> _encodePlayback(MediaSessionPlaybackSnapshot p) =>
      <String, Object?>{
        'playing': p.playing,
        'positionMs': p.position.inMilliseconds,
        'rate': p.rate,
        'seekable': p.seekable,
        // Wire-level strings keep the protocol stable even if the
        // Dart enum gains variants; native side maps to its own
        // platform enum (MPRepeatType or MediaSession REPEAT_MODE_*).
        'loop': p.loop.name,
        'shuffle': p.shuffle,
        'completed': p.completed,
        'stopped': p.stopped,
        'queued': p.queued,
        'seek': p.seek,
        'actualPlaying': p.actualPlaying,
        'buffering': p.buffering,
        'hasNext': p.hasNext,
        'hasPrevious': p.hasPrevious,
        'appPauses': p.appPauses,
      };

  /// Decodes one incoming event from the native event channel into a
  /// [MediaSessionCommand]. Returns `null` for malformed or unknown
  /// command types; those are filtered out before reaching consumer
  /// subscribers.
  MediaSessionCommand? _decodeCommand(dynamic raw) {
    if (raw is! Map) return null;
    final type = raw['type'];
    if (type is! String) return null;
    return _plainCommands[type] ?? _decodeArgCommand(type, raw);
  }

  /// The commands that carry no argument, by their `type`.
  static const _plainCommands = <String, MediaSessionCommand>{
    'play': MediaSessionCommand.play,
    'pause': MediaSessionCommand.pause,
    'playPause': MediaSessionCommand.playPause,
    'stop': MediaSessionCommand.stop,
    'next': MediaSessionCommand.next,
    'previous': MediaSessionCommand.previous,
    'like': MediaSessionCommand.like,
  };

  /// The commands of [_decodeCommand] that carry an argument in [raw]:
  /// `null` for an unknown [type] or an argument of the wrong type.
  static MediaSessionCommand? _decodeArgCommand(
    String type,
    Map<dynamic, dynamic> raw,
  ) {
    switch (type) {
      case 'seekTo':
        return _millis(raw['positionMs'], MediaSessionCommand.seekTo);
      case 'seekBy':
        return _millis(raw['offsetMs'], MediaSessionCommand.seekBy);
      case 'setRepeatMode':
        final name = raw['loop'];
        if (name is! String) return null;
        final loop = Loop.values.firstWhere(
          (l) => l.name == name,
          orElse: () => Loop.off,
        );
        return MediaSessionCommand.setRepeatMode(loop);
      case 'setShuffle':
        final s = raw['shuffle'];
        if (s is! bool) return null;
        return MediaSessionCommand.setShuffle(s);
      case 'setPlaybackRate':
        final r = raw['rate'];
        if (r is num) return MediaSessionCommand.setPlaybackRate(r.toDouble());
        return null;
    }
    return null;
  }

  /// [make] of [ms] milliseconds, `null` when [ms] is no int.
  static MediaSessionCommand? _millis(
    Object? ms,
    MediaSessionCommand Function(Duration) make,
  ) => ms is int ? make(Duration(milliseconds: ms)) : null;
}
