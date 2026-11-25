// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../generated/audio_effects_settings.dart';
import '../models/chapter.dart';
import '../models/device.dart';
import '../models/media.dart';
import '../models/media_session.dart';
import '../models/source_resolve_request.dart';
import '../pcm/pcm_format.dart';
import '../pcm/pcm_source.dart';
import '../types/enums/cover.dart';
import '../types/enums/format.dart';
import '../types/enums/gapless.dart';
import '../types/enums/hls_bitrate.dart';
import '../types/enums/hook.dart';
import '../types/enums/log_level.dart';
import '../types/enums/loop.dart';
import '../types/enums/spdif.dart';
import '../types/sealed/channels.dart';
import '../types/sealed/track.dart';
import '../types/settings/cache_settings.dart';
import '../types/settings/demuxer_settings.dart';
import '../types/settings/replay_gain_settings.dart';
import '../types/settings/spectrum_settings.dart';
import 'player_configuration.dart';
import 'player_state.dart';
import 'player_stream.dart';

/// Public surface of the [Player]: every method, getter, and stream a
/// consumer interacts with.
///
/// Exists so test code can mock the player cleanly:
///
/// ```dart
/// class MockPlayer extends Mock implements PlayerApi {}
/// ```
///
/// Without this interface a mock would have to extend `Player` itself,
/// which drags in the FFI handle, the event isolate, and the `_PlayerBase`
/// initialization. None of that is mockable in a unit test.
///
/// `Player implements PlayerApi`. Production code that takes a `Player`
/// argument should consider taking a `PlayerApi` instead unless it needs
/// access to extension members not on the interface (none today).
abstract interface class PlayerApi {
  /// The configuration captured at construction time.
  PlayerConfiguration get configuration;

  /// Synchronous snapshot of the player's complete state. Updated on
  /// every observed property change before the corresponding stream
  /// emits.
  PlayerState get state;

  /// Typed event streams for individual state fields and transient
  /// events.
  PlayerStream get stream;

  // ── Lifecycle ──────────────────────────────────────────────────────

  /// Completes once the player has started its core, or with a
  /// [PlayerInitException] when it could not. Every call already waits
  /// for it, so awaiting it is only needed to learn of a failed start
  /// before the first call, as when a screen shows an error at once.
  Future<void> get initialized;

  /// Tears down the player. Idempotent: every call returns the same
  /// teardown future.
  ///
  /// mpv shuts down in a background isolate, so the app keeps drawing
  /// while the audio output closes. The future completes once mpv is gone.
  ///
  /// On Android a player whose isolate exits without it (the engine was
  /// destroyed while the app's process stays) stops and frees libmpv on
  /// its own.
  Future<void> dispose();

  // ── Loading ────────────────────────────────────────────────────────

  /// Loads [media] as the sole playlist entry and optionally starts
  /// playback. When [play] is null the configuration's autoplay value
  /// decides. Replaces any currently loaded file or playlist.
  Future<void> open(Media media, {bool? play});

  /// Loads [medias] as the new playlist, optionally starting at [index]
  /// (clamped to the valid range) and optionally starting playback. The
  /// multi-item counterpart of [open]. It succeeds or fails as a whole:
  /// see [Player.openAll].
  Future<void> openAll(List<Media> medias, {bool? play, int index = 0});

  /// Loads a playlist file or URL (`.m3u`, `.m3u8`, `.pls` or `.cue`) as the
  /// new playlist via mpv's `loadlist`, expanding its entries into the
  /// playlist: the path for internet-radio station lists and remote `.m3u`
  /// playlists. Contrast with [open], which loads a single entry. See
  /// [Player.openPlaylistFile] for the per-[Media] option caveats.
  Future<void> openPlaylistFile(Media playlist, {bool? play});

  /// Creates a live [PcmSource] of [format] and opens it as the sole
  /// playlist entry. When [play] is null the configuration's autoplay
  /// value decides, as for [open]. See [Player.openPcmStream].
  Future<PcmSource> openPcmStream(
    PcmFormat format, {
    bool? play,
    Duration maxBuffered = const Duration(seconds: 30),
    bool lowLatency = false,
    Map<String, Object?>? extras,
  });

  // ── Playback ───────────────────────────────────────────────────────

  /// Starts or resumes playback (sets the play-pause intent to play).
  /// Idempotent while playing. Once the queue has ended
  /// ([PlaybackState.completed]) it starts the last track again from its
  /// beginning; after `stop(keepPlaylist: true)` it starts the entry that
  /// stopped from its beginning; with nothing loaded, or at the end of a
  /// source that cannot seek back, the intent stays off.
  Future<void> play();

