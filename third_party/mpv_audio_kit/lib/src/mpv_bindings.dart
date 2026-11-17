// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// ignore_for_file: camel_case_types

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:meta/meta.dart';

// ---------------------------------------------------------------------------
// mpv_error  (subset — limited to required error codes)
// ---------------------------------------------------------------------------
/// Mirror of libmpv's `mpv_error` return codes (the subset this package uses).
///
/// Negative values indicate an error; [mpvErrorSuccess] (0) means success.
abstract final class MpvError {
  /// No error (`MPV_ERROR_SUCCESS`).
  static const int mpvErrorSuccess = 0;

  /// The event ringbuffer is full (`MPV_ERROR_EVENT_QUEUE_FULL`).
  static const int mpvErrorEventQueueFull = -1;

  /// Memory allocation failed (`MPV_ERROR_NOMEM`).
  static const int mpvErrorNomem = -2;

  /// The mpv core was not configured/initialized (`MPV_ERROR_UNINITIALIZED`).
  static const int mpvErrorUninitialized = -3;

  /// A function received an invalid parameter (`MPV_ERROR_INVALID_PARAMETER`).
  static const int mpvErrorInvalidParameter = -4;

  /// The named option does not exist (`MPV_ERROR_OPTION_NOT_FOUND`).
  static const int mpvErrorOptionNotFound = -5;

  /// The option value has an unsupported format (`MPV_ERROR_OPTION_FORMAT`).
  static const int mpvErrorOptionFormat = -6;

  /// Setting the option failed (`MPV_ERROR_OPTION_ERROR`).
  static const int mpvErrorOptionError = -7;

  /// The named property does not exist (`MPV_ERROR_PROPERTY_NOT_FOUND`).
  static const int mpvErrorPropertyNotFound = -8;

  /// The property cannot be used in the requested format
  /// (`MPV_ERROR_PROPERTY_FORMAT`).
  static const int mpvErrorPropertyFormat = -9;

  /// The property exists but is currently unavailable
  /// (`MPV_ERROR_PROPERTY_UNAVAILABLE`).
  static const int mpvErrorPropertyUnavailable = -10;

  /// A generic error occurred accessing the property
  /// (`MPV_ERROR_PROPERTY_ERROR`).
  static const int mpvErrorPropertyError = -11;

  /// A command failed during execution (`MPV_ERROR_COMMAND`).
  static const int mpvErrorCommand = -12;

  /// Loading the requested file/URL failed (`MPV_ERROR_LOADING_FAILED`).
  static const int mpvErrorLoadingFailed = -13;

  /// Initializing the audio output failed (`MPV_ERROR_AO_INIT_FAILED`).
  static const int mpvErrorAoInitFailed = -14;

  /// Initializing the video output failed (`MPV_ERROR_VO_INIT_FAILED`).
  static const int mpvErrorVoInitFailed = -15;

  /// There was nothing to play (`MPV_ERROR_NOTHING_TO_PLAY`).
  static const int mpvErrorNothingToPlay = -16;

  /// The file format could not be determined (`MPV_ERROR_UNKNOWN_FORMAT`).
  static const int mpvErrorUnknownFormat = -17;

  /// The operation is not supported (`MPV_ERROR_UNSUPPORTED`).
  static const int mpvErrorUnsupported = -18;

  /// The API function is not implemented (`MPV_ERROR_NOT_IMPLEMENTED`).
  static const int mpvErrorNotImplemented = -19;

  /// An unspecified error occurred (`MPV_ERROR_GENERIC`).
  static const int mpvErrorGeneric = -20;
}

// ---------------------------------------------------------------------------
// mpv_format
// ---------------------------------------------------------------------------
/// Mirror of libmpv's `mpv_format` data-type tags used when reading or
/// writing properties and decoding [MpvNode] values.
abstract final class MpvFormat {
  /// No value / invalid format (`MPV_FORMAT_NONE`).
  static const int mpvFormatNone = 0;

  /// UTF-8 string (`MPV_FORMAT_STRING`).
  static const int mpvFormatString = 1;

  /// OSD-formatted string (`MPV_FORMAT_OSD_STRING`).
  static const int mpvFormatOsdString = 2;

