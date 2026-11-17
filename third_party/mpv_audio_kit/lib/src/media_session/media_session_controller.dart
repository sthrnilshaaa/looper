// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/cover_art.dart';
import '../models/media_session.dart';
import '../player/player_state.dart';
import '../types/enums/loop.dart';
import '../types/sealed/media_session_artwork.dart';
import '../types/sealed/media_session_command.dart';
import 'artwork_fetcher.dart';
import 'media_session_channel.dart';
import 'media_session_inputs.dart';

/// Orchestrates the bridge between the [Player]'s reactive state and
/// the OS media session.
///
/// Subscribes to a focused subset of [PlayerStream]:
///
/// - `playWhenReady` / `rate` / `seekCompleted` / `seekable` / `loop` /
///   `shuffle` → push a fresh playback snapshot (the OS extrapolates
///   position forward from this, so we never push raw `time-pos`
///   ticks). The OS play/pause state is driven by `playWhenReady` (user
///   intent), which is stable across seeks — so the button never
///   flickers while scrubbing. The `seekCompleted` push re-syncs the
///   landed position to the OS slider.
/// - `duration` / `metadata` / `coverArt` / `mediaTitle` → push a
///   fresh metadata snapshot.
/// - `mediaSession` (the config field itself) → push a config update
///   when the consumer reconfigures while enabled.
///
/// Computes effective metadata (override > mpv-derived) using the
/// current [PlayerState] snapshot at push time, so streams are only
/// signal sources — never source of truth.
///
/// Incoming commands from the OS event channel are routed through
/// [onCommand]. The owner ([_MediaSessionModule]) is responsible for
/// applying them to the [Player] and forwarding to consumer
/// subscribers — this class is transport-only.
///
/// Lifecycle: instantiated on first `setMediaSession(non-null)`,
/// disposed on `setMediaSession(null)` or `Player.dispose()`.
@internal
class MediaSessionController {
  final PlayerState Function() _stateSnapshot;
  final MediaSessionInputs _inputs;
  final void Function(MediaSessionCommand) _onCommand;
  final void Function()? _onAudioOutputReset;
  final MediaSessionChannel _channel;

  /// Downloads remote artwork so only a local file reaches the OS (Linux,
  /// see [downloadArtwork]); `null` passes artwork URLs through to native.
  final ArtworkFetcher? _artworkFetcher;

  final List<StreamSubscription<dynamic>> _subscriptions = [];
  StreamSubscription<MediaSessionCommand>? _commandSub;
  StreamSubscription<void>? _audioOutputResetSub;
  bool _disposed = false;

  // ── Coalescing ──────────────────────────────────────────────────────
  // One mpv file-load fans out across up to 4 metadata streams + several
  // playback streams in the same microtask turn. Collapse them into at most
  // one updateMetadata + one updatePlayback per turn so the (multi-MB) cover
  // art crosses the channel once, not 4×. A dirty-flag + microtask flush.
  bool _metadataDirty = false;
  bool _playbackDirty = false;
  bool _playbackSeek = false;
  bool _flushScheduled = false;
  MediaSessionMetadataSnapshot? _lastMetadata;

  // ── Remote artwork download (only with an [_artworkFetcher]) ────────
  // The last downloaded URL and its result (`null` on failure), plus the
  // URL whose download is in flight. One cover at a time: a track change
  // simply supersedes the pending one.
  String? _fetchedArtUri;
  CoverArt? _fetchedArt;
  String? _pendingArtUri;
  // Runs after a failed download and fetches the same URL again, so a
  // server that was briefly down still gets a cover on this track. At most
  // [_artworkAttempts] downloads per URL: a URL that keeps failing (a 404)
  // is not fetched, credentials and all, forever.
  Timer? _artRetry;
  final Duration _artworkRetryAfter;
  static const _artworkAttempts = 3;
  String? _artAttemptsUri;
  int _artAttempts = 0;

  MediaSessionController._({
    required PlayerState Function() stateSnapshot,
    required MediaSessionInputs inputs,
    required void Function(MediaSessionCommand) onCommand,
    void Function()? onAudioOutputReset,
    MediaSessionChannel? channel,
    ArtworkFetcher? artworkFetcher,
    Duration artworkRetryAfter = const Duration(seconds: 30),
  })  : _artworkRetryAfter = artworkRetryAfter,
        _stateSnapshot = stateSnapshot,
        _inputs = inputs,
        _onCommand = onCommand,
        _onAudioOutputReset = onAudioOutputReset,
        _channel = channel ?? MediaSessionChannel(),
        _artworkFetcher = artworkFetcher;

