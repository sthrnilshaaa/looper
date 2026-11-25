## [0.8.0] - 24-11-2026

### libmpv-r27
**All platforms**
- The libraries say `mpv v0.42.0+r27`, on the mpv 0.42.0 and FFmpeg 9.0.2 of r26.
- FFmpeg's TLS option `ca_extra_file`: certificates trusted on top of the roots in use, where `ca_file` replaces them.
- `playlist-prev-playlist` and `playlist-next-playlist` with no current entry fail. mpv 0.42.0 read the source playlist of the missing entry and the process ended.

**HarmonyOS**
- `libmpv_ohos-arm64-v8a.so` for the devices and `libmpv_ohos-x86_64.so` for the emulators, built with the OpenHarmony SDK, playing through `ohaudio`, an output over OHAudio. They make only the calls of API 12 (HarmonyOS 5.0).

### All platforms
**Breaking**
- TLS certificates are verified by default, as in mpv and FFmpeg: a server with a self-signed certificate fails to open. `setTlsExtraCaFile` trusts such a server on top of the built-in roots, and `PlayerConfiguration.tlsVerify` turns verification off before the first load. `http://` sources, local files and SMB are not affected.
- The 96 flat fields of `PlayerState`, deprecated since 0.7.0, are gone: read each one from its group.
- `openPcmStream` follows `PlayerConfiguration.autoPlay` when `play` is null, as `open` does. It played at once.
- `setMediaSession` throws `MediaSessionException`, a `PlayerException` with a `reason`, where it threw `StateError`.
- The setters with a range throw `RangeError` before writing: `setVolume`, `setVolumeGain`, `setVolumeGainMin`, `setVolumeGainMax`, `setVolumeMax`, `setAbLoopCount`, `setAudioBuffer`, `setNetworkTimeout` and `setAudioSampleRate`.
- The value classes are `final`, and `Player` and `PlayerStream` are `interface` classes: a fake still implements them.
- A class that implements `PlayerApi` takes the new signatures: `stop` has `keepPlaylist`, `openPcmStream` a nullable `play`, and `initialized` is new.

**Added**
- `stop(keepPlaylist: true)` unloads the file and keeps the playlist. The index stays on the entry that stopped, `next` and `previous` move it with nothing loaded, and `play` starts it from its beginning.
- `state.playbackState`, the value `stream.playbackState` emitted last.
- `initialized` completes once the player has started, or with the `PlayerInitException` of a start that failed.
- `setTlsExtraCaFile` trusts the certificates of a file on top of the roots in use, for a home server with a self-signed certificate or a private CA, while every other server is verified as before. The covers of the media session trust it too.

**Fixed**
- The next and previous buttons of the OS follow a change of the queue at once. They followed it only at the next play, pause or seek.
- `nextPlaylist` and `previousPlaylist` return false when no entry is current. mpv 0.42 ended the process there.

**Docs**
- A Wear OS topic: the manifest, the Bluetooth output, and what is left to the app. The CI runs the Android integration tests on the Wear OS emulator.
- The README and the description on pub.dev list every platform. The README links the Platforms topic and the topics of each TV, of Wear OS and of HarmonyOS.

### HarmonyOS
**Added**
- OpenHarmony and HarmonyOS through Flutter-OH 3.41.9 or later. The build hook recognizes an OHOS build by the clang of the OpenHarmony SDK, or by the user define `ohos`, which a Linux or OHOS target follows and Android, Apple and Windows ignore, and bundles the OHOS libmpv. A HarmonyOS topic says what the app declares.
- The media session is an AVSession: the System UI shows the title, the artist and the cover, and its controls reach the player. While the player plays, the package runs the continuous task of audio playback, which keeps the app playing in the background, once the app declares `ohos.permission.KEEP_BACKGROUND_RUNNING` and `backgroundModes: ["audioPlayback"]`.

### Linux
**Fixed**
- MPRIS reports `Stopped`, with no metadata, after a stop of the app or of the desktop controls. It reported `Paused`.
- While stopped or at the end, MPRIS offers Play when the queue has entries, and not when it is empty.

## [0.7.2] - 16-11-2026

### libmpv-r26
**All platforms**
- mpv 0.42.0, from 0.41.0, and FFmpeg 9.0.2, from 8.1.1, with OpenSSL 4.1.0 and libplacebo 7.387.0. The libraries say `mpv v0.42.0+r26`.
- mpv 0.42.0 names a local file by its absolute, normalized path, with backslashes on Windows: a relative path, `./`, `//` and `..` come back rewritten in `playlist` and in `state.file.path`. The playlist of the state keeps the `Media` the app gave.
- No `env://` protocol and no `env` property: a playlist or a property expansion can no longer read the environment of the app.
- The HLS demuxer keeps its persistent connections under FFmpeg 9.0, which turned them off when mpv reads the playlist.
- A stream whose cache fills before its end gets its waveform again, from the re-open or from playback. It could end `failed` when the analysis was behind the download.
- The AES cipher of TLS runs in constant time. GHASH, the hash of AES-GCM, keeps its C code with tables.
- zlib 1.4, xz 5.8.4, expat 2.10.0, libxml2 2.15.4, libpng 1.6.59 and libiconv 1.19.1.

**Android**
- Built with NDK r30. The minimum stays Android 7.0 (SDK 24).

**Tizen**
- A seek no longer plays audio from before it.

**Web**
- Emscripten 7.0.0. The module runs from Chrome 92, Firefox 114 and Safari 15.2.

### All platforms
**Changed**
- Certificates are still not verified by default (`tls-verify` off), so a home server with a self-signed certificate plays: mpv 0.42.0 turns verification on, the player keeps it off. `setTlsVerify(true)` turns it on. A later release will make verification the default.