  /// Pauses playback, preserving the playhead position. Idempotent.
  Future<void> pause();

  /// Stops playback and unloads the current file. The playlist is cleared
  /// and the next track must be loaded with [open], unless [keepPlaylist]
  /// keeps the entries: the playlist index stays on the entry that
  /// stopped, [next] and [previous] move it with nothing loaded, and [play]
  /// starts it from its beginning.
  Future<void> stop({bool keepPlaylist = false});

  /// Seeks within the current file. With [relative] `false` [position] is
  /// an absolute timestamp, a negative one going to the start; with `true`
  /// it is a signed offset from the playhead. [exact] forces a
  /// sample-accurate (slower) seek.
  Future<void> seek(Duration position, {bool relative, bool exact});

  /// Seeks by percentage of the file duration (0 to 100). See
  /// [Player.seekToPercent].
  Future<void> seekToPercent(double percent, {bool relative, bool exact});

  /// Jumps back to where playback was before the last jump in the current
  /// file (mpv's `revert-seek`); throws [MpvCommandException] when there
  /// is none yet. See [Player.revertSeek].
  Future<void> revertSeek();

  /// Jumps to the 0-based chapter [index] in the current file; throws
  /// [MpvCommandException] when [index] is out of range.
  Future<void> setChapter(int index);

  /// Replaces the current file's chapter markers with [chapters], an
  /// external-chapters injection for sources whose container carries none
  /// (e.g. an extracted audio stream whose chapters are published
  /// separately). Writes mpv's
  /// `chapter-list` directly, so [PlayerStream.chapters] reflect them and
  /// [setChapter] navigates them. Call after the file is loaded; an empty
  /// list clears them.
  Future<void> setChapters(List<Chapter> chapters);

  /// Sets the A-B loop start point for the current file; `null` disables
  /// it. See [Player.setAbLoopA].
  Future<void> setAbLoopA(Duration? position);

  /// Sets the A-B loop end point for the current file; `null` disables it.
  Future<void> setAbLoopB(Duration? position);

  /// Sets how many times playback jumps back to A after the first pass;
  /// `null` loops infinitely and `0` turns the loop off.
  Future<void> setAbLoopCount(int? count);

  /// Saves a "watch later" resume point for the current file (mpv's
  /// `write-watch-later-config`). See [Player.writeResumeConfig].
  Future<void> writeResumeConfig();

  /// Deletes the "watch later" resume point for the current file, or for
  /// [filename] when given. See [Player.deleteResumeConfig].
  Future<void> deleteResumeConfig({String? filename});

  // ── Playlist ───────────────────────────────────────────────────────

  /// Appends [media] to the end of the playlist.
  Future<void> add(Media media);

  /// Removes the playlist entry at [index]. Throws [RangeError] if [index]
  /// is out of range.
  Future<void> remove(int index);

  /// Advances to the next playlist entry and returns `true`, or `false`
  /// when there is none. With [force] true, advancing past the last entry
  /// stops playback; the default does nothing at the end. After
  /// `stop(keepPlaylist: true)` it moves the entry that stopped, with
  /// nothing loaded.
  Future<bool> next({bool force});

  /// Returns to the previous playlist entry and returns `true`, or `false`
  /// when there is none. With [force] true, going back past the first
  /// entry stops playback; the default does nothing at the start. After
  /// `stop(keepPlaylist: true)` it moves the entry that stopped, with
  /// nothing loaded.
  Future<bool> previous({bool force});

  /// Jumps to the next entry from a different source playlist
  /// (`playlist-path`), navigation across concatenated playlists. Returns
  /// `false` when there is none.
  Future<bool> nextPlaylist();

  /// Jumps to the first of the previous entries from a different source
  /// playlist (`playlist-path`). The reverse of [nextPlaylist].
  Future<bool> previousPlaylist();

  /// Jumps to the playlist entry at [index] and plays it. Throws
  /// [RangeError] if [index] is out of range.
  Future<void> jump(int index);

  /// Moves the playlist entry from index [from] to index [to]. Throws
  /// [RangeError] if either is out of range.
  Future<void> move(int from, int to);

  /// Replaces the playlist entry at [index] with [media]. Throws
  /// [RangeError] if [index] is out of range.
  Future<void> replace(int index, Media media);

