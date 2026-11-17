## [0.4.9] - 10-10-2026

### Contributions
- [@erikjara](https://github.com/erikjara): reported that on an auto-advance the cover and waveform of the next track arrived before `state.playlist` moved to it ([#21](https://github.com/ales-drnz/mpv_audio_kit/issues/21)).
- [@doodlezucc](https://github.com/doodlezucc): reported that a `Media` opened by `file://` URL lost its `extras` in the playlist ([#23](https://github.com/ales-drnz/mpv_audio_kit/issues/23)).

### Fixed
- On an auto-advance, `state.playlist` and `state.path` name the new track before its cover, waveform reset and first envelope arrive. With prefetch on they often still named the previous one.
- A `Media` opened by `file://` URL keeps its `extras` in `state.playlist` and in the source resolver. mpv names the entry by the decoded path, and the lookup missed it.
- `AphaserSettings.delayMin`, `AresampleSettings.sample_rateMax` and `FirequalizerSettings.accuracyMin` are 0.1, 768000 and 3, values the filter accepts. ffmpeg declares wider ranges than it builds with.
- `AiirChannelsX.withChannels` turns the default `format` and `process` into `tf` and direct, which its real coefficients need. With the defaults the filter refused the chain. A format or process set by hand is kept.
- A `double` field of an effect that three decimals cannot hold goes to the filter with six, so `0.0014` no longer becomes `0.001` and `0.0625` no longer becomes `0.063`.
- The temp copy of an `asset://` source goes to a directory of the user and app, so another user or app sharing `/tmp` no longer collides with it. It is written aside and renamed, so another instance never reads it half written.
- `dispose()` refuses new calls from its start. With a media session it accepted them until the session was released.
- `setLoop` from file to playlist no longer emits a passing `Loop.off`.
- `dispose()` closes `stream.playWhenReady`, `playbackState`, `audioDevice` and `audioEffects` too, so a subscriber waiting on them no longer hangs.
- The position no longer stays behind the paused playhead: a clock update that fell inside the 33 ms throttle window was dropped, and mpv sends no other once paused. It is now held and sent when the window closes.
- Android, Windows and Linux: a remote cover that fails to download is downloaded again after 30 seconds, three tries at most. Before, the track kept no cover until the next one.
- Android: next and previous from the media keys, Bluetooth and the notification reach the player. The session offered only the media item form of these commands, and Media3 dropped the ones the buttons send.
- Android: a libmpv download that fails or does not match its checksum stops the build. Before, the app was built without libmpv and failed at its first `Player`.
- iOS and macOS: the privacy manifest declares the file timestamp, disk space and boot time APIs libmpv calls, so App Store Connect no longer flags them as missing.
- Windows: the plugin builds with Visual Studio 2026.
- Windows: on a retry, a source resolver that returned a local path with forward slashes gets the original `Media` again. mpv reports the path back with backslashes, and the lookup missed it.

### Build
- Closing the app while the waveform or loudness scan reads an HTTPS stream no longer frees TLS state under it.
- A waveform or loudness scan whose workers fail to start stops the ones already running instead of waiting for their whole decode.
- Windows: `dispose()` no longer crashes the app or corrupts its memory. libmpv released the audio device watcher on a thread other than the one that created it.
- Windows: `previousPlaylist()` across two playlist files no longer crashes the app.
- Updated libmpv to `libmpv-r15` across all platforms.

## [0.4.8] - 24-09-2026

### Contributions
- [@erikjara](https://github.com/erikjara): reported that the waveform analyzer opened network sources without the player's TLS and header options ([#19](https://github.com/ales-drnz/mpv_audio_kit/issues/19)) and asked for a per-bin RMS ([#20](https://github.com/ales-drnz/mpv_audio_kit/issues/20)).

### Added
- `WaveformData.rms`: the RMS of each bin, to draw loud masters whose peaks sit at full scale. `null` with an older libmpv.

### Fixed
- Android and Windows no longer publish a remote cover's URL: the image is downloaded first and handed to the OS, as on Linux since 0.4.7.
- Android: a Bluetooth or headset key with the app closed no longer gets the app killed, and audio without a title keeps its notification and background playback.
- iOS: audio no longer stays silent after an interruption or a media services reset while the player reports playback.
- Windows: the media session no longer overrides the app's own AppUserModelID, and a cover shows again after the session is disabled and re-enabled.
- Linux: a second instance of an app keeps its media controls, and apps using the package no longer delete each other's covers.

### Build
- The waveform and loudness scan open a remote file with the same network options as playback: `tls-verify`, `tls-ca-file`, `Media.httpHeaders`, user agent and cookies. Before, they skipped certificate verification and dropped the headers.
- Added a per-bin RMS to the native waveform analyzer, behind `WaveformData.rms`.
- Waveform peaks of a stereo file stay within `[-1, 1]`. The ahead-of-time decode now downmixes like the progressive one, where it could reach about 1.41.
- Changing track or closing the app while the waveform or loudness scan was decoding could crash the process.
- Updated libmpv to `libmpv-r14` across all platforms.

## [0.4.7] - 23-09-2026

### Contributions
- [@erikjara](https://github.com/erikjara): reported that stream URLs with credentials in the query reached the media session ([#18](https://github.com/ales-drnz/mpv_audio_kit/issues/18)).

### Fixed
- MPRIS on Linux no longer publishes network URLs. `xesam:url` is set only for local files, and a remote cover is downloaded and published as a private temp file instead of its URL.
- A tag-less stream with no title no longer shows the URL query on the lockscreen, SMTC or Now Playing: the query and any userinfo are stripped from the URL-derived title.

## [0.4.6] - 18-09-2026

### Contributions
- [@xiaobaimc](https://github.com/xiaobaimc): found and fixed the intermittent exit crash on Windows, tracing it to the SMTC teardown running after the process threadpool was gone ([#17](https://github.com/ales-drnz/mpv_audio_kit/pull/17)).

### Fixed
- Windows apps no longer crash on exit with `0xC000000D` inside `ntdll.dll` on some Windows 10 and 11 setups. The media session is now leaked on purpose instead of being torn down during DLL detach, so no WinRT handler is revoked once the OS has already dismantled the threadpool.

## [0.4.5] - 22-08-2026

### Contributions
- [@visionxStudio](https://github.com/visionxStudio): reported the startup crash on Android 10 ([#16](https://github.com/ales-drnz/mpv_audio_kit/issues/16)).

### Build
- Android apps no longer die at startup with a native SIGSEGV on API 24 to 29.
- Updated libmpv to `libmpv-r13` across all platforms.

## [0.4.4] - 3-08-2026

### Changed
- `openAll` no longer loads the first entry briefly before jumping to the requested index. Entries are appended without starting playback and a single jump starts directly at the selected track, so a UI bound to the playlist index never flashes track 1 during the transition and no audio from it leaks out. The outgoing track keeps playing until the jump.
- `Playlist.index` can now be `-1` while entries exist but none is active yet (the build-up phase of `openAll`, before playback starts). Guard reads with `index >= 0` before addressing `items`; consumers that already did so are unaffected.
- When mpv omits the current flag during playlist reorders, the playlist index now follows the current entry by URI instead of pinning its old position, so a `move` keeps the real track highlighted even when the entry shifted.

## [0.4.3] - 3-08-2026

### Contributions
- [@yhsj0919](https://github.com/yhsj0919): requested an official callback for resolving playback URLs at play time, for temporary CDN and token-based sources ([#15](https://github.com/ales-drnz/mpv_audio_kit/issues/15)).

### Added
- `Player.setSourceResolver`: official callback to resolve or refresh a playback URL right before each track opens, without wiring `on_load` hooks by hand. The resolver receives the entry's original `Media` (`extras` intact) and returns the URL to play; `null` keeps the current one. A failed open re-invokes it once with `isRetry: true`, so an expired URL can be refreshed and retried.

### Fixed
- Opening a new track or album right after the previous one finished no longer starts stuck paused (the engine parked at end of content swallowed the unpause, so a second tap was needed). `open`, `openAll`, `openPlaylistFile` and `jump` now start playback reliably from that state.

## [0.4.2] - 18-06-2026

### Contributions
- [@xiaobaimc](https://github.com/xiaobaimc): reported the Windows UI micro-stutter regression and helped finding the fix, pinpointing libmpv's timer-resolution changes as the root cause ([#12](https://github.com/ales-drnz/mpv_audio_kit/issues/12)).

### Build
- Windows UI micro-stutter and dropped frames are now fully resolved.
- Updated libmpv to `libmpv-r12` across all platforms.

## [0.4.1] - 17-06-2026

### Fixed
- A Flutter Hot-Restart no longer leaves the previous run's audio engine playing in the background. Each restart used to orphan a libmpv instance, the leaked engines are now fully torn down on the next restart instead of only being paused.
- A `Player` dropped without `dispose()` now fully releases its native audio engine, instead of leaving it running until the app exits.

## [0.4.0] - 16-06-2026

### Breaking
- `AudioEffects` slots are now nullable (`null` = "never configured"), so a consumer keeps only the effect classes it names (~270 KB saved when none are used). Reading a slot now needs a null-check (`e.bass?.enabled ?? false`); construction is unchanged.
- Demuxer buffering is now one `DemuxerSettings` bundle applied with `Player.setDemuxer`, replacing the three separate setters and fields. Migrate `setDemuxerMaxBytes(b)` to `setDemuxer(state.demuxer.copyWith(maxBytes: b))`; `maxBackBytes` and `readahead` likewise.

### Added
- Per-effect updaters on `AudioEffects` (`updateBass`, `updateAcompressor`, …): one-line incremental edits, e.g. `e.updateBass((b) => b.copyWith(g: 3))`.
- `Player.getRawPropertyNode(String)`: reads any mpv property as a decoded native tree (maps, lists, scalars), the typed counterpart of `getRawProperty` for structured properties like `track-list`.
- `Player.stream.loudnessMeter` (`Loudness`): live EBU R128 metering (momentary, short-term, integrated, range). Listener-gated.
- `Player.stream.loudness` (`LoudnessScan`): whole-track EBU R128 loudness (integrated LUFS, range, sample and true peak), measured off the playback path moments after load. Volume-normalize any track, ReplayGain tags or not. Listener-gated; adaptive and live streams report `unavailable`.
- Glitch-free live DSP edits: parameter-only changes on command-capable filters (54 of 87) now apply to the running graph in place, so an EQ or compressor slider drag no longer resets filter state. Topology changes still rebuild the chain.
- Each typed effect now carries a stable label in mpv's `af` chain (`@aek_<effect>:`), the anchor for live updates and metering.
- `Player.setHlsBitrate(HlsBitrate)`: change the HLS variant-selection policy at runtime (previously init-only via `PlayerConfiguration.hlsBitrate`), observable on `state.hlsBitrate` and `stream.hlsBitrate`.
- `Player.setCookies(bool)`: enable mpv's HTTP cookie jar for network streams, observable on `state.cookies` and `stream.cookies`.
- `Player.setHttpProxy(String)`: route network streams through an HTTP proxy (empty string clears it), observable on `state.httpProxy` and `stream.httpProxy`.

### Changed
- `seek`, `seekToPercent`, `revertSeek`, `jump`, `move`, `remove`, and the `open` family now throw `MpvException` when mpv rejects the command (e.g. seeking with nothing loaded, an out-of-range playlist index) instead of failing silently.
- Rapid back-to-back transport calls now settle in program order: the last `open`, `stop`, or `clearPlaylist` issued wins, even if an earlier source resolves slower.
- `Player.dispose()` is now await-safe for concurrent callers: every call returns the same teardown future, so a second `await dispose()` completes only when native resources are actually released.
- Lower steady-state overhead during playback: all playback-clock properties now share the 30 Hz update throttle, property deduplication no longer allocates per event, and no-op `setAudioEffects` calls skip the native round-trip.
- Removed two unused dependencies (`crypto`, `plugin_platform_interface`) from the package's dependency graph.

### Fixed
- Starting or switching tracks no longer freezes the UI while the audio output wakes up: a Bluetooth or AirPlay speaker powering on, an HDMI receiver, a device switch (the macOS beachball). Controls, cover art and the visualizer, waveform, and loudness streams stay responsive throughout.
- Metadata containing invalid UTF-8 (e.g. the station name of a legacy latin-1 internet-radio server) no longer freezes all state updates for the rest of the session; malformed sequences decode to replacement characters instead.
- Disposing a `Player` while it was still initializing no longer leaks the mpv core and its event loop; teardown now completes in milliseconds instead of hitting a 2-second timeout.
- `jump()` from a paused state now raises `playWhenReady`, keeping the OS play and pause button in sync with actual playback.
- A failed load no longer leaves `playWhenReady` (and the OS play and pause button) stuck on "playing".
- `completed` no longer pulses `true` between tracks on a gapless playlist advance; it fires only at the genuine end of content.
- `stream.fft`, `stream.pcm`, `stream.spectrum` and `stream.waveform` now emit `done` on dispose, so awaiting them across a dispose no longer hangs.
- Two rapid un-awaited `updateAudioEffects` calls no longer drop the first mutation.
- Two overlapping `setMediaSession` calls no longer leak a duplicate session controller that double-pushed every state change to the OS for the rest of the process.
- Two distinct `asset://` URIs whose flattened names collide (e.g. `a/b.mp3` and `a_b.mp3`) no longer overwrite each other's extracted file during playback.
- On macOS and iOS the numeric C locale is now actually forced to `"C"` as libmpv requires (the previous code set a different locale category on Apple platforms).
- Calling a setter while the player is being disposed during initialization now fails with the documented `StateError` instead of an internal error.
- Disposing a `Player` while a setter or `registerHook` call is mid-flight no longer risks a native crash.
- A media-session command from the OS (lockscreen or headset) that the engine rejects (e.g. a seek arriving with nothing loaded) is now handled gracefully instead of surfacing as an uncaught error.

### Build
- Waveform generation is now shown live for local files.
- Added native loudness analyzer behind `Player.stream.loudness`.
- The libmpv of Windows no longer pins the system-wide 1 ms timer at init, which caused UI micro-stutter or dropped frames in the app.
- HTTPS certificate trust is now compiled into the bundled libmpv (Mozilla CA roots) instead of a shipped `cacert.pem` asset.
- Updated libmpv to `libmpv-r11` across all platforms.

## [0.3.6] - 9-06-2026

### Build
- The bundled `libmpv.framework` was signed with the wrong identifier on iOS and macOS.
- Updated libmpv to `libmpv-r10` across all platforms.

## [0.3.5] - 9-06-2026

### Changed
- Audio-effect catalog corrected, removed `headphone` (needs a second HRIR input the single-stream chain can't provide), added `aintegral` and `asetrate`.

### Fixed
- Filters with mandatory params (`chorus`, `pan`, `channelmap`, `aeval`, `arnndn`) now make those params **required** in their `*Settings` constructors, so they can't be silently dropped and fail to initialize in mpv. 

### Build
- Full feature parity with **~50–65% smaller** binaries.
- Updated libmpv to `libmpv-r9` across all platforms.

## [0.3.4] - 8-06-2026

### Changed
- Disposing a `Player` now stops the mpv event loop immediately instead of waiting for a shutdown event, so teardown is fast and reliable.

### Fixed
- The app no longer hangs on exit when a `Player` is left undisposed; shutdown now completes promptly.
- `Player.dispose()` no longer risks a crash when the event loop hasn't fully stopped.

## [0.3.3] - 7-06-2026

### Contributions
- [@ketanchoyal](https://github.com/ketanchoyal): `MediaSession.autoApplyPlaylistNavigation`, opt out of automatic media-session next and previous track handling ([#11](https://github.com/ales-drnz/mpv_audio_kit/pull/11)).

### Added
- `Player.openPlaylistFile(Media, {bool? play})`: loads a playlist file or URL (`.m3u`, `.m3u8`, `.pls`, `.cue`) via mpv's `loadlist`, expanding its entries into `Player.stream.playlist`, for internet-radio station lists and remote playlists. (`open` still loads a single entry.)
- `Player.addAudioTrack(Media, {select, title, lang})` and `Player.removeAudioTrack(Track)`: load or remove an external audio file as a selectable track on the current file (mpv's `audio-add` and `audio-remove`), e.g. a separate-language dub or a commentary track.
- `MpvTrack.external`, `MpvTrack.externalFilename`, and `MpvTrack.codecProfile`: surface whether a track was loaded from a separate file (and its source path), plus the codec profile string when the container reports one.
- `Player.rescanExternalFiles({keepSelection})`: re-scan sidecar external files (auto-loaded audio and cover art) for the current file without reopening it (mpv's `rescan-external-files`).
- `Player.stream.demuxerCacheState` and `Player.state.demuxerCacheState` (`DemuxerCacheState` + `CacheRange`): structured demuxer-cache snapshot for streaming, with the buffered time ranges (render the downloaded regions of a network seek bar), the raw download rate, and the eof-cached, bof-cached, and underrun flags. Empty for directly-seekable local files.
- `Player.setAudioMediaRole(bool)` (+ `state` and `stream` `audioMediaRole`): report a "music" media role to the OS audio server (PulseAudio and PipeWire) so it applies the right routing and volume profile on Linux (mpv's `audio-set-media-role`).
- `PlayerConfiguration.normalizeDownmix` (mpv's `--audio-normalize-downmix`): loudness-normalize surround content downmixed to fewer channels, avoiding clipping on 5.1→stereo. Default off.
- `PlayerConfiguration.demuxerCacheDir` (mpv's `--demuxer-cache-dir`): directory for the on-disk demuxer cache (companion of `CacheSettings.onDisk`); point it at a writable path on mobile.
- `Format.s64` and `Format.s64Planar`: 64-bit signed PCM, which mpv emits in `audio-params` and accepts on `audio-format` (previously folded to `auto`, losing the read-side value).
- Resume playback ("watch later"): `Player.writeResumeConfig()` and `Player.deleteResumeConfig({filename})` save or clear a resume point for the current file, and `PlayerConfiguration.resumePlayback` (default `true`) and `PlayerConfiguration.watchLaterDir` control restore-on-reopen and where the configs live (point `watchLaterDir` at a writable path on mobile). Only audio-relevant props are persisted, ideal for audiobook and podcast resume.
- `PlayerConfiguration.forceSeekable` (mpv's `--force-seekable`): allow in-cache seeking on streams mpv reports as non-seekable (direct-HTTP or HLS audio). Default off.
- `PlayerConfiguration.hlsBitrate` (`HlsBitrate.no`, `min`, or `max`, mpv's `--hls-bitrate`): which variant mpv selects from an adaptive HLS playlist. Default `max`; use `min` to save bandwidth on metered links.
- `Player.seekToPercent(double percent, {relative, exact})` and `Player.revertSeek()`: percentage-based seeking (for progress-bar scrubbing) and undo-the-last-seek (mpv's `seek …-percent` and `revert-seek`).
- `Player.next` and `Player.previous` gained a `force` flag: advancing past the last entry (or rewinding past the first) stops playback; the default behaviour is unchanged.
- `Player.nextPlaylist()` and `Player.previousPlaylist()`: jump to the next or previous entry from a different source playlist, for navigating across concatenated playlists.
- `Player.stream.playlistPath` and `Player.state.playlistPath`: the source playlist (`.m3u` or `.pls`) the current entry was expanded from; empty when the file was not loaded via a playlist.
- `Player.setVolumeGainMin` and `Player.setVolumeGainMax` (+ `state` and `stream` `volumeGainMin` and `volumeGainMax`): configure the dB clamps applied to `setVolumeGain` (mpv's `volume-gain-min` and `volume-gain-max`, defaults -96 and +12). Previously the dartdoc advertised these bounds as configurable but no setter existed.
- `Player.setSystemVolume` and `Player.setSystemMute` (+ nullable `state` and `stream` `systemVolume` and `systemMute`): control the OS per-app mixer (mpv's `ao-volume` and `ao-mute`), distinct from the soft volume and mute. Best-effort: silently ignored (no throw) when the active audio backend doesn't expose system volume and mute; the state is `null` in that case.
- `CacheSettings.pauseInitial` (mpv's `cache-pause-initial`): buffer before playback starts, and again after each seek, until the cache fills, for a smoother start on network sources (web-radio, HLS, Plex). Default `false`.
- `MediaSession.autoApplyPlaylistNavigation` (default `true`): set `false` to stop the package auto-calling `Player.next` and `Player.previous` on OS media-session next and previous, so the app can handle those buttons itself (e.g. ±30s skip).

### Changed
- `Player.seek` gained an `exact` flag for sample-accurate (vs keyframe) seeking; the default behaviour is unchanged.
- Removed `MpvTrack.demuxDuration`. mpv's track list never populated it (it was always `null`); use `Player.state.duration` for the playing file's length.
- Removed `Spdif.aac` and `Spdif.mp3`. mpv's `audio-spdif` passthrough only accepts `ac3`, `dts`, `dts-hd`, `eac3`, `truehd`; neither dropped value was ever a valid passthrough codec (`audio-spdif` is a free-form string list and silently ignores unrecognized tokens).
- `CacheSettings.secs` now defaults to mpv's own `--cache-secs` default (~1000 h) instead of 1 h, so every cache default mirrors mpv exactly. Effective cache memory is still bounded by `DemuxerSettings.maxBytes` (150 MiB by default).

### Fixed
- Playback no longer hard-fails when the audio device can't be opened: it falls back to a null output and keeps the position clock running, with the failure still reported on `Player.stream.audioOutputState`.

### Build
- The shared Apple plugin sources ship as regular files rather than symlinks (this would cause issues with compilers).

## [0.3.2] - 5-06-2026

### Fixed
- Windows SMTC: artwork supplied as a `file://` URI (e.g. local cache paths) is now displayed correctly. 

## [0.3.1] - 5-06-2026

### Fixed
- Old build tag in macOS podspec.

## [0.3.0] - 5-06-2026

### Added
- `Player.setMediaSession(MediaSession?)`: publishes the player to the OS media session (Now Playing, Control Center, lockscreen, MPRIS, SMTC, Android notification). Metadata and artwork come from the playing file or override per field; `null` removes the entry.
- `Player.stream.mediaSessionCommands`: transport commands the OS sends back (play, pause, next, seek, repeat, shuffle, speed, and the favourite or like press). Auto-applied to the player and surfaced here for analytics or interception; `MediaSessionCommandLike` is emit-only (no built-in favourite concept).
- `MediaSession`: configures the advertised buttons (`MediaAction`, including the `like` or favourite feedback with its `isFavorite` filled-star state), artwork (`MediaSessionArtwork`), skip intervals, supported speeds, the interruption response (`InterruptionPolicy`), and the app identity (`appName`, `desktopEntry`).
- `Player.state.playWhenReady` and `Player.stream.playWhenReady`: the play-pause *intent* axis, set by `play`, `pause`, `open`, or `stop`.
- `Player.setChapters(List<Chapter>)`: injects or replaces the current file's chapter markers by writing mpv's `chapter-list` NODE property directly. `Player.stream.chapters` and `state.chapters` then reflect the injected list, and `setChapter` navigates it natively.
- `Player.setLogLevel(LogLevel)`: changes the engine log verbosity at runtime (the initial value comes from `PlayerConfiguration.logLevel`).
- `Player.stream.prefetchCacheDuration`: how much of the next track the background prefetch has buffered ahead, as a `Duration`. Pair it with `prefetchState` for a determinate "Prefetching…" indicator.
- `Player.stream.waveform` now grows progressively for streams that aren't decodable up front (network or transcode sources), filling in as playback advances. The new `WaveformData.filled` field flags per-bin coverage.
- `Media.httpChunkSize`: opt-in cap (in bytes) on each HTTP range request for a source. Rate-limit a single open-ended request for the whole file, so seeking back freezes once the buffer drains.
- `Media.demuxerLavfOptions`: opt-in per-track options for libmpv's libavformat demuxer, applied as the file-local `demuxer-lavf-o` and scoped to that exact playlist entry.

### Fixed
- `Player.stream.audioOutputState` and `state.audioOutputState` now report `AudioOutputState.failed` when the audio output can't initialize; before, it only ever settled on `closed`.
- `Player.stream.prefetchState` no longer occasionally stays on `loading` when a prefetch is cancelled before its opener starts.
- `Player.stream.waveform` no longer renders a short flat segment at the end when a file's declared duration overshoots the decoded audio.
- `Player.stream.tap(...)` no longer re-emits an identical PCM frame on every poll while paused or stopped at end of content.
- A finished track or playlist now settles the play-pause button back on "play" and reports `state.completed` and `MpvPlaybackState.completed` at the natural end of content.
- `setRawProperty('pause', …)` is now rejected: it bypassed the play-pause intent and desynced the OS button; use `Player.play()` and `Player.pause()`.
- A failed first `open(play: true)` no longer leaves the play-pause button stuck on "pause".
- `setAudioDriver('auto')` (and an empty string) now selects mpv's auto-probe instead of failing with "Audio output auto not found".

### Example
- The example app has moved to its own repository as a standalone app, [MPV Studio](https://github.com/ales-drnz/mpv_studio). The bundled `example/` is now a minimal single-file demo.

### Build
- Updated the bundled Mozilla CA certificates (`cacert.pem`) to the 2026-05-14 set.
- Migrated the Android build to Flutter's Built-in Kotlin model.
- The bundled libmpv's `smb2://` protocol now percent-decodes the URL path, user and share (previously only the password).
- Updated libmpv to `libmpv-r8` across all platforms.

## [0.2.3] - 25-05-2026

### Docs
- Branding realignment with the rest of the libraries.

## [0.2.2] - 23-05-2026

### Added
- `AevalSettings` and `AformatSettings` now expose their typed parameters (previously toggle-only).
- Correct numeric bounds on ~116 more parameters that were `null` before, including the whole biquad family's `width_type`, `transform` and `precision`, `atempo.tempo`, and many others. The matching `<param>Min` and `<param>Max` constants now reflect the real ffmpeg ranges.
- New typed enums for the biquad family's `width_type` and `transform`, plus `SurroundWinFunc`.
- Param doc comments now flag which AVOptions ffmpeg marks as runtime-tunable, deprecated, or array-typed. Deprecated parameters also carry a Dart `@Deprecated` annotation.

### Changed
- The six `EBU R128` stat fields (`integrated`, `range`, `lra_low`, `lra_high`, `sample_peak`, `true_peak`) are no longer setter fields on `Ebur128Settings`: ffmpeg flags them as read-only outputs and rejected any attempt to set them. Read them via `af-metadata/<label>` instead.

### Fixed
- `compand.points`, `mcompand.args`, `aiir.{p,z,k,gains,…}`, `firequalizer.gain`, `anequalizer.colors` and other string-grammar parameters now carry their ffmpeg default value instead of an empty default. The hand-written list-typed extensions (`CompandSettings.transferPoints`, `AiirSettings.channels`, `McompandSettings.bands`, …) consequently decode the real ffmpeg default state when the filter is constructed without overrides.

### Build
- Improvements to Swift Package Manager on both iOS and macOS.


## [0.2.1] - 21-05-2026

### Fixed
- Incorrect README mentions.

## [0.2.0] - 21-05-2026

### Added
- `Player.stream.waveform`: a min-max amplitude envelope of the whole track (`WaveformData`) for a static overview strip. Listener-gated, so the background analyzer runs only while a consumer is subscribed.
- `Player.stream.tap(AudioEffect, side: TapSide)`: typed per-filter PCM tap that picks a slot in the effect chain and a `pre` or `post` side. Lazy, arming on the first listener and tearing down on the last cancel.
- `BandProcessor`: public PCM-to-bands processor running the same FFT pipeline as `Player.stream.fft`, for per-filter spectrum curves built from a tap.
- `AudioEffectsX.active`: yields the `AudioEffect` for every enabled slot, so the live effect rack can be iterated without enumerating each typed field.
- Typed extensions for every filter whose lavfi grammar packs structured data into an opaque string: `compand`, `aecho`, `chorus`, `adelay`, `aiir`, `firequalizer`, `afftdn`, `mcompand`, `superequalizer`, `anequalizer`. Each exposes a typed model (`CompandPoint`, `AechoTap`, `AnequalizerBand`, …) and round-trips losslessly.
- `<name>Min`, `<name>Max`, and `<name>Default` constants on every typed `*Settings` class, so UI builders can read each parameter's engine range and default directly.
- The biquad-family `*Settings` (`equalizer`, `bass`, `treble`, `bandpass`, `highpass`, `lowpass`, …) now expose every parameter ffmpeg's biquad chain accepts (`width`, `mix`, `channels`, `normalize`, `transform`, …).
- `SpectrumSettings.overlapFactor`: overlap-add factor for smoother visualizer motion (default `4`, i.e. 75% overlap).
- Enum-typed parameters with a symbolic ffmpeg default are now non-nullable, carrying that documented default.

### Changed
- The real-time FFT frame stream moved from `Player.stream.spectrum` to the new `Player.stream.fft`. `Player.stream.spectrum` is now a reactive view of the current `SpectrumSettings`, emitted on every `setSpectrum` or `updateSpectrum` call.

### Fixed
- Filter values containing `:` `=` `,` or `|` (e.g. `anequalizer.params`, `pan.args`) are now accepted instead of being rejected at chain build.
- Spectrum band magnitudes follow the Web Audio `AnalyserNode` convention (normalised by half the FFT size before the dB conversion). New `SpectrumSettings` defaults: `minDb: -100`, `maxDb: -30`.

### Build
- Switched to OpenSSL for TLS.
- Ffmpeg updated to `8.1.1` and bumped all its dependencies.
- Restored 32-bit ARM Android, Intel macOS, and the Intel iOS Simulator to the bundled binaries.
- iOS and macOS libmpv now ships as a dynamic xcframework (Swift Package Manager builds no longer fail).
- Updated libmpv to `libmpv-r7` across all platforms.

## [0.1.3] - 9-05-2026

### Fixed
- Flutter Hot Restart no longer hangs in debug builds when a `Player` is alive.

## [0.1.2] - 7-05-2026

### Changed
- `Player()` returns immediately during cold start: the heavy libmpv init (library open, handle creation and initialisation, ~80 property observers) now runs on the background event isolate instead of the host isolate.
- The background event isolate now blocks on `mpv_wait_event` instead of polling every 50 ms, eliminating ~20 spurious wake-ups per second during idle playback.
- `dispose()` is robust against being called before `Player()` finishes coming up: it waits for init to settle (or fail) before issuing the cooperative quit and tearing down the streams, so the safety timeout never fires on construction-then-dispose patterns.

### Fixed
- `Media.httpHeaders` now validate keys and values and throw `ArgumentError` on inputs that would corrupt the outgoing HTTP request.
- `Player.add()` and `Player.replace()` now wait for the bundled CA file before emitting `loadfile`, matching `Player.open()`. The first HTTPS append issued immediately after construction no longer races peer verification.
- The Player finalizer now issues a cooperative quit instead of tearing down the handle directly, eliminating a possible crash when a Player is garbage-collected without `dispose()`.

## [0.1.1] - 6-05-2026

### Changed
- Numeric setters now validate at the wrapper boundary and throw `ArgumentError` with a precise stack trace instead of waiting for a round-trip `MpvException`. Affects `setVolume`, `setRate`, `setPitch`, `setVolumeMax`.
- `SpectrumSettings` rejects out-of-range values at construction (FFT size must be a power of two in `[256, 4096]`, smoothing in `[0, 1]`, `bandHighHz > bandLowHz`, etc.) instead of letting them surface as visually-broken output downstream.

### Fixed
- `Media.httpHeaders` now reach mpv on every track, including the first one. Previously they were silently dropped on the first `open()` and applied to the wrong file on subsequent calls.
- `replace()` on the currently-playing entry is now seamless instead of briefly stopping playback before resuming on the new track.
- `setNetworkTimeout` honours sub-second precision; durations below 1s no longer collapse to "no timeout".
- `setTlsCaFile('')` restores the bundled CA default instead of silently disabling peer verification.
- `setTlsCaFile` is now declared on the public `PlayerApi` interface.
- `setReplayGain`, `setCache`, and `setLoop` are now atomic: if any partial write fails, the previous values are restored before the error is rethrown.
- `dispose()` no longer falls through its safety timeout when racing an in-flight `open()`.
- `state.position` is cleared synchronously on `open()` so a UI reading the playhead on track-change no longer briefly shows the previous track's value.
- `state.chapters` and `state.currentChapter` are now refreshed after every load. Two consecutive files with structurally-identical chapter lists previously left both fields stranded at the prior track's value.

### Build
- Added AudioToolbox decoders for macOS and iOS.
- Fixed TLS on macOS and iOS (now aligned with the others).
- Updated libmpv to `libmpv-r6` across all platforms.

## [0.1.0] - 5-05-2026

Major release. The Dart API has been redesigned for type safety, ergonomics, and atomic state mutations.

### Added
- A new `AudioEffects` bundle covering equalizer, compressor, loudness, pitch, tempo, bass, treble, stereo width, headphone crossfeed, silence trim, and raw lavfi effects applied atomically through one setter.
- A-B loop and chapter navigation.
- Aggregate playback-state stream (idle, loading, buffering, playing, paused, completed) for one-line UI bindings.
- 20+ new observable streams covering timing, file metadata, cache, demuxer, and version info.
- Typed `Hook` enum for the file-loading lifecycle.
- New `MpvPrefetchState.failed` variant for when background prefetch fails.
- Typed errors via the `MpvPlayerError` hierarchy and a public `MpvException` for raw-API failures.
- Real-time FFT spectrum and raw PCM streams (`Player.stream.spectrum` and `Player.stream.pcm`) captured post-DSP for visualizers.
- `setTlsCaFile(path)` with custom root-CA bundle.

### Changed
- DSP effects, ReplayGain, and cache settings now live in atomic config objects applied in one call instead of multiple granular setters.
- Track selection, format, channel layout, S/PDIF passthrough, log levels, and hooks are now typed enums and sealed classes instead of free-form strings.
- Embedded cover art is exposed as raw codec bytes through a dedicated `state.coverArt` + `stream.coverArt` pair, with Flutter conveniences (`art.image` returns an `ImageProvider`, plus `art.extension`, `art.isPng`, `art.isJpeg`, …).
- `setAudioDisplay`, `setImageDisplayDuration`, and the `Display` enum are removed - they controlled mpv's video pipeline, which the audio-only build no longer ships. Cover bytes are surfaced regardless via `state.coverArt`.
- Raw-API escape hatches (`getRawProperty`, `setRawProperty`, `sendRawCommand`) are now `Future<...>` and surface mpv-side errors as `MpvException` instead of silently no-oping. `getRawProperty` still returns `null` on failure.
- Every typed setter (`setVolume`, `setRate`, `setAudioEffects`, `setCache`, …) now throws `MpvException` when mpv rejects the write, instead of silently advancing the optimistic state.
- `Player.openPlaylist` renamed to `Player.openAll` (matches Dart's `addAll` and `removeAll` convention).

### Fixed
- The initial player state (volume, format, channels, params, …) is now reliably populated before the first `await`. A startup race could previously leave one or more state fields at their default until the next user-driven setter.
- Calling `dispose()` immediately after construction no longer throws.
- Player instances that get garbage-collected without an explicit `dispose()` now release their native handle automatically. Always prefer `await player.dispose()`; this is just a safety net.
- `Player.dispose()` completes in milliseconds instead of falling through a 2-second timeout.
- HTTP headers no longer leak across `open()` calls; per-file headers stay scoped to their `Media`.
- Android `content://` file descriptors are released on aborted loads, including when an `openAll([...])` fails mid-batch.
- `state.coverArt` now mirrors the latest `stream.coverArt` emit synchronously (was permanently `null` despite being documented).
- `print(state)` and `print(audioEffects)` now render the actual values instead of placeholder text.
- Hot-Restart cleanup is hardened against false positives so a long-lived dev process can't have it trip on memory belonging to other tools.
- Several correctness fixes around playlist equality, hook idempotency, cache precision, and lifecycle stream synchronisation.
- HTTPS streams now connect on Android out of the box; previously TLS verification had no trust roots and every handshake failed.

### Example
- Spectrum visualizer in the Player tab driven by `Player.stream.spectrum`, plus a Settings page exposing every `SpectrumSettings` knob (FFT size, window, band count, range, emit rate, attack, release smoothing, dB range) for live exploration.
- Filters page reorganised into category sub-pages covering every filter shipped with the build, plus a dedicated 18-band visualizer for `superequalizer`.

### Build
- Patched prefetch to also support `.failed` state.
- Patched audio output state to report AO immediately.
- Patched audio frames to extract PCM streams (visualizer).
- Fixed Android `audiotrack` driver not working.
- Bundled libmpv binaries reduced by ~55% (e.g. macOS 29 MB → 13 MB).
- Bumped minimum deployment targets to iOS 15.0 and macOS 12.0.
- iOS Simulator is now Apple Silicon only (dropped x86_64).
- Added arm64 support for Linux and Windows.
- Updated libmpv to `libmpv-r5` across all platforms.

## [0.0.9] - 27-04-2026

### Fixed
- Lifecycle streams (`stream.playing`, `stream.buffering`, and `stream.completed`) silently desynced from `state` on file boundaries - `stream.completed` never fired on natural EOF and `stream.buffering` never emitted at all. All three now stay in sync with `state` across every lifecycle transition.
- `dispose()` leaked four stream controllers (audio display, cover-art auto, image display duration, prefetch state). All now closed on teardown.
- Use-after-dispose hazards on `open()` and `openPlaylist()`: disposing the player while URI normalisation was still in flight could SIGSEGV on Android `intent://` loads. Added disposed re-checks after every async boundary.
- Defensive disposal guards on the position polling and embedded-cover pipelines so in-flight work bails instead of writing to closed controllers.
- `setEqualizerGains()` now respects the disposal contract.
- `setAudioFilters()` and `setEqualizerGains()` now route state mutation through the same path as every other setter.
- `openPlaylist(medias, index: N)` no longer silently no-ops when `N >= medias.length`; the index is clamped to `medias.length - 1`.

### Changed
- Reordered the `dispose()` teardown sequence so the event loop exits cleanly without ever calling `mpv_wait_event` on a freed handle.

## [0.0.8] - 24-04-2026

### Added
- `stream.prefetchState` - observable lifecycle of mpv's background playlist-prefetch (`MpvPrefetchState`: `idle`, `loading`, `ready`, `used`).
- `stream.seekCompleted` - authoritative "seek finished" signal that fires exactly once per seek or initial file load.

### Changed
- `on_load` hook now runs for prefetched tracks, so custom URL schemes resolve uniformly whether mpv is opening the current track or pre-opening the next one.
- DASH segment downloads now reuse a single TCP connection across segment GETs (matches HLS persistent-HTTP behaviour).

### Fixed
- Spurious `position = 0` no longer emits on `stream.position` during seek or playback-restart.
- Audible click at every segment boundary on well-formed fragmented-MP4 and DASH streams (AAC encoder priming edit lists are now respected on fMP4).

### Example
- Rewrote the seek slider to release its drag value via `stream.seekCompleted` instead of a fixed delay.

### Build
- Updated libmpv binaries to `libmpv-r4` across all platforms.

## [0.0.7] - 12-04-2026

### Changed
- `audio-format` (u8, s16, s32, float, etc.) now accepts `"no"` and `""` for instant reset to default - previously a full player restart was required.

### Example
- Updated deprecated APIs that prevented the example app from running.

### Build
- Updated libmpv binaries to `libmpv-r3` across all platforms.

## [0.0.6] - 08-04-2026

### Added
- SMB2 and SMB3 protocol support (`smb2://`) for Samba (CIFS) network shares via libsmb2.
- Typed error stream - `Stream<MpvPlayerError>` (sealed: `MpvEndFileError`, `MpvLogError`) replaces `Stream<String>`.
- `stream.endFile` (`MpvFileEndedEvent`) for all file-end events, including premature EOF detection.
- `stream.pausedForCache` and `stream.demuxerViaNetwork` for network state monitoring.
- Optional `timeout` parameter on `registerHook` for automatic safety continuation.

### Fixed
- Incorrect name for the audio-stream-silence property.

### Build
- Updated libmpv binaries from `libmpv-r1` to `libmpv-r2` across all platforms.

## [0.0.5+1] - 30-03-2026

### Docs
- Improved README documentation.

## [0.0.5] - 24-03-2026

### Added
- Stream hooks API (`registerHook`, `continueHook`, `player.stream.hook`) to intercept mpv's file-loading pipeline.

### Docs
- README fixes and consistency improvements.

## [0.0.4] - 23-03-2026

### Added
- New APIs to configure embedded and external cover-art handling: `setAudioDisplay`, `setCoverArtAuto`, `setImageDisplayDuration`.

### Changed
- Fast jump into playlist now automatically starts playback.

### Example
- Refined Queue tab design and improved stability.
- Added new sliders to DSP filters.

## [0.0.3+2] - 21-03-2026

### Fixed
- Minor fixes.

## [0.0.3+1] - 21-03-2026

### Build
- New tag system for versioning libmpv binaries (`libmpv-r1`, `libmpv-r2`, …) to avoid conflicts with the pub version number on GitHub Releases.

## [0.0.3] - 21-03-2026

### Changed
- **Linux**: bumped minimum supported OS version to Ubuntu 24.04 - required because mpv 0.41.0 enforces a strict dependency on `libpipewire-0.3 >= 0.3.57` for its native PipeWire backend.

### Docs
- Added a detailed *Troubleshooting* section in the README explaining how to correctly satisfy Linux system dependencies when building on containers.

### Example
- Fixed AO menu not showing the default driver automatically.

## [0.0.2+3] - 20-03-2026

### Build
- Updated Linux libmpv: ALSA, PipeWire, and PulseAudio now all work without external dependencies.

## [0.0.2+2] - 18-03-2026

### Changed
- Cleaned up files.

## [0.0.2+1] - 17-03-2026

### Fixed
- Minor fixes.

## [0.0.2] - 17-03-2026

### Added
- Extended documentation.

### Changed
- Restructured the example app's settings UI: each mpv property has its own dedicated page; the stream lab moved to main navigation.

### Fixed
- File picker on macOS.
- Other audio-engine fixes.

## [0.0.1+9] - 16-03-2026

### Added
- New option to choose the AO driver in the example app.
- Added `audio_service` to the example app to test the native OS audio controls.

### Changed
- Re-added the `audiounit` driver alongside `avfoundation` in libmpv for iOS - `audio_service` now works with both.

## [0.0.1+8] - 16-03-2026

### Changed
- Removed the `audiounit` driver from libmpv to fix the native iOS widget for audio control when using the `audio_service` library.

### Fixed
- File picker error in the example app.

## [0.0.1+7] - 16-03-2026

### Fixed
- macOS libs build.

## [0.0.1+6] - 15-03-2026

### Fixed
- Shuffle bug.

## [0.0.1+5] - 15-03-2026

### Fixed
- Minor fixes.

## [0.0.1+4] - 15-03-2026

### Fixed
- Minor fixes.

## [0.0.1+3] - 15-03-2026

### Fixed
- Minor fixes.

## [0.0.1+2] - 15-03-2026

### Fixed
- Minor fixes.

## [0.0.1+1] - 15-03-2026

### Added
- Swift Package Manager support for iOS and macOS.

### Fixed
- Broken image links on pub.dev (now use absolute GitHub URLs).
- All static analysis warnings; enforced curly braces in flow control structures.

## [0.0.1] - 15-03-2026

### Added
- Initial release. High-performance audio library for Flutter powered by `libmpv` v0.41.0.
- Cross-platform support: iOS, Android, macOS, Windows, and Linux.
- Comprehensive example app demonstrating DSP, hardware routing, and queue management.
