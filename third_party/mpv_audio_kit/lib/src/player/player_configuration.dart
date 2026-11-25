// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../types/enums/hls_bitrate.dart';
import '../types/enums/log_level.dart';

/// Build-time configuration for a [Player]: the set-once choices applied
/// before or at `mpv_initialize`.
///
/// The split is grounded in mpv's own option model: an option mpv applies
/// reactively at runtime (one carrying an `UPDATE_*` flag: `volume`,
/// `audio-client-name`, the audio driver, …) is exposed as a `setX(...)`
/// method, **not** duplicated here. This class holds the set-once consumer
/// choices read at use-time (the resume policy, the watch-later dir) plus the
/// initial value of the few runtime properties whose starting state matters
/// before the first `setX` can land ([initialVolume], [logLevel]). The
/// audio-only library invariants (video and scripting disabled, …) are fixed
/// and deliberately not configurable.
final class PlayerConfiguration {
  /// If `true`, playback starts automatically as soon as a track finishes
  /// loading. Default: `false`.
  final bool autoPlay;

  /// Initial volume level (0 to 100). Default: `100`.
  final double initialVolume;

  /// Threshold forwarded to the [PlayerStream.log] stream.
  ///
  /// Default: [LogLevel.warn]. Surfaces warnings, errors, fatals.
  final LogLevel logLevel;

  /// Whether to resume playback from the saved "watch later" position when a
  /// previously-played file is opened again (mpv's `--resume-playback`).
  /// Default `true` (mpv's default). Resume only happens once a config has
  /// been written via [Player.writeResumeConfig]; until then this is inert.
  /// The values a resume point restores (speed, volume and the like) stay
  /// for the files that follow: see [Player.writeResumeConfig].
  final bool resumePlayback;

  /// Directory where the "watch later" resume configs are stored
  /// (mpv's `--watch-later-dir`). `null` uses mpv's default location, which
  /// is often not writable on mobile; point this at an app-writable path
  /// (e.g. from `getApplicationSupportDirectory()`) when using resume there.
  final String? watchLaterDir;

  /// Force in-cache seeking on streams mpv reports as non-seekable
  /// (mpv's `--force-seekable`). Read at demux open, so it governs every
  /// subsequent load. Default `false`. Useful to keep the scrub bar live on
  /// direct-HTTP or HLS audio that doesn't advertise seeking.
  final bool forceSeekable;

  /// Which HLS variant mpv selects from an adaptive master playlist
  /// (mpv's `--hls-bitrate`). Read at stream open. Default [HlsBitrate.max]
  /// (mpv's default). Set [HlsBitrate.min] to save bandwidth on metered links.
  final HlsBitrate hlsBitrate;

  /// Scale down surround content downmixed to fewer channels so the mix
  /// cannot clip (mpv's `--audio-normalize-downmix`). Read when the
  /// resampler is built. Default `false` (mpv's default): off risks
  /// clipping on 5.1→stereo, on sounds quieter.
  final bool normalizeDownmix;

  /// Directory for the on-disk demuxer cache (mpv's `--demuxer-cache-dir`),
  /// the companion of [CacheSettings.onDisk]. `null` uses mpv's default
  /// location (often not writable on mobile); point this at an app-writable
  /// path (e.g. `getTemporaryDirectory()`) when spilling the cache to disk.
  final String? demuxerCacheDir;

  /// Whether `https://` sources must present a certificate a trusted root
  /// signed (mpv's `--tls-verify`), set before the first load. Default
  /// `true`, as mpv and FFmpeg have it. A home server with a self-signed
  /// certificate fails to open then: pass [Player.setTlsCaFile] a bundle
  /// with its certificate (the file replaces the built-in roots, so it also
  /// needs those of the other servers the app plays from), or turn
  /// verification off here or with [Player.setTlsVerify].
  final bool tlsVerify;

  /// Creates a configuration; every field defaults to its documented value.
  const PlayerConfiguration({
    this.autoPlay = false,
    this.initialVolume = 100.0,
    this.logLevel = LogLevel.warn,
    this.resumePlayback = true,
    this.watchLaterDir,
    this.forceSeekable = false,
    this.hlsBitrate = HlsBitrate.max,
    this.normalizeDownmix = false,
    this.demuxerCacheDir,
    this.tlsVerify = true,
  });
}
