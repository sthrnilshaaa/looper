// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../mpv_bindings.dart';
import 'debug_log.dart';
import 'mpv_requests.dart';
import 'reply_tracker.dart';

/// The player's asynchronous channel to libmpv: property writes, commands
/// and property reads go out through the `mpv_*_async` calls, and their
/// replies come back through the event isolate ([onReply], [onGetReply]).
///
/// No call waits on the playloop, so the main isolate never blocks on a
/// busy core. After [close] no call reaches libmpv: the handle is about to
/// be freed, and a continuation resumed by the drain must not touch it.
final class MpvClient implements MpvRequests {
  /// Creates a client for [handle], bound through [lib].
  MpvClient(this._lib, this._handle);

  final MpvLibrary _lib;
  final Pointer<MpvHandle> _handle;

  // Writes and commands resolve as accepted when drained, the behavior of
  // a call racing dispose before the API went async; reads resolve as
  // failed, which surfaces as a `null` value.
  final ReplyTracker _writes = ReplyTracker(
    drained: (MpvError.mpvErrorSuccess, null),
  );
  final ReplyTracker _reads = ReplyTracker(
    drained: (MpvError.mpvErrorGeneric, null),
  );
  bool _closed = false;

  /// Whether [close] was called: no request reaches libmpv any more, and
  /// the calls resolve at once (writes as accepted, reads as failed).
  bool get isClosed => _closed;

  @override
  Future<int> setProperty(String name, String value) {
    if (_closed) return Future.value(MpvError.mpvErrorSuccess);
    return _send(
      _writes,
      (id) => using((arena) {
        final v = arena<Pointer<Utf8>>()
          ..value = value.toNativeUtf8(allocator: arena);
        return _lib.mpvSetPropertyAsync(
          _handle,
          id,
          name.toNativeUtf8(allocator: arena),
          MpvFormat.mpvFormatString,
          v.cast(),
        );
      }),
    ).then((reply) => reply.$1);
  }

  /// The node tree is built in an [Arena], and mpv deep-copies it before
  /// the call returns (`m_option_copy` on the NODE option type), so every
  /// allocation is freed on return. A value outside the shapes of
  /// [MpvRequests.setNodeProperty] throws [ArgumentError].
  @override
  Future<int> setNodeProperty(String name, Object? value) {
    if (_closed) return Future.value(MpvError.mpvErrorSuccess);
    return _send(
      _writes,
      (id) => using((arena) {
        final node = arena<MpvNode>();
        _fillNode(node, value, arena);
        return _lib.mpvSetPropertyAsync(
          _handle,
          id,
          name.toNativeUtf8(allocator: arena),
          MpvFormat.mpvFormatNode,
          node.cast(),
        );
      }),
    ).then((reply) => reply.$1);
  }

  @override
  Future<(int, Object?)> command(List<String> args) {
    if (_closed) return Future.value((MpvError.mpvErrorSuccess, null));
    return _send(
      _writes,
      (id) => using((arena) {
        final arr = arena<Pointer<Utf8>>(args.length + 1);
        for (var i = 0; i < args.length; i++) {
          arr[i] = args[i].toNativeUtf8(allocator: arena);
        }
        arr[args.length] = nullptr;
        return _lib.mpvCommandAsync(_handle, id, arr);
      }),
    );
  }

  @override
  Future<(int, Object?)> getProperty(String name, int format) {
    if (_closed) return Future.value((MpvError.mpvErrorGeneric, null));
    return _send(
      _reads,
      (id) => using(
        (arena) => _lib.mpvGetPropertyAsync(
          _handle,
          id,
          name.toNativeUtf8(allocator: arena),
          format,
        ),
      ),
    );
  }

  /// Resolves the write or command [id] with its reply.
  void onReply(int id, int error, Object? result) =>
      _writes.complete(id, error, result);

  /// Resolves the read [id] with its reply.
  void onGetReply(int id, int error, Object? value) =>
      _reads.complete(id, error, value);

  @override
  Future<void> settleWrites() => _writes.settle();

  /// Stops every further call from reaching libmpv and resolves the
  /// pending requests (see [ReplyTracker.drain]). Call it once no reply
  /// can arrive anymore, right before the handle is freed.
  void close() {
    _closed = true;
    _writes.drain();
    _reads.drain();
  }

  @override
  String errorString(int code) {
    final p = _lib.mpvErrorString(code);
    return p == nullptr ? 'error $code' : p.cast<Utf8>().toDartString();
  }

  @override
  void hookContinue(int id) {
    if (_closed) return;
    final rc = _lib.mpvHookContinue(_handle, id);
    if (rc < 0) debugLog('mpv_audio_kit: hook continue $id refused: rc=$rc');
  }

  /// `mpv_request_log_messages` is thread-safe and works on the shared
  /// client handle, so it needs no round trip through the event isolate.
  @override
  void requestLogMessages(String level) {
    if (_closed) return;
    final rc = using(
      (arena) => _lib.mpvRequestLogMessages(
        _handle,
        level.toNativeUtf8(allocator: arena),
      ),
    );
    if (rc < 0) debugLog('mpv_audio_kit: log level $level refused: rc=$rc');
  }

  Future<(int, Object?)> _send(
    ReplyTracker tracker,
    int Function(int id) enqueue,
  ) {
    final (id, reply) = tracker.open();
    final int rc;
    try {
      rc = enqueue(id);
    } catch (_) {
      // Settle the slot, or settleWrites would wait on it forever.
      tracker.reject(id, MpvError.mpvErrorGeneric);
      rethrow;
    }
    // Rejected client-side (a parse error, a full reply queue): no reply
    // will come.
    if (rc < 0) tracker.reject(id, rc);
    return reply;
  }
}

/// Writes [value] into [node], allocating what it points to in [arena].
void _fillNode(Pointer<MpvNode> node, Object? value, Arena arena) {
  final n = node.ref;
  switch (value) {
    case null:
      n.format = MpvFormat.mpvFormatNone;
    case final bool b:
      n.format = MpvFormat.mpvFormatFlag;
      n.u.flag = b ? 1 : 0;
    case final int i:
      n.format = MpvFormat.mpvFormatInt64;
      n.u.int64 = i;
    case final double d:
      n.format = MpvFormat.mpvFormatDouble;
      n.u.double_ = d;
    case final String s:
      n.format = MpvFormat.mpvFormatString;
      n.u.string = s.toNativeUtf8(allocator: arena);
    case final List<Object?> list:
      n.format = MpvFormat.mpvFormatNodeArray;
      n.u.list = _nodeList(list, null, arena);
    case final Map<String, Object?> map:
      n.format = MpvFormat.mpvFormatNodeMap;
      n.u.list = _nodeList(map.values.toList(), map.keys.toList(), arena);
    default:
      throw ArgumentError.value(value, 'value', 'not an mpv node value');
  }
}

/// The node list of [values], with [keys] for a map (an array has none).
/// An empty list points to no values.
Pointer<MpvNodeList> _nodeList(
  List<Object?> values,
  List<String>? keys,
  Arena arena,
) {
  final list = arena<MpvNodeList>();
  list.ref.num = values.length;
  list.ref.values = values.isEmpty ? nullptr : arena<MpvNode>(values.length);
  list.ref.keys = keys == null || keys.isEmpty
      ? nullptr
      : arena<Pointer<Utf8>>(keys.length);
  for (var i = 0; i < values.length; i++) {
    _fillNode(list.ref.values + i, values[i], arena);
    if (keys != null) list.ref.keys[i] = keys[i].toNativeUtf8(allocator: arena);
  }
  return list;
}
