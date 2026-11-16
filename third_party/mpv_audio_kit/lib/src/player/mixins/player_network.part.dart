// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// Network setters: cache configuration, demuxer limits, network
/// timeouts, TLS verification, and audio-output buffering.
mixin _NetworkModule on _PlayerBase {
  /// Sets the cache configuration atomically.
  ///
  /// Writes the six backing mpv properties (`cache`, `cache-secs`,
  /// `cache-on-disk`, `cache-pause`, `cache-pause-wait`, `cache-pause-initial`)
  /// in one shot. Modify a single field via
  /// `await player.setCache(state.cache.copyWith(secs: const Duration(seconds: 30)))`.
  Future<void> setCache(CacheSettings settings) async {
    await _gate();
    final previous = state.cache;
    final writes = <(String, String, String)>[
      ('cache', settings.mode.mpvValue, previous.mode.mpvValue),
      (
        'cache-secs',
        durationToSeconds(settings.secs).toStringAsFixed(3),
        durationToSeconds(previous.secs).toStringAsFixed(3)
      ),
      (
        'cache-on-disk',
        settings.onDisk ? 'yes' : 'no',
        previous.onDisk ? 'yes' : 'no'
      ),
      (
        'cache-pause',
        settings.pause ? 'yes' : 'no',
        previous.pause ? 'yes' : 'no'
      ),
      (
        'cache-pause-wait',
        durationToSeconds(settings.pauseWait).toStringAsFixed(3),
        durationToSeconds(previous.pauseWait).toStringAsFixed(3)
      ),
      (
        'cache-pause-initial',
        settings.pauseInitial ? 'yes' : 'no',
        previous.pauseInitial ? 'yes' : 'no'
      ),
    ];
    final committed = <(String, String)>[];
    try {
      for (final (name, value, prior) in writes) {
        await _prop(name, value);
        committed.add((name, prior));
      }
    } catch (_) {
      for (final (name, prior) in committed.reversed) {
        await _propRc(name, prior);
      }
      rethrow;
    }
    _updateField(
        (s) => s.copyWith(cache: settings), _reactives.cache, settings,);
  }

  /// Sets the audio output buffer depth.
  ///
  /// Range: 0 to 10 seconds. Default 200 ms — matches mpv's default and is
  /// a sane trade-off between latency and underrun resistance. Increase
  /// for high-latency wireless outputs (Bluetooth, network speakers);
  /// decrease for live monitoring or low-latency listening.
  Future<void> setAudioBuffer(Duration size) async {
    await _gate();
    await _prop('audio-buffer', durationToSeconds(size).toStringAsFixed(3));
    _updateField(
        (s) => s.copyWith(audioBuffer: size), _reactives.audioBuffer, size,);
  }

  /// Enables or disables streaming silence when no audio is playing.
  Future<void> setAudioStreamSilence(bool enable) async {
    await _gate();
    await _prop('audio-stream-silence', enable ? 'yes' : 'no');
    _updateField((s) => s.copyWith(audioStreamSilence: enable),
        _reactives.audioStreamSilence, enable,);
  }

  /// Sets the network connection timeout.
  ///
  /// Default 60 seconds. Pass [Duration.zero] to fall back to FFmpeg's
  /// own protocol-specific defaults. Applied to every connection attempt
  /// mpv makes (HTTP, HTTPS, …). Sub-second precision is honoured
  /// down to the microsecond.
  Future<void> setNetworkTimeout(Duration timeout) async {
    await _gate();
    // mpv's `network-timeout` accepts a fractional second value (e.g.
    // "0.5"). Truncating with `inSeconds` would collapse any sub-second
    // duration to 0, which mpv interprets as "no timeout".
    await _prop('network-timeout', durationToSeconds(timeout).toStringAsFixed(6));
    _updateField((s) => s.copyWith(networkTimeout: timeout),
        _reactives.networkTimeout, timeout,);
  }

  /// Whether to verify TLS/SSL certificates for network streams.
  Future<void> setTlsVerify(bool enable) async {
    await _gate();
    await _prop('tls-verify', enable ? 'yes' : 'no');
    _updateField(
        (s) => s.copyWith(tlsVerify: enable), _reactives.tlsVerify, enable,);
  }

  /// Sets the absolute filesystem path to a PEM bundle of trusted CA
  /// certificates used for `https://` peer verification.
  ///
  /// The bundled libmpv ships with the Mozilla CA roots compiled in, so
  /// [setTlsVerify] works out of the box on every platform. Call this only
  /// to override those roots — for example to pin against a corporate root
  /// CA. Passing an empty string clears the override and falls back to the
  /// built-in roots.
  Future<void> setTlsCaFile(String path) async {
    await _gate();
    await _prop('tls-ca-file', path);
    _updateField((s) => s.copyWith(tlsCaFile: path), _reactives.tlsCaFile,
        path,);
  }

  /// Sets the HLS variant-selection policy for adaptive streams.
  ///
  /// Chooses which audio rendition mpv picks from an HLS master playlist
  /// (mpv's `hls-bitrate`). Default [HlsBitrate.max]. Takes effect on the
  /// next load. The initial policy can also be set via
  /// `PlayerConfiguration.hlsBitrate`.
  Future<void> setHlsBitrate(HlsBitrate hlsBitrate) async {
    await _gate();
    await _prop('hls-bitrate', hlsBitrate.mpvValue);
    _updateField((s) => s.copyWith(hlsBitrate: hlsBitrate),
        _reactives.hlsBitrate, hlsBitrate,);
  }

  /// Enables mpv's HTTP cookie jar for network streams (mpv's `cookies`).
  ///
  /// Takes effect on the next load. Default `false`.
  Future<void> setCookies(bool enable) async {
    await _gate();
    await _prop('cookies', enable ? 'yes' : 'no');
    _updateField(
        (s) => s.copyWith(cookies: enable), _reactives.cookies, enable,);
  }

  /// Sets the HTTP proxy URL for network streams (mpv's `http-proxy`).
  ///
  /// Applies to FFmpeg's HTTP stack on the next load; pass an empty string
  /// to clear. Per-request headers go through `Media.httpHeaders` instead.
  Future<void> setHttpProxy(String url) async {
    await _gate();
    await _prop('http-proxy', url);
    _updateField(
        (s) => s.copyWith(httpProxy: url), _reactives.httpProxy, url,);
  }

  /// Sets the demuxer buffering configuration atomically.
  ///
  /// Writes the three backing mpv properties (`demuxer-max-bytes`,
  /// `demuxer-max-back-bytes`, `demuxer-readahead-secs`) in one shot. The byte
  /// caps are forwarded as raw byte counts (sub-MiB precision preserved), and
  /// the readahead is a fractional-seconds value (sub-second precision
  /// preserved). Modify a single field via
  /// `await player.setDemuxer(state.demuxer.copyWith(maxBackBytes: 0))`.
  Future<void> setDemuxer(DemuxerSettings settings) async {
    await _gate();
    final previous = state.demuxer;
    final writes = <(String, String, String)>[
      (
        'demuxer-max-bytes',
        settings.maxBytes.toString(),
        previous.maxBytes.toString()
      ),
      (
        'demuxer-max-back-bytes',
        settings.maxBackBytes.toString(),
        previous.maxBackBytes.toString()
      ),
      (
        'demuxer-readahead-secs',
        durationToSeconds(settings.readahead).toStringAsFixed(6),
        durationToSeconds(previous.readahead).toStringAsFixed(6)
      ),
    ];
    final committed = <(String, String)>[];
    try {
      for (final (name, value, prior) in writes) {
        await _prop(name, value);
        committed.add((name, prior));
      }
    } catch (_) {
      for (final (name, prior) in committed.reversed) {
        await _propRc(name, prior);
      }
      rethrow;
    }
    _updateField(
        (s) => s.copyWith(demuxer: settings), _reactives.demuxer, settings,);
  }

  /// Whether to fallback to untimed null output if audio output fails.
  Future<void> setAudioNullUntimed(bool enable) async {
    await _gate();
    await _prop('ao-null-untimed', enable ? 'yes' : 'no');
    _updateField((s) => s.copyWith(audioNullUntimed: enable),
        _reactives.audioNullUntimed, enable,);
  }
}
