import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:looper_player/features/playback/domain/playback_queue.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:looper_player/core/utils/logger_helper.dart';
import 'package:looper_player/core/services/audio/android_audio_focus_manager.dart';
import 'package:looper_player/core/services/storage/media_store_write_service.dart';
import 'package:looper_player/features/playback/presentation/providers/lyrics/lyrics_search_provider.dart';
import 'package:looper_player/features/playback/domain/lyric_models.dart';
import 'package:looper_player/features/playback/domain/volume_fader.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/core/providers/providers.dart';
import 'package:looper_player/features/library/data/scanner/scanner.dart';
import 'package:looper_player/features/playback/data/lyrics_cache.dart';
import 'package:looper_player/features/playback/data/lyrics_fetcher.dart';
import 'package:window_manager/window_manager.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/features/playback/presentation/providers/lyrics/lyrics_notifier.dart';
import 'package:looper_player/features/playback/presentation/providers/equalizer/equalizer_notifier.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:isar_community/isar.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:looper_player/core/utils/l10n.dart';

part 'playback_notifier.g.dart';
part 'playback_state.dart';
part 'listen_tracking.dart';
part 'maintenance.dart';

@Riverpod(keepAlive: true)
class Playback extends _$Playback {
  late final Player player;
  final PlaybackQueue _queue = PlaybackQueue();
  List<Song> get _playlist => _queue.songs;
  int get _currentIndex => _queue.currentIndex;

  void _publishQueue() {
    state = state.copyWith(
      queue: _queue.songs,
      queueEntryIds: _queue.entries.map((entry) => entry.id).toList(),
      manualQueueEntryIds: _queue.pendingManual
          .map((entry) => entry.id)
          .toSet(),
      currentQueueIndex: _currentIndex,
    );
  }

  bool _isTransitioning = false;
  int _activeCrossfadeId = 0;
  Timer? _silenceTimer;
  Timer? _songCompletionTimer;
  int _lastWidgetPositionUpdate = 0;
  // Separate, much coarser throttle for the isar.songs.put() progress
  // write - see the position-stream listener in _init() for why this is
  // decoupled from _lastWidgetPositionUpdate.
  int _lastProgressSaveCheckpoint = 0;
  static const int _progressSaveIntervalMs = 20000;
  DateTime _lastSeekTime = DateTime.fromMillisecondsSinceEpoch(0);
  // A track end that arrived while play() was still loading a song. mpv
  // flips `completed` back to false on START_FILE, so a `true` seen after
  // that reset belongs to the new track (a song only a second or two long
  // can end before play() finishes) and is replayed once the load settles.
  bool _pendingCompletion = false;
  bool _completedResetSinceLoad = true;
  bool _pausedForRouteChange = false;
  // When mpv_audio_kit last paused us on the OS's behalf (see
  // _onRemotePause) - lets onBecomingNoisy tell that the pause it raced
  // was the route change, whichever of the two arrived first.
  DateTime _lastRemotePauseAt = DateTime.fromMillisecondsSinceEpoch(0);
  // Where a Stop left off. mpv's stop unloads the file, so the next resume
  // has to reopen the song and seek back here.
  Duration? _resumePositionAfterStop;
  // Play/pause/stop fade gain, multiplied into the user volume by
  // _applyVolume. Kept separate from state.volume so a fade never has to
  // remember what to restore.
  late final VolumeFader _fader = VolumeFader((_) => _applyVolume());
  final List<StreamSubscription> _subscriptions = [];

  // --- Real listening-time tracking (Looper Analyze) ---------------------
  // Wall-clock time actually spent with mpv reporting `playing: true` for
  // the current song, NOT `playCount * duration`. See _pauseListenSegment/
  // _flushListenedTime below.
  DateTime? _listenSegmentStart;
  int _pendingListenedMs = 0;
  int? _activePlayEventId;
  String? _activeListenSongPath;
  DateTime _lastListenCheckpoint = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  PlaybackState build() {
    ref.onDispose(_disposePlayback);
    if (Platform.isAndroid) {
      ref.read(androidAudioFocusManagerProvider);
    }
    player = ref.read(audioServiceProvider).player;
    final audioSvc = ref.read(audioServiceProvider);
    audioSvc.onNext = skipNext;
    audioSvc.onPrevious = skipPrevious;
    audioSvc.onFavoriteToggle = toggleFavorite;
    // mpv_audio_kit has already applied every command below to mpv by the
    // time it reaches us (see AudioService's callback docs), so these only
    // bring app state in line - they must never re-toggle.
    audioSvc.onSeekApplied = _onRemoteSeek;
    audioSvc.onShuffleCommand = _onRemoteShuffle;
    audioSvc.onRepeatCommand = _onRemoteRepeat;
    audioSvc.onPlay = _onRemotePlay;
    audioSvc.onPause = _onRemotePause;
    audioSvc.onPlayPause = _onRemotePlayPause;
    audioSvc.onStop = _onRemoteStop;
    _init();
    _initWidgetChannel();
    ref.listen<LyricsState>(lyricsProvider, (previous, next) {
      if (next.songId == state.currentSong?.id && !next.isLoading) {
        _updateWidgetState();
      }
    });
    ref.listen<AppSettings>(settingsProvider, (previous, next) {
      if (previous?.audioFocus != next.audioFocus ||
          previous?.resumeAfterCall != next.resumeAfterCall ||
          previous?.resumeOnBluetoothConnect != next.resumeOnBluetoothConnect) {
        // While paused, keep auto-resume disarmed (see
        // _disarmAutoResumeAfterFocusGain) - toggling a setting mustn't
        // re-arm it behind a deliberate pause.
        final policy = next.audioFocus && !state.isPlaying
            ? InterruptionPolicy.pauseOnly
            : _getInterruptionPolicy();
        ref.read(audioServiceProvider).applyAudioFocusPolicy(policy);
        if (Platform.isAndroid) {
          ref.read(androidAudioFocusManagerProvider).syncSettings();
        }
      }
      if (previous?.enableAudioCache != next.enableAudioCache ||
          previous?.audioCacheSizeMB != next.audioCacheSizeMB ||
          previous?.audioCacheSecs != next.audioCacheSecs ||
          previous?.audioBackCacheSizeMB != next.audioBackCacheSizeMB) {
        ref
            .read(audioServiceProvider)
            .configureCache(
              enabled: next.enableAudioCache,
              maxBytes: next.audioCacheSizeMB * 1024 * 1024,
              cacheSecs: next.audioCacheSecs,
              backBytes: next.audioBackCacheSizeMB * 1024 * 1024,
            );
      }
      if (previous?.exclusiveHardwareMode != next.exclusiveHardwareMode) {
        ref
            .read(audioServiceProvider)
            .configureHardwareExclusive(next.exclusiveHardwareMode);
      }
      if (previous?.stopOnTaskRemoved != next.stopOnTaskRemoved) {
        ref
            .read(audioServiceProvider)
            .setStopOnTaskRemoved(next.stopOnTaskRemoved);
      }
    });
    return PlaybackState();
  }

  void updateNotification({bool forceFresh = false}) {
    _updateNotification(forceFresh: forceFresh);
  }

  void _updateNotification({bool forceFresh = false}) {
    final song = state.currentSong;
    if (song != null) {
      final audioSvc = ref.read(audioServiceProvider);
      audioSvc.updateMediaSessionMetadata(
        title: song.title,
        artist: song.artist ?? currentL10n().unknownArtist,
        album: song.album ?? currentL10n().unknownAlbum,
        artPath: song.artPath,
        duration: song.duration != null
            ? Duration(milliseconds: song.duration!)
            : null,
        isFavorite: song.isFavorite,
        forceFresh: forceFresh,
      );
    }
    _updateWidgetState();
  }

