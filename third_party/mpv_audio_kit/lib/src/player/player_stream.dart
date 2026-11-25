// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../events/mpv_hook_event.dart';
import '../events/mpv_log_entry.dart';
import '../events/player_error.dart';
import '../generated/audio_effects.dart';
import '../generated/audio_effects_settings.dart';
import '../models/audio_params.dart';
import '../models/chapter.dart';
import '../models/cover_art.dart';
import '../models/demuxer_cache_state.dart';
import '../models/device.dart';
import '../models/fft_frame.dart';
import '../models/loudness.dart';
import '../models/loudness_scan.dart';
import '../models/media_session.dart';
import '../models/mpv_track.dart';
import '../models/pcm_frame.dart';
import '../models/playlist.dart';
import '../models/waveform_data.dart';
import '../reactive/default_reactives.dart';
import '../reactive/reactive_property.dart';
import '../types/enums/cover.dart';
import '../types/enums/format.dart';
import '../types/enums/gapless.dart';
import '../types/enums/hls_bitrate.dart';
import '../types/enums/loop.dart';
import '../types/enums/spdif.dart';
import '../types/enums/tap_side.dart';
import '../types/sealed/channels.dart';
import '../types/sealed/media_session_command.dart';
import '../types/settings/cache_settings.dart';
import '../types/settings/demuxer_settings.dart';
import '../types/settings/replay_gain_settings.dart';
import '../types/settings/spectrum_settings.dart';
import '../types/state/audio_output_state.dart';
import '../types/state/mpv_playback_state.dart';
import '../types/state/prefetch_state.dart';
import 'mpv_playback_state_derive.dart';

