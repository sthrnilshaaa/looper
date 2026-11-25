// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The libmpv module in WebAssembly (libmpv.mjs and libmpv.wasm, built by
// libmpv-scripts with Emscripten) seen from Dart: the exported C functions,
// the memory, and the decoding of the client API structs at their wasm32
// offsets. Pointers are wasm32 addresses, plain ints; the 64-bit arguments
// (reply ids, hook ids, PCM ids) cross as JavaScript BigInts.

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../../internals/event_decoder.dart';
import 'web_layout.dart';

@JS('BigInt')
external JSBigInt _bigInt(JSNumber value);

@JS('Number')
external JSNumber _number(JSBigInt value);

/// [value] as a JavaScript BigInt, for a 64-bit argument.
@internal
JSBigInt bigInt(int value) => _bigInt(value.toJS);

/// The BigInt [value] of a 64-bit result as an int (exact below 2^53).
@internal
int bigIntValue(JSBigInt value) => _number(value).toDartInt;

/// The longest run so far of each call that waits for the core on the
/// main thread (`mpv_initialize`, `mpv_hook_add`, `mpv_hook_continue`,
/// `mpv_terminate_destroy` and the like), in microseconds, by C name: the
/// measure behind running them there rather than on a service thread.
@visibleForTesting
final Map<String, int> webCallMaxMicros = {};

/// Runs [body], the call [name] of the module, and records its length in
/// [webCallMaxMicros].
@internal
T timedCall<T>(String name, T Function() body) {
  final clock = Stopwatch()..start();
  try {
    return body();
  } finally {
    final micros = clock.elapsedMicroseconds;
    if (micros > (webCallMaxMicros[name] ?? -1)) {
      webCallMaxMicros[name] = micros;
    }
  }
}

@JS('DataView')
extension type _View._(JSObject _) implements JSObject {
  external _View(JSObject buffer);
  external int getInt32(int byteOffset, bool littleEndian);
  external int getUint32(int byteOffset, bool littleEndian);
  external double getFloat64(int byteOffset, bool littleEndian);
  external void setInt32(int byteOffset, int value, bool littleEndian);
  external void setUint32(int byteOffset, int value, bool littleEndian);
  external void setFloat64(int byteOffset, double value, bool littleEndian);
}

@JS('Uint8Array')
extension type _Bytes._(JSObject _) implements JSObject {
  external _Bytes(JSObject buffer, int byteOffset, int length);
  external JSUint8Array slice();
  external void set(JSUint8Array source, int offset);
}

/// The exported C functions and runtime helpers of the module, by their
/// Emscripten names.
@internal
extension type MpvExports._(JSObject _) implements JSObject {
  @JS('_mpv_create')
  external int mpvCreate();
  @JS('_mpv_create_client')
  external int mpvCreateClient(int ctx, int name);
  @JS('_mpv_initialize')
  external int mpvInitialize(int ctx);
  @JS('_mpv_terminate_destroy')
  external void mpvTerminateDestroy(int ctx);
  @JS('_mpv_destroy')
  external void mpvDestroy(int ctx);
  @JS('_mpv_set_option_string')
  external int mpvSetOptionString(int ctx, int name, int value);
  @JS('_mpv_set_property_string')
  external int mpvSetPropertyString(int ctx, int name, int value);
  @JS('_mpv_request_log_messages')
  external int mpvRequestLogMessages(int ctx, int level);
  @JS('_mpv_request_event')
  external int mpvRequestEvent(int ctx, int event, int enable);
  @JS('_mpv_observe_property')
  external int mpvObserveProperty(int ctx, JSBigInt id, int name, int format);
  @JS('_mpv_wait_event')
  external int mpvWaitEvent(int ctx, double timeout);
  @JS('_mpv_set_property_async')
  external int mpvSetPropertyAsync(
    int ctx,
    JSBigInt id,
    int name,
    int format,
    int data,
  );
  @JS('_mpv_get_property_async')
  external int mpvGetPropertyAsync(int ctx, JSBigInt id, int name, int format);
  @JS('_mpv_command_async')
  external int mpvCommandAsync(int ctx, JSBigInt id, int args);
  @JS('_mpv_hook_add')
  external int mpvHookAdd(int ctx, JSBigInt id, int name, int priority);
  @JS('_mpv_hook_continue')
  external int mpvHookContinue(int ctx, JSBigInt id);
  @JS('_mpv_error_string')
  external int mpvErrorString(int error);
  @JS('_mak_web_wakeup_attach')
  external int wakeupAttach(int ctx);
  @JS('_mak_web_wakeup_detach')
  external void wakeupDetach(int bridge);
  @JS('_mak_web_abi_version')
  external int abiVersion();
  @JS('_mak_web_layout')
  external int layout();
  @JS('_malloc')
  external int malloc(int size);
  @JS('_free')
  external void free(int pointer);
  @JS('_mak_pcm_create')
  external JSBigInt pcmCreate(JSBigInt capacity);
  @JS('_mak_pcm_write')
  external JSBigInt pcmWrite(JSBigInt id, int data, JSBigInt length);
  @JS('_mak_pcm_finish')
  external int pcmFinish(JSBigInt id);
  @JS('_mak_pcm_abort')
  external int pcmAbort(JSBigInt id);
  @JS('_mak_pcm_buffered')
  external JSBigInt pcmBuffered(JSBigInt id);
  @JS('_mak_pcm_state')
  external int pcmState(JSBigInt id);
  @JS('_mak_pcm_release')
  external int pcmRelease(JSBigInt id);
  @JS('_mak_pcm_release_all')
  external void pcmReleaseAll();
  @JS('_mpv_command_string')
  external int mpvCommandString(int ctx, int args);
  @JS('_mak_webio_live_streams')
  external int webioLiveStreams();
  @JS('UTF8ToString')
  external JSString utf8ToString(int pointer);
  @JS('stringToNewUTF8')
  external int stringToNewUtf8(JSString value);
  external JSObject get wasmMemory;
  external MakWebAudio get makWebAudio;
}

