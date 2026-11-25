// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The live PCM input of the bundled libmpv (the `mak-pcm://` stream and its
// `mak_pcm_*` C API, a mpv_audio_kit patch). Every call takes a mutex for a
// moment and never waits on the reader. The calls themselves are in the
// backend: FFI leaf calls natively, the module's exports on the web.

import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../backend/backend.dart' show openPcmNative;
import '../internals/mpv_audio_kit.dart';

/// The native side of a `PcmSource`: one byte FIFO per id, read by mpv
/// through `mak-pcm://<id>`. Negative returns are the codes below.
@internal
abstract interface class PcmNative {
  /// Unknown id.
  static const int errUnknown = -1;

  /// Invalid argument.
  static const int errInvalid = -2;

  /// The source is finished, aborted or released.
  static const int errClosed = -3;

  /// Out of memory.
  static const int errNoMemory = -4;

  // Native state codes of [state].

  /// The source is open and no reader has opened it yet.
  static const int stateOpen = 0;

  /// A reader opened the source.
  static const int stateReading = 1;

  /// [finish] was called; the reader may still be draining.
  static const int stateFinished = 2;

  /// The reader saw the end.
  static const int stateDrained = 3;

  /// [abort] was called.
  static const int stateAborted = 4;

  /// The reader closed before the end (stop, next, dispose).
  static const int stateReaderClosed = 5;

  /// A new source with a soft cap of [capacityBytes]; the id or an error.
  int create(int capacityBytes);

  /// Copies up to the free space of [data]; the bytes taken or an error.
  int write(int id, Uint8List data);

  /// Ends the input: the reader plays what is buffered, then sees the end.
  int finish(int id);

  /// Drops the buffer and ends the reader at once.
  int abort(int id);

  /// Bytes waiting in the FIFO.
  int buffered(int id);

  /// One of the state codes above, or an error.
  int state(int id);

  /// The app side lets go; freed once the reader closed too.
  int release(int id);

  /// Aborts and releases every source in the process.
  void releaseAll();
}

/// The [PcmNative] of the libmpv the players use: the bundled one, or the
/// library at [MpvAudioKit.libraryPath].
///
/// Throws [UnsupportedError] when that libmpv has no live PCM input (a
/// custom build without the mpv_audio_kit patches).
@internal
PcmNative pcmNative() {
  final override = debugPcmNativeOverride;
  if (override != null) return override;
  // The sources live in the library the players use, which
  // ensureInitialized chooses: before it, a source could land in another.
  if (!MpvAudioKit.isInitialized) {
    throw StateError(
      'Call MpvAudioKit.ensureInitialized() before creating a PcmSource.',
    );
  }
  return _native ??= openPcmNative(MpvAudioKit.libraryPath);
}

/// Test-only: replaces the native layer of every new `PcmSource`.
@visibleForTesting
PcmNative? debugPcmNativeOverride;

PcmNative? _native;