  /// Boolean flag, stored as an int (`MPV_FORMAT_FLAG`).
  static const int mpvFormatFlag = 3;

  /// 64-bit signed integer (`MPV_FORMAT_INT64`).
  static const int mpvFormatInt64 = 4;

  /// Double-precision float (`MPV_FORMAT_DOUBLE`).
  static const int mpvFormatDouble = 5;

  /// Generic [MpvNode] value (`MPV_FORMAT_NODE`).
  static const int mpvFormatNode = 6;

  /// Node array (`MPV_FORMAT_NODE_ARRAY`).
  static const int mpvFormatNodeArray = 7;

  /// Node map / key-value object (`MPV_FORMAT_NODE_MAP`).
  static const int mpvFormatNodeMap = 8;

  /// Raw byte array (`MPV_FORMAT_BYTE_ARRAY`).
  static const int mpvFormatByteArray = 9;
}

// ---------------------------------------------------------------------------
// mpv_event_id
// ---------------------------------------------------------------------------
/// Mirror of libmpv's `mpv_event_id` tags delivered by `mpv_wait_event`.
abstract final class MpvEventId {
  /// No event was available (`MPV_EVENT_NONE`).
  static const int mpvEventNone = 0;

  /// The mpv core is shutting down (`MPV_EVENT_SHUTDOWN`).
  static const int mpvEventShutdown = 1;

  /// A log message is available (`MPV_EVENT_LOG_MESSAGE`).
  static const int mpvEventLogMessage = 2;

  /// Reply to an async `mpv_get_property` (`MPV_EVENT_GET_PROPERTY_REPLY`).
  static const int mpvEventGetPropertyReply = 3;

  /// Reply to an async `mpv_set_property` (`MPV_EVENT_SET_PROPERTY_REPLY`).
  static const int mpvEventSetPropertyReply = 4;

  /// Reply to an async command (`MPV_EVENT_COMMAND_REPLY`).
  static const int mpvEventCommandReply = 5;

  /// Playback of a new file has started (`MPV_EVENT_START_FILE`).
  static const int mpvEventStartFile = 6;

  /// Playback of a file has ended (`MPV_EVENT_END_FILE`).
  static const int mpvEventEndFile = 7;

  /// The file was loaded and decoding is about to start
  /// (`MPV_EVENT_FILE_LOADED`).
  static const int mpvEventFileLoaded = 8;

  /// The player has entered idle mode with nothing loaded (`MPV_EVENT_IDLE`).
  static const int mpvEventIdle = 11;

  /// Periodic timer tick (`MPV_EVENT_TICK`).
  static const int mpvEventTick = 14;

  /// A client message was received (`MPV_EVENT_CLIENT_MESSAGE`).
  static const int mpvEventClientMessage = 16;

  /// Video output was reconfigured (`MPV_EVENT_VIDEO_RECONFIG`).
  static const int mpvEventVideoReconfig = 17;

  /// Audio output was reconfigured (`MPV_EVENT_AUDIO_RECONFIG`).
  static const int mpvEventAudioReconfig = 18;

  /// A seek was initiated (`MPV_EVENT_SEEK`).
  static const int mpvEventSeek = 20;

  /// Playback restarted after a seek or file load
  /// (`MPV_EVENT_PLAYBACK_RESTART`).
  static const int mpvEventPlaybackRestart = 21;

  /// An observed property changed value (`MPV_EVENT_PROPERTY_CHANGE`).
  static const int mpvEventPropertyChange = 22;

  /// The event queue overflowed and events were dropped
  /// (`MPV_EVENT_QUEUE_OVERFLOW`).
  static const int mpvEventQueueOverflow = 24;

  /// A registered hook was triggered (`MPV_EVENT_HOOK`).
  static const int mpvEventHook = 25;
}

// ---------------------------------------------------------------------------
// mpv_end_file_reason
// ---------------------------------------------------------------------------
/// Mirror of libmpv's `mpv_end_file_reason`, carried in [MpvEventEndFile].
abstract final class MpvEndFileReason {
  /// The file reached its natural end (`MPV_END_FILE_REASON_EOF`).
  static const int mpvEndFileReasonEof = 0;

  /// Playback was stopped by command (`MPV_END_FILE_REASON_STOP`).
  static const int mpvEndFileReasonStop = 2;

