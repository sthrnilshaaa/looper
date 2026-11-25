// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The Hot Restart registry of the web: a record on globalThis that outlives
// the Dart program. A Hot Restart runs main() again in the same page, while
// the module, its cores, their audio and their network streams go on: the
// replaced program never disposed them. The record names the module
// instance and the cores the players of the page hold, so the next program
// reuses the instance (one wasm memory and one pool of workers per page)
// and destroys the cores it finds there.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:meta/meta.dart';

import '../../internals/analysis_commands.dart';
import 'mpv_module.dart';

@JS('globalThis')
external JSObject get _global;

/// The property of globalThis that holds the record.
const String _kKey = '__mpvAudioKit';

/// The record: the URL the module came from, its instance, and the cores of
/// the players that have not disposed them.
extension type _Record._(JSObject _) implements JSObject {
  external factory _Record({String url, JSObject module, JSArray<_Core> cores});

  external String get url;
  external JSObject get module;
  external JSArray<_Core> cores;
}

/// One core of a player: its client, the read client of the web session,
/// and their wakeup bridges.
extension type _Core._(JSObject _) implements JSObject {
  external factory _Core({
    int handle,
    int reads,
    int handleBridge,
    int readsBridge,
  });

  external int get handle;
  external int get reads;
  external int get handleBridge;
  external int get readsBridge;
}

_Record? get _record => _global[_kKey] as _Record?;

/// The module instance a previous program of this page loaded from [url],
/// to be reused; `null` when there is none.
@internal
JSObject? registeredModule(String url) {
  final record = _record;
  return record != null && record.url == url ? record.module : null;
}

/// Test-only: gets the handle of each core [registerModule] destroys.
@visibleForTesting
void Function(int handle)? debugWebReapTrace;

/// Makes [module], loaded from [url], the module of this page's record.
///
/// The cores the record holds belong to the program a Hot Restart replaced:
/// with [reap] they are destroyed first, on the instance that runs them,
/// with what that program left on: the analysis switches (per module, like
/// libmpv's per process), the live PCM sources, the webaudio output's
/// AudioContext. Without [reap] they are left alone.
@internal
void registerModule(String url, MpvModule module, {required bool reap}) {
  final previous = _record;
  if (previous != null && reap) {
    // JavaScript identity: two Dart views of one object are not identical.
    if (previous.module.strictEquals(module.instance).toDart) {
      // The output's context is replaced by this program's own.
      _reap(module, previous.cores.toDart, closeOutput: false);
    } else if (_moduleOf(previous.module) case final old?) {
      _reap(old, previous.cores.toDart, closeOutput: true);
    }
  }
  _global[_kKey] = _Record(
    url: url,
    module: module.instance,
    cores: JSArray<_Core>(),
  );
}

/// The previous module instance, when it is not the one this program uses
/// (another URL); `null` when it cannot be driven any more.
MpvModule? _moduleOf(JSObject instance) {
  try {
    return MpvModule(instance);
  } catch (_) {
    return null;
  }
}

// A module that aborted throws at every call. A core that cannot be
// destroyed is passed over, and so is the rest of the cleanup: what throws
// here would fail the load of the page for every player.
void _reap(MpvModule m, List<_Core> cores, {required bool closeOutput}) {
  final c = m.c;
  for (final core in cores) {
    debugWebReapTrace?.call(core.handle);
    try {
      m.detachWakeup(core.reads, core.readsBridge);
      m.detachWakeup(core.handle, core.handleBridge);
      for (final command in analysisOffCommands) {
        m.withStrings([command], (p) => c.mpvCommandString(core.handle, p[0]));
      }
      c.mpvDestroy(core.reads);
      c.mpvTerminateDestroy(core.handle);
    } catch (_) {}
  }
  try {
    c.pcmReleaseAll();
    if (closeOutput) c.makWebAudio.close().toDart.ignore();
  } catch (_) {}
}

/// Records the core of a player, once its bring-up kept it.
@internal
void trackCore({
  required int handle,
  required int reads,
  required int handleBridge,
  required int readsBridge,
}) {
  _record?.cores.add(
    _Core(
      handle: handle,
      reads: reads,
      handleBridge: handleBridge,
      readsBridge: readsBridge,
    ),
  );
}

/// Drops the core of [handle], at dispose.
@internal
void untrackCore(int handle) {
  final cores = _record?.cores;
  if (cores == null) return;
  final kept = [
    for (final core in cores.toDart)
      if (core.handle != handle) core,
  ];
  _record!.cores = kept.toJS;
}

/// The handles the record holds, for tests.
@visibleForTesting
List<int> get debugTrackedCores => [
  for (final core in _record?.cores.toDart ?? const <_Core>[]) core.handle,
];
