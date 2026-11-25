// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of 'default_specs.dart';

// The specs of playback and timing.

/// The playback and timing specs, with the `duration` that [hint] combines
/// with the entry's hint and the `idle-active` that calls [onIdleActive].
List<MpvPropertySpec<Object?>> _playbackSpecs(
  DefaultPropertyReactives r,
  DurationHint hint,
  void Function(bool idle) onIdleActive,
) => [
  MpvPropertySpec<Duration>.double(
    name: 'time-pos',
    reactive: r.position,
    parse: _toDuration,
    reduce: (v, s) => s.copyWith(position: v),
  ),
  MpvPropertySpec<Duration>.double(
    name: 'duration',
    reactive: r.duration,
    parse: (raw, s) {
      hint.mpv = secondsToDuration(raw);
      return hint.duration(s);
    },
    unavailable: (s) {
      hint.mpv = Duration.zero;
      return Duration.zero;
    },
    reduce: (v, s) => hint.apply(s),
  ),
  // Combined with `duration` above: its cell holds mpv's flag, and a
  // change of it sets both values and both streams.
  MpvPropertySpec<bool>.flag(
    name: 'duration-estimated',
    reactive: r.mpvDurationEstimated,
    parse: (raw, s) => hint.estimated = raw,
    unavailable: (s) => hint.estimated = false,
    reduce: (v, s) => hint.apply(s),
  ),
  MpvPropertySpec<Duration>.double(
    name: 'demuxer-cache-time',
    reactive: r.buffer,
    parse: _toDuration,
    reduce: (v, s) => s.copyWith(buffer: v),
  ),
  // `state.playback.playing = !core-idle`: `pause` stays `no` from idle into
  // the first file. A file that starts in the playloop iteration the last one
  // ended reports no `core-idle` change, so the event isolate also reads it at
  // every PLAYBACK_RESTART.
  MpvPropertySpec<bool>.flag(
    name: 'core-idle',
    reactive: r.playing,
    parse: (raw, _) => !raw,
    reduce: (playing, s) => s.copyWith(playing: playing),
  ),
  // NOTE: `pause` is deliberately NOT observed here (the event isolate
  // observes it only for its end-of-content read and never forwards
  // it). The intent axis (`playWhenReady`) is driven purely by the
  // play, pause, open and stop call sites (plus the resets at idle and at the
  // end of content): intent changes only on explicit method calls.
  // Observing `pause` would mis-report intent at idle (mpv's
  // `pause` defaults to `no` even when nothing is loaded) and the initial
  // observe burst could race the optimistic set on the first open.
  MpvPropertySpec<double>.double(
    name: 'volume',
    reactive: r.volume,
    parse: _canonicalFloat,
    reduce: (v, s) => s.copyWith(volume: v),
  ),
  MpvPropertySpec<double>.double(
    name: 'speed',
    reactive: r.rate,
    parse: _identityDouble,
    reduce: (v, s) => s.copyWith(rate: v),
  ),
  MpvPropertySpec<double>.double(
    name: 'pitch',
    reactive: r.pitch,
    parse: _identityDouble,
    reduce: (v, s) => s.copyWith(pitch: v),
  ),
  MpvPropertySpec<bool>.flag(
    name: 'mute',
    reactive: r.mute,
    parse: _identityBool,
    reduce: (v, s) => s.copyWith(mute: v),
  ),
  MpvPropertySpec<bool>.flag(
    name: 'idle-active',
    // No state field for idle-active; the side-effect (`onIdleActive`) does
    // the lifecycle work. We still need a reactive for dedup so repeated
    // `true → true` events don't refire the lifecycle helper.
    reactive: ReactiveProperty<bool>(false),
    parse: _identityBool,
    reduce: (_, s) => s,
    onChange: onIdleActive,
  ),
  MpvPropertySpec<bool>.flag(
    name: 'shuffle',
    reactive: r.shuffle,
    parse: _identityBool,
    reduce: (v, s) => s.copyWith(shuffle: v),
  ),
  MpvPropertySpec<bool>.flag(
    name: 'audio-pitch-correction',
    reactive: r.pitchCorrection,
    parse: _identityBool,
    reduce: (v, s) => s.copyWith(pitchCorrection: v),
  ),
  MpvPropertySpec<Duration>.double(
    name: 'audio-delay',
    reactive: r.audioDelay,
    parse: _toDuration,
    reduce: (v, s) => s.copyWith(audioDelay: v),
  ),
  MpvPropertySpec<double?>.double(
    name: 'audio-bitrate',
    reactive: r.audioBitrate,
    parse: (raw, _) => raw > 0 ? raw : null,
    reduce: (v, s) => s.copyWith(audioBitrate: v),
  ),
  // `audio-device` lives outside the registry: the description must
  // cross-reference `state.audioDevices` (parsed from
  // `audio-device-list`), and specs don't have access to that
  // sibling state; the player's custom dispatcher does.
];

/// The extras of the playback timing and the stream capability.
List<MpvPropertySpec<Object?>> _playbackExtraSpecs(
  DefaultPropertyReactives r,
) => [
  MpvPropertySpec<Duration>.double(
    name: 'audio-pts',
    reactive: r.audioPts,
    parse: _toDuration,
    reduce: (v, s) => s.copyWith(audioPts: v),
  ),
  MpvPropertySpec<Duration>.double(
    name: 'time-remaining',
    reactive: r.timeRemaining,
    parse: _toDuration,
    reduce: (v, s) => s.copyWith(timeRemaining: v),
  ),
  MpvPropertySpec<Duration>.double(
    name: 'playtime-remaining',
    reactive: r.playtimeRemaining,
    parse: _toDuration,
    reduce: (v, s) => s.copyWith(playtimeRemaining: v),
  ),
  MpvPropertySpec<bool>.flag(
    name: 'eof-reached',
    reactive: r.eofReached,
    parse: _identityBool,
    reduce: (v, s) => s.copyWith(eofReached: v),
  ),

  // ── Stream capability ────────────────────────────────────────────────
  MpvPropertySpec<bool>.flag(
    name: 'seekable',
    reactive: r.seekable,
    parse: _identityBool,
    reduce: (v, s) => s.copyWith(seekable: v),
  ),
  MpvPropertySpec<bool>.flag(
    name: 'partially-seekable',
    reactive: r.partiallySeekable,
    parse: _identityBool,
    reduce: (v, s) => s.copyWith(partiallySeekable: v),
  ),
];
