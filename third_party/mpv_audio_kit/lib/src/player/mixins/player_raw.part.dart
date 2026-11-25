// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of '../player.dart';

// The `%n%` length prefix and the list actions of an option name.
final _kCountedPrefix = RegExp(r'^%\d+%');
final _kListAction = RegExp(
  r'^(.+)-(add|append|pre|set|clr|del|remove|toggle)$',
);

/// The option names in a `key=value,key=value` list, the per-file options
/// of `loadfile`, unquoted: mpv also takes `"key"`, `[key]` and `%n%key`.
/// A value can itself hold commas, so this may also return a word from
/// inside one: good enough to spot `af` and `pause`.
Iterable<String> _optionKeys(String options) sync* {
  for (final part in options.split(',')) {
    final eq = part.indexOf('=');
    var key = (eq < 0 ? part : part.substring(0, eq)).trim();
    final counted = _kCountedPrefix.firstMatch(key);
    if (counted != null) key = key.substring(counted.end);
    if (key.length >= 2 &&
        ((key.startsWith('"') && key.endsWith('"')) ||
            (key.startsWith('[') && key.endsWith(']')))) {
      key = key.substring(1, key.length - 1);
    }
    yield key;
  }
}

/// The property an option name on the command line writes: `no-pause`
/// sets `pause`, and `af-add`, `af-set` and the other list actions edit
/// `af`.
String _optionProperty(String key) {
  if (key.startsWith('no-')) return key.substring(3);
  final list = _kListAction.firstMatch(key);
  return list == null ? key : list.group(1)!;
}

/// Commands whose second argument names a property they write.
const _kPropertyCommands = {
  'set',
  'add',
  'multiply',
  'cycle',
  'cycle-values',
  'change-list',
};

