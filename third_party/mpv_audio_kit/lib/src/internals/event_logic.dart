// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../mpv_constants.dart' as mpv;
import 'core_events.dart';

part 'event_end_of_content.dart';
part 'event_properties.dart';

// The event pump's logic, the same on every transport: which events take
// reads of the core and in which order, the payloads they ride, the
// property cache, the end of content. A transport decodes each mpv event
// out of the core's memory, hands it here, and waits for the future a
// dispatch returns before it takes the next event from mpv: the native
// pump reads synchronously on its own isolate, the web pump reads
// asynchronously, and in both the later events stay in mpv's queue
// meanwhile, so the player sees them in the same order.

typedef _Send = void Function(MpvIsolateEvent event);

/// The property the embedded cover of the loaded file is read from.
@internal
const String kEmbeddedCoverProperty = 'embedded-cover-art-data';

/// The value a transport hands [EventLogic.property] when mpv sent the
/// change without data (`MPV_FORMAT_NONE`): the property is unavailable.
@internal
const Object kPropertyUnavailable = _Sentinel('unavailable');

/// The value a transport hands [EventLogic.property] for a format the
/// player does not observe (OSD_STRING, a top-level BYTE_ARRAY).
@internal
const Object kPropertyUnobserved = _Sentinel('unobserved');

final class _Sentinel {
  const _Sentinel(this.name);
  final String name;
  @override
  String toString() => name;
}

/// The bytes of a property in the form a transport sends to another
/// isolate without copying them again. The reader of a pump that runs on
/// its own isolate answers the read of the embedded cover with it, and the
/// receiving side turns [data] back into the bytes.
@internal
final class TransferredBytes {
  /// Wraps [data], the transport's form of the bytes.
  const TransferredBytes(this.data);

  /// The bytes, as the transport sends them.
  final Object data;
}

/// The property reads the event logic takes, in mpv's formats. Each one
/// answers `null` when the read fails, and once the pump was asked to
/// stop: nothing read after a stop reaches the player.
@internal
abstract interface class CoreReader {
  /// [name] as a string (`MPV_FORMAT_STRING`).
  Future<String?> string(String name);

  /// [name] as a double (`MPV_FORMAT_DOUBLE`).
  Future<double?> float(String name);

  /// [name] as an integer (`MPV_FORMAT_INT64`).
  Future<int?> int64(String name);

  /// [name] as a flag (`MPV_FORMAT_FLAG`): 1 or 0.
  Future<int?> flag(String name);

  /// [name] as a decoded node tree (`MPV_FORMAT_NODE`), byte arrays as
  /// [Uint8List]. The embedded cover (`embedded-cover-art-data`) may come
  /// as [TransferredBytes] instead.
  Future<Object?> node(String name);
}

/// The event logic of one core: turns the events a transport decodes into
/// the events the player consumes, through [send].
@internal
final class EventLogic {
  /// The logic of a core that [reader] reads and whose events go to
  /// [send].
  EventLogic(this._reader, this._send);

  final CoreReader _reader;
  final _Send _send;
  late final _PropertyForwarder _properties = _PropertyForwarder(
    _reader,
    _send,
  );
  late final _EndOfContent _endOfContent = _EndOfContent(
    _reader,
    _send,
    _properties,
  );

  _PropertyCache get _cache => _properties.cache;

  /// Registers the observe format of [name], which [property] changes and
  /// the re-read of an unavailable value use.
  void observe(String name, int format) => _cache.formats[name] = format;

  /// How long the pump may wait for the next event: [cap], shortened to the
  /// end of the earliest throttle window while a value is held back.
  double waitSeconds(double cap) => _properties.waitSeconds(cap);

  /// Whether a value is held back for a throttle window or the group, or
  /// a read of the end of content is due.
  bool get holdsValues =>
      _cache.trailing.isNotEmpty ||
      _cache.group.isNotEmpty ||
      _cache.endOfContentAgainAt != null;

