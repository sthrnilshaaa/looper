// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
// The libmpv the build hook bundles (hook/build.dart), which every @Native
// declaration below binds to. Leaf calls follow the rule of MpvLibrary:
// only the documented non-blocking, callback-free ones.
@DefaultAsset('package:mpv_audio_kit/libmpv')
library;

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:meta/meta.dart';

import '../mpv_bindings.dart';

/// Resolves one symbol of the bundled libmpv now: @Native symbols resolve
/// on first use, and a missing asset then fails here, with its error.
@internal
void resolveBundledMpv() {
  Native.addressOf<NativeFunction<Pointer<MpvHandle> Function()>>(_mpvCreate);
}

/// The [MpvLibrary] of the libmpv the build hook bundles with the app:
/// each call is a static call of its @Native declaration.
@internal
final class BundledMpvLibrary implements MpvLibrary {
  /// The bundled libmpv.
  const BundledMpvLibrary();

  @override
  Pointer<MpvHandle> mpvCreate() => _mpvCreate();

  @override
  int mpvInitialize(Pointer<MpvHandle> ctx) => _mpvInitialize(ctx);

  @override
  void mpvTerminateDestroy(Pointer<MpvHandle> ctx) => _mpvTerminateDestroy(ctx);

  @override
  void mpvWakeup(Pointer<MpvHandle> ctx) => _mpvWakeup(ctx);

  @override
  int mpvSetOptionString(
    Pointer<MpvHandle> ctx,
    Pointer<Utf8> name,
    Pointer<Utf8> data,
  ) => _mpvSetOptionString(ctx, name, data);

  @override
  int mpvSetPropertyString(
    Pointer<MpvHandle> ctx,
    Pointer<Utf8> name,
    Pointer<Utf8> data,
  ) => _mpvSetPropertyString(ctx, name, data);

  @override
  Pointer<Utf8> mpvGetPropertyString(
    Pointer<MpvHandle> ctx,
    Pointer<Utf8> name,
  ) => _mpvGetPropertyString(ctx, name);

  @override
  int mpvGetProperty(
    Pointer<MpvHandle> ctx,
    Pointer<Utf8> name,
    int format,
    Pointer<Void> data,
  ) => _mpvGetProperty(ctx, name, format, data);

  @override
  int mpvSetPropertyAsync(
    Pointer<MpvHandle> ctx,
    int replyUserdata,
    Pointer<Utf8> name,
    int format,
    Pointer<Void> data,
  ) => _mpvSetPropertyAsync(ctx, replyUserdata, name, format, data);

  @override
  int mpvGetPropertyAsync(
    Pointer<MpvHandle> ctx,
    int replyUserdata,
    Pointer<Utf8> name,
    int format,
  ) => _mpvGetPropertyAsync(ctx, replyUserdata, name, format);

  @override
  int mpvCommandAsync(
    Pointer<MpvHandle> ctx,
    int replyUserdata,
    Pointer<Pointer<Utf8>> args,
  ) => _mpvCommandAsync(ctx, replyUserdata, args);

  @override
  int mpvCommandString(Pointer<MpvHandle> ctx, Pointer<Utf8> args) =>
      _mpvCommandString(ctx, args);

  @override
  Pointer<MpvEvent> mpvWaitEvent(Pointer<MpvHandle> ctx, double timeout) =>
      _mpvWaitEvent(ctx, timeout);

  @override
  int mpvObserveProperty(
    Pointer<MpvHandle> ctx,
    int replyUserdata,
    Pointer<Utf8> name,
    int format,
  ) => _mpvObserveProperty(ctx, replyUserdata, name, format);

  @override
  void mpvFree(Pointer<Void> data) => _mpvFree(data);

  @override
  void mpvFreeNodeContents(Pointer<MpvNode> node) => _mpvFreeNodeContents(node);

  @override
  Pointer<Utf8> mpvErrorString(int error) => _mpvErrorString(error);

  @override
  int mpvRequestLogMessages(Pointer<MpvHandle> ctx, Pointer<Utf8> minLevel) =>
      _mpvRequestLogMessages(ctx, minLevel);

  @override
  int mpvHookAdd(
    Pointer<MpvHandle> ctx,
    int replyUserdata,
    Pointer<Utf8> name,
    int priority,
  ) => _mpvHookAdd(ctx, replyUserdata, name, priority);

  @override
  int mpvHookContinue(Pointer<MpvHandle> ctx, int id) =>
      _mpvHookContinue(ctx, id);
}

@Native<Pointer<MpvHandle> Function()>(symbol: 'mpv_create')
external Pointer<MpvHandle> _mpvCreate();

@Native<Int32 Function(Pointer<MpvHandle>)>(symbol: 'mpv_initialize')
external int _mpvInitialize(Pointer<MpvHandle> ctx);