  Future<void> _init() async {
    _subscriptions.add(
      player.stream.error.listen((err) {
        LoggerHelper.write('Mpv Player Error: $err');
      }),
    );

    _subscriptions.add(
      player.stream.log.listen((entry) {
        LoggerHelper.write('Mpv Player Log: $entry');
      }),
    );

    _subscriptions.add(
      player.stream.internalLog.listen((entry) {
        LoggerHelper.write('Mpv Player InternalLog: $entry');
      }),
    );

    _subscriptions.add(
      player.stream.playing.listen((playing) {
        // Safety net: a faded pause leaves the fade gain at 0, so if mpv
        // starts playing through any path that didn't fade back in
        // (plugin auto-resume, repeat-one, ...) it would play silently.
        // Only while the fader is idle - a running fade owns the gain.
        if (playing &&
            player.state.playWhenReady &&
            !_fader.isFading &&
            _fader.factor < 1.0) {
          _fadeIn();
        }
        if (state.isScrubbing) {
          return;
        }
        if (DateTime.now().difference(_lastSeekTime).inMilliseconds < 400) {
          return;
        }
        // While a track switch is in flight, the native player briefly
        // reports `playing: false` as it stops the old track and loads the
        // new one, before `_playDirect` explicitly sets isPlaying back to
        // true. Letting that transient `false` through made the play/pause
        // button's background (bound directly to isPlaying) flash on every
        // song change. `_isTransitioning` already tracks this window, so
        // just ignore spurious pauses inside it - a real `true` still comes
        // through once the new track actually starts.
        if (_isTransitioning && !playing) {
          return;
        }

        state = state.copyWith(isPlaying: playing);
        _updateNotification();
        if (!playing && ref.read(settingsProvider).persistQueue) {
          ref
              .read(settingsProvider.notifier)
              .updateLastPosition(state.position.inMilliseconds);
        }
        if (!playing) {
          unawaited(
            _savePerSongProgress(
              state.currentSong,
              state.position,
              state.duration,
            ),
          );
        }

        // Real listening-time tracking for Looper Analyze: `playing` here is
        // mpv's own core-idle-derived signal, so a segment only ever opens
        // while audio is genuinely advancing and closes the instant it
        // isn't (pause, seek-buffering, focus loss, EOF, ...).
        if (playing) {
          _startListenSegment();
        } else {
          _pauseListenSegment();
          unawaited(_flushListenedTime());
        }
      }),
    );

    _subscriptions.add(
      player.stream.position.listen((position) {
        if (!state.isScrubbing) {
          // seek() already set state.position to the seek target the
          // instant it was called, before the native player actually
          // finishes repositioning - for a brief window after that, this
          // stream can still emit one or more stale ticks reporting where
          // playback was *before* the seek (mpv hasn't caught up yet). Since
          // a real forward-playing tick can never report a position at or
          // before wherever we just explicitly moved to, treat one that does
          // as stale and drop it instead of letting it overwrite the seek -
          // otherwise the UI (and specifically the lyrics screen's active-
          // line highlight, which reacts to this same position) flickers
          // back to the pre-seek spot for a moment, making a tap-to-seek on
          // a lyric line intermittently look like it did nothing.
          final withinSeekWindow =
              DateTime.now().difference(_lastSeekTime).inMilliseconds < 400;
          final isStaleAfterSeek =
              withinSeekWindow && position <= state.position;
          if (!isStaleAfterSeek) {
            state = state.copyWith(position: position);
          }
        }
        _checkAndUpdateLyrics();

        final now = DateTime.now().millisecondsSinceEpoch;
        // Widened from 2s to 5s: this only feeds the notification/queue
        // sync and the (usually unpinned - see _anyHomeWidgetPinned) home
        // screen widget, neither of which needs sub-5-second resolution.
        if (state.isPlaying && now - _lastWidgetPositionUpdate > 5000) {
          _lastWidgetPositionUpdate = now;
          _updateWidgetState();
          if (ref.read(settingsProvider).persistQueue) {
            ref
                .read(settingsProvider.notifier)
                .updateLastPosition(position.inMilliseconds);
          }
        }
        // Deliberately on its own, coarser (20s) throttle rather than
        // reusing the block above: this writes to Song via
        // isar.songs.put(), and the library list watches the *entire*
        // songs collection (library_notifier._watchSongs), so every write
        // here forces a full-library re-query + rebuild of every widget
        // watching libraryProvider's song list. Pause and song-change
        // already checkpoint the exact position (see the `playing`
        // listener above), so this periodic write is only crash insurance
        // and doesn't need second-level resolution.
        if (state.isPlaying &&
            now - _lastProgressSaveCheckpoint > _progressSaveIntervalMs) {
          _lastProgressSaveCheckpoint = now;
          unawaited(
            _savePerSongProgress(state.currentSong, position, state.duration),
          );
        }
        unawaited(_checkpointListenedTimeIfDue());
      }),
    );

    _subscriptions.add(
      player.stream.duration.listen((duration) {
        if (duration != Duration.zero) {
          state = state.copyWith(duration: duration);
        }
      }),
    );

    _subscriptions.add(
      player.stream.completed.listen((completed) {
        debugPrint("======== COMPLETED ========");
        debugPrint("completed = $completed");
        debugPrint("position  = ${player.state.position}");
        debugPrint("duration  = ${player.state.duration}");
        debugPrint("playlist completed = ${player.state.completed}");

        if (!completed) {
          _completedResetSinceLoad = true;
          return;
        }
        // The stream only emits on change, so every `true` here is a real
        // end of content - no time-based debounce needed. Mid-load, defer
        // it to play() instead of dropping it (a stale end of the outgoing
        // track never gets past the reset check).
        if (_isTransitioning) {
          if (_completedResetSinceLoad) _pendingCompletion = true;
          return;
        }
        _onTrackCompleted();
      }),
    );

    // Wait for settings to load
    await ref.read(settingsProvider.notifier).initialization;

    // Load last settings
    final settings = ref.read(settingsProvider);
    state = state.copyWith(
      volume: settings.volume,
      isShuffle: settings.shuffle,
      repeatMode: RepeatMode.values[settings.repeatMode],
    );
    _applyVolume();

    // Apply cache and hardware configurations
    final audioSvc = ref.read(audioServiceProvider);
    await audioSvc.applyAudioFocusPolicy(_getInterruptionPolicy());
    if (Platform.isAndroid) {
      ref.read(androidAudioFocusManagerProvider).syncSettings();
    }
    await audioSvc.configureCache(
      enabled: settings.enableAudioCache,
      maxBytes: settings.audioCacheSizeMB * 1024 * 1024,
      cacheSecs: settings.audioCacheSecs,
      backBytes: settings.audioBackCacheSizeMB * 1024 * 1024,
    );
    await audioSvc.configureHardwareExclusive(settings.exclusiveHardwareMode);
    await audioSvc.setStopOnTaskRemoved(settings.stopOnTaskRemoved);

    final savedSongIds = settings.lastQueueSongIds;
    final savedIndex = settings.lastQueueIndex;

    if (settings.persistQueue && savedSongIds.isNotEmpty) {
      final loadedSongs = await Future.wait(
        savedSongIds.map((id) => DbService.isar.songs.get(id)),
      );
      _queue.restore(
        loadedSongs,
        index: savedIndex,
        manualIndices: settings.lastQueueManualIndices,
        originalOrder: settings.lastQueueOriginalOrder,
      );
      _publishQueue();
      if (_queue.current != null) {
        final song = _queue.current!.song;
        state = state.copyWith(
          queue: List.from(_playlist),
          queueSourceKey: collectionKey(_queue.songs),
          currentSong: song,
          isRestoredSession: true,
          position: Duration(milliseconds: settings.lastPositionMs),
          duration: song.duration != null
              ? Duration(milliseconds: song.duration!)
              : Duration.zero,
        );
        ref.read(lyricsProvider.notifier).fetchForSong(song);
        ref.read(equalizerProvider.notifier).onSongChanged(song);
        _updateWidgetState();

        final initialPos = Duration(milliseconds: settings.lastPositionMs);
        final restoredEntryId = _queue.current?.id;
        Future.delayed(const Duration(milliseconds: 500), () async {
          if (_queue.current?.id != restoredEntryId ||
              state.currentSong?.path != song.path) {
            return;
          }
          await play(
            song,
            forceDisableCrossfade: true,
            play: settings.resumeOnStart,
            initialPosition: initialPos,
          );
        });
      }
    } else if (settings.persistQueue && settings.lastPlayedSongId != null) {
      final song = await DbService.isar.songs.get(settings.lastPlayedSongId!);
      if (song != null) {
        state = state.copyWith(
          currentSong: song,
          isRestoredSession: true,
          position: Duration(milliseconds: settings.lastPositionMs),
          duration: song.duration != null
              ? Duration(milliseconds: song.duration!)
              : Duration.zero,
        );
        ref.read(lyricsProvider.notifier).fetchForSong(song);
        ref.read(equalizerProvider.notifier).onSongChanged(song);
        _queue.load([song]);
        _publishQueue();
        _updateWidgetState(); // Sync initial song data with home screen widgets on launch

        final initialPos = Duration(milliseconds: settings.lastPositionMs);
        final restoredEntryId = _queue.current?.id;
        Future.delayed(const Duration(milliseconds: 500), () async {
          if (_queue.current?.id != restoredEntryId ||
              state.currentSong?.path != song.path) {
            return;
          }
          await play(
            song,
            forceDisableCrossfade: true,
            play: settings.resumeOnStart,
            initialPosition: initialPos,
          );
        });
      }
    } else {
      await ref
          .read(settingsProvider.notifier)
          .updateLastQueueState([], -1, null, positionMs: 0);
    }
  }

  Future<void> playAtIndex(int index) async {
    if (index < 0 || index >= _queue.entries.length) return;
    _queue.select(index);
    _publishQueue();
    await play(_queue.current!.song);
  }

  /// Starts a collection, or continues its current track without seeking.
  Future<void> playCollection(
    List<Song> songs, {
    bool shuffle = false,
    int? sourcePlaylistId,
  }) async {
    if (songs.isEmpty) return;
    if (shuffle && !state.isShuffle) await toggleShuffle();

    final currentIndex = songs.indexWhere(
      (song) => song.path == state.currentSong?.path,
    );
    _setPlaylist(
      songs,
      initialIndex: shuffle
          ? math.Random().nextInt(songs.length)
          : math.max(0, currentIndex),
      continueCurrent: !shuffle && currentIndex != -1,
      sourcePlaylistId: sourcePlaylistId,
    );
  }