**Fixed**
- The build hook drops the libmpv binaries of earlier releases from its shared cache, about 8 MB per release and per target.
- A libmpv download that fails on the network names the release and the asset, and the `libmpv` user define that builds without network.
- `setVolume` above `volumeMax` and `setVolumeGain` outside `volumeGainMin` and `volumeGainMax` play the value again, as their docs say. On mpv 0.42.0 they threw `MpvCommandException`.
- An entry added while a file loads keeps its `Media` and `extras` once `add` returns. It could show a bare `Media` of its path until the next playlist report.
- A file opened paused gets its audio params. When mpv reported them unavailable after the file had started, they stayed empty until the next file.

**Docs**
- A Platforms topic says what each platform has: output drivers, devices, passthrough, media session, SMB, analysis, live PCM and cover.
- The Network and cache topic and `CacheSettings.onDisk` say the disk cache is not persistent, with a recipe for offline listening. The Output topic says why Android has no audio offload.

### Android
**Changed**
- Media3 1.11.1.

### iOS, tvOS, macOS
**Fixed**
- The build hook checks the unpacked libmpv against the hash it recorded on unpacking, and unpacks it again when they differ.
- Enabling the media session again drops a seek bar still held by a scrub of the session before.
- On iOS an interruption that only means the app was suspended is told by its reason key, which replaced the older key in iOS 14.5.

### Linux
**Fixed**
- An app in a Flatpak sandbox shows its cover in the desktop media controls.

### Windows
**Fixed**
- The cover of the media controls is built without a thread of its own, so a cover can no longer freeze the app.

## [0.7.1] - 15-11-2026

### libmpv-r25
**All platforms**
- The loudness scan no longer reports ready from part of a file: it reports failed when a decode worker measured nothing, and unavailable for a file whose channel layout changes midway or that declares more than 48 hours.
- NaN and infinite samples of a float file read as silence in the waveform, the loudness scan and the taps.
- A waveform grown from playback drops the audio past its axis, which went into its last bin.
- The PCM tap never makes the thread of the audio output wait.
- The loudness scan no longer reads a channel layout left as the stack had it, which could end the process when a scan started.
- The analysis of a file URL with percent escapes set by a source resolver works. It failed while the file played.
- The Mozilla CA bundle is the one of 5-11-2026. In: two SECOM and two Telia roots. Out: Atos TrustedRoot 2011, Entrust Root Certification Authority, SecureSign Root CA12, ePKI Root Certification Authority and three emSign roots.

**Linux, Tizen, webOS**
- The libraries are built with a stack canary and `_FORTIFY_SOURCE=2` and linked with full RELRO. The TV libraries had neither.

### All platforms
**Changed**
- `sendRawCommand` throws `ArgumentError` for `quit` and `quit-watch-later`, which left every later call waiting. Use `dispose`.
- The lists, maps and sets of the state that come from mpv cannot be changed in place: a change throws `UnsupportedError`. `Spdif.parseMpvList` returns such a set too.
- `toString` of `Media`, `SourceResolveRequest` and `MediaSessionArtwork.uri` hides the values of a URL's query and keeps their names.
- `MpvEndFileReason.fromValue` gives `error` for a code it does not know, where it gave `eof`.
- `Channels.custom('stereo')` equals `Channels.stereo`: two layouts are equal when their mpv string is.
- The spectrum analyzes each sample once, so a poll costs about 60 percent less at 30 fps.
- The bands of the spectrum rise and fall more slowly with the same `attackSmoothing` and `releaseSmoothing`: the smoothing steps once per FFT hop of audio, about 94 times a second at the defaults, where it stepped 8 times per poll. The defaults are unchanged. A release of about 0.24 and an attack of about 0.83 give the motion of 0.7.0 at 30 fps.
- A cover download is cancelled when the track changes or the session goes off, ends 60 seconds after its start at the latest, and the last 4 covers are kept in memory.
- `dispose` waits 5 seconds at most for the media session, and not at all on a player that never published one.

**Fixed**
- A player whose core shut down by itself no longer leaves its calls waiting: they complete, and later calls do nothing.
- A core that the event isolate left too late to be destroyed at `dispose` is destroyed once the isolate exits.
- The cache of `Media` by URL no longer grows with every URL a queue ever held.
- `play`, `openAll` and the source resolver complete without `PlayerDisposedException` when a `dispose` lands while they run.
- `playWhenReady` stays true when `play()` is called before a `jump()` has finished.
- `setChapter(-1)` shows `currentChapter` as `null`, and `setAudioSpdif` and `openAll` keep a copy of what they are given.
- A time from mpv that is NaN or infinite reads as `Duration.zero`, where it dropped the whole event.
- A `PcmSource` that no player reads is polled 4 times a second, not 50, and the embedded cover reaches the main isolate with one copy.
- A `Float64List` in `supportedPlaybackRates` no longer falls back to the default rates on Apple and Windows.
- Options and properties mpv refuses at start are reported on `internalLog`.

**Added**
- `Playlist.current`, the active entry or null.
- `PlayerInitException.cause`, the error behind a failed start.
- `isLoadingError`, `isAudioOutputError`, `isFormatError` and `reachedNaturalEnd` are members of `EndFileError` and `MpvFileEndedEvent`. The extensions stay.

### Linux
**Changed**
- MPRIS follows `MediaSession.actions`, as the other platforms do. `Play`, `Pause`, `PlayPause` and `Stop` reach the player only when their action is declared, and a write of `LoopStatus`, `Shuffle` or `Rate` is refused without `setRepeatMode`, `setShuffle` or `setPlaybackRate`.
- With the default actions `Stop`, `LoopStatus`, `Shuffle` and `Rate` no longer reach the player, where they always did. Declare `MediaAction.stop`, `setRepeatMode`, `setShuffle` and `setPlaybackRate` to keep them.
- `CanPlay` and `CanPause` are false when the matching action is not declared, and a playback update sends `PropertiesChanged` only for the properties that changed.

