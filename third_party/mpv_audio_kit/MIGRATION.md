# Migrating to 0.8.0

0.8.0 runs on libmpv-r27, which the build hook bundles, and on no other
libmpv. An app that bundles its own needs a build of libmpv-scripts at
libmpv-r27. 0.8.0 removes what 0.7.0 deprecated and changes a few
signatures and defaults. Most apps change only the reads of the state.

## TLS certificates are verified

`tls-verify` is on by default, as in mpv 0.42 and FFmpeg 9: an `https://`
source must present a certificate a trusted root signed. 0.7 kept it off.
A home server with a self-signed certificate (a Jellyfin or a NAS) now
fails to open, with a certificate error on `player.stream.log`. The
waveform and the loudness scan of that server fail the same way. The
covers of the media session were verified before 0.8.0 too. `http://`
sources, local files and SMB are not affected.

- Keep verification and trust the server: pass `setTlsExtraCaFile` a PEM
  file with its certificate, or with the CA that signed it. The file is
  trusted on top of the built-in roots, so every other server opens as
  before.
- Or trust only your own servers: `setTlsCaFile` replaces the built-in
  roots with its file, and a server its file does not vouch for fails.
- Or turn verification off, as 0.7 had it:
  `Player(configuration: const PlayerConfiguration(tlsVerify: false))`,
  or `setTlsVerify(false)` later.

## The flat fields of PlayerState are gone

Each value is read from its group: `state.position` is
`state.playback.position`. The analyzer flags every read left. The
streams of `player.stream` do not change, and `copyWith` still takes
every field by its name.

| Group | Its fields, `state.<field>` before 0.8.0 |
| --- | --- |
| `playback` | `playlist`, `playing`, `playWhenReady`, `completed`, `position`, `duration`, `seeking`, `seekable`, `partiallySeekable`, `percentPos`, `timeRemaining`, `playtimeRemaining`, `eofReached`, `audioPts`, `currentChapter`, `loop`, `shuffle`, `abLoopA`, `abLoopB`, `abLoopCount`, `remainingAbLoops` |
| `network` | `buffering`, `buffer`, `bufferingPercentage`, `bufferDuration`, `demuxerCacheState`, `pausedForCache`, `demuxerViaNetwork`, `demuxerIdle`, `cacheSpeed`, `cacheBufferingState`, `readError`, `skippedSegments` |
| `file` | `metadata`, `chapterMetadata`, `chapters`, `tracks`, `currentAudioTrack`, `audioParams`, `audioBitrate`, `coverArt`, `mediaTitle`, `fileFormat`, `fileSize`, `path`, `filename`, `streamPath`, `streamOpenFilename`, `playlistPath`, `currentDemuxer`, `demuxerStartTime` |
| `output` | `audioOutParams`, `audioDevice`, `audioDevices`, `audioOutputState`, `currentAo`, `systemVolume`, `systemMute` |
| `settings` | `volume`, `mute`, `volumeMax`, `volumeGain`, `volumeGainMin`, `volumeGainMax`, `rate`, `pitch`, `pitchCorrection`, `audioDelay`, `gapless`, `replayGain`, `audioEffects`, `spectrum`, `coverArtAuto`, `prefetchPlaylist`, `cache`, `demuxer`, `networkTimeout`, `tlsVerify`, `tlsCaFile`, `hlsBitrate`, `cookies`, `httpProxy`, `audioExclusive`, `audioMediaRole`, `audioBuffer`, `audioStreamSilence`, `audioNullUntimed`, `audioSpdif`, `audioSampleRate`, `audioFormat`, `audioChannels`, `audioClientName`, `audioDriver`, `mediaSession` |
| `versions` | `mpvVersion`, `ffmpegVersion` |

`dart fix` cannot rewrite these reads: a data-driven fix does not turn a
getter into a chain of two.

## Other changes

