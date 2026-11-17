// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:mpv_audio_kit/src/events/mpv_hook_event.dart';
import 'package:mpv_audio_kit/src/events/mpv_log_entry.dart';
import 'package:mpv_audio_kit/src/events/mpv_player_error.dart';
import 'package:mpv_audio_kit/src/generated/audio_effects.dart';
import 'package:mpv_audio_kit/src/generated/audio_effects_settings.dart';
import 'package:mpv_audio_kit/src/models/audio_params.dart';
import 'package:mpv_audio_kit/src/models/chapter.dart';
import 'package:mpv_audio_kit/src/models/cover_art.dart';
import 'package:mpv_audio_kit/src/models/demuxer_cache_state.dart';
import 'package:mpv_audio_kit/src/models/device.dart';
import 'package:mpv_audio_kit/src/models/fft_frame.dart';
import 'package:mpv_audio_kit/src/models/loudness.dart';
import 'package:mpv_audio_kit/src/models/loudness_scan.dart';
import 'package:mpv_audio_kit/src/models/media_session.dart';
import 'package:mpv_audio_kit/src/models/mpv_track.dart';
import 'package:mpv_audio_kit/src/models/pcm_frame.dart';
import 'package:mpv_audio_kit/src/models/playlist.dart';
import 'package:mpv_audio_kit/src/models/waveform_data.dart';
import 'package:mpv_audio_kit/src/player/mpv_playback_state_derive.dart';
import 'package:mpv_audio_kit/src/reactive/default_reactives.dart';
import 'package:mpv_audio_kit/src/reactive/reactive_property.dart';
import 'package:mpv_audio_kit/src/types/enums/cover.dart';
import 'package:mpv_audio_kit/src/types/enums/format.dart';
import 'package:mpv_audio_kit/src/types/enums/gapless.dart';
import 'package:mpv_audio_kit/src/types/enums/hls_bitrate.dart';
import 'package:mpv_audio_kit/src/types/enums/loop.dart';
import 'package:mpv_audio_kit/src/types/enums/spdif.dart';
import 'package:mpv_audio_kit/src/types/enums/tap_side.dart';
import 'package:mpv_audio_kit/src/types/sealed/channels.dart';
import 'package:mpv_audio_kit/src/types/sealed/media_session_command.dart';
import 'package:mpv_audio_kit/src/types/settings/cache_settings.dart';
import 'package:mpv_audio_kit/src/types/settings/demuxer_settings.dart';
import 'package:mpv_audio_kit/src/types/settings/replay_gain_settings.dart';
import 'package:mpv_audio_kit/src/types/settings/spectrum_settings.dart';
import 'package:mpv_audio_kit/src/types/state/audio_output_state.dart';
import 'package:mpv_audio_kit/src/types/state/mpv_playback_state.dart';
import 'package:mpv_audio_kit/src/types/state/mpv_prefetch_state.dart';