  /// The player is quitting (`MPV_END_FILE_REASON_QUIT`).
  static const int mpvEndFileReasonQuit = 3;

  /// Playback ended due to an error (`MPV_END_FILE_REASON_ERROR`).
  static const int mpvEndFileReasonError = 4;

  /// Playback was redirected to another file (`MPV_END_FILE_REASON_REDIRECT`).
  static const int mpvEndFileReasonRedirect = 5;
}

// ---------------------------------------------------------------------------
// Opaque handle type
// ---------------------------------------------------------------------------
/// Opaque FFI type for `mpv_handle *`, the client context returned by
/// `mpv_create` and passed to every other client-API call.
final class MpvHandle extends Opaque {}

// ---------------------------------------------------------------------------
// mpv_event  (layout matches mpv.h)
// ---------------------------------------------------------------------------
/// FFI layout of `mpv_event`, the struct returned by `mpv_wait_event`.
final class MpvEvent extends Struct {
  /// The event type, one of the [MpvEventId] constants.
  @Int32()
  external int eventId;

  /// Error code for reply events ([MpvError]); 0 on success.
  @Int32()
  external int error;

  /// The user-data value associated with the originating async request.
  @Uint64()
  external int replyUserdata;

  /// Pointer to the event-specific payload struct (e.g. [MpvEventProperty]),
  /// or `nullptr` when the event carries no data.
  external Pointer<Void> data;
}

// ---------------------------------------------------------------------------
// mpv_event_end_file
// ---------------------------------------------------------------------------
/// FFI layout of `mpv_event_end_file`, the payload of an end-file event.
final class MpvEventEndFile extends Struct {
  /// Why playback ended, one of the [MpvEndFileReason] constants.
  @Int32()
  external int reason;

  /// Error code ([MpvError]) when [reason] is an error; otherwise 0.
  @Int32()
  external int error;
}

// ---------------------------------------------------------------------------
// mpv_event_property
// ---------------------------------------------------------------------------
/// FFI layout of `mpv_event_property`, the payload of a property-change event.
final class MpvEventProperty extends Struct {
  /// The property name (`const char *`). Held as `Pointer<Void>` to satisfy
  /// FFI struct rules; cast to `Pointer<Utf8>` when reading.
  external Pointer<Void> name;

  /// The data format of [data], one of the [MpvFormat] constants.
  @Int32()
  external int format;

  // 4 bytes of implicit padding before the next 8-byte pointer (C ABI).
  // Dart FFI calculates struct layout automatically via @Int32 + Pointer alignment.

  /// Pointer to the new property value, decoded according to [format].
  external Pointer<Void> data;
}

// ---------------------------------------------------------------------------
// mpv_event_log_message
// ---------------------------------------------------------------------------
/// FFI layout of `mpv_event_log_message`, the payload of a log-message event.
final class MpvEventLogMessage extends Struct {
  /// The originating component prefix (`const char *`, e.g. `"vd"`).
  external Pointer<Void> prefix;

  /// The log level as text (`const char *`, e.g. `"warn"`, `"error"`).
  external Pointer<Void> level;

  /// The message text (`const char *`), including its trailing newline.
  external Pointer<Void> text;

  /// The numeric `mpv_log_level` corresponding to [level].
  @Int32()
  external int logLevel;
}

// ---------------------------------------------------------------------------
// mpv_node & co
// ---------------------------------------------------------------------------

/// FFI layout of `mpv_node`, mpv's tagged-union container for arbitrary
/// property/command values.
final class MpvNode extends Struct {
  /// The value union; the active member is selected by [format].
  external MpvNodeUnion u;

  /// The active union member, one of the [MpvFormat] constants.
  @Int32()
  external int format;
}

/// FFI layout of the `mpv_node` value union (`u`).
final class MpvNodeUnion extends Union {
  /// String value, valid when the node format is `MPV_FORMAT_STRING`.
  external Pointer<Utf8> string;

  /// Boolean flag, valid when the node format is `MPV_FORMAT_FLAG`.
  @Int32()
  external int flag;

  /// Integer value, valid when the node format is `MPV_FORMAT_INT64`.
  @Int64()
  external int int64;

