// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The layout of the client API structs the decoder reads, one table per
// data model, the one source of the offsets: the event decoder reads them,
// the web module is checked against the ilp32 table (web_layout.dart), and
// test/packaging/struct_layout_test.dart holds both tables, and the FFI
// structs, to the structLayout of the pinned manifest. Plain Dart, so the
// web build reads it too.

import 'package:meta/meta.dart';

/// The sizes and offsets of the client API structs of the pinned libmpv
/// for one data model, with the four fields the patch read_error of
/// libmpv-scripts appends to `mpv_event_end_file`.
@internal
final class StructLayout {
  const StructLayout._({
    required this.pointerSize,
    required this.eventSize,
    required this.eventId,
    required this.eventError,
    required this.eventReplyUserdata,
    required this.eventData,
    required this.startFileSize,
    required this.startFileEntryId,
    required this.endFileSize,
    required this.endFileReason,
    required this.endFileError,
    required this.endFileEntryId,
    required this.endFileInsertId,
    required this.endFileInsertNumEntries,
    required this.endFileReadError,
    required this.endFileSkippedSegments,
    required this.endFileDuration,
    required this.endFilePosition,
    required this.propertySize,
    required this.propertyName,
    required this.propertyFormat,
    required this.propertyData,
    required this.logSize,
    required this.logPrefix,
    required this.logLevel,
    required this.logText,
    required this.logLogLevel,
    required this.nodeSize,
    required this.nodeU,
    required this.nodeFormat,
    required this.nodeListSize,
    required this.nodeListNum,
    required this.nodeListValues,
    required this.nodeListKeys,
    required this.byteArraySize,
    required this.byteArrayData,
    required this.byteArraySizeField,
    required this.hookSize,
    required this.hookName,
    required this.hookId,
  });

  /// 64-bit hosts: 8-byte pointers and `size_t`.
  static const StructLayout lp64 = StructLayout._(
    pointerSize: 8,
    eventSize: 24,
    eventId: 0,
    eventError: 4,
    eventReplyUserdata: 8,
    eventData: 16,
    startFileSize: 8,
    startFileEntryId: 0,
    endFileSize: 56,
    endFileReason: 0,
    endFileError: 4,
    endFileEntryId: 8,
    endFileInsertId: 16,
    endFileInsertNumEntries: 24,
    endFileReadError: 28,
    endFileSkippedSegments: 32,
    endFileDuration: 40,
    endFilePosition: 48,
    propertySize: 24,
    propertyName: 0,
    propertyFormat: 8,
    propertyData: 16,
    logSize: 32,
    logPrefix: 0,
    logLevel: 8,
    logText: 16,
    logLogLevel: 24,
    nodeSize: 16,
    nodeU: 0,
    nodeFormat: 8,
    nodeListSize: 24,
    nodeListNum: 0,
    nodeListValues: 8,
    nodeListKeys: 16,
    byteArraySize: 16,
    byteArrayData: 0,
    byteArraySizeField: 8,
    hookSize: 16,
    hookName: 0,
    hookId: 8,
  );

  /// 32-bit ARM and wasm32: 4-byte pointers and `size_t`, and `int64_t`
  /// and `double` aligned to 8.
  static const StructLayout ilp32 = StructLayout._(
    pointerSize: 4,
    eventSize: 24,
    eventId: 0,
    eventError: 4,
    eventReplyUserdata: 8,
    eventData: 16,
    startFileSize: 8,
    startFileEntryId: 0,
    endFileSize: 56,
    endFileReason: 0,
    endFileError: 4,
    endFileEntryId: 8,
    endFileInsertId: 16,
    endFileInsertNumEntries: 24,
    endFileReadError: 28,
    endFileSkippedSegments: 32,
    endFileDuration: 40,
    endFilePosition: 48,
    propertySize: 12,
    propertyName: 0,
    propertyFormat: 4,
    propertyData: 8,
    logSize: 16,
    logPrefix: 0,
    logLevel: 4,
    logText: 8,
    logLogLevel: 12,
    nodeSize: 16,
    nodeU: 0,
    nodeFormat: 8,
    nodeListSize: 12,
    nodeListNum: 0,
    nodeListValues: 4,
    nodeListKeys: 8,
    byteArraySize: 8,
    byteArrayData: 0,
    byteArraySizeField: 4,
    hookSize: 16,
    hookName: 0,
    hookId: 8,
  );

  /// The table for a host whose pointers are [pointerSize] bytes.
  static StructLayout of(int pointerSize) => pointerSize == 8 ? lp64 : ilp32;

  /// The size of a pointer and of a `size_t`.
  final int pointerSize;

  /// `mpv_event`: its size and the offset of each field.
  final int eventSize, eventId, eventError, eventReplyUserdata, eventData;

  /// `mpv_event_start_file`: its size and `playlist_entry_id`.
  final int startFileSize, startFileEntryId;

  /// `mpv_event_end_file`: its size and the fields of mpv.
  final int endFileSize,
      endFileReason,
      endFileError,
      endFileEntryId,
      endFileInsertId,
      endFileInsertNumEntries;

  /// `mpv_event_end_file`: the fields of the patch read_error.
  final int endFileReadError,
      endFileSkippedSegments,
      endFileDuration,
      endFilePosition;

  /// `mpv_event_property`: its size and the offset of each field.
  final int propertySize, propertyName, propertyFormat, propertyData;

  /// `mpv_event_log_message`: its size and the offset of each field.
  final int logSize, logPrefix, logLevel, logText, logLogLevel;

  /// `mpv_node`: its size, its union and its format.
  final int nodeSize, nodeU, nodeFormat;

  /// `mpv_node_list`: its size and the offset of each field.
  final int nodeListSize, nodeListNum, nodeListValues, nodeListKeys;

  /// `mpv_byte_array`: its size, `data` and the `size` field.
  final int byteArraySize, byteArrayData, byteArraySizeField;

  /// `mpv_event_hook`: its size and the offset of each field.
  final int hookSize, hookName, hookId;

  /// The table `mak_web_layout()` of a web module returns, in its order
  /// (scripts/web/mak_web.c of libmpv-scripts): the sizes and the offsets
  /// that are not 0.
  List<int> get webTable => [
    nodeSize,
    nodeFormat,
    nodeListSize,
    nodeListValues,
    nodeListKeys,
    byteArraySize,
    byteArraySizeField,
    eventSize,
    eventError,
    eventReplyUserdata,
    eventData,
    propertySize,
    propertyFormat,
    propertyData,
    logSize,
    logText,
    logLogLevel,
    endFileSize,
    endFileError,
    endFileEntryId,
    endFileInsertId,
    endFileInsertNumEntries,
    endFileReadError,
    endFileSkippedSegments,
    endFileDuration,
    endFilePosition,
    hookSize,
    hookId,
  ];
}