  /// Wires the controller up and pushes the initial full state to the
  /// native side. Returns once the initial `enable` call has been
  /// dispatched (native ACK is fire-and-forget — see
  /// [MediaSessionChannel] for the rationale).
  ///
  /// [inputs] declares the exact slice of Player state the controller
  /// consumes. Production builds it via
  /// `MediaSessionInputs.fromPlayer(...)`; tests can build a
  /// [MediaSessionInputs] from raw [StreamController]s and drive
  /// arbitrary event sequences.
  ///
  /// [artworkFetcher] defaults to [downloadArtwork] where the OS would
  /// otherwise publish the artwork URL (see [downloadsArtworkOn]), and to
  /// none on Apple, where the native side fetches it privately.
  static Future<MediaSessionController> create({
    required PlayerState Function() stateSnapshot,
    required MediaSessionInputs inputs,
    required void Function(MediaSessionCommand) onCommand,
    void Function()? onAudioOutputReset,
    @visibleForTesting MediaSessionChannel? channel,
    @visibleForTesting ArtworkFetcher? artworkFetcher,
    @visibleForTesting Duration artworkRetryAfter = const Duration(seconds: 30),
  }) async {
    final c = MediaSessionController._(
      stateSnapshot: stateSnapshot,
      inputs: inputs,
      onCommand: onCommand,
      onAudioOutputReset: onAudioOutputReset,
      channel: channel,
      artworkFetcher: artworkFetcher ??
          (downloadsArtworkOn(defaultTargetPlatform) ? downloadArtwork : null),
      artworkRetryAfter: artworkRetryAfter,
    );
    await c._wireUp();
    return c;
  }

  Future<void> _wireUp() async {
    // Playback-state signals — drive `updatePlayback`. The OS button
    // tracks `playWhenReady` (user intent), which is flicker-free across
    // seeks. The `seekCompleted` push re-syncs the landed position on
    // EVERY restart (seek + file-load) so the OS slider tracks mpv (e.g.
    // snaps to ~0 on playlist auto-advance).
    _subscriptions.add(_inputs.playWhenReady.listen((_) => _markPlayback()));
    // Actual-output + buffering changes drive position-extrapolation gating and
    // the loading indication. They do NOT touch the OS play/pause button (bound
    // to playWhenReady), so they can't flicker it; same-turn pushes coalesce.
    _subscriptions.add(_inputs.playing.listen((_) => _markPlayback()));
    _subscriptions.add(_inputs.buffering.listen((_) => _markPlayback()));
    _subscriptions.add(_inputs.rate.listen((_) => _markPlayback()));
    // A seek landing (PLAYBACK_RESTART) carries seek=true so the native side
    // (Linux MPRIS) can emit `Seeked` deterministically.
    _subscriptions
        .add(_inputs.seekCompleted.listen((_) => _markPlayback(seek: true)));
    // Seekable governs both the OS scrubber (enabled/disabled) and
    // the "live stream" UI mode — re-push when it flips.
    _subscriptions.add(_inputs.seekable.listen((_) => _markPlayback()));
    // Loop + shuffle drive the OS repeat / shuffle button visual state
    // (Apple's `currentRepeatType` / `currentShuffleType`,
    // MPRIS `LoopStatus` / `Shuffle`, MediaSession actions).
    _subscriptions.add(_inputs.loop.listen((_) => _markPlayback()));
    _subscriptions.add(_inputs.shuffle.listen((_) => _markPlayback()));

    // Metadata signals — drive `updateMetadata`.
    _subscriptions.add(_inputs.duration.listen((_) => _markMetadata()));
    _subscriptions.add(_inputs.metadata.listen((_) => _markMetadata()));
    _subscriptions.add(_inputs.coverArt.listen((_) => _markMetadata()));
    _subscriptions.add(_inputs.mediaTitle.listen((_) => _markMetadata()));

    // Config changes — drive `updateConfig`, AND re-push metadata. The
    // metadata-override fields (title / artist / album / artwork /
    // duration) live in the metadata snapshot, not the config map, so a
    // `setMediaSession(copyWith(title: ...))` must also re-push metadata
    // or the override would never reach the OS until an unrelated mpv
    // metadata tick happened to fire (often never on a static track).
    _subscriptions.add(_inputs.mediaSession.listen((session) {
      if (session == null) return;
      _channel.updateConfig(session);
      _markMetadata();
    }),);

    // Inbound commands from the OS event channel.
    _commandSub = _channel.commandStream.listen(_onCommand);
    final onReset = _onAudioOutputReset;
    if (onReset != null) {
      _audioOutputResetSub = _channel.audioOutputResets.listen(
        (_) => onReset(),
      );
    }

    // Push the initial full state.
    final state = _stateSnapshot();
    final session = state.mediaSession;
    if (session == null) return;
    final metadata = _computeMetadata();
    _lastMetadata = metadata;
    await _channel.enable(
      session: session,
      metadata: metadata,
      playback: _computePlayback(),
    );
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _artRetry?.cancel();

    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
    await _commandSub?.cancel();
    _commandSub = null;
    await _audioOutputResetSub?.cancel();
    _audioOutputResetSub = null;
    await _channel.disable();
  }