/// Typed event streams for subscribing to individual [Player] state changes.
///
/// Access via `player.stream`:
/// ```dart
/// player.stream.playing.listen((isPlaying) { ... });
/// player.stream.position.listen((pos) { ... });
/// ```
///
/// Internally each stream is the broadcast view of a [ReactiveProperty]
/// (for state-backed signals like `playing`, `volume`, `position`, …) or a
/// plain [Stream] from a [StreamController] (for transient events like
/// `error`, `endFile`, `log`).
class PlayerStream {
  /// Internal constructor wired by `Player`. Not part of the public API —
  /// the `DefaultPropertyReactives` argument is library-private, so a
  /// downstream call cannot satisfy it without reaching into `src/`.
  @internal
  PlayerStream.fromInternals({
    required DefaultPropertyReactives reactives,
    required ReactiveProperty<bool> buffering,
    required ReactiveProperty<bool> completed,
    required ReactiveProperty<Playlist> playlist,
    required ReactiveProperty<Loop> loop,
    required ReactiveProperty<List<Device>> audioDevices,
    required ReactiveProperty<Map<String, String>> metadata,
    required ReactiveProperty<double> bufferingPercentage,
    required ReactiveProperty<DemuxerCacheState> demuxerCacheState,
    required ReactiveProperty<AudioEffects> audioEffects,
    required ReactiveProperty<MediaSession?> mediaSession,
    required this.endFile,
    required this.error,
    required this.log,
    required this.internalLog,
    required this.hook,
    required this.seekCompleted,
    required this.coverArt,
    required this.fft,
    required this.pcm,
    required this.spectrum,
    required this.waveform,
    required this.loudnessMeter,
    required this.loudness,
    required this.tap,
    required this.mediaSessionCommands,
  })  : playing = reactives.playing.stream,
        playWhenReady = reactives.playWhenReady.stream,
        position = reactives.position.stream,
        duration = reactives.duration.stream,
        buffer = reactives.buffer.stream,
        volume = reactives.volume.stream,
        rate = reactives.rate.stream,
        pitch = reactives.pitch.stream,
        mute = reactives.mute.stream,
        shuffle = reactives.shuffle.stream,
        pitchCorrection = reactives.pitchCorrection.stream,
        audioDelay = reactives.audioDelay.stream,
        audioBitrate = reactives.audioBitrate.stream,
        audioDevice = reactives.audioDevice.stream,
        audioParams = reactives.audioParams.stream,
        // mpv exposes `audio-out-params` as a single MPV_FORMAT_NODE_MAP
        // and there is no codec / codec-name sibling on the output side, so
        // the aggregator is a direct passthrough of the node reactive.
        audioOutParams = reactives.audioOutParamsNode.stream,
        gapless = reactives.gapless.stream,
        replayGain = reactives.replayGain.stream,
        volumeGain = reactives.volumeGain.stream,
        volumeGainMin = reactives.volumeGainMin.stream,
        volumeGainMax = reactives.volumeGainMax.stream,
        systemVolume = reactives.systemVolume.stream,
        systemMute = reactives.systemMute.stream,
        cache = reactives.cache.stream,
        demuxer = reactives.demuxer.stream,
        networkTimeout = reactives.networkTimeout.stream,
        tlsVerify = reactives.tlsVerify.stream,
        hlsBitrate = reactives.hlsBitrate.stream,
        cookies = reactives.cookies.stream,
        httpProxy = reactives.httpProxy.stream,
        pausedForCache = reactives.pausedForCache.stream,
        demuxerViaNetwork = reactives.demuxerViaNetwork.stream,
        audioExclusive = reactives.audioExclusive.stream,
        audioMediaRole = reactives.audioMediaRole.stream,
        audioBuffer = reactives.audioBuffer.stream,
        audioStreamSilence = reactives.audioStreamSilence.stream,
        audioNullUntimed = reactives.audioNullUntimed.stream,
        tracks = reactives.tracks.stream,
        currentAudioTrack = reactives.currentAudioTrack.stream,
        audioSpdif = reactives.audioSpdif.stream,
        volumeMax = reactives.volumeMax.stream,
        audioSampleRate = reactives.audioSampleRate.stream,
        audioFormat = reactives.audioFormat.stream,
        audioChannels = reactives.audioChannels.stream,
        audioClientName = reactives.audioClientName.stream,
        audioDriver = reactives.audioDriver.stream,
        audioOutputState = reactives.audioOutputState.stream,
        coverArtAuto = reactives.coverArtAuto.stream,
        prefetchState = reactives.prefetchState.stream,
        prefetchCacheDuration = reactives.prefetchCacheDuration.stream,
        prefetchPlaylist = reactives.prefetchPlaylist.stream,
        audioPts = reactives.audioPts.stream,
        timeRemaining = reactives.timeRemaining.stream,
        playtimeRemaining = reactives.playtimeRemaining.stream,
        eofReached = reactives.eofReached.stream,
        seekable = reactives.seekable.stream,
        partiallySeekable = reactives.partiallySeekable.stream,
        mediaTitle = reactives.mediaTitle.stream,
        fileFormat = reactives.fileFormat.stream,
        fileSize = reactives.fileSize.stream,
        bufferDuration = reactives.bufferDuration.stream,
        demuxerIdle = reactives.demuxerIdle.stream,
        currentChapter = reactives.currentChapter.stream,
        chapters = reactives.chapters.stream,
        path = reactives.path.stream,
        filename = reactives.filename.stream,
        streamPath = reactives.streamPath.stream,
        streamOpenFilename = reactives.streamOpenFilename.stream,
        playlistPath = reactives.playlistPath.stream,
        abLoopA = reactives.abLoopA.stream,
        abLoopB = reactives.abLoopB.stream,
        abLoopCount = reactives.abLoopCount.stream,
        remainingAbLoops = reactives.remainingAbLoops.stream,
        seeking = reactives.seeking.stream,
        percentPos = reactives.percentPos.stream,
        cacheSpeed = reactives.cacheSpeed.stream,
        cacheBufferingState = reactives.cacheBufferingState.stream,
        currentDemuxer = reactives.currentDemuxer.stream,
        currentAo = reactives.currentAo.stream,
        demuxerStartTime = reactives.demuxerStartTime.stream,
        chapterMetadata = reactives.chapterMetadata.stream,
        mpvVersion = reactives.mpvVersion.stream,
        ffmpegVersion = reactives.ffmpegVersion.stream,
        buffering = buffering.stream,
        completed = completed.stream,
        playbackState = _playbackStateStream(reactives, buffering, completed),
        playlist = playlist.stream,
        loop = loop.stream,
        audioDevices = audioDevices.stream,
        metadata = metadata.stream,
        bufferingPercentage = bufferingPercentage.stream,
        demuxerCacheState = demuxerCacheState.stream,
        audioEffects = audioEffects.stream,
        mediaSession = mediaSession.stream;