| 0.7 | 0.8.0 |
| --- | --- |
| `openPcmStream(format)` plays at once | follows `PlayerConfiguration.autoPlay` (off by default): pass `play: true` |
| `setMediaSession` throws `StateError` | throws `MediaSessionException`, a `PlayerException` whose `reason` is `notRootIsolate`, `otherPlayer` or `otherEngine` |
| `setVolume` above 1000, `setVolumeGain`, `setVolumeGainMin`, `setVolumeGainMax` and `setVolumeMax` out of range throw `MpvCommandException` | throw `RangeError` before anything is written |
| `setAbLoopCount(-1)` throws `ArgumentError` | throws `RangeError` (a subtype: `on ArgumentError` still catches it) |
| `setAudioBuffer`, `setNetworkTimeout` and `setAudioSampleRate` out of mpv's range throw `MpvCommandException` | throw `RangeError` before anything is written: outside 0 to 10 s, below 0, and outside 0 to 768000 |
| `class CoverArt`, `FftFrame`, `Loudness`, `LoudnessScan`, `MediaSession`, `MpvHookEvent`, `MpvLogEntry`, `PcmFrame`, `PlayerConfiguration`, `BandProcessor` | `final class`: they cannot be extended or implemented outside the package |
| `class Player`, `class PlayerStream` | `interface class`: a fake still implements them, nothing extends them |
| A fake that implements `PlayerApi` or `Player` overrides `stop()` and `openPcmStream(format, {bool play = true, ...})` | overrides `stop({bool keepPlaylist = false})` and `openPcmStream(format, {bool? play, ...})`, and implements `initialized` unless it has a `noSuchMethod` |

A `switch` over `PlayerException` that lists every case needs a
`MediaSessionException` case. An `on PlayerException` no longer catches
the out-of-range values above: they are programming errors, checked before
the call reaches libmpv. NaN still throws `ArgumentError`. The settings
objects (`setReplayGain`, `setCache`, `setDemuxer`) still leave their ranges
to mpv, which refuses a value with `MpvCommandException`.

# Migrating to 0.7.0

0.7.0 runs on libmpv-r24, which the build hook bundles, and on no other
libmpv. An app that bundles the default libmpv changes nothing; one that
bundles its own needs a build of libmpv-scripts at libmpv-r24.

## PlayerState in groups

`PlayerState` holds its values in six groups. The flat fields of 0.6
still read the same values, deprecated: the analyzer points at each one,
and they go in 0.8.0.

| Group | What it holds | Some of its fields |
| --- | --- | --- |
| `playback` (`PlaybackState`) | transport, position, the playlist | `playing`, `position`, `duration`, `playlist`, `loop` |
| `network` (`NetworkState`) | buffering, cache, read health | `buffering`, `buffer`, `demuxerCacheState`, `readError` |
| `file` (`FileState`) | what mpv read from the current file | `metadata`, `tracks`, `audioParams`, `coverArt`, `path` |
| `output` (`OutputState`) | the audio output in use | `audioOutParams`, `audioDevice`, `audioOutputState`, `currentAo` |
| `settings` (`PlayerSettings`) | what the app asked of the player | `volume`, `rate`, `audioEffects`, `cache`, `mediaSession` |
| `versions` (`LibraryVersions`) | libmpv and FFmpeg | `mpvVersion`, `ffmpegVersion` |

| 0.6 | 0.7.0 |
| --- | --- |
| `player.state.position` | `player.state.playback.position` |
| `player.state.volume` | `player.state.settings.volume` |
| `player.state.metadata` | `player.state.file.metadata` |
| `PlayerState(volume: 50)` | `PlayerState(settings: PlayerSettings(volume: 50))` |
| `state.copyWith(volume: 50)` | unchanged: `copyWith` takes the groups and every field |

The streams of `player.stream` do not change: `player.stream.position`
stays as it is. The deprecation message of each flat field names its
group, so `dart fix` is not needed: the message says the new path.

A field added in 0.7.0 is in its group only: `playback.durationEstimated`
has no flat getter.

## Behavior changes

- `playback.duration` is the entry's `waveformDurationHint` when FFmpeg
  estimated mpv's duration from the bitrate (an MP3 without a Xing header,
  ADTS AAC, a length a server guessed): such an estimate can be far off.
  An exact duration still wins over the hint, and `player.stream.duration`
  follows. `playback.durationEstimated` tells an estimate with no hint.
- The same file loaded again (a playlist of one entry with
  `Loop.playlist`) keeps its waveform and loudness scan: mpv no longer
  decodes it again, and `player.stream.waveform` and
  `player.stream.loudnessScan` no longer emit `null` in between. Another
  file under the same path, or a pass that had not finished, is decoded
  again as before.
