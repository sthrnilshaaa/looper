// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The events the event pump hands the player, one per mpv event it consumes,
// and the observe specs of bring-up. Plain Dart: the native pump (an isolate
// over FFI) and the web pump (the main thread over js_interop) produce the
// same events.

import 'dart:typed_data';

/// Base type for every message the event pump forwards to the player after
/// init: one subclass per mpv event the player consumes. The name comes
/// from the native pump, which runs in an isolate of its own.
sealed class MpvIsolateEvent {}

/// A property change the player observes: one subclass per mpv format.
sealed class MpvPropertyEvent extends MpvIsolateEvent {}

/// The answer to an async request of the player.
sealed class MpvReplyEvent extends MpvIsolateEvent {}

/// mpv fired MPV_EVENT_START_FILE: a `loadfile` began opening the
/// next entry (fires even if the open ultimately fails).
class MpvEventStartFile extends MpvIsolateEvent {
  /// The `playlist_entry_id` of the entry mpv opens.
  final int entryId;

  /// Carries the [entryId] of the entry being opened.
  MpvEventStartFile(this.entryId);
}

/// mpv fired MPV_EVENT_FILE_LOADED: the current file is open and its
/// metadata and track list are available.
///
/// Carries every value the player needs at the file-load boundary, read by
/// the event pump right after the event is dequeued. A synchronous property
/// read queues on the core's dispatch and waits for the playloop to serve
/// it, which can take seconds while an audio output initializes (e.g.
/// CoreAudio waking a Bluetooth or AirPlay device). Riding the payload
/// keeps that wait off the main isolate: the native pump waits in its own
/// isolate, the web pump reads asynchronously and holds the later events
/// meanwhile.
class MpvEventFileLoaded extends MpvIsolateEvent {
  /// The playlist entry `path`, applied to the state before the cover and
  /// waveform resets go out. `null` when the read failed.
  final String? path;

  /// Freshly read `playlist` node tree. Applied to the state before the
  /// cover and waveform resets, so a listener pairing them with the current
  /// entry sees the new track: on an auto-advance the observed `playlist`
  /// change reaches the main isolate after this event. `null` when the read
  /// failed.
  final dynamic playlist;

  /// `time-pos` in seconds at load time; `null` when unavailable.
  final double? timePos;

  /// Raw `chapter` index (negative = no chapter active); `null` when the
  /// read failed (no update is applied then, matching a failed poll).
  final int? chapterIndex;

  /// Freshly read `chapter-list` node tree. Read on EVERY file load:
  /// mpv's observer queue dedups on `equal_mpv_value` (see
  /// `player/client.c::send_client_property_changes`), so two consecutive
  /// tracks with structurally-equal chapter lists (e.g. audiobook parts
  /// sharing one chapter pattern) would otherwise skip the PROPERTY_CHANGE
  /// and strand the wrapper on the previous file's chapters. `null` when
  /// the read failed.
  final dynamic chapterList;

  /// Embedded cover art bytes, copied out of mpv-owned memory. `null` when
  /// the file has no embedded cover or the read failed: the player emits
  /// `null` so consumers clear stale artwork.
  final Uint8List? coverData;

  /// MIME type of the cover; `null` when the file has none.
  final String? coverMime;

  /// The embedded cover as the native pump sends it to the main isolate:
  /// the bytes in the transport's own form, which cross without a second
  /// copy. `null` on the web, and once the receiving side has put the
  /// bytes in [coverData] with [withCover], before the player gets the
  /// event.
  final Object? coverTransfer;

  /// Carries the file-load payload; every field is `null`-tolerant so a
  /// partially failed read still delivers the event.
  MpvEventFileLoaded({
    this.path,
    this.playlist,
    this.timePos,
    this.chapterIndex,
    this.chapterList,
    this.coverData,
    this.coverMime,
    this.coverTransfer,
  });

  /// This event with [bytes] as its cover and no [coverTransfer]. `null`
  /// bytes are no cover, and no [coverMime].
  MpvEventFileLoaded withCover(Uint8List? bytes) => MpvEventFileLoaded(
    path: path,
    playlist: playlist,
    timePos: timePos,
    chapterIndex: chapterIndex,
    chapterList: chapterList,
    coverData: bytes,
    coverMime: bytes == null ? null : coverMime,
  );
}

/// mpv fired MPV_EVENT_PLAYBACK_RESTART: the seek (or file load) has
/// finished reinitializing and playback is about to resume.
/// This is the authoritative "seek request is finished" signal.
class MpvEventPlaybackRestart extends MpvIsolateEvent {
  /// `time-pos` in seconds where playback restarted, read by the event
  /// pump at dispatch time so the landing position reaches the stream
  /// ahead of any throttled `time-pos` observer event: without a
  /// synchronous read on the main isolate (which would stall behind a
  /// busy playloop, e.g. during audio-output init). `null` when
  /// unavailable.
  final double? timePos;

  /// Carries the seek's landing [timePos].
  MpvEventPlaybackRestart({this.timePos});
}