  /// Aggregate [MpvPlaybackState] derived from the 5 underlying signals
  /// the library already tracks (`playing`, `buffering`, `completed`,
  /// `pausedForCache`, `duration`). Lazy: subscriptions to the source
  /// streams open only on the first listener.
  static Stream<MpvPlaybackState> _playbackStateStream(
    DefaultPropertyReactives r,
    ReactiveProperty<bool> bufferingProp,
    ReactiveProperty<bool> completedProp,
  ) {
    MpvPlaybackState snapshot() => deriveMpvPlaybackState(
          playing: r.playing.value,
          buffering: bufferingProp.value,
          completed: completedProp.value,
          pausedForCache: r.pausedForCache.value,
          duration: r.duration.value,
        );

    return _bindAggregate<MpvPlaybackState>(snapshot, [
      r.playing.stream,
      bufferingProp.stream,
      completedProp.stream,
      r.pausedForCache.stream,
      r.duration.stream,
    ]);
  }

  /// Generic helper for building a broadcast aggregator stream.
  ///
  /// On the first listener, emits a synchronous initial snapshot and
  /// subscribes to every input [sources] stream, piping a fresh
  /// `snapshot()` value to the output controller on each upstream event.
  /// Repeated upstream events that resolve to the same aggregate value
  /// are deduplicated so subscribers see one emission per actual change.
  /// On the last cancel, tears the subscriptions down.
  static Stream<T> _bindAggregate<T>(
    T Function() snapshot,
    List<Stream<dynamic>> sources,
  ) {
    late final StreamController<T> ctrl;
    List<StreamSubscription<dynamic>>? subs;
    late T last;
    var primed = false;
    void pump() {
      final next = snapshot();
      if (primed && last == next) return;
      last = next;
      primed = true;
      ctrl.add(next);
    }

    ctrl = StreamController<T>.broadcast(
      onListen: () {
        // Reset the dedup memory on every fresh subscription cycle so a
        // late subscriber receives the current aggregate as its first
        // event regardless of whether the previous cycle saw the same
        // value.
        primed = false;
        pump();
        // The aggregate is done once every input is: dispose closes them
        // all, and a subscriber awaiting it must not hang.
        var open = sources.length;
        subs = [
          for (final s in sources)
            s.listen(
              (_) => pump(),
              onDone: () {
                if (--open == 0) ctrl.close();
              },
            ),
        ];
      },
      onCancel: () async {
        final toCancel = subs;
        subs = null;
        if (toCancel == null) return;
        for (final s in toCancel) {
          await s.cancel();
        }
      },
    );
    return ctrl.stream;
  }

  // ── Playback / lifecycle ─────────────────────────────────────────────────

  /// Emits whenever the active playlist changes (adds, removes, reorders).
  final Stream<Playlist> playlist;

  /// Emits when actual audio output starts/stops — mpv's `core-idle`
  /// (inverted). Toggles transiently during seeks and buffering. For a
  /// stable play/pause button, listen to [playWhenReady] instead.
  final Stream<bool> playing;

  /// Emits the user-intent-to-play axis, driven by [Player.play] /
  /// [Player.pause] / [Player.open] / [Player.stop] (and released at the
  /// natural end of content). Stable across seeks and buffering — this is
  /// the signal to bind a play/pause button to. See
  /// [PlayerState.playWhenReady].
  final Stream<bool> playWhenReady;

  /// Emits `true` when the current track finishes playing to its end —
  /// including a single track or the last playlist entry, where the shipped
  /// `keep-open` policy makes mpv park paused on the last frame rather than
  /// emit an end-of-file event. See [PlayerState.completed].
  final Stream<bool> completed;