- On the web, a pause of the media session's `<audio>` element from
  outside the page (the browser, a call, another app) follows
  `MediaSession.interruptionPolicy`, as on iOS and Android. With the
  default `pauseAndResume` the player pauses, and plays again when the
  browser plays the element again; with `pauseOnly` it stays paused. 0.6
  played on, as `keepPlaying` still does.

# Migrating to 0.6.2

0.6.2 runs on libmpv-r21, which the build hook bundles, and on no other
libmpv. An app that bundles the default libmpv changes nothing.

## A libmpv of another release fails

An app that bundles its own libmpv (the `libmpv` user define) or passes
one to `MpvAudioKit.ensureInitialized` must give a build of libmpv-scripts
at libmpv-r21: its `mpv-version` ends with `+r21`.

| 0.6.1 | 0.6.2 |
| --- | --- |
| Another release, or upstream mpv, played with a warning on `internalLog` | A `Player` fails to start with a `PlayerInitException` that names the release it found |
| A web module of another release was refused by its ABI only | It is refused by its release too |

A GPL build with Rubber Band is built from the same release, with
`LIBMPV_GPL=1`.

## Behavior changes

- `AechoEffect.withTaps`, `ChorusEffect.withVoices` and
  `CompandEffect.withTransferPoints` throw `ArgumentError` on an empty
  list, instead of returning a copy that mpv refuses. Turn the effect off
  with `enabled: false`.
- A key of `params` that is no option name throws `ArgumentError` before
  the state changes. Before, the state held the new chain while mpv kept
  the old one.
- On the web the demuxer cache starts at 64 MiB ahead and 16 MiB behind,
  in place of 150 and 50. `setDemuxer` sets other sizes.
- On the web `setAudioSampleRate` throws `StateError` for a rate the
  browser refuses, and the output stays at the rate before.

# Migrating to 0.6.0

0.6.0 adds the web and needs libmpv-r20, which the build hook bundles. Most
apps change nothing. These are the cases that need a change.

## Flutter 3.41

The package needs Flutter 3.41 or later, for the web assets it ships.

## Hook.prefetch

With `setPrefetchPlaylist(true)`, mpv opens the next entry ahead of time.
On libmpv-r20 it runs a hook of its own for that early open,
`Hook.prefetch`, while the current entry keeps playing, and `Hook.load`
runs once per entry, when it starts.

| 0.5.x | 0.6.0 |
| --- | --- |
| `Hook.load` ran for the early open and again when the entry started | `Hook.prefetch` runs for the early open, `Hook.load` once at the start |
| An exhaustive `switch` over `Hook` | Add the `Hook.prefetch` case |
| A `Hook.load` listener that rewrites `stream-open-filename` for the prefetch | Register `Hook.prefetch` too and rewrite `prefetch-open-filename`; `prefetch-playlist-entry-id` names the entry |

`setSourceResolver` handles both hooks: an app that resolves URLs through
it needs no change. Its resolver now runs for the next entry while the
current one plays; a URL it returns after the entry started, or after the
entry left the next place, is dropped with a warning on `internalLog`.

## One OS media session per process

The OS media session is one per process. The first Flutter engine that
enables it owns it until it disables it or detaches, on every platform, and
the commands go to it. `setMediaSession` in another engine (an add-to-app
screen, a background task) throws `StateError` instead of taking the
session over.

## The reconnect defaults are mpv's global stream-lavf-o

The player retries a dropped HTTP connection through mpv's global
`stream-lavf-o` (`reconnect=1,reconnect_delay_max=7,`
`reconnect_on_network_error=1,seg_max_retry=4`). Setting `stream-lavf-o`
with `setRawProperty` replaces them. To add a key and keep them:

```dart
await player.sendRawCommand(['change-list', 'stream-lavf-o', 'add', 'timeout=5000000']);
```

`Media.streamLavfOptions` adds options for one entry, on top of them.

## A libmpv through the user define

An app that bundles a libmpv through the build hook's `libmpv` user
define gets a warning on `internalLog` when it is older than libmpv-r20 or
lacks one of its patches, naming what each missing patch costs. It still
plays. 0.6.2 refuses such a libmpv: see Migrating to 0.6.2.

## RubberbandEffect