/// `Module.makWebAudio` of the module (scripts/web/mak_webaudio.js of
/// libmpv-scripts): the AudioContext the webaudio output plays into, its
/// AudioWorklet, and the resume at the first user gesture.
@internal
extension type MakWebAudio._(JSObject _) implements JSObject {
  /// Makes the AudioContext and loads the worklet; a second call replaces
  /// the context, and every open output reopens on the new one.
  external JSPromise<JSObject> init([JSObject? options]);

  /// Resumes the context, which the autoplay policy starts suspended.
  external JSPromise<JSAny?> resume();

  /// Closes the context: open outputs fail until the next [init].
  external JSPromise<JSAny?> close();

  /// Calls [listener] with the context's state at each change; returns the
  /// function that removes it.
  external JSFunction onStateChange(JSFunction listener);

  /// `none` before [init], then the AudioContext's state.
  external String get state;

  /// The AudioWorkletNode of output [id], made on first use.
  external JSObject output([int id]);

  /// The AudioContext, `null` before [init].
  external JSObject? get context;
}

/// One instance of the libmpv module: its exports, its memory, and the
/// wakeup bridge that calls back into Dart.
@internal
final class MpvModule implements CoreMemory {
  /// Wraps the instance [module] the module factory resolved with, after
  /// checking its ABI version and its struct layout against the ones the
  /// decoders assume, before any other call into it. [processorUrl] is
  /// where the webaudio output's worklet is, when not beside the module.
  MpvModule(JSObject module, {this.processorUrl})
    : instance = module,
      _m = MpvExports._(module) {
    checkWebModuleAbi(_m.has('_mak_web_abi_version') ? _m.abiVersion() : null);
    checkWebLayout(_layoutTable());
    // One callback per module: mak_web.c posts it to the main thread, at
    // most once per handle until it runs, whenever mpv wakes that client.
    // Emscripten also runs that posted work while the main thread waits for
    // a lock inside a call of the module (a busy wait that "assists" the
    // other threads), so the callback can come in the middle of a drain or
    // a read. It only schedules the work, which runs once the call that was
    // waiting has returned.
    _m['onMpvWakeup'] = ((JSNumber handle) {
      final h = handle.toDartInt;
      if (!_wakeups.containsKey(h) || !_scheduled.add(h)) return;
      scheduleMicrotask(() {
        _scheduled.remove(h);
        _wakeups[h]?.call();
      });
    }).toJS;
  }

  /// The module instance, as the factory resolved it.
  final JSObject instance;

  /// Where mak_webaudio_processor.js is, when not beside libmpv.mjs.
  final String? processorUrl;

  final MpvExports _m;
  final Map<int, void Function()> _wakeups = {};
  final Set<int> _scheduled = {};

  /// The exported C functions.
  MpvExports get c => _m;

  /// The module's `mak_web_layout()`, up to its `-1` end.
  List<int> _layoutTable() {
    final table = _m.layout();
    final view = _view();
    final values = <int>[];
    for (var i = 0; i < 64; i++) {
      final v = view.getInt32(table + 4 * i, true);
      if (v < 0) break;
      values.add(v);
    }
    return values;
  }

  /// Calls [onWakeup] on the main thread whenever mpv wakes client
  /// [handle], until [detachWakeup]. Returns the bridge.
  int attachWakeup(int handle, void Function() onWakeup) {
    _wakeups[handle] = onWakeup;
    return _m.wakeupAttach(handle);
  }

  /// Stops the wakeups of [handle] through [bridge].
  void detachWakeup(int handle, int bridge) {
    _wakeups.remove(handle);
    _m.wakeupDetach(bridge);
  }