  Future<void> toggleCollectionShuffle(
    List<Song> songs, {
    int? sourcePlaylistId,
  }) async {
    if (songs.isEmpty) return;
    // Only switches shuffle off for the collection that is actually playing
    // shuffled; anywhere else a tap starts this collection shuffled.
    if (state.isShuffle && state.queueSourceKey == collectionKey(songs)) {
      await toggleShuffle();
    } else {
      await playCollection(
        songs,
        shuffle: true,
        sourcePlaylistId: sourcePlaylistId,
      );
    }
  }

  void setPlaylist(
    List<Song> songs, {
    int initialIndex = 0,
    bool continueCurrent = false,
    int? sourcePlaylistId,
  }) {
    _setPlaylist(
      songs,
      initialIndex: initialIndex,
      continueCurrent: continueCurrent,
      sourcePlaylistId: sourcePlaylistId,
    );
  }

  void _setPlaylist(
    List<Song> songs, {
    int initialIndex = 0,
    bool continueCurrent = false,
    int? sourcePlaylistId,
  }) {
    _queue.load(songs, initialIndex: initialIndex, shuffle: state.isShuffle);
    _publishQueue();
    state = state.copyWith(queueSourceKey: collectionKey(songs));
    if (_playlist.isNotEmpty && _currentIndex != -1) {
      if (continueCurrent &&
          _playlist[_currentIndex].path == state.currentSong?.path) {
        unawaited(_saveQueueState());
        unawaited(_continueCollection(sourcePlaylistId));
      } else {
        play(_playlist[_currentIndex], sourcePlaylistId: sourcePlaylistId);
      }
    }
  }

  Future<void> _continueCollection(int? sourcePlaylistId) async {
    if (!state.isPlaying) await togglePlay();
    if (!state.isPlaying || sourcePlaylistId == null) return;
    await DbService.isar.writeTxn(() async {
      final playlist = await DbService.isar.playlists.get(sourcePlaylistId);
      if (playlist == null) return;
      playlist.lastPlayed = DateTime.now();
      await DbService.isar.playlists.put(playlist);
    });
  }

  /// [immediate] skips the wait for the UI position to catch up with the
  /// end - used when the end was deferred past a load and is long settled.
  void _onTrackCompleted({bool immediate = false}) {
    _isTransitioning = true;
    _songCompletionTimer?.cancel();

    void onSongFinished() {
      if (state.isSleepTimerActive && state.sleepTimerSongsRemaining != null) {
        final remaining = state.sleepTimerSongsRemaining! - 1;
        if (remaining <= 0) {
          state = state.copyWith(
            isSleepTimerActive: false,
            sleepTimerSongsRemaining: null,
            sleepTimerSongsInitial: null,
            sleepTimerDurationRemaining: null,
            sleepTimerDurationInitial: null,
          );
          unawaited(_pauseAtPlaybackEnd());
          return;
        } else {
          state = state.copyWith(sleepTimerSongsRemaining: remaining);
        }
      }

      if (state.repeatMode == RepeatMode.one) {
        _isTransitioning = false;
        player.seek(Duration.zero);
        ref.read(audioServiceProvider).resume();
      } else {
        _isTransitioning = true;
        skipNext(isManual: false);
      }
    }

    final remaining = state.duration - state.position;
    if (!immediate &&
        remaining.inMilliseconds > 0 &&
        remaining.inMilliseconds < 10000) {
      _songCompletionTimer = Timer(
        remaining + const Duration(milliseconds: 100),
        onSongFinished,
      );
    } else {
      onSongFinished();
    }
  }

  Future<void> play(
    Song song, {
    bool forceDisableCrossfade = false,
    bool play = true,
    Duration? initialPosition,
    bool blockDuringCall = true,
    int? sourcePlaylistId,
  }) async {
    _silenceTimer?.cancel();
    _songCompletionTimer?.cancel();
    _pausedForRouteChange = false;
    final settings = ref.read(settingsProvider);
    if (play && blockDuringCall && settings.audioFocus) {
      final onCall = await ref.read(audioServiceProvider).isOnCall();
      if (onCall) {
        _showErrorSnackBar(
          'Playback blocked: Cannot play music during an active call',
          (l10n) => l10n.activeCallCannotPlay,
        );
        return;
      }
    }

    final isUrl =
        song.path.startsWith('http://') || song.path.startsWith('https://');
    if (!isUrl) {
      await _requestStoragePermissions();
      final file = File(song.path);
      if (!await file.exists()) {
        _showErrorSnackBar(
          'File not found or inaccessible: ${song.title}',
          (l10n) => l10n.fileNotFoundOrInaccessible(song.title),
        );
        return;
      }
    }

    final crossfadeId = ++_activeCrossfadeId;
    _isTransitioning = true;
    _pendingCompletion = false;
    _completedResetSinceLoad = !player.state.completed;

    try {
      await _playDirect(
        song,
        crossfadeId,
        play: play,
        initialPosition: initialPosition,
        sourcePlaylistId: sourcePlaylistId,
      );
    } catch (e) {
      if (crossfadeId == _activeCrossfadeId) {
        try {
          await _playDirect(
            song,
            crossfadeId,
            play: play,
            initialPosition: initialPosition,
            sourcePlaylistId: sourcePlaylistId,
          );
        } catch (retryError, stack) {
          LoggerHelper.write(
            'Playback failed permanently for: ${song.path}',
            retryError,
            stack,
          );
          _showErrorSnackBar(
            'Playback failed: Unable to load or play "${song.title}". Please verify the file is not corrupted.',
            (l10n) => l10n.playbackFailedCorrupted(song.title),
          );
          rethrow;
        }
      } else {}
    } finally {
      if (crossfadeId == _activeCrossfadeId) {
        int attempts = 0;

        while (!_pendingCompletion &&
            (player.state.completed || (play && !state.isPlaying)) &&
            attempts < 40) {
          await Future.delayed(const Duration(milliseconds: 25));
          attempts++;
        }

        _isTransitioning = false;
        // The new song already ended while it was loading - advance now.
        if (_pendingCompletion && player.state.completed) {
          _pendingCompletion = false;
          _onTrackCompleted(immediate: true);
        }
      }
    }
  }

  Future<void> _playDirect(
    Song song,
    int crossfadeId, {
    bool play = true,
    Duration? initialPosition,
    int? sourcePlaylistId,
  }) async {
    // A new track is loading - close out whatever real listening-time
    // segment was accruing for the outgoing song before attribution moves
    // to this one.
    _pauseListenSegment();
    unawaited(_flushListenedTime());

    // Same idea for "Keep Song Progress" - save the outgoing song's position
    // (state.currentSong/state.position still refer to it, one line above
    // where they get overwritten below) before this song takes over.
    unawaited(
      _savePerSongProgress(state.currentSong, state.position, state.duration),
    );

    _lastWidgetLyricLine = '';
    ref.read(lyricsSearchQueryProvider.notifier).clear();
    state = state.copyWith(
      currentSong: song,
      duration: song.duration != null
          ? Duration(milliseconds: song.duration!)
          : Duration.zero,
      position: initialPosition ?? Duration.zero,
      isRestoredSession: initialPosition != null,
    );
    ref.read(lyricsProvider.notifier).fetchForSong(song);
    ref.read(equalizerProvider.notifier).onSongChanged(song);

    // Apply equalizer settings for the song
    final settings = ref.read(settingsProvider);
    final gains = ref.read(equalizerProvider).currentSongGains;
    final customFilter = ref.read(equalizerProvider).customFilterString;

    final metadata = {
      'title': song.title,
      'artist': song.artist ?? currentL10n().unknownArtist,
      'album': song.album ?? currentL10n().unknownAlbum,
      if (song.artPath != null) 'artPath': song.artPath!,
      if (song.duration != null) 'duration': song.duration!,
    };
    bool targetPlay = play;
    final int fadeLength = settings.fadePlayPauseStop
        ? settings.playPauseStopFadeLength
        : 0;
    final bool shouldFade = fadeLength > 0 && targetPlay;
    _resumePositionAfterStop = null;
    _fader.set(shouldFade ? 0.0 : 1.0);

    await ref
        .read(audioServiceProvider)
        .play(
          song.path,
          metadata: metadata,
          play: targetPlay,
          equalizerGains: gains,
          equalizerEnabled: settings.equalizerEnabled,
          customFilter: customFilter,
          interruptionPolicy: _getInterruptionPolicy(),
        );

    if (targetPlay) {
      state = state.copyWith(isPlaying: true);
      _updateNotification(forceFresh: true);
      // Note: audio focus itself is requested natively by mpv_audio_kit's own
      // MediaSession/InterruptionPolicy as soon as playback starts (it is the
      // sole focus owner - see AudioFocusController.kt). Never request focus
      // from app code as well: that opens a second, competing
      // AudioFocusRequest for the same app, which makes
      // Android immediately deliver a spurious focus-loss to mpv's listener
      // and pause playback right after it started.
    }

    if (shouldFade && crossfadeId == _activeCrossfadeId) {
      unawaited(_fader.fadeTo(1.0, Duration(milliseconds: fadeLength)));
    }

    if (crossfadeId != _activeCrossfadeId) return;

    _updateWidgetState(); // Update home screen widgets instantly with the new song metadata

    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      await windowManager.setTitle(
        'Looper Player - ${song.title} - ${song.artist ?? currentL10n().unknownArtist}',
      );
    }

