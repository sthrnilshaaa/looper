// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:meta/meta.dart';

import '../../media_session/outside_pause.dart';
import 'mpv_module.dart';

/// Test-only: gets a line for each step of the page's output (init,
/// resume, route).
@visibleForTesting
void Function(String line)? debugWebAudioTrace;

@JS('document.createElement')
external JSObject _createElement(String tag);

/// The property of the module instance that holds the remover of the
/// page's state listener.
const String _kStateListener = '__makStateListenerOff';

/// The property of the module instance that holds the `<audio>` element
/// of the page's media session.
const String _kElement = '__makElement';

/// The listeners of the element and of the gestures, as `[target, type,
/// listener, ...]`, kept on the module instance: a program a Hot Restart
/// replaced cannot take its own off.
const String _kListeners = '__makListeners';

/// The property of the module instance that holds the rate its context
/// was made at, `0` for the device's: a program after a Hot Restart keeps
/// the context, and its rate.
const String _kSampleRate = '__makSampleRate';

@JS('document')
external JSObject get _document;

/// The events that count as a user gesture for a media element.
const List<String> _kGestures = ['pointerdown', 'keydown', 'touchend'];

/// The page's audio output: the AudioContext of `Module.makWebAudio`, which
/// mpv's webaudio output plays into, shared by every player of the page.
///
/// It is made before any core starts, so the output always finds it: a
/// core without one would fall back to the null output, silent. The
/// autoplay policy starts the context suspended until a user gesture; the
/// module resumes it at every gesture while it is not running, and
/// [resume] does it at a play. [needsGesture] says whether the sound is
/// held meanwhile.
///
/// Output 0 goes to the context's destination, or, with [routeToElement],
/// through a MediaStreamAudioDestinationNode into an `<audio>` element,
/// which the browsers want before they show the media session's controls.
@internal
final class WebAudioOutput {
  WebAudioOutput._(this._module);

  final MpvModule _module;
  MakWebAudio get _audio => _module.c.makWebAudio;
  final StreamController<bool> _gesture = StreamController<bool>.broadcast();
  String _state = 'none';
  int _sampleRate = 0;
  bool _toElement = false;
  JSObject? _element;
  JSObject? _stream;
  Future<void> _rates = Future<void>.value();

  /// Whether output 0 also goes to the context's destination while it is
  /// routed to the element: until the element plays, and whenever it stops
  /// without the player asking.
  bool _direct = false;

  // The element's play and pause from outside the output (the browser, a
  // call, another app): [outsidePlayback].
  final StreamController<bool> _outside = StreamController<bool>.broadcast();
  final OutsideElementWatch _watch = OutsideElementWatch();

  JSFunction? _onPlaying;
  JSFunction? _onPause;
  JSFunction? _onGesture;

  /// Makes the context of [module] and loads the worklet; a context of a
  /// replaced program is closed first. Throws when either fails.
  ///
  /// With [reuse], after a Hot Restart on the module the page had, the
  /// context the replaced program made is kept when there is one, at the
  /// rate it was made at: making a new one there made the module abort.
  static Future<WebAudioOutput> start(
    MpvModule module, {
    bool reuse = false,
  }) async {
    final output = WebAudioOutput._(module);
    // One listener per page: a program a Hot Restart replaced left its own
    // on the module.
    final instance = module.instance;
    final previous = instance[_kStateListener];
    if (previous.isA<JSFunction>()) {
      (previous as JSFunction).callAsFunction();
    }
    instance[_kStateListener] = output._audio.onStateChange(
      output._onState.toJS,
    );
    // And the listeners of its element and gestures, and the <audio>
    // element of its media session, still playing.
    _removeListeners(instance);
    final element = instance[_kElement];
    if (element.isA<JSObject>()) {
      (element as JSObject).callMethod('pause'.toJS);
      element['srcObject'] = null;
    }
    if (reuse && output._audio.context != null) {
      final rate = instance[_kSampleRate];
      output._sampleRate = rate.isA<JSNumber>()
          ? (rate as JSNumber).toDartInt
          : 0;
      debugWebAudioTrace?.call('reuse ${output._sampleRate}');
      output._onState(output._audio.state);
      // Output 0 may still go to the replaced program's element.
      output._route();
      return output;
    }
    await output._init(output._sampleRate);
    return output;
  }