  /// Inserts [media] at [index] in the playlist, before the entry there;
  /// [index] equal to the length appends. The current entry keeps
  /// playing. Throws [RangeError] if [index] is outside `0..length`. See
  /// [Player.insert].
  Future<void> insert(int index, Media media);

  /// Removes every entry from the playlist; with [keepCurrent] true the
  /// current one stays and keeps playing. See [Player.clearPlaylist].
  Future<void> clearPlaylist({bool keepCurrent = false});

  /// Sets the loop policy (off, current file, or whole playlist). Turned on
  /// once the queue has ended ([PlaybackState.completed]), it rewinds:
  /// [Loop.file] seeks the track to its start, [Loop.playlist] moves to the
  /// first entry, and both stay paused. Call [play] to start again.
  Future<void> setLoop(Loop loop);

  /// Enables or disables shuffled playlist order.
  Future<void> setShuffle(bool shuffle);

  /// Enables or disables prefetching the next playlist entry during
  /// playback. Hooks and the source resolver then also run for the next
  /// entry while the current one plays: see [Player.setPrefetchPlaylist].
  Future<void> setPrefetchPlaylist(bool enabled);

  // ── Audio output ───────────────────────────────────────────────────

  /// Sets the soft volume in percent (`100` is unattenuated), from 0 to
  /// 1000. [setVolumeMax] does not cap it: see [Player.setVolume].
  Future<void> setVolume(double volume);

  /// Sets the playback rate multiplier (`1.0` is normal speed).
  Future<void> setRate(double rate);

  /// Sets the pitch multiplier (`1.0` leaves pitch unchanged).
  Future<void> setPitch(double pitch);

  /// Mutes or unmutes the output.
  Future<void> setMute(bool mute);

  /// Selects the audio output [device].
  Future<void> setAudioDevice(Device device);

  /// Enables or disables holding pitch constant when the rate changes.
  Future<void> setPitchCorrection(bool enable);

  /// Sets the audio sync offset relative to the playback clock.
  Future<void> setAudioDelay(Duration delay);

  /// Sets the gapless-playback policy across playlist boundaries.
  Future<void> setGapless(Gapless gapless);

  /// Applies the ReplayGain configuration atomically.
  Future<void> setReplayGain(ReplayGainSettings settings);

  /// Sets the gain in dB applied on top of the volume, from -150 to +150.
  /// [setVolumeGainMin] and [setVolumeGainMax] do not cap it.
  Future<void> setVolumeGain(double gainDb);

  /// Sets mpv's `volume-gain-min`, in dB: the floor of mpv's relative
  /// steps on the gain (`add`, `cycle`), not of [setVolumeGain].
  Future<void> setVolumeGainMin(double gainDb);

  /// Sets mpv's `volume-gain-max`, in dB: the top of mpv's relative steps
  /// on the gain (`add`, `cycle`), not of [setVolumeGain].
  Future<void> setVolumeGainMax(double gainDb);

  /// Sets mpv's `volume-max`, in percent: the top of mpv's relative volume
  /// steps (`add`, `cycle`), and a natural top for a volume slider. It
  /// does not cap [setVolume].
  Future<void> setVolumeMax(double limit);

  /// Sets the volume the audio driver exposes in percent (`ao-volume`),
  /// distinct from the soft [setVolume]: the app's own stream on most
  /// drivers, the whole device with ALSA and WASAPI in exclusive mode. See
  /// [Player.setSystemVolume]. Throws [RangeError] outside `[0, 100]`.
  /// Best-effort: silently ignored (no throw) when the active audio output
  /// doesn't expose system volume, as on iOS and Android.
  Future<void> setSystemVolume(double volume);

  /// Sets the mute the audio driver exposes (`ao-mute`), distinct from the
  /// soft [setMute], with the reach of [setSystemVolume]. Best-effort:
  /// silently ignored (no throw) when unsupported by the AO.
  Future<void> setSystemMute(bool mute);

  /// Opens the audio device in exclusive mode when [exclusive] is true:
  /// WASAPI and CoreAudio take the device, PipeWire keeps other streams
  /// off the sink, and iOS and Android's default driver ignore it. See
  /// [Player.setAudioExclusive].
  Future<void> setAudioExclusive(bool exclusive);

  /// Reports a "music" media role to the OS audio server (PulseAudio or
  /// PipeWire) when [enable] is true (mpv's `audio-set-media-role`). On
  /// Android it only tags the content type: see [Player.setAudioMediaRole].
  Future<void> setAudioMediaRole(bool enable);