@Native<Void Function(Pointer<MpvHandle>)>(symbol: 'mpv_terminate_destroy')
external void _mpvTerminateDestroy(Pointer<MpvHandle> ctx);

@Native<Void Function(Pointer<MpvHandle>)>(symbol: 'mpv_wakeup', isLeaf: true)
external void _mpvWakeup(Pointer<MpvHandle> ctx);

@Native<Int32 Function(Pointer<MpvHandle>, Pointer<Utf8>, Pointer<Utf8>)>(
  symbol: 'mpv_set_option_string',
)
external int _mpvSetOptionString(
  Pointer<MpvHandle> ctx,
  Pointer<Utf8> name,
  Pointer<Utf8> data,
);

@Native<Int32 Function(Pointer<MpvHandle>, Pointer<Utf8>, Pointer<Utf8>)>(
  symbol: 'mpv_set_property_string',
)
external int _mpvSetPropertyString(
  Pointer<MpvHandle> ctx,
  Pointer<Utf8> name,
  Pointer<Utf8> data,
);

@Native<Pointer<Utf8> Function(Pointer<MpvHandle>, Pointer<Utf8>)>(
  symbol: 'mpv_get_property_string',
)
external Pointer<Utf8> _mpvGetPropertyString(
  Pointer<MpvHandle> ctx,
  Pointer<Utf8> name,
);

@Native<
  Int32 Function(Pointer<MpvHandle>, Pointer<Utf8>, Int32, Pointer<Void>)
>(symbol: 'mpv_get_property')
external int _mpvGetProperty(
  Pointer<MpvHandle> ctx,
  Pointer<Utf8> name,
  int format,
  Pointer<Void> data,
);

@Native<
  Int32 Function(
    Pointer<MpvHandle>,
    Uint64,
    Pointer<Utf8>,
    Int32,
    Pointer<Void>,
  )
>(symbol: 'mpv_set_property_async')
external int _mpvSetPropertyAsync(
  Pointer<MpvHandle> ctx,
  int replyUserdata,
  Pointer<Utf8> name,
  int format,
  Pointer<Void> data,
);

@Native<Int32 Function(Pointer<MpvHandle>, Uint64, Pointer<Utf8>, Int32)>(
  symbol: 'mpv_get_property_async',
)
external int _mpvGetPropertyAsync(
  Pointer<MpvHandle> ctx,
  int replyUserdata,
  Pointer<Utf8> name,
  int format,
);

@Native<Int32 Function(Pointer<MpvHandle>, Uint64, Pointer<Pointer<Utf8>>)>(
  symbol: 'mpv_command_async',
)
external int _mpvCommandAsync(
  Pointer<MpvHandle> ctx,
  int replyUserdata,
  Pointer<Pointer<Utf8>> args,
);

@Native<Int32 Function(Pointer<MpvHandle>, Pointer<Utf8>)>(
  symbol: 'mpv_command_string',
)
external int _mpvCommandString(Pointer<MpvHandle> ctx, Pointer<Utf8> args);

@Native<Pointer<MpvEvent> Function(Pointer<MpvHandle>, Double)>(
  symbol: 'mpv_wait_event',
)
external Pointer<MpvEvent> _mpvWaitEvent(
  Pointer<MpvHandle> ctx,
  double timeout,
);

@Native<Int32 Function(Pointer<MpvHandle>, Uint64, Pointer<Utf8>, Int32)>(
  symbol: 'mpv_observe_property',
)
external int _mpvObserveProperty(
  Pointer<MpvHandle> ctx,
  int replyUserdata,
  Pointer<Utf8> name,
  int format,
);

@Native<Void Function(Pointer<Void>)>(symbol: 'mpv_free', isLeaf: true)
external void _mpvFree(Pointer<Void> data);

@Native<Void Function(Pointer<MpvNode>)>(
  symbol: 'mpv_free_node_contents',
  isLeaf: true,
)
external void _mpvFreeNodeContents(Pointer<MpvNode> node);

@Native<Pointer<Utf8> Function(Int32)>(symbol: 'mpv_error_string', isLeaf: true)
external Pointer<Utf8> _mpvErrorString(int error);

@Native<Int32 Function(Pointer<MpvHandle>, Pointer<Utf8>)>(
  symbol: 'mpv_request_log_messages',
)
external int _mpvRequestLogMessages(
  Pointer<MpvHandle> ctx,
  Pointer<Utf8> minLevel,
);

@Native<Int32 Function(Pointer<MpvHandle>, Uint64, Pointer<Utf8>, Int32)>(
  symbol: 'mpv_hook_add',
)
external int _mpvHookAdd(
  Pointer<MpvHandle> ctx,
  int replyUserdata,
  Pointer<Utf8> name,
  int priority,
);

@Native<Int32 Function(Pointer<MpvHandle>, Uint64)>(symbol: 'mpv_hook_continue')
external int _mpvHookContinue(Pointer<MpvHandle> ctx, int id);