    await DbService.isar.writeTxn(() async {
      final dbSong = await DbService.isar.songs
          .filter()
          .pathEqualTo(song.path)
          .findFirst();

      final songToUpdate = dbSong ?? song;
      if (play) {
        songToUpdate.lastPlayed = DateTime.now();
        if (sourcePlaylistId != null) {
          final playlist = await DbService.isar.playlists.get(sourcePlaylistId);
          if (playlist != null) {
            playlist.lastPlayed = songToUpdate.lastPlayed;
            await DbService.isar.playlists.put(playlist);
          }
        }
        songToUpdate.playCount++;
        _activePlayEventId = await _logPlayEvent(songToUpdate);
      } else {
        // Loaded but not actually starting playback (e.g. a paused restore)
        // - nothing "played" yet, so no play-event row to top up.
        _activePlayEventId = null;
      }
      // Real listening time now attributes to this song regardless of
      // `play`, so a later manual resume of a paused restore still counts
      // toward its Song.totalListenedMs even without a fresh play event.
      _activeListenSongPath = songToUpdate.path;
      _pendingListenedMs = 0;
      _lastListenCheckpoint = DateTime.now();

      if (dbSong != null) {
        song.id = dbSong.id;
        song.isFavorite = dbSong.isFavorite;
        song.playCount = dbSong.playCount;
        song.lastPlayed = dbSong.lastPlayed;
      } else {
        song.id = songToUpdate.id;
      }

      await DbService.isar.songs.put(songToUpdate);
    });

    if (settings.persistQueue) {
      await ref.read(settingsProvider.notifier).updateLastPlayedSong(song.id);
    }

    final hadQueue = _queue.entries.isNotEmpty;
    _queue.selectSong(song);
    _publishQueue();
    if (!hadQueue) {
      state = state.copyWith(queueSourceKey: collectionKey([song]));
    }
    _updateNotification();
    await _saveQueueState();

    // Explicit initialPosition (e.g. the "Persist Last Queue" app-restart
    // resume) always wins; otherwise fall back to this song's own saved
    // position when "Keep Song Progress" is on. A fresh DB read here since
    // the in-memory `song` may be a stale copy from a playlist built earlier.
    Duration? effectivePosition = initialPosition;
    if (effectivePosition == null && settings.keepSongProgress) {
      final dbSong = await DbService.isar.songs.get(song.id);
      final savedMs = dbSong?.lastPositionMs ?? song.lastPositionMs;
      if (savedMs > 0) {
        effectivePosition = Duration(milliseconds: savedMs);
      }
    }