  /// Floating-point value, valid when the node format is `MPV_FORMAT_DOUBLE`.
  @Double()
  external double double_;

  /// List/map contents, valid for `MPV_FORMAT_NODE_ARRAY` / `_NODE_MAP`.
  external Pointer<MpvNodeList> list;

  /// Byte-array contents, valid when the node format is
  /// `MPV_FORMAT_BYTE_ARRAY`.
  external Pointer<MpvByteArray> ba;
}

/// FFI layout of `mpv_node_list`, the backing store for node arrays and maps.
final class MpvNodeList extends Struct {
  /// Number of entries in [values] (and [keys] for maps).
  @Int32()
  external int num;

  /// Pointer to the array of [num] [MpvNode] values.
  external Pointer<MpvNode> values;

  /// Pointer to the array of [num] string keys (maps only); `nullptr` for
  /// arrays.
  external Pointer<Pointer<Utf8>> keys;
}

/// FFI layout of `mpv_byte_array`, a raw byte buffer carried in an [MpvNode].
final class MpvByteArray extends Struct {
  /// Pointer to the raw bytes.
  external Pointer<Void> data;

  /// Number of bytes available at [data].
  @Size()
  external int size;
}

// ---------------------------------------------------------------------------
// mpv_event_hook
// ---------------------------------------------------------------------------
/// FFI layout of `mpv_event_hook`, the payload of a hook event.
final class MpvEventHook extends Struct {
  /// The hook name (`const char *`, e.g. `"on_load"`).
  external Pointer<Void> name;

  /// The hook id to pass to `mpv_hook_continue` once handling completes.
  @Uint64()
  external int id;
}

// ---------------------------------------------------------------------------
// Function typedefs — native side
// ---------------------------------------------------------------------------

// mpv_handle *mpv_create(void)
typedef _MpvCreateNative = Pointer<MpvHandle> Function();

/// Dart signature for `mpv_create` — allocates a new mpv client handle.
typedef MpvCreate = Pointer<MpvHandle> Function();

// int mpv_initialize(mpv_handle *ctx)
typedef _MpvInitializeNative = Int32 Function(Pointer<MpvHandle> ctx);

/// Dart signature for `mpv_initialize` — starts the mpv core for [ctx].
typedef MpvInitialize = int Function(Pointer<MpvHandle> ctx);

// void mpv_terminate_destroy(mpv_handle *ctx)
typedef _MpvTerminateDestroyNative = Void Function(Pointer<MpvHandle> ctx);

/// Dart signature for `mpv_terminate_destroy` — stops the core and releases
/// [ctx], blocking until shutdown completes.
typedef MpvTerminateDestroy = void Function(Pointer<MpvHandle> ctx);

// void mpv_wakeup(mpv_handle *ctx)
typedef _MpvWakeupNative = Void Function(Pointer<MpvHandle> ctx);

/// Dart signature for `mpv_wakeup` — interrupts a thread parked in
/// `mpv_wait_event` on [ctx], making that call return `MPV_EVENT_NONE`. If no
/// thread is currently waiting, the next `mpv_wait_event` returns immediately
/// (libmpv guarantees no lost wakeups). Safe to call from any thread.
typedef MpvWakeup = void Function(Pointer<MpvHandle> ctx);

// int mpv_set_option_string(mpv_handle *ctx, const char *name, const char *data)
typedef _MpvSetOptionStringNative = Int32 Function(
    Pointer<MpvHandle> ctx, Pointer<Utf8> name, Pointer<Utf8> data,);

/// Dart signature for `mpv_set_option_string` — sets a pre-init option by name.
typedef MpvSetOptionString = int Function(
    Pointer<MpvHandle> ctx, Pointer<Utf8> name, Pointer<Utf8> data,);

// int mpv_set_property_string(mpv_handle *ctx, const char *name, const char *data)
typedef _MpvSetPropertyStringNative = Int32 Function(
    Pointer<MpvHandle> ctx, Pointer<Utf8> name, Pointer<Utf8> data,);

/// Dart signature for `mpv_set_property_string` — sets a property from a
/// string value.
typedef MpvSetPropertyString = int Function(
    Pointer<MpvHandle> ctx, Pointer<Utf8> name, Pointer<Utf8> data,);

