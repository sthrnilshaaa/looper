// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The one decoder of mpv events, for both transports: the native pump reads
// the core's memory over FFI, the web pump the module's memory over
// js_interop, and both hand this file the addresses. Plain Dart, so the
// rules run on the VM for both layouts.

import 'package:meta/meta.dart';

import '../mpv_constants.dart';
import 'core_events.dart';
import 'event_logic.dart';
import 'struct_layout.dart';

/// The memory of a core, as the decoder reads it: the values at an
/// address, little-endian.
@internal
abstract interface class CoreMemory {
  /// The size of a pointer and of a `size_t`: 8 on a 64-bit host, 4 on
  /// wasm32 and on 32-bit ARM.
  int get pointerSize;

  /// The `int32_t` at [address].
  int i32(int address);

  /// The `int64_t` at [address].
  int i64(int address);

  /// The `double` at [address].
  double f64(int address);

  /// The pointer, or the `size_t`, at [address].
  int pointer(int address);

  /// The UTF-8 C string that starts at [address], `null` for 0.
  String? string(int address);

  /// A copy of the [length] bytes at [address], out of the core's memory
  /// before mpv frees it. With [transfer], in the form the transport
  /// sends to another isolate at the cost of one copy.
  Object bytes(int address, int length, {bool transfer = false});
}

/// What one mpv event asks of [EventLogic]: an event to dispatch, a
/// property change, or an audio reconfig.
@internal
sealed class DecodedEvent {}

/// An event [EventLogic.dispatch] takes.
@internal
final class Dispatch extends DecodedEvent {
  /// Wraps [event].
  Dispatch(this.event);

  /// The event.
  final MpvIsolateEvent event;
}

/// A change of an observed property, as [EventLogic.property] takes it.
@internal
final class PropertyChange extends DecodedEvent {
  /// The change of [name] in [format] to [value].
  PropertyChange(this.name, this.format, this.value);

  /// The property.
  final String name;

  /// The format it was observed in.
  final int format;

  /// Its value, [kPropertyUnavailable] or [kPropertyUnobserved].
  final Object? value;
}

/// MPV_EVENT_AUDIO_RECONFIG, which [EventLogic.audioReconfig] handles.
@internal
final class AudioReconfig extends DecodedEvent {}

/// Decodes the `mpv_event` at [event] out of [m], and hands it to [logic].
/// Returns the future of the reads the event takes, if any. The payload is
/// valid only until the next `mpv_wait_event`: everything is copied before
/// this returns.
@internal
Future<void>? dispatchEvent(EventLogic logic, CoreMemory m, int event) =>
    switch (decodeEvent(m, event)) {
      null => null,
      Dispatch(:final event) => logic.dispatch(event),
      PropertyChange(:final name, :final format, :final value) =>
        logic.property(name, format, value),
      AudioReconfig() => logic.audioReconfig(),
    };

/// The `mpv_event` at [event] in [m], decoded; `null` for an event the
/// player does not take.
///
/// The offsets are those of the [StructLayout] for the pointer size of [m].
@internal
DecodedEvent? decodeEvent(CoreMemory m, int event) {
  final l = StructLayout.of(m.pointerSize);
  return _decoders[m.i32(event + l.eventId)]?.call(m, l, event);
}

/// The `error` of the event at [e].
int _error(CoreMemory m, StructLayout l, int e) => m.i32(e + l.eventError);

/// The `reply_userdata` of the event at [e].
int _userdata(CoreMemory m, StructLayout l, int e) =>
    m.i64(e + l.eventReplyUserdata);

/// The `data` of the event at [e].
int _data(CoreMemory m, StructLayout l, int e) => m.pointer(e + l.eventData);