  /// What the pump does after every event and whenever its wait ends with
  /// no event: it sends the held values whose window has closed, then
  /// reads the end of content once that is due. Returns the future of that read; the pump waits for it
  /// before the next event.
  Future<void>? idle() {
    _properties.flushTrailing();
    final again = _cache.endOfContentAgainAt;
    if (again == null || _throttleClock.elapsedMilliseconds < again) {
      return null;
    }
    _cache.endOfContentAgainAt = null;
    return _endOfContent.send();
  }

  /// A property change of [name] in [format], with the [value] the
  /// transport decoded, [kPropertyUnavailable] or [kPropertyUnobserved].
  /// Returns a future when the change takes reads (an end-of-content
  /// trigger, the `time-pos` change after a read of it); the pump waits
  /// for it before the next event.
  Future<void>? property(String name, int format, Object? value) {
    if (name == 'time-pos' && _cache.timePosRead) {
      return _properties.forwardFreshTimePos();
    }
    if (name == 'pause') {
      _cache.sentPause = value is int ? value : null;
    } else if (name != 'keep-open-parked') {
      _properties.dispatch(name, format, value);
      if (identical(value, kPropertyUnavailable)) {
        final late = _properties.rereadLate(name);
        if (late != null) {
          return _kEndOfContentTriggers.contains(name)
              ? late.then((_) => _endOfContent.send())
              : late;
        }
      }
    }
    if (_kEndOfContentTriggers.contains(name)) {
      return _endOfContent.send();
    }
    return null;
  }

  /// mpv sent AUDIO_RECONFIG: the audio chain was rebuilt, for a track
  /// switch, a format change or an output reopen. The player takes nothing
  /// from the event itself; the values it left unavailable are read again.
  /// Returns the future of the reads; the pump waits for it before the
  /// next event.
  Future<void> audioReconfig() => _properties.rereadUnavailable();

  /// Any other event, as the transport decoded it: the bare
  /// [MpvEventFileLoaded], [MpvEventPlaybackRestart] and [MpvEventEndFile]
  /// are filled here with the reads they carry. Returns a future when the
  /// event takes reads; the pump waits for it before the next event.
  Future<void>? dispatch(MpvIsolateEvent event) {
    switch (event) {
      case MpvEventStartFile(:final entryId):
        // A clock value held from the previous file must not land after the
        // new one starts.
        _cache.trailing.clear();
        _cache.started = _StartedEntry(entryId);
        _cache.restarted = false;
        _send(event);
      case MpvEventFileLoaded():
        return _fileLoaded();
      case final MpvEventEndFile ended:
        _cache.restarted = false;
        if (ended.reason == mpv.MpvEndFileReason.mpvEndFileReasonEof ||
            ended.reason == mpv.MpvEndFileReason.mpvEndFileReasonError) {
          return _endFile(ended);
        }
        _send(_endFileEvent(ended, lastEntry: false));
      case MpvEventPlaybackRestart():
        return _playbackRestart();
      default:
        _send(event);
    }
    return null;
  }

  // The payload reads run in the pump, not on the main isolate: each one
  // waits for the playloop, and the file-load boundary is exactly the window
  // where the playloop can be stuck for seconds initializing the audio
  // output. A failed payload read must never swallow the event itself:
  // lifecycle, the effects chain check and the waveform re-arm ride it.
  Future<void> _fileLoaded() async {
    MpvEventFileLoaded loaded;
    try {
      loaded = await _readFileLoadedEvent();
    } catch (e, st) {
      _send(
        MpvEventInternalLog('warn', 'file-loaded payload read failed: $e\n$st'),
      );
      loaded = MpvEventFileLoaded();
    }
    // The values mpv has not notified again go first, so the player has
    // them when FILE_LOADED ends the loading state.
    await _properties.rereadUnavailable();
    _send(loaded);
    // A short entry can reach EOF before this event is handled: its
    // `eof-reached` change may already be spent (re-read above, or skipped
    // by mpv), so the end of content is read again after it.
    await _endOfContent.send();
  }

