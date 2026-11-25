// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The checks a web module (libmpv.mjs and libmpv.wasm of libmpv-scripts)
// passes before the package makes any other call into it: its ABI version
// and the layout of the client API structs on wasm32. Plain Dart, so the
// rules run on the VM too.

import 'package:meta/meta.dart';

import '../../internals/libmpv_release.dart';
import '../../internals/struct_layout.dart';

/// The `struct` sizes and offsets of the client API on wasm32, in the order
/// of `mak_web_layout()`: the ilp32 table the decoder reads
/// (struct_layout.dart).
final List<int> _kLayout = StructLayout.ilp32.webTable;

/// Checks [version], what the module's `mak_web_abi_version()` returned
/// (`null` for a module without it), against [webModuleAbi].
///
/// Throws [StateError] for a module of another ABI.
@internal
void checkWebModuleAbi(int? version) {
  if (version == webModuleAbi) return;
  final what = version == null ? 'states no ABI version' : 'has ABI $version';
  throw StateError(
    'mpv_audio_kit: the web module $what, and this mpv_audio_kit needs '
    'ABI $webModuleAbi: use the libmpv.mjs, libmpv.wasm and '
    'mak_webaudio_processor.js of the libmpv-$libmpvRelease release',
  );
}

/// Checks [table], the module's `mak_web_layout()` up to its `-1` end,
/// against the layout the decoders read.
///
/// Throws [StateError] when any size or offset differs.
@internal
void checkWebLayout(List<int> table) {
  var ok = table.length == _kLayout.length;
  for (var i = 0; ok && i < _kLayout.length; i++) {
    ok = table[i] == _kLayout[i];
  }
  if (!ok) {
    throw StateError(
      'mpv_audio_kit: the web module lays out the client API structs as '
      '$table, which this mpv_audio_kit does not read',
    );
  }
}
