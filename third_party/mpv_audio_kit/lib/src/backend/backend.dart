// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The backend of the platform the package is built for: libmpv over FFI
// with an event isolate (native_backend.dart), or the libmpv module in
// WebAssembly over js_interop (web_backend.dart). Each one provides:
//
//   MpvSession createMpvSession({int? wakeupCounterAddress})
//   String? defaultLibmpv()
//   void startBackend({String? libmpv, required bool hotRestartCleanup})
//   void backendInitialized()
//   PcmNative openPcmNative(String? path)
//   Future<void>? backendReady()
//   void resumeOutput()
//   Future<void>? setOutputSampleRate(int rate)
//   bool get outputNeedsGesture, Stream<bool> get outputNeedsGestureChanges
//   String? get unsupportedReason
//   String? kOutputVolumeOption, kOutputMuteOption
//
// The rest of the package imports this file only, so dart:ffi, dart:io and
// dart:isolate never reach a web build.

export 'mpv_session.dart';
export 'native_backend.dart' if (dart.library.js_interop) 'web_backend.dart';
