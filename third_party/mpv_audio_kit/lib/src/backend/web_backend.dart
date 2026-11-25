// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:meta/meta.dart';

import '../pcm/pcm_native.dart';
import 'mpv_session.dart';
import 'web/mpv_module.dart';
import 'web/web_audio.dart';
import 'web/web_pcm.dart';
import 'web/web_registry.dart';
import 'web/web_session.dart';

/// The module (libmpv.mjs, with libmpv.wasm and mak_webaudio_processor.js
/// beside it) as a web asset of the package, which Flutter serves at
/// `assets/packages/mpv_audio_kit/web/libmpv.mjs`: loaded when
/// `MpvAudioKit.ensureInitialized` names no other.
@internal
const String kWebModuleAsset = 'packages/mpv_audio_kit/web/libmpv.mjs';

/// The gain options of the webaudio output, which `ao-volume` and
/// `ao-mute` set while an output is open and which a new output starts
/// from: `setSystemVolume` and `setSystemMute` write them before one is.
@internal
const String kOutputVolumeOption = 'webaudio-volume';

/// See [kOutputVolumeOption].
@internal
const String kOutputMuteOption = 'webaudio-mute';

@JS('URL')
extension type _Url._(JSObject _) implements JSObject {
  external _Url(String url, String base);
  external String get href;
}

@JS('document.baseURI')
external String get _baseUri;

/// [url] made absolute against the page: the module's workers resolve a
/// relative URL against their own script, not the page.
String _absolute(String url) => _Url(url, _baseUri).href;

/// The module and the page's output, once loaded.
final class _Loaded {
  _Loaded(this.module, this.output);
  final MpvModule module;
  final WebAudioOutput output;
}

String? _url;
bool _reap = false;
Future<_Loaded>? _loading;
_Loaded? _loaded;
Object? _failure;
final StreamController<bool> _gestureChanges =
    StreamController<bool>.broadcast();

/// Test-only: the module every session uses, in place of loading the one
/// at the URL `MpvAudioKit.ensureInitialized` got.
@visibleForTesting
Future<MpvModule>? debugWebModule;

/// Test-only: how long the load of the module waits for its start.
@visibleForTesting
Duration debugWebModuleTimeout = const Duration(seconds: 30);

Future<_Loaded> _load() => _loading ??= _start();

/// Why libmpv cannot run in this page, or `null` when it can. Its threads
/// share the module's memory, which a browser hands to workers only in a
/// secure, cross-origin isolated page; the output is an AudioWorklet.
/// Without them the module's factory would never settle.
@internal
String? get unsupportedReason {
  bool has(String name) => globalContext.has(name);
  bool flag(String name) =>
      globalContext.getProperty<JSBoolean?>(name.toJS)?.toDart ?? false;
  final String why;
  if (!flag('isSecureContext')) {
    why = 'the page is not a secure context: serve it over https';
  } else if (!flag('crossOriginIsolated')) {
    why =
        'the page is not cross-origin isolated: serve it with '
        'Cross-Origin-Opener-Policy: same-origin and '
        'Cross-Origin-Embedder-Policy: require-corp or credentialless';
  } else if (!has('SharedArrayBuffer')) {
    why = 'the browser has no SharedArrayBuffer';
  } else if (!has('AudioWorkletNode')) {
    why = 'the browser has no AudioWorklet';
  } else {
    return null;
  }
  return 'mpv_audio_kit: libmpv cannot run here, $why';
}

