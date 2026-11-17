# mpv_audio_kit

#### Audio engine for Flutter and Dart.

[![](https://img.shields.io/pub/v/mpv_audio_kit.svg?style=for-the-badge&logo=dart&logoColor=white)](https://pub.dev/packages/mpv_audio_kit)
[![](https://img.shields.io/badge/libmpv-v0.41.0-orange.svg?style=for-the-badge)]()
[![](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg?style=for-the-badge)](LICENSE)
[![](https://img.shields.io/github/stars/ales-drnz/mpv_audio_kit?style=for-the-badge&logo=github&logoColor=white)](https://github.com/ales-drnz/mpv_audio_kit)
[![](https://img.shields.io/discord/1485588004029333516?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/g2Qf4Mq9MP)
[![](https://img.shields.io/badge/Patreon-F96854?style=for-the-badge&logo=patreon&logoColor=white)](https://www.patreon.com/cw/ales_drnz)
[![](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/ales.drnz)

<table>
<tr>
<td valign="middle" width="90"><img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/mpv_audio_kit.png" width="70" alt="logo"></td>
<td valign="middle"><code>mpv_audio_kit</code> is an audio library built on mpv <code>v0.41.0</code>. It provides a dedicated background event loop, a complete DSP pipeline, and direct access to every property, making it the most capable audio library available for Flutter.</td>
</tr>
</table>

---

## Why did I build this?

Many existing Flutter audio libraries are either built on an old version of mpv or they are simply too restrictive, hiding some cool features relative to audio processing. So I made this project to provide the most powerful and flexible audio library for Flutter and solve 4 main needs:

<table>
<tr>
<td valign="middle" width="48"><img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/jellyfin.png" width="32" alt="Jellyfin"></td>
<td valign="middle"><b>Jellyfin</b><br>for song streaming, supporting <code>.m3u8</code> (<a href="#21-supported-uri-schemes">HLS</a>) is essential when using transcoding. This is particulary handy because it enables seeking on the mpv player instead of blocking it when using <code>.stream</code>.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/plex.png" width="32" alt="Plex"></td>
<td valign="middle"><b>Plex</b><br>transcoding in this case requires a <code>/decision</code> call before each stream. Plex rejects multiple parallel requests when creating playlists, so instead of relying to a local proxy server, the <code>on_load</code> <a href="#12-hooks">hook method</a> resolves <code>.m3u8</code> or <code>.mpd</code> (<a href="#21-supported-uri-schemes">DASH</a>) URLs lazily.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/samba.png" width="32" alt="Samba"></td>
<td valign="middle"><b>Samba</b><br>for playing from network shares over <code>smb2://</code> (<a href="#21-supported-uri-schemes">SMB</a>), the engine speaks SMB2 and SMB3 natively, so a track on your home server (for example a NAS) streams like any local source.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/wrench.png" width="32" alt=""></td>
<td valign="middle"><b>Total control</b><br>this library doesn't limit features; it exposes the native engine so you can tune <a href="#7-network-and-caching">buffers and network timeouts</a>, <a href="#5-audio-quality-and-dsp">DSP filters</a> and play with ffmpeg exactly how you want.</td>
</tr>
</table>

---

## Installation

Add `mpv_audio_kit` to your `pubspec.yaml`:

```yaml
dependencies:
  mpv_audio_kit: ^0.4.9
```

## Platforms requirements

| Platform  | Minimum | Architecture | Size | Device | Emulator |
| :--- | :--- | :--- | :---: | :---: | :---:
| **Android** | 7.0 (SDK 24) | arm64-v8a, armeabi-v7a, x86_64 | 8.3, 8.2, 8.9 MB | ✅ | ✅ |
| **iOS** | 15.0 | arm64, x86_64 | 7.5, 8.0 MB | ✅ | ✅ |
| **macOS** | 12.0 | arm64, x86_64 | 7.5, 8.0 MB | ✅ | - |
| **Windows**| 10 | arm64, x86_64 | 8.1, 9.1 MB | ✅ | - |
| **Linux** | Ubuntu 24.04 | aarch64, x86_64 | 8.7, 7.5 MB | ✅ | - |

---

## Contents

*   [Visuals](#visuals)
*   [Features](#features)
*   [Quick start](#quick-start)
*   [Guide](#guide)
    <details>
    <summary><a href="#1-initialization-and-lifecycle"><b>1. Initialization and lifecycle</b></a></summary>

    * [1.1 Global initialization](#11-global-initialization)
    * [1.2 Creating a player](#12-creating-a-player)
    * [1.3 Disposing a player](#13-disposing-a-player)

    </details>

    <details>
    <summary><a href="#2-media-sources"><b>2. Media sources</b></a></summary>

    * [2.1 Supported URI schemes](#21-supported-uri-schemes)
    * [2.2 HTTP headers](#22-http-headers)
    * [2.3 Extras](#23-extras)
    * [2.4 Demuxer options](#24-demuxer-options)

    </details>

    <details>
    <summary><a href="#3-playlist-management"><b>3. Playlist management</b></a></summary>

    * [3.1 Opening a single track](#31-opening-a-single-track)
    * [3.2 Opening multiple tracks](#32-opening-multiple-tracks)
    * [3.3 Modifying the queue at runtime](#33-modifying-the-queue-at-runtime)
    * [3.4 Navigation](#34-navigation)
    * [3.5 Repeat and shuffle](#35-repeat-and-shuffle)
    * [3.6 Chapter navigation](#36-chapter-navigation)

    </details>

    <details>
    <summary><a href="#4-playback-control"><b>4. Playback control</b></a></summary>

    * [4.1 Basic controls](#41-basic-controls)
    * [4.2 Seeking](#42-seeking)
    * [4.3 A-B loop](#43-a-b-loop)
    * [4.4 Speed and pitch](#44-speed-and-pitch)
    * [4.5 Volume and mute](#45-volume-and-mute)
    * [4.6 Audio delay](#46-audio-delay)
    * [4.7 Resume playback (watch later)](#47-resume-playback-watch-later)

    </details>

    <details>
    <summary><a href="#5-audio-quality-and-dsp"><b>5. Audio quality and DSP</b></a></summary>

    * [5.1 The AudioEffects bundle](#51-the-audioeffects-bundle)
    * [5.2 Common effects: quick examples](#52-common-effects-quick-examples)
    * [5.3 Available effects](#53-available-effects)
    * [5.4 ReplayGain](#54-replaygain)
    * [5.5 Gapless playback](#55-gapless-playback)

    </details>

    <details>
    <summary><a href="#6-hardware-and-routing"><b>6. Hardware and routing</b></a></summary>

    * [6.1 Audio output driver](#61-audio-output-driver)
    * [6.2 Exclusive mode](#62-exclusive-mode)
    * [6.3 Device selection](#63-device-selection)
    * [6.4 Output format](#64-output-format)
    * [6.5 SPDIF passthrough](#65-spdif-passthrough)
    * [6.6 Audio client name](#66-audio-client-name)
    * [6.7 Audio track selection](#67-audio-track-selection)
    * [6.8 Reload audio](#68-reload-audio)
    * [6.9 Media role](#69-media-role)

    </details>

    <details>
    <summary><a href="#7-network-and-caching"><b>7. Network and caching</b></a></summary>

    * [7.1 Cache configuration](#71-cache-configuration)
    * [7.2 Demuxer memory pool](#72-demuxer-memory-pool)
    * [7.3 Network timeout](#73-network-timeout)
    * [7.4 TLS and SSL verification](#74-tls-and-ssl-verification)
    * [7.5 Audio buffer](#75-audio-buffer)
    * [7.6 Audio stream silence](#76-audio-stream-silence)
    * [7.7 Untimed null output](#77-untimed-null-output)
    * [7.8 Radio and live streams](#78-radio-and-live-streams)
    * [7.9 Throttling CDNs and chunked requests](#79-throttling-cdns-and-chunked-requests)
    * [7.10 Monitoring the demuxer cache](#710-monitoring-the-demuxer-cache)

    </details>

    <details>
    <summary><a href="#8-metadata-and-cover-art"><b>8. Metadata and cover art</b></a></summary>

    * [8.1 Metadata tags](#81-metadata-tags)
    * [8.2 Cover art](#82-cover-art)

    </details>

    <details>
    <summary><a href="#9-state-and-streams"><b>9. State and streams</b></a></summary>

    * [9.1 Core streams](#91-core-streams)
    * [9.2 Playlist and track streams](#92-playlist-and-track-streams)
    * [9.3 Audio hardware streams](#93-audio-hardware-streams)
    * [9.4 DSP and filter streams](#94-dsp-and-filter-streams)
    * [9.5 Network and cache streams](#95-network-and-cache-streams)
    * [9.6 File metadata and path streams](#96-file-metadata-and-path-streams)
    * [9.7 Playback timing streams](#97-playback-timing-streams)
    * [9.8 A-B loop streams](#98-a-b-loop-streams)
    * [9.9 Cover art streams](#99-cover-art-streams)
    * [9.10 Runtime diagnostics](#910-runtime-diagnostics)
    * [9.11 Prefetch lifecycle stream](#911-prefetch-lifecycle-stream)
    * [9.12 Aggregate lifecycle](#912-aggregate-lifecycle)
    * [9.13 Complete state snapshot](#913-complete-state-snapshot)
    * [9.14 Spectrum and PCM streams](#914-spectrum-and-pcm-streams)
    * [9.15 Media session streams](#915-media-session-streams)

    </details>

    <details>
    <summary><a href="#10-raw-api"><b>10. Raw API</b></a></summary>

    * [10.1 Read a property](#101-read-a-property)
    * [10.2 Write a property](#102-write-a-property)
    * [10.3 Send a command](#103-send-a-command)

    </details>

    <details>
    <summary><a href="#11-error-handling-and-logging"><b>11. Error handling and logging</b></a></summary>

    * [11.1 Typed error stream](#111-typed-error-stream)
    * [11.2 End file stream](#112-end-file-stream)
    * [11.3 Network state](#113-network-state)
    * [11.4 Audio output lifecycle](#114-audio-output-lifecycle)
    * [11.5 Log streams](#115-log-streams)

    </details>

    <details>
    <summary><a href="#12-hooks"><b>12. Hooks</b></a></summary>

    * [12.1 Registering a hook](#121-registering-a-hook)
    * [12.2 Listening and continuing](#122-listening-and-continuing)
    * [12.3 HTTP headers via hook](#123-http-headers-via-hook)
    * [12.4 Lazy URL resolution](#124-lazy-url-resolution)
    * [12.5 The source resolver](#125-the-source-resolver)

    </details>

    <details>
    <summary><a href="#13-visualizer-waveform-and-spectrum"><b>13. Visualizer, Waveform and Spectrum</b></a></summary>

    * [13.1 Subscribing to the spectrum stream](#131-subscribing-to-the-spectrum-stream)
    * [13.2 Configuring the pipeline](#132-configuring-the-pipeline)
    * [13.3 Raw PCM stream](#133-raw-pcm-stream)
    * [13.4 Per-filter PCM taps](#134-per-filter-pcm-taps)
    * [13.5 Waveform](#135-waveform)
    * [13.6 Loudness](#136-loudness)
    * [13.7 Live loudness meter](#137-live-loudness-meter)

    </details>

    <details>
    <summary><a href="#14-os-media-session"><b>14. OS media session</b></a></summary>

    * [14.1 Enabling the session](#141-enabling-the-session)
    * [14.2 Overriding metadata](#142-overriding-metadata)
    * [14.3 Reacting to OS commands](#143-reacting-to-os-commands)
    * [14.4 Capabilities, intervals and speeds](#144-capabilities-intervals-and-speeds)
    * [14.5 Audio interruptions](#145-audio-interruptions)
    * [14.6 App identity (desktop)](#146-app-identity-desktop)

    </details>
*   [Permissions](#permissions)
*   [Troubleshooting](#troubleshooting)
*   [Project background](#project-background)

---

## Visuals

<table>
<tr>
<td valign="middle" width="90"><img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/mpv_studio.png" width="70" alt="MPV Studio"></td>
<td valign="middle">The screenshots below are from <b><a href="https://github.com/ales-drnz/mpv_studio">MPV Studio</a></b>, the standalone showcase app built on <code>mpv_audio_kit</code>. The bundled <code>example/</code> is a deliberately minimal single-file demo.
</tr>
</table>

#### Playback

<p align="center">
  <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/playback.gif" width="100%">
</p>

#### Queue

<p align="center">
  <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/queue.gif" width="100%">
</p>

#### Stream

<p align="center">
  <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/stream.gif" width="100%">
</p>

#### Effects

<p align="center">
  <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/effects.gif" width="100%">
</p>

#### Settings

<p align="center">
  <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/settings.gif" width="100%">
</p>

#### Console

<p align="center">
  <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/console.gif" width="100%">
</p>

---

## Features

<table>
<tr>
<td valign="middle" width="48"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/zap.png" width="32"></td>
<td valign="middle" width="45%"><b>Non-blocking</b><br>mpv events run in a background isolate; the UI thread stays free.</td>
<td valign="middle" width="48"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/shield-check.png" width="32"></td>
<td valign="middle" width="45%"><b>Type-safe API</b><br>typed enums, sealed selectors, <code>*Settings</code> bundles. No stringly-typed setters.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/activity.png" width="32"></td>
<td valign="middle"><b>Reactive state</b><br>synchronous <a href="#913-complete-state-snapshot"><code>state</code></a> snapshot, <a href="#9-state-and-streams">90+ observable streams</a> covering every mpv property.</td>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/music.png" width="32"></td>
<td valign="middle"><b>Gapless playback</b><br>seamless track transitions with an observable <a href="#911-prefetch-lifecycle-stream">prefetch lifecycle</a>.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/sliders-horizontal.png" width="32"></td>
<td valign="middle"><b>DSP pipeline</b><br>one <a href="#5-audio-quality-and-dsp"><code>AudioEffects</code></a> bundle covering 18-band graphic EQ, compressor, loudness, pitch and tempo, bass and treble, stereo width, headphone crossfeed, silence trim, plus any custom <code>--af</code> filter.</td>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/audio-lines.png" width="32"></td>
<td valign="middle"><b>Visualizer</b><br>real-time <a href="#13-visualizer-waveform-and-spectrum">FFT spectrum + raw PCM streams</a> with log-spaced bands and asymmetric smoothing.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/scale.png" width="32"></td>
<td valign="middle"><b>ReplayGain</b><br>track and album normalization, preamp, fallback gain.</td>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/list-plus.png" width="32"></td>
<td valign="middle"><b>Dynamic playlist</b><br>add, remove, move, replace mid-playback; <a href="#36-chapter-navigation">chapters</a> and <a href="#43-a-b-loop">A-B loop</a>.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/layers.png" width="32"></td>
<td valign="middle"><b>Multi-track audio</b><br>typed <a href="#67-audio-track-selection">track selection</a> for multilingual containers (MKV, MP4) with codec, language, and gain metadata per track.</td>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/cpu.png" width="32"></td>
<td valign="middle"><b>Hardware control</b><br><a href="#62-exclusive-mode">exclusive mode</a>, <a href="#63-device-selection">device selection</a>, <a href="#64-output-format">bit-perfect sample-rate and format</a>, <a href="#65-spdif-passthrough">SPDIF passthrough</a>.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/tag.png" width="32"></td>
<td valign="middle"><b>Metadata and cover art</b><br><a href="#82-cover-art">embedded artwork</a> as raw bytes plus a Flutter <a href="#82-cover-art"><code>ImageProvider</code></a> helper, and <a href="#81-metadata-tags">tags</a>.</td>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/globe.png" width="32"></td>
<td valign="middle"><b>Network streams</b><br>HLS, DASH, SMB, HTTP and HTTPS.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/package.png" width="32"></td>
<td valign="middle"><b>Cache control</b><br><a href="#71-cache-configuration"><code>CacheSettings</code></a> bundle for memory cache, disk overflow, pause-on-empty.</td>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/webhook.png" width="32"></td>
<td valign="middle"><b>Hooks</b><br>intercept the file-loading pipeline (also during <a href="#12-hooks">prefetch</a>) to resolve URLs, redirect, or inject headers.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/triangle-alert.png" width="32"></td>
<td valign="middle"><b>Typed errors</b><br>sealed <a href="#111-typed-error-stream"><code>MpvPlayerError</code></a> hierarchy plus dedicated sinks for engine errors, end-file events, AO failures, and logs.</td>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/terminal.png" width="32"></td>
<td valign="middle"><b>Raw access</b><br>read or write any mpv property or command; failures surface as typed <a href="#10-raw-api"><code>MpvException</code></a>.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/media-session.png" width="32"></td>
<td valign="middle"><b>OS media session</b><br>publish the player to the <a href="#14-os-media-session">system media controls</a>. Now Playing, Control Center and lockscreen, MPRIS on Linux, SMTC on Windows, and the Android media notification.</td>
<td valign="middle"></td>
<td valign="middle"></td>
</tr>
</table>

---

## Quick start

```dart
import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MpvAudioKit.ensureInitialized();
  runApp(const MaterialApp(home: AudioPlayerScreen()));
}

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key});
  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late final Player player = Player();

  @override
  void initState() {
    super.initState();
    player.open(Media('https://example.com/audio.mp3'));
  }

  @override
  void dispose() {
    player.dispose(); // fire and forget is fine inside Flutter's synchronous dispose()
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: StreamBuilder<Duration>(
          stream: player.stream.position,
          builder: (context, snap) => Text('Position: ${snap.data}'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        // Bind the button to the intent axis (`playWhenReady`), not
        // `playing`. `playing` toggles transiently during seeks.
        onPressed: () =>
            player.state.playWhenReady ? player.pause() : player.play(),
        child: const Icon(Icons.play_arrow),
      ),
    );
  }
}
```

---

## Guide

### 1. Initialization and lifecycle

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/player_lifecycle.png" width="100%">

#### 1.1 Global initialization

Call `MpvAudioKit.ensureInitialized()` once at startup, before creating any `Player` instance. This registers the native backend and cleans up any handles that leaked across a Flutter Hot-Restart.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MpvAudioKit.ensureInitialized();
  runApp(const MyApp());
}
```

#### 1.2 Creating a player

```dart
final player = Player(
  configuration: const PlayerConfiguration(
    logLevel: LogLevel.info, // mpv log verbosity
    initialVolume: 100.0, // Volume at startup (0 to 100)
    autoPlay: true,       // Start playing automatically on open()
  ),
);
```

All `PlayerConfiguration` fields are optional. Their defaults:

<details>
<summary><b>9 configuration fields</b> (click to expand)</summary>

| Field | Default | Description |
| :--- | :--- | :--- |
| `autoPlay` | `false` | Whether `open()` starts playback immediately |
| `initialVolume` | `100.0` | Volume at startup |
| `logLevel` | `LogLevel.warn` | Threshold forwarded to `player.stream.log`. Typed enum: `LogLevel.off`, `.fatal`, `.error`, `.warn`, `.info`, `.v`, `.debug`, `.trace` |
| `resumePlayback` | `true` | Restore the saved position on reopen (watch-later). Only audio-relevant props are persisted, ideal for audiobook and podcast resume |
| `watchLaterDir` | `null` | Directory for the watch-later resume configs. Often not writable on mobile, point this at an app-writable path |
| `forceSeekable` | `false` | Allow in-cache seeking on streams mpv reports as non-seekable (direct-HTTP or HLS audio) |
| `hlsBitrate` | `HlsBitrate.max` | Which variant mpv selects from an adaptive HLS playlist (`HlsBitrate.no`, `.min`, or `.max`). Use `.min` to save bandwidth on metered links |
| `normalizeDownmix` | `false` | Loudness-normalize surround content downmixed to fewer channels, avoiding clipping on 5.1→stereo |
| `demuxerCacheDir` | `null` | Directory for the on-disk demuxer cache (companion of `CacheSettings.onDisk`). Point it at a writable path on mobile |

</details>

The audio client name is set after construction:

```dart
await player.setAudioClientName('MyMusicApp');
```

#### 1.3 Disposing a player

Always call `dispose()` to release native handles.

```dart
await player.dispose();
```

---

### 2. Media sources

A `Media` object wraps a URI with optional per-track metadata and HTTP configuration.

```dart
// HTTPS stream
final track = Media('https://cdn.example.com/audio.flac');

// Local file
final local = Media('file:///home/user/music/song.flac');

// Flutter asset
final asset = Media('asset:///assets/audio/sample.mp3');

// Android content URI (e.g. from file picker)
final content = Media('content://com.android.externalstorage.documents/...');
```

#### 2.1 Supported URI schemes

##### Local and app-bundled sources

|  | Scheme | Description |
| :---: | :--- | :--- |
| <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/file.png" width="32" style="vertical-align: middle" alt="File"> | `file://` | Local files with absolute path |
| <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/flutter.png" width="32" style="vertical-align: middle" alt="Flutter"> | `asset:///` | Flutter assets bundled in the app |
| <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/android.png" width="32" style="vertical-align: middle" alt="Android"> | `content://` | Android content provider URIs (file picker, media store) |

##### Streaming sources

|  | Scheme | Description |
| :---: | :--- | :--- |
| <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/https.png" width="32" style="vertical-align: middle" alt="HTTPS"> | `https://`, `http://` | Network streams, live radio, etc... |
| <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/jellyfin.png" width="32" style="vertical-align: middle" alt="Jellyfin"> | `https://…/*.m3u8` | HTTP Live Streaming (HLS) manifest, as used by Jellyfin transcoding |
| <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/plex.png" width="32" style="vertical-align: middle" alt="Plex"> | `https://…/*.mpd` | Dynamic Adaptive Streaming over HTTP (DASH) manifest, as used by Plex transcoding |
| <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/samba.png" width="32" style="vertical-align: middle" alt="Samba"> | `smb2://` | SMB2 and SMB3 network shares |

#### 2.2 HTTP headers

Headers are applied natively to the libmpv HTTP layer, without a local proxy:

```dart
final media = Media(
  'https://api.example.com/stream/episode-42.mp3',
  httpHeaders: {
    'Authorization': 'Bearer my_token',
    'User-Agent': 'MyApp/1.0',
    'X-Custom-Header': 'value',
  },
);
await player.open(media);
```

#### 2.3 Extras

Attach arbitrary data to a track. The player carries it through the
playlist so your UI can access it without a separate lookup.

```dart
final media = Media(
  'https://cdn.example.com/track.mp3',
  extras: {
    'title': 'Track Title',
    'artist': 'Artist Name',
    'album': 'Album Name',
    'duration': const Duration(minutes: 4, seconds: 12),
    'isPodcast': true,
  },
);
```

Access later via `player.state.playlist.items[index].extras`.

#### 2.4 Demuxer options

Pass per-track options straight to libmpv's libavformat demuxer with
`Media.demuxerLavfOptions` (applied as the file-local `demuxer-lavf-o`, scoped
to that entry). A common use is reaching the *segment* demuxer of an HLS or DASH
stream through the HLS demuxer's `seg_format_options` dictionary:

```dart
final media = Media(
  'https://server/Audio/123/main.m3u8?…',
  demuxerLavfOptions: {
    // forward an option to the HLS segment demuxer
    'seg_format_options': 'advanced_editlist=0',
  },
);
```

Values must not contain a comma; keys must be non-empty.

---

### 3. Playlist management

#### 3.1 Opening a single track

```dart
// Respects PlayerConfiguration.autoPlay
await player.open(media);

// Override auto-play for this call
await player.open(media, play: true);
await player.open(media, play: false); // Load but do not start
```

#### 3.2 Opening multiple tracks

```dart
await player.openAll([track1, track2, track3]);

// Start at a specific index
await player.openAll([track1, track2, track3], index: 1);

// Override auto-play
await player.openAll([track1, track2], play: false);

// Load a playlist FILE or URL (.m3u, .m3u8, .pls, .cue), its entries
// are expanded into player.stream.playlist (internet-radio station lists,
// remote playlists). open() loads a single entry; openPlaylistFile parses it.
await player.openPlaylistFile(Media('https://example.com/stations.m3u'));
```

> Per-track HTTP headers from `Media.httpHeaders` are applied
> automatically to every entry, both the first and the queued ones.
> The wrapper passes them to mpv as file-local `loadfile` options
> (`http-header-fields`), so they ride along with that exact playlist
> entry and never touch the global option. You only need a
> [§12.5](#125-the-source-resolver) resolver or your own
> [§12](#12-hooks) hook for URL resolution, custom auth flows, etc.

#### 3.3 Modifying the queue at runtime

```dart
await player.add(newTrack);          // Append to end
await player.remove(0);              // Remove track at index 0
await player.move(5, 0);             // Move track from index 5 to index 0
await player.replace(2, newTrack);   // Replace track at index 2

await player.clearPlaylist();        // Remove all tracks (stops playback)
```

#### 3.4 Navigation

```dart
await player.next();              // Skip to the next track
await player.previous();          // Skip to the previous track
await player.jump(2);             // Jump to track at index 2 (0-indexed)

await player.next(force: true);   // Past the last entry: stop playback
await player.nextPlaylist();      // Jump to the next source playlist
await player.previousPlaylist();  // …and back across concatenated playlists
```

For internet-radio station lists and remote `.m3u` and `.pls` playlists, load
the playlist file itself with `openPlaylistFile` (see [§3.2](#32-opening-multiple-tracks));
unlike `open`, it expands the entries into `player.stream.playlist`.

#### 3.5 Repeat and shuffle

```dart
// Repeat modes
await player.setLoop(Loop.off);       // No repeat (default)
await player.setLoop(Loop.file);      // Loop the current track
await player.setLoop(Loop.playlist);  // Loop the entire playlist

// Shuffle
await player.setShuffle(true);   // Shuffle the queue
await player.setShuffle(false);  // Restore original order
```

`Loop` aggregates mpv's two underlying loop properties (`loop-file`
and `loop-playlist`) into a single mutually-exclusive choice. Subscribe
via `player.stream.loop` for live updates.

#### 3.6 Chapter navigation

For audiobooks, podcasts, and any container that ships chapter markers:

```dart
// Subscribe to the chapter list (populated after each load)
player.stream.chapters.listen((chapters) {
  for (var i = 0; i < chapters.length; i++) {
    print('${i}. ${chapters[i].title} @ ${chapters[i].time}');
  }
});

// Active chapter index (0-based; null when no chapter is active)
player.stream.currentChapter.listen((idx) => print('chapter: $idx'));

// Per-chapter metadata (mpv `chapter-metadata`)
player.stream.chapterMetadata.listen((tags) => print(tags));

// Jump to a chapter by index
await player.setChapter(2);
```

`Chapter` exposes `time` and an optional `title`. Use `state.demuxerStartTime` if you need the source-side.

---

### 4. Playback control

#### 4.1 Basic controls

```dart
await player.play();    // Start or resume
await player.pause();   // Pause
await player.stop();    // Stop and unload current file

// Toggle pattern: bind to `playWhenReady` (the intent axis), not
// `playing`, so the button stays stable while seeking or buffering.
player.state.playWhenReady ? await player.pause() : await player.play();
```

#### 4.2 Seeking

```dart
// Seek to an absolute position
await player.seek(const Duration(seconds: 30));

// Seek forward or backward relative to current position
await player.seek(const Duration(seconds: 10), relative: true);
await player.seek(const Duration(seconds: -5), relative: true);

// Sample-accurate (vs keyframe) seeking
await player.seek(const Duration(seconds: 30), exact: true);

// Percentage-based seeking (for progress-bar scrubbing)
await player.seekToPercent(50); // jump to the half-way point (0 to 100)

// Undo the last seek
await player.revertSeek();
```

mpv uses the `absolute` seek mode by default, which works correctly on
all formats including HLS, providing precise seeking even during
transcoded streams.

#### 4.3 A-B loop

Define a sub-region of the current track and loop between two
timestamps. Useful for language-learning apps, transcript review, or
practising a passage on repeat.

```dart
// Set the A and B markers (null disables the marker)
await player.setAbLoopA(const Duration(seconds: 30));
await player.setAbLoopB(const Duration(seconds: 45));

// Limit the number of repetitions; null = infinite
await player.setAbLoopCount(3);

// Read remaining iterations (null = no loop or infinite)
player.stream.remainingAbLoops.listen((n) => print('left: $n'));

// Disable
await player.setAbLoopA(null);
await player.setAbLoopB(null);
```

#### 4.4 Speed and pitch

```dart
await player.setRate(1.5);              // 1.5× speed (0.01 to 100.0)
await player.setPitch(0.9);             // Lower pitch without affecting speed
await player.setPitchCorrection(true);  // Pitch correction when changing rate
```

`setPitchCorrection` enables mpv's `scaletempo` algorithm, which
adjusts playback speed while preserving the original pitch.

For high-quality time-stretching that decouples pitch and tempo, use
the [`rubberband`](#52-common-effects-quick-examples) effect on the
DSP bundle.

#### 4.5 Volume and mute

There are two independent volume layers: the **soft** volume (mpv's own
software gain) and the **system** volume (the OS per-app mixer).

```dart
// Soft volume and mute (mpv's software gain, always available)
await player.setVolume(80.0);     // 0 to 100 (values above 100 amplify)
await player.setMute(true);
await player.setMute(false);

await player.setVolumeMax(150.0); // Raise the software volume ceiling
await player.setVolumeGain(6.0);  // Decoder-side pre-amp, in dB

// Clamp the dB range setVolumeGain accepts (defaults -96 and +12)
await player.setVolumeGainMin(-60.0);
await player.setVolumeGainMax(6.0);
```

The **system** volume and mute drive the OS per-app mixer (mpv's `ao-volume` and
`ao-mute`), distinct from the soft volume. They are best-effort: silently
ignored (no throw) when the active audio backend doesn't expose system
volume, in which case `state.systemVolume` and `state.systemMute` stay `null`.

```dart
if (player.state.systemVolume != null) {        // backend supports it
  await player.setSystemVolume(70.0);
  await player.setSystemMute(false);
}
```

#### 4.6 Audio delay

```dart
// Shift audio forward by 50 ms (useful for Bluetooth A2DP sync)
await player.setAudioDelay(const Duration(milliseconds: 50));

// Shift backward by 200 ms
await player.setAudioDelay(const Duration(milliseconds: -200));
```

#### 4.7 Resume playback (watch later)

For audiobooks and podcasts, the player can save a resume point for the
current file and restore it the next time that file is opened. Only
audio-relevant properties are persisted (position, speed, pitch, volume,
mute, audio delay, the effect chain, and the selected track).

Restore-on-reopen is controlled at build time by
`PlayerConfiguration.resumePlayback` (default `true`). Point
`watchLaterDir` at an app-writable directory on mobile; the platform
default is often not writable.

```dart
final player = Player(
  configuration: const PlayerConfiguration(
    resumePlayback: true,                 // restore on reopen (default)
    watchLaterDir: '/path/to/app/support/watch_later',
  ),
);

// Save a resume point for the current file (e.g. on background or pause)
await player.writeResumeConfig();

// Clear it: for the current file, or a specific one by filename
await player.deleteResumeConfig();
await player.deleteResumeConfig(filename: '/music/audiobook.m4b');
```

---

### 5. Audio quality and DSP

All processing in this section runs through ffmpeg filter pipeline and
works on every platform.

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/dsp_chain.png" width="100%">

#### 5.1 The AudioEffects bundle

The DSP rack lives on a single immutable [`AudioEffects`] value. Every
audio effect has its own typed `*Settings` field on the bundle, and
the whole rack is applied in one call via two setters on `Player`:

```dart
// Replace the whole bundle (presets, factory defaults, JSON restore):
Future<void> setAudioEffects(AudioEffects effects);

// Mutate one or more fields with a copyWith mapper:
Future<void> updateAudioEffects(AudioEffects Function(AudioEffects) f);
```

Each effect carries an `enabled` flag (default off). When on, it joins
the audio chain; when off, it leaves the chain but keeps its parameters
intact for the next toggle.

```dart
// Read the live bundle synchronously
final fx = player.state.audioEffects;
print('compressor on: ${fx.acompressor.enabled} '
      'threshold=${fx.acompressor.threshold}');

// Or via stream: sub-stream a single effect with .map().distinct()
player.stream.audioEffects
  .map((e) => e.acompressor)
  .distinct()
  .listen((c) => print('compressor: $c'));
```

Apply a multi-effect preset in one shot:

```dart
await player.setAudioEffects(const AudioEffects(
  acompressor: AcompressorSettings(
    enabled: true, threshold: 0.1, ratio: 4,        // linear ratio threshold
  ),
  loudnorm: LoudnormSettings(enabled: true, I: -16),
  bass: BassSettings(enabled: true, g: 3),          // bass shelf, +3 dB
  treble: TrebleSettings(enabled: true, g: -2),     // treble shelf, -2 dB
  rubberband: RubberbandSettings(
    enabled: true, pitch: 1.0, tempo: 0.95,         // -5% tempo, no pitch shift
  ),
));
```

Toggle a single stage with the per-effect updater — a never-configured
slot is seeded with its defaults first. Every effect slot is nullable
(`null` = never configured, identical on the wire to a disabled
instance), so effects your app never touches are tree-shaken out of
the binary:

```dart
await player.updateAudioEffects(
  (e) => e.updateAcompressor((c) => c.copyWith(enabled: !c.enabled)),
);
```

Reset everything:

```dart
await player.setAudioEffects(const AudioEffects());
```

> Mixing `setAudioEffects` with raw `setRawProperty('af', ...)` writes
> is not supported. The typed bundle owns the chain, and raw writes
> are rejected. Filters without a typed equivalent go through
> `effects.custom` (a `List<String>` of raw entries emitted at the head
> of the chain, before any typed stage).
>
> ```dart
> // mix typed effects with a raw filter you want to inject
> await player.updateAudioEffects((e) => e.copyWith(
>   custom: ['lavfi-aeval=val(0)|val(1)'],
>   acompressor: const AcompressorSettings(enabled: true, threshold: 0.1),
> ));
> ```

#### 5.2 Common effects: quick examples

Below are some audio effects with representative settings. Every
other effect works the same way: a typed
field on the bundle, configured via `copyWith`.

```dart
// Dynamic-range compressor
await player.updateAudioEffects((e) => e.copyWith(
  acompressor: const AcompressorSettings(
    enabled: true,
    threshold: 0.1,    // 0..1 linear scale
    ratio: 4.0,
    attack: 20.0,      // ms
    release: 250.0,    // ms
  ),
));

// EBU R128 loudness normalisation
await player.updateAudioEffects((e) => e.copyWith(
  loudnorm: const LoudnormSettings(
    enabled: true, I: -16, TP: -1.5, LRA: 11,
  ),
));

// Pitch and tempo shifting (librubberband). Enums for quality presets.
await player.updateAudioEffects((e) => e.copyWith(
  rubberband: const RubberbandSettings(
    enabled: true, pitch: 1.0594, tempo: 1.0,
    pitchq: RubberbandPitch.quality,
  ),
));

// 18-band ISO graphic EQ. Bands keyed by their original `1b`..`18b` names.
await player.updateAudioEffects((e) => e.copyWith(
  superequalizer: const SuperequalizerSettings(
    enabled: true,
    params: {'4b': 1.5, '5b': 2.0, '8b': 0.5, '13b': 1.0},
  ),
));

// Bass + treble shelves (two independent shelving effects).
await player.updateAudioEffects((e) => e.copyWith(
  bass: const BassSettings(enabled: true, g: 4, f: 100),
  treble: const TrebleSettings(enabled: true, g: -2, f: 3000),
));
```

Effects with multiple-choice parameters, rubberband's pitch quality,
aemphasis curve, equalizer filter type, expose them as Dart enums for
IDE autocomplete and compile-time safety.

#### 5.3 Available effects

The bundle ships with 87 audio effects covering compression, EQ,
denoising, spatialisation, modulation, and more. Each row below maps to a
`<Name>Settings` field on `AudioEffects` (e.g. `acompressor` →
`AudioEffects.acompressor` of type `AcompressorSettings`). For raw
`lavfi-*` filters outside this typed set, or for quick experimentation,
use `AudioEffects.custom: List<String>` to push entries through the head
of the chain.

<details>
<summary><b>Browse the full catalogue</b> (click to expand)</summary>

##### Dynamics and loudness

| Effect | Description |
|---|---|
| `acompressor` | Dynamic-range compressor |
| `acontrast` | Simple dynamic-range compression |
| `adrc` | Spectral dynamic-range controller |
| `adynamicequalizer` | Signal-driven dynamic equalization |
| `adynamicsmooth` | Dynamic smoothing of audio levels |
| `agate` | Noise gate; silences signal below a threshold |
| `alimiter` | Brick-wall limiter; caps the output level |
| `apsyclip` | Psychoacoustic clipper |
| `asoftclip` | Smooth soft-knee clipping |
| `compand` | Compander (compress on input, expand on output) |
| `deesser` | De-essing for sibilance reduction |
| `drmeter` | Dynamic-range meter |
| `dynaudnorm` | Adaptive loudness normalization |
| `ebur128` | EBU R128 loudness scanner |
| `loudnorm` | EBU R128 loudness normalisation |
| `mcompand` | Multiband compander |
| `speechnorm` | Adaptive speech-loudness normaliser |

##### Equalization and tone

| Effect | Description |
|---|---|
| `anequalizer` | High-order parametric multiband equalizer |
| `asubboost` | Subwoofer-frequency boost |
| `atilt` | Spectral tilt across the frequency range |
| `bass` | Low-shelf filter (boost, cut bass) |
| `biquad` | Generic biquad IIR filter |
| `equalizer` | Two-pole peaking EQ band |
| `firequalizer` | FIR equalizer with arbitrary frequency response |
| `highshelf` | High-shelf filter |
| `lowshelf` | Low-shelf filter |
| `superequalizer` | 18-band ISO graphic EQ |
| `tiltshelf` | Tilt shelf (combined low plus high shelf) |
| `treble` | High-shelf filter (boost, cut treble) |

##### Filters

| Effect | Description |
|---|---|
| `allpass` | Two-pole all-pass filter |
| `asubcut` | Subwoofer-frequency cut |
| `asupercut` | High-frequency Butterworth cut |
| `asuperpass` | High-order Butterworth band-pass |
| `asuperstop` | High-order Butterworth band-stop |
| `bandpass` | Two-pole Butterworth band-pass |
| `bandreject` | Two-pole Butterworth band-reject |
| `highpass` | High-pass at a given frequency |
| `lowpass` | Low-pass at a given frequency |

##### Pitch, tempo and time

| Effect | Description |
|---|---|
| `afreqshift` | Shift the spectrum by a fixed offset |
| `aphaseshift` | Shift the phase of every spectral bin |
| `aresample` | Resample to a target sample rate and format |
| `atempo` | Adjust tempo without changing pitch |
| `asetrate` | Retag the sample rate → pitch + speed (vinyl/tape varispeed) |
| `rubberband` | High-quality independent pitch and tempo |

##### Stereo, channels and spatial

| Effect | Description |
|---|---|
| `crossfeed` | Headphone crossfeed |
| `dialoguenhance` | Centre-channel dialogue enhancement |
| `earwax` | Headphone listening enhancement |
| `extrastereo` | Increase the left-right difference signal |
| `haas` | Haas effect (precedence-based stereo widening) |
| `stereotools` | Comprehensive stereo image manipulation |
| `stereowiden` | Stereo widening by reducing common signal |
| `surround` | Stereo-to-surround upmix |
| `virtualbass` | Psychoacoustic bass enhancement |

##### Modulation and creative

| Effect | Description |
|---|---|
| `acrusher` | Bit-crusher (resolution and rate reduction) |
| `aecho` | Single-tap echo and multi-tap delay |
| `aemphasis` | RIAA, FM, disc emphasis curves |
| `aexciter` | Harmonic exciter |
| `aphaser` | Phaser |
| `apulsator` | Auto-panner, tremolo hybrid |
| `crystalizer` | Audio sharpening and brightener |
| `dcshift` | DC offset shift |
| `flanger` | Flanger |
| `hdcd` | HDCD decoder |
| `tremolo` | Sinusoidal amplitude modulation |
| `vibrato` | Sinusoidal pitch modulation |

##### Denoise and restoration

| Effect | Description |
|---|---|
| `adeclick` | Click and impulse-noise removal |
| `adeclip` | Clip-restoration |
| `adecorrelate` | Channel decorrelation |
| `adelay` | Per-channel delay |
| `adenorm` | Add low-level dither to fix denormals |
| `aderivative` | Compute the derivative of the signal |
| `aintegral` | Compute the integral of the signal |
| `afftdn` | FFT-based broadband noise reduction |
| `afwtdn` | Wavelet-based broadband noise reduction |
| `anlmdn` | Non-local-means denoiser |
| `compensationdelay` | Speaker and microphone delay compensation |

##### Spectral, fade and routing

**Spectral**

| Effect | Description |
|---|---|
| `afftfilt` | Apply expressions in the frequency domain |
| `aiir` | Apply an arbitrary IIR filter |

**Fade, silence and padding**

| Effect | Description |
|---|---|
| `afade` | Fade in and out |
| `apad` | Pad with trailing silence |
| `silenceremove` | Trim leading, trailing, inline silence |

**Routing**

| Effect | Description |
|---|---|
| `aformat` | Constrain output format |

##### Advanced (mandatory parameter)

These five take a mandatory free-form value with no sensible default, so their `*Settings` constructors make it **required** — pass a valid value or the filter won't initialise. (In the MPV Studio example each has a dedicated page with curated presets, a custom field, and a model-file picker for `arnndn`.)

| Effect | Description | Required |
|---|---|---|
| `chorus` | Chorus | `delays`, `decays`, `speeds`, `depths` |
| `pan` | Mix channels with explicit per-channel gains | `args` |
| `channelmap` | Remap input channels to new positions | `map` |
| `aeval` | Per-channel expression-based filter | `exprs` |
| `arnndn` | RNN-based speech denoiser | `model` (a `.rnnn` file) |

</details>

#### 5.4 ReplayGain

```dart
await player.setReplayGain(const ReplayGainSettings(
  mode: ReplayGain.track,     // .no, .track, .album
  preamp: 2.0,                // +2 dB on top of the RG value
  fallback: -6.0,             // -6 dB on files without RG tags
  clip: false,                // false = peak-limit; true = allow clipping
));

// Tweak a single field via copyWith
await player.setReplayGain(
  player.state.replayGain.copyWith(mode: ReplayGain.album),
);
```

#### 5.5 Gapless playback

```dart
await player.setGapless(Gapless.yes);   // Full gapless. Re-uses the decoder
await player.setGapless(Gapless.weak);  // Gapless only on compatible formats (default)
await player.setGapless(Gapless.no);    // Close and re-open the AO between tracks
```

For seamless transitions between tracks of any format, combine
`Gapless.yes` with `setPrefetchPlaylist(true)` and observe the
[prefetch lifecycle](#911-prefetch-lifecycle-stream).

```dart
// Pre-open the next playlist entry in the background. First audio
// frame ready before the current track ends.
await player.setPrefetchPlaylist(true);
```
---

### 6. Hardware and routing

#### 6.1 Audio output driver

Select the native backend used for audio output:

```dart
await player.setAudioDriver('wasapi');    // Windows
await player.setAudioDriver('coreaudio'); // macOS
await player.setAudioDriver('pulse');     // Linux
await player.setAudioDriver('alsa');      // Linux
await player.setAudioDriver('pipewire');  // Linux
await player.setAudioDriver('auto');      // Auto
```

#### 6.2 Exclusive mode

Bypasses the OS audio mixer and writes directly to the hardware. Eliminates software resampling and volume processing for bit-perfect output. Only available on WASAPI (Windows), ALSA (Linux) and CoreAudio (macOS):

```dart
await player.setAudioExclusive(true);   // Request exclusive access
await player.setAudioExclusive(false);  // Release, return to shared mode
```

> Exclusive mode locks the audio device. Always call `player.dispose()` when done, or other apps will have no sound.

#### 6.3 Device selection

```dart
// Listen to available devices
player.stream.audioDevices.listen((devices) {
  for (final d in devices) {
    print('${d.name}: ${d.description}');
  }
});

// Switch to a specific device
final devices = player.state.audioDevices;
await player.setAudioDevice(devices.first);
```

Devices are populated automatically by mpv when the player initializes. The `name` field is the mpv device identifier; `description` is the human-readable label.

#### 6.4 Output format

Force a specific output format for bit-perfect playback or DAC compatibility:

```dart
// Sample rate
await player.setAudioSampleRate(0);       // Auto
await player.setAudioSampleRate(44100);   // 44.1 kHz (CD)
await player.setAudioSampleRate(48000);   // 48 kHz (DVD, broadcast)
await player.setAudioSampleRate(88200);   // 88.2 kHz (hi-res)
await player.setAudioSampleRate(96000);   // 96 kHz (hi-res)
await player.setAudioSampleRate(192000);  // 192 kHz (studio)
await player.setAudioSampleRate(384000);  // 384 kHz (DXD)

// Bit depth format
await player.setAudioFormat(Format.auto);          // mpv picks (default)
await player.setAudioFormat(Format.u8);            // 8-bit unsigned, interleaved
await player.setAudioFormat(Format.u8Planar);      // 8-bit unsigned, planar
await player.setAudioFormat(Format.s16);           // 16-bit signed, interleaved
await player.setAudioFormat(Format.s16Planar);     // 16-bit signed, planar
await player.setAudioFormat(Format.s32);           // 32-bit signed, interleaved
await player.setAudioFormat(Format.s32Planar);     // 32-bit signed, planar
await player.setAudioFormat(Format.s64);           // 64-bit signed, interleaved
await player.setAudioFormat(Format.s64Planar);     // 64-bit signed, planar
await player.setAudioFormat(Format.float32);       // 32-bit float, interleaved
await player.setAudioFormat(Format.float32Planar); // 32-bit float, planar
await player.setAudioFormat(Format.float64);       // 64-bit float, interleaved
await player.setAudioFormat(Format.float64Planar); // 64-bit float, planar

// Channel layout 
await player.setAudioChannels(Channels.auto);             // mpv picks
await player.setAudioChannels(Channels.autoSafe);         // mpv picks, reject multichannel unless verified

// 1 channel
await player.setAudioChannels(Channels.mono);             // mono
await player.setAudioChannels(Channels.oneZero);          // 1.0 (alias of mono)

// 2 channels
await player.setAudioChannels(Channels.stereo);           // stereo
await player.setAudioChannels(Channels.twoZero);          // 2.0 (alias of stereo)
await player.setAudioChannels(Channels.downmix);          // downmix (semantic alias of stereo)

// ...                                                    // ...

// 8 channels
await player.setAudioChannels(Channels.sevenOne);         // 7.1 canonical
await player.setAudioChannels(Channels.sevenOneAlsa);     // 7.1(alsa)
await player.setAudioChannels(Channels.sevenOneWide);     // 7.1(wide)
await player.setAudioChannels(Channels.sevenOneWideSide); // 7.1(wide-side)
await player.setAudioChannels(Channels.sevenOneTop);      // 7.1(top)
await player.setAudioChannels(Channels.sevenOneRear);     // 7.1(rear)
await player.setAudioChannels(Channels.octagonal);        // octagonal
await player.setAudioChannels(Channels.cube);             // cube

// Cinema, immersive
await player.setAudioChannels(Channels.hexadecagonal);    // hexadecagonal (16ch)
await player.setAudioChannels(Channels.surround222);      // 22.2 (NHK, ITU-R BS.775)

// Custom escape, anything mpv recognises but isn't in the named set
await player.setAudioChannels(
  const Channels.custom('fl-fr-fc-bl-br-sl-sr-lfe'),
);
```

> When you force a downmix (e.g. 5.1 → stereo), set
> `PlayerConfiguration.normalizeDownmix: true` to loudness-normalize the
> result and avoid clipping. It is a build-time option (default `false`).

#### 6.5 SPDIF passthrough

Send compressed audio (AC3, DTS, TrueHD, …) directly to an AV receiver
over SPDIF or HDMI:

```dart
// Home-theater Dolby + DTS-HD passthrough
await player.setAudioSpdif({Spdif.ac3, Spdif.eac3, Spdif.trueHd, Spdif.dtsHd});

// Dolby only
await player.setAudioSpdif({Spdif.ac3, Spdif.eac3, Spdif.trueHd});

// Disable passthrough
await player.setAudioSpdif({});
```

#### 6.6 Audio client name

The name shown in system audio mixers:

```dart
await player.setAudioClientName('MyMusicApp');
```

#### 6.7 Audio track selection

For containers with multiple audio tracks (e.g. MKV, MP4 with language
variants), the library exposes both the inventory of tracks the
demuxer surfaced and the active track:

```dart
// Walk the audio inventory:
for (final t in player.state.tracks.where((tr) => tr.type == 'audio')) {
  print('${t.id}: ${t.title ?? t.lang ?? "audio"} '
        '(${t.codec} ${t.sampleRate} Hz ${t.channelCount}ch)');
}

// Currently selected track
player.stream.currentAudioTrack.listen((track) {
  if (track == null) return;
  print('Now decoding track #${track.id}: ${track.title}');
});

// Switch by id
await player.setAudioTrack(const Track.id(2));

// Defer to mpv's automatic choice (container default or first audio)
await player.setAudioTrack(Track.auto);

// Disable audio output entirely (e.g. show only metadata + cover art)
await player.setAudioTrack(Track.off);

// Load an external audio file as an extra selectable track on the current
// file (a separate-language dub, a commentary track), then remove it.
await player.addAudioTrack(Media('commentary.mka'), title: 'Commentary');
await player.removeAudioTrack(const Track.id(3));

// Re-scan sidecar external files (auto-loaded audio and cover art) without
// reopening the current file.
await player.rescanExternalFiles();
```

`MpvTrack` ships rich per-track introspection: codec, decoder, sample
rate, channel count, ReplayGain tags, language, default and forced
flags, `image` and `albumArt` flags so you can skip embedded picture
streams when populating a track-switcher UI, plus `external` and
`externalFilename` (whether the track was loaded from a separate file,
and its path) and `codecProfile` (the codec profile string when the
container reports one).

#### 6.8 Reload audio

Force the audio output to reinitialize:

```dart
await player.reloadAudio();
```

#### 6.9 Media role

On Linux, tag the stream's media role as "music" so the audio server
(PulseAudio and PipeWire) applies the right routing and per-role volume
profile. On Android the audtrack and aaudio backends honour it too; it is a
no-op elsewhere.

```dart
await player.setAudioMediaRole(true);
// Observe via player.stream.audioMediaRole and player.state.audioMediaRole
```

---

### 7. Network and caching

#### 7.1 Cache configuration

The six mpv cache properties (`cache`, `cache-secs`,
`cache-on-disk`, `cache-pause`, `cache-pause-wait`, `cache-pause-initial`)
are all set in one call through `setCache(CacheSettings)`:

```dart
await player.setCache(const CacheSettings(
  mode: Cache.yes,                 // .auto (default), .yes, .no
  secs: Duration(seconds: 30),         // target cache duration ahead of the playhead
  onDisk: true,                        // spill overflow cache to disk
  pause: true,                         // auto-pause when cache runs dry
  pauseWait: Duration(seconds: 3),     // pre-buffer required before resume
  pauseInitial: true,                  // buffer before playback starts (and after seek)
));

// Tweak a single field via copyWith
await player.setCache(
  player.state.cache.copyWith(secs: const Duration(seconds: 60)),
);

// Subscribe to live changes
player.stream.cache.listen((cfg) => print('cache: ${cfg.mode} ${cfg.secs}'));
```

`pauseInitial` buffers before playback starts, and again after each seek,
until the cache fills, for a smoother start on network sources (web-radio,
HLS, Plex). When `onDisk` is set, point the on-disk cache at a writable
directory with the build-time `PlayerConfiguration.demuxerCacheDir` (it
defaults to mpv's location, which is often not writable on mobile).

#### 7.2 Demuxer memory pool

The demuxer is the component that reads and parses the media container (MP4, MKV, OGG, etc.) before the audio decoder processes it. Its three buffering properties (`demuxer-max-bytes`, `demuxer-max-back-bytes`, `demuxer-readahead-secs`) are all set in one call through `setDemuxer(DemuxerSettings)`:

```dart
await player.setDemuxer(const DemuxerSettings(
  maxBytes: 50 * 1024 * 1024,          // forward cache cap (default: 150 MiB)
  maxBackBytes: 20 * 1024 * 1024,      // seekback buffer cap (default: 50 MiB)
  readahead: Duration(seconds: 5),     // how far ahead to read (default: 1s)
));

// Tweak a single field via copyWith
await player.setDemuxer(
  player.state.demuxer.copyWith(maxBytes: 100 * 1024 * 1024),
);

// Subscribe to live changes
player.stream.demuxer.listen((d) => print('demuxer: ${d.maxBytes} bytes'));
```

For radio streams or live content where seeking is not needed, reduce the back buffer to zero to save memory:

```dart
await player.setDemuxer(player.state.demuxer.copyWith(maxBackBytes: 0));
```

#### 7.3 Network timeout

```dart
await player.setNetworkTimeout(const Duration(seconds: 10)); // Fail after 10 seconds of no data
```

#### 7.4 TLS and SSL verification

```dart
await player.setTlsVerify(true); // Enable; uses the CA roots baked into libmpv

// Override the built-in roots with a custom bundle (e.g. a corporate CA):
await player.setTlsCaFile('/path/to/corporate-ca.pem');
```

#### 7.5 Audio buffer

The hardware audio buffer. Lower values reduce latency, higher values improve stability under load:

```dart
await player.setAudioBuffer(const Duration(milliseconds: 100));  // 100 ms (low latency)
await player.setAudioBuffer(const Duration(milliseconds: 500));  // 500 ms (stable on slow hardware)
```

#### 7.6 Audio stream silence

Keep audio hardware active even when playback is paused, to eliminate click or pop on resume:

```dart
await player.setAudioStreamSilence(true);
```

> Note on iOS: the audio driver in this case is never released, so after an iOS interruption (phone call, other app audio) it stays suspended and playback can't continue.

#### 7.7 Untimed null output

When using the `null` audio driver (e.g. for server-side processing or testing without a sound device), this makes the null output run as fast as possible instead of at real time:

```dart
await player.setAudioNullUntimed(true);
```

#### 7.8 Radio and live streams

For radio, disable caching and cache-pause to minimize latency:

```dart
await player.open(Media('https://stream.radio.example.com/live.mp3'));
await player.setCache(const CacheSettings(mode: Cache.no, pause: false));
await player.setNetworkTimeout(const Duration(seconds: 10));
```

For HLS streams (like Jellyfin transcoding), the default cache settings work well. Mpv handles HLS natively and provides precise seeking even on transcoded streams:

```dart
await player.open(Media(
  'https://jellyfin.example.com/audio/stream.m3u8',
  httpHeaders: {'Authorization': 'MediaBrowser Token="..."'},
));
```

Two build-time `PlayerConfiguration` knobs tune streaming behaviour:

```dart
final player = Player(
  configuration: const PlayerConfiguration(
    // Allow in-cache seeking on streams mpv reports as non-seekable
    // (direct-HTTP or HLS audio). Default false.
    forceSeekable: true,
    // Which rendition mpv picks from an adaptive HLS playlist. Default
    // .max; use .min to save bandwidth on metered links.
    hlsBitrate: HlsBitrate.min,
  ),
);
```

#### 7.9 Throttling CDNs and chunked requests

Some CDNs, notably progressive YouTube and `googlevideo` audio, rate-limit a single open-ended HTTP range request (the whole rest of the file) to a crawl. Playback is fine from the start but **freezes after a seek**, once the buffered audio drains and the throttled connection can't refill it.

Opt in to bounded range requests for that source via `Media.httpChunkSize`, the same technique yt-dlp uses (`--http-chunk-size`). Each request stays below the CDN's threshold, so it keeps serving at full speed:

```dart
await player.open(Media(
  googlevideoUrl,
  httpChunkSize: 8 * 1024 * 1024, // 8 MiB chunks
));
```

It is opt-in and scoped to that exact track. Leave it `null` (the default) for fast, trusted servers (Plex, Jellyfin, your own library) where one large request buffers fastest. Must be a positive byte count when set.

#### 7.10 Monitoring the demuxer cache

`player.stream.demuxerCacheState` (and `player.state.demuxerCacheState`)
surface a structured `DemuxerCacheState` snapshot for streaming sources:
the buffered time ranges, the raw download rate, and the eof-cached,
bof-cached, and underrun flags. It is empty for directly-seekable local files.

The `seekableRanges` are what you render as the downloaded (buffered)
regions of a network seek bar:

```dart
player.stream.demuxerCacheState.listen((cache) {
  for (final r in cache.seekableRanges) {
    // Each CacheRange is a [start, end] Duration window already buffered.
    print('buffered ${r.start} … ${r.end}');
  }
  if (cache.underrun) {
    // The cache ran dry, show a buffering spinner.
  }
});
```

---

### 8. Metadata and cover art

#### 8.1 Metadata tags

```dart
player.stream.metadata.listen((tags) {
  final title = tags['title'];
  final artist = tags['artist'];
  final album = tags['album'];
  final date = tags['date'];
  final trackNumber = tags['track'];
  print('Now playing: $title, $artist');
});

// Synchronous access
final meta = player.state.metadata;
```

Common tag keys (case as returned by mpv): `title`, `artist`, `album`, `album_artist`, `date`, `track`, `disc`, `genre`, `comment`, `composer`.

#### 8.2 Cover art

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/cover_art_flow.png" width="100%">

Embedded cover art is exposed as **raw codec bytes** plus a few
Flutter conveniences, on a synchronous-state + reactive-stream pair:

```dart
// Synchronous read: peek at the current track's cover
final art = player.state.coverArt;
if (art != null) {
  print('Format: ${art.extension}, ${art.bytes.length} bytes');
}

// Reactive: emits on every file load, null when no cover is embedded
player.stream.coverArt.listen((art) {
  if (art != null) updateUi(art.image);
});
```

The [`CoverArt`] type carries the bytes plus a few helpers:

<details>
<summary><b>5 members</b> (click to expand)</summary>

| Member | Kind | Description |
| :--- | :--- | :--- |
| `bytes` | `final Uint8List` | Raw codec bytes |
| `mimeType` | `final String` | `'image/png'`, `'image/jpeg'`, `'image/webp'`, `'image/bmp'`, `'image/gif'` |
| `image` | getter `ImageProvider` | Ready to drop into Flutter `Image(image: …)` |
| `extension` | getter `String` | `'png'`, `'jpg'`, `'webp'`, `'bmp'`, `'gif'` |
| `isPng`, `isJpeg`, `isWebp`, `isBmp`, `isGif` | getter `bool` | MIME-type predicates |

</details>

##### In a Flutter widget

```dart
StreamBuilder<CoverArt?>(
  stream: player.stream.coverArt,
  builder: (ctx, snap) {
    final art = snap.data;
    if (art == null) {
      return const Icon(Icons.music_note, size: 96);
    }
    return Image(
      image: art.image,         // MemoryImage backed by the raw bytes
      fit: BoxFit.cover,
    );
  },
)
```

##### Saving the cover to disk

```dart
final art = player.state.coverArt;
if (art != null) {
  await File('${dir.path}/cover.${art.extension}').writeAsBytes(art.bytes);
}
```

##### Lifecycle

- `stream.coverArt` emits **once per `open()` call**, on file load,
  before playback starts.
- The emitted value is `null` when the file has no embedded picture.
  The stream emits the `null` (rather than skipping the file) so a UI
  bound to it clears the previous cover on every track change.
- `state.coverArt` mirrors the latest stream emit synchronously.
- No re-encoding, no thumbnail generation. The bytes are exactly what
  the demuxer pulled out of the file.

##### External cover files

If you want mpv to *also* look for a `cover.jpg` sitting
next to the audio file on disk:

```dart
await player.setCoverArtAuto(Cover.no);     // library default (disabled)
await player.setCoverArtAuto(Cover.exact);  // match the audio filename
await player.setCoverArtAuto(Cover.fuzzy);  // any image in the same folder
await player.setCoverArtAuto(Cover.all);    // any image, even loosely matched
```

The library defaults to `no` (mpv's own default is `exact`) so
unrelated images can't sneak in. Switch to `exact` or `fuzzy` for a
local-file player that wants disk-side artwork.

---

### 9. State and streams

`mpv_audio_kit` exposes all player state in two complementary ways:

- **`player.state`**: a synchronous, immutable snapshot of the current state. Safe to read from anywhere.
- **`player.stream`**: reactive streams that emit on every change. Use with `StreamBuilder` or `.listen()`.

#### 9.1 Core streams

<details>
<summary><b>17 streams</b> (click to expand)</summary>

| Stream | Type | Notes |
| :--- | :--- | :--- |
| `playWhenReady` | `bool` | User intent to play (the play-pause axis). Set by `play`, `pause`, `open` and `stop`; **stable across seeks and buffering**, so bind your play-pause button (and the OS media controls already do) to this, not to `playing`. |
| `playing` | `bool` | `true` only while audio is actually being produced; tracks mpv's `core-idle` (inverted). **Toggles transiently during seeks and buffering**, so use for a spinner, not a play-pause button. "Actually emitting audio" is `playWhenReady && playing`. |
| `completed` | `bool` | `true` once the current track reaches natural EOF. |
| `eofReached` | `bool` | mpv's `eof-reached`; `true` while paused at the end of a file with `keep-open=yes`. |
| `position` | `Duration` | Current playhead, throttled to ~30 Hz. |
| `duration` | `Duration` | Total duration of the current file; `Duration.zero` for live streams. |
| `seekCompleted` | `void` | Fires once per `loadfile` or seek when mpv re-initialises (PLAYBACK_RESTART). Use as the authoritative "file ready" signal. |
| `buffering` | `bool` | `true` between `start-file` and `file-loaded`. |
| `buffer` | `Duration` | Absolute timestamp the demuxer has buffered up to. |
| `bufferDuration` | `Duration` | Headroom ahead of the playhead (`demuxer-cache-duration`). |
| `bufferingPercentage` | `double` (0-100) | Wrapper-computed cache fill against `state.cache.secs`. |
| `volume` | `double` | 0-100; values above 100 amplify. |
| `mute` | `bool` | |
| `rate` | `double` | Playback speed multiplier. |
| `pitch` | `double` | Pitch multiplier. |
| `pitchCorrection` | `bool` | Whether `scaletempo` is engaged. |
| `audioDelay` | `Duration` | Audio offset relative to video (sub-millisecond precision is rounded). |

</details>

#### 9.2 Playlist and track streams

<details>
<summary><b>8 streams</b> (click to expand)</summary>

| Stream | Type | Setter |
| :--- | :--- | :--- |
| `playlist` | `Playlist` | `open`, `openAll`, `add`, `remove`, `move`, `replace`, `clearPlaylist` |
| `loop` | `Loop` | `setLoop` |
| `shuffle` | `bool` | `setShuffle` |
| `prefetchPlaylist` | `bool` | `setPrefetchPlaylist` |
| `tracks` | `List<MpvTrack>` | _(observed; populated by demuxer)_ |
| `currentAudioTrack` | `MpvTrack?` | `setAudioTrack` |
| `chapters` | `List<Chapter>` | _(observed; populated by demuxer)_ |
| `currentChapter` | `int?` | `setChapter` |

</details>

#### 9.3 Audio hardware streams

<details>
<summary><b>23 streams</b> (click to expand)</summary>

| Stream | Type | Setter |
| :--- | :--- | :--- |
| `audioDevice` | `Device` | `setAudioDevice` |
| `audioDevices` | `List<Device>` | _(read-only)_ |
| `audioParams` | `AudioParams` | _(decoder; observed)_ |
| `audioOutParams` | `AudioParams` | _(hardware; observed)_ |
| `audioBitrate` | `double?` | _(observed)_ |
| `audioOutputState` | `AudioOutputState` | _(see [§11.4](#114-audio-output-lifecycle))_ |
| `audioDriver` | `String` | `setAudioDriver` |
| `audioExclusive` | `bool` | `setAudioExclusive` |
| `audioBuffer` | `Duration` | `setAudioBuffer` |
| `audioStreamSilence` | `bool` | `setAudioStreamSilence` |
| `audioNullUntimed` | `bool` | `setAudioNullUntimed` |
| `audioSpdif` | `Set<Spdif>` | `setAudioSpdif` |
| `volumeMax` | `double` | `setVolumeMax` |
| `volumeGain` | `double` | `setVolumeGain` |
| `volumeGainMin` | `double` | `setVolumeGainMin` |
| `volumeGainMax` | `double` | `setVolumeGainMax` |
| `systemVolume` | `double?` | `setSystemVolume` (OS mixer; `null` when unsupported by the active AO) |
| `systemMute` | `bool?` | `setSystemMute` (OS mixer; `null` when unsupported by the active AO) |
| `audioSampleRate` | `int` | `setAudioSampleRate` |
| `audioFormat` | `Format` | `setAudioFormat` |
| `audioChannels` | `Channels` | `setAudioChannels` |
| `audioClientName` | `String` | `setAudioClientName` |
| `audioMediaRole` | `bool` | `setAudioMediaRole` (reports a "music" role to PulseAudio and PipeWire) |

</details>

`AudioParams` carries: `format`, `sampleRate`, `channels`,
`channelCount`, `hrChannels`, `codec`, `codecName`.

#### 9.4 DSP and filter streams

<details>
<summary><b>3 streams</b> (click to expand)</summary>

| Stream | Type | Setter |
| :--- | :--- | :--- |
| `audioEffects` | `AudioEffects` | `setAudioEffects`, `updateAudioEffects` |
| `replayGain` | `ReplayGainSettings` | `setReplayGain` |
| `gapless` | `Gapless` | `setGapless` |

</details>

#### 9.5 Network and cache streams

<details>
<summary><b>9 streams</b> (click to expand)</summary>

| Stream | Type | Setter |
| :--- | :--- | :--- |
| `cache` | `CacheSettings` | `setCache` |
| `networkTimeout` | `Duration` | `setNetworkTimeout` |
| `tlsVerify` | `bool` | `setTlsVerify` |
| `pausedForCache` | `bool` | _(observed; auto-pause signal)_ |
| `demuxerViaNetwork` | `bool` | _(observed)_ |
| `demuxerCacheState` | `DemuxerCacheState` | _(observed; buffered ranges, raw input rate, eof-cached, bof-cached, underrun)_ |
| `cacheSpeed` | `double` (bytes per second) | _(observed)_ |
| `cacheBufferingState` | `int` (0-100) | _(observed)_ |
| `demuxer` | `DemuxerSettings` | `setDemuxer` |

</details>

#### 9.6 File metadata and path streams

<details>
<summary><b>12 streams</b> (click to expand)</summary>

| Stream | Type | mpv property |
| :--- | :--- | :--- |
| `metadata` | `Map<String, String>` | `metadata` |
| `mediaTitle` | `String` | `media-title` (falls back to filename when no `title` tag) |
| `fileFormat` | `String` | `file-format` |
| `fileSize` | `int` | `file-size` |
| `path` | `String` | `path` (canonicalised, post-redirect) |
| `filename` | `String` | `filename` (no directory) |
| `streamPath` | `String` | `stream-path` (URI as originally requested) |
| `streamOpenFilename` | `String` | `stream-open-filename` (URI as opened post-redirect) |
| `playlistPath` | `String` | `playlist-path` (source `.m3u` or `.pls`; empty when not loaded via a playlist) |
| `seekable` | `bool` | `seekable` |
| `partiallySeekable` | `bool` | `partially-seekable` (HLS or DASH window) |
| `demuxerIdle` | `bool` | `demuxer-cache-idle` |

</details>

#### 9.7 Playback timing streams

<details>
<summary><b>3 streams</b> (click to expand)</summary>

| Stream | Type | Notes |
| :--- | :--- | :--- |
| `audioPts` | `Duration` | mpv's `audio-pts`; per-frame timestamp including AO latency. More granular than [`position`](#91-core-streams). |
| `timeRemaining` | `Duration` | Wall-clock time to EOF, **ignoring** playback rate. |
| `playtimeRemaining` | `Duration` | Time to EOF **adjusted** for playback rate. |

</details>

#### 9.8 A-B loop streams

<details>
<summary><b>4 streams</b> (click to expand)</summary>

| Stream | Type | Setter |
| :--- | :--- | :--- |
| `abLoopA` | `Duration?` (`null` = disabled) | `setAbLoopA` |
| `abLoopB` | `Duration?` (`null` = disabled) | `setAbLoopB` |
| `abLoopCount` | `int?` (`null` = infinite) | `setAbLoopCount` |
| `remainingAbLoops` | `int?` (`null` when no loop or infinite) | _(observed; counts down)_ |

</details>

#### 9.9 Cover art streams

<details>
<summary><b>2 streams</b> (click to expand)</summary>

| Stream | Type | Setter |
| :--- | :--- | :--- |
| `coverArt` | `CoverArt?` (one emit per file load) | _(observed; from embedded picture)_ |
| `coverArtAuto` | `Cover` | `setCoverArtAuto` |

</details>

#### 9.10 Runtime diagnostics

<details>
<summary><b>8 streams</b> (click to expand)</summary>

| Stream | Type | mpv property |
| :--- | :--- | :--- |
| `seeking` | `bool` | `seeking` (UI gate against concurrent seeks) |
| `percentPos` | `double` (0-100) | `percent-pos` |
| `currentDemuxer` | `String` | `current-demuxer` |
| `currentAo` | `String` | `current-ao` |
| `demuxerStartTime` | `Duration` | `demuxer-start-time` (initial timestamp offset) |
| `chapterMetadata` | `Map<String, String>` | `chapter-metadata` (per-chapter tags) |
| `mpvVersion` | `String` | `mpv-version` |
| `ffmpegVersion` | `String` | `ffmpeg-version` |

</details>

#### 9.11 Prefetch lifecycle stream

mpv pre-opens the next playlist entry in the background to make the
transition between tracks gapless. The wrapper exposes a typed stream
so you can drive a "Prefetching…" UI, verify gapless, or log
warnings when a prefetch is dropped without parsing log lines.

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/mpv_prefetch_state.png" width="100%">

```dart
player.stream.prefetchState.listen((state) {
  switch (state) {
    case MpvPrefetchState.idle:
      // No background prefetch in progress.
    case MpvPrefetchState.loading:
      // The opener thread is creating the demuxer for the next item
      // and the secondary cache is filling.
      showIndicator('Prefetching…');
    case MpvPrefetchState.ready:
      // Secondary demuxer is open AND idle (cache-secs reached,
      // no segment fetches outstanding). Gapless is armed.
      showIndicator('Ready');
    case MpvPrefetchState.used:
      // Edge-trigger: the track just transitioned gaplessly.
      // Fires once and then drops back to `idle`.
      showIndicator('Using prefetched');
    case MpvPrefetchState.failed:
      // Edge-trigger: the opener thread failed (network error,
      // unsupported codec, on_load hook abort).
      showIndicator('Prefetch failed');
  }
});
```

<details>
<summary><b>5 prefetch states</b> (click to expand)</summary>

| State | When it fires | Notes |
| :--- | :--- | :--- |
| `idle` | Default; after every cancel or drop | Also fires right after `used` and `failed` so they read as one-shot transients |
| `loading` | Opener thread running | Persists until the demuxer is open and the reader goes idle |
| `ready` | Secondary demuxer open + reader idle | Gapless is armed |
| `used` | Track transitioned via the prefetched stream | Edge-triggered; pairs with the subsequent `idle` |
| `failed` | Opener thread error | Edge-triggered; pairs with the subsequent `idle` |

</details>

For a determinate progress bar instead of a spinner, pair the state with
`player.stream.prefetchCacheDuration`: how much of the next track is
already buffered ahead, as a `Duration`. Divide it by your configured
cache target for a percentage; it emits `Duration.zero` while no prefetch
is in flight.

```dart
player.stream.prefetchCacheDuration.listen((buffered) {
  const target = Duration(seconds: 30); // your cache target
  final pct = (buffered.inMilliseconds / target.inMilliseconds)
      .clamp(0.0, 1.0);
  showPrefetchProgress(pct); // 0.0 → 1.0
});
```

#### 9.12 Aggregate lifecycle

`player.stream.playbackState` collapses the four underlying flags
(`playing`, `buffering`, `completed`, `pausedForCache`) plus
`duration` into a single mutually-exclusive `MpvPlaybackState` enum,
ideal when the UI wants one indicator instead of three.

```dart
player.stream.playbackState.listen((phase) {
  switch (phase) {
    case MpvPlaybackState.idle:       // No file loaded
    case MpvPlaybackState.loading:    // File is opening (demuxer and decoder init)
    case MpvPlaybackState.buffering:  // Mid-playback network stall
    case MpvPlaybackState.playing:    // Producing audio
    case MpvPlaybackState.paused:     // File loaded, audio paused
    case MpvPlaybackState.completed:  // Reached natural EOF
  }
});
```

#### 9.13 Complete state snapshot

`player.state` mirrors every stream above. Use it for one-shot reads
inside event handlers and `build()` methods:

```dart
final s = player.state;
print(s.playing);                                // bool
print(s.position);                               // Duration
print(s.duration);                               // Duration
print(s.volume);                                 // double
print(s.buffer);                                 // Duration
print(s.playlist.items[s.playlist.index].uri);   // String
print(s.metadata['title']);                      // String?
print(s.audioParams.codec);                      // String?
print(s.audioEffects.acompressor.threshold);     // double (linear ratio)
print(s.cache.secs);                             // Duration
print(s.replayGain.preamp);                      // double
print(s.tracks.where((t) => t.type == 'audio')); // Iterable<MpvTrack>
print(s.chapters);                               // List<Chapter>
print(s.audioOutputState);                       // AudioOutputState
print(s.mpvVersion);                             // e.g. '0.41.0'
print(s.ffmpegVersion);                          // e.g. '8.1.1'
```

#### 9.14 Spectrum and PCM streams

Two real-time streams expose the audio currently flowing through the
output. See [§13](#13-visualizer-waveform-and-spectrum) for the full
configuration surface, the math behind the pipeline, and a reference
visualizer.

<details>
<summary><b>2 streams</b> (click to expand)</summary>

| Stream                | Type                | What it carries |
|-----------------------|---------------------|-----------------|
| `stream.fft`          | `Stream<FftFrame>`  | Smoothed FFT bands plus raw bins, ready for a bar visualizer. |
| `stream.pcm`          | `Stream<PcmFrame>`  | Raw post-DSP samples, ready for a waveform and VU. |

</details>

Both streams are lazy (poll loop runs only while subscribed) and
share the same upstream tap, so subscribing to both costs only the
duplicate FFT computation.

```dart
player.stream.fft.listen((frame) {
  // 64 bands, each in [0, 1]. Paint directly:
  for (var i = 0; i < frame.bands.length; i++) {
    paintBar(i, frame.bands[i]);
  }
});
```

#### 9.15 Media session streams

Two streams expose the OS media session. See
[§14](#14-os-media-session) for the full setup and command surface.

<details>
<summary><b>2 streams</b> (click to expand)</summary>

| Stream                          | Type                            | What it carries |
|---------------------------------|---------------------------------|-----------------|
| `stream.mediaSession`           | `Stream<MediaSession?>`         | The active session config (or `null` when none is published); mirrors `state.mediaSession`. |
| `stream.mediaSessionCommands`   | `Stream<MediaSessionCommand>`   | Transport commands the OS sends back (play, pause, next, seek and so on). Auto-applied to the player; surfaced here for analytics or interception. |

</details>

---

### 10. Raw API

For anything not covered by the typed API, you can access mpv directly.

#### 10.1 Read a property

Returns `null` if the property doesn't exist or the call fails.

```dart
final String? value = await player.getRawProperty('audio-codec');
final String? samplerate = await player.getRawProperty('audio-params/samplerate');
```

#### 10.2 Write a property

Throws `MpvException` if libmpv rejects the write (typo, out-of-range
value, …). Carries `name`, mpv `code`, and the human-readable
`message` from `mpv_error_string`.

```dart
try {
  await player.setRawProperty('audio-samplerate', '96000');
  await player.setRawProperty('audio-channels', 'stereo');
} on MpvException catch (e) {
  print('mpv rejected ${e.name}: ${e.message} (code=${e.code})');
}
```

#### 10.3 Send a command

Same `MpvException` contract on rejection.

```dart
await player.sendRawCommand(['af', 'add', 'lavfi-aresample=48000']);
await player.sendRawCommand(['playlist-shuffle']);
await player.sendRawCommand(['ao-reload']);
```

Any command or property from the
[mpv documentation](https://mpv.io/manual/master/) is accessible
through these methods.

> Prefer the typed setters (`setVolume`, `setCache`,
> `setReplayGain`, …) when they cover your use case. They update
> `state` immediately, while the raw escape hatches have to wait for
> mpv to confirm the change.

---

### 11. Error handling and logging

#### 11.1 Typed error stream

The error stream emits `MpvPlayerError`, a sealed class with two subtypes that let you distinguish between playback failures and informational engine errors:

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/error_streams.png" width="100%">

```dart
player.stream.error.listen((error) {
  switch (error) {
    case MpvEndFileError():
      // Playback ended due to an error (e.g. network timeout, file not found).
      print('End-file error: reason=${error.reason}, code=${error.code}');
      print('  isLoadingError: ${error.isLoadingError}');
      print('  isAudioOutputError: ${error.isAudioOutputError}');
      print('  isFormatError: ${error.isFormatError}');
    case MpvLogError():
      // An mpv subsystem logged at error or fatal level (e.g. codec issue).
      // Does NOT necessarily mean playback has stopped.
      print('Log error [${error.prefix}] ${error.level}: ${error.message}');
  }
});
```

`MpvEndFileError`, emitted when `MPV_EVENT_END_FILE` fires with a non-zero error code:
- `reason`: a `MpvEndFileReason` enum (`eof`, `stop`, `quit`, `error`, `redirect`)
- `code`: the raw mpv error code (e.g. `-13` for `MPV_ERROR_LOADING_FAILED`)
- `isLoadingError`: `true` for network or file loading failures
- `isAudioOutputError`: `true` when the audio output driver failed to initialize
- `isFormatError`: `true` when the file format is unrecognizable or has no audio

`MpvLogError`, emitted when mpv logs at `error` or `fatal` level:
- `prefix`: the mpv subsystem (e.g. `'ffmpeg'`, `'ao'`, `'demux'`)
- `level`: `LogLevel` (`LogLevel.error` or `LogLevel.fatal`)
- `text`: the raw log line from the mpv subsystem
- `message`: getter returning `'[prefix] level.mpvValue: text'`

> Network note: per the mpv documentation, a network disconnection mid-stream
> may report as `MpvEndFileReason.eof` rather than `MpvEndFileReason.error`.
> Use `player.stream.endFile` and compare position vs duration for reliable detection (see §11.2).

#### 11.2 End file stream

`player.stream.endFile` emits an `MpvFileEndedEvent` for **every** file-end, not just errors. This is the only way to detect premature EOFs caused by network disconnections, which mpv reports as `reason: eof` with no error code:

```dart
player.stream.endFile.listen((event) {
  if (event.reason == MpvEndFileReason.eof) {
    final pos = player.state.position;
    final dur = player.state.duration;
    if (dur > Duration.zero && (dur - pos).inSeconds > 5) {
      print('Premature EOF, likely a network drop');
    }
  }
});
```

`MpvFileEndedEvent` fields:
- `reason`: a `MpvEndFileReason` enum value
- `error`: the raw mpv error code (non-zero only when `reason == MpvEndFileReason.error`)

#### 11.3 Network state

Two dedicated streams for monitoring network conditions:

```dart
// True when playback is paused because the cache ran empty (network stall).
// This is the authoritative signal. Prefer it over interpreting error events.
player.stream.pausedForCache.listen((paused) {
  if (paused) showBufferingIndicator();
});

// True when the current stream is being read via a network protocol.
// Useful for deciding whether an error is likely network-related.
player.stream.demuxerViaNetwork.listen((isNetwork) {
  print('Network stream: $isNetwork');
});
```

Both are also available synchronously via `player.state.pausedForCache` and `player.state.demuxerViaNetwork`.

#### 11.4 Audio output lifecycle

mpv exposes the audio output's lifecycle as a typed stream. Read it
to drive a "Connecting…" UI on slow backends, or to detect a silent
player without polling format params.

```dart
player.stream.audioOutputState.listen((state) {
  switch (state) {
    case AudioOutputState.closed:        // No AO active
    case AudioOutputState.initializing:  // ao_init_best in flight
    case AudioOutputState.active:        // AO open, producing samples
    case AudioOutputState.failed:        // ao_init_best returned NULL
  }
});
```

The library also surfaces a typed `MpvLogError` on `stream.error` the
moment the AO transitions to `failed`, so you don't need a separate
listener for the "no sound" case.

#### 11.5 Log streams

Two streams keep engine and library messages disjoint. Route them to
different sinks (e.g. show only `log` in a debug overlay while
forwarding `internalLog` to crash reporting).

```dart
// mpv engine messages: ffmpeg, demux, ao, cplayer, …
player.stream.log.listen((entry) {
  // MpvLogEntry has: prefix (String), level (LogLevel), text (String)
  if (entry.level == LogLevel.error || entry.level == LogLevel.fatal) {
    print('[${entry.level.mpvValue}] ${entry.prefix}: ${entry.text}');
  }
});

// library-side diagnostics: JSON parse warnings, hook timeouts,
// resolution errors. Always carries prefix: 'mpv_audio_kit'.
player.stream.internalLog.listen((entry) {
  print('[wrapper:${entry.level.mpvValue}] ${entry.text}');
});
```

`PlayerConfiguration.logLevel` sets the initial verbosity (`LogLevel.warn`
for production, `LogLevel.debug` or `.v` for development, `LogLevel.off` to
silence the engine). Change it at runtime with `setLogLevel`:

```dart
await player.setLogLevel(LogLevel.debug); // more detail on demand
await player.setLogLevel(LogLevel.off);   // silence the engine
```

---

### 12. Hooks

Hooks intercept mpv's file-loading pipeline before a stream is opened. Use them to lazily resolve URLs, inject per-file HTTP headers, or redirect to a different source without a local proxy server:

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/on_load_hook_sequence.png" width="100%">

> `Media.httpHeaders` need no hook at all: the wrapper passes them as
> file-local `loadfile` options, scoped to that exact playlist entry.
> You only need to register your own hook when you want to handle URL
> resolution, redirects, or any other per-load logic on top of that.
> For plain URL resolution there is an official shortcut that skips
> the wiring entirely: [`setSourceResolver`](#125-the-source-resolver).

#### 12.1 Registering a hook

Call `registerHook` **once** after creating the player (before any `open` call).

```dart
player.registerHook(Hook.load);
```

You can add a safety timeout. If `continueHook` isn't called within the given duration, the library auto-continues to prevent mpv from stalling indefinitely (e.g. due to an unhandled exception):

```dart
player.registerHook(Hook.load, timeout: const Duration(seconds: 10));
```

The full set of mpv lifecycle hooks:

<details>
<summary><b>6 lifecycle hooks</b> (click to expand)</summary>

| Hook | When it fires |
| :--- | :--- |
| `Hook.beforeStartFile` | Before any per-file work begins (drains stale property changes) |
| `Hook.load` | Before a stream is opened. Redirect the URL or attach per-file headers |
| `Hook.loadFail` | After a stream failed to open. Useful for fallback URLs |
| `Hook.preloaded` | File open, demuxer ready, before track selection and decoder init |
| `Hook.unload` | Before a file is closed. Cleanup hook tied to the current file |
| `Hook.afterEndFile` | After a file finished and was fully unloaded |

</details>

> Hooks fire during prefetch too. When mpv pre-opens the next playlist entry to enable gapless transitions, `on_load` is invoked for that track too, so custom URL schemes (e.g. `plex-transcode://` → resolved HLS URL) are resolved for every track, including the one being prefetched in the background. Your listener is called once per track regardless of whether playback is active or prefetching, and `setRawProperty('stream-open-filename', …)` accepts hook-driven rewrites in either context.

#### 12.2 Listening and continuing

Subscribe to `player.stream.hook` and call `continueHook` when processing is done. You must always call `continueHook`, even on error, otherwise mpv stalls indefinitely:

```dart
player.stream.hook.listen((event) async {
  if (event.hook == Hook.load) {
    final url = await player.getRawProperty('stream-open-filename') ?? '';

    try {
      if (url.startsWith('my-scheme://')) {
        // Redirect to a real URL
        final resolved = await myResolver(url);
        await player.setRawProperty('stream-open-filename', resolved.url);

        // Inject per-file HTTP headers (direct HTTP only; for HLS use URL query params)
        if (resolved.headers.isNotEmpty) {
          final headerString = resolved.headers.entries
              .map((e) => '${e.key}: ${e.value}')
              .join(',');
          await player.setRawProperty(
            'file-local-options/http-header-fields',
            headerString,
          );
        }
      }
    } finally {
      player.continueHook(event.id); // always call
    }
  } else {
    player.continueHook(event.id);
  }
});
```

#### 12.3 HTTP headers via hook

`file-local-options/http-header-fields` sets headers only for the current file. They are applied at the mpv and libmpv layer and work correctly for direct HTTP streams.

Important note for HLS streams: when mpv opens an HLS playlist, the actual segment downloads are handled directly by ffmpeg's lavf, which does not inherit `http-header-fields` set via the hook. If your server requires authentication on the HLS segments, embed the credentials in the URL as query parameters instead:

```dart
// ✅ Correct for HLS: auth in the URL, visible to ffmpeg's lavf
player.setRawProperty(
  'stream-open-filename',
  'https://server/stream/playlist.m3u8?token=abc123',
);

// ⚠️ Works for direct HTTP streams only; ignored by ffmpeg's lavf for HLS sub-requests
player.setRawProperty('file-local-options/http-header-fields', 'Authorization: Bearer abc123');
```

#### 12.4 Lazy URL resolution

When building a playlist with `Future.wait`, all `getStreamUrl` calls run in parallel. If your server rejects concurrent session creation (as Plex does for transcoding), store the session parameters and return a placeholder URL (e.g. `my-scheme://session-id`). The `on_load` hook fires **sequentially** as mpv opens each track, so resolution calls never overlap:

```dart
// Building the queue. No real API calls yet
final medias = await Future.wait(tracks.map((t) async {
  final url = await service.getStreamUrl(t.id); // returns "my-scheme://abc"
  return Media(url);
}));
await player.openAll(medias);

// When mpv reaches each track, the hook resolves it on demand:
// on_load → myResolver("my-scheme://abc") → /decision + start.m3u8 URL
```

#### 12.5 The source resolver

`setSourceResolver` packages the whole [§12.4](#124-lazy-url-resolution) pattern into one official callback: no `registerHook` and `continueHook` wiring, no placeholder-scheme parsing. The resolver receives the entry's **original `Media`**, with `extras` and `httpHeaders` intact, so it can branch on consumer-attached data (a track id, a per-source auth flow) and return the URL to play:

```dart
player.setSourceResolver((request) async {
  final id = request.media.extras?['trackId'] as String?;
  if (id == null) return null;         // not ours, keep the URL as-is
  return service.getPlaybackUrl(id);   // temporary CDN or token URL
});

// Queue by id, with no network calls until each track actually opens:
await player.openAll([
  Media('resolve://1', extras: {'trackId': '1'}),
  Media('resolve://2', extras: {'trackId': '2'}),
]);
```

The resolver is consulted:

* **before every stream open** (`on_load`), gapless prefetch included;
* **once more after a failed open** (`on_load_fail`) with `request.isRetry` set: return a fresh URL and mpv retries. This is the expired-token path. The retry fires at most once per load, and only when the returned URL differs from the one that failed.

Returning `null` (or the incoming `request.uri` unchanged) keeps the current URL, so a resolver that only handles some entries leaves the rest untouched. A thrown error is logged on `internalLog` and treated as "keep the current URL".

> The resolver runs on top of the raw hook API, and the two compose: with a consumer-registered `Hook.load` the resolver runs **first**, then the event surfaces on `player.stream.hook` with `stream-open-filename` already rewritten, and your hook still owns `continueHook`. A hung resolver is capped by the `timeout` argument (default 15s), after which the library auto-continues the hook so mpv never stalls. Pass `null` as the resolver to uninstall.

---

### 13. Visualizer, Waveform and Spectrum

A real-time FFT spectrum and a raw PCM stream are exposed straight
off the audio output, captured *post-DSP* (after volume, EQ,
compressor: what you actually hear). Drive a `CustomPainter`
visualizer with `bands`, build a VU meter with `samples`, or run any
custom feature extraction on top:

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/spectrum_pipeline.png" width="100%">

The pipeline is lazy: the FFT runs only while
`Player.stream.fft` (or `Player.stream.pcm`) has at least one
listener. On the last cancel the timer stops and the FFT memory is
freed.

#### 13.1 Subscribing to the spectrum stream

`Player.stream.fft` emits an [FftFrame] on a fixed interval
(default 30 fps).

<details>
<summary><b>6 fields per frame</b> (click to expand)</summary>

| Field         | Type                | What it is |
|---------------|---------------------|------------|
| `bins`        | `Float32List`       | Raw FFT magnitude per linear-frequency bin, normalised `[0, 1]`. Length = `fftSize / 2`. |
| `bands`       | `Float32List`       | Smoothed log-spaced perceptual bands ready for a bar visualizer. Length = `bandCount`. |
| `timestamp`   | `Duration`          | Playback position the samples correspond to. |
| `sampleRate`  | `int`               | Hz of the AO output. |
| `bandLowHz`   | `double`            | Lower edge of the band axis. |
| `bandHighHz`  | `double`            | Upper edge of the band axis (clamped to Nyquist). |

</details>

```dart
player.stream.fft.listen((frame) {
  // 64 bands ready to paint:
  for (var i = 0; i < frame.bands.length; i++) {
    final h = frame.bands[i] * canvasHeight;
    // draw bar i with height h …
  }
});
```

Use `bands` for visualizers, the band-level asymmetric EMA (fast
attack, slow release) makes painting them directly produce the
"bouncy" feel without any client-side animation logic. Use `bins`
for custom remappings (mel, Bark, constant-Q, peak detection).

#### 13.2 Configuring the pipeline

Tune the FFT and the visual smoothing through `SpectrumSettings`,
applied in one call via `Player.setSpectrum`, or one field at a time
with `Player.updateSpectrum` (copyWith mapper).

```dart
// 60 fps with 128 bands and a tighter dB window:
await player.setSpectrum(const SpectrumSettings(
  fftSize: 2048,
  bandCount: 128,
  emitInterval: Duration(milliseconds: 16),
  minDb: -90,
  maxDb: -20,
));

// Mutate one field, e.g. UI slider on attack smoothing:
await player.updateSpectrum((s) => s.copyWith(attackSmoothing: 0.7));
```

<details>
<summary><b>10 fields</b> (click to expand)</summary>

| Field             | Default        | Range or choice |
|-------------------|----------------|----------------|
| `fftSize`         | 2048           | Power of 2: 256, 512, 1024, 2048, 4096 |
| `bandCount`       | 64             | Typical 32-128 |
| `bandLowHz`       | 20.0           | Bottom of human hearing |
| `bandHighHz`      | 20000.0        | Clamped to Nyquist (`sampleRate / 2`) |
| `window`          | `WindowFunction.hann` | Hann, Blackman-Harris, Rectangular |
| `emitInterval`    | 33 ms (~30 fps)| 8-67 ms (~120-15 fps) |
| `attackSmoothing` | 0.5            | EMA when band rises; higher = snappier |
| `releaseSmoothing`| 0.1            | EMA when band falls; lower = slower decay |
| `minDb`, `maxDb`  | -100, -30      | dB clip range mapped to `[0, 1]`. Matches Web Audio API `AnalyserNode.minDecibels` and `maxDecibels` defaults. |
| `overlapFactor`   | 4              | Power of 2: 1 (no overlap), 2, 4 (75 %, default), 8, 16 |

</details>

The pipeline reallocates FFT memory only on changes that require it,
so flipping settings on every UI tick is cheap.

Pause behaviour. When playback pauses, the AO ring stops
receiving samples and the pipeline stops emitting. The last
[FftFrame] is "frozen": the consumer holds the displayed state
until playback resumes. To fade the visualizer to zero on pause,
animate the held frame client-side.

#### 13.3 Raw PCM stream

`Player.stream.pcm` emits [PcmFrame]s on the same cadence as
`fft`, carrying the raw post-DSP samples instead of the
frequency-domain transform. Use it for time-domain visualisations:
oscilloscope-style waveforms, accurate VU and peak meters, custom feature
extractors that need amplitude.

```dart
double peak = 0;
player.stream.pcm.listen((frame) {
  for (final s in frame.samples) {
    if (s.abs() > peak) peak = s.abs();
  }
  peak *= 0.92; // decay
  vuController.value = peak;
});
```

`samples` is a `Float32List` of interleaved channels (`L, R, L, R…`).
Use `frame.samplesPerChannel` to compute the per-channel sample
count.

#### 13.4 Per-filter PCM taps

`player.stream.tap(filter, side: ...)` captures raw audio samples at
either side of a single filter in the `af` chain. The slot is named
through the typed `AudioEffect` enum, the same 86 values surfaced as
`*Settings` fields on `AudioEffects`, so every reachable filter is
chosen at compile time. The side is one of `TapSide.pre` (before the
filter's DSP runs) or `TapSide.post` (after).

```dart
// Two-curve display: input vs output of a single filter.
player.stream
    .tap(AudioEffect.equalizer, side: TapSide.pre)
    .listen((pcm) => paintInputWaveform(pcm.samples));
player.stream
    .tap(AudioEffect.equalizer, side: TapSide.post)
    .listen((pcm) => paintOutputWaveform(pcm.samples));
```

For frequency-domain bands run the samples through `BandProcessor`,
the same FFT, windowing and smoothing the library uses for the global
visualizer, so per-filter and global curves pulse with the exact same
ballistic:

```dart
final processor = BandProcessor(player.spectrumSettings);
// Track the global config so the local FFT stays in lock-step.
final cfgSub = player.stream.spectrum.listen(processor.setSettings);
final tapSub = player.stream
    .tap(AudioEffect.equalizer, side: TapSide.post)
    .listen((pcm) {
      final fft = processor.process(pcm);
      if (fft != null) painter.bands = fft.bands;
    });
```

`AudioEffectsX.active` cross-links the singular `AudioEffect` enum
with the `AudioEffects` bundle, yielding the enum value for every slot
flagged `enabled: true`, so you can iterate the live rack:

```dart
for (final f in player.state.audioEffects.active) {
  player.stream.tap(f, side: TapSide.post).listen(_paint);
}
```

The taps are lazy in the same way the global pipeline is: the
matching engine hook activates only while at least one listener is
attached and tears down on the last cancel.

#### 13.5 Waveform

A mono envelope of the loaded track is exposed via
[PlayerStream.waveform], computed in the background on a worker thread:
~2000 bins, each with its min, max and RMS, enough to paint a waveform
overview or a waveform-style seekbar.

Complete seekable files, local or a direct-play HTTP file, are decoded
ahead of time: partial envelopes arrive while the decode runs
(`wave.decoding`), then the final one. Streams that can't be decoded
ahead of time (adaptive, non-seekable or transcoded network sources)
**grow progressively**, re-emitting as playback advances, and a live
stream of unknown length keeps a rolling window (`wave.live`). The
`wave.filled` flag (one byte per bin: `1` covered, `0` not yet) marks
which bins hold real data, so a renderer can draw the un-analysed ones as
a baseline instead of a misleading flat-zero spike.

On loud, heavily limited masters the peaks sit near full scale for most
of the track. Drawing `wave.rms` as the body of the waveform, with the
min and max as a lighter outline, keeps verses, choruses and drops
readable. `wave.rms` is `null` with a libmpv older than `libmpv-r14`.

The ahead-of-time decode opens the source a second time, with the same
network options as playback (`tls-verify`, `tls-ca-file`, headers, user
agent, cookies), so a remote file is downloaded twice. The loudness scan
below rides the same decode.

The stream is **listener-gated**: the analyzer runs only while
something is subscribed to `player.stream.waveform`, and costs
nothing when nobody listens. No configuration, no opt-in setter,
just listen.

```dart
player.stream.waveform.listen((wave) {
  if (wave == null) return; // null on track change, until the first bins land
  // wave.min and wave.max: Float32List, range [-1, +1], wave.bins long.
  // wave.rms: Float32List?, range [0, 1], same length.
  // Bin i spans [i / wave.bins * wave.duration, (i + 1) / … ).
  for (var i = 0; i < wave.bins; i++) {
    if (wave.filled[i] == 0) continue; // not yet analysed, draw a baseline
    // draw a light bar from wave.min[i] to wave.max[i]
    // and a solid one from -wave.rms![i] to wave.rms![i]
  }
});
```

#### 13.6 Loudness

The EBU R128 loudness of the loaded track is exposed via
`player.stream.loudness`, measured like the waveform: the whole file is
decoded off the playback path moments after it loads, at many times
realtime. One terminal `LoudnessScan` per track — integrated LUFS,
loudness range, sample peak and true peak — before the audio has even
started playing.

This is how you volume-normalize a library whose files carry no
ReplayGain tags:

```dart
player.stream.loudness.listen((scan) {
  if (scan?.state == LoudnessScanState.ready) {
    // ReplayGain 2.0 reference is -18 LUFS.
    player.setVolumeGain((-18.0 - scan!.integrated!).clamp(-24.0, 24.0));
  }
});
```

Like the waveform, the stream is **listener-gated** (the scan runs only
while something is subscribed) and emits `null` on the track-change
boundary so stale results clear. Sources that can only be decoded as
they play (adaptive or live network streams) report
`LoudnessScanState.unavailable` — use the live meter below for those.

#### 13.7 Live loudness meter

`player.stream.loudnessMeter` emits momentary, short-term, integrated
and loudness-range readings of the audio *as it plays* — the data for a
VU-style meter or a broadcast loudness display. The meter is the
`ebur128` stage of the audio chain, so enable it on the bundle with its
`metadata` option on:

```dart
await player.updateAudioEffects(
  (e) => e.updateEbur128((m) => m.copyWith(enabled: true, metadata: true)),
);
player.stream.loudnessMeter.listen((l) => meter.paint(l.momentary));
```

**Listener-gated** — the measurement poll runs only while a listener is
attached. While the meter is not in the chain the stream simply emits
nothing.

---

### 14. OS media session

Publish the player to the operating system's media controls (the
**Now Playing** panel, Control Center and lockscreen on iOS and macOS,
MPRIS on Linux, SMTC on Windows, and the media notification on Android)
and receive the transport commands the OS sends back.

Everything goes through one setter, `Player.setMediaSession`. Pass
`null` to remove the entry. Only one `Player` per process may own the
session at a time (enabling a second throws `StateError`); `dispose()`
releases it automatically.

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/media_session_flow.png" width="100%">

#### 14.1 Enabling the session

Title, artist, album, artwork and duration are derived from the playing
file automatically, you don't have to push anything.

```dart
await player.setMediaSession(const MediaSession());  // enable
await player.setMediaSession(null);                  // remove
```

#### 14.2 Overriding metadata

Each metadata field is an override: `null` keeps mpv's value, a value
takes over, an empty string forces a blank. Use `copyWith` to change one
field on the fly.

```dart
await player.setMediaSession(
  (player.state.mediaSession ?? const MediaSession())
      .copyWith(title: 'Custom title', artist: 'Custom artist'),
);
```

Artwork is a typed choice on the `artwork` field:

```dart
MediaSessionArtwork.embedded            // default, the file's embedded cover
MediaSessionArtwork.custom(myCoverArt)  // your own image, ignoring the file cover
MediaSessionArtwork.uri(myArtUrl)       // a URL fetched natively (only the URL crosses the channel)
MediaSessionArtwork.none                // no artwork
```

Network URLs never reach the OS media session as text, since they often
carry credentials in the query (Subsonic, Jellyfin, Plex). MPRIS on Linux
gets `xesam:url` only for local files, and a remote cover is downloaded
first and handed to the OS as an image on every platform. A tag-less stream
with no title falls back to mpv's `media-title`, which is derived from the
URL: the query is stripped from it, but passing a title through
`Media.extras` or `MediaSession.title` is still the better choice.

#### 14.3 Reacting to OS commands

Commands are **auto-applied** to the player (lockscreen play → `play()`,
scrub → `seek()`, …) and also surfaced on
`Player.stream.mediaSessionCommands` for analytics or interception:

```dart
player.stream.mediaSessionCommands.listen((command) {
  switch (command) {
    case MediaSessionCommandSeekTo(:final position):
      log('scrubbed to $position');
    case MediaSessionCommandNext():
      // next and previous drive mpv's playlist when one is loaded; with a
      // single track they only emit here, so advance your own queue.
      myQueue.next();
    case _:
      break;
  }
});
```

#### 14.4 Capabilities, intervals and speeds

`actions` advertises the controls the OS may surface. What actually renders
is **platform-gated, not just space-gated**: each native media UI draws only a
subset (and a lockscreen typically shows 3 to 4 of those). Advertising an
action a platform doesn't render is harmless: it simply isn't drawn. The full
enum also includes `MediaAction.stop` and `MediaAction.like` (a favourite or star).

```dart
const MediaSession(
  actions: {
    MediaAction.play, MediaAction.pause, MediaAction.playPause,
    MediaAction.next, MediaAction.previous, MediaAction.seek,
    MediaAction.setRepeatMode, MediaAction.setShuffle,
  },
  fastForwardInterval: Duration(seconds: 30),     // skip-forward button
  rewindInterval: Duration(seconds: 15),          // skip-back button
  supportedPlaybackRates: [1.0, 1.25, 1.5, 2.0],  // speed picker
  autoApplyPlaylistNavigation: false,             // handle next and prev yourself
);
```

Set `autoApplyPlaylistNavigation: false` to handle the next and previous buttons
yourself, e.g. a ±30s skip on a multi-file audiobook, instead of the package
switching track. The command still arrives on
[`stream.mediaSessionCommands`](#915-media-session-streams).

**Which actions each platform's native media UI actually draws:**

| Action | iOS | macOS | Android | Windows | Linux¹ |
|---|:--:|:--:|:--:|:--:|:--:|
| `play`, `pause`, `playPause` | ✓ | ✓ | ✓ | ✓ | ✓ |
| `next`, `previous` | ✓ | ✓ | ✓ | ✓ | ✓ |
| `seek` (scrubber) | ✓ | ✓ | ✓ | ✓ | KDE |
| `fastForward`, `rewind` | ✓ | ✓ | ✓ | ✓ | ✗ |
| `stop` | ✗ | ✗ | ✗ | ✓ | ✗ |
| `setRepeatMode`, `setShuffle` | ✗ | ✗ | ✓ | ✗² | KDE |
| `setPlaybackRate` | ✗ | ✗ | ✗ | ✗² | KDE |
| `like` | ✓ | ✗ | ✓ | ✗ | ✗ |

¹ Linux depends on the desktop's MPRIS consumer, KDE Plasma draws
seek, repeat, shuffle, and rate toggles, GNOME's built-in popup shows only
prev, play-pause, and next.
² Windows SMTC exposes repeat, shuffle, and rate as settable *properties* but the
native flyout draws no toggle for them.

#### 14.5 Audio interruptions

`interruptionPolicy` decides what happens on a phone call, Siri, or
another app taking audio focus:

```dart
InterruptionPolicy.pauseAndResume // default, pause then resume when the OS allows
InterruptionPolicy.pauseOnly      // pause, never auto-resume
InterruptionPolicy.keepPlaying    // stay at full volume, never auto-pause
```

`keepPlaying` is the "focused listening, always max" mode. Honest
limits: on iOS an accepted phone or FaceTime call or Siri still takes the
audio route (OS-enforced, it can't be overridden), and on Android 12+
the system may fade the app out when another app gains focus. A
headphone unplug always pauses, even in `keepPlaying` (Apple HIG). The
policy is a no-op on macOS, Linux and Windows (no per-app audio session).

> **iOS:** background playback also needs the host app's `Info.plist` to
> declare `UIBackgroundModes` → `audio`.

#### 14.6 App identity (desktop)

On Linux (MPRIS) and Windows (SMTC) the OS labels the controls with your
app. macOS, iOS and Android use the system bundle identity automatically and
ignore these fields.

```dart
const MediaSession(
  appName: 'My Player',               // name shown by MPRIS and SMTC
  desktopEntry: 'com.example.myapp',  // Linux only, see below
);
```

`desktopEntry` is the basename (no `.desktop` extension) of the file you
install to `/usr/share/applications/`; the Linux desktop uses it to find your
app icon to show beside the controls. Leave it `null` and the desktop falls
back to a generic icon rather than a wrong one. On Windows the icon comes from
the executable, so only `appName` applies there.

---

## Permissions

### Android

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

### iOS

Enable `Audio, AirPlay, and Picture in Picture` in Signing & Capabilities.

Add to `Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
```

### macOS

Add to `DebugProfile.entitlements` and `Release.entitlements`:

```xml
<key>com.apple.security.network.client</key>
<true/>
```

---

## Troubleshooting

#### Building and testing on containers (WSL, Docker, or Distrobox)
If you are developing or testing your Flutter app inside a headless Linux container, you will need to install both the core Flutter desktop build tools and the native audio server runtimes. Standard Linux desktops (like Ubuntu or Fedora) already have the audio backends pre-installed, but minimal containers require them to route sound to your host machine:

```bash
sudo apt update

# 1. Flutter desktop build essentials:
sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev

# 2. Audio backend runtimes & host routing (required to hear sound inside containers):
sudo apt install pipewire pipewire-pulse libasound2-dev libpulse-dev libpipewire-0.3-dev
```

> Note on ALSA: be aware that low-level hardware drivers like ALSA don't work inside containers. Use the PulseAudio or PipeWire backend for container testing.
> 
> Note on WSL: PipeWire and ALSA do not work on Windows Subsystem for Linux. You must use the PulseAudio backend to hear sound during development.
---

## Project background

All the native bindings, isolate logic, and architectural patterns were implemented through the use of Claude Code.

---

*Developed by Alessandro Di Ronza*