libmpv-r20 is LGPL, version 3 or later, and leaves out Rubber Band, which
is GPL. `RubberbandEffect`, the `Rubberband*` enums (`RubberbandPitch`,
`RubberbandTransients` and the others) and `AudioFilter.rubberband` are
gone.

| 0.5.x | 0.6.0 |
| --- | --- |
| `RubberbandEffect(pitch: p)` | `setPitch(p)`: mpv resamples and corrects the tempo with `scaletempo2` |
| `RubberbandEffect(tempo: t)` | `setRate(t)` with `setPitchCorrection(true)`, the default, or `AtempoEffect(tempo: t)` in the chain |
| `RubberbandEffect(pitch: p, tempo: t)` in the chain | `AsetrateEffect` with `AresampleEffect` changes pitch and speed together; follow it with `AtempoEffect` to set the tempo apart |
| `formant`, `transients`, `window` and the other options | No LGPL equivalent |

To keep Rubber Band, build libmpv yourself with libmpv-scripts' GPL option
(`LIBMPV_GPL=1`), bundle it with the build hook's `libmpv` user define and
write the stage as `RawAudioEffect('lavfi-rubberband=pitch=1.0594')`. That
library is GPL, version 3 or later: an app that ships it has to be
distributed under the GPLv3, with its source (README, Licenses).

### Saved effect chains

An app that stores chains and maps them back to typed effects by filter
name no longer finds `rubberband`: `AudioFilter.values.byName('rubberband')`
throws `ArgumentError`. Drop the stage or map it to one of the above when
it reads a saved chain. A `rubberband` stage that reaches mpv, as a
`RawAudioEffect`, is an unknown filter on the bundled libmpv: with a
file loaded, `setAudioEffects` throws `MpvCommandException` and keeps the
last chain mpv accepted; without one, the error comes at the next load,
on `stream.error`.

## Behavior changes

- The event isolate's own diagnostics (an event it could not decode, a
  property it could not read) go to `internalLog`, not to `stream.log` and
  `stream.error`.
- `endFile` carries the media, position and duration of the entry that
  ended, instead of leaving them to `state`, which has already moved on in
  a playlist. Its `readError` and `skippedSegments`, and the same fields of
  `PlayerState` at the park, tell an entry cut short by a read error.
- An app on the web serves its page cross-origin isolated (the Web topic,
  doc/web.md). Nothing changes on the other platforms.

# Migrating to 0.5.0

0.5.0 changes how audio effects are described and how libmpv reaches your
app. Most apps only need the first section.

## Audio effects are an ordered list

The `AudioEffects` bundle, one field per filter applied in a fixed order,
is gone. The effects chain is now a `List<AudioEffect>`, applied in list
order, where the same filter can appear more than once.

| 0.4 | 0.5 |
|---|---|
| `AudioEffects(...)` | `[...]`, a `List<AudioEffect>` |
| `EqualizerSettings`, `AcompressorSettings`, … | `EqualizerEffect`, `AcompressorEffect`, … |
| `level_in`, `balance_in`, `start_periods` | `levelIn`, `balanceIn`, `startPeriods` |
| `enabled: true` on every effect | `enabled` defaults to `true` |
| `AudioEffects(custom: ['lavfi-...'])` | `RawAudioEffect('lavfi-...')` anywhere in the list |
| `e.updateBass((b) => ...)` | map the list (see below) |
| `state.audioEffects.bass` | `state.audioEffects.whereType<BassEffect>()` |
| `AudioEffect.equalizer` (filter id) | `AudioFilter.equalizer` |
| `LoudnormSettings(I: -16, TP: -1, LRA: 11)` | `LoudnormEffect(i: -16, tp: -1, lra: 11)` |
| enum members like `lr_to_ms`, `LUFS` | `lrToMs`, `lufs` |
| both spellings of an option (`f` and `frequency`, `g` and `gain`) | the longer one only: `frequency`, `gain` |

ffmpeg names some options twice, and 0.4 had a field for each spelling.
0.5 keeps one field per option, the longer name: `BassEffect(g: 3)` is
`BassEffect(gain: 3)`, and likewise `w` and `width`, `t` and `widthType`
on the equalizer family, and the short aliases of `afade`, `afftdn`,
`dynaudnorm`, `speechnorm` and the others. The analyzer names each one.

Setting a chain:

