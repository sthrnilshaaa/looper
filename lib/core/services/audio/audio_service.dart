import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'dart:math' as math;
import '../../utils/logger_helper.dart';
import 'package:looper_player/core/utils/l10n.dart';
part 'player_setup.dart';

class AudioService {
  late final Player player;
  List<double>? _lastEqualizerGains;
  bool _equalizerEnabled = false;
  String? _customFilterString;
  String? _lastArtPath;
  MediaSessionArtwork _lastArtwork = MediaSessionArtwork.embedded;
  String? _publishedMediaMetadataKey;
  String? _pendingMediaMetadataKey;
  int _mediaMetadataGeneration = 0;
  InterruptionPolicy _interruptionPolicy = InterruptionPolicy.pauseAndResume;

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
    LoggerHelper.write('AudioService: Constructing Player...');
    player = Player();
    ready = _initPlayer();

    // ── EQ deferred-apply on FILE_LOADED ────────────────────────────────────────
    // `player.open()` sends a loadfile command and returns before mpv
    // fires FILE_LOADED. At that point `playlist.items` is still empty,
    // so calling `setEqualizerGains()` immediately after `open()` hits the
    // empty-guard and bails — the EQ is never applied.
    //
    // Fix: set `_pendingEqApply = true` before `open()`, then watch the
    // playlist stream. The first time items becomes non-empty (= FILE_LOADED
    // has fired and the filter chain is live) we apply the pending EQ.
    player.stream.playlist.listen((playlist) {
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

    _attachMediaSessionListeners();
  }

  Future<void> _initPlayer() async {
    LoggerHelper.write('AudioService: Initializing player properties...');
    // ponytail: Let native mpv engine negotiate audio format, buffer sizes, and readahead limits.
    // Overriding these manually (e.g. forcing float32 or 4s buffers) breaks playback and overflows
    // demuxer packet queues on budget devices.

    /*
    try {
      await player.setRawProperty('playback-time-update-interval', '0.015');
      LoggerHelper.write('AudioService: Set update interval to 15ms.');
    } catch (e) {
      LoggerHelper.write('AudioService: Failed to set raw property update interval.', e);
    }

    try {
      await player.setAudioFormat(Format.float32);
    } catch (e) {
      try {
        await player.setRawProperty('audio-format', 'float');
      } catch (_) {}
    }
    */

    try {
      await player.setRawProperty('volume-max', '150');
    } catch (e) {}

    try {
      await player.setRawProperty('audio-buffer', '0.2');
    } catch (e) {}

    try {
      await player.setRawProperty('audio-stream-silence', 'yes');
    } catch (e) {}

    try {
      await player.setRawProperty('demuxer-lavf-analyzeduration', '1.0');
    } catch (e) {}

    try {
      await player.setRawProperty('demuxer-lavf-probesize', '10000000');
    } catch (e) {}

    /*
    try {
      await player.setRawProperty('audio-buffer', '4.0');
    } catch (e) {}

    try {
      await player.setRawProperty('demuxer-readahead-secs', '20');
    } catch (e) {}

    try {
      await player.setRawProperty('audio-stream-silence', 'yes');
    } catch (e) {}

    try {
      await player.setRawProperty('gapless-audio', 'yes');
    } catch (e) {}

    try {
      await player.setRawProperty('audio-normalize-downmix', 'yes');
    } catch (e) {}

    try {
      await player.setRawProperty('replaygain-clip', 'yes');
    } catch (e) {}
    */

    try {
      await player.setRawProperty('audio-pitch-correction', 'no');
    } catch (e) {}

    try {
      await player.setRawProperty('hwdec', 'no');
    } catch (e) {}

    await _initMediaSession();
  }

  Future<void> _initMediaSession({
    InterruptionPolicy interruptionPolicy = InterruptionPolicy.pauseAndResume,
  }) async {
    _interruptionPolicy = interruptionPolicy;

    final current = player.state.mediaSession;
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
        actions: const {
          MediaAction.play,
          MediaAction.pause,
          MediaAction.playPause,
          MediaAction.stop,
          MediaAction.next,
          MediaAction.previous,
          MediaAction.seek,
          MediaAction.like,
          MediaAction.setShuffle,
          MediaAction.setRepeatMode,
        },
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
  }) async {
    try {
      final rgMode = mode == 1
          ? ReplayGain.track
          : (mode == 2 ? ReplayGain.album : ReplayGain.no);
      await player.setReplayGain(
        ReplayGainSettings(
          mode: rgMode,
          preamp: preamp,
          clip: true, // Limit peaks to prevent digital clipping
        ),
      );
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
      final activeTracks = player.state.tracks.where((t) => t.type == 'audio');
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
      return player.state.audioDevices
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
      final match = player.state.audioDevices.firstWhere(
        (d) => d.name == deviceName,
        orElse: () => player.state.audioDevices.first,
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
          actions: const {
            MediaAction.play,
            MediaAction.pause,
            MediaAction.playPause,
            MediaAction.next,
            MediaAction.previous,
            MediaAction.seek,
            MediaAction.like,
            MediaAction.setShuffle,
            MediaAction.setRepeatMode,
          },
          interruptionPolicy: policy,
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
      'AudioService: play() requested for path: $path, title: ${metadata?['title']}, play: $play',
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
    if (play && !player.state.playing) {
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
    final session = player.state.mediaSession;
    if (session != null) {
      await player.setMediaSession(session);
    }
  }

  Future<void> seek(Duration duration) async {
    LoggerHelper.write('AudioService: seek() requested to position: $duration');
    await player.seek(duration);
  }

  Future<void> stop() async {
    LoggerHelper.write('AudioService: stop() requested');
    await player.stop();
  }

  void dispose() {
    _liveEqThrottleTimer?.cancel();
    player.dispose();
  }

  // --- Advanced DSP Settings Pipeline ---

  bool _filtersInitialized = false;

  void _triggerThrottledEq(
    List<double> gains,
    bool enabled,
    String? customFilter,
  ) {
    _throttledGains = List<double>.from(gains);
    _throttledEnabled = enabled;
    _throttledCustomFilter = customFilter;
    if (_liveEqThrottleTimer == null || !_liveEqThrottleTimer!.isActive) {
      _liveEqThrottleTimer = Timer(const Duration(milliseconds: 100), () {
        _applyThrottledEq();
      });
    }
  }

  Future<void> _applyThrottledEq() async {
    if (_throttledGains == null) return;
    await setEqualizerGains(
      _throttledGains!,
      _throttledEnabled,
      customFilter: _throttledCustomFilter,
    );
  }

  Future<void> setLiveBandGain(int bandIndex, double gain) async {
    if (!_filtersInitialized || player.state.playlist.items.isEmpty) return;
    if (_lastEqualizerGains == null) return;
    _lastEqualizerGains![bandIndex] = gain;
    try {
      await player.updateAudioEffects((e) {
        final List<double> bandsFreq = [
          65,
          92,
          131,
          185,
          262,
          370,
          523,
          740,
          1000,
          1400,
          2000,
          2900,
          4100,
          5900,
          8300,
          11700,
          16600,
          20000,
        ];
        final List<double> bandsWidth = [
          20,
          30,
          40,
          60,
          80,
          110,
          160,
          220,
          300,
          420,
          600,
          850,
          1200,
          1750,
          2500,
          3500,
          5000,
          6000,
        ];
        final List<AnequalizerBand> bands = [];
        for (int i = 0; i < 18; i++) {
          final freq = bandsFreq[i];
          final width = bandsWidth[i];
          final currentGain = _lastEqualizerGains![i].clamp(-20.0, 20.0);
          bands.add(
            AnequalizerBand(
              frequency: freq,
              bandwidth: width,
              gain: currentGain,
              type: AnequalizerBandType.butterworth,
            ),
          );
        }
        final anequalizer = AnequalizerSettings(
          enabled: _equalizerEnabled,
        ).withBands(bands, channels: 2);
        return e.copyWith(
          superequalizer: const SuperequalizerSettings(enabled: false),
          anequalizer: anequalizer,
        );
      });
    } catch (_) {}
  }

  Future<void> setLivePreamp(double preamp) async {
    if (!_filtersInitialized || player.state.playlist.items.isEmpty) return;
    if (_lastEqualizerGains == null) return;
    _lastEqualizerGains![18] = preamp;
    try {
      await player.setVolumeGain(
        _equalizerEnabled ? preamp.clamp(-12.0, 12.0) : 0.0,
      );
    } catch (_) {}
  }

  Future<void> setLiveCompressor({
    double? threshold,
    double? ratio,
    double? attack,
    double? release,
  }) async {
    if (!_filtersInitialized || player.state.playlist.items.isEmpty) return;
    try {
      await player.updateAudioEffects((e) {
        final current =
            e.acompressor ?? const AcompressorSettings(enabled: true);
        double dBToMultiplier(double dB) =>
            math.pow(10.0, dB / 20.0).toDouble();
        return e.copyWith(
          acompressor: current.copyWith(
            threshold: threshold != null
                ? dBToMultiplier(threshold.clamp(-40.0, 0.0))
                : current.threshold,
            ratio: ratio ?? current.ratio,
            attack: attack ?? current.attack,
            release: release ?? current.release,
          ),
        );
      });
    } catch (e) {}
  }

  Future<void> setLiveBass(double gain) async {
    if (!_filtersInitialized || player.state.playlist.items.isEmpty) return;
    try {
      await player.updateAudioEffects((e) {
        final current = e.bass ?? const BassSettings(enabled: true, f: 100.0);
        return e.copyWith(bass: current.copyWith(g: gain.clamp(-10.0, 15.0)));
      });
    } catch (e) {}
  }

  Future<void> setLiveTreble(double gain) async {
    if (!_filtersInitialized || player.state.playlist.items.isEmpty) return;
    try {
      await player.updateAudioEffects((e) {
        final current =
            e.treble ?? const TrebleSettings(enabled: true, f: 8000.0);
        return e.copyWith(treble: current.copyWith(g: gain.clamp(-10.0, 15.0)));
      });
    } catch (e) {}
  }

  Future<void> setLiveStereoWidth(double m) async {
    if (!_filtersInitialized || player.state.playlist.items.isEmpty) return;
    try {
      await player.updateAudioEffects((e) {
        final current =
            e.extrastereo ?? const ExtrastereoSettings(enabled: true);
        return e.copyWith(
          extrastereo: current.copyWith(m: m.clamp(-10.0, 10.0)),
        );
      });
    } catch (e) {}
  }

  Future<void> setLiveCrossfeed(double strength) async {
    if (!_filtersInitialized || player.state.playlist.items.isEmpty) return;
    try {
      await player.updateAudioEffects((e) {
        final current = e.crossfeed ?? const CrossfeedSettings(enabled: true);
        return e.copyWith(
          crossfeed: current.copyWith(strength: strength.clamp(0.0, 1.0)),
        );
      });
    } catch (e) {}
  }

  Future<void> setLiveHighpass(double f) async {
    if (!_filtersInitialized || player.state.playlist.items.isEmpty) return;
    try {
      await player.updateAudioEffects((e) {
        final current = e.highpass ?? const HighpassSettings(enabled: true);
        return e.copyWith(highpass: current.copyWith(f: f.clamp(100.0, 300.0)));
      });
    } catch (e) {}
  }

  Future<void> setLiveLowpass(double f) async {
    if (!_filtersInitialized || player.state.playlist.items.isEmpty) return;
    try {
      await player.updateAudioEffects((e) {
        final current = e.lowpass ?? const LowpassSettings(enabled: true);
        return e.copyWith(
          lowpass: current.copyWith(f: f.clamp(3000.0, 6000.0)),
        );
      });
    } catch (e) {}
  }

  // ── SoX resampler filter string (injected last in every customFilters list)
  // Placed last so it is the final stage before the AO — ensuring the output
  // rate conversion (when needed) uses SoX 28-bit sinc with TPDF dither.
  // AudioEffects.custom is the sole writer of mpv's `af` property, so this
  // is the correct place for any persistent base filter.
  static const String _soxrFilter =
      '@aek_soxr:lavfi-aresample=resampler=soxr:precision=28:dither_method=triangular_hp';
  static const String _swrFilter =
      '@aek_soxr:lavfi-aresample=resampler=swr:dither_method=triangular';

  Future<void> setEqualizerGains(
    List<double> gains,
    bool enabled, {
    String? customFilter,
  }) async {
    _liveEqThrottleTimer?.cancel();
    _lastEqualizerGains = gains;
    _equalizerEnabled = enabled;
    _customFilterString = customFilter;

    if (player.state.playlist.items.isEmpty) {
      // FILE_LOADED hasn't fired yet — the playlist stream listener will
      // apply EQ once items populate. Mark _pendingEqApply so it triggers.

      _pendingEqApply = true;
      _filtersInitialized = false;
      return;
    }

    // Helper conversion dB -> ratio multiplier (e.g. 10^(dB/20))
    double dBToMultiplier(double dB) => math.pow(10.0, dB / 20.0).toDouble();

    // 1. 18-band anequalizer settings
    final List<double> bandsFreq = [
      65,
      92,
      131,
      185,
      262,
      370,
      523,
      740,
      1000,
      1400,
      2000,
      2900,
      4100,
      5900,
      8300,
      11700,
      16600,
      20000,
    ];
    final List<double> bandsWidth = [
      20,
      30,
      40,
      60,
      80,
      110,
      160,
      220,
      300,
      420,
      600,
      850,
      1200,
      1750,
      2500,
      3500,
      5000,
      6000,
    ];

    final List<AnequalizerBand> bands = [];
    if (enabled) {
      for (int i = 0; i < 18; i++) {
        final freq = bandsFreq[i];
        final width = bandsWidth[i];
        final gain = i < gains.length ? gains[i].clamp(-20.0, 20.0) : 0.0;
        bands.add(
          AnequalizerBand(
            frequency: freq,
            bandwidth: width,
            gain: gain,
            type: AnequalizerBandType.butterworth,
          ),
        );
      }
    }

    final anequalizer = AnequalizerSettings(
      enabled: enabled,
    ).withBands(bands, channels: 2);

    // 2. Dynamic Range Compressor
    final bool compEnabled =
        enabled && (gains.length > 23 ? gains[23] == 1.0 : false);
    final compressor = compEnabled
        ? AcompressorSettings(
            enabled: true,
            threshold: gains.length > 24
                ? dBToMultiplier(gains[24].clamp(-40.0, 0.0))
                : 0.125,
            ratio: gains.length > 25 ? gains[25].clamp(1.0, 20.0) : 2.0,
            attack: gains.length > 26 ? gains[26].clamp(0.01, 2000.0) : 20.0,
            release: gains.length > 27 ? gains[27].clamp(0.01, 9000.0) : 250.0,
          )
        : null;

    // 3. Loudness Normalization
    final bool loudnormEnabled =
        enabled && (gains.length > 28 ? gains[28] == 1.0 : false);
    final loudnorm = loudnormEnabled
        ? LoudnormSettings(
            enabled: true,
            I: gains.length > 29 ? gains[29].clamp(-70.0, -5.0) : -24.0,
            LRA: 11.0,
            TP: -1.5,
          )
        : null;

    // 4. Headphone Crossfeed
    final bool crossfeedEnabled =
        enabled && (gains.length > 21 ? gains[21] == 1.0 : false);
    final crossfeed = crossfeedEnabled
        ? CrossfeedSettings(
            enabled: true,
            strength: gains.length > 22 ? gains[22].clamp(0.0, 1.0) : 0.2,
          )
        : null;

    // 5. Stereo Width Expansion
    final bool widthEnabled =
        enabled && (gains.length > 30 ? gains[30] == 1.0 : false);
    final extrastereo = widthEnabled
        ? ExtrastereoSettings(
            enabled: true,
            m: gains.length > 31 ? gains[31].clamp(-10.0, 10.0) : 2.5,
          )
        : null;

    // 6. Bass & Treble tone shelving
    final bool shelvingEnabled =
        enabled && (gains.length > 44 ? gains[44] == 1.0 : true);
    final double bassGain = shelvingEnabled
        ? (gains.length > 32 ? gains[32] : 0.0)
        : 0.0;
    final double trebleGain = shelvingEnabled
        ? (gains.length > 33 ? gains[33] : 0.0)
        : 0.0;
    final bass = shelvingEnabled
        ? BassSettings(enabled: true, g: bassGain.clamp(-10.0, 15.0), f: 100.0)
        : null;
    final treble = shelvingEnabled
        ? TrebleSettings(
            enabled: true,
            g: trebleGain.clamp(-10.0, 15.0),
            f: 8000.0,
          )
        : null;

    // 7. Silence Trim
    final bool trimEnabled =
        enabled && (gains.length > 19 ? gains[19] == 1.0 : false);
    final silenceremove = trimEnabled
        ? SilenceremoveSettings(
            enabled: true,
            start_periods: 1,
            start_threshold: gains.length > 20
                ? dBToMultiplier(gains[20].clamp(-60.0, -30.0))
                : 0.003,
            stop_periods: 1,
            stop_threshold: gains.length > 20
                ? dBToMultiplier(gains[20].clamp(-60.0, -30.0))
                : 0.003,
          )
        : null;

    // 8. Lofi (acrusher + lowpass)
    final bool lofiEnabled =
        enabled && (gains.length > 41 ? gains[41] == 1.0 : false);
    final acrusher = lofiEnabled
        ? AcrusherSettings(enabled: true, bits: 8.0, samples: 4.0, mix: 0.5)
        : null;

    // 9. Speech Enhancement Filter (highpass + lowpass)
    final bool speechEnabled =
        enabled && (gains.length > 38 ? gains[38] == 1.0 : false);
    final double hpCutoff = gains.length > 39
        ? gains[39].clamp(100.0, 300.0)
        : 150.0;
    final double lpCutoff = gains.length > 40
        ? gains[40].clamp(3000.0, 6000.0)
        : 4000.0;

    final highpass = speechEnabled
        ? HighpassSettings(enabled: true, f: hpCutoff)
        : null;

    // Merge lowpass cutoff between Lofi and Speech
    final LowpassSettings? lowpass;
    if (lofiEnabled) {
      lowpass = const LowpassSettings(enabled: true, f: 3000.0);
    } else if (speechEnabled) {
      lowpass = LowpassSettings(enabled: true, f: lpCutoff);
    } else {
      lowpass = null;
    }

    // 10. Reverb (aecho)
    final bool reverbEnabled =
        enabled && (gains.length > 42 ? gains[42] == 1.0 : false);
    final aecho = reverbEnabled
        ? AechoSettings(
            enabled: true,
            delays: '40|60',
            decays: '0.4|0.3',
            in_gain: 0.8,
            out_gain: 0.5,
          )
        : null;

    // 11. Surround
    final bool surroundEnabled =
        enabled && (gains.length > 43 ? gains[43] == 1.0 : false);
    final surround = surroundEnabled ? SurroundSettings(enabled: true) : null;

    AudioEffects buildEffects() {
      final List<String> finalCustomFilters = [];
      if (customFilter != null && customFilter.trim().isNotEmpty) {
        finalCustomFilters.add(customFilter.trim());
      }
      return AudioEffects(
        custom: finalCustomFilters,
        superequalizer: const SuperequalizerSettings(enabled: false),
        anequalizer: anequalizer,
        acompressor: compressor,
        loudnorm: loudnorm,
        crossfeed: crossfeed,
        extrastereo: extrastereo,
        bass: bass,
        treble: treble,
        silenceremove: silenceremove,
        acrusher: acrusher,
        lowpass: lowpass,
        highpass: highpass,
        aecho: aecho,
        surround: surround,
      );
    }

    bool success = false;
    try {
      final double preamp = gains.length > 18
          ? gains[18].clamp(-12.0, 12.0)
          : 0.0;
      await player.setVolumeGain(enabled ? preamp : 0.0);
      await player.setAudioEffects(buildEffects());
      _resolvedResamplerFilter = 'none';
      _resamplerProbed = true;
      success = true;
    } catch (e) {
      debugPrint("Failed to set audio effects: $e");
    }

    if (success) {
      _filtersInitialized = true;
      // Rubberband Tempo and Pitch Shift (gain index 34-35) - keep these working even if master EQ is disabled
      final bool pitchTempoEnabled = gains.length > 45
          ? gains[45] == 1.0
          : true;
      final double pitch = pitchTempoEnabled
          ? (gains.length > 34 ? gains[34].clamp(0.5, 2.0) : 1.0)
          : 1.0;
      final double tempo = pitchTempoEnabled
          ? (gains.length > 35 ? gains[35].clamp(0.5, 3.0) : 1.0)
          : 1.0;
      try {
        await player.setPitch(pitch);
        await player.setRate(tempo);

        // ReplayGain (gain index 36-37)
        final int rgMode = gains.length > 36 ? gains[36].toInt() : 0;
        final double rgPreamp = gains.length > 37 ? gains[37] : 0.0;
        await configureReplayGain(mode: rgMode, preamp: rgPreamp);
      } catch (e) {}
    }
  }

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
