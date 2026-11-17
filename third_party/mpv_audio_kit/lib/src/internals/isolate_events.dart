// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of 'event_isolate.dart';

// ── Events: isolate → main ───────────────────────────────────────────────────

/// Base type for every message the event isolate forwards to the main
/// isolate after init: one subclass per mpv event the player consumes.
sealed class MpvIsolateEvent {}

/// mpv fired MPV_EVENT_START_FILE — a `loadfile` began opening the
/// next entry (fires even if the open ultimately fails).
class MpvEventStartFile extends MpvIsolateEvent {}

/// mpv fired MPV_EVENT_FILE_LOADED — the current file is open and its
/// metadata / track list is available.
///
/// Carries every value the player needs at the file-load boundary, read by
/// the event isolate right after the event is dequeued. The libmpv client
/// API is synchronous — a property read queues on the core's dispatch and
/// waits for the playloop to serve it, which can take seconds while an
/// audio output initializes (e.g. CoreAudio waking a Bluetooth/AirPlay
/// device). Riding the payload keeps that wait off the main isolate.
class MpvEventFileLoaded extends MpvIsolateEvent {
  /// The playlist entry `path` — keys the waveform / loudness-scan reset
  /// so internal reloads (EDL / gapless / track reinit) of the same source
  /// don't discard a completed envelope, and is applied to the state before
  /// the cover and waveform resets go out. `null` when the read failed.
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

  /// Freshly read `chapter-list` node tree. Read on EVERY file load —
  /// mpv's observer queue dedups on `equal_mpv_value` (see
  /// `player/client.c::send_client_property_changes`), so two consecutive
  /// tracks with structurally-equal chapter lists (e.g. audiobook parts
  /// sharing one chapter pattern) would otherwise skip the PROPERTY_CHANGE
  /// and strand the wrapper on the previous file's chapters. `null` when
  /// the read failed.
  final dynamic chapterList;

  /// Embedded cover art bytes, copied out of mpv-owned memory into a
  /// transferable buffer (zero-copy to materialize on the main isolate).
  /// `null` when the file has no embedded cover or the read failed —
  /// the player emits `null` so consumers clear stale artwork.
  final TransferableTypedData? coverData;

  /// MIME type of [coverData]; `null` iff [coverData] is `null`.
  final String? coverMime;

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
  });
}

/// mpv fired MPV_EVENT_SEEK — a seek request was accepted and playback
/// has been suspended while mpv reinitializes its pipeline.
class MpvEventPlaybackSeek extends MpvIsolateEvent {}

/// mpv fired MPV_EVENT_PLAYBACK_RESTART — the seek (or file load) has
/// finished reinitializing and playback is about to resume.
/// This is the authoritative "seek request is finished" signal.
class MpvEventPlaybackRestart extends MpvIsolateEvent {
  /// `time-pos` in seconds where playback restarted, read by the event
  /// isolate at dispatch time so the landing position reaches the stream
  /// ahead of any throttled `time-pos` observer event — without a
  /// synchronous read on the main isolate (which would stall behind a
  /// busy playloop, e.g. during audio-output init). `null` when
  /// unavailable.
  final double? timePos;

  /// Carries the seek's landing [timePos].
  MpvEventPlaybackRestart({this.timePos});
}

/// mpv fired MPV_EVENT_END_FILE — playback of the current entry ended.
class MpvEndFileEvent extends MpvIsolateEvent {
  /// The `MPV_END_FILE_REASON_*` code (EOF, stop, error, redirect, …).
  final int reason;

  /// The mpv error code when [reason] is the error reason, else `0`.
  final int error;

  /// Carries the end-of-file [reason] and [error] codes.
  MpvEndFileEvent(this.reason, this.error);
}

/// mpv fired MPV_EVENT_SHUTDOWN — the core is tearing down and the
/// event loop is about to exit.
class MpvEventShutdown extends MpvIsolateEvent {}

/// A `MPV_FORMAT_DOUBLE` property change (e.g. `time-pos`, `volume`).
class MpvEventPropertyDouble extends MpvIsolateEvent {
  /// The mpv property name that changed.
  final String name;

  /// The new value.
  final double value;

  /// Carries the changed property [name] and its new double [value].
  MpvEventPropertyDouble(this.name, this.value);
}

/// A `MPV_FORMAT_FLAG` or `MPV_FORMAT_INT64` property change, both
/// delivered as a Dart [int].
class MpvEventPropertyInt extends MpvIsolateEvent {
  /// The mpv property name that changed.
  final String name;

  /// The new value (a flag is `0` / `1`).
  final int value;

  /// Carries the changed property [name] and its new int [value].
  MpvEventPropertyInt(this.name, this.value);
}

/// A `MPV_FORMAT_STRING` property change.
class MpvEventPropertyString extends MpvIsolateEvent {
  /// The mpv property name that changed.
  final String name;

  /// The new value.
  final String value;

  /// Carries the changed property [name] and its new string [value].
  MpvEventPropertyString(this.name, this.value);
}

/// mpv emitted a property change with `MPV_FORMAT_NODE`. [value] is the
/// recursively-decoded tree: `Map<String, dynamic>` for `MPV_FORMAT_NODE_MAP`,
/// `List<dynamic>` for `MPV_FORMAT_NODE_ARRAY`, a primitive (`String`, `int`,
/// `double`, `bool`), `Uint8List` for `MPV_FORMAT_BYTE_ARRAY`, or `null` for
/// `MPV_FORMAT_NONE`.
class MpvEventPropertyNode extends MpvIsolateEvent {
  /// The mpv property name that changed.
  final String name;

  /// The recursively-decoded node tree (see the class doc for the
  /// possible Dart shapes).
  final dynamic value;

  /// Carries the changed property [name] and its decoded [value] tree.
  MpvEventPropertyNode(this.name, this.value);
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

/// Outcome of an async property write or command
/// (MPV_EVENT_SET_PROPERTY_REPLY / MPV_EVENT_COMMAND_REPLY). The main
/// isolate matches [userdata] against its pending-reply map and completes
/// the corresponding `Future` with [error].
class MpvEventReply extends MpvIsolateEvent {
  /// The `reply_userdata` the request was tagged with.
  final int userdata;

  /// The mpv error code of the request's execution; `0` on success.
  final int error;

  /// Carries the reply's [userdata] tag and [error] code.
  MpvEventReply(this.userdata, this.error);
}

/// Outcome of an async property read (MPV_EVENT_GET_PROPERTY_REPLY),
/// with the value already decoded by the event isolate.
class MpvEventGetReply extends MpvIsolateEvent {
  /// The `reply_userdata` the request was tagged with.
  final int userdata;

  /// The mpv error code of the read; `0` on success.
  final int error;

  /// The decoded value — same Dart shapes as [MpvEventPropertyNode.value]
  /// — or `null` when [error] is negative or the format carried no data.
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
