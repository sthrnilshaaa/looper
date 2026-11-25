import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'dart:math' as math;
import '../../utils/logger_helper.dart';
import 'package:looper_player/core/utils/l10n.dart';
import 'transition_director.dart';
part 'audio_dsp.dart';
part 'player_setup.dart';

class AudioService {
  late final Player _playerA;
  late final Player _playerB;
  late final TransitionDirector transitionDirector;

  Player get player => transitionDirector.activePlayer;
  Player get idlePlayer => transitionDirector.idlePlayer;

  List<double>? _lastEqualizerGains;
  bool _equalizerEnabled = false;
  String? _customFilterString;
  bool _monoEnabled = false;
  List<String> _autoEqFilters = const [];
  String? _lastArtPath;
  MediaSessionArtwork _lastArtwork = MediaSessionArtwork.embedded;
  String? _publishedMediaMetadataKey;
  String? _pendingMediaMetadataKey;
  int _mediaMetadataGeneration = 0;
  InterruptionPolicy _interruptionPolicy = InterruptionPolicy.pauseAndResume;

  // One set for every publish, so the notification's buttons stay put.
  // No stop: it takes a button slot on the notification.
  static const _sessionActions = {
    MediaAction.play,
    MediaAction.pause,
    MediaAction.playPause,
    MediaAction.next,
    MediaAction.previous,
    MediaAction.seek,
    MediaAction.like,
    MediaAction.setShuffle,
    MediaAction.setRepeatMode,
  };

  Timer? _liveEqThrottleTimer;
  List<double>? _throttledGains;
  bool _throttledEnabled = false;
  String? _throttledCustomFilter;

  // True between `play()` call and first non-empty playlist event — used
  // to trigger a deferred EQ application once FILE_LOADED populates items.
  bool _pendingEqApply = false;

  static String? _resolvedResamplerFilter;
  static bool _resamplerProbed = false;

  static const _broadcastChannel = MethodChannel('com.looper.player/broadcast');