// char *mpv_get_property_string(mpv_handle *ctx, const char *name)
typedef _MpvGetPropertyStringNative = Pointer<Utf8> Function(
    Pointer<MpvHandle> ctx, Pointer<Utf8> name,);

/// Dart signature for `mpv_get_property_string` — reads a property as a
/// newly allocated string the caller must release with `mpv_free`.
typedef MpvGetPropertyString = Pointer<Utf8> Function(
    Pointer<MpvHandle> ctx, Pointer<Utf8> name,);

// int mpv_get_property(mpv_handle*, const char*, int format, void *data)
typedef _MpvGetPropertyNative = Int32 Function(Pointer<MpvHandle> ctx,
    Pointer<Utf8> name, Int32 format, Pointer<Void> data,);

/// Dart signature for `mpv_get_property` — reads a property into `data`
/// using the given [MpvFormat].
typedef MpvGetProperty = int Function(
    Pointer<MpvHandle> ctx, Pointer<Utf8> name, int format, Pointer<Void> data,);

// int mpv_set_property(mpv_handle*, const char*, int format, void *data)
typedef _MpvSetPropertyNative = Int32 Function(Pointer<MpvHandle> ctx,
    Pointer<Utf8> name, Int32 format, Pointer<Void> data,);

/// Dart signature for `mpv_set_property` — writes a property from `data`
/// using the given [MpvFormat].
typedef MpvSetProperty = int Function(
    Pointer<MpvHandle> ctx, Pointer<Utf8> name, int format, Pointer<Void> data,);

// int mpv_set_property_async(mpv_handle*, uint64_t reply_userdata,
//                            const char *name, int format, void *data)
typedef _MpvSetPropertyAsyncNative = Int32 Function(Pointer<MpvHandle> ctx,
    Uint64 replyUserdata, Pointer<Utf8> name, Int32 format, Pointer<Void> data,);

/// Dart signature for `mpv_set_property_async` — queues a property write and
/// returns immediately; libmpv deep-copies [name] and the value before
/// returning, and delivers the outcome as an `MPV_EVENT_SET_PROPERTY_REPLY`
/// tagged with `reply_userdata`. Unlike the synchronous setter it never
/// waits for the core's playloop, so it cannot stall the calling isolate.
typedef MpvSetPropertyAsync = int Function(Pointer<MpvHandle> ctx,
    int replyUserdata, Pointer<Utf8> name, int format, Pointer<Void> data,);

// int mpv_get_property_async(mpv_handle*, uint64_t reply_userdata,
//                            const char *name, int format)
typedef _MpvGetPropertyAsyncNative = Int32 Function(Pointer<MpvHandle> ctx,
    Uint64 replyUserdata, Pointer<Utf8> name, Int32 format,);

/// Dart signature for `mpv_get_property_async` — queues a property read and
/// returns immediately; the value arrives as an `MPV_EVENT_GET_PROPERTY_REPLY`
/// carrying an `mpv_event_property` payload, tagged with `reply_userdata`.
typedef MpvGetPropertyAsync = int Function(
    Pointer<MpvHandle> ctx, int replyUserdata, Pointer<Utf8> name, int format,);

// int mpv_command_async(mpv_handle *ctx, uint64_t reply_userdata, const char **args)
typedef _MpvCommandAsyncNative = Int32 Function(Pointer<MpvHandle> ctx,
    Uint64 replyUserdata, Pointer<Pointer<Utf8>> args,);

/// Dart signature for `mpv_command_async` — parses [args] client-side,
/// queues the command and returns immediately; the outcome arrives as an
/// `MPV_EVENT_COMMAND_REPLY` tagged with `reply_userdata`.
typedef MpvCommandAsync = int Function(
    Pointer<MpvHandle> ctx, int replyUserdata, Pointer<Pointer<Utf8>> args,);

// int mpv_command(mpv_handle *ctx, const char **args)
typedef _MpvCommandNative = Int32 Function(
    Pointer<MpvHandle> ctx, Pointer<Pointer<Utf8>> args,);

/// Dart signature for `mpv_command` — runs a command from a null-terminated
/// argument array.
typedef MpvCommand = int Function(
    Pointer<MpvHandle> ctx, Pointer<Pointer<Utf8>> args,);

