// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// The longest network timeout FFmpeg takes: it keeps `timeout` as an int
/// of microseconds (tcp.c, libsmb2.c), refuses the option past INT_MAX,
/// and every network open then fails.
const _kMaxNetworkTimeout = Duration(microseconds: 2147483647);

/// Network setters: cache configuration, demuxer limits, network
/// timeouts, TLS verification, and audio-output buffering.
mixin _NetworkModule on _PlayerBase {
  /// Sets the cache configuration atomically.
  ///
  /// Writes the six backing mpv properties (`cache`, `cache-secs`,
  /// `cache-on-disk`, `cache-pause`, `cache-pause-wait`, `cache-pause-initial`)
  /// in one shot. Modify a single field with `copyWith`:
  ///
  /// ```dart
  /// await player.setCache(
  ///   player.state.settings.cache.copyWith(secs: const Duration(seconds: 30)),
  /// );
  /// ```
  ///
  /// During a live [PcmSource] entry, which plays with `cache-pause` off,
  /// a new `pause` holds only until that entry ends.
  Future<void> setCache(CacheSettings settings) async {
    await _gate();
    final previous = state.settings.cache;
    final writes = <(String, String, String)>[
      ('cache', settings.mode.mpvValue, previous.mode.mpvValue),
      (
        'cache-secs',
        durationToSeconds(settings.secs).toStringAsFixed(6),
        durationToSeconds(previous.secs).toStringAsFixed(6),
      ),
      (
        'cache-on-disk',
        settings.onDisk ? 'yes' : 'no',
        previous.onDisk ? 'yes' : 'no',
      ),
      (
        'cache-pause',
        settings.pause ? 'yes' : 'no',
        previous.pause ? 'yes' : 'no',
      ),
      (
        'cache-pause-wait',
        durationToSeconds(settings.pauseWait).toStringAsFixed(6),
        durationToSeconds(previous.pauseWait).toStringAsFixed(6),
      ),
      (
        'cache-pause-initial',
        settings.pauseInitial ? 'yes' : 'no',
        previous.pauseInitial ? 'yes' : 'no',
      ),
    ];
    await _calls.writeBundle(
      writes,
      (v) => _updateField((s) => s.copyWith(cache: v), _reactives.cache, v),
      settings,
      previous,
    );
  }

  /// Sets the audio output buffer depth.
  ///
  /// Range: 0 to 10 seconds. Default 200 ms: matches mpv's default and is
  /// a sane trade-off between latency and underrun resistance. Increase
  /// for high-latency wireless outputs (Bluetooth, network speakers);
  /// decrease for live monitoring or low-latency listening. During a live
  /// [PcmSource] entry opened with `lowLatency`, a new value holds only
  /// until that entry ends. Throws [RangeError] outside 0 to 10 seconds.
  Future<void> setAudioBuffer(Duration size) async {
    if (size.isNegative || size > const Duration(seconds: 10)) {
      throw RangeError.value(
        size.inMicroseconds,
        'size',
        'microseconds, must be in [0, 10 s]',
      );
    }
    await _write(
      'audio-buffer',
      durationToSeconds(size).toStringAsFixed(6),
      _reactives.audioBuffer,
      size,
      (s) => s.copyWith(audioBuffer: size),
    );
  }

  /// Enables or disables streaming silence when no audio is playing.
  ///
  /// On Android the default `audiotrack` driver streams the silence.
  Future<void> setAudioStreamSilence(bool enable) async {
    await _write(
      'audio-stream-silence',
      enable ? 'yes' : 'no',
      _reactives.audioStreamSilence,
      enable,
      (s) => s.copyWith(audioStreamSilence: enable),
    );
  }

  /// Sets the network connection timeout.
  ///
  /// Default 60 seconds. Pass [Duration.zero] to fall back to FFmpeg's
  /// own protocol-specific defaults. Applied to every connection attempt
  /// mpv makes (HTTP, HTTPS, …). Sub-second precision is honoured
  /// down to the microsecond.
  ///
  /// The longest timeout is 2147.483647 seconds (about 36 minutes): FFmpeg
  /// keeps it as a 32-bit count of microseconds, and a longer one would
  /// fail every network open. A longer [timeout] is capped there, in mpv
  /// and in [PlayerSettings.networkTimeout] alike.
  ///
  /// For `smb2://` sources, with [Duration.zero] the connection gets 30
  /// seconds, with no limit on the reads after it, and a stop, a track
  /// change or a dispose interrupts a connect or a read at once.
  ///
  /// Throws [RangeError] for a negative [timeout].
  Future<void> setNetworkTimeout(Duration timeout) async {
    if (timeout.isNegative) {
      throw RangeError.value(
        timeout.inMicroseconds,
        'timeout',
        'microseconds, must not be negative',
      );
    }
    if (timeout > _kMaxNetworkTimeout) timeout = _kMaxNetworkTimeout;
    // mpv's `network-timeout` accepts a fractional second value (e.g.
    // "0.5"). Truncating with `inSeconds` would collapse any sub-second
    // duration to 0, which mpv interprets as "no timeout".
    await _write(
      'network-timeout',
      durationToSeconds(timeout).toStringAsFixed(6),
      _reactives.networkTimeout,
      timeout,
      (s) => s.copyWith(networkTimeout: timeout),
    );
  }

  /// Whether to verify TLS (SSL) certificates for network streams.
  ///
  /// On by default ([PlayerConfiguration.tlsVerify]). For a home server
  /// with a self-signed certificate, [setTlsCaFile] with a bundle that
  /// holds its certificate keeps verification on. That file replaces the
  /// built-in roots, so it also holds those of the other servers the app
  /// plays from.
  Future<void> setTlsVerify(bool enable) async {
    await _write(
      'tls-verify',
      enable ? 'yes' : 'no',
      _reactives.tlsVerify,
      enable,
      (s) => s.copyWith(tlsVerify: enable),
    );
  }

  /// Sets the absolute filesystem path to a PEM bundle of trusted CA
  /// certificates used for `https://` peer verification.
  ///
  /// The bundled libmpv ships with the Mozilla CA roots compiled in, so
  /// [setTlsVerify] works out of the box on every platform. Call this only
  /// to override those roots: for example to pin against a corporate root
  /// CA. Passing an empty string clears the override and falls back to the
  /// built-in roots.
  ///
  /// The media session's cover downloads (Linux, Android and Windows) use
  /// this bundle too, on top of the system roots rather than in place of
  /// them, and always verify the certificate, whatever [setTlsVerify].
  Future<void> setTlsCaFile(String path) async {
    await _write(
      'tls-ca-file',
      path,
      _reactives.tlsCaFile,
      path,
      (s) => s.copyWith(tlsCaFile: path),
    );
  }

  /// Trusts the certificates of the PEM file at [path] on top of the roots
  /// in use: the built-in ones, or those of [setTlsCaFile]. `''` trusts
  /// nothing more. Where [setTlsCaFile] replaces the roots, this adds to
  /// them, so a home server with a self-signed certificate (the
  /// certificate itself, whose host name still has to match) or a private
  /// CA plays, and every other `https://` source is verified as before.
  /// Read when the certificate is verified ([setTlsVerify]), from the next
  /// load on. The waveform, the loudness scan and the covers the media
  /// session downloads trust it too.
  ///
  /// It is FFmpeg's `ca_extra_file`, set in `stream-lavf-o`: a global
  /// `stream-lavf-o` the app writes itself replaces it. Throws
  /// [ArgumentError] for a path with a comma, CR, LF or NUL, which the
  /// option list cannot hold.
  Future<void> setTlsExtraCaFile(String path) async {
    if (_kForbiddenInLavfValue.hasMatch(path)) {
      throw ArgumentError.value(
        path,
        'path',
        'must not contain CR, LF, NUL, or comma',
      );
    }
    await _gate();
    await _calls.commandChecked([
      'change-list',
      'stream-lavf-o',
      if (path.isEmpty) ...[
        'remove',
        'ca_extra_file',
      ] else ...[
        'add',
        'ca_extra_file=$path',
      ],
    ]);
    _updateField(
      (s) => s.copyWith(tlsExtraCaFile: path),
      _reactives.tlsExtraCaFile,
      path,
    );
  }

  /// Sets the HLS variant-selection policy for adaptive streams.
  ///
  /// Chooses which audio rendition mpv picks from an HLS master playlist
  /// (mpv's `hls-bitrate`). Default [HlsBitrate.max]. Takes effect on the
  /// next load. The initial policy can also be set via
  /// `PlayerConfiguration.hlsBitrate`.
  Future<void> setHlsBitrate(HlsBitrate hlsBitrate) async {
    await _write(
      'hls-bitrate',
      hlsBitrate.mpvValue,
      _reactives.hlsBitrate,
      hlsBitrate,
      (s) => s.copyWith(hlsBitrate: hlsBitrate),
    );
  }

  /// Enables mpv's HTTP cookie jar for network streams (mpv's `cookies`).
  ///
  /// Takes effect on the next load. Default `false`.
  Future<void> setCookies(bool enable) async {
    await _write(
      'cookies',
      enable ? 'yes' : 'no',
      _reactives.cookies,
      enable,
      (s) => s.copyWith(cookies: enable),
    );
  }

  /// Sets the HTTP proxy URL for network streams (mpv's `http-proxy`).
  ///
  /// Applies to FFmpeg's HTTP stack on the next load; pass an empty string
  /// to clear. Per-request headers go through `Media.httpHeaders` instead.
  /// `http://` and `https://` sources go through the proxy, `https://`
  /// ones tunnelled with `CONNECT`.
  Future<void> setHttpProxy(String url) async {
    await _write(
      'http-proxy',
      url,
      _reactives.httpProxy,
      url,
      (s) => s.copyWith(httpProxy: url),
    );
  }

  /// Sets the demuxer buffering configuration atomically.
  ///
  /// Writes the three backing mpv properties (`demuxer-max-bytes`,
  /// `demuxer-max-back-bytes`, `demuxer-readahead-secs`) in one shot. The byte
  /// caps are forwarded as raw byte counts (sub-MiB precision preserved), and
  /// the readahead is a fractional-seconds value (sub-second precision
  /// preserved). Modify a single field via
  /// `player.setDemuxer(state.settings.demuxer.copyWith(maxBackBytes: 0))`.
  Future<void> setDemuxer(DemuxerSettings settings) async {
    await _gate();
    final previous = state.settings.demuxer;
    final writes = <(String, String, String)>[
      (
        'demuxer-max-bytes',
        settings.maxBytes.toString(),
        previous.maxBytes.toString(),
      ),
      (
        'demuxer-max-back-bytes',
        settings.maxBackBytes.toString(),
        previous.maxBackBytes.toString(),
      ),
      (
        'demuxer-readahead-secs',
        durationToSeconds(settings.readahead).toStringAsFixed(6),
        durationToSeconds(previous.readahead).toStringAsFixed(6),
      ),
    ];
    await _calls.writeBundle(
      writes,
      (v) => _updateField((s) => s.copyWith(demuxer: v), _reactives.demuxer, v),
      settings,
      previous,
    );
  }

  /// Makes the null audio output run untimed (mpv's `ao-null-untimed`):
  /// decoding goes as fast as possible instead of at real time. Applies to
  /// the `null` driver and to the fallback used when the device fails to
  /// open.
  Future<void> setAudioNullUntimed(bool enable) async {
    await _write(
      'ao-null-untimed',
      enable ? 'yes' : 'no',
      _reactives.audioNullUntimed,
      enable,
      (s) => s.copyWith(audioNullUntimed: enable),
    );
  }
}

/// What an entry of the comma-separated `stream-lavf-o` list cannot hold.
final RegExp _kForbiddenInLavfValue = RegExp(r'[\r\n,\x00]');