Future<_Loaded> _start() async {
  // Of a start that did not load, which this one replaces.
  _failure = null;
  final reason = unsupportedReason;
  if (reason != null) {
    _failure = StateError(reason);
    throw _failure!;
  }
  final url = _absolute(
    _url ?? ui_web.assetManager.getAssetUrl(kWebModuleAsset),
  );
  try {
    final MpvModule module;
    final debug = debugWebModule;
    final previous = registeredModule(url);
    if (debug != null) {
      module = await debug;
    } else if (previous != null) {
      // A Hot Restart: the page has the module already.
      module = MpvModule(previous);
    } else {
      module = await _import(url);
    }
    registerModule(url, module, reap: _reap);
    final output = await WebAudioOutput.start(
      module,
      reuse: debug == null && previous != null,
    );
    output.needsGestureChanges.listen(_gestureChanges.add);
    if (output.needsGesture) _gestureChanges.add(true);
    return _loaded = _Loaded(module, output);
  } on WebModuleTimeout {
    // The start goes on: the next Player waits for it again.
    _loading = null;
    rethrow;
  } on _NotLoaded catch (e) {
    // A fetch the network lost may pass later: the next Player starts
    // the module again, and until then a PCM source names this failure.
    _loading = null;
    _failure = e;
    rethrow;
  } catch (e) {
    _failure = e;
    rethrow;
  }
}

Future<MpvModule> _import(String url) async {
  try {
    return await loadMpvModule(url, timeout: debugWebModuleTimeout);
  } on StateError {
    rethrow;
  } catch (e) {
    throw _NotLoaded(
      'mpv_audio_kit: the web module did not load from $url ($e). The '
      'package from pub.dev ships it; a checkout from git gets it with '
      'scripts/update_libmpv.sh. The page must be cross-origin isolated '
      '(COOP and COEP) for its threads.',
    );
  }
}

/// The module's import or its factory failed: nothing of it is left in
/// the page, unlike a module that loaded and was refused (another ABI).
final class _NotLoaded extends StateError {
  _NotLoaded(super.message);
}

/// A session over the module in WebAssembly, on the main thread.
/// [wakeupCounterAddress] is a native test hook and has no meaning here.
@internal
MpvSession createMpvSession({int? wakeupCounterAddress}) =>
    WebSession(() async => (await _load()).module);

/// The page loads the package's web module when the app gives none.
@internal
String? defaultLibmpv() => null;

/// Starts loading the module: from [libmpv], a URL, or else from the
/// package's web assets ([kWebModuleAsset]); then the page's output. With
/// [hotRestartCleanup], what a program a Hot Restart replaced left in the
/// page is torn down first. A failure reaches the first player's bring-up,
/// and every later one's, but for a module that did not load or did not
/// start in time: the next player tries again.
@internal
void startBackend({String? libmpv, required bool hotRestartCleanup}) {
  _url = libmpv;
  _reap = hotRestartCleanup;
  _load().ignore();
}

/// The Hot Restart cleanup of the web runs with the module load, in
/// [startBackend].
@internal
void backendInitialized() {}

/// Completes once the module has loaded, `null` when it has: until then no
/// PCM source can be created.
@internal
Future<void>? backendReady() => _loaded == null ? _load() : null;

/// Resumes the page's output if the autoplay policy holds it (at a play).
@internal
void resumeOutput() => _loaded?.output.resume();

/// Makes the page's output run at [rate] Hz, `0` for the device's rate.
@internal
Future<void>? setOutputSampleRate(int rate) async =>
    (await _load()).output.setSampleRate(rate);

/// Whether the browser holds the page's sound until a user gesture.
@internal
bool get outputNeedsGesture => _loaded?.output.needsGesture ?? false;

/// [outputNeedsGesture] at each change.
@internal
Stream<bool> get outputNeedsGestureChanges => _gestureChanges.stream;

/// The page's output, for the media session's `<audio>` route.
@internal
Future<WebAudioOutput> webAudioOutput() async => (await _load()).output;

/// The live PCM input of the module. The module loads asynchronously:
/// until it has, there is none.
@internal
PcmNative openPcmNative(String? path) {
  final loaded = _loaded;
  if (loaded == null) {
    throw StateError(
      _failure != null
          ? 'mpv_audio_kit: the web module failed to load: $_failure'
          : 'mpv_audio_kit: the web module is still loading. Create a '
                'PcmSource once a Player is ready (await player.ready), or '
                'with Player.openPcmStream, which waits for it.',
    );
  }
  return WebPcmNative(loaded.module);
}
