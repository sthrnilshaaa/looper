// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
// A libmpv opened from a path (a custom build, or webOS), its functions
// looked up once. Leaf calls follow the rule of MpvLibrary.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:meta/meta.dart';

import '../mpv_bindings.dart';

/// The [MpvLibrary] of the libmpv [DynamicLibrary] it is built with.
@internal
final class OpenedMpvLibrary implements MpvLibrary {
  /// Looks up every function of [lib]; throws when one is missing.
  OpenedMpvLibrary(DynamicLibrary lib)
    : _mpvCreate = lib
          .lookupFunction<
            Pointer<MpvHandle> Function(),
            Pointer<MpvHandle> Function()
          >('mpv_create'),
      _mpvInitialize = lib
          .lookupFunction<
            Int32 Function(Pointer<MpvHandle>),
            int Function(Pointer<MpvHandle>)
          >('mpv_initialize'),
      _mpvTerminateDestroy = lib
          .lookupFunction<
            Void Function(Pointer<MpvHandle>),
            void Function(Pointer<MpvHandle>)
          >('mpv_terminate_destroy'),
      _mpvWakeup = lib
          .lookupFunction<
            Void Function(Pointer<MpvHandle>),
            void Function(Pointer<MpvHandle>)
          >('mpv_wakeup', isLeaf: true),
      _mpvSetOptionString = lib
          .lookupFunction<
            Int32 Function(Pointer<MpvHandle>, Pointer<Utf8>, Pointer<Utf8>),
            int Function(Pointer<MpvHandle>, Pointer<Utf8>, Pointer<Utf8>)
          >('mpv_set_option_string'),
      _mpvSetPropertyString = lib
          .lookupFunction<
            Int32 Function(Pointer<MpvHandle>, Pointer<Utf8>, Pointer<Utf8>),
            int Function(Pointer<MpvHandle>, Pointer<Utf8>, Pointer<Utf8>)
          >('mpv_set_property_string'),
      _mpvGetPropertyString = lib
          .lookupFunction<
            Pointer<Utf8> Function(Pointer<MpvHandle>, Pointer<Utf8>),
            Pointer<Utf8> Function(Pointer<MpvHandle>, Pointer<Utf8>)
          >('mpv_get_property_string'),
      _mpvGetProperty = lib
          .lookupFunction<
            Int32 Function(
              Pointer<MpvHandle>,
              Pointer<Utf8>,
              Int32,
              Pointer<Void>,
            ),
            int Function(Pointer<MpvHandle>, Pointer<Utf8>, int, Pointer<Void>)
          >('mpv_get_property'),
      _mpvSetPropertyAsync = lib
          .lookupFunction<
            Int32 Function(
              Pointer<MpvHandle>,
              Uint64,
              Pointer<Utf8>,
              Int32,
              Pointer<Void>,
            ),
            int Function(
              Pointer<MpvHandle>,
              int,
              Pointer<Utf8>,
              int,
              Pointer<Void>,
            )
          >('mpv_set_property_async'),
      _mpvGetPropertyAsync = lib
          .lookupFunction<
            Int32 Function(Pointer<MpvHandle>, Uint64, Pointer<Utf8>, Int32),
            int Function(Pointer<MpvHandle>, int, Pointer<Utf8>, int)
          >('mpv_get_property_async'),
      _mpvCommandAsync = lib
          .lookupFunction<
            Int32 Function(Pointer<MpvHandle>, Uint64, Pointer<Pointer<Utf8>>),
            int Function(Pointer<MpvHandle>, int, Pointer<Pointer<Utf8>>)
          >('mpv_command_async'),
      _mpvCommandString = lib
          .lookupFunction<
            Int32 Function(Pointer<MpvHandle>, Pointer<Utf8>),
            int Function(Pointer<MpvHandle>, Pointer<Utf8>)
          >('mpv_command_string'),
      _mpvWaitEvent = lib
          .lookupFunction<
            Pointer<MpvEvent> Function(Pointer<MpvHandle>, Double),
            Pointer<MpvEvent> Function(Pointer<MpvHandle>, double)
          >('mpv_wait_event'),
      _mpvObserveProperty = lib
          .lookupFunction<
            Int32 Function(Pointer<MpvHandle>, Uint64, Pointer<Utf8>, Int32),
            int Function(Pointer<MpvHandle>, int, Pointer<Utf8>, int)
          >('mpv_observe_property'),
      _mpvFree = lib
          .lookupFunction<
            Void Function(Pointer<Void>),
            void Function(Pointer<Void>)
          >('mpv_free', isLeaf: true),
      _mpvFreeNodeContents = lib
          .lookupFunction<
            Void Function(Pointer<MpvNode>),
            void Function(Pointer<MpvNode>)
          >('mpv_free_node_contents', isLeaf: true),
      _mpvErrorString = lib
          .lookupFunction<
            Pointer<Utf8> Function(Int32),
            Pointer<Utf8> Function(int)
          >('mpv_error_string', isLeaf: true),
      _mpvRequestLogMessages = lib
          .lookupFunction<
            Int32 Function(Pointer<MpvHandle>, Pointer<Utf8>),
            int Function(Pointer<MpvHandle>, Pointer<Utf8>)
          >('mpv_request_log_messages'),
      _mpvHookAdd = lib
          .lookupFunction<
            Int32 Function(Pointer<MpvHandle>, Uint64, Pointer<Utf8>, Int32),
            int Function(Pointer<MpvHandle>, int, Pointer<Utf8>, int)
          >('mpv_hook_add'),
      _mpvHookContinue = lib
          .lookupFunction<
            Int32 Function(Pointer<MpvHandle>, Uint64),
            int Function(Pointer<MpvHandle>, int)
          >('mpv_hook_continue');

