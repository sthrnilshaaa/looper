// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of 'default_specs.dart';

// The specs of the cache, the demuxer and the network.

/// The cache, the demuxer and the network options.
List<MpvPropertySpec<Object?>> _networkSpecs(DefaultPropertyReactives r) => [
  // Aggregate cell: six specs share one reactive that dedups on the
  // full [CacheSettings].
  MpvPropertySpec<CacheSettings>.string(
    name: 'cache',
    reactive: r.cache,
    parse: (raw, s) => s.settings.cache.copyWith(mode: Cache.fromMpv(raw)),
    reduce: (v, s) => s.copyWith(cache: v),
  ),
  MpvPropertySpec<CacheSettings>.double(
    name: 'cache-secs',
    reactive: r.cache,
    parse: (raw, s) => s.settings.cache.copyWith(secs: secondsToDuration(raw)),
    reduce: (v, s) => s.copyWith(cache: v),
  ),
  MpvPropertySpec<CacheSettings>.flag(
    name: 'cache-on-disk',
    reactive: r.cache,
    parse: (raw, s) => s.settings.cache.copyWith(onDisk: raw),
    reduce: (v, s) => s.copyWith(cache: v),
  ),
  MpvPropertySpec<CacheSettings>.flag(
    name: 'cache-pause',
    reactive: r.cache,
    parse: (raw, s) => s.settings.cache.copyWith(pause: raw),
    reduce: (v, s) => s.copyWith(cache: v),
  ),
  MpvPropertySpec<CacheSettings>.double(
    name: 'cache-pause-wait',
    reactive: r.cache,
    parse: (raw, s) =>
        s.settings.cache.copyWith(pauseWait: secondsToDuration(raw)),
    reduce: (v, s) => s.copyWith(cache: v),
  ),
  MpvPropertySpec<CacheSettings>.flag(
    name: 'cache-pause-initial',
    reactive: r.cache,
    parse: (raw, s) => s.settings.cache.copyWith(pauseInitial: raw),
    reduce: (v, s) => s.copyWith(cache: v),
  ),
  // ── Demuxer ──────────────────────────────────────────────────────────
  // Aggregate cell: three specs share one reactive that dedups on the
  // full [DemuxerSettings].
  MpvPropertySpec<DemuxerSettings>.int64(
    name: 'demuxer-max-bytes',
    reactive: r.demuxer,
    parse: (raw, s) => s.settings.demuxer.copyWith(maxBytes: raw),
    reduce: (v, s) => s.copyWith(demuxer: v),
  ),
  MpvPropertySpec<DemuxerSettings>.int64(
    name: 'demuxer-max-back-bytes',
    reactive: r.demuxer,
    parse: (raw, s) => s.settings.demuxer.copyWith(maxBackBytes: raw),
    reduce: (v, s) => s.copyWith(demuxer: v),
  ),
  MpvPropertySpec<DemuxerSettings>.double(
    name: 'demuxer-readahead-secs',
    reactive: r.demuxer,
    parse: (raw, s) =>
        s.settings.demuxer.copyWith(readahead: secondsToDuration(raw)),
    reduce: (v, s) => s.copyWith(demuxer: v),
  ),
  MpvPropertySpec<Duration>.double(
    name: 'network-timeout',
    reactive: r.networkTimeout,
    parse: _toDuration,
    reduce: (v, s) => s.copyWith(networkTimeout: v),
  ),
  MpvPropertySpec<bool>.flag(
    name: 'tls-verify',
    reactive: r.tlsVerify,
    parse: _identityBool,
    reduce: (v, s) => s.copyWith(tlsVerify: v),
  ),
  // `tls-ca-file` is deliberately unobserved: mpv never self-mutates it,
  // so the optimistic write in `setTlsCaFile` is always the truth; an
  // observer would add one more property subscription for zero new
  // information.
  // `hls-bitrate` also accepts a raw numeric rate; an observed number
  // string is not one of the named policies, so `fromMpv` resolves it to
  // its safe default rather than throwing.
  MpvPropertySpec<HlsBitrate>.string(
    name: 'hls-bitrate',
    reactive: r.hlsBitrate,
    parse: (raw, _) => HlsBitrate.fromMpv(raw),
    reduce: (v, s) => s.copyWith(hlsBitrate: v),
  ),
  MpvPropertySpec<bool>.flag(
    name: 'cookies',
    reactive: r.cookies,
    parse: _identityBool,
    reduce: (v, s) => s.copyWith(cookies: v),
  ),
  MpvPropertySpec<String>.string(
    name: 'http-proxy',
    reactive: r.httpProxy,
    parse: _identityString,
    reduce: (v, s) => s.copyWith(httpProxy: v),
  ),
  MpvPropertySpec<bool>.flag(
    name: 'paused-for-cache',
    reactive: r.pausedForCache,
    parse: _identityBool,
    reduce: (v, s) => s.copyWith(pausedForCache: v),
  ),
  MpvPropertySpec<bool>.flag(
    name: 'demuxer-via-network',
    reactive: r.demuxerViaNetwork,
    parse: _identityBool,
    reduce: (v, s) => s.copyWith(demuxerViaNetwork: v),
  ),
];
