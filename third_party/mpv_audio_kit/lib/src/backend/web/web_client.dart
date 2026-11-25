// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import '../../internals/mpv_requests.dart';
import '../../internals/reply_tracker.dart';
import '../../mpv_constants.dart';
import 'mpv_module.dart';

/// Whether ints and doubles are one type, as when compiled to JavaScript.
const bool _jsNumbers = identical(1, 1.0);

/// The player's asynchronous channel to the core in the web module, the
/// counterpart of the native `MpvClient`: writes, commands and reads go
/// out through the `mpv_*_async` calls of client [_handle], and their
/// replies come back through the web pump ([onReply], [onGetReply]).
///
/// No call waits on the playloop. mpv copies every argument before the
/// call returns, so the strings and nodes built in the module's memory are
/// freed right after it.
@internal
final class WebClient implements MpvRequests {
  /// A client of the core behind [_handle] in module [_m].
  WebClient(this._m, this._handle);

  final MpvModule _m;
  final int _handle;

  // As natively: writes and commands resolve as accepted when drained,
  // reads as failed.
  final ReplyTracker _writes = ReplyTracker(
    drained: (MpvError.mpvErrorSuccess, null),
  );
  final ReplyTracker _reads = ReplyTracker(
    drained: (MpvError.mpvErrorGeneric, null),
  );
  bool _closed = false;

  @override
  Future<int> setProperty(String name, String value) {
    if (_closed) return Future.value(MpvError.mpvErrorSuccess);
    return _send(
      _writes,
      (id) => _m.withStrings([name, value], (p) {
        // MPV_FORMAT_STRING takes a char**.
        final slot = _m.malloc(4);
        try {
          _m.setU32(slot, p[1]);
          return _m.c.mpvSetPropertyAsync(
            _handle,
            bigInt(id),
            p[0],
            MpvFormat.mpvFormatString,
            slot,
          );
        } finally {
          _m.free(slot);
        }
      }),
    ).then((reply) => reply.$1);
  }

  /// The node is built in the module's memory and freed when the call
  /// returns, after mpv copied it. A value outside the shapes of
  /// [MpvRequests.setNodeProperty] throws [ArgumentError].
  @override
  Future<int> setNodeProperty(String name, Object? value) {
    if (_closed) return Future.value(MpvError.mpvErrorSuccess);
    return _send(_writes, (id) {
      final allocations = <int>[];
      try {
        final node = _alloc(allocations, 16);
        _fillNode(node, value, allocations);
        return _m.withStrings(
          [name],
          (p) => _m.c.mpvSetPropertyAsync(
            _handle,
            bigInt(id),
            p[0],
            MpvFormat.mpvFormatNode,
            node,
          ),
        );
      } finally {
        allocations.forEach(_m.free);
      }
    }).then((reply) => reply.$1);
  }

  @override
  Future<(int, Object?)> command(List<String> args) {
    if (_closed) return Future.value((MpvError.mpvErrorSuccess, null));
    return _send(
      _writes,
      (id) => _m.withStrings(args, (p) {
        final array = _m.malloc(4 * (p.length + 1));
        try {
          for (var i = 0; i < p.length; i++) {
            _m.setU32(array + 4 * i, p[i]);
          }
          _m.setU32(array + 4 * p.length, 0);
          return _m.c.mpvCommandAsync(_handle, bigInt(id), array);
        } finally {
          _m.free(array);
        }
      }),
    );
  }

