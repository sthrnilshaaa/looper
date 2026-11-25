// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of 'default_specs.dart';

// The specs of the audio params and of the audio output.

/// The audio params, of the decoder side and of the hardware side.
List<MpvPropertySpec<Object?>> _audioParamsSpecs(DefaultPropertyReactives r) =>
    [
      // Aggregate cell shared by three specs. The `audio-params` node
      // carries five of the eight fields; codec and codecName arrive as
      // separate string properties below. Each spec folds its slice via
      // copyWith so the reactive dedups on the full struct, and clears only
      // that slice when its property becomes unavailable.
      MpvPropertySpec<AudioParams>.node(
        name: 'audio-params',
        reactive: r.audioParams,
        parse: (raw, s) {
          final node = parseAudioParamsNode(raw);
          return s.file.audioParams.copyWith(
            format: node.format,
            sampleRate: node.sampleRate,
            channels: node.channels,
            channelCount: node.channelCount,
            hrChannels: node.hrChannels,
          );
        },
        reduce: (v, s) => s.copyWith(audioParams: v),
        unavailable: (s) => s.file.audioParams.copyWith(
          format: null,
          sampleRate: null,
          channels: null,
          channelCount: null,
          hrChannels: null,
        ),
      ),
      // `codec` and `codecName` mirror mpv's two codec properties one-to-one;
      // their content varies across mpv builds (`mp3` vs `mp3float`, `aac`
      // vs `aac_lc`, and the short-vs-descriptive split is not stable
      // either). Treat both fields as opaque hints; see the field-level
      // dartdoc on [AudioParams] for the matching contract.
      MpvPropertySpec<AudioParams>.string(
        name: 'audio-codec',
        reactive: r.audioParams,
        parse: (raw, s) =>
            s.file.audioParams.copyWith(codec: raw.isEmpty ? null : raw),
        reduce: (v, s) => s.copyWith(audioParams: v),
        unavailable: (s) => s.file.audioParams.copyWith(codec: null),
      ),
      MpvPropertySpec<AudioParams>.string(
        name: 'audio-codec-name',
        reactive: r.audioParams,
        parse: (raw, s) =>
            s.file.audioParams.copyWith(codecName: raw.isEmpty ? null : raw),
        reduce: (v, s) => s.copyWith(audioParams: v),
        unavailable: (s) => s.file.audioParams.copyWith(codecName: null),
      ),

      // ── Audio params (hardware side) ─────────────────────────────────────
      MpvPropertySpec<AudioParams>.node(
        name: 'audio-out-params',
        reactive: r.audioOutParamsNode,
        parse: (raw, _) => parseAudioParamsNode(raw),
        reduce: (v, s) => s.copyWith(audioOutParams: v),
      ),
    ];

