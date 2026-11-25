// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The web plugin of the package: the OS media session through the browser's
// navigator.mediaSession, on the channels the native plugins serve
// (media_session_channel.dart), so the Dart side is the same everywhere.
// libmpv itself is plain Dart over js_interop (backend/web_backend.dart)
// and needs no registration.

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:meta/meta.dart';

import '../backend/web_backend.dart' show webAudioOutput;
import '../media_session/outside_pause.dart';

@JS('navigator.mediaSession')
external _MediaSession? get _session;

extension type _MediaSession._(JSObject _) implements JSObject {
  external set metadata(JSObject? value);
  external set playbackState(String value);
  external void setActionHandler(String action, JSFunction? handler);
  external void setPositionState([JSObject? state]);
}

@JS('MediaMetadata')
extension type _MediaMetadata._(JSObject _) implements JSObject {
  external _MediaMetadata(JSObject init);
}

@JS('Blob')
extension type _Blob._(JSObject _) implements JSObject {
  external _Blob(JSArray<JSAny> parts, JSObject options);
}

@JS('URL.createObjectURL')
external String _createObjectUrl(JSObject blob);

@JS('URL.revokeObjectURL')
external void _revokeObjectUrl(String url);

/// The actions of navigator.mediaSession each [MediaAction] name turns on.
const Map<String, List<String>> _kActions = {
  'play': ['play'],
  'pause': ['pause'],
  'playPause': ['play', 'pause'],
  'stop': ['stop'],
  'next': ['nexttrack'],
  'previous': ['previoustrack'],
  'seek': ['seekto'],
  'fastForward': ['seekforward'],
  'rewind': ['seekbackward'],
};

const List<String> _kWebActions = [
  'play',
  'pause',
  'stop',
  'nexttrack',
  'previoustrack',
  'seekto',
  'seekforward',
  'seekbackward',
];

/// The web implementation of the media session channels.
@internal
final class MpvAudioKitWeb {
  MpvAudioKitWeb._();

  final StreamController<Object?> _commands =
      StreamController<Object?>.broadcast();
  bool _enabled = false;
  Set<String> _actions = const {};
  int _forwardMs = 15000;
  int _backwardMs = 15000;
  int? _durationMs;
  Map<Object?, Object?>? _playback;
  String? _artworkBlob;
  final OutsidePauseFollower _outside = OutsidePauseFollower();
  StreamSubscription<bool>? _outsideSub;

  /// Registers the plugin with the page's [registrar]. A Hot Restart runs
  /// it again: the session the replaced program left is cleared first.
  static void registerWith(Registrar registrar) {
    final plugin = MpvAudioKitWeb._().._clear();
    MethodChannel(
      'mpv_audio_kit/media_session',
      const StandardMethodCodec(),
      registrar,
    ).setMethodCallHandler(plugin._handle);
    PluginEventChannel<Object?>(
      'mpv_audio_kit/media_session/commands',
      const StandardMethodCodec(),
      registrar,
    ).setController(plugin._commands);
  }

  Future<Object?> _handle(MethodCall call) async {
    final session = _session;
    // A browser without the API: nothing to show, as on an unwired
    // platform.
    if (session == null) return null;
    switch (call.method) {
      case 'enable':
        final args = call.arguments as Map<Object?, Object?>;
        _enabled = true;
        _config(session, args['config'] as Map<Object?, Object?>);
        _metadata(session, args['metadata'] as Map<Object?, Object?>);
        _setPlayback(session, args['playback'] as Map<Object?, Object?>);
        await _routeToElement();
      case 'updateConfig':
        if (_enabled) _config(session, call.arguments as Map<Object?, Object?>);
      case 'updateMetadata':
        if (_enabled) {
          _metadata(session, call.arguments as Map<Object?, Object?>);
        }
      case 'updatePlayback':
        if (_enabled) {
          _setPlayback(session, call.arguments as Map<Object?, Object?>);
        }
      case 'disable':
        final was = _enabled;
        await _outsideSub?.cancel();
        _outsideSub = null;
        _clear();
        if (was) (await webAudioOutput()).routeToElement(false);
      default:
        throw MissingPluginException('${call.method} on the web');
    }
    return null;
  }

  /// Plays the page's output through the session's `<audio>` element:
  /// Chrome and Firefox show the controls of a media element only. An
  /// outside pause of that element follows the interruption policy, as an
  /// interruption on iOS and Android.
  Future<void> _routeToElement() async {
    final previous = _outsideSub;
    _outsideSub = null;
    await previous?.cancel();
    final output = await webAudioOutput();
    // A disable while the output loaded: nothing to route or follow.
    if (!_enabled) return;
    output.routeToElement(true);
    await _outsideSub?.cancel();
    _outsideSub = output.outsidePlayback.listen(_onOutside);
  }

  void _config(_MediaSession session, Map<Object?, Object?> config) {
    if (config.containsKey('interruptionPolicy')) {
      _outside.policy = OutsidePauseFollower.policyOf(
        config['interruptionPolicy'],
      );
    }
    _forwardMs = config['fastForwardIntervalMs'] as int? ?? _forwardMs;
    _backwardMs = config['rewindIntervalMs'] as int? ?? _backwardMs;
    _actions = {
      for (final name in (config['actions'] as List<Object?>? ?? const []))
        ...?_kActions[name],
    };
    for (final action in _kWebActions) {
      _setHandler(
        session,
        action,
        _actions.contains(action)
            ? (JSObject details) {
                _onAction(action, details);
              }.toJS
            : null,
      );
    }
  }