  /// Sets the set of codecs to pass through as bitstream rather than
  /// decode. See [Player.setAudioSpdif] for what
  /// stops applying to a track in passthrough.
  Future<void> setAudioSpdif(Set<Spdif> codecs);

  /// Selects the active audio [track].
  Future<void> setAudioTrack(Track track);

  /// Loads an external audio file as an extra selectable track on the current
  /// file (mpv's `audio-add`). See [Player.addAudioTrack].
  Future<void> addAudioTrack(
    Media file, {
    bool select,
    String? title,
    String? lang,
  });

  /// Removes an audio track (mpv's `audio-remove`); [Track.id] removes a
  /// specific one, [Track.auto] the current. See [Player.removeAudioTrack].
  Future<void> removeAudioTrack(Track track);

  /// Closes and reopens the audio output (mpv's `ao-reload`). The decoder
  /// keeps running.
  Future<void> reloadAudio();

  /// Re-scans the external files next to the current file (mpv's
  /// `rescan-external-files`), within mpv's auto-load options, which load
  /// none by default. See [Player.rescanExternalFiles].
  Future<void> rescanExternalFiles({bool keepSelection});

  /// Replaces the whole DSP rack atomically with [effects].
  Future<void> setAudioEffects(List<AudioEffect> effects);

  /// Mutates the current DSP rack incrementally by applying [mapper] to it
  /// and reapplying the result.
  Future<void> updateAudioEffects(
    List<AudioEffect> Function(List<AudioEffect>) mapper,
  );

  /// Sets the policy for scanning sidecar cover-art files.
  Future<void> setCoverArtAuto(Cover cover);

  /// Sets the target output sample rate in Hz, `0` for mpv's choice. See
  /// [Player.setAudioSampleRate].
  Future<void> setAudioSampleRate(int rate);

  /// Forces the output sample format; [Format.auto] lets mpv choose.
  Future<void> setAudioFormat(Format format);

  /// Forces the output channel layout; [Channels.auto] lets mpv choose.
  Future<void> setAudioChannels(Channels channels);

  /// Sets the client name reported to the audio server.
  Future<void> setAudioClientName(String name);

  /// Selects the audio output driver (e.g. `'coreaudio'`, `'wasapi'`,
  /// `'pulse'`, `'alsa'`, `'pipewire'`). Pass `'auto'` or an empty string
  /// to let mpv auto-probe the best backend (the default).
  Future<void> setAudioDriver(String driver);

  /// Applies the spectrum and PCM pipeline configuration, synchronously:
  /// it is in [PlayerSettings.spectrum] when the call returns.
  void setSpectrum(SpectrumSettings settings);

  /// Mutates the spectrum configuration by applying [mapper] to
  /// [PlayerSettings.spectrum].
  void updateSpectrum(SpectrumSettings Function(SpectrumSettings) mapper);

  // ── Cache and network ──────────────────────────────────────────────

  /// Applies the demuxer cache configuration atomically.
  Future<void> setCache(CacheSettings settings);

  /// Applies the demuxer buffering configuration atomically (forward cache
  /// cap, seekback cap, readahead).
  Future<void> setDemuxer(DemuxerSettings settings);

  /// Sets the output device buffer size.
  Future<void> setAudioBuffer(Duration size);

  /// Streams silence to keep the device open while idle when [enable] is
  /// true.
  Future<void> setAudioStreamSilence(bool enable);

  /// Sets the network I/O timeout, capped at about 36 minutes, the most
  /// FFmpeg takes.
  Future<void> setNetworkTimeout(Duration timeout);

  /// Enables or disables TLS server-certificate verification.
  Future<void> setTlsVerify(bool enable);

  /// Sets the path to a CA bundle that replaces the built-in roots for TLS
  /// verification, `''` for those roots. See [Player.setTlsCaFile].
  Future<void> setTlsCaFile(String path);

  /// Trusts the certificates of the PEM file at [path] on top of the roots
  /// in use, `''` for none. See [Player.setTlsExtraCaFile].
  Future<void> setTlsExtraCaFile(String path);

  /// Sets the HLS variant-selection policy for adaptive streams.
  Future<void> setHlsBitrate(HlsBitrate hlsBitrate);

  /// Enables mpv's HTTP cookie jar for network streams when [enable] is
  /// true.
  Future<void> setCookies(bool enable);

  /// Sets the HTTP proxy URL for network streams; empty string clears it.
  /// `http://` and `https://` sources go through it.
  Future<void> setHttpProxy(String url);