**Fixed**
- `xesam:url` of a file whose name is not UTF-8 keeps the bytes of the name, reads a malformed percent escape as mpv does, and is published for a path whose first folder looks like a drive.

### Android, Windows
**Fixed**
- A media session enable that fails no longer keeps the session for its engine: another engine can enable it.
- On Windows an error inside the media session that is no WinRT error answers the call and no longer ends the process.

### iOS, tvOS, macOS
**Fixed**
- When the title goes away after a stop, the Now Playing entry is left paused at rate 0 and no longer keeps playing.

### Tizen, webOS
**Fixed**
- `setMediaSession` does nothing beyond keeping its value in the state: Flutter no longer reports a `MissingPluginException`, and no artwork URL is loaded.

### Web
**Fixed**
- A request made when the module is out of memory fails with mpv's out of memory error, where it wrote at address 0 of the module's memory.
- A module that failed to load is loaded again by the next `Player`.
- The cover download is aborted at its timeout or when the track changes, and a response without a content length stops at 20 MB.

## [0.7.0] - 10-11-2026

### libmpv-r24
**All platforms**
- The property `duration-estimated`: yes when FFmpeg estimated the duration from the bitrate.
- The same file loaded again keeps its complete waveform and loudness scan, instead of decoding it again.
- The ring of a filter tap follows the format of its stream and goes when the tap turns off.

**Tizen**
- `libmpv_tizen-armv7l.so` for the TVs, Tizen 6.0 on, and `libmpv_tizen-x86_64.so` for the TV emulator, with `ao_tizen`, an output on Tizen's `audio_out`.

**webOS**
- `libmpv_webos-armv7l.so` for LG TVs with webOS 26 on, built with LG's webOS NDK, playing through ALSA.

### All platforms
**Breaking**
- `PlayerState` holds its values in six groups: `playback`, `network`, `file`, `output`, `settings` and `versions`. The flat fields read the same values, deprecated until 0.8.0. See MIGRATION.md.
- The `PlayerState` constructor takes the groups only: `PlayerState(settings: PlayerSettings(volume: 50))` for `PlayerState(volume: 50)`. `copyWith` still takes every field.

**Added**
- `playback.durationEstimated` and `player.stream.durationEstimated`: the duration is FFmpeg's estimate from the bitrate, with no hint to replace it.

**Changed**
- Flutter 3.38.10 is the minimum, lowered from 3.41.0 for flutter-webos. Before Flutter 3.41 an app bundles the web module on every platform, about 4.6 MB.
- `playback.duration` is the entry's `waveformDurationHint` when FFmpeg estimated the duration from the bitrate. An exact duration still wins.
- The same file loaded again, as a playlist of one entry with `Loop.playlist`, keeps its waveform and loudness scan, with no `null` in between.