```dart
// 0.4
await player.setAudioEffects(const AudioEffects(
  bass: BassSettings(enabled: true, g: 3),
  acompressor: AcompressorSettings(enabled: true, threshold: 0.1),
));

// 0.5: list order is chain order
await player.setAudioEffects(const [
  BassEffect(gain: 3),
  AcompressorEffect(threshold: 0.1),
]);
```

Changing one stage, for example from a slider:

```dart
// 0.4
await player.updateAudioEffects(
  (e) => e.updateBass((b) => b.copyWith(g: gain)),
);

// 0.5
await player.updateAudioEffects((fx) => [
  for (final e in fx) e is BassEffect ? e.copyWith(gain: gain) : e,
]);
```

When you keep several stages of one filter, address them by position:

```dart
await player.updateAudioEffects((fx) => [
  for (final (i, e) in fx.indexed)
    i == index ? (e as EqualizerEffect).copyWith(gain: gain) : e,
]);
```

A change that only touches runtime-tunable parameters and keeps the list's
shape still updates the running filter graph live. Adding, removing,
reordering or toggling a stage rebuilds the chain, as enabling or
disabling a slot did before.

Disabling keeps the stage and its settings, as before:

```dart
await player.updateAudioEffects((fx) => [
  for (final e in fx) e is BassEffect ? e.copyWith(enabled: false) : e,
]);
```

Clearing the chain: `setAudioEffects(const [])` instead of
`setAudioEffects(const AudioEffects())`.

A chain mpv refuses now throws `MpvCommandException` and leaves the state
on the last list mpv accepted, also when the refusal comes from building
the filter graph (a bad value in a `RawAudioEffect`), which 0.4 did not
report. An `updateAudioEffects` that is not awaited can therefore end in an
unhandled error. With no file loaded there is no graph yet, and such a
value surfaces at the next load on `stream.error`.

### Taps and the loudness meter

`stream.tap` takes the filter as an `AudioFilter` and, when the filter
appears more than once, which occurrence (0 for the first, disabled stages
included):

```dart
player.stream.tap(AudioFilter.equalizer, instance: 1, side: TapSide.post);
```

The live loudness meter reads the first enabled `Ebur128Effect` of the chain
with its `metadata` option on:

```dart
await player.updateAudioEffects(
  (fx) => [...fx, const Ebur128Effect(metadata: true)],
);
```

`AudioEffectsX.active` is gone: every stage has a `filter` (its
`AudioFilter`, `null` for a `RawAudioEffect`) and an `enabled` flag.
The `AfCommand` record is no longer public.

## One family of exceptions

A call that fails at libmpv or at its source now throws a sealed
`PlayerException`. Invalid arguments are programming errors and still
throw `ArgumentError` or `RangeError`, and enabling the media session on a
second player throws `StateError`.

| 0.4.x | 0.5.0 |
| --- | --- |
| `MpvException` | `MpvCommandException`, same `name`, `code` and `message` |
| `StateError` on a disposed player | `PlayerDisposedException` |
| `StateError` or `MpvLibraryException` when libmpv fails to start | `PlayerInitException` |
| `StateError` on an unreadable `content://` | `SourceException` |
| a missing `asset://` passed on to mpv | `SourceException` |

Other changes to handle:

- `next()`, `previous()`, `nextPlaylist()` and `previousPlaylist()` return
  `Future<bool>`: `false` when there is no track to go to.
- `jump()`, `remove()`, `move()` and `replace()` throw `RangeError` for an
  index out of range. `jump()` used to do nothing.
- `setVolume()` throws `RangeError` for a negative volume, `setRate()` and
  `setPitch()` outside `[0.01, 100]`. Invalid arguments are checked before
  the player finishes starting.
- `stop()`, `setShuffle()`, `reloadAudio()`, `rescanExternalFiles()` and
  `writeResumeConfig()` throw `MpvCommandException` when mpv rejects them,
  like the other methods.
- `sendRawCommand()` throws `ArgumentError` for a command that writes `af`
  or `pause`: `af` and `af-command`, `set`, `cycle`, `change-list` and the
  like, also after `no-osd` and through `options/`, and `loadfile` with
  `af` or `pause` in its options. An idiom such as
  `sendRawCommand(['cycle', 'pause'])` now throws: use `play()`, `pause()`
  and the effects API. `setRawProperty()` also rejects `options/af` and
  `file-local-options/pause`, not only `af` and `pause`.