  void _onOutside(bool elementPlaying) {
    if (!_enabled) return;
    final type = _outside.onOutside(
      elementPlaying: elementPlaying,
      playing: _playback?['playing'] == true,
    );
    if (type != null) _commands.add({'type': type});
  }

  void _onAction(String action, JSObject details) {
    // An action of the user's own ends an outside pause.
    _outside.reset();
    final command = switch (action) {
      'play' => {'type': 'play'},
      'pause' => {'type': 'pause'},
      'stop' => {'type': 'stop'},
      'nexttrack' => {'type': 'next'},
      'previoustrack' => {'type': 'previous'},
      'seekto' => {
        'type': 'seekTo',
        'positionMs': (_number(details, 'seekTime') * 1000).round(),
      },
      'seekforward' => {
        'type': 'seekBy',
        'offsetMs': _offsetMs(details, _forwardMs),
      },
      'seekbackward' => {
        'type': 'seekBy',
        'offsetMs': -_offsetMs(details, _backwardMs),
      },
      _ => null,
    };
    if (command != null) _commands.add(command);
  }

  /// The skip of a seekforward or seekbackward: the one the browser asks
  /// for, or the interval of the session.
  static int _offsetMs(JSObject details, int fallbackMs) {
    final offset = details['seekOffset'];
    return offset.isA<JSNumber>()
        ? ((offset as JSNumber).toDartDouble * 1000).round()
        : fallbackMs;
  }

  static double _number(JSObject details, String key) {
    final value = details[key];
    return value.isA<JSNumber>() ? (value as JSNumber).toDartDouble : 0;
  }

  void _metadata(_MediaSession session, Map<Object?, Object?> m) {
    _durationMs = m['durationMs'] as int?;
    final init = JSObject();
    for (final key in const ['title', 'artist', 'album']) {
      final value = m[key];
      if (value is String) init[key] = value.toJS;
    }
    final bytes = m['artworkBytes'];
    final url = m['artworkUrl'];
    final previous = _artworkBlob;
    _artworkBlob = null;
    String? src;
    var type = '';
    if (bytes is Uint8List && bytes.isNotEmpty) {
      type = m['artworkMime'] as String? ?? '';
      src = _artworkBlob = _createObjectUrl(
        _Blob(<JSAny>[bytes.toJS].toJS, JSObject()..['type'] = type.toJS),
      );
    } else if (url is String) {
      // A URL the package could not download (no CORS): the browser loads
      // it as an image.
      src = url;
    }
    if (src != null) {
      final image = JSObject()..['src'] = src.toJS;
      if (type.isNotEmpty) image['type'] = type.toJS;
      init['artwork'] = <JSAny>[image].toJS;
    }
    session.metadata = _MediaMetadata(init);
    if (previous != null) _revokeObjectUrl(previous);
    _position(session);
  }

  void _setPlayback(_MediaSession session, Map<Object?, Object?> p) {
    _playback = p;
    // Played since: an outside pause that ends later plays nothing.
    if (p['playing'] == true) _outside.reset();
    session.playbackState = p['playing'] == true ? 'playing' : 'paused';
    _position(session);
  }

  /// The position the browser extrapolates from: the last playback push
  /// against the duration of the metadata; a live stream (not seekable)
  /// has an infinite duration, and an unknown duration clears it.
  void _position(_MediaSession session) {
    final p = _playback;
    if (p == null) return;
    final seekable = p['seekable'] == true;
    final durationMs = _durationMs;
    try {
      if (seekable && (durationMs == null || durationMs <= 0)) {
        session.setPositionState();
        return;
      }
      final duration = seekable ? durationMs! / 1000 : double.infinity;
      final position = ((p['positionMs'] as int? ?? 0) / 1000).clamp(
        0.0,
        duration,
      );
      final rate = (p['rate'] as num? ?? 1).toDouble();
      session.setPositionState(
        JSObject()
          ..['duration'] = duration.toJS
          ..['playbackRate'] = (rate > 0 ? rate : 1.0).toJS
          ..['position'] = position.toJS,
      );
    } catch (_) {
      // A browser that refuses a value: the controls just show no slider.
    }
  }

  /// Takes everything off the browser's session.
  void _clear() {
    _enabled = false;
    _outside.reset();
    _playback = null;
    _durationMs = null;
    final session = _session;
    if (session == null) return;
    session.metadata = null;
    session.playbackState = 'none';
    for (final action in _kWebActions) {
      _setHandler(session, action, null);
    }
    try {
      session.setPositionState();
    } catch (_) {}
    final blob = _artworkBlob;
    _artworkBlob = null;
    if (blob != null) _revokeObjectUrl(blob);
  }

  /// Sets the handler of [action]; a browser that does not know the
  /// action throws, and the action is skipped.
  static void _setHandler(
    _MediaSession session,
    String action,
    JSFunction? handler,
  ) {
    try {
      session.setActionHandler(action, handler);
    } catch (_) {}
  }
}