  Future<void> _init(int rate) async {
    final options = JSObject();
    final processor = _module.processorUrl;
    if (processor != null) options['processorUrl'] = processor.toJS;
    if (rate > 0) options['sampleRate'] = rate.toJS;
    debugWebAudioTrace?.call('init $rate');
    await _audio.init(options).toDart;
    _module.instance[_kSampleRate] = rate.toJS;
    _onState(_audio.state);
    if (_toElement) _route();
  }

  void _onState(String state) {
    final before = needsGesture;
    _state = state;
    if (_watch.onContextState(state)) _playElement();
    if (needsGesture != before) _gesture.add(needsGesture);
  }

  /// Whether the browser holds the sound until a user gesture: the context
  /// is suspended (or, on iOS, interrupted).
  bool get needsGesture => _state == 'suspended' || _state == 'interrupted';

  /// [needsGesture] at each change.
  Stream<bool> get needsGestureChanges => _gesture.stream;

  /// Resumes a context the autoplay policy holds. Called at a play, where a
  /// user gesture is likely; the module also resumes at each gesture.
  void resume() {
    if (!needsGesture) return;
    debugWebAudioTrace?.call('resume');
    _audio.resume().toDart.ignore();
  }

  /// Makes a new context at [rate] (Hz; `0` for the device's), so mpv
  /// resamples to it once and the browser not at all. Every player of the
  /// page plays at that rate: open outputs reopen on the new context.
  ///
  /// The changes run one after the other. A rate the browser refuses
  /// throws a [StateError] and leaves a context at the rate before.
  Future<void> setSampleRate(int rate) {
    final change = _rates.then((_) => _changeSampleRate(rate));
    _rates = change.catchError((Object _) {});
    return change;
  }

  Future<void> _changeSampleRate(int rate) async {
    if (rate == _sampleRate) return;
    try {
      await _init(rate);
      _sampleRate = rate;
    } catch (e) {
      // The module closed the old context before it made the new one.
      try {
        await _init(_sampleRate);
      } catch (_) {
        // Nothing else to fall back to: the next change tries again.
      }
      throw StateError(
        'mpv_audio_kit: the browser refused an audio output at $rate Hz '
        '($e)',
      );
    }
  }

  /// Sends output 0 through an `<audio>` element ([on]) or straight to the
  /// context's destination.
  void routeToElement(bool on) {
    if (on == _toElement) return;
    _toElement = on;
    _route();
  }

  void _route() {
    final context = _audio.context;
    if (context == null) return;
    final node = _audio.output(0);
    node.callMethod('disconnect'.toJS);
    _direct = false;
    _watch.reset();
    debugWebAudioTrace?.call('route ${_toElement ? 'element' : 'destination'}');
    if (!_toElement) {
      // The listeners go first: the element's pause event comes later.
      _listen(false);
      _element?.callMethod('pause'.toJS);
      _element?['srcObject'] = null;
      node.callMethod('connect'.toJS, context['destination']);
      return;
    }
    final destination =
        context.callMethod('createMediaStreamDestination'.toJS) as JSObject;
    node.callMethod('connect'.toJS, destination);
    _stream = destination['stream'] as JSObject;
    final element = _element ??= _createElement('audio');
    _module.instance[_kElement] = element;
    element['srcObject'] = _stream;
    _listen(true);
    // The context's destination keeps the sound until the element plays:
    // a browser can refuse its play() outside a gesture.
    _setDirect(true);
    _playElement();
  }