  /// Emits the current playback position as a [Duration].
  final Stream<Duration> position;

  /// Emits once after a seek request has been fully reinitialized by mpv
  /// and playback is about to resume — i.e. the authoritative
  /// `MPV_EVENT_PLAYBACK_RESTART` signal.
  final Stream<void> seekCompleted;

  /// Emits the duration of the current track. Zero for live / unknown streams.
  final Stream<Duration> duration;

  /// Emits the current volume level (0–100+).
  final Stream<double> volume;

  /// Emits the current playback speed multiplier.
  final Stream<double> rate;

  /// Emits the current pitch multiplier.
  final Stream<double> pitch;

  /// Emits `true` while buffering data; `false` once playback resumes.
  final Stream<bool> buffering;

  /// Emits the current demuxer buffer depth as a [Duration].
  final Stream<Duration> buffer;

  /// Emits the buffer fill percentage (0.0–100.0).
  final Stream<double> bufferingPercentage;

  /// Emits the rich demuxer cache state (buffered ranges + network flags).
  /// Empty for local files; populated when streaming. See
  /// [DemuxerCacheState].
  final Stream<DemuxerCacheState> demuxerCacheState;

  /// Emits the current [Loop] when it changes.
  final Stream<Loop> loop;

  /// Emits `true` when shuffle mode is enabled.
  final Stream<bool> shuffle;

  /// Emits aggregated [AudioParams] from the decoder (track source).
  final Stream<AudioParams> audioParams;

  /// Emits aggregated [AudioParams] from the hardware output (post-processing).
  final Stream<AudioParams> audioOutParams;

  /// Emits the current audio bitrate in bps. `null` = unavailable.
  final Stream<double?> audioBitrate;

  /// Emits the currently selected [Device].
  final Stream<Device> audioDevice;

  /// Emits the full list of detected [Device]s when it changes.
  final Stream<List<Device>> audioDevices;

  /// Emits `true` when the player is muted.
  final Stream<bool> mute;

  /// Emits the current audio delay.
  final Stream<Duration> audioDelay;

  /// Emits `true` when pitch correction is enabled.
  final Stream<bool> pitchCorrection;

  /// Emits the metadata dictionary for the current track.
  final Stream<Map<String, String>> metadata;

  /// Emits the gapless playback mode.
  final Stream<Gapless> gapless;

  /// Aggregate ReplayGain configuration — emits a fresh
  /// [ReplayGainSettings] whenever any of mode / preamp / clip /
  /// fallback changes. Set with [Player.setReplayGain].
  final Stream<ReplayGainSettings> replayGain;

  /// Emits the software volume gain in dB.
  final Stream<double> volumeGain;

  /// Emits the lower clamp on [volumeGain] in dB (`volume-gain-min`).
  final Stream<double> volumeGainMin;

  /// Emits the upper clamp on [volumeGain] in dB (`volume-gain-max`).
  final Stream<double> volumeGainMax;

  /// Emits the OS per-app mixer volume (`ao-volume`); `null` when the active
  /// audio output doesn't expose it.
  final Stream<double?> systemVolume;

  /// Emits the OS per-app mute (`ao-mute`); `null` when the active audio
  /// output doesn't expose it.
  final Stream<bool?> systemMute;

  /// Aggregate cache configuration — emits a fresh [CacheSettings]
  /// whenever any of mode / secs / onDisk / pause / pauseWait / pauseInitial
  /// changes. Set with [Player.setCache].
  final Stream<CacheSettings> cache;

  /// Aggregate demuxer-buffering configuration — emits a fresh
  /// [DemuxerSettings] whenever any of maxBytes / maxBackBytes / readahead
  /// changes. Set with [Player.setDemuxer].
  final Stream<DemuxerSettings> demuxer;

  /// Emits the network timeout duration.
  final Stream<Duration> networkTimeout;

  /// Emits whether TLS verification is enabled.
  final Stream<bool> tlsVerify;

  /// Emits the HLS variant-selection policy.
  final Stream<HlsBitrate> hlsBitrate;

  /// Emits whether the HTTP cookie jar is enabled for network streams.
  final Stream<bool> cookies;

  /// Emits the HTTP proxy URL; empty string when none is configured.
  final Stream<String> httpProxy;

  /// Emits `true` when playback is paused because the network cache ran
  /// empty; `false` once mpv resumes after [cache] `pauseWait` seconds
  /// of buffered data are available again.
  final Stream<bool> pausedForCache;