  // The memory can grow, which replaces the buffer: the view is kept for
  // as long as the memory hands out the buffer it was made on, and made
  // again on the new one. Decoding a node reads thousands of fields.
  _View _view() {
    final buffer = _m.wasmMemory['buffer'] as JSObject;
    final view = _viewCache;
    if (view != null && buffer.strictEquals(_viewBuffer).toDart) return view;
    _viewBuffer = buffer;
    return _viewCache = _View(buffer);
  }

  JSObject? _viewBuffer;
  _View? _viewCache;

  @override
  int get pointerSize => 4;

  /// The signed 32-bit value at [p].
  @override
  int i32(int p) => _view().getInt32(p, true);

  /// The unsigned 32-bit value at [p] (a pointer, a size_t).
  int u32(int p) => _view().getUint32(p, true);

  /// A pointer or a `size_t` at [p]: wasm32 has 32-bit ones.
  @override
  int pointer(int p) => u32(p);

  /// The signed 64-bit value at [p] (exact below 2^53).
  @override
  int i64(int p) {
    final view = _view();
    return view.getInt32(p + 4, true) * 4294967296 + view.getUint32(p, true);
  }

  /// The double at [p].
  @override
  double f64(int p) => _view().getFloat64(p, true);

  /// The NUL-terminated string at [p], malformed UTF-8 replaced with
  /// U+FFFD as on the native side; `null` for a null pointer.
  @override
  String? string(int p) => p == 0 ? null : _m.utf8ToString(p).toDart;

  /// A copy of the [length] bytes at [p]. [transfer] changes nothing: the
  /// web pump runs on the main thread.
  @override
  Uint8List bytes(int p, int length, {bool transfer = false}) {
    if (length <= 0) return Uint8List(0);
    final buffer = _m.wasmMemory['buffer'] as JSObject;
    return _Bytes(buffer, p, length).slice().toDart;
  }

  /// Copies [data] to the module's memory at [p].
  void writeBytes(int p, Uint8List data) {
    final buffer = _m.wasmMemory['buffer'] as JSObject;
    _Bytes(buffer, p, data.length).set(data.toJS, 0);
  }

  /// Writes the 32-bit [value] at [p].
  void setU32(int p, int value) => _view().setUint32(p, value, true);

  /// Writes the signed 32-bit [value] at [p].
  void setI32(int p, int value) => _view().setInt32(p, value, true);

  /// Writes the signed 64-bit [value] at [p] (exact below 2^53).
  void setI64(int p, int value) {
    final view = _view();
    final hi = (value / 4294967296).floor();
    view.setUint32(p, value - hi * 4294967296, true);
    view.setInt32(p + 4, hi, true);
  }

  /// Writes the double [value] at [p].
  void setF64(int p, double value) => _view().setFloat64(p, value, true);

  /// A copy of [value] in the module's memory, NUL-terminated; free it with
  /// [free]. Throws [WebOutOfMemory] when the module has no room for it.
  int newString(String value) =>
      _allocated(_m.stringToNewUtf8(value.toJS), value.length + 1);

  /// Allocates [size] bytes of the module's memory. Throws
  /// [WebOutOfMemory] when the module has no room for them.
  int malloc(int size) => _allocated(_m.malloc(size), size);

  // The memory has a ceiling ([webModuleMemory]) and malloc returns NULL
  // past it: a write there would land on the module's own low memory.
  int _allocated(int pointer, int size) {
    if (pointer == 0 && size > 0) throw WebOutOfMemory._(size);
    return pointer;
  }

  /// Frees [pointer], allocated with [malloc] or [newString].
  void free(int pointer) => _m.free(pointer);

  /// Runs [body] with [values] copied to the module's memory as strings,
  /// freed when it returns.
  T withStrings<T>(List<String> values, T Function(List<int> pointers) body) {
    final pointers = <int>[];
    try {
      for (final v in values) {
        pointers.add(newString(v));
      }
      return body(pointers);
    } finally {
      for (final p in pointers) {
        free(p);
      }
    }
  }
}

/// The pages of 64 KiB the module's memory starts with: the 32 MB its
/// build starts from (`INITIAL_MEMORY`), and the least a memory passed to
/// the factory may have.
@internal
const int kWebMemoryInitialPages = 512;

/// The most pages the module's memory grows to: 512 MiB.
@internal
const int kWebMemoryMaximumPages = 8192;

/// The most pages on WebKit for phones and tablets, which refuses a shared
/// memory that large or kills the page past a few hundred MB: 256 MiB.
@internal
const int kWebMemoryMobileMaximumPages = 4096;

/// Test-only: whether to take the profile of WebKit for phones and tablets
/// ([kWebMemoryMobileMaximumPages]) whatever the browser, or never. `null`
/// asks the browser.
@visibleForTesting
bool? debugWebKitMobile;