  // ── Push helpers ────────────────────────────────────────────────────

  /// Marks the playback snapshot dirty and schedules a coalesced flush.
  ///
  /// The OS play/pause state comes from `playWhenReady` (user intent),
  /// not `core-idle` — so it stays stable while mpv churns through the
  /// seek/restart cycle and the scrub-bar button never flickers. No
  /// seek-transient masking is needed. [seek] sticks across the coalescing
  /// window so a seek landing in the same turn still emits MPRIS `Seeked`.
  void _markPlayback({bool seek = false}) {
    _playbackDirty = true;
    if (seek) _playbackSeek = true;
    _scheduleFlush();
  }

  void _markMetadata() {
    _metadataDirty = true;
    _scheduleFlush();
  }

  void _scheduleFlush() {
    if (_flushScheduled || _disposed) return;
    _flushScheduled = true;
    scheduleMicrotask(_flush);
  }

  /// Flushes the coalesced dirty state: at most one metadata + one playback
  /// push per microtask turn. Metadata is deduped against the last-pushed
  /// snapshot so an unchanged value (incl. cover identity) doesn't re-ship.
  Future<void> _flush() async {
    _flushScheduled = false;
    if (_disposed || _stateSnapshot().mediaSession == null) {
      _metadataDirty = false;
      _playbackDirty = false;
      _playbackSeek = false;
      return;
    }
    if (_metadataDirty) {
      _metadataDirty = false;
      final snap = _computeMetadata();
      if (_lastMetadata == null || snap != _lastMetadata) {
        _lastMetadata = snap;
        await _channel.updateMetadata(snap);
      }
    }
    if (_playbackDirty) {
      final seek = _playbackSeek;
      _playbackDirty = false;
      _playbackSeek = false;
      await _channel.updatePlayback(_computePlayback(seek: seek));
    }
  }

  // ── Snapshot builders ───────────────────────────────────────────────