  /// Connects output 0 to the context's destination as well ([on]), or
  /// takes it off, while it is routed to the element.
  void _setDirect(bool on) {
    final context = _audio.context;
    if (on == _direct || context == null) return;
    _direct = on;
    final node = _audio.output(0);
    final destination = context['destination'] as JSObject;
    debugWebAudioTrace?.call('direct $on');
    if (on) {
      node.callMethod('connect'.toJS, destination);
    } else {
      node.callMethod('disconnect'.toJS, destination);
    }
  }

  /// Listens to the element and to the gestures of the page ([on]), or
  /// stops. The element playing takes the sound off the destination; the
  /// element stopping without the output asking (the browser paused it,
  /// another app took the audio) puts it back, and the next gesture or
  /// running state plays the element again.
  void _listen(bool on) {
    final element = _element;
    if (element == null) return;
    void each(String method, String type, JSFunction? f) {
      if (f != null) element.callMethod(method.toJS, type.toJS, f);
    }

    void gestures(String method, JSFunction? f) {
      if (f == null) return;
      for (final type in _kGestures) {
        _document.callMethod(method.toJS, type.toJS, f);
      }
    }

    _removeListeners(_module.instance);
    _onPlaying = _onPause = _onGesture = null;
    if (!on) return;
    _onPlaying = ((JSAny? _) {
      debugWebAudioTrace?.call('element playing');
      if (!_toElement) return;
      _setDirect(false);
      if (_watch.onPlaying()) _outside.add(true);
    }).toJS;
    _onPause = ((JSAny? _) {
      if (!_toElement) return;
      debugWebAudioTrace?.call('element paused');
      _setDirect(true);
      // The output pauses the element only after taking its listeners off:
      // a pause seen here comes from outside.
      if (_watch.onPause()) _outside.add(false);
    }).toJS;
    _onGesture = ((JSAny? _) {
      if (_toElement && _direct) _playElement();
    }).toJS;
    each('addEventListener', 'playing', _onPlaying);
    each('addEventListener', 'pause', _onPause);
    gestures('addEventListener', _onGesture);
    _module.instance[_kListeners] = <JSAny?>[
      element,
      'playing'.toJS,
      _onPlaying,
      element,
      'pause'.toJS,
      _onPause,
      for (final type in _kGestures) ...[_document, type.toJS, _onGesture],
    ].toJS;
  }

  /// Takes off the listeners kept on [instance] ([_kListeners]).
  static void _removeListeners(JSObject instance) {
    final kept = instance[_kListeners];
    instance[_kListeners] = null;
    if (!kept.isA<JSArray>()) return;
    final list = (kept as JSArray<JSAny?>).toDart;
    for (var i = 0; i + 2 < list.length; i += 3) {
      (list[i] as JSObject).callMethod(
        'removeEventListener'.toJS,
        list[i + 1],
        list[i + 2],
      );
    }
  }

  /// The `<audio>` element output 0 plays through, while routed there.
  JSObject? get element => _toElement ? _element : null;

  /// `false` when the element, playing, is paused from outside the output
  /// (the browser, a call, another app), and `true` when the browser plays
  /// it again after one, or the output does when an interruption ends (the
  /// context runs again after `interrupted`). A play of the output itself
  /// at a gesture sends nothing. The media session follows its interruption
  /// policy on these.
  Stream<bool> get outsidePlayback => _outside.stream;

  void _playElement() {
    final element = this.element;
    if (element == null) return;
    // Refused until a user gesture: the next gesture or running state
    // plays it, and the destination keeps the sound meanwhile.
    _watch.onOutputPlay(
      elementPaused: (element['paused'] as JSBoolean?)?.toDart ?? true,
    );
    element
        .callMethod<JSPromise?>('play'.toJS)
        ?.toDart
        .then<void>((_) {}, onError: (Object _) => _watch.onPlayRefused())
        .ignore();
  }
}