## Renamed types and streams

The `Mpv` prefix now marks only types that carry mpv's own data
(`MpvError`, `MpvLogEntry`, `MpvHookEvent`, `MpvTrack`,
`MpvFileEndedEvent`, `MpvEndFileReason`, `MpvCommandException`).
`MpvPlaybackState` keeps it so it doesn't clash with audio_service's
`PlaybackState`.

| 0.4.x | 0.5.0 |
| --- | --- |
| `MpvPlayerError` | `PlayerError` |
| `MpvEndFileError`, `MpvEndFileErrorX` | `EndFileError`, `EndFileErrorX` |
| `MpvLogError` | `LogError` |
| `MpvPrefetchState` | `PrefetchState` |
| `player.stream.loudness` | `player.stream.loudnessScan` |

`player.stream.tap(...)` is now a method taking an `AudioFilter` and an
`instance`, see [Taps and the loudness meter](#taps-and-the-loudness-meter).

## Synchronous spectrum and log level

`setSpectrum`, `updateSpectrum` and `setLogLevel` return `void`: remove the
`await`. The spectrum settings moved from `player.spectrumSettings` to
`player.state.spectrum`, and still stream on `player.stream.spectrum`.

## State streams start from the current value

Every state stream of `player.stream` now gives a new subscriber the
current value first, then the changes. Event streams (`seekCompleted`,
`endFile`, `error`, `log`, `internalLog`, `hook`, `mediaSessionCommands`,
`fft`, `pcm`, `loudnessMeter`, taps) are unchanged.

- `initialData: player.state.x` in a `StreamBuilder` is no longer needed.
- `stream.x.first` returns the current value. To wait for the next change,
  use `stream.x.skip(1).first`. `firstWhere` with a condition works as
  before, but returns at once when the current value already matches.
- `playbackState` used to replay only to its first subscriber; now every
  subscriber gets it.

## libmpv comes from a build hook

The package now fetches libmpv through a Dart build hook instead of
Gradle, CocoaPods, SwiftPM and CMake. Nothing changes in a normal app, but:

- The minimum is Dart 3.10 and Flutter 3.38. Building for iOS needs
  Flutter 3.47.4 or later: older releases mark the bundled framework for
  an iOS version below the library's 15.0, and the hook stops the build.
- The first build of each target downloads libmpv, so it needs network
  access. There is no libmpv for 32-bit x86 Android emulators or 32-bit
  Linux, so building for them stops with an error.
- The bundled file is `libmpv_audio_kit.so`, `mpv_audio_kit.dll` or
  `libmpv_audio_kit.framework`, so it no longer collides with media_kit's
  `libmpv` or with the plugin's own framework. Scripts or build steps that
  looked for `libmpv.so` in your app need the new name.
- To build without network, save the release's libmpv and point the
  `libmpv` user define at it in your app's `pubspec.yaml`:

  ```yaml
  hooks:
    user_defines:
      mpv_audio_kit:
        libmpv: path/to/the/saved/libmpv
  ```

  A directory holds files named like the release assets, one per target.
  A single file is bundled for every target, so it only suits a build for
  one target and architecture: on Apple it is the binary of one slice,
  thinned to one architecture with `lipo -thin` when the slice is
  universal. `MpvAudioKit.ensureInitialized(libmpv: path)` still loads a
  library by path at run time. On Windows your build needs the patches of
  libmpv-scripts 0.1.7 or later: with an unpatched mpv, every `dispose()`
  crashes the process, and `previousPlaylist()` can crash it too.
- On Linux the package no longer falls back to a system `libmpv.so`.
- The player reports on `stream.internalLog` when the loaded libmpv is
  not the release the package expects.

## Behavior changes

- After `stop()` or a failed load, and while the next track loads, the
  state no longer keeps the previous file's values: `duration`, `path`,
  `mediaTitle`, `metadata`, `fileSize`, `audioParams` and the like go back
  to their defaults (0, empty, `null`) until mpv reports the new ones. A
  progress bar that divides by `duration` must handle 0. The OS media
  session is not affected: it holds its metadata while a track loads.
- `systemVolume` and `systemMute` are `null` while no audio output is open,
  for example after `stop()`.
