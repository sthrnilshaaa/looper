// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../models/cover_art.dart';
import '../models/media_session.dart';
import '../player/player_stream.dart';
import '../types/enums/loop.dart';

/// The exact slice of [PlayerStream] that [MediaSessionController]
/// consumes.
///
/// Defining this as a separate type instead of passing the whole
/// [PlayerStream] makes the controller's dependency surface explicit
/// — adding a new subscription means adding a field here, which
/// shows up immediately at the construction site. It also makes the
/// controller cleanly unit-testable: tests build a
/// [MediaSessionInputs] from raw [StreamController]s rather than
/// having to fabricate a full [PlayerStream] (which carries 80+
/// fields the controller does not look at).
@internal
class MediaSessionInputs {
  /// User intent to play, driven by the play/pause/open/stop call sites.
  /// This is the axis the OS play/pause button binds to — stable across
  /// seeks and buffering, so the button never flickers while scrubbing.
  /// (Deliberately NOT `core-idle`, which toggles on every seek.)
  final Stream<bool> playWhenReady;

  /// Actual audio output (`core-idle` inverted). Distinct from
  /// [playWhenReady]: this toggles transiently on seek and goes false during a
  /// buffer stall. The OS button is NOT bound to this (it would flicker); it
  /// drives position extrapolation (only advance the scrubber while audio is
  /// genuinely advancing) and the buffering indication.
  final Stream<bool> playing;

  /// Buffering / loading (cache underrun while intending to play). Surfaced as
  /// a loading state on the OS where supported (Android `STATE_BUFFERING`).
  final Stream<bool> buffering;

  /// Playback rate (mpv `speed`).
  final Stream<double> rate;

  /// Every PLAYBACK_RESTART, irrespective of cause (seek OR file load).
  /// Drives the forced position re-sync to the OS bridge so the slider
  /// snaps to the landed position (e.g. ~0 on a playlist auto-advance).
  /// The OS play/pause button is bound to [playWhenReady] (stable across
  /// seeks), so no seek-transient suppression is needed here.
  final Stream<void> seekCompleted;

  /// Mirrors mpv's `seekable` property — toggles when the OS-visible
  /// scrubber should be enabled (HLS sliding window, live → DVR).
  final Stream<bool> seekable;

  /// Loop mode aggregate (`loop-file` + `loop-playlist`).
  final Stream<Loop> loop;

  /// Shuffle on/off.
  final Stream<bool> shuffle;

  /// Track duration. Drives the OS scrubber's end-of-track marker.
  final Stream<Duration> duration;

  /// Aggregate of mpv's `metadata` tag dict.
  final Stream<Map<String, String>> metadata;

  /// Embedded cover-art payload after each file load (or `null`
  /// when the new file has no embedded picture).
  final Stream<CoverArt?> coverArt;

  /// mpv's `media-title` (falls back to filename for files without
  /// a `title` tag).
  final Stream<String> mediaTitle;

  /// The current [MediaSession] config (override + capability bits)
  /// — `null` when the OS session is disabled.
  final Stream<MediaSession?> mediaSession;

  const MediaSessionInputs({
    required this.playWhenReady,
    required this.playing,
    required this.buffering,
    required this.rate,
    required this.seekCompleted,
    required this.seekable,
    required this.loop,
    required this.shuffle,
    required this.duration,
    required this.metadata,
    required this.coverArt,
    required this.mediaTitle,
    required this.mediaSession,
  });

  /// Convenience builder for the production wiring: pulls the
  /// matching streams off a real [PlayerStream].
  factory MediaSessionInputs.fromPlayer({
    required PlayerStream stream,
  }) =>
      MediaSessionInputs(
        playWhenReady: stream.playWhenReady,
        playing: stream.playing,
        buffering: stream.buffering,
        rate: stream.rate,
        seekCompleted: stream.seekCompleted,
        seekable: stream.seekable,
        loop: stream.loop,
        shuffle: stream.shuffle,
        duration: stream.duration,
        metadata: stream.metadata,
        coverArt: stream.coverArt,
        mediaTitle: stream.mediaTitle,
        mediaSession: stream.mediaSession,
      );
}