  Future<bool> isOnCall() async {
    if (!Platform.isAndroid) return false;
    try {
      final bool? result = await _broadcastChannel.invokeMethod<bool>(
        'isOnCall',
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> restartApp() async {
    if (Platform.isAndroid) {
      try {
        await _broadcastChannel.invokeMethod('restartApp');
      } catch (_) {
        exit(0);
      }
    } else {
      exit(0);
    }
  }

  Future<void> setStopOnTaskRemoved(bool value) async {
    if (!Platform.isAndroid) return;
    try {
      await _broadcastChannel.invokeMethod('setStopOnTaskRemoved', {
        'value': value,
      });
    } catch (_) {}
  }

  // Callbacks for OS media-session commands (notification, lock screen,
  // Bluetooth/headset buttons, MPRIS, and mpv_audio_kit's own audio-focus
  // and becoming-noisy reactions, which arrive as play/pause commands).
  //
  // mpv_audio_kit auto-applies play/pause/playPause/stop/seek/shuffle/repeat
  // to the Player *before* emitting the command here, so these handlers must
  // reconcile app state with what already happened - never re-apply or
  // toggle it again, or the two layers undo each other. Only next/previous
  // (autoApplyPlaylistNavigation: false) and like are left to the app.
  void Function()? onNext;
  void Function()? onPrevious;
  void Function()? onFavoriteToggle;

  /// mpv already sought to about [target] (for a relative SeekBy, mpv
  /// offsets its live playhead, so this is only an estimate for the UI).
  void Function(Duration target)? onSeekApplied;

  /// mpv's own shuffle was already set to [shuffle].
  void Function(bool shuffle)? onShuffleCommand;

  /// mpv's own loop mode was already set to [loop].
  void Function(Loop loop)? onRepeatCommand;

  /// mpv was already told to play.
  void Function()? onPlay;

  /// mpv was already told to pause.
  void Function()? onPause;

  /// mpv already toggled, resolved against its own `playWhenReady`.
  void Function()? onPlayPause;

  /// mpv already stopped, which unloads the current file.
  void Function()? onStop;

  /// Resolves once the bootstrap `setMediaSession()` call in [_initPlayer]
  /// has actually completed. mpv_audio_kit's `setMediaSession` lazily
  /// allocates its native-side controller on the first non-null call and
  /// explicitly does not support a second *concurrent* non-null call
  /// racing the first (see the package's own `_MediaSessionModule` docs) —
  /// the loser's freshly-created controller gets disposed, which tears
  /// down the single native media-session singleton out from under the
  /// winner, permanently killing the notification for the rest of the
  /// process. Callers that need to reconfigure the session (e.g.
  /// [applyAudioFocusPolicy]) must await this first so they land on the
  /// safe "reconfigure existing controller" path instead of racing the
  /// bootstrap create.
  late final Future<void> ready;

  AudioService() {
    LoggerHelper.write(
      'AudioService: Constructing dual Players for Crossmix...',
    );
    _playerA = Player();
    _playerB = Player();
    transitionDirector = TransitionDirector(
      playerA: _playerA,
      playerB: _playerB,
    );
    ready = _initPlayer();

    // ── EQ deferred-apply on FILE_LOADED ────────────────────────────────────────
    void setupEqListener(Player p) {
      p.stream.playlist.listen((playlist) {
        if (_pendingEqApply && playlist.items.isNotEmpty) {
          _pendingEqApply = false;
          if (_lastEqualizerGains != null) {
            setEqualizerGains(
              _lastEqualizerGains!,
              _equalizerEnabled,
              customFilter: _customFilterString,
            );
          }
        }
      });
    }

    setupEqListener(_playerA);
    setupEqListener(_playerB);

    _attachMediaSessionListeners();
  }

  Future<void> _configurePlayer(Player p) async {
    try {
      await p.setRawProperty('volume-max', '150');
    } catch (_) {}

    try {
      await p.setRawProperty('audio-buffer', '0.2');
    } catch (_) {}

    try {
      await p.setRawProperty('demuxer-lavf-analyzeduration', '1.0');
    } catch (_) {}

    try {
      await p.setRawProperty('demuxer-lavf-probesize', '10000000');
    } catch (_) {}

    try {
      await p.setRawProperty('audio-pitch-correction', 'yes');
    } catch (_) {}

    try {
      await p.setRawProperty('hwdec', 'no');
    } catch (_) {}
  }

  Future<void> _initPlayer() async {
    LoggerHelper.write('AudioService: Initializing player properties...');
    await _configurePlayer(_playerA);
    await _configurePlayer(_playerB);
    await _initMediaSession();
  }

  Future<void> _initMediaSession({
    InterruptionPolicy interruptionPolicy = InterruptionPolicy.pauseAndResume,
  }) async {
    _interruptionPolicy = interruptionPolicy;

    final current = player.state.settings.mediaSession;
    // Must be awaited: mpv_audio_kit's setMediaSession() lazily allocates its
    // native-side controller on the first non-null call, and explicitly does
    // not support a second *concurrent* non-null call racing that bootstrap
    // (see the package's `_MediaSessionModule` docs) - the loser's
    // freshly-created controller gets disposed, which tears down the single
    // native media-session singleton out from under the winner and silently
    // kills the notification for the rest of the process. Firing this
    // fire-and-forget let it race the constructor's own bootstrap call in
    // _initPlayer(), which is exactly what `ready` above now serializes
    // against.
    await player.setMediaSession(
      (current ?? const MediaSession()).copyWith(
        appName: 'Looper Player',
        desktopEntry: 'looper_player',
        autoApplyPlaylistNavigation: false,
        actions: _sessionActions,
        interruptionPolicy: _interruptionPolicy,
      ),
    );
  }

  /// Call this when the audioFocus setting changes so the interruption
  /// policy is re-published to the native media session. Awaits [ready]
  /// first so a policy change fired before bootstrap finishes can't race it
  /// (see [_initMediaSession]).
  Future<void> applyAudioFocusPolicy(
    InterruptionPolicy interruptionPolicy,
  ) async {
    await ready;
    await _initMediaSession(interruptionPolicy: interruptionPolicy);
  }

  // --- Caching Configurations ---

  Future<void> configureCache({
    required bool enabled,
    required int maxBytes,
    required int cacheSecs,
    required int backBytes,
  }) async {
    try {
      await player.setCache(
        CacheSettings(
          mode: enabled ? Cache.yes : Cache.no,
          secs: Duration(seconds: cacheSecs),
        ),
      );
      await player.setDemuxer(
        DemuxerSettings(maxBytes: maxBytes, maxBackBytes: backBytes),
      );
    } catch (e) {}
  }

  // --- ReplayGain Scaling ---

  Future<void> configureReplayGain({
    required int mode, // 0 = off, 1 = track, 2 = album
    required double preamp,
    bool clip = true,
    double fallback = 0.0,
  }) async {
    try {
      final rgMode = mode == 1
          ? ReplayGain.track
          : (mode == 2 ? ReplayGain.album : ReplayGain.no);
      final settings = ReplayGainSettings(
        mode: rgMode,
        preamp: preamp,
        clip: clip,
        fallback: fallback,
      );
      await player.setReplayGain(settings);
      if (idlePlayer.state.playback.playlist.items.isNotEmpty) {
        try {
          await idlePlayer.setReplayGain(settings);
        } catch (_) {}
      }
    } catch (e) {}
  }

  // --- Multi-track Audio Stream Handling ---

  Future<List<Map<String, dynamic>>> getAudioTracks() async {
    try {
      final String? trackListJson = await player.getRawProperty('track-list');
      if (trackListJson == null) return [];
      final List<dynamic> rawTracks = jsonDecode(trackListJson);
      return rawTracks
          .where((t) => t['type'] == 'audio')
          .map(
            (t) => {
              'id': t['id'] as int,
              'title': t['title'] ?? 'Track ${t['id']}',
              'lang': t['lang'] ?? 'unknown',
              'codec': t['codec'] ?? 'unknown',
              'channels': t['demux-channels'] ?? 2,
              'selected': t['selected'] as bool? ?? false,
            },
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> selectAudioTrack(int trackId) async {
    try {
      // Find matching track
      final activeTracks = player.state.file.tracks.where(
        (t) => t.type == 'audio',
      );
      final match = activeTracks.firstWhere(
        (t) => t.id == trackId,
        orElse: () => activeTracks.first,
      );
      await player.setAudioTrack(Track.id(match.id));
    } catch (e) {}
  }

  // --- Hardware Device Routing ---

  Future<List<Map<String, String>>> getAudioDevices() async {
    try {
      return player.state.output.audioDevices
          .map<Map<String, String>>(
            (d) => {
              'name': (d.name as String?) ?? '',
              'description': (d.description as String?) ?? '',
            },
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> routeAudioDevice(String deviceName) async {
    try {
      final match = player.state.output.audioDevices.firstWhere(
        (d) => d.name == deviceName,
        orElse: () => player.state.output.audioDevices.first,
      );
      await player.setAudioDevice(match);
    } catch (e) {}
  }

  Future<void> configureHardwareExclusive(bool exclusive) async {
    try {
      await player.setAudioExclusive(exclusive);
    } catch (e) {}
  }

  // --- Playback Controls ---

  Future<void> updateMediaSessionMetadata({
    required String title,
    required String artist,
    required String album,
    String? artPath,
    Duration? duration,
    bool isFavorite = false,
    bool forceFresh = false,
  }) async {
    final policy = _interruptionPolicy;
    final metadataKey = Object.hash(
      title,
      artist,
      album,
      artPath,
      duration,
      isFavorite,
      policy,
    ).toString();
    if (!forceFresh &&
        (metadataKey == _publishedMediaMetadataKey ||
            metadataKey == _pendingMediaMetadataKey)) {
      return;
    }

    final generation = ++_mediaMetadataGeneration;
    _pendingMediaMetadataKey = metadataKey;
    var resolvedArtPath = _lastArtPath;
    var resolvedArtwork = _lastArtwork;

    if (forceFresh || artPath != _lastArtPath) {
      if (artPath != null && artPath.isNotEmpty) {
        if (artPath.startsWith('http://') || artPath.startsWith('https://')) {
          resolvedArtPath = artPath;
          resolvedArtwork = MediaSessionArtwork.uri(Uri.parse(artPath));
        } else {
          try {
            final file = File(artPath);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              final ext = artPath.split('.').last.toLowerCase();
              final mimeType = switch (ext) {
                'png' => 'image/png',
                'webp' => 'image/webp',
                'gif' => 'image/gif',
                'bmp' => 'image/bmp',
                _ => 'image/jpeg',
              };
              resolvedArtPath = artPath;
              resolvedArtwork = MediaSessionArtwork.custom(
                CoverArt(bytes: bytes, mimeType: mimeType),
              );
            } else {
              resolvedArtPath = null;
              resolvedArtwork = MediaSessionArtwork.embedded;
            }
          } catch (_) {
            resolvedArtPath = null;
            resolvedArtwork = MediaSessionArtwork.embedded;
          }
        }
      } else {
        resolvedArtPath = null;
        resolvedArtwork = MediaSessionArtwork.embedded;
      }
    }

    // Ignore a slow artwork result when a newer track has already started.
    if (generation != _mediaMetadataGeneration) return;
    // A crossfade swap may be moving the session between players.
    await transitionDirector.sessionReady;
    if (generation != _mediaMetadataGeneration) return;

    try {
      await player.setMediaSession(
        MediaSession(
          title: title,
          artist: artist,
          album: album,
          artwork: resolvedArtwork,
          duration: duration,
          isFavorite: isFavorite,
          appName: 'Looper Player',
          desktopEntry: 'looper_player',
          autoApplyPlaylistNavigation: false,
          actions: _sessionActions,
          // Read now, not before the artwork loaded: a policy change may
          // have landed meanwhile.
          interruptionPolicy: _interruptionPolicy,
        ),
      );
      if (generation == _mediaMetadataGeneration) {
        _lastArtPath = resolvedArtPath;
        _lastArtwork = resolvedArtwork;
        _publishedMediaMetadataKey = metadataKey;
      }
    } catch (error) {
      LoggerHelper.write(
        'AudioService: Failed to update media-session metadata',
        error,
      );
    } finally {
      if (generation == _mediaMetadataGeneration) {
        _pendingMediaMetadataKey = null;
      }
    }
  }

  Future<void> play(
    String path, {
    Map<String, dynamic>? metadata,
    bool play = true,
    List<double>? equalizerGains,
    bool? equalizerEnabled,
    String? customFilter,
    InterruptionPolicy interruptionPolicy = InterruptionPolicy.pauseAndResume,
  }) async {
    LoggerHelper.write(
      'AudioService: play() requested for path: ${path.split('?').first}, title: ${metadata?['title']}, play: $play',
    );
    if (equalizerGains != null) {
      _lastEqualizerGains = equalizerGains;
    }
    if (equalizerEnabled != null) {
      _equalizerEnabled = equalizerEnabled;
    }
    if (customFilter != null) {
      _customFilterString = customFilter;
    }

    _interruptionPolicy = interruptionPolicy;

    // Signal that we want EQ applied once FILE_LOADED fires.
    // This replaces the post-open() immediate call that always raced
    // against an empty playlist.
    _pendingEqApply = _lastEqualizerGains != null;
    _filtersInitialized = false; // Reset so deferred apply does a full rewrite

    final artPath = metadata?['artPath']?.toString();
    final String title = metadata?['title']?.toString() ?? 'Unknown Title';
    final String artist =
        metadata?['artist']?.toString() ?? currentL10n().unknownArtist;
    final String album =
        metadata?['album']?.toString() ?? currentL10n().unknownAlbum;
    final Duration? duration = metadata?['duration'] != null
        ? Duration(
            milliseconds:
                int.tryParse(metadata?['duration']?.toString() ?? '0') ?? 0,
          )
        : null;

    await updateMediaSessionMetadata(
      title: title,
      artist: artist,
      album: album,
      artPath: artPath,
      duration: duration,
      forceFresh: true,
    );

    final media = Media(
      path,
      extras: {
        'title': title,
        'artist': artist,
        'album': album,
        'artPath': artPath,
        'duration': metadata?['duration']?.toString(),
      },
    );

    // Native prefetch enqueuing will occur natively at the player level.
    // EQ is now applied via the playlist stream listener (deferred to FILE_LOADED)
    // so we do NOT call setEqualizerGains() here — that would race the empty playlist.
    await player.open(media, play: play);
    if (play && !player.state.playback.playing) {
      await player.play();
    }
  }

  Future<void> pause() async {
    LoggerHelper.write('AudioService: pause() requested');
    await player.pause();
  }

  Future<void> resume() async {
    LoggerHelper.write('AudioService: resume() requested');
    await player.play();
    await transitionDirector.sessionReady;
    final session = player.state.settings.mediaSession;
    if (session != null) {
      await player.setMediaSession(session);
    }
  }

  Future<void> seek(Duration duration) async {
    LoggerHelper.write('AudioService: seek() requested to position: $duration');
    // mpv resets the lavfi graph on seek, which clears the reverb tail.
    await player.seek(duration);
  }

  Future<void> stop() async {
    LoggerHelper.write('AudioService: stop() requested');
    await player.stop();
  }

  void dispose() {
    _liveEqThrottleTimer?.cancel();
    transitionDirector.dispose();
    _playerA.dispose();
    _playerB.dispose();
  }

  // --- Advanced DSP Settings Pipeline ---

  bool _filtersInitialized = false;

  // ── SoX resampler filter string (injected last in every customFilters list)
  // Placed last so it is the final stage before the AO — ensuring the output
  // rate conversion (when needed) uses SoX 28-bit sinc with TPDF dither.
  // AudioEffects.custom is the sole writer of mpv's `af` property, so this
  // is the correct place for any persistent base filter.
  static const String _soxrFilter =
      '@aek_soxr:lavfi-aresample=resampler=soxr:precision=28:dither_method=triangular_hp';
  static const String _swrFilter =
      '@aek_soxr:lavfi-aresample=resampler=swr:dither_method=triangular';

  Future<Map<String, String>> getAudioOutputCapabilities() async {
    final Map<String, String> capabilities = {};
    try {
      capabilities['Active Codec'] =
          await player.getRawProperty('audio-codec-name') ?? 'N/A';
    } catch (_) {}
    try {
      capabilities['Output Device'] =
          await player.getRawProperty('audio-device') ?? 'Default';
    } catch (_) {}
    try {
      final String? format = await player.getRawProperty(
        'audio-out-detected-format',
      );
      capabilities['Output Format'] = format ?? 'N/A';
    } catch (_) {}
    try {
      final String? sampleRate = await player.getRawProperty(
        'audio-out-detected-samplerate',
      );
      capabilities['Output Sample Rate'] = sampleRate != null
          ? '$sampleRate Hz'
          : 'N/A';
    } catch (_) {}
    try {
      final String? channels = await player.getRawProperty(
        'audio-out-detected-channels',
      );
      capabilities['Output Channels'] = channels ?? 'N/A';
    } catch (_) {}
    try {
      final String? sampleRate = await player.getRawProperty(
        'audio-params/samplerate',
      );
      capabilities['Source Sample Rate'] = sampleRate != null
          ? '$sampleRate Hz'
          : 'N/A';
    } catch (_) {}
    try {
      final String? format = await player.getRawProperty('audio-params/format');
      capabilities['Source Format'] = format ?? 'N/A';
    } catch (_) {}
    try {
      final String? channels = await player.getRawProperty(
        'audio-params/channel-count',
      );
      capabilities['Source Channels'] = channels ?? 'N/A';
    } catch (_) {}
    try {
      capabilities['Resampler Filter'] = _resolvedResamplerFilter ?? 'None';
    } catch (_) {}
    return capabilities;
  }
}
