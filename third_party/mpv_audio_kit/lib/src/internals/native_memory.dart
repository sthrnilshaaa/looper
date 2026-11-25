// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The memory of the cores of this process, as the decoder reads it over
// FFI, and the bytes that cross the isolates.

import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:meta/meta.dart';

import '../mpv_bindings.dart' as mpv;
import 'core_events.dart';
import 'event_decoder.dart';

/// Decodes a NUL-terminated mpv-owned C string, replacing invalid UTF-8
/// sequences with U+FFFD instead of throwing.
///
/// mpv does not guarantee valid UTF-8 on every string it hands to the
/// client API: ICY response headers (`icy-name`, …) are copied into tags
/// verbatim, so a legacy latin-1 radio server delivers raw bytes like
/// `0xE9` here. A strict decode would throw [FormatException] mid-dispatch.
String decodeMpvString(Pointer<Utf8> ptr) {
  final units = ptr.cast<Uint8>();
  var length = 0;
  while (units[length] != 0) {
    length++;
  }
  return utf8.decode(units.asTypedList(length), allowMalformed: true);
}

/// Recursively converts an mpv `mpv_node` C struct into a Dart-native tree.
///
/// Maps:
///   - `MPV_FORMAT_NONE`        → `null`
///   - `MPV_FORMAT_STRING`      → [String]
///   - `MPV_FORMAT_FLAG`        → [bool]
///   - `MPV_FORMAT_INT64`       → [int]
///   - `MPV_FORMAT_DOUBLE`      → [double]
///   - `MPV_FORMAT_NODE_ARRAY`  → `List<dynamic>` of recursively-decoded children
///   - `MPV_FORMAT_NODE_MAP`    → `Map<String, dynamic>` of recursively-decoded children
///   - `MPV_FORMAT_BYTE_ARRAY`  → [Uint8List] copied out of mpv-owned memory,
///     or with [transferBytes] a [TransferableTypedData], which crosses to
///     the main isolate without a second copy (see [materializeBytes])
///
/// The returned tree owns its memory: any data borrowed from mpv (strings,
/// byte arrays) is copied during decoding so the caller can safely dispose
/// of the source `mpv_node` via `mpv_free_node_contents` immediately after.
///
/// Exposed at top-level (rather than file-private) so unit tests can build
/// synthetic `mpv_node` trees and exercise the decoder without spinning up
/// a real player.
Object? decodeMpvNode(
  Pointer<mpv.MpvNode> node, {
  bool transferBytes = false,
}) => decodeNode(nativeMemory, node.address, transfer: transferBytes);

/// The memory of the cores of this process, as [decodeNode] and
/// [dispatchEvent] read it.
@internal
const CoreMemory nativeMemory = _NativeMemory();

final class _NativeMemory implements CoreMemory {
  const _NativeMemory();

  @override
  int get pointerSize => sizeOf<IntPtr>();

  @override
  int i32(int address) => Pointer<Int32>.fromAddress(address).value;

  @override
  int i64(int address) => Pointer<Int64>.fromAddress(address).value;

  @override
  double f64(int address) => Pointer<Double>.fromAddress(address).value;

  @override
  int pointer(int address) => Pointer<UintPtr>.fromAddress(address).value;

  @override
  String? string(int address) =>
      address == 0 ? null : decodeMpvString(Pointer<Utf8>.fromAddress(address));

  @override
  Object bytes(int address, int length, {bool transfer = false}) {
    // Copied out of mpv-owned memory before the caller frees the node. A
    // size_t past the range of an int reads negative: no node of mpv has
    // one, and it fails the decode.
    RangeError.checkNotNegative(length, 'length');
    final view = length == 0
        ? Uint8List(0)
        : Pointer<Uint8>.fromAddress(address).asTypedList(length);
    return transfer
        ? TransferableTypedData.fromList([view])
        : Uint8List.fromList(view);
  }
}

/// Turns the cover a [MpvEventFileLoaded] crossed the isolates with
/// ([MpvEventFileLoaded.coverTransfer], a [TransferableTypedData]) into
/// its bytes, on the receiving isolate. An empty one is no cover. Any
/// other event is returned as it is.
MpvIsolateEvent materializeCover(MpvIsolateEvent event) {
  if (event is! MpvEventFileLoaded) return event;
  final transfer = event.coverTransfer;
  if (transfer is! TransferableTypedData) return event;
  final bytes = transfer.materialize().asUint8List();
  return event.withCover(bytes.isEmpty ? null : bytes);
}

/// Turns the [TransferableTypedData] byte arrays of a get reply back into
/// [Uint8List]s, in place, on the receiving isolate. Maps and lists are
/// walked; other values are returned as they are.
Object? materializeBytes(Object? value) {
  switch (value) {
    case TransferableTypedData():
      return value.materialize().asUint8List();
    case Map<String, dynamic>():
      for (final entry in value.entries.toList(growable: false)) {
        value[entry.key] = materializeBytes(entry.value);
      }
      return value;
    case List<dynamic>():
      for (var i = 0; i < value.length; i++) {
        value[i] = materializeBytes(value[i]);
      }
      return value;
    default:
      return value;
  }
}