  /// Emits `true` when the current stream is being read via a network
  /// protocol (HTTP, RTMP, …); `false` for local files.
  final Stream<bool> demuxerViaNetwork;

  /// Emits whether audio exclusive mode is enabled.
  final Stream<bool> audioExclusive;

  /// Emits whether the "music" media role is reported to the audio server
  /// (`audio-set-media-role`).
  final Stream<bool> audioMediaRole;

  /// Emits the audio buffer duration.
  final Stream<Duration> audioBuffer;

  /// Emits whether stream silence is enabled.
  final Stream<bool> audioStreamSilence;

  /// Emits whether fallback to null output is enabled.
  final Stream<bool> audioNullUntimed;

  /// All tracks reported by mpv for the current file (audio + embedded
  /// picture + any other type the demuxer surfaced). See
  /// [PlayerState.tracks] for the filtering pattern.
  final Stream<List<MpvTrack>> tracks;

  /// Currently-active audio track, or `null` when none is selected.
  final Stream<MpvTrack?> currentAudioTrack;

  /// Emits the current S/PDIF passthrough codec set. Empty set =
  /// passthrough disabled.
  final Stream<Set<Spdif>> audioSpdif;

  /// Emits the max volume limit.
  final Stream<double> volumeMax;

  /// Emits the target sample rate.
  final Stream<int> audioSampleRate;

  /// Emits the target audio sample format.
  final Stream<Format> audioFormat;

  /// Emits the target audio channel layout.
  final Stream<Channels> audioChannels;

  /// Emits the audio client name.
  final Stream<String> audioClientName;

  /// Emits the audio output driver.
  final Stream<String> audioDriver;

  /// Lifecycle of mpv's audio output: `closed → initializing → active`
  /// in the success path, `→ failed` if `ao_init_best()` returns a
  /// NULL handle. A typed [MpvLogError] is emitted on [error] the
  /// moment this stream emits [AudioOutputState.failed].
  final Stream<AudioOutputState> audioOutputState;

  /// All DSP effects in mpv's `--af` pipeline, bundled into a single
  /// atomic snapshot. Set with [Player.setAudioEffects] /
  /// [Player.updateAudioEffects]. Sub-stream a single effect via
  /// `audioEffects.map((e) => e.acompressor).distinct()`.
  final Stream<AudioEffects> audioEffects;

  // ── Cover Art ──────────────────────────────────────────────────────────────

  /// Emits the current external cover-art auto-load policy.
  final Stream<Cover> coverArtAuto;

  /// Emits for **every** file-end event — clean completions, stops, errors,
  /// and premature EOFs alike.
  ///
  /// Use [MpvFileEndedEvent.reachedNaturalEnd] to detect whether an EOF
  /// was genuine or caused by a network disconnection.
  final Stream<MpvFileEndedEvent> endFile;

  /// Emits typed error events from the mpv engine.
  ///
  /// Use pattern matching to distinguish [MpvEndFileError] (playback
  /// failures) from [MpvLogError] (informational engine errors).
  final Stream<MpvPlayerError> error;

  /// Engine-side log entries from mpv at the configured log level
  /// (`PlayerConfiguration.logLevel`).
  ///
  /// Prefix examples: `'ffmpeg'`, `'demux'`, `'ao'`, `'cplayer'`.
  /// For library-side messages (parse warnings, hook timeouts), see
  /// [internalLog].
  final Stream<MpvLogEntry> log;

  /// Library-side log entries — JSON parse warnings, hook timeouts, and
  /// other messages produced by the Dart layer itself. Always carries
  /// `prefix: 'mpv_audio_kit'`.
  ///
  /// Disjoint from [log] so you can route engine and library noise to
  /// different sinks (e.g. show only [log] in a debug overlay while
  /// routing [internalLog] to crash reporting).
  final Stream<MpvLogEntry> internalLog;

  /// Emits whenever mpv fires a registered hook (see `Player.registerHook`).
  final Stream<MpvHookEvent> hook;

  /// Lifecycle of mpv's background playlist-prefetch — works uniformly
  /// across HLS, DASH, raw HTTP, SMB, and local files.
  final Stream<MpvPrefetchState> prefetchState;

  /// How much of the next track is buffered ahead by the background
  /// prefetch, as a [Duration]. Pair with [prefetchState] for a
  /// determinate "Prefetching X%" indicator (divide by your configured
  /// cache target). Emits `Duration.zero` while no prefetch is in flight.
  final Stream<Duration> prefetchCacheDuration;

