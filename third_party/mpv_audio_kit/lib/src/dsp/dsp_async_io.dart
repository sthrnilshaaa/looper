// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:typed_data';

/// Issues an async mpv property read and resolves with `(errorCode, value)`
/// once the event isolate forwards the reply. The FFI call only enqueues the
/// request — it never waits for the core's playloop — so a DSP pipeline's
/// poll loop can run without a blocking read on the main isolate (the macOS
/// beachball while an audio output initializes). `value` is the same decoded
/// shape the property-change pipeline produces (`Map` / `List` / scalar /
/// [Uint8List]), already copied out of mpv-owned memory in the event isolate.
typedef AsyncPropertyGet = Future<(int, dynamic)> Function(
  String name,
  int format,
);

/// Issues an async mpv property write and resolves with the mpv rc. Used by
/// the listener-gated pipelines to flip their native `*-enabled` flags
/// (waveform / loudness-scan) and the filter-tap active list off the main
/// isolate.
typedef AsyncPropertySet = Future<int> Function(String name, String value);

/// Reinterprets a decoded `MPV_FORMAT_BYTE_ARRAY` value — a [Uint8List] of
/// interleaved, host-order Float32 PCM, the wire format every audio tap emits
/// — as a [Float32List]. Returns `null` for a non-byte value or one too small
/// to hold a single sample.
///
/// Host order == little-endian on every supported target, so the
/// reinterpret is correct without a per-sample loop. A view whose buffer does
/// not start 4-byte-aligned at offset 0 is copied into a fresh aligned buffer
/// first (a `Float32List` view requires alignment).
Float32List? float32FromByteValue(Object? value) {
  if (value is! Uint8List || value.length < 4) return null;
  final n = value.length ~/ 4;
  if (value.offsetInBytes == 0) {
    return value.buffer.asFloat32List(0, n);
  }
  final aligned = Uint8List.fromList(value.sublist(0, n * 4));
  return aligned.buffer.asFloat32List(0, n);
}