  final Pointer<MpvHandle> Function() _mpvCreate;

  final int Function(Pointer<MpvHandle>) _mpvInitialize;

  final void Function(Pointer<MpvHandle>) _mpvTerminateDestroy;

  final void Function(Pointer<MpvHandle>) _mpvWakeup;

  final int Function(Pointer<MpvHandle>, Pointer<Utf8>, Pointer<Utf8>)
  _mpvSetOptionString;

  final int Function(Pointer<MpvHandle>, Pointer<Utf8>, Pointer<Utf8>)
  _mpvSetPropertyString;

  final Pointer<Utf8> Function(Pointer<MpvHandle>, Pointer<Utf8>)
  _mpvGetPropertyString;

  final int Function(Pointer<MpvHandle>, Pointer<Utf8>, int, Pointer<Void>)
  _mpvGetProperty;

  final int Function(Pointer<MpvHandle>, int, Pointer<Utf8>, int, Pointer<Void>)
  _mpvSetPropertyAsync;

  final int Function(Pointer<MpvHandle>, int, Pointer<Utf8>, int)
  _mpvGetPropertyAsync;

  final int Function(Pointer<MpvHandle>, int, Pointer<Pointer<Utf8>>)
  _mpvCommandAsync;

  final int Function(Pointer<MpvHandle>, Pointer<Utf8>) _mpvCommandString;

  final Pointer<MpvEvent> Function(Pointer<MpvHandle>, double) _mpvWaitEvent;

  final int Function(Pointer<MpvHandle>, int, Pointer<Utf8>, int)
  _mpvObserveProperty;

  final void Function(Pointer<Void>) _mpvFree;

  final void Function(Pointer<MpvNode>) _mpvFreeNodeContents;

  final Pointer<Utf8> Function(int) _mpvErrorString;

  final int Function(Pointer<MpvHandle>, Pointer<Utf8>) _mpvRequestLogMessages;

  final int Function(Pointer<MpvHandle>, int, Pointer<Utf8>, int) _mpvHookAdd;

  final int Function(Pointer<MpvHandle>, int) _mpvHookContinue;

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
