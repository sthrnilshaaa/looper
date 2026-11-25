// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/cover_art.dart';
import '../player/player_state.dart';
import '../types/sealed/media_session_command.dart';
import 'artwork_fetcher.dart';
import 'artwork_loader.dart';
import 'media_session_channel.dart';
import 'media_session_inputs.dart';
import 'media_session_snapshots.dart';
import 'media_session_uris.dart';

/// Orchestrates the bridge between the [Player]'s reactive state and
/// the OS media session.
///
/// Subscribes to a focused subset of [PlayerStream]:
///
/// - `playWhenReady`, `rate`, `seekCompleted`, `seekable`, `loop` and
///   `shuffle` → push a fresh playback snapshot (the OS extrapolates
///   position forward from this, so we never push raw `time-pos`
///   ticks). The OS play-pause state is driven by `playWhenReady` (user
///   intent), which is stable across seeks, so the button never
///   flickers while scrubbing. The `seekCompleted` push re-syncs the
///   landed position to the OS slider.
/// - `duration`, `metadata`, `coverArt` and `mediaTitle` → push a
///   fresh metadata snapshot.
/// - `mediaSession` (the config field itself) → push a config update
///   when the consumer reconfigures while enabled.
///
/// Computes effective metadata (override > mpv-derived) using the
/// current [PlayerState] snapshot at push time, so streams are only
/// signal sources, never source of truth.
///
/// Incoming commands from the OS event channel are routed through
/// [onCommand]. The owner ([_MediaSessionModule]) is responsible for
/// applying them to the [Player] and forwarding to consumer
/// subscribers; this class is transport-only.
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

  /// Loads artwork URLs ([fetchesArtwork]) so the OS gets the image
  /// bytes, never the URL (see [downloadsArtworkOn]). Without one, artwork
  /// URLs show no artwork. It runs one load at a time, cancels the one a
  /// track change leaves behind and keeps the last few covers.
  final ArtworkLoader? _artworkLoader;

  final List<StreamSubscription<dynamic>> _subscriptions = [];
  StreamSubscription<MediaSessionCommand>? _commandSub;
  StreamSubscription<void>? _audioOutputResetSub;
  bool _disposed = false;

  // Whether a native side answered `enable`. Until it has, and for good on
  // a platform without one (Tizen, webOS), nothing listens to the event
  // channel, no artwork is loaded and nothing is pushed.
  bool _native = false;

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

  // ── Artwork download (only with an [_artworkLoader]) ────────────────
  // The last downloaded URL and its result (`null` on failure), plus the
  // URL whose download is in flight. One cover at a time: a track change
  // cancels the pending one.
  String? _fetchedArtUri;
  CoverArt? _fetchedArt;
  String? _pendingArtUri;
  // Runs after a failed download and fetches the same URL again, so a
  // server that was briefly down still gets a cover on this track. At most
  // [_artworkAttempts] downloads per URL: a URL that keeps failing (a 404,
  // an unreadable CA file) is not fetched, credentials and all, forever.
  Timer? _artRetry;
  final Duration _artworkRetryAfter;
  static const _artworkAttempts = 3;
  String? _artAttemptsUri;
  int _artAttempts = 0;

  // The pauses and stops the app made, pushed as
  // [MediaSessionPlaybackSnapshot.appPauses].
  int _appPauses = 0;

  // The `seekable` last sent to the OS. mpv reports it unavailable while
  // the next track loads, and the OS reads a non-seekable entry as a live
  // stream, so the loading gap keeps the previous value.
  bool? _pushedSeekable;

  MediaSessionController._({
    required PlayerState Function() stateSnapshot,
    required MediaSessionInputs inputs,
    required void Function(MediaSessionCommand) onCommand,
    void Function()? onAudioOutputReset,
    MediaSessionChannel? channel,
    ArtworkLoader? artworkLoader,
    Duration artworkRetryAfter = const Duration(seconds: 30),
  }) : _artworkRetryAfter = artworkRetryAfter,
       _stateSnapshot = stateSnapshot,
       _inputs = inputs,
       _onCommand = onCommand,
       _onAudioOutputReset = onAudioOutputReset,
       _channel = channel ?? MediaSessionChannel(),
       _artworkLoader = artworkLoader;

  /// Wires the controller up and pushes the initial full state to the
  /// native side. Returns once the initial `enable` call has been
  /// dispatched (native ACK is fire-and-forget; see
  /// [MediaSessionChannel] for the rationale).
  ///
  /// [inputs] declares the exact slice of Player state the controller
  /// consumes. Production builds it from the player's change streams;
  /// tests can build a
  /// [MediaSessionInputs] from raw [StreamController]s and drive
  /// arbitrary event sequences.
  ///
  /// [artworkLoader] defaults to one over [loadArtwork] (see
  /// [downloadsArtworkOn]). It gets the artwork URLs [fetchesArtwork] names.
  /// [artworkFetcher] is a plain fetcher for it to run instead.
  static Future<MediaSessionController> create({
    required PlayerState Function() stateSnapshot,
    required MediaSessionInputs inputs,
    required void Function(MediaSessionCommand) onCommand,
    void Function()? onAudioOutputReset,
    @visibleForTesting MediaSessionChannel? channel,
    @visibleForTesting ArtworkFetcher? artworkFetcher,
    @visibleForTesting ArtworkLoader? artworkLoader,
    @visibleForTesting Duration artworkRetryAfter = const Duration(seconds: 30),
  }) async {
    final c = MediaSessionController._(
      stateSnapshot: stateSnapshot,
      inputs: inputs,
      onCommand: onCommand,
      onAudioOutputReset: onAudioOutputReset,
      channel: channel,
      artworkLoader:
          artworkLoader ??
          (artworkFetcher != null
              ? ArtworkLoader.uncancellable(artworkFetcher)
              : downloadsArtworkOn(defaultTargetPlatform)
              ? ArtworkLoader.platform()
              : null),
      artworkRetryAfter: artworkRetryAfter,
    );
    try {
      await c._wireUp();
    } catch (_) {
      // Its subscriptions are live by now: tear them down, or every push
      // of the player would reach a controller nobody holds.
      try {
        await c.dispose();
      } catch (_) {
        // The original error is the one the caller needs.
      }
      rethrow;
    }
    return c;
  }

  Future<void> _wireUp() async {
    // Playback-state signals: drive `updatePlayback`. The OS button
    // tracks `playWhenReady` (user intent), which is flicker-free across
    // seeks. The `seekCompleted` push re-syncs the landed position on
    // EVERY restart (seek + file-load) so the OS slider tracks mpv (e.g.
    // snaps to ~0 on playlist auto-advance).
    _subscriptions.add(_inputs.playWhenReady.listen((_) => _markPlayback()));
    // Actual-output + buffering changes drive position-extrapolation gating and
    // the loading indication. They do NOT touch the OS play-pause button (bound
    // to playWhenReady), so they can't flicker it; same-turn pushes coalesce.
    _subscriptions.add(_inputs.playing.listen((_) => _markPlayback()));
    // Loading ends: push the metadata held back while it lasted.
    _subscriptions.add(
      _inputs.buffering.listen((buffering) {
        if (buffering) _clearStopped();
        _markPlayback();
        if (!buffering) _markMetadata();
      }),
    );
    _subscriptions.add(_inputs.rate.listen((_) => _markPlayback()));
    // A seek landing (PLAYBACK_RESTART) carries seek=true so the native side
    // (Linux MPRIS) can emit `Seeked` deterministically.
    _subscriptions.add(
      _inputs.seekCompleted.listen((_) => _markPlayback(seek: true)),
    );
    // Seekable governs both the OS scrubber (enabled or disabled) and
    // the "live stream" UI mode; re-push when it flips.
    _subscriptions.add(_inputs.seekable.listen((_) => _markPlayback()));
    // Loop + shuffle drive the OS repeat and shuffle button visual state
    // (Apple's `currentRepeatType` and `currentShuffleType`,
    // MPRIS `LoopStatus` and `Shuffle`, MediaSession actions).
    _subscriptions.add(_inputs.loop.listen((_) => _markPlayback()));
    _subscriptions.add(_inputs.shuffle.listen((_) => _markPlayback()));
    // The queue drives next, previous, and Play while stopped.
    _subscriptions.add(_inputs.playlist.listen((_) => _markPlayback()));

    // Metadata signals: drive `updateMetadata`.
    _subscriptions.add(_inputs.duration.listen((_) => _markMetadata()));
    _subscriptions.add(_inputs.metadata.listen((_) => _markMetadata()));
    _subscriptions.add(_inputs.coverArt.listen((_) => _markMetadata()));
    _subscriptions.add(_inputs.mediaTitle.listen((_) => _markMetadata()));

    // Config changes: drive `updateConfig`, AND re-push metadata. The
    // metadata-override fields (title, artist, album, artwork and
    // duration) live in the metadata snapshot, not the config map, so a
    // `setMediaSession(copyWith(title: ...))` must also re-push metadata
    // or the override would never reach the OS until an unrelated mpv
    // metadata tick happened to fire (often never on a static track).
    _subscriptions.add(
      _inputs.mediaSession.listen((session) {
        if (session == null) return;
        unawaited(_channel.updateConfig(session));
        _markMetadata();
      }),
    );

    // Push the initial full state. An artwork URL is not loaded yet: the
    // platform may have no session to show it on.
    final state = _stateSnapshot();
    final session = state.settings.mediaSession;
    if (session == null) return;
    final metadata = _computeMetadata();
    _lastMetadata = metadata;
    final native = await _channel.enable(
      session: session,
      metadata: metadata,
      playback: _pushedPlayback(),
    );
    if (_disposed) return;
    if (!native) {
      // No plugin on this platform: the session is a no-op. Listening to
      // the event channel would make Flutter report an error.
      await _cancelInputs();
      return;
    }
    _native = true;

    // Inbound commands from the OS event channel. The native side keeps
    // the sink of each engine whatever the order of `listen` and `enable`.
    _commandSub = _channel.commandStream.listen(_onCommand);
    final onReset = _onAudioOutputReset;
    if (onReset != null) {
      _audioOutputResetSub = _channel.audioOutputResets.listen(
        (_) => onReset(),
      );
    }
    // What changed while `enable` was in flight, and the artwork URL the
    // first snapshot left out.
    _markMetadata();
  }

  Future<void> _cancelInputs() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _artRetry?.cancel();
    _artworkLoader?.cancel();

    await _cancelInputs();
    await _commandSub?.cancel();
    _commandSub = null;
    await _audioOutputResetSub?.cancel();
    _audioOutputResetSub = null;
    await _channel.disable();
  }

  // ── Push helpers ────────────────────────────────────────────────────

  /// Marks the playback snapshot dirty and schedules a coalesced flush.
  ///
  /// The OS play-pause state comes from `playWhenReady` (user intent),
  /// not `core-idle`, so it stays stable while mpv churns through the
  /// seek and restart cycle and the scrub-bar button never flickers. No
  /// seek-transient masking is needed. [seek] sticks across the coalescing
  /// window so a seek landing in the same turn still emits MPRIS `Seeked`.
  void _markPlayback({bool seek = false}) {
    _playbackDirty = true;
    if (seek) _playbackSeek = true;
    _scheduleFlush();
  }

  /// The app called `pause` or `stop`. Pushed even when the state does
  /// not change: during a call the player is already paused, and Android
  /// must still learn that the end of the call is not to play again.
  void appPaused() {
    _appPauses++;
    _markPlayback();
  }

  /// The player stopped: the OS shows a stopped state, where it has one,
  /// until a load starts. A play with nothing to start leaves it stopped.
  void stopped() {
    _stopped = true;
    _markPlayback();
  }

  /// Set by [stopped], cleared by the next load.
  bool _stopped = false;

  void _clearStopped() {
    if (!_stopped) return;
    _stopped = false;
    _markPlayback();
  }

  void _markMetadata() {
    _metadataDirty = true;
    _scheduleFlush();
  }

  void _scheduleFlush() {
    if (_flushScheduled || _disposed || !_native) return;
    _flushScheduled = true;
    scheduleMicrotask(_flush);
  }

  /// Flushes the coalesced dirty state: at most one metadata + one playback
  /// push per microtask turn. Metadata is deduped against the last-pushed
  /// snapshot so an unchanged value (incl. cover identity) doesn't re-ship.
  ///
  /// While a track loads, metadata stays dirty instead: mpv reports the
  /// previous file's title, tags and duration unavailable before the new
  /// ones arrive, and pushing that gap would flash an empty entry on the
  /// lockscreen. The end of loading pushes it once.
  ///
  /// Both pushes are sent in this turn, metadata first: the channel keeps
  /// the order of the sends, and the play state of a track change does not
  /// wait for the native side to answer a message with a cover in it.
  /// Nothing is sent after an await, so nothing follows a `disable`.
  void _flush() {
    _flushScheduled = false;
    if (_disposed || _stateSnapshot().settings.mediaSession == null) {
      _metadataDirty = false;
      _playbackDirty = false;
      _playbackSeek = false;
      return;
    }
    if (_metadataDirty && !_stateSnapshot().network.buffering) {
      _metadataDirty = false;
      final snap = _computeMetadata();
      if (_lastMetadata == null || snap != _lastMetadata) {
        _lastMetadata = snap;
        unawaited(_channel.updateMetadata(snap));
      }
    }
    if (_playbackDirty) {
      final seek = _playbackSeek;
      _playbackDirty = false;
      _playbackSeek = false;
      unawaited(_channel.updatePlayback(_pushedPlayback(seek: seek)));
    }
  }

  // ── Snapshot builders ───────────────────────────────────────────────

  MediaSessionMetadataSnapshot _computeMetadata() =>
      metadataSnapshot(_stateSnapshot(), _artworkFor);

  /// The playback snapshot to push now. It is pushed, so it records the
  /// `seekable` the OS shows.
  MediaSessionPlaybackSnapshot _pushedPlayback({bool seek = false}) {
    final snap = playbackSnapshot(
      _stateSnapshot(),
      seek: seek,
      pushedSeekable: _pushedSeekable,
      appPauses: _appPauses,
      stopped: _stopped,
    );
    _pushedSeekable = snap.seekable;
    return snap;
  }

  /// The picture of [artwork] for the native side, and the URL the browser
  /// shows instead. A URL reaches the native side as the image it names,
  /// or not at all. In the browser a URL the fetch cannot read (no CORS)
  /// still shows: the browser loads it as an image and hands the OS the
  /// picture.
  ({CoverArt? cover, String? artworkUrl}) _artworkFor(
    ({CoverArt? bytes, String? uri}) artwork,
  ) {
    final uri = artwork.uri;
    if (uri == null) return (cover: artwork.bytes, artworkUrl: null);
    final cover = _native && _artworkLoader != null && fetchesArtwork(uri)
        ? _downloadedArtwork(uri)
        : null;
    final showUrl = passesArtworkUrl && cover == null && isHttpUri(uri);
    return (cover: cover, artworkUrl: showUrl ? uri : null);
  }

  /// The cover loaded from the artwork [uri], or `null` while the load is
  /// in flight or after it failed. Starts the load on first sight of [uri],
  /// which cancels the one in flight; its completion re-pushes metadata. A
  /// cover the loader still keeps (the track before, most often) comes
  /// back at once.
  CoverArt? _downloadedArtwork(String uri) {
    if (uri == _fetchedArtUri) return _fetchedArt;
    final loader = _artworkLoader!;
    final settings = _stateSnapshot().settings;
    final caFiles = [
      for (final f in [settings.tlsCaFile, settings.tlsExtraCaFile])
        if (f.isNotEmpty) f,
    ];
    final kept = loader.cached(uri, caFiles);
    if (kept != null) {
      // The load of the track skipped past is not worth finishing.
      if (_pendingArtUri != null) loader.cancel();
      _pendingArtUri = null;
      _artRetry?.cancel();
      _fetchedArtUri = uri;
      _fetchedArt = kept;
      return kept;
    }
    if (uri != _pendingArtUri) {
      _pendingArtUri = uri;
      _artRetry?.cancel();
      if (uri != _artAttemptsUri) {
        _artAttemptsUri = uri;
        _artAttempts = 0;
      }
      _artAttempts++;
      unawaited(
        loader.load(uri, caFiles).then((cover) {
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
}

/// Runs a [Player] call issued by an OS media-session command without
/// awaiting it, and reports a late failure to [onError] instead of
/// leaving it unhandled.
///
/// [action] can complete with any value type (`next` and `previous`
/// return a `Future<bool>`), so the error handler must not return a value
/// typed for one of them.
@internal
void runSessionCommand(
  Future<Object?> action,
  void Function(Object error) onError,
) {
  unawaited(
    action.then<void>((_) {}, onError: (Object e, StackTrace st) => onError(e)),
  );
}