  @override
  Future<(int, Object?)> getProperty(String name, int format) {
    if (_closed) return Future.value((MpvError.mpvErrorGeneric, null));
    return _send(
      _reads,
      (id) => _m.withStrings([
        name,
      ], (p) => _m.c.mpvGetPropertyAsync(_handle, bigInt(id), p[0], format)),
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

  /// Stops every further call from reaching mpv and resolves the pending
  /// requests. Call it once no reply can arrive anymore.
  void close() {
    _closed = true;
    _writes.drain();
    _reads.drain();
  }

  @override
  String errorString(int code) =>
      _m.string(_m.c.mpvErrorString(code)) ?? 'error $code';

  /// `mpv_hook_continue` locks the core, here on the main thread, which
  /// waits for the playloop's next dispatch point. While the core runs a
  /// hook it waits on that dispatch, so the wait is short; the longest one
  /// is kept in [webCallMaxMicros].
  @override
  void hookContinue(int id) {
    if (_closed) return;
    timedCall(
      'mpv_hook_continue',
      () => _m.c.mpvHookContinue(_handle, bigInt(id)),
    );
  }

  @override
  void requestLogMessages(String level) {
    if (_closed) return;
    _m.withStrings([level], (p) => _m.c.mpvRequestLogMessages(_handle, p[0]));
  }

  Future<(int, Object?)> _send(
    ReplyTracker tracker,
    int Function(int id) enqueue,
  ) {
    final (id, reply) = tracker.open();
    int rc;
    try {
      rc = enqueue(id);
    } on WebOutOfMemory {
      // No room for the arguments: mpv's own answer to that.
      rc = MpvError.mpvErrorNomem;
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

  int _alloc(List<int> allocations, int size) {
    final p = _m.malloc(size);
    allocations.add(p);
    return p;
  }

  /// Writes [value] into the 16-byte `mpv_node` at [node], allocating what
  /// it points to and recording it in [allocations].
  void _fillNode(int node, Object? value, List<int> allocations) {
    switch (value) {
      case null:
        _m.setI32(node + 8, MpvFormat.mpvFormatNone);
      case final bool b:
        _m.setI32(node + 8, MpvFormat.mpvFormatFlag);
        _m.setI32(node, b ? 1 : 0);
      // Compiled to JavaScript, 3 and 3.0 are one value and both pass
      // `is int`: every number goes as a double there. The package's only
      // node write, `chapter-list`, holds doubles.
      case final num n when _jsNumbers:
        _m.setI32(node + 8, MpvFormat.mpvFormatDouble);
        _m.setF64(node, n.toDouble());
      case final int i:
        _m.setI32(node + 8, MpvFormat.mpvFormatInt64);
        _m.setI64(node, i);
      case final double d:
        _m.setI32(node + 8, MpvFormat.mpvFormatDouble);
        _m.setF64(node, d);
      case final String s:
        _m.setI32(node + 8, MpvFormat.mpvFormatString);
        final p = _m.newString(s);
        allocations.add(p);
        _m.setU32(node, p);
      case final List<Object?> list:
        _m.setI32(node + 8, MpvFormat.mpvFormatNodeArray);
        _m.setU32(node, _nodeList(list, null, allocations));
      case final Map<String, Object?> map:
        _m.setI32(node + 8, MpvFormat.mpvFormatNodeMap);
        _m.setU32(
          node,
          _nodeList(map.values.toList(), map.keys.toList(), allocations),
        );
      default:
        throw ArgumentError.value(value, 'value', 'not an mpv node value');
    }
  }

  /// The `mpv_node_list` of [values], with [keys] for a map (an array has
  /// none). An empty list points to no values.
  int _nodeList(List<Object?> values, List<String>? keys, List<int> allocs) {
    final list = _alloc(allocs, 12);
    _m.setI32(list, values.length);
    final items = values.isEmpty ? 0 : _alloc(allocs, 16 * values.length);
    final names = keys == null || keys.isEmpty
        ? 0
        : _alloc(allocs, 4 * keys.length);
    _m.setU32(list + 4, items);
    _m.setU32(list + 8, names);
    for (var i = 0; i < values.length; i++) {
      _fillNode(items + 16 * i, values[i], allocs);
      if (keys != null) {
        final p = _m.newString(keys[i]);
        allocs.add(p);
        _m.setU32(names + 4 * i, p);
      }
    }
    return list;
  }
}