// int mpv_command_string(mpv_handle *ctx, const char *args)
typedef _MpvCommandStringNative = Int32 Function(
    Pointer<MpvHandle> ctx, Pointer<Utf8> args,);

/// Dart signature for `mpv_command_string` — runs a command from a single
/// command-line string.
typedef MpvCommandString = int Function(
    Pointer<MpvHandle> ctx, Pointer<Utf8> args,);

// mpv_event *mpv_wait_event(mpv_handle *ctx, double timeout)
typedef _MpvWaitEventNative = Pointer<MpvEvent> Function(
    Pointer<MpvHandle> ctx, Double timeout,);

/// Dart signature for `mpv_wait_event` — blocks up to `timeout` seconds for
/// the next [MpvEvent].
typedef MpvWaitEvent = Pointer<MpvEvent> Function(
    Pointer<MpvHandle> ctx, double timeout,);

// int mpv_observe_property(mpv_handle*, uint64_t reply_userdata, const char*, int format)
typedef _MpvObservePropertyNative = Int32 Function(Pointer<MpvHandle> ctx,
    Uint64 replyUserdata, Pointer<Utf8> name, Int32 format,);

/// Dart signature for `mpv_observe_property` — subscribes to change events
/// for a property, tagged with `reply_userdata`.
typedef MpvObserveProperty = int Function(
    Pointer<MpvHandle> ctx, int replyUserdata, Pointer<Utf8> name, int format,);

// void mpv_free(void *data)
typedef _MpvFreeNative = Void Function(Pointer<Void> data);

/// Dart signature for `mpv_free` — frees memory allocated by libmpv.
typedef MpvFree = void Function(Pointer<Void> data);

// void mpv_free_node_contents(mpv_node *node)
typedef _MpvFreeNodeContentsNative = Void Function(Pointer<MpvNode> node);

/// Dart signature for `mpv_free_node_contents` — frees memory owned by the
/// contents of an [MpvNode].
typedef MpvFreeNodeContents = void Function(Pointer<MpvNode> node);

// const char *mpv_error_string(int error)
typedef _MpvErrorStringNative = Pointer<Utf8> Function(Int32 error);

/// Dart signature for `mpv_error_string` — maps an [MpvError] code to a
/// human-readable description.
typedef MpvErrorString = Pointer<Utf8> Function(int error);

// int mpv_request_log_messages(mpv_handle*, const char *min_level)
typedef _MpvRequestLogMessagesNative = Int32 Function(
    Pointer<MpvHandle> ctx, Pointer<Utf8> minLevel,);

/// Dart signature for `mpv_request_log_messages` — enables log-message events
/// at or above `min_level`.
typedef MpvRequestLogMessages = int Function(
    Pointer<MpvHandle> ctx, Pointer<Utf8> minLevel,);

// int mpv_hook_add(mpv_handle *ctx, uint64_t reply_userdata, const char *name, int priority)
typedef _MpvHookAddNative = Int32 Function(Pointer<MpvHandle> ctx,
    Uint64 replyUserdata, Pointer<Utf8> name, Int32 priority,);

/// Dart signature for `mpv_hook_add` — registers a hook handler for the named
/// hook at the given priority.
typedef MpvHookAdd = int Function(Pointer<MpvHandle> ctx, int replyUserdata,
    Pointer<Utf8> name, int priority,);

// int mpv_hook_continue(mpv_handle *ctx, uint64_t id)
typedef _MpvHookContinueNative = Int32 Function(
    Pointer<MpvHandle> ctx, Uint64 id,);

/// Dart signature for `mpv_hook_continue` — resumes mpv after a hook with the
/// given id has been handled.
typedef MpvHookContinue = int Function(Pointer<MpvHandle> ctx, int id);

// ---------------------------------------------------------------------------
// Loaded library wrapper
// ---------------------------------------------------------------------------

/// Holds an opened libmpv [DynamicLibrary] and the resolved client-API
/// function pointers, looked up once at construction.
class MpvLibrary {
  final DynamicLibrary _lib;

  /// Bound `mpv_create`.
  late final MpvCreate mpvCreate;

  /// Bound `mpv_initialize`.
  late final MpvInitialize mpvInitialize;