  MediaSessionMetadataSnapshot _computeMetadata() {
    final state = _stateSnapshot();
    final override = state.mediaSession;
    final mpvMeta = state.metadata;

    // The currently-playing queue item. Its consumer-attached
    // [Media.extras] are the metadata fallback for tag-less files — most
    // importantly transcoded streams (HLS/DASH), where mpv sees no tags and
    // reports the stream URL as `media-title`. extras sit below mpv's real
    // tags but above the filename-derived `media-title`.
    final playlist = state.playlist;
    final item =
        (playlist.index >= 0 && playlist.index < playlist.items.length)
            ? playlist.items[playlist.index]
            : null;
    final extras = item?.extras;

    // Title falls through: explicit override → mpv's `metadata.title` tag
    // → consumer-attached `extras['title']` → mpv's `media-title` (which
    // itself falls back to the filename for files without a title tag).
    // For a network item that last fallback is derived from the URL, so its
    // query string (often credentials) is stripped first.
    final remote = item != null && !_isLocalUri(item.uri);
    final title = override?.title ??
        _firstTagValue(mpvMeta, const ['title']) ??
        _extra(extras, 'title') ??
        (state.mediaTitle.isEmpty
            ? null
            : remote
                ? _redactUrlTitle(state.mediaTitle)
                : state.mediaTitle);

    final artist = override?.artist ??
        _firstTagValue(mpvMeta, const ['artist', 'album_artist']) ??
        _extra(extras, 'artist');

    final album = override?.album ??
        _firstTagValue(mpvMeta, const ['album']) ??
        _extra(extras, 'album');

    final duration = override?.duration ??
        (state.duration == Duration.zero ? null : state.duration);

    // Rich tags (mpv-derived, with the extras-attached artist as a final
    // fallback for the album-artist line on tag-less streams).
    final albumArtist =
        _firstTagValue(mpvMeta, const ['album_artist']) ?? _extra(extras, 'artist');
    final genre = _firstTagValue(mpvMeta, const ['genre']);
    // mpv `track` / `disc` tags are often "3" or "3/12" — take the leading int.
    final trackNumber = _parseLeadingInt(_firstTagValue(mpvMeta, const ['track']));
    final discNumber = _parseLeadingInt(_firstTagValue(mpvMeta, const ['disc']));

    // Source URI of the current item, for MPRIS xesam:url. Only local files:
    // the bus is readable by every process in the session, and a network
    // URL can carry credentials (Subsonic `u`, `t` and `s`, Jellyfin `api_key`).
    final url = remote ? null : item?.uri;

    var artwork = _resolveArtwork(override, state.coverArt, extras);
    if (_artworkFetcher != null && _isHttpUri(artwork.uri)) {
      artwork = (bytes: _downloadedArtwork(artwork.uri!), uri: null);
    }

    return MediaSessionMetadataSnapshot(
      title: title,
      artist: artist,
      album: album,
      artwork: artwork.bytes,
      artworkUri: artwork.uri,
      duration: duration,
      trackNumber: trackNumber,
      discNumber: discNumber,
      albumArtist: albumArtist,
      genre: genre,
      url: url,
    );
  }

  /// Reads a non-empty string [key] from a queue item's [Media.extras];
  /// `null` if the map is absent, lacks the key, or the value is blank or
  /// not a string. Lets a consumer supply lockscreen metadata for streams
  /// the file itself can't tag.
  String? _extra(Map<String, Object?>? extras, String key) {
    final v = extras?[key];
    return (v is String && v.isNotEmpty) ? v : null;
  }

  /// Whether [uri] names a local file: a `file:` URI, a plain path, or a
  /// Windows drive path (which parses with a one-letter scheme).
  static bool _isLocalUri(String uri) {
    final scheme = Uri.tryParse(uri)?.scheme ?? '';
    return scheme.isEmpty || scheme == 'file' || scheme.length == 1;
  }

  static bool _isHttpUri(String? uri) {
    if (uri == null) return false;
    final scheme = Uri.tryParse(uri)?.scheme.toLowerCase();
    return scheme == 'http' || scheme == 'https';
  }

  /// Removes what could be credentials from a title mpv derived from a URL:
  /// a trailing `key=value` query or fragment, and the userinfo of a full
  /// URL. A real title with a `?` in it ("Who Are You?") has no `=` after
  /// it and is left alone. `null` when nothing is left.
  static String? _redactUrlTitle(String title) {
    var t = title;
    final query = RegExp(r'[?#]\S*$').firstMatch(t);
    if (query != null && query.group(0)!.contains('=')) {
      t = t.substring(0, query.start);
    }
    t = t.replaceFirstMapped(
      RegExp(r'^([a-z][a-z0-9+.-]*://)[^/@\s]*@', caseSensitive: false),
      (m) => m.group(1)!,
    );
    return t.isEmpty ? null : t;
  }