@JS('navigator')
external JSObject get _navigator;

/// Whether the page runs on WebKit for phones and tablets: an iPhone, an
/// iPod or an iPad, which says it is a Mac with a touch screen.
bool get _webKitMobile {
  final forced = debugWebKitMobile;
  if (forced != null) return forced;
  final agent = (_navigator['userAgent'] as JSString?)?.toDart ?? '';
  if (RegExp('iPhone|iPad|iPod').hasMatch(agent)) return true;
  final touch = (_navigator['maxTouchPoints'] as JSNumber?)?.toDartInt ?? 0;
  return agent.contains('Macintosh') && touch > 1;
}

@JS('WebAssembly.Memory')
extension type _Memory._(JSObject _) implements JSObject {
  external _Memory(JSObject descriptor);
}

/// A shared memory of [maximum] pages that starts at
/// [kWebMemoryInitialPages], or `null` when the browser refuses it.
JSObject? _memory(int maximum) {
  final descriptor = JSObject()
    ..['initial'] = kWebMemoryInitialPages.toJS
    ..['maximum'] = maximum.toJS
    ..['shared'] = true.toJS;
  try {
    return _Memory(descriptor);
  } catch (_) {
    return null;
  }
}

/// The memory the package hands the module's factory: shared, 32 MB at
/// the start, growing up to 512 MiB, or 256 MiB on WebKit for phones and
/// tablets and wherever the larger one is refused. The module's own
/// ceiling is 2 GB, more than such a browser gives a page. `null` when
/// even the smaller one is refused: the module then makes its own.
@internal
JSObject? webModuleMemory() {
  if (!_webKitMobile) {
    final memory = _memory(kWebMemoryMaximumPages);
    if (memory != null) return memory;
  }
  return _memory(kWebMemoryMobileMaximumPages);
}

/// Imports the module at [url] (libmpv.mjs) and instantiates it on the
/// memory of [webModuleMemory]. [wasmUrl] is where libmpv.wasm is, and
/// [processorUrl] where mak_webaudio_processor.js is, when not beside
/// [url].
///
/// The factory waits for the module's threads, and never settles when
/// their workers cannot load: a file served without COEP, a
/// Content-Security-Policy that leaves them out, a module on another
/// origin. Past [timeout] it fails with a [WebModuleTimeout]. The 30 s
/// count from the import, so a libmpv.wasm still on its way counts as
/// well. The start goes on: a later load of [url] in the same program
/// waits for that same start again, rather than making a second module.
@internal
Future<MpvModule> loadMpvModule(
  String url, {
  String? wasmUrl,
  String? processorUrl,
  Duration timeout = const Duration(seconds: 30),
}) async {
  final start = _starting[url] ??= _startModule(url, wasmUrl);
  final JSAny? instance;
  try {
    instance = await start.timeout(
      timeout,
      onTimeout: () => throw WebModuleTimeout._(
        'mpv_audio_kit: the web module did not start within '
        '${timeout.inSeconds} s: libmpv.wasm is still loading, or the '
        'workers of its threads did not load. Serve every file with the '
        'COOP and COEP headers, libmpv.mjs and libmpv.wasm included, from '
        'the origin of the page, and let a Content-Security-Policy allow '
        'them as workers',
      ),
    );
  } on WebModuleTimeout {
    rethrow;
  } catch (_) {
    _starting.remove(url)?.ignore();
    rethrow;
  }
  _starting.remove(url)?.ignore();
  return MpvModule(instance as JSObject, processorUrl: processorUrl);
}

/// The starts of [loadMpvModule] still going, by URL, in this program: a
/// Hot Restart forgets them.
final Map<String, Future<JSAny?>> _starting = {};

Future<JSAny?> _startModule(String url, String? wasmUrl) async {
  final namespace = await importModule(url.toJS).toDart;
  final factory = namespace['default'] as JSFunction;
  final options = JSObject();
  if (wasmUrl != null) {
    options['locateFile'] = ((JSString path) => wasmUrl.toJS).toJS;
  }
  final memory = webModuleMemory();
  if (memory != null) options['wasmMemory'] = memory;
  return (factory.callAsFunction(null, options) as JSPromise).toDart;
}

/// The web module's malloc returned NULL: its memory reached the ceiling
/// of [webModuleMemory], or the browser refused to grow it.
@internal
final class WebOutOfMemory extends StateError {
  WebOutOfMemory._(int size)
    : super(
        'mpv_audio_kit: the web module is out of memory (an allocation of '
        '$size bytes failed)',
      );
}

/// The web module did not start within the time [loadMpvModule] waits.
/// Its start goes on, and a later load waits for it again.
@internal
final class WebModuleTimeout extends StateError {
  WebModuleTimeout._(super.message);
}
