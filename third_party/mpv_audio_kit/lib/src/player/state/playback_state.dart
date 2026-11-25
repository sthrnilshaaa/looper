// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../../internals/unset_sentinel.dart';
import '../../models/playlist.dart';
import '../../types/enums/loop.dart';

part '../../generated/playback_state_data.dart';

const _kEmptyPlaylist = Playlist.empty;

/// Transport, position and the playlist of the [Player]: what plays, where it is, and how it moves through the queue.
///
/// The [PlayerState.playback] of a player: read it from `player.state.playback`,
/// or follow one value through its stream in `player.stream`.
///
/// {@category State and streams}
final class PlaybackState with _$PlaybackState {
  /// The currently loaded playlist and active track index.
  final Playlist playlist;

  /// Whether the player is currently producing output (not paused, not
  /// buffering, not mid-seek). Mirrors mpv's `core-idle` (inverted):
  /// the *actual-output* axis. It toggles transiently during seeks and
  /// buffering; for a stable play-pause indicator bind to [playWhenReady]
  /// instead.
  final bool playing;

  /// User intent to play: the play-pause axis, set by [Player.play],
  /// [Player.pause], [Player.open] and [Player.stop] (and released at the
  /// natural end of content). Unlike [playing], it does NOT flip during a
  /// seek or while buffering, so it is the correct signal to drive a
  /// play-pause button (including the OS media-session control). "Actually
  /// emitting audio" is `playWhenReady && playing`.
  final bool playWhenReady;

  /// Whether playback has reached the end of the content.
  ///
  /// Becomes `true` at the end of a single track or of the last playlist
  /// entry, where the shipped `keep-open` policy makes mpv park paused on
  /// the last frame. mpv parks once the audio output has played its
  /// buffer, so `completed` comes when the end is heard. [eofReached]
  /// turns `true` earlier, as soon as the decoder is done, about one
  /// output buffer before. It stays `false` between playlist entries and
  /// while `loop-file` or `loop-playlist` is on, except at the end of a
  /// live `PcmSource` entry, which [Loop.file] does not repeat. Resets to
  /// `false` when a new track starts (a fresh [Player.open] or
  /// [Player.openAll], or a playlist advance), when you seek back into the
  /// track, or when a loop is turned on:
  /// [Player.setLoop] then rewinds, paused. Drives
  /// [MpvPlaybackState.completed].
  final bool completed;

  /// Current playback position.
  final Duration position;

  /// Total duration of the current track. Zero when unknown: a live
  /// stream, nothing loaded, or a track still loading.
  ///
  /// When FFmpeg estimated mpv's duration from the bitrate (an MP3 without
  /// a Xing header, ADTS AAC, a length a server guessed) and the entry has
  /// a [Media.waveformDurationHint], it is the hint: such an estimate can
  /// be far off. An exact duration always wins over the hint.
  /// [percentPos] and [timeRemaining] stay mpv's, on its own duration.
  final Duration duration;

  /// Whether [duration] is an estimate FFmpeg made from the bitrate, with
  /// no [Media.waveformDurationHint] to replace it: it can be far off, and
  /// [position] may pass it or stop short of it. `false` for an exact
  /// duration, a hint, or no file. Mirrors mpv's `duration-estimated`.
  final bool durationEstimated;

  /// Whether mpv is currently seeking. Useful as a UI gate to prevent
  /// new seek commands from racing the in-flight one (slider drag
  /// during a long network seek). Mirrors mpv's `seeking`.
  final bool seeking;

  /// Whether the current stream supports seeking at all (live streams
  /// often do not).
  final bool seekable;

  /// Whether the stream is partially seekable: only some ranges are
  /// reachable (typical for HLS or DASH when only a sliding window is
  /// available).
  final bool partiallySeekable;

  /// Playback position as a percentage of the file duration (0 to 100).
  /// Convenience for progress bar UIs that want a single normalized
  /// value rather than `position / duration` math. Mirrors mpv's
  /// `percent-pos`.
  final double percentPos;

  /// Time remaining until the file ends, ignoring playback speed.
  final Duration timeRemaining;

  /// Time remaining until the file ends, adjusted for playback speed:
  /// what the listener will actually wait. At 2.0x speed on a 60 s
  /// remaining file this is 30 s.
  final Duration playtimeRemaining;

  /// Whether playback has reached end-of-file. Distinct from
  /// `completed` (lifecycle flag): `eofReached` mirrors mpv's
  /// `eof-reached` and disambiguates a natural EOF from a user pause.
  final bool eofReached;

  /// Audio frame timestamp at the playhead. Advances per audio frame
  /// (more granular than `position`, which mpv updates on a fixed
  /// schedule) and includes audio driver latency. Useful for
  /// audio-only sync calculations.
  final Duration audioPts;

  /// Index of the active chapter (0-based), or `null` when no chapter
  /// is active or the file has none. Setter: [Player.setChapter].
  final int? currentChapter;

  /// Current loop or repeat mode.
  final Loop loop;

  /// Whether the playlist is in shuffle mode.
  final bool shuffle;

  /// A-B loop start point. `null` when disabled, and again once the file
  /// it was set on ends; a point set with no file loaded stays for every
  /// file. Setter: [Player.setAbLoopA]. Mirrors mpv's `ab-loop-a`.
  final Duration? abLoopA;

  /// A-B loop end point. `null` when disabled, and again once the file it
  /// was set on ends. Setter: [Player.setAbLoopB]. Mirrors mpv's
  /// `ab-loop-b`.
  final Duration? abLoopB;

  /// How many times playback jumps back to A after the first pass, so the
  /// section is heard this count plus one times. `null` = infinite loop
  /// (mpv's `inf`); `0` turns the A-B loop off even with both points set.
  /// Setter: [Player.setAbLoopCount]. Mirrors mpv's `ab-loop-count`.
  final int? abLoopCount;

  /// How many more times playback will jump back to A. `null` only when
  /// the count is infinite; reported even with no points set. It starts
  /// from [abLoopCount] at every load and every change of A, B or the
  /// count, and reads 0 on the last pass. Read-only; mirrors mpv's
  /// `remaining-ab-loops`.
  final int? remainingAbLoops;

  /// Creates a [PlaybackState]; each value defaults to the one of a player that
  /// has loaded nothing.
  const PlaybackState({
    this.playlist = _kEmptyPlaylist,
    this.playing = false,
    this.playWhenReady = false,
    this.completed = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.durationEstimated = false,
    this.seeking = false,
    this.seekable = false,
    this.partiallySeekable = false,
    this.percentPos = 0.0,
    this.timeRemaining = Duration.zero,
    this.playtimeRemaining = Duration.zero,
    this.eofReached = false,
    this.audioPts = Duration.zero,
    this.currentChapter,
    this.loop = Loop.off,
    this.shuffle = false,
    this.abLoopA,
    this.abLoopB,
    this.abLoopCount,
    this.remainingAbLoops,
  });
}