/// The public raw escape hatches: property reads and writes, commands and
/// the log level, with the guards that keep the properties the player
/// owns out of them.
mixin _RawModule on _PlayerBase {
  /// Reads any mpv property as a string.
  ///
  /// **Escape hatch for properties not surfaced by the typed API.** For
  /// observed properties (`volume`, `pause`, `cache-secs`, …), prefer
  /// `player.state.<field>`: the cached value is updated on every
  /// property-change event from mpv and avoids an FFI round-trip.
  ///
  /// Returns `null` if the property doesn't exist or the read
  /// fails. Throws [PlayerDisposedException] if the player has been disposed.
  @override
  Future<String?> getRawProperty(String name) async {
    await _gate();
    final (error, value) = await _calls.get(name, MpvFormat.mpvFormatString);
    return error < 0 ? null : value as String?;
  }

  /// Reads any mpv property as a decoded node tree.
  ///
  /// Typed counterpart of [getRawProperty] for structured properties
  /// (`track-list`, `metadata`, `demuxer-cache-state`, …): returns the
  /// same shapes the event pipeline produces (`Map<String, dynamic>`,
  /// `List<dynamic>`, [String], [int], [double], [bool], byte arrays),
  /// with no string re-parsing on the caller's side.
  ///
  /// Returns `null` if the property doesn't exist or is currently
  /// unavailable. Throws [PlayerDisposedException] if the player has been disposed.
  Future<Object?> getRawPropertyNode(String name) async {
    await _gate();
    final (error, value) = await _calls.get(name, MpvFormat.mpvFormatNode);
    return error < 0 ? null : value;
  }

  /// Writes any mpv property as a string.
  ///
  /// **Warning:** this is an escape hatch for properties the typed API
  /// doesn't yet cover. If [name] is one of the registry-observed
  /// properties (volume, cache-*, replaygain*, ao, …), the
  /// resulting state mutation will *also* flow through the property
  /// observer on mpv's side, so `player.state` and `player.stream` will
  /// stay consistent, but expect a one-event-loop-tick delay between
  /// the call returning and the cached state catching up. Prefer the
  /// typed setters (`setVolume`, `setCache`, `setReplayGain`, …) when
  /// they exist, both for type-safety and because they update the state
  /// as soon as mpv confirms the write, without waiting for the observer.
  ///
  /// Two properties are reserved and rejected:
  /// - `af`: owned by the effects chain (raw lavfi entries included, as
  ///   [RawAudioEffect] stages); a raw write would silently desync
  ///   `state.settings.audioEffects`. Use [setAudioEffects] or
  ///   [updateAudioEffects].
  /// - `pause`: owned by the transport intent axis. It is deliberately not
  ///   observed (see [PlaybackState.playWhenReady]), so a raw write would
  ///   change actual playback while leaving
  ///   `state.playback.playWhenReady` (and the OS play-pause button bound
  ///   to it) reporting the old intent. Use [play] or [pause].
  ///
  /// Throws [PlayerDisposedException] if the player has been disposed,
  /// [ArgumentError] if [name] is reserved, or [MpvCommandException] if mpv
  /// rejects the property write (unknown name, out-of-range value, etc.).
  @override
  Future<void> setRawProperty(String name, String value) async {
    _checkNotOwned(name, 'name');
    await _gate();
    await _calls.prop(name, value);
  }

  /// Throws [ArgumentError] when [name] is a property the player owns:
  /// `af` (the effects chain) or `pause` (the transport intent), also
  /// through the `options/` and `file-local-options/` prefixes, which
  /// write the same option.
  void _checkNotOwned(String name, String argName) {
    for (final prefix in const ['options/', 'file-local-options/']) {
      if (name.startsWith(prefix)) {
        _checkNotOwned(name.substring(prefix.length), argName);
        return;
      }
    }
    if (name == 'af') {
      throw ArgumentError.value(
        name,
        argName,
        'Property `af` is owned by the effects chain. '
        'Use Player.setAudioEffects or updateAudioEffects, and pass '
        'experimental or expression-based filters as a RawAudioEffect.',
      );
    }
    if (name == 'pause') {
      throw ArgumentError.value(
        name,
        argName,
        'Property `pause` is owned by the transport intent axis and is not '
        'observed, so a raw write would desync state.playWhenReady (and '
        'the OS play-pause button) from actual playback. '
        'Use Player.play() or Player.pause() instead.',
      );
    }
  }

  /// Throws [ArgumentError] when [command] shuts the core down. A core
  /// that quits takes the event isolate with it: no call would get its
  /// reply any more.
  void _checkNotQuit(String command) {
    if (command == 'quit' || command == 'quit-watch-later') {
      throw ArgumentError.value(
        command,
        'args',
        'Command `$command` shuts the core down under the player. '
            'Use Player.dispose() instead.',
      );
    }
  }

  /// Sends a raw mpv command.
  ///
  /// **Escape hatch.** Same caveats as [setRawProperty]: prefer the
  /// typed playback and playlist methods (`play`, `pause`, `seek`,
  /// `add`, `jump`, …) when they cover your use case.
  ///
  /// The two properties [setRawProperty] reserves stay reserved here:
  /// `af` and `af-command`, and a command that writes `af` or `pause`
  /// (`set`, `add`, `multiply`, `cycle`, `cycle-values`, `change-list`),
  /// also after a prefix such as `no-osd`, through `options/` or
  /// `file-local-options/`, or in the per-file options of `loadfile`,
  /// throw [ArgumentError] before anything reaches mpv. So do `quit` and
  /// `quit-watch-later`: a core that shuts down under the player answers
  /// no call any more. Use [dispose].
  ///
  /// Throws [PlayerDisposedException] if the player has been disposed,
  /// [ArgumentError] for a reserved command as above, or
  /// [MpvCommandException] if mpv rejects the command (unknown command,
  /// invalid argument, etc.). A successful return guarantees mpv
  /// accepted the command; the actual side-effect on playback state
  /// is observed asynchronously via [Player.stream].
  Future<void> sendRawCommand(List<String> args) async {
    // Symmetric guard with setRawProperty: mpv exposes `af` and
    // `af-command` as commands that mutate the audio chain incrementally,
    // and `set`, `change-list`, `cycle` and the like write any property,
    // `af` and `pause` included. Skip the command prefixes (`no-osd`, …)
    // before looking.
    final i = commandStart(args);
    if (i < args.length) {
      // mpv reads `_` in a command name as `-` (`change_list`).
      final command = args[i].replaceAll('_', '-');
      if (command == 'af' || command == 'af-command') {
        throw ArgumentError.value(
          command,
          'args',
          'Command `$command` is owned by the effects chain. '
              'Use Player.setAudioEffects or updateAudioEffects, and pass '
              'experimental or expression-based filters as a RawAudioEffect.',
        );
      }
      _checkNotQuit(command);
      if (_kPropertyCommands.contains(command)) {
        // `cycle-values` takes flags such as `!reverse` before the name.
        var p = i + 1;
        while (p < args.length && args[p].startsWith('!')) {
          p++;
        }
        if (p < args.length) _checkNotOwned(args[p], 'args');
      }
      // `loadfile <url> <flags> <index> <options>` sets per-file options,
      // which can name `af` or `pause` too.
      if (command == 'loadfile' && i + 4 < args.length) {
        for (final key in _optionKeys(args[i + 4])) {
          _checkNotOwned(_optionProperty(key), 'args');
        }
      }
    }
    await _gate();
    final rc = await _calls.command(args);
    if (rc < 0) {
      throw MpvCommandException(
        name: args.isEmpty ? '<empty>' : args.first,
        code: rc,
        message: _calls.errorString(rc),
      );
    }
  }

  /// Changes the engine log verbosity at runtime (the initial value comes
  /// from [PlayerConfiguration.logLevel]). Synchronous: before the player
  /// has finished starting, the level is kept and applied once it has.
  void setLogLevel(LogLevel level) {
    _checkNotDisposed();
    _pendingLogLevel = level;
    if (_bringUpCompleted) _calls.requestLogMessages(level);
  }
}
