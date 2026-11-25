// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:meta/meta.dart';

import '../mpv_bindings.dart' as mpv;
import 'event_logic.dart';
import 'native_memory.dart';

// ── Synchronous property reads (event-isolate side only) ─────────────────────

/// The reads of [EventLogic] as synchronous client calls. They block this
/// isolate until the playloop serves the request: safe here, never on the
/// main isolate. Each one answers null once a stop is requested
/// ([_stopRequested]).
@internal
final class NativeReader implements CoreReader {
  /// Reads the core [_handle] of [_lib], until [_stopFlag] is set.
  NativeReader(this._lib, this._handle, this._stopFlag);

  final mpv.MpvLibrary _lib;
  final Pointer<mpv.MpvHandle> _handle;
  final Pointer<Int32> _stopFlag;

  /// Whether dispose asked this isolate to stop
  /// ([MpvEventIsolate.requestStop]). One event takes up to a dozen
  /// synchronous reads, each a wait on the core. Read after read past the
  /// stop, against a busy core, they outlasted the exit timeout of
  /// [MpvEventIsolate.stop], and
  /// dispose skipped the destroy. Nothing read after a stop reaches the
  /// main isolate anyway: [MpvEventIsolate.stop] closed the port.
  bool get _stopRequested => _stopFlag.value != 0;

  @override
  Future<String?> string(String name) async {
    if (_stopRequested) return null;
    return using<String?>((arena) {
      final n = name.toNativeUtf8(allocator: arena);
      final ptr = _lib.mpvGetPropertyString(_handle, n);
      if (ptr == nullptr) return null;
      final s = decodeMpvString(ptr.cast());
      _lib.mpvFree(ptr.cast());
      return s;
    });
  }

  @override
  Future<double?> float(String name) async {
    if (_stopRequested) return null;
    return using<double?>((arena) {
      final n = name.toNativeUtf8(allocator: arena);
      final buf = arena<Double>();
      final rc = _lib.mpvGetProperty(
        _handle,
        n,
        mpv.MpvFormat.mpvFormatDouble,
        buf.cast(),
      );
      return rc == mpv.MpvError.mpvErrorSuccess ? buf.value : null;
    });
  }

  @override
  Future<int?> int64(String name) async {
    if (_stopRequested) return null;
    return using<int?>((arena) {
      final n = name.toNativeUtf8(allocator: arena);
      final buf = arena<Int64>();
      final rc = _lib.mpvGetProperty(
        _handle,
        n,
        mpv.MpvFormat.mpvFormatInt64,
        buf.cast(),
      );
      return rc == mpv.MpvError.mpvErrorSuccess ? buf.value : null;
    });
  }

  @override
  Future<int?> flag(String name) async {
    if (_stopRequested) return null;
    return using<int?>((arena) {
      final n = name.toNativeUtf8(allocator: arena);
      final buf = arena<Int32>();
      final rc = _lib.mpvGetProperty(
        _handle,
        n,
        mpv.MpvFormat.mpvFormatFlag,
        buf.cast(),
      );
      return rc == mpv.MpvError.mpvErrorSuccess ? buf.value : null;
    });
  }

  @override
  Future<Object?> node(String name) async {
    if (_stopRequested) return null;
    final node = calloc<mpv.MpvNode>();
    try {
      final rc = using(
        (arena) => _lib.mpvGetProperty(
          _handle,
          name.toNativeUtf8(allocator: arena),
          mpv.MpvFormat.mpvFormatNode,
          node.cast(),
        ),
      );
      if (rc < 0) return null;
      // decodeMpvNode copies every borrowed string and byte buffer, so the
      // node contents can be freed before the tree is returned. The cover
      // is megabytes: it is copied once, into the form that crosses to
      // the main isolate as it is (see [materializeCover]).
      if (name == kEmbeddedCoverProperty) {
        final cover = decodeMpvNode(node, transferBytes: true);
        return cover is TransferableTypedData ? TransferredBytes(cover) : cover;
      }
      return decodeMpvNode(node);
    } finally {
      _lib.mpvFreeNodeContents(node);
      calloc.free(node);
    }
  }
}