/// Typed streams of the [Player]'s state and events.
///
/// Access via `player.stream`:
/// ```dart
/// player.stream.playing.listen((isPlaying) { ... });
/// player.stream.position.listen((pos) { ... });
/// ```
///
/// A state stream (`playing`, `volume`, `position`, `playlist`,
/// `playbackState`, `coverArt`, `waveform`, …) gives each new subscriber
/// the current value first, then every change, so a `StreamBuilder` needs
/// no `initialData`. To wait for the next change instead, skip the first
/// event: `player.stream.volume.skip(1).first`.
///
/// An event stream (`seekCompleted`, `endFile`, `error`, `log`,
/// `internalLog`, `hook`, `mediaSessionCommands`, `fft`, `pcm`,
/// `loudnessMeter`, `tap`) only delivers what happens after `listen()`.
///
/// {@category State and streams}
interface class PlayerStream {
  /// Internal constructor wired by `Player`. Not part of the public API:
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
    required ReactiveProperty<List<AudioEffect>> audioEffects,
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
    required this.loudnessScan,
    required Stream<PcmFrame> Function(
      AudioFilter filter, {
      int instance,
      required TapSide side,
    })
    tap,
    required this.mediaSessionCommands,
  }) : _tap = tap,
       playing = reactives.playing.stream,
       playWhenReady = reactives.playWhenReady.stream,
       position = reactives.position.stream,
       duration = reactives.duration.stream,
       durationEstimated = reactives.durationEstimated.stream,
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
       // and there is no codec or codec-name sibling on the output side, so
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

  /// Aggregate [MpvPlaybackState] derived from 5 signals the library
  /// already tracks (`playing`, `buffering`, `completed`, `pausedForCache`
  /// and whether `path` names a loaded file). Lazy: subscriptions to the source
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
      fileLoaded: r.path.value.isNotEmpty,
    );

    return aggregateStream<MpvPlaybackState>(snapshot, [
      r.playing.changes,
      bufferingProp.changes,
      completedProp.changes,
      r.pausedForCache.changes,
      r.path.changes,
    ]);
  }

  // ── Playback and lifecycle ───────────────────────────────────────────────

  /// Emits whenever the active playlist changes (adds, removes, reorders).
  final Stream<Playlist> playlist;

  /// Emits when actual audio output starts or stops: mpv's `core-idle`
  /// (inverted). Toggles transiently during seeks and buffering. For a
  /// stable play-pause button, listen to [playWhenReady] instead.
  final Stream<bool> playing;

  /// Emits the user-intent-to-play axis, driven by [Player.play],
  /// [Player.pause], [Player.open] and [Player.stop] (and released at the
  /// natural end of content). Stable across seeks and buffering; this is
  /// the signal to bind a play-pause button to. See
  /// [PlaybackState.playWhenReady].
  final Stream<bool> playWhenReady;

  /// Emits `true` when playback reaches the end of a single track or of the
  /// last playlist entry, not between entries and not while looping. See
  /// [PlaybackState.completed].
  final Stream<bool> completed;

  /// Emits the current playback position as a [Duration].
  final Stream<Duration> position;

  /// Emits once after a seek request has been fully reinitialized by mpv
  /// and playback is about to resume, i.e. the authoritative
  /// `MPV_EVENT_PLAYBACK_RESTART` signal.
  final Stream<void> seekCompleted;

  /// Emits the duration of the current track. Zero when unknown: a live
  /// stream, nothing loaded, or a track still loading. The entry's
  /// [Media.waveformDurationHint] over a duration estimated from the
  /// bitrate, as [PlaybackState.duration].
  final Stream<Duration> duration;

  /// Emits whether the duration is an estimate from the bitrate, with no
  /// hint to replace it ([PlaybackState.durationEstimated]).
  final Stream<bool> durationEstimated;

  /// Emits the current soft volume in percent (0 to 1000, 100 is unity).
  final Stream<double> volume;

  /// Emits the current playback speed multiplier.
  final Stream<double> rate;

  /// Emits the current pitch multiplier.
  final Stream<double> pitch;

  /// Emits `true` while a file opens, from start-file to file-loaded, and
  /// `false` once it is loaded, ends or fails. A network stall during
  /// playback shows on [pausedForCache], not here; [playbackState] folds
  /// both into one value.
  final Stream<bool> buffering;

  /// Emits the absolute timestamp the demuxer has buffered up to
  /// (`demuxer-cache-time`), not a depth: [bufferDuration] is the headroom
  /// ahead of the playhead. See [NetworkState.buffer].
  final Stream<Duration> buffer;

  /// Emits the cache fill as a percentage (0.0 to 100.0) of
  /// [CacheSettings.secs]. Near 0 with mpv's default `cache-secs` of 1000
  /// hours: see [NetworkState.bufferingPercentage] for what to use instead.
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

  /// Aggregate ReplayGain configuration: emits a fresh
  /// [ReplayGainSettings] whenever any of mode, preamp, clip or
  /// fallback changes. Set with [Player.setReplayGain].
  final Stream<ReplayGainSettings> replayGain;

  /// Emits the software volume gain in dB.
  final Stream<double> volumeGain;

  /// Emits mpv's `volume-gain-min` in dB. See [PlayerSettings.volumeGainMin].
  final Stream<double> volumeGainMin;

  /// Emits mpv's `volume-gain-max` in dB. See [PlayerSettings.volumeGainMax].
  final Stream<double> volumeGainMax;

  /// Emits the volume the audio driver exposes (`ao-volume`); `null` when
  /// the active audio output doesn't expose it. See
  /// [OutputState.systemVolume].
  final Stream<double?> systemVolume;

  /// Emits the mute the audio driver exposes (`ao-mute`); `null` when the
  /// active audio output doesn't expose it.
  final Stream<bool?> systemMute;

  /// Aggregate cache configuration: emits a fresh [CacheSettings]
  /// whenever any of mode, secs, onDisk, pause, pauseWait or pauseInitial
  /// changes. Set with [Player.setCache].
  final Stream<CacheSettings> cache;

  /// Aggregate demuxer-buffering configuration: emits a fresh
  /// [DemuxerSettings] whenever any of maxBytes, maxBackBytes or readahead
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

  /// Emits whether the null audio output runs untimed.
  final Stream<bool> audioNullUntimed;

  /// All tracks reported by mpv for the current file (audio + embedded
  /// picture + any other type the demuxer surfaced). See
  /// [FileState.tracks] for the filtering pattern.
  final Stream<List<MpvTrack>> tracks;

  /// Currently-active audio track, or `null` when none is selected.
  final Stream<MpvTrack?> currentAudioTrack;

  /// Emits the current S/PDIF passthrough codec set. Empty set =
  /// passthrough disabled.
  final Stream<Set<Spdif>> audioSpdif;

  /// Emits mpv's `volume-max`. See [PlayerSettings.volumeMax].
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

  /// Lifecycle of mpv's audio output: in practice `closed`, then `active`,
  /// or `failed` when no output opens. [AudioOutputState.initializing] is
  /// set while the output opens, but the opening blocks mpv's core, so it
  /// is almost never observed. A typed [LogError] is emitted on [error]
  /// the moment this stream emits [AudioOutputState.failed]; the state then
  /// stays `failed`, and a second failure in a row emits nothing new.
  ///
  /// When no device can be opened mpv usually opens the null output
  /// instead, and this stream says [AudioOutputState.active] while
  /// nothing is heard. Then [error] gets a [LogError] once for that
  /// opening, unless the app chose the null driver itself.
  final Stream<AudioOutputState> audioOutputState;

  /// The effects chain: the ordered list of stages in mpv's `af`
  /// pipeline. Set with [Player.setAudioEffects] or
  /// [Player.updateAudioEffects].
  final Stream<List<AudioEffect>> audioEffects;

  // ── Cover Art ──────────────────────────────────────────────────────────────

  /// Emits the current external cover-art auto-load policy.
  final Stream<Cover> coverArtAuto;

  /// Emits for **every** file-end event: clean completions, stops, errors,
  /// and premature EOFs alike, with the `Media`, position and duration of
  /// the entry that ended.
  ///
  /// [MpvFileEndedEventX.reachedNaturalEnd] is `true` for any EOF, and mpv
  /// also reports EOF when a network stream drops. To tell the two apart,
  /// compare [MpvFileEndedEvent.position] with
  /// [MpvFileEndedEvent.duration], not the state: when the event arrives
  /// the state can already describe the next entry. The last entry parks
  /// on its end instead ([PlaybackState.completed]) and emits here only
  /// when it is stopped or replaced.
  final Stream<MpvFileEndedEvent> endFile;

  /// Emits typed error events from the mpv engine.
  ///
  /// Use pattern matching to distinguish [EndFileError] (playback
  /// failures) from [LogError] (informational engine errors).
  final Stream<PlayerError> error;

  /// Engine-side log entries from mpv at the configured log level
  /// (`PlayerConfiguration.logLevel`).
  ///
  /// Prefix examples: `'ffmpeg'`, `'demux'`, `'ao'`, `'cplayer'`.
  /// For library-side messages (parse warnings, hook timeouts), see
  /// [internalLog].
  final Stream<MpvLogEntry> log;

  /// Library-side log entries: parse warnings, hook timeouts, and
  /// other messages produced by the Dart layer itself. Always carries
  /// `prefix: 'mpv_audio_kit'`.
  ///
  /// Disjoint from [log] so you can route engine and library noise to
  /// different sinks (e.g. show only [log] in a debug overlay while
  /// routing [internalLog] to crash reporting).
  final Stream<MpvLogEntry> internalLog;

  /// Emits whenever mpv fires a registered hook (see `Player.registerHook`).
  final Stream<MpvHookEvent> hook;

  /// Lifecycle of mpv's background playlist-prefetch. Works uniformly
  /// across HLS, DASH, raw HTTP, SMB, and local files.
  final Stream<PrefetchState> prefetchState;

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

  /// Whether the stream is only partially seekable (HLS or DASH window).
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

  /// Source playlist of the current entry (`playlist-path`): the `.m3u` or
  /// `.pls` path it was expanded from; empty when not loaded via a playlist.
  final Stream<String> playlistPath;

  /// URI as actually opened post-redirect. Mirrors mpv's
  /// `stream-open-filename`.
  final Stream<String> streamOpenFilename;

  /// A-B loop start point. `null` when disabled, and again once the file
  /// it was set on ends. Set via [Player.setAbLoopA].
  final Stream<Duration?> abLoopA;

  /// A-B loop end point. `null` when disabled, and again once the file it
  /// was set on ends. Set via [Player.setAbLoopB].
  final Stream<Duration?> abLoopB;

  /// How many times playback jumps back to A after the first pass.
  /// `null` = infinite, `0` = off. Set via [Player.setAbLoopCount].
  final Stream<int?> abLoopCount;

  /// How many more times playback will jump back to A. `null` only when
  /// the count is infinite; it starts from [abLoopCount] at every load and
  /// every change of A, B or the count. Read-only; mirrors mpv's
  /// `remaining-ab-loops`.
  final Stream<int?> remainingAbLoops;

  /// Whether mpv is currently seeking. UI gate to suppress concurrent
  /// seek commands during a long (network) seek.
  final Stream<bool> seeking;

  /// Playback position as percentage of duration (0 to 100).
  final Stream<double> percentPos;

  /// Demuxer cache download speed in bytes per second.
  final Stream<double> cacheSpeed;

  /// Cache fill state as percentage (0 to 100). mpv's own metric, distinct
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
  /// Derived lazily from `playing`, `buffering`, `completed`,
  /// `pausedForCache` and `path` (idle means no file is loaded).
  /// Subscribing here opens subscriptions to those 5 streams only for as
  /// long as a listener is attached. See [MpvPlaybackState] for the state mapping.
  final Stream<MpvPlaybackState> playbackState;

  /// Embedded cover-art payload after each file load: the original
  /// codec bytes (PNG, JPEG, WEBP, …) from the file's attached
  /// picture stream, plus the MIME type. Hand straight to
  /// `Image.memory(raw.bytes)` or run your own pipeline (resize, encode,
  /// cache); the bytes are passed through unchanged.
  ///
  /// Emits when each file loads, including mpv's reloads of the same file:
  /// a [CoverArt] when the new file has embedded artwork, or `null` when
  /// it does not. [Player.open], [Player.openAll] and
  /// [Player.openPlaylistFile] also emit `null` when they return, so the
  /// new file's value follows a `null`, and the same cover can arrive
  /// again as a new object. Listen for `null` to clear stale artwork on
  /// tracks without a cover.
  final Stream<CoverArt?> coverArt;

  /// Real-time FFT frequency spectrum of the audio currently playing
  /// through the player's output, captured post-DSP (after volume,
  /// EQ, compressor, etc.: what you actually hear).
  ///
  /// Emit rate, FFT size, perceptual band layout, smoothing and dB
  /// clipping are all configured via [Player.setSpectrum]. The default
  /// preset emits 30 frames a second with 64 log-spaced bands ready for a
  /// `CustomPainter`-style visualizer.
  ///
  /// **Lazy**: the FFT pipeline allocates and the FFI poll loop
  /// starts on the first listener, and tears down on the last cancel.
  /// Both [fft] and [pcm] share the same upstream tap, so
  /// subscribing to both costs only the FFT computation, not a second
  /// tap.
  ///
  /// Stops emitting while playback is paused (the AO ring stops
  /// receiving samples). The last [FftFrame] is "frozen" in the sense
  /// that no further events fire; hold the last value as the
  /// displayed state until playback resumes. When the stream gets its
  /// first listener while paused, that listener receives the last frame
  /// once.
  ///
  /// The tap behind [fft] and [pcm] is one per process: with several
  /// players, the streams of each show the audio the last output wrote,
  /// also on a player that is paused or stopped.
  final Stream<FftFrame> fft;

  /// Real-time raw PCM samples of the audio currently playing through
  /// the player's output, captured post-DSP. Use for time-domain
  /// visualisations: accurate VU and peak meters, oscilloscopes, custom
  /// feature extractors.
  ///
  /// Each frame holds the latest audio written to the output, up to
  /// 4096 frames per channel, so consecutive frames overlap (by about
  /// 60 % at the default 33 ms). Appending them one after the other
  /// repeats audio; a scrolling display has to keep only the samples it
  /// has not drawn yet.
  ///
  /// For frequency-domain visualisations (spectrum bars, glow
  /// effects), prefer [fft] which is computed from the same tap.
  ///
  /// Same lazy and pause semantics as [fft]. Configured by the
  /// emit rate of [Player.setSpectrum] (the FFT-side knobs are
  /// ignored for this stream).
  final Stream<PcmFrame> pcm;

  /// Per-stage PCM tap: emits [PcmFrame]s captured at the chosen
  /// [TapSide] of one [filter] stage in the effects chain. Use
  /// [TapSide.pre] for "input signal" overlays, [TapSide.post] for
  /// "output signal" overlays in a per-filter editor.
  ///
  /// The tap is **lazy**: the engine activates the matching hook in
  /// the audio chain only while at least one listener is attached,
  /// and tears down on the last cancel. Multiple subscribers to the
  /// same `(filter, instance, side)` share a single underlying tap. The
  /// native tap state is one per process: two players tapping the same
  /// stage read one mixed feed, and at most eight stages are tapped
  /// across all players. The players of one isolate keep that list
  /// together. A player in another isolate replaces it with its own.
  ///
  /// [filter] names the stage's filter and [instance] which of its
  /// occurrences in [PlayerSettings.audioEffects] (0, the default, for the
  /// first): with two [EqualizerEffect]s in the list, `instance: 1` taps
  /// the second. Disabled stages count too, and a disabled stage emits
  /// nothing. The tap follows the occurrence, not a particular stage:
  /// moving other filters around keeps it on the same one, while swapping
  /// the two equalizers swaps what `instance: 0` taps. libmpv captures up
  /// to 8 stages at a time. Live streams without an active af chain emit
  /// no frames; the stream is silent (no error) when the loaded libmpv
  /// does not expose the filter-tap property.
  Stream<PcmFrame> tap(
    AudioFilter filter, {
    int instance = 0,
    required TapSide side,
  }) => _tap(filter, instance: instance, side: side);

  final Stream<PcmFrame> Function(
    AudioFilter filter, {
    int instance,
    required TapSide side,
  })
  _tap;

  /// Reactive view of the current [SpectrumSettings]: the configuration
  /// of the FFT pipeline (size, bands, window, emit rate, smoothing, dB
  /// clip). Emits a fresh snapshot on every [Player.setSpectrum] or
  /// [Player.updateSpectrum] call so reactive UI can bind without
  /// polling `state.settings.spectrum` (which remains as a synchronous accessor
  /// for callers that don't want a subscription).
  ///
  /// Mirrors the bundle-stream pattern of [replayGain], [cache] and
  /// [audioEffects]: `setX` ↔ `stream.x` of the matching settings
  /// type. Unlike those, this one lives entirely Dart-side: the stream
  /// is fed from the FFT pipeline's local cache, not from an mpv
  /// property observer (the underlying `pcm-tap-frame` property only
  /// supplies samples, not config).
  final Stream<SpectrumSettings> spectrum;

  /// Mono min, max and RMS amplitude envelope of the current track, binned
  /// across the full track duration. Use for a static full-track
  /// overview strip with click-to-seek.
  ///
  /// Emits `null` each time a file loads (so renderers can clear stale
  /// data), then the envelope. The same file loaded again keeps a final
  /// envelope, with no `null`: mpv keeps its analysis. A local file is decoded in the
  /// background: partial envelopes with [WaveformData.decoding] set, then
  /// the final one. An HTTP file that plays from its start is decoded the
  /// same way from mpv's cache as it downloads. Adaptive, non-seekable or
  /// transcoded network streams grow the envelope from playback instead,
  /// and a live stream of unknown length emits a rolling window
  /// ([WaveformData.live]).
  ///
  /// The analysis decodes the audio track the player plays, also a
  /// `content://` source on Android. With an external track selected
  /// ([Player.addAudioTrack]) the envelope grows from playback, and the
  /// loudness scan reports [LoudnessScanState.unavailable]. It also reads
  /// a file of more than 8 channels or whose channel count changes, and
  /// puts a file whose timestamps do not start at zero on the playback
  /// time axis.
  ///
  /// A remote file is downloaded once: the decode reads the packets mpv
  /// already cached. When one pass from the start to the end is not
  /// possible (playback starting further in, a seek past the cache, a
  /// track switch, a cut download, a file larger than the cache), it opens
  /// the source a second time, with the same network options as playback
  /// (`tls-verify`, `tls-ca-file`, headers, user agent, cookies), and gives
  /// the same result.
  ///
  /// **Listener-gated**: the native analyzer runs and the pipeline
  /// polls only while a listener is attached. With no listener on any
  /// player, a waveform costs nothing.
  ///
  /// **Single active analysis per process.** The background analyzer is a
  /// process-global singleton: the most recent `open()` wins, so with
  /// multiple [Player]s alive only the last-loaded file's waveform is
  /// computed, and the stream of every listening player with a file loaded
  /// shows it, also when another player loaded that file; a player with
  /// nothing loaded shows none. While one player listens, the files
  /// of a player with no listener are decoded too. An envelope that grows
  /// from playback takes in the audio of every player. This matches the
  /// single-player-per-app usage this package targets; don't rely on
  /// concurrent waveforms across players. The analyzer stays on while a
  /// player of this isolate listens: another player's cancel or dispose
  /// does not turn it off.
  final Stream<WaveformData?> waveform;

  /// Live EBU R128 loudness measurements ([Loudness]: momentary,
  /// short-term, integrated, range) from the `ebur128` stage of the
  /// audio chain.
  ///
  /// Requires the meter in the chain: it reads the first enabled
  /// [Ebur128Effect] of the list with its `metadata` option on:
  ///
  /// ```dart
  /// await player.updateAudioEffects(
  ///   (fx) => [...fx, const Ebur128Effect(metadata: true)],
  /// );
  /// player.stream.loudnessMeter.listen((l) => meter.paint(l.momentary));
  /// ```
  ///
  /// **Listener-gated**: the measurement poll runs only while a
  /// listener is attached. While the meter is not in the chain the
  /// stream simply emits nothing. A new listener gets the next reading
  /// (polled every 100 ms), not the last one.
  ///
  /// The meter starts over at every seek, loop wrap, track change and
  /// output reopen, so [Loudness.integrated] and [Loudness.range] cover
  /// the audio since then. For a whole track use [loudnessScan].
  final Stream<Loudness> loudnessMeter;

  /// Offline loudness scan of the loaded source ([LoudnessScan]:
  /// integrated LUFS, loudness range, sample and true peak), measured by
  /// decoding the whole file off the playback path at many times
  /// realtime; the result lands moments after the file loads, before
  /// the audio has played. Use it to volume-normalize tracks without
  /// ReplayGain tags:
  ///
  /// ```dart
  /// player.stream.loudnessScan.listen((scan) {
  ///   if (scan?.state == LoudnessScanState.ready) {
  ///     player.setVolumeGain((-18.0 - scan!.integrated!).clamp(-24, 24));
  ///   }
  /// });
  /// ```
  ///
  /// Like [waveform], the scan of a remote file reads mpv's cache, and
  /// opens the source a second time only when that pass is not possible.
  /// It reads the same sources as [waveform]: the audio track the player
  /// plays, `content://`, more than 8 channels and timestamps that do not
  /// start at zero.
  ///
  /// While the scan runs it emits `scanning` snapshots with a
  /// [LoudnessScan.progress]. Then one terminal [LoudnessScan] per track
  /// (`ready`, `failed`, or `unavailable` for sources that can only be
  /// measured during playback, such as adaptive or live streams; use
  /// [loudnessMeter] there), and `null` each time a file loads, so stale
  /// results clear. The same file loaded again keeps a terminal result,
  /// with no `null`.
  ///
  /// **Lazy**: the native scan runs only while a listener is
  /// attached; with no listener on any player it costs nothing. Like the
  /// [waveform] analyzer, it stays on while a player of this isolate
  /// listens.
  ///
  /// **Single active scan per process**, as for [waveform]: with several
  /// players the last `open()` wins, and the stream of every listening
  /// player with a file loaded shows that file. The gain example above
  /// assumes one player.
  final Stream<LoudnessScan?> loudnessScan;

  // ── Media session ──────────────────────────────────────────────────

  /// Current OS media-session config + metadata, or `null` when the
  /// session is disabled. Emits on every [Player.setMediaSession] call:
  /// `null` on disable, a fresh [MediaSession] on enable or
  /// reconfigure.
  ///
  /// To check just "enabled or not" without subscribing to every
  /// reconfigure, map and distinct:
  /// `stream.mediaSession.map((s) => s != null).distinct()`.
  final Stream<MediaSession?> mediaSession;

  /// Incoming commands issued by the OS media session: taps on the
  /// lockscreen, Bluetooth headset button presses, Siri or Google
  /// Assistant playback requests, Android Auto or CarPlay actions.
  ///
  /// By default these are auto-applied to the [Player]: play →
  /// [Player.play], pause → [Player.pause], seekTo → [Player.seek],
  /// etc. Subscribing here is for analytics, logging, or intercepting
  /// edge cases. The stream emits as the command is handed to the
  /// player, before mpv confirms it: `state` may still hold the previous
  /// value here. To follow the result, observe the matching stream (for
  /// example [shuffle], [loop] or [rate]).
  ///
  /// For [MediaSessionCommandNext] and [MediaSessionCommandPrevious]:
  /// the package routes them to mpv's `playlist-next` or
  /// `playlist-prev` when the playlist holds more than one entry and
  /// [MediaSession.autoApplyPlaylistNavigation] is on (the default);
  /// otherwise the command arrives here unhandled, for the consumer's
  /// queue logic to act on.
  final Stream<MediaSessionCommand> mediaSessionCommands;
}