/// mpv fired MPV_EVENT_END_FILE: playback of the current entry ended.
class MpvEventEndFile extends MpvIsolateEvent {
  /// The `playlist_entry_id` of the entry that ended, the one its
  /// [MpvEventStartFile] named.
  final int entryId;

  /// The `MPV_END_FILE_REASON_*` code (EOF, stop, error, redirect, …).
  final int reason;

  /// The mpv error code when [reason] is the error reason, else `0`.
  final int error;

  /// Whether the entry that ended is the last one of the playlist, read by
  /// the event pump from mpv's playlist (by entry id, so a playlist
  /// that already moved on cannot mislead it). Only read for the EOF and
  /// error reasons, `false` for the others.
  final bool lastEntry;

  /// The position of the entry when it ended, in seconds: from the event
  /// (patch read_error), else the last `time-pos` mpv reported
  /// for it; `null` when none came.
  final double? position;

  /// The duration of the entry when it ended, in seconds: from the event,
  /// else the last `duration` mpv reported; `null` when none came.
  final double? duration;

  /// Whether the entry stopped on a read error, from the event (patch
  /// read_error). `null` only for an event made in a test.
  final bool? readError;

  /// The HLS or DASH segments the entry lost to errors, from the event;
  /// `null` as for [readError].
  final int? skippedSegments;

  /// Carries the end-of-file [reason] and [error] codes of entry [entryId],
  /// with its last [position] and [duration], and the [readError] and
  /// [skippedSegments] of the event.
  MpvEventEndFile(
    this.entryId,
    this.reason,
    this.error, {
    this.lastEntry = false,
    this.position,
    this.duration,
    this.readError,
    this.skippedSegments,
  });
}

/// Where the core stands against the end of content, read by the event
/// pump in one go: whether the current file reached EOF
/// (`eof-reached`), whether mpv parked on it, and whether it is the last
/// playlist entry. Sent after
/// FILE_LOADED and PLAYBACK_RESTART, and on every `eof-reached`, `pause`
/// (the keep-open park pauses the core), `loop-file` and `loop-playlist`
/// notification. The player derives `completed` from it: the observed
/// `eof-reached` alone gives edges mpv can skip between short entries,
/// matched against a playlist position the main isolate may not have
/// caught up with yet.
class MpvEventEndOfContent extends MpvIsolateEvent {
  /// Whether the current file reached its end (`eof-reached`).
  final bool eof;

  /// Whether mpv parked at the end: [eof] and the core paused, which
  /// keep-open does only once the output buffer has played out. Equal to
  /// [eof] when `keep-open-pause` is off, since no pause comes then.
  final bool parked;

  /// Whether the current file is the last playlist entry.
  final bool lastEntry;

  /// Whether the current entry is a live PCM source (`mak-pcm://`), which
  /// mpv plays once whatever the loop. Read only when [parked].
  final bool live;

  /// `time-pos` read at the park, the position where the file ended. It
  /// rides the event, as on [MpvEventPlaybackRestart], so `completed`
  /// never comes with a throttled position from before the end. Read only
  /// when [parked].
  final double? timePos;

  /// `demuxer-read-error` read at the park: whether the file stopped on a
  /// read error. `null` when the read failed. Read only when [parked].
  final bool? readError;

  /// `demuxer-skipped-segments` read at the park, `null` as for
  /// [readError].
  final int? skippedSegments;

  /// Carries the [eof], [parked], [lastEntry], [live], [timePos],
  /// [readError] and [skippedSegments] reads.
  MpvEventEndOfContent({
    required this.eof,
    required this.parked,
    required this.lastEntry,
    this.live = false,
    this.timePos,
    this.readError,
    this.skippedSegments,
  });
}

/// mpv fired MPV_EVENT_SHUTDOWN: the core is tearing down and the
/// event loop is about to exit.
class MpvEventShutdown extends MpvIsolateEvent {}

/// A `MPV_FORMAT_DOUBLE` property change (e.g. `time-pos`, `volume`).
final class MpvEventPropertyDouble extends MpvPropertyEvent {
  /// The mpv property name that changed.
  final String name;

  /// The new value.
  final double value;

  /// Carries the changed property [name] and its new double [value].
  MpvEventPropertyDouble(this.name, this.value);
}

/// A `MPV_FORMAT_FLAG` or `MPV_FORMAT_INT64` property change, both
/// delivered as a Dart [int].
final class MpvEventPropertyInt extends MpvPropertyEvent {
  /// The mpv property name that changed.
  final String name;

  /// The new value (a flag is `0` or `1`).
  final int value;

  /// Carries the changed property [name] and its new int [value].
  MpvEventPropertyInt(this.name, this.value);
}

/// A `MPV_FORMAT_STRING` property change.
final class MpvEventPropertyString extends MpvPropertyEvent {
  /// The mpv property name that changed.
  final String name;

  /// The new value.
  final String value;

  /// Carries the changed property [name] and its new string [value].
  MpvEventPropertyString(this.name, this.value);
}

/// An observed property that had a value became unavailable
/// (`MPV_FORMAT_NONE`): the file was unloaded, or the new one has no such
/// value. The player returns the matching state field to its seed.
final class MpvEventPropertyUnavailable extends MpvPropertyEvent {
  /// The mpv property name that became unavailable.
  final String name;