  Future<void> _endFile(MpvEventEndFile ended) async {
    final lastEntry = await _endOfContent.isLastEntry(ended.entryId);
    _send(_endFileEvent(ended, lastEntry: lastEntry));
  }

  /// The END_FILE the transport decoded as [ended], with what mpv reported
  /// of its entry. mpv has unloaded the file by now: the position and
  /// duration come from the event, else from what mpv
  /// reported of the entry since the START_FILE that named it
  /// ([_PropertyCache.started]).
  MpvEventEndFile _endFileEvent(
    MpvEventEndFile ended, {
    required bool lastEntry,
  }) {
    final started = _cache.started;
    final entry = started?.id == ended.entryId ? started : null;
    return MpvEventEndFile(
      ended.entryId,
      ended.reason,
      ended.error,
      lastEntry: lastEntry,
      position: ended.position ?? entry?.position,
      duration: ended.duration ?? entry?.duration,
      readError: ended.readError,
      skippedSegments: ended.skippedSegments,
    );
  }

  // The landing position rides the event payload (read here, where waiting
  // on the core is harmless), so it reaches the stream before any throttled
  // time-pos event from the property observer. A held time-pos from before
  // the seek would land after it and step the position back: drop it. The
  // other clock values keep the newest one mpv sent, which the seek may
  // already have moved.
  Future<void> _playbackRestart() async {
    _cache.trailing.remove('time-pos');
    _properties.flushGroup();
    // Ahead of the event, so a listener of the restart sees `playing`.
    await _properties.forwardCoreIdle();
    _send(MpvEventPlaybackRestart(timePos: await _properties.readTimePos()));
    await _properties.rereadUnavailable();
    _cache.restarted = true;
    await _endOfContent.send();
  }

  /// Reads the file-load payload (path, playlist, position, chapters,
  /// embedded cover) for [MpvEventFileLoaded]. A malformed or oversized
  /// embedded picture must not abort the rest of the payload, so the cover
  /// read is guarded on its own: the event then carries a `null` cover and
  /// consumers clear stale artwork.
  Future<MpvEventFileLoaded> _readFileLoadedEvent() async {
    (Object, String)? cover;
    try {
      cover = await _readEmbeddedCover();
    } catch (_) {
      // Cover stays null; the rest of the payload is still delivered.
    }
    return MpvEventFileLoaded(
      path: await _reader.string('path'),
      playlist: await _reader.node('playlist'),
      timePos: await _properties.readTimePos(),
      chapterIndex: await _reader.int64('chapter'),
      chapterList: await _reader.node('chapter-list'),
      coverData: switch (cover?.$1) {
        final Uint8List bytes => bytes,
        _ => null,
      },
      coverMime: cover?.$2,
      coverTransfer: switch (cover?.$1) {
        TransferredBytes(:final data) => data,
        _ => null,
      },
    );
  }

  /// Reads the embedded cover art of the loaded file via the
  /// `embedded-cover-art-data` and `embedded-cover-art-mime` properties.
  /// Returns `null` when the file has no embedded cover. The bytes are the
  /// original PNG, JPEG or other format as embedded (no decode, no
  /// conversion), copied out of mpv-owned memory by the reader: a
  /// [Uint8List], or the [TransferredBytes] of a pump on its own isolate.
  Future<(Object, String)?> _readEmbeddedCover() async {
    final data = await _reader.node(kEmbeddedCoverProperty);
    final Object cover;
    switch (data) {
      case TransferredBytes():
        cover = data;
      case Uint8List() when data.isNotEmpty:
        cover = data;
      default:
        return null;
    }
    final mime =
        await _reader.string('embedded-cover-art-mime') ??
        'application/octet-stream';
    return (cover, mime);
  }
}
