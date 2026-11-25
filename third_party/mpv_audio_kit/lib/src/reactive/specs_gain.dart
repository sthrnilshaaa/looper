// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of 'default_specs.dart';

// The specs of gapless, ReplayGain and the volume gains.

/// Gapless, ReplayGain and the volume gains, of the player and of the
/// system mixer.
List<MpvPropertySpec<Object?>> _gainSpecs(DefaultPropertyReactives r) => [
  MpvPropertySpec<Gapless>.string(
    name: 'gapless-audio',
    reactive: r.gapless,
    parse: (raw, _) => Gapless.fromMpv(raw),
    reduce: (v, s) => s.copyWith(gapless: v),
  ),
  // ── ReplayGain ───────────────────────────────────────────────────────
  // Aggregate cell, same pattern as audio-params above: four specs
  // share one reactive that dedups on the full [ReplayGainSettings].
  MpvPropertySpec<ReplayGainSettings>.string(
    name: 'replaygain',
    reactive: r.replayGain,
    parse: (raw, s) =>
        s.settings.replayGain.copyWith(mode: ReplayGain.fromMpv(raw)),
    reduce: (v, s) => s.copyWith(replayGain: v),
  ),
  MpvPropertySpec<ReplayGainSettings>.double(
    name: 'replaygain-preamp',
    reactive: r.replayGain,
    parse: (raw, s) =>
        s.settings.replayGain.copyWith(preamp: canonicalFloat(raw)),
    reduce: (v, s) => s.copyWith(replayGain: v),
  ),
  MpvPropertySpec<ReplayGainSettings>.double(
    name: 'replaygain-fallback',
    reactive: r.replayGain,
    parse: (raw, s) =>
        s.settings.replayGain.copyWith(fallback: canonicalFloat(raw)),
    reduce: (v, s) => s.copyWith(replayGain: v),
  ),
  MpvPropertySpec<ReplayGainSettings>.flag(
    name: 'replaygain-clip',
    reactive: r.replayGain,
    parse: (raw, s) => s.settings.replayGain.copyWith(clip: raw),
    reduce: (v, s) => s.copyWith(replayGain: v),
  ),
  MpvPropertySpec<double>.double(
    name: 'volume-gain',
    reactive: r.volumeGain,
    parse: _canonicalFloat,
    reduce: (v, s) => s.copyWith(volumeGain: v),
  ),
  MpvPropertySpec<double>.double(
    name: 'volume-gain-min',
    reactive: r.volumeGainMin,
    parse: _canonicalFloat,
    reduce: (v, s) => s.copyWith(volumeGainMin: v),
  ),
  MpvPropertySpec<double>.double(
    name: 'volume-gain-max',
    reactive: r.volumeGainMax,
    parse: _canonicalFloat,
    reduce: (v, s) => s.copyWith(volumeGainMax: v),
  ),
  // System-mixer pair. Unavailable while no audio output is open and on
  // outputs without per-app volume (e.g. the null AO): both go back to
  // their `null` seed then.
  MpvPropertySpec<double?>.double(
    name: 'ao-volume',
    reactive: r.systemVolume,
    parse: (raw, _) => canonicalFloat(raw),
    reduce: (v, s) => s.copyWith(systemVolume: v),
  ),
  MpvPropertySpec<bool?>.flag(
    name: 'ao-mute',
    reactive: r.systemMute,
    parse: (raw, _) => raw,
    reduce: (v, s) => s.copyWith(systemMute: v),
  ),
];