/// One decoder for each event the player takes, by event id.
final Map<int, DecodedEvent Function(CoreMemory, StructLayout, int)> _decoders =
    {
      MpvEventId.mpvEventPropertyChange: _propertyChange,
      MpvEventId.mpvEventShutdown: (_, _, _) => Dispatch(MpvEventShutdown()),
      MpvEventId.mpvEventStartFile: (m, l, e) => Dispatch(
        MpvEventStartFile(m.i64(_data(m, l, e) + l.startFileEntryId)),
      ),
      MpvEventId.mpvEventFileLoaded: (_, _, _) =>
          Dispatch(MpvEventFileLoaded()),
      MpvEventId.mpvEventEndFile: (m, l, e) =>
          Dispatch(_endFile(m, l, _data(m, l, e))),
      MpvEventId.mpvEventAudioReconfig: (_, _, _) => AudioReconfig(),
      MpvEventId.mpvEventSetPropertyReply: (m, l, e) =>
          Dispatch(MpvEventReply(_userdata(m, l, e), _error(m, l, e))),
      MpvEventId.mpvEventCommandReply: _commandReply,
      MpvEventId.mpvEventGetPropertyReply: _getReply,
      MpvEventId.mpvEventLogMessage: _log,
      MpvEventId.mpvEventHook: (m, l, e) => Dispatch(
        MpvEventHookFired(
          m.i64(_data(m, l, e) + l.hookId),
          m.string(m.pointer(_data(m, l, e) + l.hookName)) ?? '',
        ),
      ),
      MpvEventId.mpvEventPlaybackRestart: (_, _, _) =>
          Dispatch(MpvEventPlaybackRestart()),
    };

DecodedEvent _propertyChange(CoreMemory m, StructLayout l, int e) {
  final data = _data(m, l, e);
  final format = m.i32(data + l.propertyFormat);
  return PropertyChange(
    m.string(m.pointer(data + l.propertyName)) ?? '',
    format,
    _changeValue(m, format, m.pointer(data + l.propertyData)),
  );
}

/// An `mpv_event_command`, whose only member is the `mpv_node result`
/// (`loadfile` returns `playlist_entry_id` in it).
DecodedEvent _commandReply(CoreMemory m, StructLayout l, int e) {
  final error = _error(m, l, e);
  final data = _data(m, l, e);
  final result = error >= 0 && data != 0 ? decodeNode(m, data) : null;
  return Dispatch(MpvEventReply(_userdata(m, l, e), error, result));
}

DecodedEvent _getReply(CoreMemory m, StructLayout l, int e) {
  final error = _error(m, l, e);
  final value = error >= 0 ? propertyValue(m, _data(m, l, e)) : null;
  return Dispatch(MpvEventGetReply(_userdata(m, l, e), error, value));
}

/// An `mpv_event_log_message`: the prefix, the level and the text.
DecodedEvent _log(CoreMemory m, StructLayout l, int e) {
  final data = _data(m, l, e);
  String text(int offset) => m.string(m.pointer(data + offset)) ?? '';
  return Dispatch(
    MpvEventLog(
      text(l.logPrefix),
      text(l.logLevel),
      text(l.logText).trimRight(),
    ),
  );
}

/// The `mpv_event_end_file` at [data]. A duration or position mpv did not
/// know (-1) is `null`, and the event logic keeps what mpv reported of the
/// entry before.
MpvEventEndFile _endFile(CoreMemory m, StructLayout l, int data) {
  double? known(double seconds) => seconds >= 0 ? seconds : null;
  return MpvEventEndFile(
    m.i64(data + l.endFileEntryId),
    m.i32(data + l.endFileReason),
    m.i32(data + l.endFileError),
    readError: m.i32(data + l.endFileReadError) != 0,
    skippedSegments: m.i64(data + l.endFileSkippedSegments),
    duration: known(m.f64(data + l.endFileDuration)),
    position: known(m.f64(data + l.endFilePosition)),
  );
}

/// The value of a property change as [EventLogic.property] takes it.
Object? _changeValue(CoreMemory m, int format, int data) {
  if (format == MpvFormat.mpvFormatNone || data == 0) {
    return kPropertyUnavailable;
  }
  return switch (format) {
    MpvFormat.mpvFormatDouble ||
    MpvFormat.mpvFormatFlag ||
    MpvFormat.mpvFormatInt64 ||
    MpvFormat.mpvFormatString ||
    MpvFormat.mpvFormatNode => _value(m, format, data, transfer: false),
    _ => kPropertyUnobserved,
  };
}