  /// The downloaded cover for the remote artwork [uri], or `null` while the
  /// download is in flight or after it failed. Starts the download on first
  /// sight of [uri]; its completion re-pushes metadata. A failed download is
  /// tried again after [_artworkRetryAfter], up to [_artworkAttempts] times
  /// per URL.
  CoverArt? _downloadedArtwork(String uri) {
    if (uri == _fetchedArtUri) return _fetchedArt;
    if (uri != _pendingArtUri) {
      _pendingArtUri = uri;
      _artRetry?.cancel();
      if (uri != _artAttemptsUri) {
        _artAttemptsUri = uri;
        _artAttempts = 0;
      }
      _artAttempts++;
      unawaited(
        _artworkFetcher!(Uri.parse(uri))
            .catchError((Object _) => null)
            .then((cover) {
          if (_disposed || uri != _pendingArtUri) return;
          _pendingArtUri = null;
          _fetchedArtUri = uri;
          _fetchedArt = cover;
          if (cover == null && _artAttempts < _artworkAttempts) {
            _artRetry = Timer(_artworkRetryAfter, () {
              // Forget the failure so the next push downloads again.
              if (_fetchedArtUri == uri) _fetchedArtUri = null;
              _markMetadata();
            });
          }
          _markMetadata();
        }),
      );
    }
    return null;
  }

  /// Parses the leading integer from a tag like `"3"` or `"3/12"`; `null` if
  /// absent or non-numeric.
  int? _parseLeadingInt(String? raw) {
    if (raw == null) return null;
    final match = RegExp(r'^\s*(\d+)').firstMatch(raw);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  /// Resolves the effective artwork into the two mutually-exclusive shapes the
  /// snapshot carries: decoded [bytes] (embedded / custom) or a [uri] the
  /// native side fetches itself.
  ///
  /// For the default [MediaSessionArtwork.embedded] the file's embedded cover
  /// wins; when it has none — the common case for a transcoded stream — we
  /// fall back to a network artwork URL the consumer attached to the queue
  /// item as `extras['art']`, mirroring the title/artist/album fallback. An
  /// explicit [MediaSessionArtwork.none] suppresses art outright (no fallback).
  ({CoverArt? bytes, String? uri}) _resolveArtwork(
    MediaSession? override,
    CoverArt? embedded,
    Map<String, Object?>? extras,
  ) {
    final artwork = override?.artwork ?? MediaSessionArtwork.embedded;
    return switch (artwork) {
      MediaSessionArtworkNone() => (bytes: null, uri: null),
      MediaSessionArtworkCustom(:final cover) => (bytes: cover, uri: null),
      MediaSessionArtworkUri(:final uri) => (bytes: null, uri: uri.toString()),
      MediaSessionArtworkEmbedded() => embedded != null
          ? (bytes: embedded, uri: null)
          : (bytes: null, uri: _extra(extras, 'art')),
    };
  }

  MediaSessionPlaybackSnapshot _computePlayback({bool seek = false}) {
    final state = _stateSnapshot();
    // Navigability: a real multi-item mpv playlist reflects its bounds
    // (loop=playlist wraps both ways); a single item stays navigable so an
    // external-queue consumer still receives next/previous.
    final pl = state.playlist;
    final multi = pl.items.length > 1;
    final loopPlaylist = state.loop == Loop.playlist;
    final hasNext = !multi || loopPlaylist || pl.index < pl.items.length - 1;
    final hasPrevious = !multi || loopPlaylist || pl.index > 0;
    return MediaSessionPlaybackSnapshot(
      playing: state.playWhenReady,
      position: state.position,
      rate: state.rate,
      seekable: state.seekable,
      loop: state.loop,
      shuffle: state.shuffle,
      // Terminal end-of-content. The `eof-reached` hook releases
      // `playWhenReady` at true EOF, which already drives a playback push,
      // so the completed transition is carried on that same snapshot.
      completed: state.completed,
      seek: seek,
      // Actual output + buffering — for extrapolation gating and the loading
      // state. Independent of the intent axis the button binds to.
      actualPlaying: state.playing,
      buffering: state.buffering,
      hasNext: hasNext,
      hasPrevious: hasPrevious,
    );
  }

  /// First non-empty value among [keys] in the mpv metadata map, matched
  /// **case-insensitively**: mpv's tag-key casing varies by container
  /// (ID3v2 / Vorbis come back lowercase, but MP4 / iTunes atoms do not),
  /// so never assume a fixed case. [keys] are given lowercase; the list
  /// also carries semantic fallbacks (e.g. `album_artist` when `artist`
  /// is absent).
  String? _firstTagValue(Map<String, String> meta, List<String> keys) {
    for (final key in keys) {
      for (final entry in meta.entries) {
        if (entry.value.isNotEmpty && entry.key.toLowerCase() == key) {
          return entry.value;
        }
      }
    }
    return null;
  }
}