  /// Bound `mpv_terminate_destroy`.
  late final MpvTerminateDestroy mpvTerminateDestroy;

  /// Bound `mpv_wakeup` — unblocks a parked `mpv_wait_event`.
  late final MpvWakeup mpvWakeup;

  /// Bound `mpv_set_option_string`.
  late final MpvSetOptionString mpvSetOptionString;

  /// Bound `mpv_set_property_string`.
  late final MpvSetPropertyString mpvSetPropertyString;

  /// Bound `mpv_get_property_string`.
  late final MpvGetPropertyString mpvGetPropertyString;

  /// Bound `mpv_get_property`.
  late final MpvGetProperty mpvGetProperty;

  /// Bound `mpv_set_property`.
  late final MpvSetProperty mpvSetProperty;

  /// Bound `mpv_set_property_async`.
  late final MpvSetPropertyAsync mpvSetPropertyAsync;

  /// Bound `mpv_get_property_async`.
  late final MpvGetPropertyAsync mpvGetPropertyAsync;

  /// Bound `mpv_command_async`.
  late final MpvCommandAsync mpvCommandAsync;

  /// Bound `mpv_command`.
  late final MpvCommand mpvCommand;

  /// Bound `mpv_command_string`.
  late final MpvCommandString mpvCommandString;

  /// Bound `mpv_wait_event`.
  late final MpvWaitEvent mpvWaitEvent;

  /// Bound `mpv_observe_property`.
  late final MpvObserveProperty mpvObserveProperty;

  /// Bound `mpv_free`.
  late final MpvFree mpvFree;

  /// Bound `mpv_free_node_contents`.
  late final MpvFreeNodeContents mpvFreeNodeContents;

  /// Bound `mpv_error_string`.
  late final MpvErrorString mpvErrorString;

  /// Bound `mpv_request_log_messages`.
  late final MpvRequestLogMessages mpvRequestLogMessages;

  /// Bound `mpv_hook_add`.
  late final MpvHookAdd mpvHookAdd;

  /// Bound `mpv_hook_continue`.
  late final MpvHookContinue mpvHookContinue;

  /// Creates a wrapper from an already opened library (same process).
  factory MpvLibrary.fromExisting(DynamicLibrary lib) => MpvLibrary._(lib);

  /// Test-only: builds an [MpvLibrary] with every `mpv*` field left
  /// as an unassigned `late final`. The caller must set the entries
  /// it exercises; touching an unset one throws
  /// [LateInitializationError], so misuse surfaces as a test failure
  /// instead of a silent FFI crash.
  @visibleForTesting
  MpvLibrary.uninitializedForTest() : _lib = DynamicLibrary.process();

