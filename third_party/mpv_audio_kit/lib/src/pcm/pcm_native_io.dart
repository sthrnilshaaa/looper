// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The live PCM input over FFI. Every call takes a mutex for a moment and
// never waits on the reader, so all of them are leaf calls.
@DefaultAsset('package:mpv_audio_kit/libmpv')
library;

import 'dart:ffi';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:meta/meta.dart';

import 'pcm_native.dart';

/// The [PcmNative] of the libmpv at [path], or of the bundled one when
/// [path] is `null`. Throws [UnsupportedError] when that libmpv has no
/// live PCM input (a custom build without the mpv_audio_kit patches).
@internal
PcmNative openNativePcm(String? path) {
  try {
    if (path == null) {
      // @Native symbols resolve on first use: resolve one now, so a libmpv
      // without the patch fails here with a useful message.
      Native.addressOf<NativeFunction<Int64 Function(Int64)>>(_create);
      return const _BundledPcmNative();
    }
    return _LookupPcmNative(DynamicLibrary.open(path));
  } catch (e) {
    throw UnsupportedError(
      'This libmpv has no live PCM input (mak_pcm_create): $e. '
      'It comes with the libmpv release mpv_audio_kit bundles.',
    );
  }
}

final class _BundledPcmNative implements PcmNative {
  const _BundledPcmNative();

  @override
  int create(int capacityBytes) => _create(capacityBytes);

  @override
  int write(int id, Uint8List data) => _write(id, data.address, data.length);

  @override
  int finish(int id) => _finish(id);

  @override
  int abort(int id) => _abort(id);

  @override
  int buffered(int id) => _buffered(id);

  @override
  int state(int id) => _state(id);

  @override
  int release(int id) => _release(id);

  @override
  void releaseAll() => _releaseAll();
}

final class _LookupPcmNative implements PcmNative {
  _LookupPcmNative(DynamicLibrary lib)
    : _c = lib.lookupFunction<Int64 Function(Int64), int Function(int)>(
        'mak_pcm_create',
        isLeaf: true,
      ),
      _w = lib
          .lookupFunction<
            Int64 Function(Int64, Pointer<Uint8>, Int64),
            int Function(int, Pointer<Uint8>, int)
          >('mak_pcm_write', isLeaf: true),
      _f = lib.lookupFunction<Int32 Function(Int64), int Function(int)>(
        'mak_pcm_finish',
        isLeaf: true,
      ),
      _a = lib.lookupFunction<Int32 Function(Int64), int Function(int)>(
        'mak_pcm_abort',
        isLeaf: true,
      ),
      _b = lib.lookupFunction<Int64 Function(Int64), int Function(int)>(
        'mak_pcm_buffered',
        isLeaf: true,
      ),
      _s = lib.lookupFunction<Int32 Function(Int64), int Function(int)>(
        'mak_pcm_state',
        isLeaf: true,
      ),
      _r = lib.lookupFunction<Int32 Function(Int64), int Function(int)>(
        'mak_pcm_release',
        isLeaf: true,
      ),
      _all = lib.lookupFunction<Void Function(), void Function()>(
        'mak_pcm_release_all',
        isLeaf: true,
      );

  final int Function(int) _c;
  final int Function(int, Pointer<Uint8>, int) _w;
  final int Function(int) _f;
  final int Function(int) _a;
  final int Function(int) _b;
  final int Function(int) _s;
  final int Function(int) _r;
  final void Function() _all;

  @override
  int create(int capacityBytes) => _c(capacityBytes);

  // The typed-data address only reaches @Native leaf calls, so this path
  // copies through a native buffer: one block, allocated at the first
  // write and used again by every write of every source. A chunk longer
  // than the block goes in several calls, in order.
  static const int _blockBytes = 64 * 1024;
  Pointer<Uint8> _block = nullptr;

  @override
  int write(int id, Uint8List data) {
    if (data.isEmpty) return 0;
    if (_block == nullptr) _block = malloc<Uint8>(_blockBytes);
    final block = _block.asTypedList(_blockBytes);
    var taken = 0;
    while (taken < data.length) {
      final n = math.min(_blockBytes, data.length - taken);
      block.setRange(0, n, data, taken);
      final rc = _w(id, _block, n);
      // An error after a part was taken: the part counts, and the next
      // write gets the error.
      if (rc < 0) return taken > 0 ? taken : rc;
      taken += rc;
      if (rc < n) break;
    }
    return taken;
  }

  @override
  int finish(int id) => _f(id);

  @override
  int abort(int id) => _a(id);

  @override
  int buffered(int id) => _b(id);

  @override
  int state(int id) => _s(id);

  @override
  int release(int id) => _r(id);

  @override
  void releaseAll() {
    _all();
    if (_block != nullptr) malloc.free(_block);
    _block = nullptr;
  }
}

@Native<Int64 Function(Int64)>(symbol: 'mak_pcm_create', isLeaf: true)
external int _create(int capacityBytes);

@Native<Int64 Function(Int64, Pointer<Uint8>, Int64)>(
  symbol: 'mak_pcm_write',
  isLeaf: true,
)
external int _write(int id, Pointer<Uint8> data, int len);

@Native<Int32 Function(Int64)>(symbol: 'mak_pcm_finish', isLeaf: true)
external int _finish(int id);

@Native<Int32 Function(Int64)>(symbol: 'mak_pcm_abort', isLeaf: true)
external int _abort(int id);

@Native<Int64 Function(Int64)>(symbol: 'mak_pcm_buffered', isLeaf: true)
external int _buffered(int id);

@Native<Int32 Function(Int64)>(symbol: 'mak_pcm_state', isLeaf: true)
external int _state(int id);

@Native<Int32 Function(Int64)>(symbol: 'mak_pcm_release', isLeaf: true)
external int _release(int id);

@Native<Void Function()>(symbol: 'mak_pcm_release_all', isLeaf: true)
external void _releaseAll();
