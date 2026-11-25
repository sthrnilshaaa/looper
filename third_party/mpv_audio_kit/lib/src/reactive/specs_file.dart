// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of 'default_specs.dart';

// The specs of the file, its metadata and its chapters.

/// The file metadata, the buffering depth, the chapters, the paths, the
/// A-B loop and the introspection of the core.
List<MpvPropertySpec<Object?>> _fileSpecs(DefaultPropertyReactives r) => [
  MpvPropertySpec<String>.string(
    name: 'media-title',
    reactive: r.mediaTitle,
    parse: _identityString,
    reduce: (v, s) => s.copyWith(mediaTitle: v),
  ),
  MpvPropertySpec<String>.string(
    name: 'file-format',
    reactive: r.fileFormat,
    parse: _identityString,
    reduce: (v, s) => s.copyWith(fileFormat: v),
  ),
  MpvPropertySpec<int>.int64(
    name: 'file-size',
    reactive: r.fileSize,
    parse: _identityInt,
    reduce: (v, s) => s.copyWith(fileSize: v),
  ),

  // ── Buffering depth ──────────────────────────────────────────────────
  MpvPropertySpec<Duration>.double(
    name: 'demuxer-cache-duration',
    reactive: r.bufferDuration,
    parse: _toDuration,
    reduce: (v, s) => s.copyWith(bufferDuration: v),
  ),
  MpvPropertySpec<bool>.flag(
    name: 'demuxer-cache-idle',
    reactive: r.demuxerIdle,
    parse: _identityBool,
    reduce: (v, s) => s.copyWith(demuxerIdle: v),
  ),

  // ── Chapter navigation ───────────────────────────────────────────────
  // mpv emits `chapter = -1` when no chapter is active; map to `null`.
  MpvPropertySpec<int?>.int64(
    name: 'chapter',
    reactive: r.currentChapter,
    parse: (raw, _) => raw < 0 ? null : raw,
    reduce: (v, s) => s.copyWith(currentChapter: v),
  ),
  MpvPropertySpec<List<Chapter>>.node(
    name: 'chapter-list',
    reactive: r.chapters,
    parse: (raw, _) => parseChapterListNode(raw),
    reduce: (v, s) => s.copyWith(chapters: v),
  ),

  // ── Path and URI introspection (read-only) ───────────────────────────
  MpvPropertySpec<String>.string(
    name: 'path',
    reactive: r.path,
    parse: _identityString,
    reduce: (v, s) => s.copyWith(path: v),
  ),
  MpvPropertySpec<String>.string(
    name: 'filename',
    reactive: r.filename,
    parse: _identityString,
    reduce: (v, s) => s.copyWith(filename: v),
  ),
  MpvPropertySpec<String>.string(
    name: 'stream-path',
    reactive: r.streamPath,
    parse: _identityString,
    reduce: (v, s) => s.copyWith(streamPath: v),
  ),
  MpvPropertySpec<String>.string(
    name: 'playlist-path',
    reactive: r.playlistPath,
    parse: _identityString,
    reduce: (v, s) => s.copyWith(playlistPath: v),
  ),
  MpvPropertySpec<String>.string(
    name: 'stream-open-filename',
    reactive: r.streamOpenFilename,
    parse: _identityString,
    reduce: (v, s) => s.copyWith(streamOpenFilename: v),
  ),

  // ── A-B loop ────────────────────────────────────────────────────────
  // mpv emits `ab-loop-a` and `-b` as STRING (`'no'` when disabled, a
  // numeric string otherwise: `OPT_TIME` with `M_OPT_ALLOW_NO`).
  MpvPropertySpec<Duration?>.string(
    name: 'ab-loop-a',
    reactive: r.abLoopA,
    parse: (raw, _) => _parseAbLoopTime(raw),
    reduce: (v, s) => s.copyWith(abLoopA: v),
  ),
  MpvPropertySpec<Duration?>.string(
    name: 'ab-loop-b',
    reactive: r.abLoopB,
    parse: (raw, _) => _parseAbLoopTime(raw),
    reduce: (v, s) => s.copyWith(abLoopB: v),
  ),
  // `ab-loop-count` is `OPT_CHOICE` with `'inf'=-1` and a non-negative
  // numeric range. We surface it as a nullable int (`null` = inf).
  MpvPropertySpec<int?>.string(
    name: 'ab-loop-count',
    reactive: r.abLoopCount,
    parse: (raw, _) => _parseAbLoopCount(raw),
    reduce: (v, s) => s.copyWith(abLoopCount: v),
  ),
  // Read-only int. `-1` from mpv == infinity; map to `null`.
  MpvPropertySpec<int?>.int64(
    name: 'remaining-ab-loops',
    reactive: r.remainingAbLoops,
    parse: (raw, _) => raw < 0 ? null : raw,
    reduce: (v, s) => s.copyWith(remainingAbLoops: v),
  ),

  // ── Tier 2 introspection ────────────────────────────────────────────
  MpvPropertySpec<bool>.flag(
    name: 'seeking',
    reactive: r.seeking,
    parse: _identityBool,
    reduce: (v, s) => s.copyWith(seeking: v),
  ),
  MpvPropertySpec<double>.double(
    name: 'percent-pos',
    reactive: r.percentPos,
    parse: _identityDouble,
    reduce: (v, s) => s.copyWith(percentPos: v),
  ),
  MpvPropertySpec<double>.double(
    name: 'cache-speed',
    reactive: r.cacheSpeed,
    parse: _identityDouble,
    reduce: (v, s) => s.copyWith(cacheSpeed: v),
  ),
  MpvPropertySpec<int>.int64(
    name: 'cache-buffering-state',
    reactive: r.cacheBufferingState,
    parse: _identityInt,
    reduce: (v, s) => s.copyWith(cacheBufferingState: v),
  ),
  MpvPropertySpec<String>.string(
    name: 'current-demuxer',
    reactive: r.currentDemuxer,
    parse: _identityString,
    reduce: (v, s) => s.copyWith(currentDemuxer: v),
  ),
  MpvPropertySpec<String>.string(
    name: 'current-ao',
    reactive: r.currentAo,
    parse: _identityString,
    reduce: (v, s) => s.copyWith(currentAo: v),
  ),
  MpvPropertySpec<Duration>.double(
    name: 'demuxer-start-time',
    reactive: r.demuxerStartTime,
    parse: _toDuration,
    reduce: (v, s) => s.copyWith(demuxerStartTime: v),
  ),
  MpvPropertySpec<Map<String, String>>.node(
    name: 'chapter-metadata',
    reactive: r.chapterMetadata,
    parse: (raw, _) => _parseStringMap(raw),
    reduce: (v, s) => s.copyWith(chapterMetadata: v),
  ),
  MpvPropertySpec<String>.string(
    name: 'mpv-version',
    reactive: r.mpvVersion,
    parse: _identityString,
    reduce: (v, s) => s.copyWith(mpvVersion: v),
  ),
  MpvPropertySpec<String>.string(
    name: 'ffmpeg-version',
    reactive: r.ffmpegVersion,
    parse: _identityString,
    reduce: (v, s) => s.copyWith(ffmpegVersion: v),
  ),
];
