// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../generated/audio_effects_settings.dart';
import '../models/chapter.dart';
import '../models/device.dart';
import '../models/media.dart';
import '../models/media_session.dart';
import '../models/source_resolve_request.dart';
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

/// Public surface of the [Player] — every method, getter, and stream a
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
/// initialization — none of that is mockable in a unit test.
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

  /// Currently-applied spectrum / PCM pipeline configuration. Mutate via
  /// [setSpectrum] / [updateSpectrum].
  SpectrumSettings get spectrumSettings;

  // ── Lifecycle ──────────────────────────────────────────────────────

  /// Tears down the player. Idempotent.
  Future<void> dispose();

  // ── Loading ────────────────────────────────────────────────────────

  /// Loads [media] as the sole playlist entry and optionally starts
  /// playback. When [play] is null the configuration's autoplay value
  /// decides. Replaces any currently loaded file or playlist.
  Future<void> open(Media media, {bool? play});

  /// Loads [medias] as the new playlist, optionally starting at [index]
  /// (clamped to the valid range) and optionally starting playback. The
  /// multi-item counterpart of [open].
  Future<void> openAll(List<Media> medias, {bool? play, int index = 0});

  /// Loads a playlist file or URL (`.m3u` / `.m3u8` / `.pls` / `.cue`) as the
  /// new playlist via mpv's `loadlist`, expanding its entries into the
  /// playlist — the path for internet-radio station lists and remote `.m3u`
  /// playlists. Contrast with [open], which loads a single entry. See
  /// [Player.openPlaylistFile] for the per-[Media] option caveats.
  Future<void> openPlaylistFile(Media playlist, {bool? play});

  // ── Playback ───────────────────────────────────────────────────────

  /// Starts or resumes playback (sets the play/pause intent to play).
  /// Idempotent.
  Future<void> play();

  /// Pauses playback, preserving the playhead position. Idempotent.
  Future<void> pause();

  /// Stops playback and unloads the current file; the next track must be
  /// loaded with [open].
  Future<void> stop();

  /// Seeks within the current file. With [relative] `false` [position] is
  /// an absolute timestamp; with `true` it is a signed offset from the
  /// playhead. [exact] forces a sample-accurate (slower) seek.
  Future<void> seek(Duration position, {bool relative, bool exact});

  /// Seeks by percentage of the file duration (0–100). See
  /// [Player.seekToPercent].
  Future<void> seekToPercent(double percent, {bool relative, bool exact});

  /// Undoes the last seek, returning to the prior position (mpv's
  /// `revert-seek`). See [Player.revertSeek].
  Future<void> revertSeek();

  /// Jumps to the 0-based chapter [index] in the current file.
  Future<void> setChapter(int index);

  /// Replaces the current file's chapter markers with [chapters] — an
  /// external-chapters injection for sources whose container carries none
  /// (e.g. a resolved YouTube / `googlevideo` audio stream). Writes mpv's
  /// `chapter-list` directly, so [PlayerStream.chapters] reflect them and
  /// [setChapter] navigates them. Call after the file is loaded; an empty
  /// list clears them.
  Future<void> setChapters(List<Chapter> chapters);

  /// Sets the A-B loop start point; `null` disables it.
  Future<void> setAbLoopA(Duration? position);

  /// Sets the A-B loop end point; `null` disables it.
  Future<void> setAbLoopB(Duration? position);

  /// Sets the number of A-B loop repetitions; `null` loops infinitely.
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

  /// Removes the playlist entry at [index].
  Future<void> remove(int index);

  /// Advances to the next playlist entry. With [force] true, advancing past
  /// the last entry stops playback; the default does nothing at the end.
  Future<void> next({bool force});

  /// Returns to the previous playlist entry. With [force] true, going back
  /// past the first entry stops playback; the default does nothing at the start.
  Future<void> previous({bool force});

  /// Jumps to the next entry from a different source playlist
  /// (`playlist-path`) — navigation across concatenated playlists.
  Future<void> nextPlaylist();

  /// Jumps to the first of the previous entries from a different source
  /// playlist (`playlist-path`). The reverse of [nextPlaylist].
  Future<void> previousPlaylist();

  /// Jumps to the playlist entry at [index] and plays it.
  Future<void> jump(int index);

  /// Moves the playlist entry from index [from] to index [to].
  Future<void> move(int from, int to);

  /// Replaces the playlist entry at [index] with [media].
  Future<void> replace(int index, Media media);

  /// Removes every entry from the playlist.
  Future<void> clearPlaylist();

  /// Sets the loop policy (off, current file, or whole playlist).
  Future<void> setLoop(Loop loop);

  /// Enables or disables shuffled playlist order.
  Future<void> setShuffle(bool shuffle);

  /// Enables or disables prefetching the next playlist entry during
  /// playback.
  Future<void> setPrefetchPlaylist(bool enabled);

  // ── Audio output ───────────────────────────────────────────────────

  /// Sets the output volume in percent (`100` is unattenuated). mpv applies
  /// its own `volume-max` ceiling.
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

  /// Sets the decoder-side gain in dB applied on top of the volume.
  Future<void> setVolumeGain(double gainDb);

  /// Sets the lower clamp on the volume gain, in dB (`volume-gain-min`).
  Future<void> setVolumeGainMin(double gainDb);

  /// Sets the upper clamp on the volume gain, in dB (`volume-gain-max`).
  Future<void> setVolumeGainMax(double gainDb);

  /// Sets the upper bound the [setVolume] setter accepts, in percent.
  Future<void> setVolumeMax(double limit);

  /// Sets the OS per-app mixer volume in percent (`ao-volume`), distinct from
  /// the soft [setVolume]. Best-effort: silently ignored (no throw) when the
  /// active audio output doesn't expose system volume.
  Future<void> setSystemVolume(double volume);

  /// Sets the OS per-app mute (`ao-mute`), distinct from the soft [setMute].
  /// Best-effort: silently ignored (no throw) when unsupported by the AO.
  Future<void> setSystemMute(bool mute);

  /// Opens the audio device in exclusive mode when [exclusive] is true.
  Future<void> setAudioExclusive(bool exclusive);

  /// Reports a "music" media role to the OS audio server (PulseAudio /
  /// PipeWire) when [enable] is true (mpv's `audio-set-media-role`).
  Future<void> setAudioMediaRole(bool enable);

  /// Sets the set of codecs to pass through as bitstream rather than
  /// decode.
  Future<void> setAudioSpdif(Set<Spdif> codecs);

  /// Selects the active audio [track].
  Future<void> setAudioTrack(Track track);

  /// Loads an external audio file as an extra selectable track on the current
  /// file (mpv's `audio-add`). See [Player.addAudioTrack].
  Future<void> addAudioTrack(Media file,
      {bool select, String? title, String? lang,});

  /// Removes an audio track (mpv's `audio-remove`); [Track.id] removes a
  /// specific one, [Track.auto] the current. See [Player.removeAudioTrack].
  Future<void> removeAudioTrack(Track track);

  /// Reloads the current audio track, reopening the decoder and output.
  Future<void> reloadAudio();

  /// Re-scans sidecar external files (auto-loaded audio / cover art) for the
  /// current file (mpv's `rescan-external-files`). See
  /// [Player.rescanExternalFiles].
  Future<void> rescanExternalFiles({bool keepSelection});

  /// Replaces the whole DSP rack atomically with [effects].
  Future<void> setAudioEffects(AudioEffects effects);

  /// Mutates the current DSP rack incrementally by applying [mapper] to it
  /// and reapplying the result.
  Future<void> updateAudioEffects(AudioEffects Function(AudioEffects) mapper);

  /// Sets the policy for scanning sidecar cover-art files.
  Future<void> setCoverArtAuto(Cover cover);

  /// Forces the output sample rate in Hz; pass mpv's auto value to let it
  /// choose.
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

  /// Applies the spectrum / PCM pipeline configuration atomically.
  Future<void> setSpectrum(SpectrumSettings settings);

  /// Mutates the spectrum configuration incrementally by applying [mapper]
  /// to it and reapplying the result.
  Future<void> updateSpectrum(
      SpectrumSettings Function(SpectrumSettings) mapper,);

  // ── Cache / network ────────────────────────────────────────────────

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

  /// Sets the network I/O timeout.
  Future<void> setNetworkTimeout(Duration timeout);

  /// Enables or disables TLS server-certificate verification.
  Future<void> setTlsVerify(bool enable);

  /// Sets the path to a custom CA bundle for TLS verification.
  Future<void> setTlsCaFile(String path);

  /// Sets the HLS variant-selection policy for adaptive streams.
  Future<void> setHlsBitrate(HlsBitrate hlsBitrate);

  /// Enables mpv's HTTP cookie jar for network streams when [enable] is
  /// true.
  Future<void> setCookies(bool enable);

  /// Sets the HTTP proxy URL for network streams; empty string clears it.
  Future<void> setHttpProxy(String url);

  /// Runs the null audio output untimed when [enable] is true.
  Future<void> setAudioNullUntimed(bool enable);

  // ── Media session ──────────────────────────────────────────────────

  /// Publishes the [Player] to the OS media session (lockscreen / SMTC
  /// / MPRIS), wiring up Bluetooth AVRCP, headset buttons, Siri /
  /// Google Assistant, and the platform's audio-session lifecycle per
  /// [MediaSession.interruptionPolicy].
  ///
  /// Pass `null` to disable the session and remove the entry from the
  /// system. Only one [Player] per process can have an active session
  /// at a time; calling this with a non-null [session] on a second
  /// [Player] throws [StateError].
  ///
  /// Incoming OS commands (play/pause from the lockscreen, next track
  /// from a Bluetooth headset, …) are auto-applied to this [Player]
  /// and also surfaced on [PlayerStream.mediaSessionCommands] for
  /// analytics / interception.
  ///
  /// `dispose()` automatically calls `setMediaSession(null)` before
  /// tearing down libmpv, so the OS lockscreen never holds a stale
  /// entry past the player's lifetime.
  Future<void> setMediaSession(MediaSession? session);

  // ── Hooks ──────────────────────────────────────────────────────────

  /// Registers a libmpv hook. Higher [priority] runs earlier; [timeout]
  /// caps how long mpv waits before auto-continuing. Hook events surface
  /// on [PlayerStream.hook] and must be released with [continueHook].
  Future<void> registerHook(Hook hook, {int priority = 0, Duration? timeout});

  /// Releases the hook stage identified by [id], letting mpv resume the
  /// gated operation.
  Future<void> continueHook(int id);

  /// Installs a [SourceResolver] — the official callback for resolving or
  /// refreshing a playback URL right before each track opens (and once
  /// more after a failed open, with [SourceResolveRequest.isRetry] set),
  /// driven internally by the `on_load` / `on_load_fail` hooks. Return
  /// `null` to keep the current URL; pass `null` to uninstall. [timeout]
  /// caps a hung resolver (default 15s, `null` disables).
  Future<void> setSourceResolver(SourceResolver? resolver,
      {Duration? timeout = const Duration(seconds: 15),});

  // ── Raw escape hatch ───────────────────────────────────────────────

  /// Reads an arbitrary mpv property as a string; `null` if unset or
  /// unavailable. Escape hatch for properties without a typed accessor.
  Future<String?> getRawProperty(String name);

  /// Reads an arbitrary mpv property as a decoded node tree (maps / lists /
  /// scalars / byte arrays); `null` if unset or unavailable. The structured
  /// counterpart of [getRawProperty] for properties like `track-list`.
  Future<Object?> getRawPropertyNode(String name);

  /// Writes an arbitrary mpv property from a string. Escape hatch for
  /// properties without a typed setter; writes to `af` and `pause` are
  /// rejected because they would desync the typed state.
  Future<void> setRawProperty(String name, String value);

  /// Sends an arbitrary mpv command with its argument list. Escape hatch
  /// for commands without a typed wrapper.
  Future<void> sendRawCommand(List<String> args);

  /// Sets the minimum severity of log messages mpv emits on
  /// [PlayerStream.log] at runtime (`mpv_request_log_messages`).
  ///
  /// The initial level comes from [PlayerConfiguration.logLevel]; raise it
  /// (e.g. to [LogLevel.debug]) to surface more diagnostics on demand, or
  /// lower it to cut log volume. Cheap and thread-safe.
  Future<void> setLogLevel(LogLevel level);
}
