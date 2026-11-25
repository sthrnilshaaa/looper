// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The client API structs of libmpv the package handles over FFI, with the
// constants and the functions (ffi/mpv_library.dart). The decoder reads
// the payloads of the events at the offsets of
// internals/struct_layout.dart, so their structs live in the tests.

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'mpv_constants.dart';

export 'ffi/mpv_library.dart';
export 'mpv_constants.dart';

// ---------------------------------------------------------------------------
// Opaque handle type
// ---------------------------------------------------------------------------
/// Opaque FFI type for `mpv_handle *`, the client context returned by
/// `mpv_create` and passed to every other client-API call.
final class MpvHandle extends Opaque {}

// ---------------------------------------------------------------------------
// mpv_event  (layout matches mpv.h)
// ---------------------------------------------------------------------------
/// FFI layout of `mpv_event`, the struct returned by `mpv_wait_event`.
final class MpvEvent extends Struct {
  /// The event type, one of the [MpvEventId] constants.
  @Int32()
  external int eventId;

  /// Error code for reply events ([MpvError]); 0 on success.
  @Int32()
  external int error;

  /// The user-data value associated with the originating async request.
  @Uint64()
  external int replyUserdata;

  /// Pointer to the event-specific payload struct (e.g.
  /// `mpv_event_property`), or `nullptr` when the event carries no data.
  external Pointer<Void> data;
}

// ---------------------------------------------------------------------------
// mpv_node & co
// ---------------------------------------------------------------------------

/// FFI layout of `mpv_node`, mpv's tagged-union container for arbitrary
/// property and command values.
final class MpvNode extends Struct {
  /// The value union; the active member is selected by [format].
  external MpvNodeUnion u;

  /// The active union member, one of the [MpvFormat] constants.
  @Int32()
  external int format;
}

/// FFI layout of the `mpv_node` value union (`u`).
final class MpvNodeUnion extends Union {
  /// String value, valid when the node format is `MPV_FORMAT_STRING`.
  external Pointer<Utf8> string;

  /// Boolean flag, valid when the node format is `MPV_FORMAT_FLAG`.
  @Int32()
  external int flag;

  /// Integer value, valid when the node format is `MPV_FORMAT_INT64`.
  @Int64()
  external int int64;

  /// Floating-point value, valid when the node format is `MPV_FORMAT_DOUBLE`.
  @Double()
  external double double_;

  /// List or map contents, valid for `MPV_FORMAT_NODE_ARRAY` or `_NODE_MAP`.
  external Pointer<MpvNodeList> list;

  /// Byte-array contents, valid when the node format is
  /// `MPV_FORMAT_BYTE_ARRAY`.
  external Pointer<MpvByteArray> ba;
}

/// FFI layout of `mpv_node_list`, the backing store for node arrays and maps.
final class MpvNodeList extends Struct {
  /// Number of entries in [values] (and [keys] for maps).
  @Int32()
  external int num;

  /// Pointer to the array of [num] [MpvNode] values.
  external Pointer<MpvNode> values;

  /// Pointer to the array of [num] string keys (maps only); `nullptr` for
  /// arrays.
  external Pointer<Pointer<Utf8>> keys;
}

/// FFI layout of `mpv_byte_array`, a raw byte buffer carried in an [MpvNode].
final class MpvByteArray extends Struct {
  /// Pointer to the raw bytes.
  external Pointer<Void> data;

  /// Number of bytes available at [data].
  @Size()
  external int size;
}
