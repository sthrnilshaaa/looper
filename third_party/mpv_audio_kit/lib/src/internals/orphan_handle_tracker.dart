// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:mpv_audio_kit/src/internals/debug_log.dart';
import 'package:mpv_audio_kit/src/mpv_bindings.dart';

/// Recovers libmpv handles leaked across a Flutter Hot-Restart.
///
/// Flutter replaces the Dart VM but keeps the parent process alive,
/// so handles allocated by the previous VM stay open (and block
/// exclusive-mode audio devices like WASAPI) until the process exits.
/// The tracker stashes a per-pid native buffer of live handle
/// addresses in a tmp file; on startup the new VM rehydrates that
/// buffer and surfaces every still-tracked handle to the caller's
/// cleanup callback.
///
/// **Production no-op** — guarded by `dart.vm.product`. Hot-Restart
/// is a development concern; in product builds the parent process
/// dies with the VM and there are no orphans to rescue.
///
/// **Single-isolate** — [add] / [remove] are not synchronized across
/// isolates that share a pid. The test suite disables the tracker
/// via `MpvAudioKit.ensureInitialized(hotRestartCleanup: false)`.
class OrphanHandleTracker {
  static const int _kBufferSize = 256;
  // Magic cookie stored alongside every address. Hot-Restart cleanup
  // verifies this before calling into libmpv with a stored address so a
  // pid-reuse / file-corruption scenario can't trick us into invoking FFI
  // on a pointer that wasn't ours. Slots are laid out as
  // [cookie₀, addr₀, cookie₁, addr₁, …] in the underlying buffer.
  static const int _kCookie = 0x4D414B5F4D5056AB; // "MAK_MPV\xab"
  // 2 IntPtrs per slot (cookie + address).
  static const int _kSlotStride = 2;
  /// The process-wide singleton. One tracker shares the per-pid leak
  /// buffer across every [Player] created in this Dart VM.
  static final OrphanHandleTracker instance = OrphanHandleTracker._();
  static bool _initialized = false;

  late final File _file;
  late final Pointer<IntPtr> _buffer;
  final Completer<void> _completer = Completer<void>();

  bool get _isDebug => !const bool.fromEnvironment('dart.vm.product');