    if (effectivePosition != null && effectivePosition > Duration.zero) {
      int attempts = 0;
      while (player.state.duration == Duration.zero && attempts < 40) {
        await Future.delayed(const Duration(milliseconds: 50));
        attempts++;
      }
      // Defensively clamp against a stale/corrupt saved value outliving the
      // song's actual duration (e.g. re-tagged file) rather than seeking
      // past the end.
      final dur = player.state.duration;
      final target = (dur > Duration.zero && effectivePosition > dur)
          ? Duration.zero
          : effectivePosition;
      if (target > Duration.zero) {
        await seek(target);
      }
    }
  }

  void addToQueue(Song song) {
    _queue.add(song);
    _publishQueue();
    unawaited(_saveQueueState());
  }

  void addNext(Song song) {
    _queue.add(song, next: true);
    _publishQueue();
    unawaited(_saveQueueState());
  }

  /// Ends the current segment (if any) and folds its elapsed wall-clock time
  /// into the pending total for whichever song is currently attributed.
  /// Doesn't touch the DB itself - pair with [_flushListenedTime].
  void _pauseListenSegment() {
    final start = _listenSegmentStart;
    if (start == null) return;
    _pendingListenedMs += DateTime.now().difference(start).inMilliseconds;
    _listenSegmentStart = null;
  }

  /// Persists whatever real listened time has accumulated since the last
  /// flush onto both the song's running [Song.totalListenedMs] total and
  /// the currently active [PlayEvent.listenedMs] (if this segment started
  /// from a genuine "play", not just a paused restore). Safe to call often -
  /// it's a no-op once there's nothing pending.
  Future<void> _flushListenedTime() async {
    final ms = _pendingListenedMs;
    final path = _activeListenSongPath;
    if (ms <= 0 || path == null) return;
    _pendingListenedMs = 0;
    final eventId = _activePlayEventId;

    try {
      await DbService.isar.writeTxn(() async {
        final dbSong = await DbService.isar.songs
            .filter()
            .pathEqualTo(path)
            .findFirst();
        if (dbSong != null) {
          dbSong.totalListenedMs += ms;
          await DbService.isar.songs.put(dbSong);
        }
        if (eventId != null) {
          final event = await DbService.isar.playEvents.get(eventId);
          if (event != null) {
            event.listenedMs += ms;
            await DbService.isar.playEvents.put(event);
          }
        }
      });
    } catch (e) {
      LoggerHelper.write('Playback._flushListenedTime failed', e);
    }
  }

  /// Checkpoints an in-progress segment during long uninterrupted playback,
  /// so an app kill mid-song loses at most ~[_listenCheckpointInterval] of
  /// listened time instead of the whole session. Called from the position
  /// stream tick alongside the existing widget/queue-persistence throttle.
  static const _listenCheckpointInterval = Duration(seconds: 20);

  Future<void> playFromFile(String path) async {
    // Check if song exists in DB
    final songs = await DbService.isar.songs
        .filter()
        .pathEqualTo(path)
        .findAll();
    Song? song = songs.isEmpty ? null : songs.first;

    if (song == null) {
      // Create a temporary song object from metadata
      final metadata = await MetadataGod.readMetadata(file: path);
      // Extract and save artwork
      String? artPath;
      if (metadata.picture != null) {
        final scanner =
            LibraryScanner(); // Need to save it using the same logic
        artPath = await scanner.saveAlbumArt(
          metadata.album ?? 'unknown',
          metadata.picture!.data,
        );
      }

      song = Song()
        ..path = path
        ..title = metadata.title ?? path.split('/').last
        ..artist = metadata.artist
        ..album = metadata.album
        ..duration = metadata.durationMs?.toInt()
        ..artPath = artPath;
    }

    await play(song);
  }

  Future<void> stop() async {
    _silenceTimer?.cancel();
    _songCompletionTimer?.cancel();
    _pauseListenSegment();
    unawaited(_flushListenedTime());
    final settings = ref.read(settingsProvider);
    if (settings.fadePlayPauseStop && settings.playPauseStopFadeLength > 0) {
      final finished = await _fader.fadeTo(
        0.0,
        Duration(milliseconds: settings.playPauseStopFadeLength),
      );
      // Something (a play tap, a new song) took over mid-fade.
      if (!finished) return;
    }
    _resumePositionAfterStop = state.position;
    state = state.copyWith(isPlaying: false);
    await ref.read(audioServiceProvider).stop();
    // The user explicitly stopped playback: disarm mpv_audio_kit's
    // auto-resume-on-focus-gain latch so an unrelated transient focus
    // loss/gain cycle (e.g. a notification sound) can't resurrect the song.
    await _disarmAutoResumeAfterFocusGain();
  }

  Future<void> togglePlay() async {
    if (state.isPlaying) {
      await _pauseFromUser();
    } else {
      await _resumeFromUser();
    }
  }

  /// In-app pause (button, widget, sleep-timer-free paths): fade out, then
  /// pause mpv - unless a play tap superseded the fade in the meantime.
  Future<void> _pauseFromUser() async {
    _silenceTimer?.cancel();
    _songCompletionTimer?.cancel();
    _pausedForRouteChange = false;
    state = state.copyWith(isPlaying: false);
    _updateNotification();

    final settings = ref.read(settingsProvider);
    try {
      if (settings.fadePlayPauseStop && settings.playPauseStopFadeLength > 0) {
        final finished = await _fader.fadeTo(
          0.0,
          Duration(milliseconds: settings.playPauseStopFadeLength),
        );
        if (!finished) return;
      }
      await ref.read(audioServiceProvider).pause();
      // Deliberate user pause: disarm mpv_audio_kit's auto-resume-on-focus-
      // gain latch (see _disarmAutoResumeAfterFocusGain doc) so it doesn't
      // resume this track behind the user's back later.
      await _disarmAutoResumeAfterFocusGain();
    } catch (e, stack) {
      LoggerHelper.write('Playback pause failed', e, stack);
      state = state.copyWith(isPlaying: player.state.playWhenReady);
      _updateNotification();
    }
  }

  /// In-app play (button, widget): blocked during a call, then resumes.
  Future<void> _resumeFromUser() async {
    _silenceTimer?.cancel();
    state = state.copyWith(isPlaying: true);
    _updateNotification();

    try {
      if (ref.read(settingsProvider).audioFocus &&
          await ref.read(audioServiceProvider).isOnCall()) {
        state = state.copyWith(isPlaying: false);
        _updateNotification();
        _showErrorSnackBar(
          'Playback blocked: Cannot play music during an active call',
          (l10n) => l10n.activeCallCannotPlay,
        );
        return;
      }
      await _resumeCurrent(mpvAlreadyPlaying: false);
    } catch (e, stack) {
      LoggerHelper.write('Playback resume failed', e, stack);
      state = state.copyWith(isPlaying: player.state.playWhenReady);
      _updateNotification();
    }
  }

  /// Resumes the current song and fades the volume back in. Reopens the
  /// song first when mpv has nothing playable loaded: nothing picked yet,
  /// the track ran to completion, or a Stop unloaded it.
  ///
  /// [mpvAlreadyPlaying] is true when mpv_audio_kit already un-paused mpv
  /// on the OS's behalf, in which case only the volume needs restoring.
  Future<void> _resumeCurrent({required bool mpvAlreadyPlaying}) async {
    _pausedForRouteChange = false;
    // About to (re)start playback: restore whatever interruption policy the
    // settings actually dictate, undoing any disarm from a previous manual
    // pause/stop.
    await _reapplyInterruptionPolicy();

    final settings = ref.read(settingsProvider);
    Song? songToPlay = state.currentSong;
    if (songToPlay == null) {
      if (_playlist.isNotEmpty) {
        songToPlay = (_currentIndex >= 0 && _currentIndex < _playlist.length)
            ? _playlist[_currentIndex]
            : _playlist.first;
      } else {
        if (settings.lastPlayedSongId != null) {
          songToPlay = await DbService.isar.songs.get(
            settings.lastPlayedSongId!,
          );
        }
        songToPlay ??= await DbService.isar.songs.where().findFirst();
      }
      if (songToPlay != null) {
        await play(songToPlay, blockDuringCall: !mpvAlreadyPlaying);
        return;
      }
    }

    if (songToPlay != null &&
        (player.state.completed || player.state.playlist.items.isEmpty)) {
      await play(
        songToPlay,
        initialPosition: player.state.completed
            ? null
            : _resumePositionAfterStop,
        // An OS play (e.g. resume after a call) may land while the audio
        // mode still reads "in call"; the plugin already gates on focus.
        blockDuringCall: !mpvAlreadyPlaying,
      );
      return;
    }

    if (mpvAlreadyPlaying) {
      _fadeIn();
      return;
    }
    // Start from silence only if mpv is really paused; a pause fade that
    // was cut short is still audible and just reverses from where it is.
    if (!player.state.playWhenReady && _fadeLength() > Duration.zero) {
      _fader.set(0.0);
    }
    await ref.read(audioServiceProvider).resume();
    _fadeIn();
  }

  /// Playback ran out on its own: end of the queue, or the song-count sleep
  /// timer. Like a user pause minus the fade. Clears _isTransitioning,
  /// which the completion handler set and would otherwise leave stuck -
  /// the `playing` listener drops every `false` while it's set, so the UI
  /// kept showing "playing" and the next tap paused instead of playing.
  Future<void> _pauseAtPlaybackEnd() async {
    _isTransitioning = false;
    _songCompletionTimer?.cancel();
    _pausedForRouteChange = false;
    state = state.copyWith(isPlaying: false);
    _updateNotification();
    await ref.read(audioServiceProvider).pause();
    // Nothing should auto-resume after the queue ended or the listener
    // fell asleep, e.g. once a voice note's transient focus is released.
    await _disarmAutoResumeAfterFocusGain();
  }

  // --- OS media-session commands (already applied to mpv, see build()) ---

  Future<void> _onRemotePlay() async {
    _silenceTimer?.cancel();
    state = state.copyWith(isPlaying: true);
    _updateNotification();
    try {
      // No isOnCall() gate here: this is either a headset/notification tap
      // or mpv_audio_kit resuming after a call, and the plugin already
      // pauses again itself if it can't get audio focus.
      await _resumeCurrent(mpvAlreadyPlaying: true);
    } catch (e, stack) {
      LoggerHelper.write('Remote play reconcile failed', e, stack);
      state = state.copyWith(isPlaying: player.state.playWhenReady);
      _updateNotification();
    }
  }

  void _onRemotePause() {
    _lastRemotePauseAt = DateTime.now();
    _silenceTimer?.cancel();
    _songCompletionTimer?.cancel();
    if (state.isPlaying) {
      state = state.copyWith(isPlaying: false);
      _updateNotification();
    }
    // A pause from the notification or a headset should stop a later
    // transient focus loss/gain from resuming us, same as an in-app pause.
    // Not when the pause came from a call, though: the plugin armed its
    // resume-after-call latch under the current policy and a second
    // transient loss while paused would clear it under pauseOnly.
    unawaited(() async {
      if (await ref.read(audioServiceProvider).isOnCall()) return;
      if (state.isPlaying) return; // resumed again meanwhile
      await _disarmAutoResumeAfterFocusGain();
    }());
  }

  Future<void> _onRemotePlayPause() async {
    // The plugin resolves the toggle against its own play intent and
    // applies it asynchronously; let that land, then follow whichever way
    // it went instead of toggling our own flag (the two can disagree).
    await Future<void>.delayed(Duration.zero);
    if (player.state.playWhenReady) {
      await _onRemotePlay();
    } else {
      _onRemotePause();
    }
  }

  void _onRemoteStop() {
    // mpv's stop unloads the file; remember where to pick up again.
    _resumePositionAfterStop = state.position;
    _onRemotePause();
  }

  void _onRemoteSeek(Duration target) {
    _songCompletionTimer?.cancel();
    _lastSeekTime = DateTime.now();
    final clamped = target < Duration.zero
        ? Duration.zero
        : (state.duration > Duration.zero && target > state.duration
              ? state.duration
              : target);
    state = state.copyWith(position: clamped);
  }

  // The app keeps mpv's own shuffle/loop off - it runs the queue and
  // repeat-one itself, and mpv looping would stop `completed` from firing.
  // The OS therefore always shows those as off, so treat each press as a
  // toggle/cycle of the app's own mode, as before.
  void _onRemoteShuffle(bool _) {
    unawaited(player.setShuffle(false));
    unawaited(toggleShuffle());
  }

  void _onRemoteRepeat(Loop _) {
    unawaited(player.setLoop(Loop.off));
    nextRepeatMode();
  }

  Future<void> skipNext({bool isManual = true}) async {
    if (!_queue.advance(
      repeatAll: state.repeatMode == RepeatMode.all,
      shuffled: state.isShuffle,
    )) {
      if (_queue.entries.isNotEmpty) await _pauseAtPlaybackEnd();
      return;
    }
    _publishQueue();
    await play(_queue.current!.song);
  }

  Future<void> skipPrevious({bool force = false}) async {
    if (_queue.entries.isEmpty) return;
    if (!force && state.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }
    final previous = _currentIndex - 1;
    _queue.select(
      previous < 0
          ? state.repeatMode == RepeatMode.all
                ? _queue.entries.length - 1
                : 0
          : previous,
    );
    _publishQueue();
    await play(_queue.current!.song);
  }

  Future<void> seekRelative(int seconds) async {
    Duration newPos = state.position + Duration(seconds: seconds);
    if (newPos < Duration.zero) newPos = Duration.zero;
    if (newPos > state.duration) newPos = state.duration;
    await seek(newPos);
  }

  void adjustVolume(double delta) {
    final newVolume = (state.volume + delta).clamp(0.0, 1.0);
    setVolume(newVolume);
  }

  Future<void> toggleShuffle() async {
    final newState = !state.isShuffle;
    state = state.copyWith(isShuffle: newState);
    await ref.read(settingsProvider.notifier).updateShuffle(newState);

    _queue.shuffle(newState);
    _publishQueue();
    await _saveQueueState();
    _updateNotification();
  }

  void nextRepeatMode() {
    final nextMode = RepeatMode
        .values[(state.repeatMode.index + 1) % RepeatMode.values.length];
    state = state.copyWith(repeatMode: nextMode);
    ref.read(settingsProvider.notifier).updateRepeatMode(nextMode.index);
    _updateWidgetState();
  }

  void setVolume(double volume) {
    state = state.copyWith(volume: volume);
    _applyVolume();
    ref.read(settingsProvider.notifier).updateVolume(volume);
  }

  /// The one place mpv's volume is written: user volume x fade gain, or
  /// silence while scrubbing.
  void _applyVolume() {
    player.setVolume(
      state.isScrubbing ? 0 : state.volume * _fader.factor * 100,
    );
  }

  Future<void> seek(Duration position) async {
    _songCompletionTimer?.cancel();
    _lastSeekTime = DateTime.now();

    try {
      await player.seek(position);
      state = state.copyWith(position: position);
      if (!state.isScrubbing) _applyVolume();
      if (ref.read(settingsProvider).persistQueue) {
        ref
            .read(settingsProvider.notifier)
            .updateLastPosition(position.inMilliseconds);
      }
    } catch (e) {
      debugPrint('Seek failed: $e');
      state = state.copyWith(position: position);
    }
  }

  void startScrubbing() {
    _lastSeekTime = DateTime.now();
    state = state.copyWith(isScrubbing: true);
    _applyVolume();
  }

  void stopScrubbing() {
    _lastSeekTime = DateTime.now();
    state = state.copyWith(isScrubbing: false, position: player.state.position);
    _applyVolume();
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    _queue.reorder(oldIndex, newIndex);
    _publishQueue();
    await _saveQueueState();
  }

  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= _queue.entries.length) return;
    final wasCurrent = index == _currentIndex;
    _queue.remove(index);
    _publishQueue();
    if (wasCurrent) {
      if (index < _queue.entries.length) {
        await playAtIndex(index);
      } else if (state.repeatMode == RepeatMode.all &&
          _queue.entries.isNotEmpty) {
        await playAtIndex(0);
      } else {
        await _stopRemovedCurrent();
      }
    }
    await _saveQueueState();
  }

  Future<void> _stopRemovedCurrent() async {
    _activeCrossfadeId++;
    _pendingCompletion = false;
    _silenceTimer?.cancel();
    _songCompletionTimer?.cancel();
    _resumePositionAfterStop = null;
    _pauseListenSegment();
    unawaited(_flushListenedTime());
    _queue.clear();
    _publishQueue();
    _isTransitioning = false;
    await _disarmAutoResumeAfterFocusGain();
    await player.stop();
    state = state.copyWith(
      currentSong: null,
      isPlaying: false,
      position: Duration.zero,
      duration: Duration.zero,
      queueSourceKey: null,
    );
    ref.read(equalizerProvider.notifier).onSongChanged(null);
    _updateNotification();
  }

  Future<void> clearQueue() async {
    _queue.clear();
    await _stopRemovedCurrent();
    state = PlaybackState(
      volume: state.volume,
      isShuffle: state.isShuffle,
      repeatMode: state.repeatMode,
    );
    _publishQueue();
    await _saveQueueState();
  }

  Future<void> toggleFavorite() async {
    final song = state.currentSong;
    if (song == null) return;

    // Toggle and persist
    final newFavoriteState = !song.isFavorite;
    await DbService.isar.writeTxn(() async {
      song.isFavorite = newFavoriteState;
      await DbService.isar.songs.put(song);
    });

    // Read a fresh instance back from DB to guarantee a new object reference
    // so Riverpod's select((s) => s.currentSong) detects the identity change
    // and rebuilds widgets (the like button, notification etc.)
    final freshSong = await DbService.isar.songs.get(song.id) ?? song;

    // Sync the in-memory playlist entry too
    _queue.updateSong(freshSong);

    state = state.copyWith(currentSong: freshSong, queue: List.from(_playlist));
    _updateNotification();
  }

  double _lastVolume = 1.0;

  void toggleMute() {
    if (state.volume > 0) {
      _lastVolume = state.volume;
      setVolume(0);
    } else {
      setVolume(_lastVolume > 0 ? _lastVolume : 1.0);
    }
  }

  void updateSongEqualizer({
    required int songId,
    required bool hasCustom,
    List<double>? gains,
  }) {
    // Update in playlist
    final idx = _playlist.indexWhere((s) => s.id == songId);
    if (idx != -1) {
      _playlist[idx].hasCustomEqualizer = hasCustom;
      _playlist[idx].equalizerGains = gains;
    }

    // Update in currentSong if it matches
    final song = state.currentSong;
    if (song != null && song.id == songId) {
      song.hasCustomEqualizer = hasCustom;
      song.equalizerGains = gains;
      state = state.copyWith(currentSong: song, queue: List.from(_playlist));
    } else {
      state = state.copyWith(queue: List.from(_playlist));
    }
  }

  void updateSongLyrics(int songId, String lyrics) {
    final idx = _playlist.indexWhere((s) => s.id == songId);
    if (idx != -1) {
      _playlist[idx].lyrics = lyrics;
    }

    final song = state.currentSong;
    if (song != null && song.id == songId) {
      song.lyrics = lyrics;
      state = state.copyWith(currentSong: song, queue: List.from(_playlist));
    } else {
      state = state.copyWith(queue: List.from(_playlist));
    }
  }

  void updateSongLyricsOffset(int songId, int? offsetMs) {
    final idx = _playlist.indexWhere((s) => s.id == songId);
    if (idx != -1) {
      _playlist[idx].lyricsOffsetMs = offsetMs;
    }

    final song = state.currentSong;
    if (song != null && song.id == songId) {
      song.lyricsOffsetMs = offsetMs;
    }
  }

  void clearAllSongsEqualizer() {
    for (final entry in _queue.entries) {
      entry.song.hasCustomEqualizer = false;
      entry.song.equalizerGains = null;
    }
    final song = state.currentSong;
    if (song != null) {
      song.hasCustomEqualizer = false;
      song.equalizerGains = null;
      state = state.copyWith(currentSong: song, queue: List.from(_playlist));
    } else {
      state = state.copyWith(queue: List.from(_playlist));
    }
  }

  /// Edits song metadata (title, artist, album, year, genre, artPath,
  /// lyrics). If [title] actually changes the song's title, the physical
  /// file is renamed to match (this is the only place a song's title can be
  /// changed, so it doubles as the file-rename action - no separate "rename
  /// file" UI). On Android, best-effort also writes title/artist/album/
  /// genre/year/lyrics into the file's own tags (see MediaStoreWriteService).
  /// The returned bool reflects only the DB write - a declined/unsupported
  /// rename or tag write is not treated as a failure, since the DB-side edit
  /// already stands on its own (that's what every other read path in this
  /// app uses).
  Future<bool> editSongMetadata(
    Song song, {
    String? title,
    String? artist,
    String? album,
    int? year,
    String? genre,
    String? artPath,
    String? lyrics,
  }) async {
    final originalPath = song.path;
    final oldArtist = (song.artist ?? 'Unknown Artist').trim();
    final oldTitle = song.title.trim();
    // null = lyrics untouched in the sheet. Otherwise the current (possibly
    // word-synced) lyrics are backed up under their provider first.
    if (lyrics != null) await LyricsFetcher.backUpBeforeEdit(song);
    final sanitizedTitle = (title != null && title.trim().isNotEmpty)
        ? title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim()
        : null;
    final titleChanged = sanitizedTitle != null && sanitizedTitle != song.title;

    final isCurrent = state.currentSong?.id == song.id;
    final wasPlaying = state.isPlaying;
    final lastPosition = state.position;

    // Only rename the physical file when the title actually changed - a
    // song's title very commonly differs from its on-disk filename already
    // (from tags set before this app ever saw it), and re-triggering a
    // rename on every metadata edit just because of that mismatch would be
    // a surprising side effect of e.g. only changing the genre.
    String? renamedPath;
    if (titleChanged) {
      final file = File(originalPath);
      final ext = p.extension(originalPath);
      final newDisplayName = '$sanitizedTitle$ext';
      final newPath = p.join(file.parent.path, newDisplayName);
      final collides =
          newPath.toLowerCase() != originalPath.toLowerCase() &&
          await File(newPath).exists();
      if (!collides) {
        try {
          if (isCurrent) {
            // Completely stop player to release file handle locks
            await player.stop();
            await Future.delayed(const Duration(milliseconds: 500));
          }
          if (await file.exists()) {
            if (Platform.isAndroid) {
              // Renames on Android scoped storage go through MediaStore -
              // File.rename() throws for any file this app doesn't own
              // (most MediaStore-indexed songs), so it needs the native
              // consent flow rather than a raw filesystem rename.
              renamedPath = await MediaStoreWriteService.renameFile(
                originalPath,
                newDisplayName,
              );
            } else {
              await file.rename(newPath);
              renamedPath = newPath;
            }
          }
        } catch (e) {}
        if (renamedPath == null && isCurrent) {
          // Declined/failed - resume where playback was before we stopped it.
          await play(song, play: wasPlaying);
          await seek(lastPosition);
        }
      }
    }

    try {
      await DbService.isar.writeTxn(() async {
        if (title != null && title.isNotEmpty) song.title = title.trim();
        if (artist != null) {
          song.artist = artist.trim().isEmpty ? null : artist.trim();
        }
        if (album != null) {
          song.album = album.trim().isEmpty ? null : album.trim();
        }
        if (year != null) song.year = year == 0 ? null : year;
        if (genre != null) {
          song.genre = genre.trim().isEmpty ? null : genre.trim();
        }
        if (artPath != null) {
          song.artPath = artPath.trim().isEmpty ? null : artPath.trim();
        }
        // [song] may be a stale queue copy - untouched lyrics come from the
        // database, so a newer (e.g. word-synced) save isn't overwritten.
        song.lyrics = lyrics == null
            ? (await DbService.isar.songs.get(song.id))?.lyrics ?? song.lyrics
            : lyrics.trim().isEmpty
            ? null
            : LyricsFetcher.userLyrics(lyrics);
        if (renamedPath != null) song.path = renamedPath;
        await DbService.isar.songs.put(song);
      });

      // The lyrics cache is keyed by artist/title - move it along.
      await LyricsCache.rename(
        oldArtist,
        oldTitle,
        (song.artist ?? 'Unknown Artist').trim(),
        song.title.trim(),
      );

      // Update the in-memory playlist
      _queue.updateSong(song);

      // Reflect changes in live playback state if this is the current song
      if (isCurrent) {
        state = state.copyWith(currentSong: song, queue: List.from(_playlist));
        if (renamedPath != null) {
          // Resume playing track from the new path
          await play(song, play: wasPlaying);
          await seek(lastPosition);
        } else {
          _updateNotification();
        }
        ref.read(lyricsProvider.notifier).fetchForSong(song, force: true);
      } else {
        state = state.copyWith(queue: List.from(_playlist));
      }

      if (Platform.isAndroid) {
        try {
          await MediaStoreWriteService.writeTags(
            song.path,
            title: song.title,
            artist: song.artist,
            album: song.album,
            genre: song.genre,
            year: song.year,
            lyrics: song.lyrics,
          );
        } catch (_) {}
      }

      return true;
    } catch (e) {
      if (isCurrent && renamedPath != null) {
        // Fallback: restore player using original song/state
        await play(song, play: wasPlaying);
        await seek(lastPosition);
      }
      return false;
    }
  }

  Future<FileActionResult> deleteSong(Song song) async {
    try {
      await _requestStoragePermissions();
    } catch (e) {}

    final isCurrent = state.currentSong?.id == song.id;
    final wasPlaying = state.isPlaying;

    if (isCurrent) {
      // Completely stop player to release file handle locks
      await player.stop();
      // Wait for player to completely release the file handle
      await Future.delayed(const Duration(milliseconds: 500));
    }

    final file = File(song.path);
    bool fileDeleted = false;
    try {
      if (await file.exists()) {
        if (Platform.isAndroid) {
          // Scoped storage: File.delete() throws for any file this app
          // doesn't own (most MediaStore-indexed songs), so route through
          // the native MediaStore consent flow instead.
          fileDeleted = await MediaStoreWriteService.deleteFile(song.path);
        } else {
          await file.delete();
          fileDeleted = true;
        }
      }
    } catch (e) {}

    bool dbSuccess = false;
    try {
      await DbService.isar.writeTxn(() async {
        await DbService.isar.songs.delete(song.id);
      });
      dbSuccess = true;

      // Remove every occurrence of the deleted file from both queue orders.
      final nextEntry = _queue.entries
          .skip(_currentIndex + 1)
          .where((entry) => entry.song.id != song.id)
          .firstOrNull;
      for (var i = _queue.entries.length - 1; i >= 0; i--) {
        if (_queue.entries[i].song.id == song.id) _queue.remove(i);
      }
      _publishQueue();
      if (isCurrent) {
        if (nextEntry != null) {
          _queue.select(_queue.entries.indexOf(nextEntry));
          _publishQueue();
          await play(nextEntry.song, play: wasPlaying);
        } else {
          await _stopRemovedCurrent();
        }
      }
      await _saveQueueState();

      // Clean up orphaned artists and albums
      await _cleanUpOrphanedArtistsAndAlbums();
    } catch (e) {}

    if (!dbSuccess) {
      return FileActionResult.failure;
    }
    return fileDeleted ? FileActionResult.success : FileActionResult.dbOnly;
  }

  Future<void> shareSong(Song song) => shareSongs([song]);

  /// Shares one or more songs as files through a single native share sheet.
  /// [shareSong] is a thin wrapper over this so there's one implementation
  /// of "turn songs into an XFile share" instead of two.
  Future<void> shareSongs(List<Song> songs) async {
    if (songs.isEmpty) return;
    final text = songs.length == 1
        ? currentL10n().shareSongText(songs.first.title)
        : currentL10n().shareSongsText(songs.length);
    await Share.shareXFiles(
      songs.map((s) => XFile(s.path)).toList(),
      text: text,
    );
  }

  static const _widgetChannel = MethodChannel('com.looper.player/widget');
  String _lastWidgetLyricLine = '';

  void _checkAndUpdateLyrics() {
    if (!Platform.isAndroid) return;
    try {
      final lyricsState = ref.read(lyricsProvider);
      final currentPosition = state.position;
      String currentLine = "";
      if (lyricsState.rawLrc != null && lyricsState.isSynced) {
        final activeLineIndex = _activeLyricLineIndex(
          lyricsState.parsedLines,
          currentPosition,
        );
        if (activeLineIndex != -1) {
          currentLine = lyricsState.parsedLines[activeLineIndex].fullText;
        }
      }
      if (currentLine != _lastWidgetLyricLine) {
        _lastWidgetLyricLine = currentLine;
        _updateWidgetState();
      }
    } catch (e) {}
  }

  bool? _hasHomeWidgetsPinned;
  int _lastHomeWidgetPinCheckMs = 0;
  static const int _homeWidgetPinCheckIntervalMs = 60000;
  static const List<String> _homeWidgetProviders = [
    'PlayerWidgetProvider',
    'PlayerWidgetProviderSquareArtwork',
    'PlayerWidgetProviderSquareProgress',
    'PlayerWidgetProviderLargeLyrics',
    'PlayerWidgetProviderBar',
    'PlayerWidgetProviderMedium',
    'PlayerWidgetProviderLargeArtwork',
    'PlayerWidgetProviderLargeArtworkInfo',
    'PlayerWidgetProviderTallArtwork',
    'PlayerWidgetProviderTallArtworkInfo',
    'PlayerWidgetProviderDial',
    'PlayerWidgetProviderArtworkSide',
  ];

  /// Whether any of this app's home-screen widgets is actually pinned to
  /// a launcher, cached for [_homeWidgetPinCheckIntervalMs] so checking
  /// costs one platform-channel round trip a minute rather than one per
  /// call. _updateWidgetState() used to unconditionally push 11
  /// saveWidgetData writes + one updateWidget broadcast per widget type on
  /// every throttle tick even for the (typical) user who never placed any
  /// of these widgets on their home screen. The native side sends
  /// onWidgetRefresh when a widget is placed, so the cache never hides one.
  Future<bool> _anyHomeWidgetPinned() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_hasHomeWidgetsPinned != null &&
        now - _lastHomeWidgetPinCheckMs < _homeWidgetPinCheckIntervalMs) {
      return _hasHomeWidgetsPinned!;
    }
    _lastHomeWidgetPinCheckMs = now;
    try {
      final installed = await HomeWidget.getInstalledWidgets();
      // home_widget reports Android's *short* class name, which for a class
      // inside the app's own package is ".PlayerWidgetProvider" rather than
      // the fully qualified name - so compare on the simple name only.
      _hasHomeWidgetsPinned = installed.any(
        (w) =>
            _homeWidgetProviders.contains(w.androidClassName?.split('.').last),
      );
    } catch (_) {
      // Can't tell - fail open so a widget the user actually placed never
      // silently stops updating.
      _hasHomeWidgetsPinned = true;
    }
    return _hasHomeWidgetsPinned!;
  }

  Timer? _sleepTimer;

  void startSleepTimer({Duration? duration, int? songCount}) {
    _sleepTimer?.cancel();
    _sleepTimer = null;

    if (duration != null) {
      state = state.copyWith(
        isSleepTimerActive: true,
        sleepTimerDurationRemaining: duration,
        sleepTimerDurationInitial: duration,
        sleepTimerSongsRemaining: null,
        sleepTimerSongsInitial: null,
      );

      _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!state.isSleepTimerActive ||
            state.sleepTimerDurationRemaining == null) {
          timer.cancel();
          _sleepTimer = null;
          return;
        }

        final remaining =
            state.sleepTimerDurationRemaining! - const Duration(seconds: 1);
        if (remaining <= Duration.zero) {
          timer.cancel();
          _sleepTimer = null;
          state = state.copyWith(
            isSleepTimerActive: false,
            sleepTimerDurationRemaining: null,
            sleepTimerSongsRemaining: null,
            sleepTimerDurationInitial: null,
            sleepTimerSongsInitial: null,
          );
          // Route through togglePlay() instead of a bare player.pause():
          // it's the same "pause" a tap on the play button triggers, so a
          // song caught mid-playback gets the fade-out/notification sync
          // that already exists there instead of a jarring hard cut.
          if (state.isPlaying) {
            unawaited(togglePlay());
          }
        } else {
          state = state.copyWith(sleepTimerDurationRemaining: remaining);
        }
      });
    } else if (songCount != null) {
      state = state.copyWith(
        isSleepTimerActive: true,
        sleepTimerDurationRemaining: null,
        sleepTimerDurationInitial: null,
        sleepTimerSongsRemaining: songCount,
        sleepTimerSongsInitial: songCount,
      );
    }
  }

  void stopSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    state = state.copyWith(
      isSleepTimerActive: false,
      sleepTimerDurationRemaining: null,
      sleepTimerSongsRemaining: null,
      sleepTimerDurationInitial: null,
      sleepTimerSongsInitial: null,
    );
  }

  // mpv_audio_kit keeps holding audio focus across a pause/stop (by design,
  // so a quick manual resume doesn't re-duck other apps) and, under
  // InterruptionPolicy.pauseAndResume, arms auto-resume on the *next*
  // transient focus loss/gain cycle regardless of why playback isn't
  // running. Without this, an unrelated notification chime arriving after
  // the user has explicitly paused/stopped would silently resume this app's
  // playback. Forcing the policy to pauseOnly disarms that latch; the next
  // deliberate play/resume restores whatever policy the settings dictate
  // via _reapplyInterruptionPolicy().
  Future<void> _disarmAutoResumeAfterFocusGain() async {
    if (!ref.read(settingsProvider).audioFocus) return;
    await _applyInterruptionPolicy(InterruptionPolicy.pauseOnly);
  }

  /// Headphones unplugged / Bluetooth audio dropped. mpv_audio_kit pauses
  /// for this itself; this broadcast only races that pause, so it records
  /// that playback stopped for a route change (for "Resume on Bluetooth
  /// Connect") whichever arrived first, and pauses too in case it came
  /// first (a second pause is a no-op).
  void onBecomingNoisy() {
    final pausedJustNow =
        DateTime.now().difference(_lastRemotePauseAt) <
        const Duration(seconds: 2);
    if (!state.isPlaying && !pausedJustNow) return;
    if (state.isPlaying) {
      unawaited(ref.read(audioServiceProvider).pause());
      _onRemotePause();
    }
    _pausedForRouteChange = true;
  }

  Future<void> resumeOnBluetoothConnect() async {
    if (state.isPlaying || !_pausedForRouteChange) return;
    if (!ref.read(settingsProvider).resumeOnBluetoothConnect) return;

    _silenceTimer?.cancel();
    state = state.copyWith(isPlaying: true);
    _updateNotification();
    try {
      await _resumeCurrent(mpvAlreadyPlaying: false);
    } catch (e, stack) {
      LoggerHelper.write('Resume on Bluetooth connect failed', e, stack);
      state = state.copyWith(isPlaying: player.state.playWhenReady);
      _updateNotification();
    }
  }

  void _disposePlayback() {
    // Best-effort: flush whatever real listening time is pending. There's no
    // synchronous flush available here, so a hard process kill in the same
    // instant can still lose the last few seconds - unavoidable without a
    // native-side write.
    _pauseListenSegment();
    unawaited(_flushListenedTime());
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _silenceTimer?.cancel();
    _sleepTimer?.cancel();
    _fader.cancel();
  }

  void _initWidgetChannel() {
    if (!Platform.isAndroid) return;
    _widgetChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onWidgetAction':
          final action = call.arguments as String?;
          if (action == 'com.looper.player.ACTION_PLAY_PAUSE') {
            togglePlay();
          } else if (action == 'com.looper.player.ACTION_NEXT') {
            skipNext();
          } else if (action == 'com.looper.player.ACTION_PREV') {
            skipPrevious();
          } else if (action == 'com.looper.player.ACTION_SHUFFLE') {
            toggleShuffle();
          } else if (action == 'com.looper.player.ACTION_REPEAT') {
            nextRepeatMode();
          }
          break;
        case 'onWidgetRefresh':
          // Native side saw a widget being placed. If we believed none was
          // pinned, nothing has been saved for it to show - re-check and
          // push now rather than at the next cache expiry. Ignored while
          // widgets are known pinned: our own updateWidget broadcasts land
          // here too.
          if (_hasHomeWidgetsPinned != true) {
            _hasHomeWidgetsPinned = null;
            _updateWidgetState();
          }
          break;
      }
    });
  }

  /// Index of the lyric line active at [position] in [lines].
  ///
  /// [lines] are sorted and contiguous by construction (LrcParser.parse
  /// sorts by startTime and sets each line's endTime to the next line's
  /// startTime), so a binary search on startTime is equivalent to the
  /// linear `indexWhere(start <= position < end)` scan this replaces -
  /// O(log n) instead of O(n). This runs on every playback position tick
  /// (many times per second while playing, from _checkAndUpdateLyrics),
  /// so the linear scan's cost was paid continuously for the entire
  /// duration of playback, whether or not the lyrics screen was open.
  int _activeLyricLineIndex(List<LyricLine> lines, Duration position) {
    if (lines.isEmpty) return -1;
    if (position < lines.first.startTime) return 0;
    if (position >= lines.last.endTime) return lines.length - 1;

    int lo = 0;
    int hi = lines.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (lines[mid].startTime <= position) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  Future<void> _updateWidgetState() async {
    if (!Platform.isAndroid) return;
    try {
      if (!await _anyHomeWidgetPinned()) return;

      final song = state.currentSong;
      final lyricsState = ref.read(lyricsProvider);
      final currentPosition = state.position;
      String currentLine = "";
      String nextLine = "";
      if (lyricsState.rawLrc != null && lyricsState.isSynced) {
        final activeLineIndex = _activeLyricLineIndex(
          lyricsState.parsedLines,
          currentPosition,
        );
        if (activeLineIndex != -1) {
          currentLine = lyricsState.parsedLines[activeLineIndex].fullText;
          if (activeLineIndex + 1 < lyricsState.parsedLines.length) {
            nextLine = lyricsState.parsedLines[activeLineIndex + 1].text;
          }
        }
      }

      final accentColor = ref.read(settingsProvider).accentColor;

      await HomeWidget.saveWidgetData<String>(
        'title',
        song?.title ?? currentL10n().noSongPlaying,
      );
      await HomeWidget.saveWidgetData<String>('artist', song?.artist ?? '');
      await HomeWidget.saveWidgetData<bool>('isPlaying', state.isPlaying);
      await HomeWidget.saveWidgetData<bool>('isShuffle', state.isShuffle);
      await HomeWidget.saveWidgetData<int>(
        'repeatMode',
        state.repeatMode.index,
      );
      await HomeWidget.saveWidgetData<String>('lyrics', currentLine);
      await HomeWidget.saveWidgetData<String>('nextLyrics', nextLine);
      await HomeWidget.saveWidgetData<String>('artPath', song?.artPath ?? '');
      await HomeWidget.saveWidgetData<int>('accentColor', accentColor);
      await HomeWidget.saveWidgetData<int>(
        'position',
        currentPosition.inMilliseconds,
      );
      await HomeWidget.saveWidgetData<int>(
        'duration',
        state.duration.inMilliseconds,
      );

      for (final name in _homeWidgetProviders) {
        await HomeWidget.updateWidget(
          name: name,
          qualifiedAndroidName: 'com.looper.player.$name',
        );
      }
    } catch (e) {}
  }

  InterruptionPolicy _getInterruptionPolicy() {
    final settings = ref.read(settingsProvider);
    if (!settings.audioFocus) {
      return InterruptionPolicy.keepPlaying;
    }
    // audioFocusRestartOnGain used to be ANDed in here too, but it has no
    // UI any more - a stale `false` from an older build would have silently
    // disabled resume-after-call with no way to turn it back on.
    return settings.resumeAfterCall
        ? InterruptionPolicy.pauseAndResume
        : InterruptionPolicy.pauseOnly;
  }

  Future<void> _applyInterruptionPolicy(InterruptionPolicy policy) async {
    await ref.read(audioServiceProvider).applyAudioFocusPolicy(policy);
  }

  Future<void> _reapplyInterruptionPolicy() async {
    if (!ref.read(settingsProvider).audioFocus) return;
    await _applyInterruptionPolicy(_getInterruptionPolicy());
  }

  /// Persists [song]'s current listening position for "Keep Song Progress".
  /// A song that's essentially finished (within 3s of its own end) gets its
  /// saved position cleared back to 0 instead of stored near-the-end, so
  /// replaying a track that played through naturally starts fresh rather
  /// than immediately re-ending.
  Future<void> _savePerSongProgress(
    Song? song,
    Duration position,
    Duration duration,
  ) async {
    if (song == null) return;
    if (!ref.read(settingsProvider).keepSongProgress) return;

    final remaining = duration - position;
    final isFinished =
        duration > Duration.zero && remaining <= const Duration(seconds: 3);
    final valueMs = isFinished ? 0 : position.inMilliseconds;

    if (song.lastPositionMs == valueMs) return;
    song.lastPositionMs = valueMs;

    await DbService.isar.writeTxn(() async {
      final dbSong = await DbService.isar.songs.get(song.id);
      if (dbSong != null) {
        dbSong.lastPositionMs = valueMs;
        await DbService.isar.songs.put(dbSong);
      }
    });
  }

  Future<void> _saveQueueState() async {
    final settings = ref.read(settingsProvider);
    if (!settings.persistQueue) return;
    final songIds = _playlist.map((s) => s.id).toList();
    await ref
        .read(settingsProvider.notifier)
        .updateLastQueueState(
          songIds,
          _currentIndex,
          state.currentSong?.id,
          positionMs: state.position.inMilliseconds,
          manualIndices: _queue.manualIndices,
          originalOrder: _queue.originalOrder,
        );
  }

  /// Duration of the play/pause/stop fade, or zero when fading is off.
  Duration _fadeLength() {
    final settings = ref.read(settingsProvider);
    return settings.fadePlayPauseStop && settings.playPauseStopFadeLength > 0
        ? Duration(milliseconds: settings.playPauseStopFadeLength)
        : Duration.zero;
  }

  /// Brings the fade gain back to full, fading if fades are enabled.
  void _fadeIn() {
    unawaited(_fader.fadeTo(1.0, _fadeLength()));
  }
}