### Tizen
**Added**
- Samsung Tizen TVs through [flutter-tizen](https://github.com/flutter-tizen/flutter-tizen): the build hook bundles the Tizen libmpv, and the user define `tizen: true` picks the one of the TV emulator. Checked on the Tizen 10.0 emulator.

### webOS
**Added**
- LG webOS TVs through [flutter-webos](https://github.com/lg-flutter-webos/flutter-webos): the package is an FFI plugin there, and `webos/CMakeLists.txt` bundles the webOS libmpv. An arm64 build fails: the TVs' libmpv is 32-bit ARM. Checked with the app running on the TVs' system libraries under qemu, not yet on a TV.

### Web
**Changed**
- A pause of the media session's `<audio>` element from outside the page follows `MediaSession.interruptionPolicy`, as on iOS and Android. With `pauseAndResume` it plays again when the browser plays the element, or when an interruption ends. 0.6 played on, as `keepPlaying` still does.

## [0.6.4] - 8-11-2026

### libmpv-r23
**All platforms**
- A pause in an `on_unload` or `on_after_end_file` hook with `keep-open=no` plays the rest of the file before the output closes.
- A pull output paused in its last few milliseconds keeps them: the position no longer creeps while paused, and the resume plays the rest.

**Android**
- E-AC3 passthrough opens the output at the rate of its IEC61937 stream, 192 kHz, instead of the output's own.

### All platforms
**Fixed**
- `openAll` at an index past the first gives the list it was asked for at once: the entry that played until the jump no longer shows in the playlist, and a call by index in that moment addresses the list the app sees.
- The build hook reads the iOS deployment version of code_assets 2.2 as well as the target version of the older ones.

### Android
**Added**
- Android TV, Fire TV and Google TV as a platform: the Android build, the remote's media keys through the media session, checked on the TV emulator of API 36. See the Android TV topic for the manifest.
- `MpvAudioKit.passthroughCodecs()`, which of AC3, E-AC3 and DTS the HDMI sink takes.

**Fixed**
- The media keys of a remote or headset reach the player on Android 7 and 8 while the app is in front.

### Web
**Fixed**
- Disposing a player no longer holds the page for about a frame: it waits for mpv to shut down before destroying it.

## [0.6.3] - 5-11-2026

### Contributions
- [@erikjara](https://github.com/erikjara): asked for tvOS and added it, in the kit and in the libmpv build ([#30](https://github.com/ales-drnz/mpv_audio_kit/issues/30), [#31](https://github.com/ales-drnz/mpv_audio_kit/pull/31), [libmpv-scripts#3](https://github.com/ales-drnz/libmpv-scripts/pull/3)).

### libmpv-r22
**All platforms**
- A pause in the last buffer of a file pauses at once, instead of blocking until the output played it out, and `keep-open-parked` tells the park of keep-open from such a pause.

**Android, iOS, Linux, macOS**
- An analysis turned on once an `fd://` source has loaded reads that source, even when the app has reused the descriptor, and each player of the process keeps its own.

**tvOS**
- `libmpv_tvos.xcframework.zip`, for Apple TV and its simulator.

### All platforms
**Fixed**
- A pause in the last 0.4 s of an entry keeps the rest: `completed` stays false, and `play()` plays the rest instead of starting the entry again.

### tvOS
**Added**
- tvOS through [flutter-tvos](https://fluttertv.dev) ([#30](https://github.com/ales-drnz/mpv_audio_kit/issues/30)): `tvos/Package.swift` links `libmpv_tvos.xcframework.zip` of the release, and the build hook bundles nothing there. Tried on the simulator.

## [0.6.2] - 5-11-2026

### libmpv-r21
**All platforms**
- A seek after a read error in a Matroska file tries the read again.
- A stream with `waveformDurationHint` cut by a read error publishes no loudness, and `eof-cached` no longer reads yes for its cache.
- The duration hint wins over a duration estimated from the bitrate and yields to an exact one, so the waveform of such a stream is not cut short.
- An AAC track in a fragmented MP4 no longer plays its priming samples outside DASH.
- Each stream of an `fd://` source reads at its own position.
- The waveform and the loudness of an `fd://` source describe that source even when the app reuses the descriptor on `FILE_LOADED`.
- A change of effects at the end of a stream that cannot seek no longer leaves it running.

**Android, iOS, Linux, macOS, Windows**
- A chunked HTTP stream whose resume the server refuses ends on a read error, instead of as a complete file.
- With `keep-open` the output plays to the last sample, instead of stopping up to 0.2 s early.

**Web**
- The module reads over HTTP through short answers, outages, credentials and refused resumes.
- A `makWebAudio.init` that fails leaves no context and no device.

### All platforms
**Breaking**
- A libmpv of another release, or a build of upstream mpv, fails `Player` start with a `PlayerInitException`, instead of a warning on `internalLog`. See MIGRATION.md.

**Changed**
- `withTaps`, `withVoices` and `withTransferPoints` throw an `ArgumentError` on an empty list.
- A bad key of `params` is refused before the state changes.
- `Media.toString` hides the values of `streamLavfOptions` and `demuxerLavfOptions` and the user info of the URI.
- `CompensationdelayEffect` changes go live instead of rebuilding the chain.

**Fixed**
- `endFile` carries the duration and position of an entry that loads and ends at once.
- Outside the web, a slow audio output no longer freezes the UI while the next entry opens ahead of time.
- The URL the resolver gave for a prefetch serves its own entry, also when two entries share a URL.
- A string effect option with a bracket reaches the filter whole.
- A refused header value, the demuxer options and the user info of a URI stay out of logs and errors.
- A second Flutter engine of the process leaves the players of the first alone.
- `playWhenReady` stays true after two `play()` calls at the end while a seek to the end is on its way.

### Web
**Changed**
- The demuxer cache starts at 64 MiB ahead and 16 MiB behind, in place of 150 and 50.
- `setAudioSampleRate` throws a `StateError` on a rate the browser refuses, and the output stays at the rate before.

**Fixed**
- The module runs on 512 MiB of memory at most, 256 MiB on iOS, which WebKit on phones and tablets allows.
- A page whose module cannot start its threads fails its players with a `PlayerInitException` after 30 s, naming the headers to check.
- A refused sample rate no longer leaves the page silent.
- A pause of the media session's audio from outside no longer leaves the page silent.
- A Hot Restart keeps the sound.
- The end of an entry is read before the next entry starts, as on the other platforms.

### Android
**Fixed**
- A pause or a stop made during a call stays one, and a play then waits for the call to end.

### Linux
**Fixed**
- A second Flatpak instance gets its own media controls.
- MPRIS `xesam:url` of a local file is percent-encoded, a `#` and a `?` of the name included.

## [0.6.1] - 2-11-2026

### Docs
- A shorter README, with the guides moved to topics of the API reference.

## [0.6.0] - 2-11-2026

### Contributions
- [@2697a](https://github.com/2697a): asked for Flutter Web support ([#26](https://github.com/ales-drnz/mpv_audio_kit/issues/26)).
- [@erikjara](https://github.com/erikjara): reported that the waveform of an HTTP stream served without byte ranges never filled from mpv's cache ([#29](https://github.com/ales-drnz/mpv_audio_kit/issues/29)).

### Breaking
- Flutter 3.41 is the minimum.
- `RubberbandEffect`, its eight `Rubberband*` enums and `AudioFilter.rubberband` are gone, as the LGPL libmpv of `libmpv-r20` leaves out Rubber Band. MIGRATION lists what replaces them.
- `Hook` has `prefetch`: an exhaustive switch over it needs the new case. On `libmpv-r20`, `on_load` runs once per entry, and the early open of the next one runs `on_prefetch`.
- The source resolver runs on `on_prefetch` for the next entry, while the current one plays. A URL it returns after the entry started or left the next place is dropped with a warning.
- `setMediaSession` throws `StateError` when another Flutter engine of the process owns the OS media session, which stays with the first engine that enabled it.
- The reconnect defaults of http entries are mpv's global `stream-lavf-o`, which an app's own `stream-lavf-o` replaces.
- A custom libmpv older than `libmpv-r20`, or built without one of its patches, plays with a warning on `internalLog` that names what it lacks.
- The event isolate's own diagnostics go to `internalLog` instead of `stream.log` and `stream.error`.

### Added
- The web: players run libmpv in WebAssembly and play through Web Audio, on a cross-origin isolated page ([#26](https://github.com/ales-drnz/mpv_audio_kit/issues/26)).
- `MpvAudioKit.unsupportedReason` says what a page lacks, and a player there fails at once with a `PlayerInitException`.
- `MpvAudioKit.needsUserGesture` and `needsUserGestureStream` say whether the browser holds the sound until a user gesture, and `Player.play` resumes it from inside one.
- `Media.fromBlob` plays a file the user picks or drops in the browser.
- The OS media session on the web, through `navigator.mediaSession`.
- `Media.waveformDurationHint` gives the length of an HTTP stream that cannot seek and tells none, so its waveform decodes from mpv's cache ([#29](https://github.com/ales-drnz/mpv_audio_kit/issues/29)).
- `MpvAudioKit.ensureInitialized` registers the license texts of the bundled libmpv, so `showLicensePage` and `AboutDialog` list them. On the web they are also in `web/THIRD_PARTY_LICENSES.txt`.
- `endFile` carries the media, position and duration of the entry that ended, and whether a read error cut it short (`readError`, `skippedSegments`). `PlayerState` has the same two fields for the parked entry.

### Fixed
- An http entry recovers from a dropped connection, a failed open or an HLS segment that does not open, instead of ending early without an error.
- A seek after a read error tries the read again.
- `playing` comes back at the next file of a gapless advance, so `playbackState`, the spectrum, the taps and the media session no longer stay idle.
- A seek or `play()` at the end that parks again at once raises `completed` again, so `playWhenReady` goes back off.
- `play()` and `jump()` at the end that land on the end again no longer leave `playWhenReady` true over a silent park.
- Each park at the end spends the play intent once, so a loop turned off at the park, or a load that leaves it, no longer turns `playWhenReady` off.
- When a short entry plays out between two position updates, `state.position` no longer goes back to its start.
- The effects chain keeps the values set live through a seek, a loop, a track switch and the next file.
- The source resolver gets the `Media` of the entry that loads, also when two entries share a URL.
- A new player no longer shows the waveform or the loudness scan of one disposed just before.
- The Hot Restart cleanup closes the old players off the main isolate, and the first new player waits for it.
- Covers reach the media session plugins as bytes: `file://` is read in Dart, and Apple downloads covers with the same retries and 20 MB limit as the other platforms.
- Android: `content://` and `android.resource://` covers show again, and are checked as images.
- Android: the media service stays in the foreground through a call, so playback resumes when it ends.
- Windows: a second engine gets its own media session channel, and a media key after the first engine is destroyed no longer uses freed memory.
- Linux: one MPRIS server per process, owned by the first engine, and `xesam:url` is a file URI for a local item.

### Build
- The bundled libmpv is LGPL, version 3 or later, instead of GPL, and its release has the license texts in `licenses.zip`.
- The end of a gapless file plays to its last sample when the output ran dry in its last buffer, instead of parking up to 0.4 s early.
- iOS and macOS share one Swift package in `darwin`.
- Windows: a refused `http://` or `smb2://` connection fails at once instead of after the network timeout.
- Updated libmpv to `libmpv-r20` across all platforms, with the web module shipped as web assets of the package.

### Docs
- The README describes the web and how to serve a cross-origin isolated page, and links a live demo of mpv_studio. MIGRATION covers 0.6.0.
- The README has a Licenses section: what an app that ships the bundled libmpv must do, and the GPL route for Rubber Band.
- The headers of the generated effects files say that the filter descriptions in their comments are FFmpeg's text, under FFmpeg's licenses.

## [0.5.3] - 22-10-2026

### Contributions
- [@erikjara](https://github.com/erikjara): reported and fixed that the waveform of an HTTP file decoded from the cache was not marked as partial ([#28](https://github.com/ales-drnz/mpv_audio_kit/issues/28), [libmpv-scripts#1](https://github.com/ales-drnz/libmpv-scripts/pull/1)).

### Build
- The waveform of an HTTP file decoded from mpv's cache emits its partial envelopes with `decoding`, `coverageBins` and `decodeFraction` set, then the final one, like a local file ([#28](https://github.com/ales-drnz/mpv_audio_kit/issues/28)). An envelope that grows from playback keeps `decoding` false.
- Updated libmpv to `libmpv-r19` across all platforms.

### Docs
- README and dartdoc describe the libmpv the package bundles, without notes on what older releases did.

## [0.5.2] - 19-10-2026

### Contributions
- [@erikjara](https://github.com/erikjara): reported that the cleanup of old Hot Restart files failed on iOS ([#24](https://github.com/ales-drnz/mpv_audio_kit/issues/24)).

### Breaking
- `PlayerApi` has `insert` and the `keepCurrent` parameter of `clearPlaylist`: a class that implements it by hand must add them.
- `setSystemVolume` outside 0 to 100 throws `RangeError`, like `setVolume`, and invalid `SpectrumSettings` throw in release builds too.
- `addAudioTrack` and `removeAudioTrack` throw `MpvCommandException` when mpv refuses them.
- An effect value that lavfi would read or write out of bounds throws `ArgumentError`, and the state stays as it was.
- `openAll` fails as a whole when mpv refuses an append: the entries it added are removed and the play intent goes back.
- The resume point no longer saves the effect chain, and the player's chain wins over one saved by an earlier version.
- A-B loop points apply to the file they were set on and go back to `null` when it ends.
- `audioDriver` starts as `''`, the automatic choice mpv reports, instead of `'auto'`.
- A fallback to the null output, when no audio device opens, emits a `LogError` on `stream.error`.
- `dispose()` no longer waits for the done event of its streams: a paused listener gets it when it resumes.
- `setMediaSession` outside the root isolate throws a `StateError` instead of killing that isolate.
- Each hook event has its own id, and a consumer hook no longer receives an event that its timeout already continued.
- Android: the players of a Flutter engine destroyed while the process stays stop and release libmpv. Keep the engine alive to play after the activity closes.

### Added
- `Media.start` opens an entry at a chosen position, and wins over a saved resume point.
- `Media.end` ends an entry at a chosen point of the file, for previews and segments of a long file.
- `Player.insert` puts a track at any position of the queue, such as right after the current one.
- `clearPlaylist(keepCurrent: true)` empties the queue and keeps the current track playing.

### Changed
- While the player is paused or stopped, `stream.fft`, `stream.pcm` and the filter taps stop polling mpv. A new listener still gets the current frame.
- The Hot Restart cleanup keeps its state in an environment variable instead of files in the temp directory. Files left there by earlier versions can be deleted.
- A ready waveform can end with unfilled bins when the audio is shorter than its estimated length.
- Error and log messages use plain punctuation, and `CacheRange.toString()` reads `CacheRange(start: ..., end: ...)`.

### Fixed
- `openAll` of a few thousand entries no longer loses some on a busy device: it sends its appends in windows of 512 instead of all at once, still in about 0.25 s for 5000.
- A `pause()` right after `play()`, `jump()` or a load at the end of the queue is no longer undone.
- A failed `openPlaylistFile`, or an `open` that mpv refuses, puts back the previous play intent.
- `openAll` at the end of the queue no longer flashes `playWhenReady` to false, and keeps a `play()` called during it.
- When `completed` turns true, `state.position` is where the file ended.
- An absolute seek before the start goes to the start, and `setChapters` keeps in the state the chapters mpv accepted.
- Waveform and loudness scan start again at every file load, so a path with new content no longer keeps an old result.
- `stream.tap` emits a new slice on every poll while playing, about 30 Hz instead of 10 Hz with FLAC files.
- A listener that subscribes to `stream.fft` or `stream.pcm` while paused gets the current frame.
- One player no longer silences the filter taps, the waveform or the loudness scan of another player.
- Live updates of alimiter, agate, afreqshift and aphaseshift options, and of adelay delays, rebuild the stage instead of playing a wrong value.
- `AiirChannelsX.withChannels` keeps its coefficients at full precision, and mpv accepts effect durations under a millisecond.
- `PcmSource.abort()` on a queued source removes its entry, also when the app changes the playlist at the same moment.
- `dispose()` no longer blocks the main isolate while mpv shuts down, and completes when the app holds a paused subscription.
- Disposing a player while a busy core serves its event reads no longer skips the destroy.
- A source resolver that answers after its hook timed out no longer rewrites the URL of the next entry.
- `setSourceResolver` with `timeout: null` removes an earlier deadline, and a late `continueHook` no longer releases the next event of the same hook.
- With the prefetch on, the source resolver runs once for an entry the prefetch opened, so a resolver that returns a new URL each time keeps gapless playback.
- `file://localhost` URLs open, and a `file://` URL from the source resolver reaches mpv as a path.
- `deleteResumeConfig` takes a `file://` or `asset://` URI as given to `open`.
- `setNetworkTimeout` caps the value at 2147.48 s, the most FFmpeg accepts, instead of making every network open fail.
- Asset copies get a short file name, so an asset with a deep path opens.
- A debug launch that gets the pid of an earlier process no longer crashes, and the Hot Restart cleanup works on iOS ([#24](https://github.com/ales-drnz/mpv_audio_kit/issues/24)) and armeabi-v7a.
- After a Hot Restart, the analysis and the media session left on by the old run are turned off.
- Profile builds no longer run the debug Hot Restart support: an idle player wakes once a second, as in release.
- Two `setMediaSession` calls in flight, or a dispose followed by a new player, no longer leave the OS media session off.
- Android: a `content://` source no longer reads or writes the resume point of another file, and its descriptors are closed when mpv never takes the entry.
- Android: a call or an assistant no longer restarts a track the user paused, and the notification seek bar no longer stays frozen.
- Android: opening a file from a cloud provider no longer freezes the app, and a second Flutter engine no longer turns off the media session.
- iOS and macOS: a second engine no longer clears the Now Playing entry of the one that owns it.
- Windows: `file://C:/...` opens the drive path again, and `file://server/share` opens the share.
- Windows: the media controls no longer pile up genres or keep the previous track number.
- Linux: a new `desktopEntry`, `appName` or rate list reaches MPRIS without a disable.

### Build
- While a source resolver runs for the prefetch, the playing track keeps its duration, metadata and position, and a `dump-cache` no longer crashes the app.
- The prefetch skips an entry whose `httpHeaders`, `httpChunkSize`, `start` or `end` differ from the playing one, so headers never reach another host. That entry opens when it starts, after a short pause.
- Two players prefetch independently, and `prefetchState` turns `failed` at once and goes back to `idle` after `stop()`.
- The waveform and the loudness scan no longer crash on a file with more than 8 channels or on an MP3 that turns from stereo to mono.
- The waveform and the loudness scan follow the selected audio track, work on Android `content://` sources and on files whose timestamps do not start at zero.
- Stopping or skipping a file stops its analysis and its download, and a raw AAC over HTTP is analyzed from the cache.
- `setAudioSpdif` passthrough works, and https sources play through `setHttpProxy`.
- FFmpeg audio filters refuse values that read or write out of their buffers, so a `RawAudioEffect` fails the chain instead of crashing.
- SMB stop and quit return at once when the server stops answering, instead of after about 120 s, and URLs with a port, an IPv6 host or a bare `%` open.
- `setChapters` with fewer chapters than the current one no longer crashes.
- A live PCM source with a loop on plays once and sets `completed` at its end.
- The spectrum no longer shows the previous track's samples after the output format changes, and keeps its frame through a long pause.
- Android: audiotrack rests while there is nothing to play, reopens after audioserver dies, keeps its audio and position across a pause, and feeds silence for `setAudioStreamSilence`.
- iOS: the media session's audio mode is no longer replaced by `MoviePlayback`.
- Windows: the audio output closes on mpv's core thread when a player is disposed.
- Updated libmpv to `libmpv-r18` across all platforms.

### Docs
- README, dartdoc and MIGRATION say what each audio driver does with the volume, exclusive mode and the media role, and how hooks, the source resolver and live PCM entries behave with the prefetch and loops.

## [0.5.1] - 15-10-2026

### Added
- The variants of `MediaSessionArtwork`, `Track` and `Channels` are exported, so an app can switch over them.
- `CoverArt.toString` shows the MIME type and the size.

### Changed
- `completed` turns true when the end of the last track is heard, at mpv's keep-open park, instead of one output buffer earlier when the decoder finishes.
- `openAll` sends a large playlist in one go: 5000 entries load in about 0.2 s instead of 40 s.
- Coming back to a finished waveform or loudness scan reuses the result instead of decoding the file again.
- The loudness meter reads its four values in one call, and a growing waveform is not emitted again while it does not change.
- `chapters`, `tracks`, `chapterMetadata` and `audioSpdif` emit only when their content changes.
- `Media.toString` no longer prints HTTP header values.

### Fixed
- Disposing a player turns off the waveform and loudness scan it armed, so the next player no longer decodes every file.
- A NaN or infinite sample no longer leaves the spectrum bands stuck at NaN, and an emit interval under 8 ms no longer polls without pause.
- `play()` with nothing loaded, or at the end of a source that cannot seek back, leaves `playWhenReady` off, and in the last moments of a track it no longer restarts it.
- A failed `open`, `openAll` or `openPlaylistFile` puts back the previous play intent, and `play()` or `pause()` right after one that is not awaited decides whether the new file plays.
- `playbackState` no longer flashes `idle` while a file loads: `idle` means no file is loaded.
- `stop()` after a failed load empties the playlist and ends a live PCM source queued there.
- A live PCM source whose entry left early, or that the app keeps only through its `Media`, ends or plays as expected, and a live entry stays unseekable with the cache forced on.
- `PcmSource.addStream` fails with a `StateError` on a chunk after `close()`.
- Android `content://` file descriptors, from `open`, the playlist calls and `addAudioTrack`, are closed once their entry or file is gone, and at dispose.
- A player whose init fails no longer reports an unhandled error when nothing awaits it, and `continueHook` after `dispose` does nothing instead of throwing.
- A failing next or previous from the OS media session is logged instead of escaping as an unhandled error.
- A ReplayGain tag of 0 dB is read as 0, not as missing.
- The media session artwork download refuses a redirect from https to plain http.

### Build
- The build hook's download times out and retries network failures, a 404 points at the `libmpv` user define, and a user define with a missing path fails with a clear message.
- The iOS podspec no longer links AudioToolbox, Security and CoreFoundation, which the plugin does not use.
- Removing the next playlist entry while a source resolver runs for its prefetch no longer reads freed memory.
- Two players tapping a filter with the same label no longer write past the tap buffer, and frames larger than the tap scratch keep all their samples.
- Turning the waveform off keeps a running loudness scan going, and stopping a file ends the analysis it fed instead of leaving it half done.
- The SMB timeout is read in microseconds, as mpv passes it.
- Updated libmpv to `libmpv-r17` across all platforms.

## [0.5.0] - 14-10-2026

### Contributions
- [@erikjara](https://github.com/erikjara): reported that the waveform analyzer downloaded a remote file a second time ([#22](https://github.com/ales-drnz/mpv_audio_kit/issues/22)).
- [@jacoplane](https://github.com/jacoplane): reported that a file without tags kept the previous file's `metadata` ([#25](https://github.com/ales-drnz/mpv_audio_kit/issues/25)).
- [@2697a](https://github.com/2697a): asked for a way to play raw PCM while it arrives, such as generated speech ([#27](https://github.com/ales-drnz/mpv_audio_kit/issues/27)).

### Breaking
- Audio effects are an ordered `List<AudioEffect>`, applied in list order, in place of the `AudioEffects` bundle. The same filter can appear more than once, and raw lavfi entries (`RawAudioEffect`) can sit anywhere in the list.
- Effect classes are named `XxxEffect` (was `XxxSettings`), their parameters and enum members are camelCase (`levelIn`, `lrToMs`), and `enabled` defaults to `true`.
- An option ffmpeg spells twice has one field, under the longer name: `BassEffect(gain: 3)`, not `g` or `gain`.
- The filter-id enum is now `AudioFilter`, and `stream.tap` takes an `instance` for filters that appear more than once.
- Minimum Dart 3.10 and Flutter 3.38, and Flutter 3.47.4 to build for iOS.
- libmpv is bundled as `libmpv_audio_kit.so`, `mpv_audio_kit.dll` or `libmpv_audio_kit.framework`, and the Linux fallback to a system `libmpv.so` is gone.
- A call that fails at libmpv or at its source throws one sealed `PlayerException`: `PlayerDisposedException`, `PlayerInitException`, `MpvCommandException` (was `MpvException`) and `SourceException`. `stop()` and `setShuffle()` now throw too when mpv rejects them, and a missing `asset://` throws instead of reaching mpv.
- `next()`, `previous()`, `nextPlaylist()` and `previousPlaylist()` return `false` when there is no track to go to, and an index out of range throws `RangeError` in `jump()`, `remove()`, `move()` and `replace()`.
- A negative volume, or a rate or pitch outside `[0.01, 100]`, throws `RangeError` before reaching mpv.
- State streams give a new subscriber the current value first, then the changes, so `StreamBuilder` needs no `initialData` and `skip(1)` waits for the next change. Event streams are unchanged.
- The `Mpv` prefix is kept only on types that carry mpv's own data: `MpvPlayerError`, `MpvEndFileError`, `MpvLogError` and `MpvPrefetchState` are now `PlayerError`, `EndFileError`, `LogError` and `PrefetchState`, and `MpvEndFileErrorX` is `EndFileErrorX`.
- `MpvLibraryException`, `AfCommand` and `AudioEffectsX.active` are no longer public: a failed start throws `PlayerInitException`, and each stage has its own `filter`.
- `systemVolume` and `systemMute` are `null` while no audio output is open.
- `stream.loudness` is `stream.loudnessScan`, next to the live `stream.loudnessMeter`.
- `setSpectrum`, `updateSpectrum` and `setLogLevel` are synchronous and work before the player has started. The spectrum settings are in `state.spectrum`, and the `spectrumSettings` getter is gone.

### Added
- libmpv reaches the app through a Dart build hook, with one pinned checksum per binary. An app can bundle its own build with the `libmpv` user define, a directory of release assets or a single file.
- The player reports on `stream.internalLog` when the loaded libmpv is not the release it expects.
- Live effect updates, taps and the loudness meter follow one stage when the others are toggled or reordered.
- `PcmSource` and `Player.openPcmStream` play raw PCM chunks as they arrive, such as generated speech, with no file or local server ([#27](https://github.com/ales-drnz/mpv_audio_kit/issues/27)).

### Changed
- The effects API is generated by `tool/codegen` in this repository, and CI checks the generated files match it.
- CI analyzes the package, tests it on Linux and macOS, and builds the test app on every platform.

### Fixed
- After `stop()`, a failed load, or a track without a given value, the state no longer keeps the previous file's values (path, title, duration, audio parameters, cover, waveform and the like): each goes back to its default. While the next track loads, the OS media session waits for the new ones instead of showing the gap or a live stream.
- `play()` at the end of the queue starts the last track again. It showed playing over silence, since mpv paused again at the end.
- A file without tags clears `state.metadata` and emits an empty map on `stream.metadata`, instead of keeping the previous file's tags.
- A `file://` URL with escapes that are not UTF-8, such as a Latin-1 file name, opens again. Since 0.4.9 it was decoded to a name that does not exist.
- An effects chain the filter graph refuses throws `MpvCommandException`, and the state goes back to the last list mpv accepted. Before, the call returned, the state showed the new chain and the old one kept playing.
- A chain rebuilt after live slider changes applies the requested values: a stage moved live and set back could stay at the live value.
- A value an effect got live keeps playing after a seek, a loop or an audio track switch. mpv rebuilds its filters there from the values they were created with, which brought back the old one.
- The live loudness meter reads the first enabled `Ebur128Effect` with `metadata` on, so a disabled or silent first one no longer mutes it.
- A setter emits the value it was given once: volume, gains and ReplayGain no longer come back rounded (`42.37` as `42.400001525878906`), and durations keep their microseconds. `setCache`, `setDemuxer` and `setReplayGain` no longer emit a half-applied value.
- `audioParams` emits once when a file unloads and once when the next one loads, with all its fields. mpv reports the codec and the format separately, which made a track change emit up to six partial values.
- Playlist entries with the same URI keep their own `Media` and `extras`: the player maps mpv's entry ids back to them instead of the URI, where the last one loaded won.
- `sendRawCommand` rejects `set`, `change-list`, `cycle` and the other property commands on `af` or `pause`, also through prefixes and `loadfile` options, which desynced the effects chain or the play and pause state. The check is against mistakes, not every way mpv offers.
- On Linux, Android and Windows a remote cover download always verifies the certificate, against the system roots and the player's `tls-ca-file`.
- `open`, `openPlaylistFile` and `jump` with playback on no longer start paused after a playlist whose last track ends as soon as it loads, such as a very short one. The player asks mpv whether it is parked at the end instead of trusting `completed`, which can miss that end.
- `completed`, and with it `playbackState` and the play and pause intent, follows the end of a playlist with very short entries: it could rise at a track change and drop again, or never rise at the end. The player now reads the end from mpv at each load, restart and pause instead of following the `eof-reached` changes, which mpv can skip.

### Build
- Linux: libmpv loads with glibc 2.31 or later (it needed 2.38) and on systems without PipeWire or PulseAudio, and needs only ALSA. A PipeWire older than 0.3.57 is skipped in favour of PulseAudio.
- The library's SONAME is `libmpv_audio_kit.so` on Linux and Android, so an app using media_kit too no longer fails to build or load a second `libmpv`.
- The per-filter tap is keyed on the chain label, so two instances of one filter get separate taps.
- mpv's version string carries the libmpv release, which the player checks at startup.
- Every source is pinned: tarballs by SHA-256, Windows ones included, and git sources by the commit of their tag.
- Changing the effects near the end of a track no longer stops playback there when the change removes a stage that holds the end of the file, such as `RubberbandEffect`.
- An effect added while the file ends, as during that re-seek, starts on the real audio format: `HdcdEffect` came up disabled.
- Changing the effects right after a seek no longer stalls a short file when a stage with a long look-ahead, such as `DynaudnormEffect`, already holds its end.
- Linux: an app that exits without disposing the player no longer crashes at exit, since PipeWire and PulseAudio stay loaded until the process ends.
- The waveform and loudness scan of an HTTP file that plays from its start decode it from mpv's cache as it downloads, so the file is downloaded once instead of twice ([#22](https://github.com/ales-drnz/mpv_audio_kit/issues/22)). Otherwise they open it again as before, with the same result.
- A waveform or loudness scan enabled while a file opens, as by a view that subscribes when the queue fills, no longer opens the file a second time. A Jellyfin HLS transcode could fail to open.
- The waveform and loudness scan of a local file give the result of one decode of it: loudness and peaks no longer drift where the parallel decode splits the file.
- The loudness scan of a Matroska file no longer reads -70 LUFS, and the one of an MP2 file no longer crashes the app.
- The waveform of an MP3 no longer ends one encoder delay short.
- The mak-pcm protocol, which mpv reads as the app adds chunks, with playback starting about 0.2 s after the first one ([#27](https://github.com/ales-drnz/mpv_audio_kit/issues/27)).
- Updated libmpv to `libmpv-r16` across all platforms.

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