  OrphanHandleTracker._() {
    _file = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}mpv_audio_kit_refs_$pid.txt',);
  }

  /// Initializes the tracker once per Dart VM.
  ///
  /// On a fresh launch the buffer is allocated and the file written;
  /// on a Hot-Restart the file already exists and the existing buffer
  /// is reattached. Any non-zero entries in the buffer are surfaced
  /// to [onOrphanFound] for the caller to clean up.
  void ensureInitialized(
      void Function(List<Pointer<MpvHandle>>) onOrphanFound,) {
    if (!_isDebug) {
      return;
    }
    if (_initialized) {
      return;
    }
    // The cookie is 64-bit; on a 32-bit IntPtr host the high half would
    // silently truncate and any non-zero residual could pose as a valid
    // pointer in the leak buffer. Skip the tracker entirely on 32-bit
    // platforms — the targeted desktop / mobile builds are all 64-bit
    // today.
    if (sizeOf<IntPtr>() != 8) {
      debugLog(
        'mpv_audio_kit: OrphanHandleTracker requires a 64-bit IntPtr '
        '(got ${sizeOf<IntPtr>() * 8}-bit). Hot-restart cleanup disabled.',
      );
      if (!_completer.isCompleted) {
        _completer.complete();
      }
      return;
    }
    _initialized = true;

    _sweepStaleSentinelFiles();

    try {
      if (!_file.existsSync()) {
        // Intentionally never freed: the buffer must outlive the Dart VM
        // so the next Hot-Restart can rehydrate orphan addresses from it.
        // The OS reclaims the allocation when the host process eventually
        // exits.
        _buffer = calloc<IntPtr>(_kBufferSize * _kSlotStride);
        _file.writeAsStringSync(_buffer.address.toString());
      } else {
        final addressStr = _file.readAsStringSync().trim();
        final address = int.parse(addressStr);
        _buffer = Pointer<IntPtr>.fromAddress(address);
      }

      final orphans = <Pointer<MpvHandle>>[];
      for (int i = 0; i < _kBufferSize; i++) {
        final cookieRef = _buffer + (i * _kSlotStride);
        final addrRef = _buffer + (i * _kSlotStride + 1);
        final cookieVal = cookieRef.value;
        final refAddr = addrRef.value;
        // Skip slots that lack the magic cookie — either empty (cookie=0)
        // or filled by something other than us (pid reuse hitting the
        // same buffer address). This is the load-bearing safety check
        // against handing libmpv a dangling pointer.
        if (cookieVal != _kCookie) continue;
        if (refAddr != 0) {
          orphans.add(Pointer.fromAddress(refAddr));
          cookieRef.value = 0;
          addrRef.value = 0;
        }
      }

      if (orphans.isNotEmpty) {
        onOrphanFound(orphans);
      }
    } catch (e) {
      debugLog('mpv_audio_kit: OrphanHandleTracker initialization failed: $e');
    } finally {
      if (!_completer.isCompleted) {
        _completer.complete();
      }
    }
  }

  /// Cleans up `mpv_audio_kit_refs_<pid>.txt` files from previous Dart
  /// VMs whose host process is no longer alive. Without this sweep the
  /// system temp directory accumulates one file per dev session for the
  /// lifetime of the host machine.
  ///
  /// Safe under `flutter test` because the harness disables this tracker
  /// (`hotRestartCleanup: false`), so the sweep never runs in CI / test
  /// processes that share a pid namespace.
  void _sweepStaleSentinelFiles() {
    try {
      final tmp = Directory(Directory.systemTemp.path);
      if (!tmp.existsSync()) return;
      final keepName = _file.uri.pathSegments.last;
      for (final entry in tmp.listSync(followLinks: false)) {
        if (entry is! File) continue;
        final name = entry.uri.pathSegments.last;
        if (!name.startsWith('mpv_audio_kit_refs_') ||
            !name.endsWith('.txt') ||
            name == keepName) {
          continue;
        }
        final pidStr = name.substring(
            'mpv_audio_kit_refs_'.length, name.length - '.txt'.length,);
        final otherPid = int.tryParse(pidStr);
        if (otherPid == null || otherPid == pid) continue;
        if (_isPidAlive(otherPid)) continue;
        try {
          entry.deleteSync();
        } catch (_) {
          // Best-effort: another VM may be racing the same sweep.
        }
      }
    } catch (e) {
      debugLog('mpv_audio_kit: stale-sentinel sweep failed: $e');
    }
  }

  /// Returns `true` when [otherPid] points at a live process (POSIX:
  /// `kill -0`; Windows: best-effort assume alive). The check is purely
  /// to avoid wiping the sentinel of a still-running sibling Dart VM
  /// (rare in practice, but the tracker is shared per-pid).
  bool _isPidAlive(int otherPid) {
    if (Platform.isWindows) {
      // No cheap POSIX-equivalent without an FFI call; err on the side
      // of keeping the file so we never delete a live VM's sentinel.
      return true;
    }
    final result = Process.runSync('kill', ['-0', otherPid.toString()]);
    return result.exitCode == 0;
  }

  /// Records [handle] in the first free slot.
  ///
  /// Silently drops the handle when the buffer is full and emits a
  /// stderr warning. Hot-Restart cleanup will then miss this handle
  /// — on Windows that means a WASAPI exclusive-mode device may
  /// stay locked until the parent process terminates.
  void add(Pointer<MpvHandle> handle) {
    if (!_isDebug || !_initialized) {
      return;
    }
    _completer.future.then((_) {
      if (handle == nullptr) {
        return;
      }
      for (int i = 0; i < _kBufferSize; i++) {
        final cookieRef = _buffer + (i * _kSlotStride);
        final addrRef = _buffer + (i * _kSlotStride + 1);
        if (cookieRef.value == 0 && addrRef.value == 0) {
          cookieRef.value = _kCookie;
          addrRef.value = handle.address;
          return;
        }
      }
      debugLog(
        'mpv_audio_kit: OrphanHandleTracker buffer full ($_kBufferSize '
        'handles tracked). Handle ${handle.address} not registered for '
        'hot-restart cleanup — dispose Player instances before creating '
        'more.',
      );
    });
  }

  /// Clears [handle] from the buffer when [Player.dispose] runs
  /// normally — keeps the orphan list accurate so the next
  /// Hot-Restart only sees handles that actually leaked.
  void remove(Pointer<MpvHandle> handle) {
    if (!_isDebug || !_initialized) {
      return;
    }
    _completer.future.then((_) {
      if (handle == nullptr) {
        return;
      }
      for (int i = 0; i < _kBufferSize; i++) {
        final cookieRef = _buffer + (i * _kSlotStride);
        final addrRef = _buffer + (i * _kSlotStride + 1);
        if (cookieRef.value == _kCookie && addrRef.value == handle.address) {
          cookieRef.value = 0;
          addrRef.value = 0;
          break;
        }
      }
    });
  }
}