  /// Whether mpv prefetches the next playlist item in the background.
  /// Toggle via [Player.setPrefetchPlaylist].
  final Stream<bool> prefetchPlaylist;

  /// Audio frame timestamp at the playhead (mpv's `audio-pts`). More
  /// granular than [position] for audio-only sync.
  final Stream<Duration> audioPts;

  /// Time until end-of-file ignoring playback speed.
  final Stream<Duration> timeRemaining;

  /// Time until end-of-file adjusted for playback speed.
  final Stream<Duration> playtimeRemaining;

  /// Whether playback has reached EOF (mpv's `eof-reached`).
  final Stream<bool> eofReached;

  /// Whether the current stream supports seeking.
  final Stream<bool> seekable;

  /// Whether the stream is only partially seekable (HLS / DASH window).
  final Stream<bool> partiallySeekable;

  /// Display name for the current track (`media-title`); falls back to
  /// the file name when no `title` tag is present.
  final Stream<String> mediaTitle;

  /// Container format (e.g. `mp4`, `flac`, `mp3`).
  final Stream<String> fileFormat;

  /// Total stream size in bytes; `0` when unknown.
  final Stream<int> fileSize;

  /// Buffered duration ahead of the playhead (`demuxer-cache-duration`).
  /// Complements [buffer] (absolute timestamp) with the headroom amount.
  final Stream<Duration> bufferDuration;

  /// Whether the demuxer thread is idle (cache full or EOF).
  final Stream<bool> demuxerIdle;

  /// Active chapter index, or `null` when no chapter is active.
  /// Set via [Player.setChapter].
  final Stream<int?> currentChapter;

  /// Chapter markers for the current file.
  final Stream<List<Chapter>> chapters;

  /// Full path or URI of the current file, post-redirect.
  /// Mirrors mpv's `path`. Empty when no file is loaded.
  final Stream<String> path;

  /// File name only (no directory) of the current file.
  /// Mirrors mpv's `filename`. Empty when no file is loaded.
  final Stream<String> filename;

  /// URI as originally requested, before any `on_load` hook redirect.
  /// Mirrors mpv's `stream-path`.
  final Stream<String> streamPath;

  /// Source playlist of the current entry (`playlist-path`) — the `.m3u` /
  /// `.pls` path it was expanded from; empty when not loaded via a playlist.
  final Stream<String> playlistPath;

  /// URI as actually opened post-redirect. Mirrors mpv's
  /// `stream-open-filename`.
  final Stream<String> streamOpenFilename;

  /// A-B loop start point. `null` when disabled. Set via
  /// [Player.setAbLoopA].
  final Stream<Duration?> abLoopA;

  /// A-B loop end point. `null` when disabled. Set via
  /// [Player.setAbLoopB].
  final Stream<Duration?> abLoopB;

  /// Total A-B loop repetitions. `null` = infinite. Set via
  /// [Player.setAbLoopCount].
  final Stream<int?> abLoopCount;

  /// Remaining A-B loop repetitions in the active loop. `null` when no
  /// loop is active or count is infinite. Read-only — mirrors mpv's
  /// `remaining-ab-loops`.
  final Stream<int?> remainingAbLoops;

  /// Whether mpv is currently seeking. UI gate to suppress concurrent
  /// seek commands during a long (network) seek.
  final Stream<bool> seeking;

  /// Playback position as percentage of duration (0–100).
  final Stream<double> percentPos;

  /// Demuxer cache download speed in bytes per second.
  final Stream<double> cacheSpeed;

  /// Cache fill state as percentage (0–100). mpv's own metric, distinct
  /// from [bufferingPercentage].
  final Stream<int> cacheBufferingState;

  /// Name of the active demuxer (e.g. `mkv`, `lavf`, `mp3`).
  final Stream<String> currentDemuxer;

  /// Name of the audio output driver actually in use post-resolution.
  final Stream<String> currentAo;

  /// Initial timestamp offset of the current file as reported by the
  /// demuxer.
  final Stream<Duration> demuxerStartTime;

  /// Tag dictionary for the active chapter (per-chapter metadata).
  final Stream<Map<String, String>> chapterMetadata;

  /// mpv version string. Stable for the lifetime of the [Player].
  final Stream<String> mpvVersion;

  /// FFmpeg version string. Stable for the lifetime of the [Player].
  final Stream<String> ffmpegVersion;