  MpvLibrary._(this._lib) {
    mpvCreate = _lib.lookupFunction<_MpvCreateNative, MpvCreate>('mpv_create');
    mpvInitialize = _lib
        .lookupFunction<_MpvInitializeNative, MpvInitialize>('mpv_initialize');
    mpvTerminateDestroy =
        _lib.lookupFunction<_MpvTerminateDestroyNative, MpvTerminateDestroy>(
            'mpv_terminate_destroy',);
    // isLeaf: documented non-blocking and callback-free (libmpv client.h),
    // so the call skips the generated trampoline's thread-state transition.
    // NEVER mark a call that can block on the core (wait_event, command,
    // set/get property) or re-enter Dart as leaf.
    mpvWakeup = _lib.lookupFunction<_MpvWakeupNative, MpvWakeup>('mpv_wakeup',
        isLeaf: true,);
    mpvSetOptionString =
        _lib.lookupFunction<_MpvSetOptionStringNative, MpvSetOptionString>(
            'mpv_set_option_string',);
    mpvSetPropertyString =
        _lib.lookupFunction<_MpvSetPropertyStringNative, MpvSetPropertyString>(
            'mpv_set_property_string',);
    mpvGetPropertyString =
        _lib.lookupFunction<_MpvGetPropertyStringNative, MpvGetPropertyString>(
            'mpv_get_property_string',);
    mpvGetProperty = _lib.lookupFunction<_MpvGetPropertyNative, MpvGetProperty>(
        'mpv_get_property',);
    mpvSetProperty = _lib.lookupFunction<_MpvSetPropertyNative, MpvSetProperty>(
        'mpv_set_property',);
    // The async variants enqueue on the core's dispatch and return without
    // waiting for the playloop (verified against the bundled source:
    // `run_async` = reserve_reply + mp_dispatch_enqueue; name/value are
    // deep-copied first). They still take short-lived internal locks, so
    // they are NOT leaf-safe.
    mpvSetPropertyAsync =
        _lib.lookupFunction<_MpvSetPropertyAsyncNative, MpvSetPropertyAsync>(
            'mpv_set_property_async',);
    mpvGetPropertyAsync =
        _lib.lookupFunction<_MpvGetPropertyAsyncNative, MpvGetPropertyAsync>(
            'mpv_get_property_async',);
    mpvCommandAsync =
        _lib.lookupFunction<_MpvCommandAsyncNative, MpvCommandAsync>(
            'mpv_command_async',);
    mpvCommand =
        _lib.lookupFunction<_MpvCommandNative, MpvCommand>('mpv_command');
    mpvCommandString =
        _lib.lookupFunction<_MpvCommandStringNative, MpvCommandString>(
            'mpv_command_string',);
    mpvWaitEvent = _lib
        .lookupFunction<_MpvWaitEventNative, MpvWaitEvent>('mpv_wait_event');
    mpvObserveProperty =
        _lib.lookupFunction<_MpvObservePropertyNative, MpvObserveProperty>(
            'mpv_observe_property',);
    mpvFree =
        _lib.lookupFunction<_MpvFreeNative, MpvFree>('mpv_free', isLeaf: true);
    mpvFreeNodeContents =
        _lib.lookupFunction<_MpvFreeNodeContentsNative, MpvFreeNodeContents>(
            'mpv_free_node_contents', isLeaf: true,);
    mpvErrorString = _lib.lookupFunction<_MpvErrorStringNative, MpvErrorString>(
        'mpv_error_string', isLeaf: true,);
    mpvRequestLogMessages = _lib.lookupFunction<_MpvRequestLogMessagesNative,
        MpvRequestLogMessages>('mpv_request_log_messages');
    mpvHookAdd =
        _lib.lookupFunction<_MpvHookAddNative, MpvHookAdd>('mpv_hook_add');
    mpvHookContinue =
        _lib.lookupFunction<_MpvHookContinueNative, MpvHookContinue>(
            'mpv_hook_continue',);
  }

  /// Opens libmpv from the platform-specific path or a custom [path].
  /// Throws [MpvLibraryException] if the library cannot be found.
  factory MpvLibrary.open([String? path]) {
    final resolvedPath = path ?? _resolvePath();
    try {
      return MpvLibrary._(DynamicLibrary.open(resolvedPath));
    } catch (e) {
      throw MpvLibraryException('Failed to load libmpv from "$resolvedPath".\n'
          'Error: $e\n'
          'Ensure the library is present and all its dependencies are installed.');
    }
  }

  static String _resolvePath() {
    if (Platform.isMacOS || Platform.isIOS) {
      // Embedded as <App>/Frameworks/libmpv.framework/libmpv via the
      // plugin's xcframework. dyld resolves the leaf path through the
      // host app's LC_RPATH (@executable_path/Frameworks).
      return 'libmpv.framework/libmpv';
    } else if (Platform.isLinux) {
      // Check local folder first (common for portable builds/AppImage)
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final localSo = '$exeDir/lib/libmpv.so';
      final bundleSo = '$exeDir/libmpv.so';

      if (File(localSo).existsSync()) {
        return localSo;
      }
      if (File(bundleSo).existsSync()) {
        return bundleSo;
      }

      // Fallback to system search path
      return 'libmpv.so';
    } else if (Platform.isWindows) {
      // On Windows, use an absolute path relative to the executable.
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final localDll = '$exeDir\\libmpv.dll';
      if (File(localDll).existsSync()) {
        return localDll;
      }
      // Fallback to searching in PATH.
      return 'libmpv.dll';
    } else if (Platform.isAndroid) {
      // Precompiled in android/src/main/jniLibs/<abi>/libmpv.so
      return 'libmpv.so';
    }
    throw MpvLibraryException(
        'Platform not supported: ${Platform.operatingSystem}',);
  }
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