/// The audio output and its driver, the tracks, the cover art policy, the
/// prefetch and the `audio-output-state` that calls [onAudioOutputState].
List<MpvPropertySpec<Object?>> _outputSpecs(
  DefaultPropertyReactives r,
  void Function(AudioOutputState state) onAudioOutputState,
) => [
  MpvPropertySpec<Duration>.double(
    name: 'audio-buffer',
    reactive: r.audioBuffer,
    parse: _toDuration,
    reduce: (v, s) => s.copyWith(audioBuffer: v),
  ),
  MpvPropertySpec<bool>.flag(
    name: 'audio-exclusive',
    reactive: r.audioExclusive,
    parse: _identityBool,
    reduce: (v, s) => s.copyWith(audioExclusive: v),
  ),
  MpvPropertySpec<bool>.flag(
    name: 'audio-set-media-role',
    reactive: r.audioMediaRole,
    parse: _identityBool,
    reduce: (v, s) => s.copyWith(audioMediaRole: v),
  ),
  MpvPropertySpec<bool>.flag(
    name: 'audio-stream-silence',
    reactive: r.audioStreamSilence,
    parse: _identityBool,
    reduce: (v, s) => s.copyWith(audioStreamSilence: v),
  ),
  MpvPropertySpec<bool>.flag(
    name: 'ao-null-untimed',
    reactive: r.audioNullUntimed,
    parse: _identityBool,
    reduce: (v, s) => s.copyWith(audioNullUntimed: v),
  ),
  // Track inventory + currently-active audio track. mpv exposes these
  // as structured node trees; the typed [MpvTrack] model lets a UI
  // build a "switch audio track" picker without touching `aid` strings.
  MpvPropertySpec<List<MpvTrack>>.node(
    name: 'track-list',
    reactive: r.tracks,
    parse: (raw, _) => parseTrackListNode(raw),
    reduce: (v, s) => s.copyWith(tracks: v),
  ),
  MpvPropertySpec<MpvTrack?>.node(
    name: 'current-tracks/audio',
    reactive: r.currentAudioTrack,
    parse: (raw, _) => parseCurrentTrackNode(raw),
    reduce: (v, s) => s.copyWith(currentAudioTrack: v),
  ),
  MpvPropertySpec<Set<Spdif>>.string(
    name: 'audio-spdif',
    reactive: r.audioSpdif,
    parse: (raw, _) => Spdif.parseMpvList(raw),
    reduce: (v, s) => s.copyWith(audioSpdif: v),
  ),
  MpvPropertySpec<double>.double(
    name: 'volume-max',
    reactive: r.volumeMax,
    parse: _canonicalFloat,
    reduce: (v, s) => s.copyWith(volumeMax: v),
  ),
  MpvPropertySpec<int>.int64(
    name: 'audio-samplerate',
    reactive: r.audioSampleRate,
    parse: _identityInt,
    reduce: (v, s) => s.copyWith(audioSampleRate: v),
  ),
  MpvPropertySpec<Format>.string(
    name: 'audio-format',
    reactive: r.audioFormat,
    parse: (raw, _) => Format.fromMpv(raw),
    reduce: (v, s) => s.copyWith(audioFormat: v),
  ),
  MpvPropertySpec<Channels>.string(
    name: 'audio-channels',
    reactive: r.audioChannels,
    parse: (raw, _) => Channels.fromMpv(raw),
    reduce: (v, s) => s.copyWith(audioChannels: v),
  ),
  MpvPropertySpec<String>.string(
    name: 'audio-client-name',
    reactive: r.audioClientName,
    parse: _identityString,
    reduce: (v, s) => s.copyWith(audioClientName: v),
  ),
  // mpv's `af` property is owned exclusively by `setAudioEffects` and
  // `updateAudioEffects`: the effects chain (raw entries included, as
  // `RawAudioEffect` stages) is the only writer. Raw writes
  // to `af` are rejected by `setRawProperty`, so the property is not
  // observed here.
  MpvPropertySpec<String>.string(
    name: 'ao',
    reactive: r.audioDriver,
    parse: _identityString,
    reduce: (v, s) => s.copyWith(audioDriver: v),
  ),

  // ── Cover art (external file scan policy) ────────────────────────────
  MpvPropertySpec<Cover>.string(
    name: 'cover-art-auto',
    reactive: r.coverArtAuto,
    parse: (raw, _) => Cover.fromMpv(raw),
    reduce: (v, s) => s.copyWith(coverArtAuto: v),
  ),

  // `prefetch-state` is stream-only (no PlayerState field),
  // exposed through `Player.stream.prefetchState`.
  MpvPropertySpec<PrefetchState>.string(
    name: 'prefetch-state',
    reactive: r.prefetchState,
    parse: (raw, _) => PrefetchState.fromMpv(raw),
    reduce: (_, s) => s,
  ),
  // `prefetch-cache-duration` is stream-only (no PlayerState field),
  // exposed through `Player.stream.prefetchCacheDuration`.
  MpvPropertySpec<Duration>.double(
    name: 'prefetch-cache-duration',
    reactive: r.prefetchCacheDuration,
    parse: (raw, _) => Duration(microseconds: (raw * 1e6).round()),
    reduce: (_, s) => s,
  ),
  MpvPropertySpec<AudioOutputState>.string(
    name: 'audio-output-state',
    reactive: r.audioOutputState,
    parse: (raw, _) => AudioOutputState.fromMpv(raw),
    reduce: (v, s) => s.copyWith(audioOutputState: v),
    onChange: onAudioOutputState,
  ),
  MpvPropertySpec<bool>.flag(
    name: 'prefetch-playlist',
    reactive: r.prefetchPlaylist,
    parse: _identityBool,
    reduce: (v, s) => s.copyWith(prefetchPlaylist: v),
  ),
];