  /// Aggregate playback lifecycle as a single mutually-exclusive enum.
  ///
  /// Derived lazily from `playing` / `buffering` / `completed` /
  /// `pausedForCache` / `duration` — subscribing here opens
  /// subscriptions to those 5 streams only for as long as a listener
  /// is attached. See [MpvPlaybackState] for the state mapping.
  final Stream<MpvPlaybackState> playbackState;

  /// Embedded cover-art payload after each file load — the original
  /// codec bytes (PNG / JPEG / WEBP / …) from the file's attached
  /// picture stream, plus the MIME type. Hand straight to
  /// `Image.memory(raw.bytes)` or run your own pipeline (resize, encode,
  /// cache) — the bytes are passed through unchanged.
  ///
  /// Emits exactly once per file load: a [CoverArt] when the new
  /// file has embedded artwork, or `null` when it does not. Listen for
  /// `null` to clear stale artwork on tracks without a cover.
  final Stream<CoverArt?> coverArt;

  /// Real-time FFT frequency spectrum of the audio currently playing
  /// through the player's output, captured post-DSP (after volume,
  /// EQ, compressor, etc. — what you actually hear).
  ///
  /// Emit rate, FFT size, perceptual band layout, smoothing and dB
  /// clipping are all configured via [Player.setSpectrum]. The default
  /// preset emits 30 frames/sec with 64 log-spaced bands ready for a
  /// `CustomPainter`-style visualizer.
  ///
  /// **Lazy** — the FFT pipeline allocates and the FFI poll loop
  /// starts on the first listener, and tears down on the last cancel.
  /// Both [fft] and [pcm] share the same upstream tap, so
  /// subscribing to both costs only the FFT computation, not a second
  /// tap.
  ///
  /// Stops emitting while playback is paused (the AO ring stops
  /// receiving samples). The last [FftFrame] is "frozen" in the sense
  /// that no further events fire — hold the last value as the
  /// displayed state until playback resumes.
  final Stream<FftFrame> fft;

  /// Real-time raw PCM samples of the audio currently playing through
  /// the player's output, captured post-DSP. Use for time-domain
  /// visualisations: scrolling waveforms, accurate VU/peak meters,
  /// oscilloscopes, custom feature extractors.
  ///
  /// For frequency-domain visualisations (spectrum bars, glow
  /// effects), prefer [fft] which is computed from the same tap.
  ///
  /// Same lazy / pause semantics as [fft]. Configured by the
  /// emit rate of [Player.setSpectrum] (the FFT-side knobs are
  /// ignored for this stream).
  final Stream<PcmFrame> pcm;

  /// Per-filter PCM tap — emits [PcmFrame]s captured at the chosen
  /// [TapSide] of [filter]'s slot in the `af` chain. Use
  /// [TapSide.pre] for "input signal" overlays, [TapSide.post] for
  /// "output signal" overlays in a per-filter editor.
  ///
  /// The tap is **lazy**: the engine activates the matching hook in
  /// the audio chain only while at least one listener is attached,
  /// and tears down on the last cancel. Multiple subscribers to the
  /// same `(filter, side)` share a single underlying tap.
  ///
  /// [filter] is one of the typed [AudioEffect] values — the same
  /// 86 filters surfaced as `*Settings` fields on [AudioEffects], so
  /// every reachable filter is named at compile time. Live streams
  /// without an active af chain emit no frames; the stream is silent
  /// (no error) when the loaded libmpv does not expose the
  /// filter-tap property.
  final Stream<PcmFrame> Function(
    AudioEffect filter, {
    required TapSide side,
  }) tap;

  /// Reactive view of the current [SpectrumSettings] — the configuration
  /// of the FFT pipeline (size, bands, window, emit rate, smoothing, dB
  /// clip). Emits a fresh snapshot on every [Player.setSpectrum] /
  /// [Player.updateSpectrum] call so reactive UI can bind without
  /// polling [Player.spectrumSettings] (which remains as a synchronous
  /// accessor for callers that don't want a subscription).
  ///
  /// Mirrors the bundle-stream pattern of [replayGain] / [cache] /
  /// [audioEffects] — `setX` ↔ `stream.x` of the matching `*Settings`
  /// type. Unlike those, this one lives entirely Dart-side: the stream
  /// is fed from the FFT pipeline's local cache, not from an mpv
  /// property observer (the underlying `pcm-tap-frame` property only
  /// supplies samples, not config).
  final Stream<SpectrumSettings> spectrum;

