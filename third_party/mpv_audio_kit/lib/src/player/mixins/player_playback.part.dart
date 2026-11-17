// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// Transport setters: play / pause / stop / seek, chapter navigation,
/// and the A-B loop controls.
mixin _PlaybackModule on _PlayerBase {
  /// Starts or resumes playback. Idempotent: a no-op when already
  /// playing. Returns immediately; the actual `pause=no` round-trip
  /// to mpv settles asynchronously, observable via [PlayerStream.playing].
  Future<void> play() async {
    await _gate();
    // Optimistic intent: `pause` is silent on the first load → playing
    // transition, so set the intent axis here rather than relying on the
    // observer. See [PlayerState.playWhenReady].
    _updateField((s) => s.copyWith(playWhenReady: true),
        _reactives.playWhenReady, true,);
    await _prop('pause', 'no');
  }

  /// Pauses playback. Idempotent: a no-op when already paused. Position
  /// is preserved — call [play] to resume from the same offset.
  Future<void> pause() async {
    await _gate();
    _updateField((s) => s.copyWith(playWhenReady: false),
        _reactives.playWhenReady, false,);
    await _prop('pause', 'yes');
  }

  /// Writes mpv's "watch later" resume config for the current file, saving the
  /// playback position (plus a curated set of audio props) so a later
  /// [Player.open] of the same file resumes from here. Playback continues.
  ///
  /// Pairs with [PlayerConfiguration.resumePlayback] (on by default) and
  /// [PlayerConfiguration.watchLaterDir]. On mobile, set `watchLaterDir` to a
  /// writable path or the write silently fails.
  Future<void> writeResumeConfig() async {
    await _gate();
    await _command(['write-watch-later-config']);
  }

  /// Deletes the "watch later" resume config — for the current file, or for
  /// [filename] when given — clearing any saved resume point.
  Future<void> deleteResumeConfig({String? filename}) async {
    await _gate();
    await _command(filename == null
        ? ['delete-watch-later-config']
        : ['delete-watch-later-config', filename],);
  }

  /// Stops playback and unloads the current file. Distinct from [pause]:
  /// the demuxer is torn down, the playhead is reset, and the next call
  /// must be [open] (not [play]) to start a new track.
  Future<void> stop() async {
    _checkNotDisposed();
    // Claim the load epoch synchronously so an in-flight open() that is
    // still resolving its URI aborts instead of resuming after this call
    // and restarting playback (see [Player.open]).
    _loadEpoch++;
    await _gate();
    // Stop unloads the file; intent returns to "not playing" so the OS
    // button settles on play. mpv may not emit `pause` here, so set it.
    _updateField((s) => s.copyWith(playWhenReady: false),
        _reactives.playWhenReady, false,);
    // Execute in-flight transport writes first — see [_settleWrites].
    await _settleWrites();
    await _command(['stop']);
  }

  /// Seeks playback to a position in the current file.
  ///
  /// With [relative] = `false` (default), [position] is an absolute
  /// timestamp from the start of the file (clamped to `[0, duration]`).
  /// With [relative] = `true`, [position] is a signed offset from the
  /// current playhead — positive moves forward, negative moves backward.
  ///
  /// Examples:
  /// ```dart
  /// await player.seek(const Duration(seconds: 30));                    // jump to 0:30
  /// await player.seek(const Duration(seconds: -10), relative: true);   // skip back 10s
  /// await player.seek(const Duration(seconds: 30), relative: true);    // skip forward 30s
  /// ```
  ///
  /// Throws [MpvException] if mpv rejects the seek — most commonly when
  /// nothing is loaded.
  Future<void> seek(Duration position,
      {bool relative = false, bool exact = false,}) async {
    await _gate();
    final secs = durationToSeconds(position);
    final mode = relative ? 'relative' : 'absolute';
    await _commandChecked(
        ['seek', secs.toStringAsFixed(6), exact ? '$mode+exact' : mode],);
  }

  /// Seeks by percentage of the file duration (0–100). Absolute by default,
  /// or relative to the current percent position when [relative] is true.
  /// [exact] forces a sample-accurate (slower) seek instead of snapping to a
  /// keyframe. Counterpart of [seek] for progress-bar scrubbing.
  Future<void> seekToPercent(double percent,
      {bool relative = false, bool exact = false,}) async {
    await _gate();
    _checkFinite(percent, 'percent');
    final mode = relative ? 'relative-percent' : 'absolute-percent';
    await _commandChecked(
        ['seek', percent.toStringAsFixed(4), exact ? '$mode+exact' : mode],);
  }

  /// Undoes the last [seek] / [seekToPercent], jumping back to the position
  /// before it; calling it again undoes the revert. Works only within the
  /// current file (mpv's `revert-seek`).
  Future<void> revertSeek() async {
    await _gate();
    await _commandChecked(['revert-seek']);
  }

  /// Jumps to the chapter at [index] in the current file.
  ///
  /// Indexing is 0-based and matches [PlayerState.chapters]. mpv handles
  /// out-of-range values (negative or beyond the last chapter) by
  /// clamping; the optimistic [PlayerState.currentChapter] update reflects
  /// the requested value and is corrected by the next observer event.
  Future<void> setChapter(int index) async {
    await _gate();
    await _prop('chapter', index.toString());
    _updateField((s) => s.copyWith(currentChapter: index),
        _reactives.currentChapter, index,);
  }

  /// Replaces the current file's chapter markers with [chapters] — an
  /// "external chapters" injection for sources whose container carries none.
  ///
  /// The canonical case is a resolved YouTube / `googlevideo` audio stream:
  /// YouTube's chapters live in the video description
  /// not in the audio container, so a freshly-loaded stream has an empty
  /// `chapter-list`. This writes the list directly through the stable C API
  /// (`mpv_set_property` on `chapter-list`), so [PlayerStream.chapters] /
  /// [PlayerState.chapters] then reflect them and [setChapter] navigates them
  /// natively — no demuxer chapters required. Pass an empty list to clear.
  ///
  /// Timing: call this AFTER the file is loaded (e.g. on the first
  /// [PlayerStream.duration] event for the track). mpv resets `chapter-list`
  /// to the demuxer's own chapters on each load, so a write issued before the
  /// load settles would be overwritten.
  Future<void> setChapters(List<Chapter> chapters) async {
    await _gate();
    final rc = await _setChapterListNode(chapters);
    if (rc < 0) {
      throw MpvException(
          name: 'chapter-list', code: rc, message: _errorString(rc),);
    }
    // Reflect optimistically; the `chapter-list` observer confirms with mpv's
    // normalized view (e.g. clamped/sorted times) on the next event.
    final list = List<Chapter>.unmodifiable(chapters);
    _updateField((s) => s.copyWith(chapters: list), _reactives.chapters, list);
  }

  // ── A-B loop ───────────────────────────────────────────────────────────────

  /// Sets the A-B loop start point. Pass `null` to disable.
  ///
  /// Combined with [setAbLoopB], creates a playback loop: when the head
  /// crosses the B point, mpv seeks back to A. Common in language-learning
  /// or audiobook apps for repeated practice of a passage.
  Future<void> setAbLoopA(Duration? position) async {
    await _gate();
    await _prop(
        'ab-loop-a',
        position == null
            ? 'no'
            : durationToSeconds(position).toStringAsFixed(6),);
    _updateField(
        (s) => s.copyWith(abLoopA: position), _reactives.abLoopA, position,);
  }

  /// Sets the A-B loop end point. Pass `null` to disable. See [setAbLoopA].
  Future<void> setAbLoopB(Duration? position) async {
    await _gate();
    await _prop(
        'ab-loop-b',
        position == null
            ? 'no'
            : durationToSeconds(position).toStringAsFixed(6),);
    _updateField(
        (s) => s.copyWith(abLoopB: position), _reactives.abLoopB, position,);
  }

  /// Sets the total A-B loop repetitions. Pass `null` for infinite looping
  /// (mpv's `inf`); non-negative int for explicit count. Mirrors mpv's
  /// `--ab-loop-count` option.
  Future<void> setAbLoopCount(int? count) async {
    await _gate();
    if (count != null && count < 0) {
      throw ArgumentError.value(count, 'count', 'must be null (= inf) or >= 0');
    }
    await _prop('ab-loop-count', count == null ? 'inf' : count.toString());
    _updateField(
        (s) => s.copyWith(abLoopCount: count), _reactives.abLoopCount, count,);
  }
}
