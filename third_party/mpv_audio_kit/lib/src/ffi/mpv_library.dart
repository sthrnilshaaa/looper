// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The client API functions of libmpv the package calls, in one interface
// with two implementations: the bundled library through @Native
// (mpv_library_bundled.dart), and a library opened from a path through
// lookups (mpv_library_opened.dart).

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import '../mpv_bindings.dart';
import 'mpv_library_bundled.dart';
import 'mpv_library_opened.dart';

/// The client API functions of an opened libmpv, the bundled one or one
/// at a path, resolved once at [MpvLibrary.open].
///
/// Leaf calls (no thread-state transition) are only the documented
/// non-blocking, callback-free ones: `mpv_wakeup`, `mpv_free`,
/// `mpv_free_node_contents` and `mpv_error_string`. A call that can block
/// on the core (wait_event, command, set or get property) or re-enter Dart
/// is never a leaf call.
abstract interface class MpvLibrary {
  /// Opens libmpv: the one the build hook bundles with the app, or the
  /// library at [path] when given (a custom libmpv build).
  /// Throws [MpvLibraryException] if the library cannot be found.
  factory MpvLibrary.open([String? path]) {
    if (path == null) {
      try {
        // @Native symbols resolve on first use; resolve one now so a
        // missing asset fails here, with a useful message.
        resolveBundledMpv();
      } catch (e) {
        throw MpvLibraryException(
          'Failed to load the libmpv bundled with mpv_audio_kit.\n'
          'Error: $e\n'
          'The build hook (hook/build.dart) provides it; check the build '
          'output for a hook failure.${_ohosHint()}',
        );
      }
      return const BundledMpvLibrary();
    }
    try {
      return OpenedMpvLibrary(DynamicLibrary.open(path));
    } catch (e) {
      throw MpvLibraryException(
        'Failed to load libmpv from "$path".\n'
        'Error: $e\n'
        'Ensure the library is present and all its dependencies are installed.',
      );
    }
  }

  /// `mpv_create`: allocates a new mpv client handle.
  Pointer<MpvHandle> mpvCreate();

  /// `mpv_initialize`: starts the mpv core for [ctx].
  int mpvInitialize(Pointer<MpvHandle> ctx);

  /// `mpv_terminate_destroy`: stops the core and releases [ctx], blocking
  /// until shutdown completes.
  void mpvTerminateDestroy(Pointer<MpvHandle> ctx);

  /// `mpv_wakeup`: interrupts a thread parked in `mpv_wait_event` on
  /// [ctx], making that call return `MPV_EVENT_NONE`. If no thread is
  /// currently waiting, the next `mpv_wait_event` returns immediately
  /// (libmpv guarantees no lost wakeups). Safe to call from any thread.
  void mpvWakeup(Pointer<MpvHandle> ctx);

  /// `mpv_set_option_string`: sets a pre-init option by name.
  int mpvSetOptionString(
    Pointer<MpvHandle> ctx,
    Pointer<Utf8> name,
    Pointer<Utf8> data,
  );

  /// `mpv_set_property_string`: sets a property from a string value.
  int mpvSetPropertyString(
    Pointer<MpvHandle> ctx,
    Pointer<Utf8> name,
    Pointer<Utf8> data,
  );

  /// `mpv_get_property_string`: reads a property as a newly allocated
  /// string the caller must release with `mpv_free`.
  Pointer<Utf8> mpvGetPropertyString(
    Pointer<MpvHandle> ctx,
    Pointer<Utf8> name,
  );

  /// `mpv_get_property`: reads a property into [data] using the given
  /// [MpvFormat].
  int mpvGetProperty(
    Pointer<MpvHandle> ctx,
    Pointer<Utf8> name,
    int format,
    Pointer<Void> data,
  );

  /// `mpv_set_property_async`: queues a property write and returns
  /// immediately; libmpv deep-copies [name] and the value before
  /// returning, and delivers the outcome as an
  /// `MPV_EVENT_SET_PROPERTY_REPLY` tagged with [replyUserdata]. Unlike the
  /// synchronous setter it never waits for the core's playloop, so it
  /// cannot stall the calling isolate.
  int mpvSetPropertyAsync(
    Pointer<MpvHandle> ctx,
    int replyUserdata,
    Pointer<Utf8> name,
    int format,
    Pointer<Void> data,
  );

  /// `mpv_get_property_async`: queues a property read and returns
  /// immediately; the value arrives as an `MPV_EVENT_GET_PROPERTY_REPLY`
  /// carrying an `mpv_event_property` payload, tagged with
  /// [replyUserdata].
  int mpvGetPropertyAsync(
    Pointer<MpvHandle> ctx,
    int replyUserdata,
    Pointer<Utf8> name,
    int format,
  );

  /// `mpv_command_async`: parses [args] client-side, queues the command and
  /// returns immediately; the outcome arrives as an
  /// `MPV_EVENT_COMMAND_REPLY` tagged with [replyUserdata].
  int mpvCommandAsync(
    Pointer<MpvHandle> ctx,
    int replyUserdata,
    Pointer<Pointer<Utf8>> args,
  );

  /// `mpv_command_string`: runs a command from a single command-line
  /// string.
  int mpvCommandString(Pointer<MpvHandle> ctx, Pointer<Utf8> args);

  /// `mpv_wait_event`: blocks up to [timeout] seconds for the next
  /// [MpvEvent].
  Pointer<MpvEvent> mpvWaitEvent(Pointer<MpvHandle> ctx, double timeout);

  /// `mpv_observe_property`: subscribes to change events for a property,
  /// tagged with [replyUserdata].
  int mpvObserveProperty(
    Pointer<MpvHandle> ctx,
    int replyUserdata,
    Pointer<Utf8> name,
    int format,
  );

  /// `mpv_free`: frees memory allocated by libmpv.
  void mpvFree(Pointer<Void> data);

  /// `mpv_free_node_contents`: frees memory owned by the contents of an
  /// [MpvNode].
  void mpvFreeNodeContents(Pointer<MpvNode> node);

  /// `mpv_error_string`: maps an [MpvError] code to a human-readable
  /// description.
  Pointer<Utf8> mpvErrorString(int error);

  /// `mpv_request_log_messages`: enables log-message events at or above
  /// [minLevel].
  int mpvRequestLogMessages(Pointer<MpvHandle> ctx, Pointer<Utf8> minLevel);

  /// `mpv_hook_add`: registers a hook handler for the named hook at the
  /// given priority.
  int mpvHookAdd(
    Pointer<MpvHandle> ctx,
    int replyUserdata,
    Pointer<Utf8> name,
    int priority,
  );

  /// `mpv_hook_continue`: resumes mpv after a hook with the given id has
  /// been handled.
  int mpvHookContinue(Pointer<MpvHandle> ctx, int id);
}

/// Exception thrown when the `libmpv` shared library cannot be loaded or resolved.
class MpvLibraryException implements Exception {
  /// The error message describing the failure.
  final String message;

  /// Creates a new [MpvLibraryException] with the given [message].
  const MpvLibraryException(this.message);

  @override
  String toString() => 'MpvLibraryException: $message';
}

/// On OHOS, the define that makes the hook bundle the OHOS libmpv: a
/// Flutter-OH whose hook input no longer names the SDK's clang gets the
/// desktop Linux one, which does not load there.
String _ohosHint() => Platform.operatingSystem == 'ohos'
    ? '\nOn OpenHarmony and HarmonyOS, set the ohos user define to true '
          '(hooks: user_defines: mpv_audio_kit: ohos: true) so the hook '
          'bundles libmpv_ohos.'
    : '';
