// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/cover_art.dart';
import '../models/media_session.dart';
import '../types/enums/loop.dart';
import '../types/sealed/media_session_command.dart';

/// Effective metadata snapshot pushed to native — already resolved
/// (override > mpv-derived). The controller computes this and hands it
/// to the channel; the channel just serialises and ships.
@internal
class MediaSessionMetadataSnapshot {
  final String? title;
  final String? artist;
  final String? album;

  /// Decoded artwork bytes (embedded cover or a [MediaSessionArtwork.custom]
  /// image). Mutually exclusive with [artworkUri] — at most one is set.
  final CoverArt? artwork;

  /// A remote / file artwork URL the native side resolves itself
  /// ([MediaSessionArtwork.uri], or the consumer-attached `extras['art']`
  /// fallback for a tag-less stream). Mutually exclusive with [artwork].
  final String? artworkUri;
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

  const MediaSessionMetadataSnapshot({
    this.title,
    this.artist,
    this.album,
    this.artwork,
    this.artworkUri,
    this.duration,
    this.trackNumber,
    this.discNumber,
    this.albumArtist,
    this.genre,
    this.url,
  });

  // Value equality so the controller can dedup unchanged snapshots before
  // re-shipping. The byte [artwork] compares by reference identity — the
  // resolver returns a stable [CoverArt] until the cover genuinely changes,
  // so the (multi-MB) bytes are never walked here; [artworkUri] is a small
  // string and compares by value.
  @override
  bool operator ==(Object other) =>
      other is MediaSessionMetadataSnapshot &&
      other.title == title &&
      other.artist == artist &&
      other.album == album &&
      other.duration == duration &&
      identical(other.artwork, artwork) &&
      other.artworkUri == artworkUri &&
      other.trackNumber == trackNumber &&
      other.discNumber == discNumber &&
      other.albumArtist == albumArtist &&
      other.genre == genre &&
      other.url == url;

  @override
  int get hashCode => Object.hash(
        title,
        artist,
        album,
        duration,
        identityHashCode(artwork),
        artworkUri,
        trackNumber,
        discNumber,
        albumArtist,
        genre,
        url,
      );
}

/// Effective playback snapshot pushed to native. The OS extrapolates
/// [position] forward using [rate] from receipt time, so this is pushed
/// on state changes (play/pause/seek), not on every `time-pos` tick.
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

  /// End-of-content reached (mpv's `eof-reached` rising edge, mirrored by
  /// [PlayerState.completed]). The native side maps this to a terminal
  /// state — Android `STATE_ENDED`, Linux MPRIS `PlaybackStatus=Stopped`
  /// with empty `Metadata` — instead of leaving a finished track parked as
  /// "Paused at full length" on the OS surface. Apple has no distinct
  /// "ended" playback state and parks acceptably as paused, so it ignores it.
  final bool completed;

  /// This snapshot originates from a seek landing (PLAYBACK_RESTART), as
  /// opposed to a plain play/pause/rate change. Linux MPRIS uses it to emit
  /// the `Seeked` signal deterministically — even for a sub-second scrub that
  /// a magnitude heuristic would miss, which otherwise leaves the OS slider
  /// snapped back to the pre-seek position.
  final bool seek;

  /// Actual audio output (`core-idle` inverted), distinct from [playing]
  /// (which is the intent the OS button binds to). The native side advances
  /// the scrub bar by extrapolation ONLY while this is true, so the slider
  /// doesn't keep moving during a buffer stall or a seek transient.
  final bool actualPlaying;

  /// Buffering / loading. Mapped to a loading state where the OS supports one
  /// (Android `STATE_BUFFERING`).
  final bool buffering;

  /// Whether next / previous navigation is available right now. For a real
  /// multi-item mpv playlist these reflect the actual bounds (respecting
  /// `loop == playlist` wrap); for a single item they stay `true` so a
  /// consumer driving an external queue still receives the command. The OS
  /// greys the skip buttons out when false (Windows / Linux / Apple).
  final bool hasNext;
  final bool hasPrevious;

  const MediaSessionPlaybackSnapshot({
    required this.playing,
    required this.position,
    required this.rate,
    required this.seekable,
    required this.loop,
    required this.shuffle,
    this.completed = false,
    this.seek = false,
    this.actualPlaying = false,
    this.buffering = false,
    this.hasNext = true,
    this.hasPrevious = true,
  });
}