/// The value of the `mpv_event_property` at [property], as a read carries
/// it; `null` without one. The byte arrays of a node come in the form the
/// transport sends on: the polled PCM, tap and waveform frames are copied
/// once.
@internal
Object? propertyValue(CoreMemory m, int property) {
  if (property == 0) return null;
  final l = StructLayout.of(m.pointerSize);
  final data = m.pointer(property + l.propertyData);
  if (data == 0) return null;
  return _value(m, m.i32(property + l.propertyFormat), data, transfer: true);
}

/// The value of format [format] at [data]: a flag as an int.
Object? _value(CoreMemory m, int format, int data, {required bool transfer}) =>
    switch (format) {
      MpvFormat.mpvFormatDouble => m.f64(data),
      MpvFormat.mpvFormatFlag => m.i32(data),
      MpvFormat.mpvFormatInt64 => m.i64(data),
      MpvFormat.mpvFormatString => m.string(m.pointer(data)),
      MpvFormat.mpvFormatNode => decodeNode(m, data, transfer: transfer),
      _ => null,
    };

/// The `mpv_node` at [node], as a Dart tree: a string, a bool for a flag,
/// an int, a double, a list, a map with string keys, or the bytes of a
/// byte array ([CoreMemory.bytes], sent on as is with [transfer]). `null`
/// for any other format. Everything is copied, so mpv can free the node
/// right after.
///
/// The offsets of `mpv_node`, `mpv_node_list` and `mpv_byte_array` are
/// those of the [StructLayout] for the pointer size of [m].
@internal
Object? decodeNode(CoreMemory m, int node, {bool transfer = false}) =>
    _node(m, StructLayout.of(m.pointerSize), node, transfer);

Object? _node(CoreMemory m, StructLayout l, int node, bool transfer) {
  final u = node + l.nodeU;
  switch (m.i32(node + l.nodeFormat)) {
    case MpvFormat.mpvFormatString:
      return m.string(m.pointer(u));
    case MpvFormat.mpvFormatFlag:
      return m.i32(u) != 0;
    case MpvFormat.mpvFormatInt64:
      return m.i64(u);
    case MpvFormat.mpvFormatDouble:
      return m.f64(u);
    case MpvFormat.mpvFormatNodeArray:
      return _nodeArray(m, l, m.pointer(u), transfer);
    case MpvFormat.mpvFormatNodeMap:
      return _nodeMap(m, l, m.pointer(u), transfer);
    case MpvFormat.mpvFormatByteArray:
      final ba = m.pointer(u);
      return m.bytes(
        m.pointer(ba + l.byteArrayData),
        m.pointer(ba + l.byteArraySizeField),
        transfer: transfer,
      );
  }
  return null;
}

/// The `mpv_node_list` at [list] of an array.
List<Object?> _nodeArray(
  CoreMemory m,
  StructLayout l,
  int list,
  bool transfer,
) {
  final values = m.pointer(list + l.nodeListValues);
  final count = m.i32(list + l.nodeListNum);
  return [
    for (var i = 0; i < count; i++)
      _node(m, l, values + l.nodeSize * i, transfer),
  ];
}

/// The `mpv_node_list` at [list] of a map, its keys after its values.
Map<String, dynamic> _nodeMap(
  CoreMemory m,
  StructLayout l,
  int list,
  bool transfer,
) {
  final values = m.pointer(list + l.nodeListValues);
  final keys = m.pointer(list + l.nodeListKeys);
  final count = m.i32(list + l.nodeListNum);
  return <String, dynamic>{
    for (var i = 0; i < count; i++)
      m.string(m.pointer(keys + l.pointerSize * i)) ?? '': _node(
        m,
        l,
        values + l.nodeSize * i,
        transfer,
      ),
  };
}
