// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// Media-session setter: publishes the [Player] to the OS lockscreen /
/// SMTC / MPRIS entry, wires Bluetooth AVRCP and headset buttons, and
/// (when enabled) integrates with the platform's audio-session
/// lifecycle for phone-call / Siri / navigation auto-pause.
///
/// Pass `null` to disable. Only one [Player] per process can hold the
/// session — see [Player._mediaSessionOwner]. `dispose()` releases the
/// session automatically before tearing down libmpv.
///
/// Lifecycle:
/// - First non-null call: registers the static guard, allocates a
///   [MediaSessionController] that pushes state to the native side
///   and listens for inbound OS commands.
/// - Subsequent non-null calls: reconfigure (controller stays alive,
///   the new config flows through `state.mediaSession` → stream →
///   controller).
/// - `null` call: tears the controller down, clears the static guard.
///
/// Inbound commands are auto-applied to the [Player] (play → play(),
/// seek → seek(), …) AND emitted on
/// [PlayerStream.mediaSessionCommands] for analytics / interception.
/// `next` / `previous` are routed to mpv's playlist when one is
/// loaded; otherwise they only emit on the consumer stream so the
/// app's queue logic can react.
mixin _MediaSessionModule on _PlayerBase {
  Future<void> setMediaSession(MediaSession? session) async {
    _checkNotDisposed();

    // 1. Single-instance guard.
    if (session != null) {
      final owner = Player._mediaSessionOwner;
      if (owner != null && !identical(owner, this)) {
        throw StateError(
          'Another Player instance already owns the OS media session. '
          'SMTC (Windows) and MPNowPlayingInfoCenter (Apple) are '
          'single-instance per process, so only one Player can publish '
          'to the lockscreen at a time. Disable the existing session '
          'with `setMediaSession(null)` on the other Player before '
          'enabling this one.',
        );
      }
      Player._mediaSessionOwner = this as Player;
    } else if (identical(Player._mediaSessionOwner, this)) {
      Player._mediaSessionOwner = null;
    }

    // 2. Update state synchronously (optimistic). The controller's
    //    own subscription to `stream.mediaSession` will pick up the
    //    config change and push it to native via `updateConfig`.
    _updateField(
      (s) => s.copyWith(mediaSession: session),
      _mediaSession,
      session,
    );

    // 3. Lazily allocate the controller on first enable; tear it
    //    down on disable. Recreating per-enable would race the
    //    bootstrap `enable` call against any in-flight teardown.
    if (session != null) {
      if (_mediaSessionController == null) {
        final controller = await MediaSessionController.create(
          stateSnapshot: () => _state,
          inputs: MediaSessionInputs.fromPlayer(stream: stream),
          onCommand: _handleSessionCommand,
          onAudioOutputReset: _reloadAudioOutput,
        );
        // Re-check EVERYTHING that gated the create, not just ownership:
        // a concurrent `setMediaSession(non-null)` also passed the
        // `== null` pre-check above and may have assigned its controller
        // during this await — overwriting it here would strand the other
        // one with live subscriptions, double-pushing to native for the
        // rest of the process. Exactly one create wins; the losers tear
        // their fresh controller down.
        if (_mediaSessionController == null &&
            identical(Player._mediaSessionOwner, this) &&
            _state.mediaSession != null) {
          _mediaSessionController = controller;
        } else {
          await controller.dispose();
        }
      }
    } else {
      final c = _mediaSessionController;
      _mediaSessionController = null;
      await c?.dispose();
    }
  }

  /// Drops the OS media session without the public checks: called by
  /// dispose, which has already refused new calls.
  Future<void> _releaseMediaSession() async {
    if (identical(Player._mediaSessionOwner, this)) {
      Player._mediaSessionOwner = null;
    }
    final c = _mediaSessionController;
    _mediaSessionController = null;
    await c?.dispose();
  }

  /// Handles a remote command issued by the OS media session.
  ///
  /// Auto-applies the command to the [Player] (the optimistic update
  /// pattern guarantees `state` reflects the new value synchronously),
  /// then emits on [PlayerStream.mediaSessionCommands] so consumer
  /// subscribers can observe the resolved order.
  ///
  /// [MediaSessionCommandNext] / [MediaSessionCommandPrevious] use
  /// the smart-default routing: if the active playlist has more than
  /// one entry, the package calls mpv's `playlist-next` /
  /// `playlist-prev`. Otherwise the command is emit-only, leaving
  /// the consumer's queue logic to handle it.
  void _handleSessionCommand(MediaSessionCommand command) {
    // Auto-apply. We deliberately don't `await` these — the command
    // stream callback is synchronous and the Player setters are
    // optimistic (state updates land before the FFI round-trip). A late
    // rejection is caught by [_applySessionCommand].
    switch (command) {
      case MediaSessionCommandPlay():
        _applySessionCommand((this as Player).play());
      case MediaSessionCommandPause():
        _applySessionCommand((this as Player).pause());
      case MediaSessionCommandPlayPause():
        // Resolve against the INTENT axis, not actual output: `_state.playing`
        // (core-idle inverted) toggles transiently on every seek/buffer, so a
        // single-button PlayPause landing during a transient would flip the
        // wrong way. The OS button itself binds to `playWhenReady`; match it.
        if (_state.playWhenReady) {
          _applySessionCommand((this as Player).pause());
        } else {
          _applySessionCommand((this as Player).play());
        }
      case MediaSessionCommandStop():
        _applySessionCommand((this as Player).stop());
      case MediaSessionCommandNext():
        if (shouldAutoApplyPlaylistNav(
          autoApplyPlaylistNavigation:
              _state.mediaSession?.autoApplyPlaylistNavigation,
          playlistLength: _state.playlist.items.length,
        )) {
          _applySessionCommand((this as Player).next());
        }
      case MediaSessionCommandPrevious():
        if (shouldAutoApplyPlaylistNav(
          autoApplyPlaylistNavigation:
              _state.mediaSession?.autoApplyPlaylistNavigation,
          playlistLength: _state.playlist.items.length,
        )) {
          _applySessionCommand((this as Player).previous());
        }
      case MediaSessionCommandLike():
        // Emit-only: there is no built-in favourite concept, so it is not
        // auto-applied. The consumer reacts on the stream below and reflects
        // the new state via `MediaSession.isFavorite`.
        break;
      case MediaSessionCommandSeekTo(:final position):
        _applySessionCommand((this as Player).seek(position));
      case MediaSessionCommandSeekBy(:final offset):
        // Apply as a TRUE relative seek so mpv does the base-position
        // arithmetic against its own live playhead. Computing an absolute
        // target from `_state.position` here would compose off a stale
        // base when skip buttons repeat faster than the position observer
        // updates — rapid lockscreen / headset double-taps would under-skip.
        _applySessionCommand((this as Player).seek(offset, relative: true));
      case MediaSessionCommandSetRepeatMode(:final loop):
        _applySessionCommand((this as Player).setLoop(loop));
      case MediaSessionCommandSetShuffle(:final shuffle):
        _applySessionCommand((this as Player).setShuffle(shuffle));
      case MediaSessionCommandSetPlaybackRate(:final rate):
        _applySessionCommand((this as Player).setRate(rate));
    }
    // Always emit on the consumer-facing stream, regardless of
    // whether the command was auto-applied. Even for next/previous
    // on a single-media playlist (where auto-apply is a no-op) the
    // consumer needs to see the command to drive its own queue.
    _mediaSessionCommandsCtrl.add(command);
  }

  /// Reopens mpv's audio output after the OS restored the audio session
  /// without it (see [MediaSessionChannel.audioOutputResets]): the
  /// AudioUnit the system stopped for an interruption or a media services
  /// reset stays silent, while mpv keeps reporting playback.
  void _reloadAudioOutput() {
    _applySessionCommand(_commandChecked(const ['ao-reload']));
  }

  /// Fires an inbound-command action without awaiting it (the command-stream
  /// callback is synchronous and the typed setters are optimistic), but
  /// catches a late rejection. The setters are genuinely async now, so a
  /// command mpv rejects — e.g. a lockscreen seek arriving with nothing loaded
  /// ([Player.seek] throws via `_commandChecked`) — would otherwise escape as
  /// an unhandled async error (which can crash a guarded zone) seconds later.
  void _applySessionCommand(Future<void> action) {
    unawaited(action.catchError((Object e, StackTrace st) {
      _internalLog('Media-session command failed: $e', level: LogLevel.warn);
    }),);
  }
}