  /// Mono min, max and RMS amplitude envelope of the current track, binned
  /// across the full track duration. Use for a static full-track
  /// overview strip with click-to-seek.
  ///
  /// Emits `null` on every track-change boundary (so renderers can
  /// clear stale data), then the envelope. A complete seekable file,
  /// local or a direct-play HTTP file, is decoded in the background:
  /// partial envelopes with [WaveformData.decoding] set, then the final
  /// one. Adaptive, non-seekable or transcoded network streams grow the
  /// envelope from playback instead, and a live stream of unknown length
  /// emits a rolling window ([WaveformData.live]).
  ///
  /// The background decode opens the source a second time, with the same
  /// network options as playback (`tls-verify`, `tls-ca-file`, headers,
  /// user agent, cookies). For a remote file that means a second download.
  ///
  /// **Listener-gated** — the native analyzer runs and the pipeline
  /// polls only while a listener is attached; the cost of a waveform
  /// nobody is listening to is zero.
  ///
  /// **Single active analysis per process.** The background analyzer is a
  /// process-global singleton: the most recent `open()` wins, so with
  /// multiple [Player]s alive only the last-loaded file's waveform is
  /// computed. This matches the single-player-per-app usage this package
  /// targets; don't rely on concurrent waveforms across players.
  final Stream<WaveformData?> waveform;

  /// Live EBU R128 loudness measurements ([Loudness]: momentary,
  /// short-term, integrated, range) from the `ebur128` stage of the
  /// audio chain.
  ///
  /// Requires the meter in the chain: enable it on the bundle with its
  /// `metadata` option on —
  ///
  /// ```dart
  /// await player.updateAudioEffects(
  ///   (e) => e.updateEbur128(
  ///       (m) => m.copyWith(enabled: true, metadata: true)),
  /// );
  /// player.stream.loudnessMeter.listen((l) => meter.paint(l.momentary));
  /// ```
  ///
  /// **Listener-gated** — the measurement poll runs only while a
  /// listener is attached. While the meter is not in the chain the
  /// stream simply emits nothing.
  final Stream<Loudness> loudnessMeter;

  /// Offline loudness scan of the loaded source ([LoudnessScan]:
  /// integrated LUFS, loudness range, sample/true peak), measured by
  /// decoding the whole file off the playback path at many times
  /// realtime — the result lands moments after the file loads, before
  /// the audio has played. Use it to volume-normalize tracks without
  /// ReplayGain tags:
  ///
  /// ```dart
  /// player.stream.loudness.listen((scan) {
  ///   if (scan?.state == LoudnessScanState.ready) {
  ///     player.setVolumeGain((-18.0 - scan!.integrated!).clamp(-24, 24));
  ///   }
  /// });
  /// ```
  ///
  /// Like [waveform], the scan opens the source a second time, with the
  /// same network options as playback.
  ///
  /// Emits one terminal [LoudnessScan] per track (`ready`, `failed`, or
  /// `unavailable` for sources that can only be measured during
  /// playback — adaptive/live streams; use [loudness] there), and
  /// `null` on the track-change boundary so stale results clear.
  ///
  /// **Lazy** — the native scan runs only while a listener is
  /// attached; an idle stream costs nothing.
  final Stream<LoudnessScan?> loudness;

  // ── Media session ──────────────────────────────────────────────────

  /// Current OS media-session config + metadata, or `null` when the
  /// session is disabled. Emits on every [Player.setMediaSession] call
  /// — `null` on disable, a fresh [MediaSession] on enable or
  /// reconfigure.
  ///
  /// To check just "enabled or not" without subscribing to every
  /// reconfigure, map and distinct:
  /// `stream.mediaSession.map((s) => s != null).distinct()`.
  final Stream<MediaSession?> mediaSession;

  /// Incoming commands issued by the OS media session — taps on the
  /// lockscreen, Bluetooth headset button presses, Siri / Google
  /// Assistant playback requests, Android Auto / CarPlay actions.
  ///
  /// By default these are auto-applied to the [Player]: play →
  /// [Player.play], pause → [Player.pause], seekTo → [Player.seek],
  /// etc. Subscribing here is for analytics, logging, or intercepting
  /// edge cases — the stream emits *after* the optimistic state
  /// update, so observing it from a UI is safe and ordered.
  ///
  /// For [MediaSessionCommandNext] / [MediaSessionCommandPrevious]:
  /// the package routes them to mpv's `playlist-next` /
  /// `playlist-prev` when a playlist is loaded; otherwise the command
  /// arrives here unhandled, for the consumer's queue logic to act
  /// on.
  final Stream<MediaSessionCommand> mediaSessionCommands;
}