  /// Runs the null audio output untimed when [enable] is true.
  Future<void> setAudioNullUntimed(bool enable);

  // ── Media session ──────────────────────────────────────────────────

  /// Publishes the [Player] to the OS media session (lockscreen, SMTC
  /// or MPRIS), wiring up Bluetooth AVRCP, headset buttons, Siri or
  /// Google Assistant, and the platform's audio-session lifecycle per
  /// [MediaSession.interruptionPolicy].
  ///
  /// Pass `null` to disable the session and remove the entry from the system.
  /// Only one [Player] per process can have an active session at a time:
  /// calling this with a non-null [session] on a second [Player] throws a
  /// [MediaSessionException], also when that [Player] belongs to another
  /// Flutter engine of the process. The session stays with the first until it
  /// is set to `null`, its [Player] is disposed or its engine is destroyed.
  ///
  /// Incoming OS commands (play-pause from the lockscreen, next track
  /// from a Bluetooth headset, …) are auto-applied to this [Player]
  /// and also surfaced on [PlayerStream.mediaSessionCommands] for
  /// analytics or interception.
  ///
  /// `dispose()` releases the session itself before tearing down libmpv,
  /// as `setMediaSession(null)` would, so the OS lockscreen never holds a
  /// stale entry past the player's lifetime.
  Future<void> setMediaSession(MediaSession? session);

  // ── Hooks ──────────────────────────────────────────────────────────

  /// Registers a libmpv hook. Lower [priority] runs earlier, as in mpv,
  /// and 0 is the neutral default; [timeout]
  /// caps how long mpv waits before auto-continuing (without it, an
  /// earlier deadline for [hook] stays). Hook events surface on
  /// [PlayerStream.hook] and must be released with [continueHook].
  Future<void> registerHook(Hook hook, {int priority = 0, Duration? timeout});

  /// Releases the hook stage identified by [id], letting mpv resume the
  /// gated operation. A no-op for an event already released, also by the
  /// timeout, and after [dispose], which has already released every
  /// pending hook.
  Future<void> continueHook(int id);

  /// Installs a [SourceResolver], the official callback for resolving or
  /// refreshing a playback URL right before each track opens (and once
  /// more after a failed open, with [SourceResolveRequest.isRetry] set),
  /// driven internally by the `on_load`, `on_load_fail` and `on_prefetch`
  /// hooks. Return `null` to keep the current URL; pass `null` to
  /// uninstall. [timeout] caps a hung resolver (default 15s, `null`
  /// disables). With [setPrefetchPlaylist] on, the next entry is resolved
  /// on `on_prefetch` while the current one plays, and its open reuses
  /// that URL.
  Future<void> setSourceResolver(
    SourceResolver? resolver, {
    Duration? timeout = const Duration(seconds: 15),
  });

  // ── Raw escape hatch ───────────────────────────────────────────────

  /// Reads an arbitrary mpv property as a string; `null` if unset or
  /// unavailable. Escape hatch for properties without a typed accessor.
  Future<String?> getRawProperty(String name);

  /// Reads an arbitrary mpv property as a decoded node tree (maps, lists,
  /// scalars or byte arrays); `null` if unset or unavailable. The structured
  /// counterpart of [getRawProperty] for properties like `track-list`.
  Future<Object?> getRawPropertyNode(String name);

  /// Writes an arbitrary mpv property from a string. Escape hatch for
  /// properties without a typed setter; writes to `af` and `pause`, also
  /// through `options/` and `file-local-options/`, throw [ArgumentError]
  /// because they would desync the typed state.
  Future<void> setRawProperty(String name, String value);

  /// Sends an arbitrary mpv command with its argument list. Escape hatch
  /// for commands without a typed wrapper. A command that writes `af` or
  /// `pause`, such as `cycle pause`, throws [ArgumentError]: see
  /// [Player.sendRawCommand].
  Future<void> sendRawCommand(List<String> args);

  /// Sets the minimum severity of log messages mpv emits on
  /// [PlayerStream.log] at runtime (`mpv_request_log_messages`).
  ///
  /// The initial level comes from [PlayerConfiguration.logLevel]; raise it
  /// (e.g. to [LogLevel.debug]) to surface more diagnostics on demand, or
  /// lower it to cut log volume. Synchronous, and valid before the player
  /// has finished starting: the level then applies once it has.
  void setLogLevel(LogLevel level);
}