  /// Carries the [name] of the property that became unavailable.
  MpvEventPropertyUnavailable(this.name);
}

/// mpv emitted a property change with `MPV_FORMAT_NODE`. [value] is the
/// recursively-decoded tree: `Map<String, dynamic>` for `MPV_FORMAT_NODE_MAP`,
/// `List<dynamic>` for `MPV_FORMAT_NODE_ARRAY`, a primitive (`String`, `int`,
/// `double`, `bool`), `Uint8List` for `MPV_FORMAT_BYTE_ARRAY`, or `null` for
/// an `MPV_FORMAT_NONE` node inside the tree. A property that is NONE
/// itself arrives as [MpvEventPropertyUnavailable].
final class MpvEventPropertyNode extends MpvPropertyEvent {
  /// The mpv property name that changed.
  final String name;

  /// The recursively-decoded node tree (see the class doc for the
  /// possible Dart shapes).
  final dynamic value;

  /// Carries the changed property [name] and its decoded [value] tree.
  MpvEventPropertyNode(this.name, this.value);
}

/// Changes of several properties that back one state cell, held together
/// by the event pump so the cell moves once: each of [events] is an
/// [MpvEventPropertyNode], [MpvEventPropertyString] or
/// [MpvEventPropertyUnavailable], applied in order.
final class MpvEventPropertyGroup extends MpvPropertyEvent {
  /// The held property changes, oldest first.
  final List<MpvIsolateEvent> events;

  /// Carries the held property changes [events].
  MpvEventPropertyGroup(this.events);
}

/// mpv emitted a log line (MPV_EVENT_LOG_MESSAGE) at or above the
/// requested log level.
class MpvEventLog extends MpvIsolateEvent {
  /// The mpv module that produced the line (e.g. `ao`, `ffmpeg`).
  final String prefix;

  /// The mpv log level (`error`, `warn`, `info`, …).
  final String level;

  /// The message text, trailing whitespace stripped.
  final String text;

  /// Carries a single log line's [prefix], [level] and [text].
  MpvEventLog(this.prefix, this.level, this.text);
}

/// A diagnostic of the event pump itself: an event it could not decode,
/// a read that failed. Library-side, so the player puts it on
/// `internalLog`, never on the engine's `log` or `error`.
class MpvEventInternalLog extends MpvIsolateEvent {
  /// The level, as mpv names it (`error`, `warn`).
  final String level;

  /// The message text.
  final String text;

  /// Carries one diagnostic's [level] and [text].
  MpvEventInternalLog(this.level, this.text);
}

/// Outcome of an async property write or command
/// (MPV_EVENT_SET_PROPERTY_REPLY, MPV_EVENT_COMMAND_REPLY). The main
/// isolate matches [userdata] against its pending-reply map and completes
/// the corresponding `Future` with [error].
class MpvEventReply extends MpvReplyEvent {
  /// The `reply_userdata` the request was tagged with.
  final int userdata;

  /// The mpv error code of the request's execution; `0` on success.
  final int error;

  /// A command's decoded result node, `null` for a property write or a
  /// command that returns nothing.
  final Object? result;

  /// Carries the reply's [userdata] tag, [error] code and [result].
  MpvEventReply(this.userdata, this.error, [this.result]);
}

/// Outcome of an async property read (MPV_EVENT_GET_PROPERTY_REPLY),
/// with the value already decoded by the event pump.
class MpvEventGetReply extends MpvReplyEvent {
  /// The `reply_userdata` the request was tagged with.
  final int userdata;

  /// The mpv error code of the read; `0` on success.
  final int error;

  /// The decoded value, in the same Dart shapes as
  /// [MpvEventPropertyNode.value], or `null` when [error] is negative or
  /// the format carried no data.
  final dynamic value;

  /// Carries the reply's [userdata] tag, [error] code and decoded [value].
  MpvEventGetReply(this.userdata, this.error, this.value);
}

/// mpv reached a hook (MPV_EVENT_HOOK) the player registered. The main
/// isolate must acknowledge it via `mpv_hook_continue` so mpv proceeds.
class MpvEventHookFired extends MpvIsolateEvent {
  /// The hook id to pass back to `mpv_hook_continue`.
  final int id;

  /// The hook name (e.g. `on_load`, `on_unload`).
  final String name;

  /// Carries the fired hook's [id] and [name].
  MpvEventHookFired(this.id, this.name);
}

/// Single property to register via `mpv_observe_property` at bring-up.
/// [replyId] is opaque user data; the dispatcher matches by name on the
/// receive side.
class MpvObserveSpec {
  /// mpv property name to observe (e.g. `time-pos`, `pause`).
  final String name;

  /// The `MPV_FORMAT_*` constant the property's value is delivered in.
  final int format;

  /// Opaque user-data tag echoed back on each property change; the
  /// main-side dispatcher matches incoming changes by [name], not this.
  final int replyId;

  /// Describes a single property to register via `mpv_observe_property`.
  const MpvObserveSpec(this.name, this.format, this.replyId);
}
