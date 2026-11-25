// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../../pcm/pcm_native.dart';
import 'mpv_module.dart';

/// The live PCM input of the web module: the `mak_pcm_*` exports, whose
/// 64-bit ids and sizes cross as BigInts. Each call takes the source's
/// mutex for a moment, as natively, so it may run on the main thread.
@internal
final class WebPcmNative implements PcmNative {
  /// The PCM input of module [_m].
  WebPcmNative(this._m);

  final MpvModule _m;

  @override
  int create(int capacityBytes) =>
      bigIntValue(_m.c.pcmCreate(bigInt(capacityBytes)));

  // The bytes are copied into the module's memory for the call: the FIFO
  // copies what it takes before the call returns. Without room for the
  // copy the answer is the native one's, and the source keeps the chunk.
  @override
  int write(int id, Uint8List data) {
    if (data.isEmpty) return 0;
    final int buffer;
    try {
      buffer = _m.malloc(data.length);
    } on WebOutOfMemory {
      return PcmNative.errNoMemory;
    }
    try {
      _m.writeBytes(buffer, data);
      return bigIntValue(
        _m.c.pcmWrite(bigInt(id), buffer, bigInt(data.length)),
      );
    } finally {
      _m.free(buffer);
    }
  }

  @override
  int finish(int id) => _m.c.pcmFinish(bigInt(id));

  @override
  int abort(int id) => _m.c.pcmAbort(bigInt(id));

  @override
  int buffered(int id) => bigIntValue(_m.c.pcmBuffered(bigInt(id)));

  @override
  int state(int id) => _m.c.pcmState(bigInt(id));

  @override
  int release(int id) => _m.c.pcmRelease(bigInt(id));

  @override
  void releaseAll() => _m.c.pcmReleaseAll();
}