/// Two platform channels: a method channel (`mpv_audio_kit/media_session`,
/// Dart → native: `enable` / `update*` / `disable`) and an event channel
/// (`.../commands`, native → Dart: the OS remote commands). Method calls
/// swallow [MissingPluginException] / [PlatformException] so an unwired
/// platform is a no-op, not a crash — Dart-side state stays correct.
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
  Future<void> enable({
    required MediaSession session,
    required MediaSessionMetadataSnapshot metadata,
    required MediaSessionPlaybackSnapshot playback,
  }) async {
    await _invoke('enable', <String, Object?>{
      'config': _encodeConfig(session),
      'metadata': _encodeMetadata(metadata),
      'playback': _encodePlayback(playback),
    });
  }

  /// Push a new configuration to the native side — actions, artwork
  /// source, audio-interruption flags. Called when the consumer
  /// reconfigures via `setMediaSession(newSession)` while the session
  /// is already enabled.
  Future<void> updateConfig(MediaSession session) =>
      _invoke('updateConfig', _encodeConfig(session));

  /// Push a fresh metadata snapshot to the native side — title /
  /// artist / album / artwork / duration. Called on metadata or
  /// cover-art changes.
  Future<void> updateMetadata(MediaSessionMetadataSnapshot metadata) =>
      _invoke('updateMetadata', _encodeMetadata(metadata));

  /// Push a fresh playback state to the native side — playing /
  /// position / rate. Called on play/pause transitions, seek
  /// completion, rate changes. NOT on every `time-pos` tick: the OS
  /// extrapolates from the last update's `(position, rate, timestamp)`.
  Future<void> updatePlayback(MediaSessionPlaybackSnapshot playback) =>
      _invoke('updatePlayback', _encodePlayback(playback));

  /// Tear down the OS media session entirely. Called on
  /// `setMediaSession(null)` and on `Player.dispose()`.
  Future<void> disable() => _invoke('disable', null);

  Future<void> _invoke(String method, Object? args) async {
    try {
      await _method.invokeMethod<void>(method, args);
    } on MissingPluginException {
      // Native side not yet wired on this platform — Dart-side state
      // is still consistent, only the OS lockscreen entry is absent.
    } on PlatformException {
      // Native side reported a failure — swallow so a misbehaving
      // platform implementation can't take down the Dart isolate. The
      // next state-change push re-syncs: pushes are event-driven, so a
      // dropped one self-heals on the following change.
    }
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
      'supportedPlaybackRates': s.supportedPlaybackRates,
    };
    // `appName` is consumed by Windows SMTC (the process AUMID) and Linux MPRIS
    // (Identity / bus name); macOS / iOS / Android use the system app identity.
    // The app icon bytes are NOT read by any native side (Windows derives the
    // SMTC icon from the AUMID; MPRIS has no per-player icon beyond
    // DesktopEntry), so they are never shipped across the channel.
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      config['appName'] = s.appName;
    }
    // `desktopEntry` resolves the MPRIS app icon — Linux only.
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
        // A URL the native side fetches itself (mutually exclusive with the
        // bytes above) — keeps the (multi-MB) blob off the channel for
        // remote covers. `null` when artwork is embedded/custom/none.
        'artworkUri': m.artworkUri,
        'durationMs': m.duration?.inMilliseconds,
        'trackNumber': m.trackNumber,
        'discNumber': m.discNumber,
        'albumArtist': m.albumArtist,
        'genre': m.genre,
        'url': m.url,
      };

  Map<String, Object?> _encodePlayback(MediaSessionPlaybackSnapshot p) =>
      <String, Object?>{
        'playing': p.playing,
        'positionMs': p.position.inMilliseconds,
        'rate': p.rate,
        'seekable': p.seekable,
        // Wire-level strings keep the protocol stable even if the
        // Dart enum gains variants — native side maps to its own
        // platform enum (MPRepeatType / MediaSession REPEAT_MODE_*).
        'loop': p.loop.name,
        'shuffle': p.shuffle,
        'completed': p.completed,
        'seek': p.seek,
        'actualPlaying': p.actualPlaying,
        'buffering': p.buffering,
        'hasNext': p.hasNext,
        'hasPrevious': p.hasPrevious,
      };

  /// Decodes one incoming event from the native event channel into a
  /// [MediaSessionCommand]. Returns `null` for malformed or unknown
  /// command types — those are filtered out before reaching consumer
  /// subscribers.
  MediaSessionCommand? _decodeCommand(dynamic raw) {
    if (raw is! Map) return null;
    final type = raw['type'];
    if (type is! String) return null;
    switch (type) {
      case 'play':
        return MediaSessionCommand.play;
      case 'pause':
        return MediaSessionCommand.pause;
      case 'playPause':
        return MediaSessionCommand.playPause;
      case 'stop':
        return MediaSessionCommand.stop;
      case 'next':
        return MediaSessionCommand.next;
      case 'previous':
        return MediaSessionCommand.previous;
      case 'like':
        return MediaSessionCommand.like;
      case 'seekTo':
        final pos = raw['positionMs'];
        if (pos is! int) return null;
        return MediaSessionCommand.seekTo(Duration(milliseconds: pos));
      case 'seekBy':
        final off = raw['offsetMs'];
        if (off is! int) return null;
        return MediaSessionCommand.seekBy(Duration(milliseconds: off));
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
}

