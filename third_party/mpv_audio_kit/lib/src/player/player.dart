// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io' show Platform;
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:meta/meta.dart';

import '../dsp/filter_tap_pipeline.dart';
import '../dsp/loudness_meter_pipeline.dart';
import '../dsp/loudness_scan_pipeline.dart';
import '../dsp/spectrum_pipeline.dart';
import '../dsp/waveform_pipeline.dart';
import '../events/mpv_exception.dart';
import '../events/mpv_hook_event.dart';
import '../events/mpv_log_entry.dart';
import '../events/mpv_player_error.dart';
import '../generated/audio_effects_settings.dart';
import '../internals/debug_log.dart';
import '../internals/duration_seconds.dart';
import '../internals/event_isolate.dart';
import '../internals/library_loader.dart';
import '../internals/orphan_handle_tracker.dart';
import '../internals/player_finalizer.dart';
import '../internals/uri_resolver.dart';
import '../media_session/media_session_controller.dart';
import '../media_session/media_session_inputs.dart';
import '../models/chapter.dart';
import '../models/cover_art.dart';
import '../models/demuxer_cache_state.dart';
import '../models/device.dart';
import '../models/fft_frame.dart';
import '../models/loudness.dart';
import '../models/loudness_scan.dart';
import '../models/media.dart';
import '../models/media_session.dart';
import '../models/pcm_frame.dart';
import '../models/playlist.dart';
import '../models/source_resolve_request.dart';
import '../models/waveform_data.dart';
import '../mpv_bindings.dart' hide MpvEndFileReason;
import '../reactive/default_reactives.dart';
import '../reactive/default_specs.dart';
import '../reactive/node_parsers.dart';
import '../reactive/property_registry.dart';
import '../reactive/reactive_property.dart';
import '../types/enums/cover.dart';
import '../types/enums/format.dart';
import '../types/enums/gapless.dart';
import '../types/enums/hls_bitrate.dart';
import '../types/enums/hook.dart';
import '../types/enums/log_level.dart';
import '../types/enums/loop.dart';
import '../types/enums/spdif.dart';
import '../types/enums/tap_side.dart';
import '../types/sealed/channels.dart';
import '../types/sealed/media_session_command.dart';
import '../types/sealed/track.dart';
import '../types/settings/cache_settings.dart';
import '../types/settings/demuxer_settings.dart';
import '../types/settings/replay_gain_settings.dart';
import '../types/settings/spectrum_settings.dart';
import 'audio_output_error.dart';
import 'lifecycle_transitions.dart';
import 'player_api.dart';
import 'player_configuration.dart';
import 'player_state.dart';
import 'player_stream.dart';
import 'playlist_nav_gate.dart';

export '../events/mpv_hook_event.dart';
export '../events/mpv_log_entry.dart';
export '../generated/audio_effects.dart';
export '../generated/audio_effects_settings.dart';
export '../models/audio_params.dart';
export '../models/cover_art.dart';
export '../models/device.dart';
export '../models/loudness.dart';
export '../models/media.dart';
export '../models/media_session.dart';
export '../models/playlist.dart';
export '../models/source_resolve_request.dart';
export '../types/enums/format.dart';
export '../types/enums/interruption_policy.dart';
export '../types/enums/loop.dart';
export '../types/enums/media_action.dart';
export '../types/sealed/channels.dart';
export '../types/sealed/media_session_artwork.dart';
export '../types/sealed/media_session_command.dart';
export '../types/sealed/track.dart';
export '../types/settings/spectrum_settings.dart';
export 'player_configuration.dart';
export 'player_state.dart';
export 'player_stream.dart';

part 'mixins/player_audio.part.dart';
part 'mixins/player_dispatch.part.dart';
part 'mixins/player_ffi.part.dart';
part 'mixins/player_hooks.part.dart';
part 'mixins/player_init.part.dart';
part 'mixins/player_load_validation.part.dart';
part 'mixins/player_media_session.part.dart';
part 'mixins/player_network.part.dart';
part 'mixins/player_playback.part.dart';
part 'mixins/player_playlist.part.dart';

/// A high-performance audio player powered by libmpv.
///
/// Implements [PlayerApi] so test code can mock the player without
/// dragging in the FFI handle and event isolate
/// (`class MockPlayer extends Mock implements PlayerApi {}`).
class Player extends _PlayerBase
    with
        _FfiModule,
        _LoadValidationModule,
        _InitModule,
        _DispatchModule,
        _PlaybackModule,
        _PlaylistModule,
        _AudioModule,
        _NetworkModule,
        _HooksModule,
        _MediaSessionModule
    implements PlayerApi {
  /// Creates a [Player] instance with optional [configuration].
  Player({super.configuration});

  /// Process-wide single-instance guard for the OS media session.
  /// SMTC (Windows) and MPNowPlayingInfoCenter (Apple) are
  /// single-instance per process — enabling on a second [Player]
  /// would silently steal the first one's lockscreen entry. Linux
  /// MPRIS could support multiple instances via `instance<PID>`
  /// suffixing, but we ban it universally for cross-OS consistency.
  /// Cleared on `dispose()` and on `setMediaSession(null)`.
  static Player? _mediaSessionOwner;

  /// Test-only. The event isolate writes to [wakeupCounterAddress] on
  /// every wakeup — a bogus value corrupts process memory.
  @visibleForTesting
  Player.testInstrumented({
    super.configuration,
    required int super.wakeupCounterAddress,
  });

  // --- Public Specialized API ---

  /// Opens a [Media] and optionally starts playback immediately.
  ///
  /// `pause` is set as a global property before `loadfile` so the
  /// property observer always fires on the first-load transition
  /// (a per-file option can skip the `PROPERTY_CHANGE` emit).
  /// Rapid back-to-back `open()` calls don't race: each call claims the
  /// load epoch synchronously and aborts at its next await once a later
  /// content-replacing call (open / openAll / openPlaylistFile / stop /
  /// clearPlaylist) has claimed a newer one — so the call that is LAST
  /// in program order wins, regardless of per-URI resolve latency.
  @override
  Future<void> open(Media media, {bool? play}) async {
    _checkNotDisposed();
    final epoch = ++_loadEpoch;
    await _gate();
    if (epoch != _loadEpoch) return;
    _validateLoadOptions(media);
    final shouldPlay = play ?? configuration.autoPlay;
    // Optimistic intent (the play/pause axis), written at the call point —
    // BEFORE the `resolveUri` / trust-bundle awaits below — so a play() /
    // pause() issued right after open() (without awaiting it) wins by call
    // order instead of racing this write past the I/O hops. mpv leaves
    // `pause` at `no` and fires no PROPERTY_CHANGE on the first autoplay
    // load, so the observer alone would never surface this intent.
    _updateField(
      (s) => s.copyWith(playWhenReady: shouldPlay),
      _reactives.playWhenReady,
      shouldPlay,
    );
    _mediaCache.clear();
    _mediaCache[media.uri] = media;
    final resolved = await resolveUri(media.uri);
    if (_disposed || epoch != _loadEpoch) {
      await resolved.dispose?.call();
      return;
    }
    _mediaCache[resolved.uri] = media;
    // Execute in-flight transport writes (e.g. an un-awaited seek) before
    // the replace below, so they apply to the OLD file — see [_settleWrites].
    await _settleWrites();
    if (_disposed || epoch != _loadEpoch) {
      await resolved.dispose?.call();
      return;
    }
    // Captured BEFORE the pause write: when true, mpv is parked paused on
    // the last frame (`keep-open`), and the pre-loadfile `pause=no` below
    // does not survive — unpausing at EOF makes the playloop hit EOF again
    // and `keep-open-pause` re-pauses the core before the loadfile (queued
    // behind this write's async reply round-trip) is ever processed. The
    // corrective write after the replace is what actually sticks.
    final parkedAtEof = _state.completed;
    await _prop('pause', shouldPlay ? 'no' : 'yes');
    final opts = _buildLoadfileOptions(media);
    if (opts.isEmpty) {
      await _commandChecked(['loadfile', resolved.uri, 'replace']);
    } else {
      // Per-Media `httpHeaders` / `httpChunkSize` ride along as the 4th
      // `loadfile` arg (mpv 0.38+: index must be `-1` when options are
      // present), so mpv scopes them as file-local for this exact playlist
      // entry — never writing the global `http-header-fields` / `stream-lavf-o`.
      await _commandChecked(['loadfile', resolved.uri, 'replace', '-1', opts]);
    }
    if (parkedAtEof && shouldPlay) {
      await _prop('pause', 'no');
    }
    // Drop visible per-track state — cover art, chapter list and current
    // chapter index — so a UI that reads the state immediately after
    // `open()` returns doesn't render the previous track's data. Placed
    // AFTER the loadfile reply (not before): the async writes above
    // suspend, and by FIFO port delivery every still-queued OLD-file
    // PROPERTY_CHANGE (e.g. a trailing `chapter-list`) has been received
    // and applied by the time that reply lands — clearing here is the last
    // word before return, so none of those stale events survive into the
    // post-`open()` snapshot. The NEW file's FILE_LOADED arrives later and
    // repopulates.
    _clearPerFileState();
  }

  /// Opens a list of [Media] items as the new playlist, optionally starting at [index].
  ///
  /// Multi-media counterpart of [open]. [index] is clamped to
  /// `[0, medias.length - 1]`.
  ///
  /// Entries are appended on the core WITHOUT starting playback (mpv's
  /// `loadfile append` never autostarts), then a single
  /// `playlist-play-index` starts directly at [index]. The entry at
  /// position 0 is never loaded, played, or reported as current unless
  /// it IS the requested index — so a UI bound to
  /// [PlayerState.playlist]'s `index` never flashes track 1 before the
  /// selected track, and no audio from track 1 leaks out. During the
  /// transition the outgoing track keeps playing (or stays parked) until
  /// the jump; while entries build up on an idle core the playlist
  /// `index` reports `-1` (see [Playlist.index]).
  @override
  Future<void> openAll(List<Media> medias, {bool? play, int index = 0}) async {
    _checkNotDisposed();
    if (medias.isEmpty) {
      return;
    }
    // Claim the load epoch synchronously — see [open].
    final epoch = ++_loadEpoch;
    await _gate();
    if (epoch != _loadEpoch) return;
    // Validate the full batch before any side-effect, so a bad header
    // on entry N can't leave entries 0..N-1 half-loaded.
    for (final m in medias) {
      _validateLoadOptions(m);
    }
    final clampedIndex = index.clamp(0, medias.length - 1);
    final shouldPlay = play ?? configuration.autoPlay;
    // Optimistic intent written at the call point, before the resolve / tls
    // awaits below — see [open] for the rationale.
    _updateField(
      (s) => s.copyWith(playWhenReady: shouldPlay),
      _reactives.playWhenReady,
      shouldPlay,
    );
    // Snapshot the outgoing current entry's Media so it keeps its
    // metadata while still visible in playlist events during the
    // transition (retained until the post-jump remove below).
    final oldPlaylist = _state.playlist;
    final oldCurrent = oldPlaylist.items.isNotEmpty &&
            oldPlaylist.index >= 0 &&
            oldPlaylist.index < oldPlaylist.items.length
        ? oldPlaylist.items[oldPlaylist.index]
        : null;
    _mediaCache.clear();
    if (oldCurrent != null) _mediaCache[oldCurrent.uri] = oldCurrent;
    // Resolve once per media — content:// resolutions detach a JVM-side
    // FD, doing it twice would leak one FD per track.
    final resolved = <ResolvedUri>[];
    try {
      for (final m in medias) {
        _mediaCache[m.uri] = m;
        final r = await resolveUri(m.uri);
        if (_disposed || epoch != _loadEpoch) {
          await r.dispose?.call();
          for (final prior in resolved) {
            await prior.dispose?.call();
          }
          return;
        }
        _mediaCache[r.uri] = m;
        resolved.add(r);
      }
    } catch (_) {
      // Mid-loop failure: dispose the partially-resolved entries to
      // avoid leaking content:// file descriptors / asset cache files,
      // then rethrow so the caller observes the original error.
      for (final prior in resolved) {
        await prior.dispose?.call();
      }
      rethrow;
    }
    // Execute in-flight transport writes before the replace — see
    // [_settleWrites].
    await _settleWrites();
    if (_disposed || epoch != _loadEpoch) {
      for (final prior in resolved) {
        await prior.dispose?.call();
      }
      return;
    }
    // ── Phase 1: clear the outgoing playlist ──────────────────────────
    // `playlist-clear` keeps ONLY the current entry (mpv's
    // playlist_clear_except_current), so the outgoing track keeps
    // playing while the new entries build up — no idle gap, no silence.
    // The flow is decided from mpv's own properties AFTER the clear
    // (`playlist-count`, `eof-reached`), not from the Dart-side state
    // snapshot: state can lag the core by an event round-trip, and a
    // wrong guess here would offset every append target below.
    Future<void> bailDisposing() async {
      for (final prior in resolved) {
        await prior.dispose?.call();
      }
    }

    await _command(['playlist-clear']);
    if (_disposed || epoch != _loadEpoch) return bailDisposing();
    final retainedCount =
        int.tryParse(await getRawProperty('playlist-count') ?? '') ?? 0;
    if (_disposed || epoch != _loadEpoch) return bailDisposing();
    var parkedAtEof = false;
    if (retainedCount > 0) {
      // A retained entry parked at EOF cannot survive the appends:
      // `keep-open` holds the park only while no next entry exists (mpv's
      // handle_keep_open), so the first append would create a "next" and
      // mpv would auto-advance into the new album's entry 0 —
      // resurrecting the exact transient this flow eliminates. Remove it
      // NOW instead: the playlist is single-entry after the clear, so
      // PT_NEXT_ENTRY finds nothing and the core goes idle — where
      // appends provably never autostart.
      parkedAtEof = await getRawProperty('eof-reached') == 'yes';
      if (_disposed || epoch != _loadEpoch) return bailDisposing();
      if (parkedAtEof) {
        await _command(['playlist-remove', '0']);
        if (_disposed || epoch != _loadEpoch) return bailDisposing();
        // Barrier: wait for the core to actually reach idle before any
        // append. The remove's playback teardown runs asynchronously on
        // the playloop, and an append landing before it completes gets
        // picked up by the end-of-file advancement — playlist_get_next
        // from a NULL current with the playlist not started returns
        // entry 0 — which would start the incoming album's first track:
        // the exact transient this flow eliminates. Idle lands within a
        // playloop iteration; the bound only guards a wedged core.
        for (var i = 0; i < 100; i++) {
          if (await getRawProperty('idle-active') == 'yes') break;
          if (_disposed || epoch != _loadEpoch) return bailDisposing();
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        if (_disposed || epoch != _loadEpoch) return bailDisposing();
      }
    }
    // Whether an old entry is still occupying position 0 (the playing
    // flow): the append targets shift by one until the post-jump remove
    // drops it.
    final retainedOld = retainedCount > 0 && !parkedAtEof;

    // ── Phase 2: append every entry — playback never starts here ──────
    // mpv's `loadfile append` is play=false unconditionally (unlike
    // append-play), even on an idle core. Per-Media `httpHeaders` ride
    // along as the 4th `loadfile` arg, so mpv scopes them as file-local
    // without ever writing the global `http-header-fields` option.
    for (var i = 0; i < medias.length; i++) {
      final opts = _buildLoadfileOptions(medias[i]);
      if (opts.isEmpty) {
        await _commandChecked(['loadfile', resolved[i].uri, 'append']);
      } else {
        await _commandChecked(
            ['loadfile', resolved[i].uri, 'append', '-1', opts],);
      }
      if (_disposed || epoch != _loadEpoch) return bailDisposing();
    }

    // ── Phase 3: intent, then one direct jump to the target ───────────
    // The pause write cannot be fought by keep-open here: the parked
    // flow already left EOF (idle after the remove above), and the
    // playing flow is mid-track. `playlist-play-index` sets
    // playlist->current straight to the target entry (mp_set_playlist_
    // entry) — entries before it are never loaded or made current.
    await _prop('pause', shouldPlay ? 'no' : 'yes');
    final target = (retainedOld ? 1 : 0) + clampedIndex;
    await _commandChecked(['playlist-play-index', target.toString()]);

    // Parked flow traversed idle, and the idle-active observer resets
    // playWhenReady (its job when content genuinely ends). By FIFO
    // event delivery that reset has already been applied once the
    // play-index reply lands, so re-asserting the intent here is the
    // last word — without this the OS play button would stick on
    // "paused" while the new album plays.
    if (parkedAtEof) {
      _updateField(
        (s) => s.copyWith(playWhenReady: shouldPlay),
        _reactives.playWhenReady,
        shouldPlay,
      );
    }

    // ── Phase 4: drop the retained old entry ──────────────────────────
    // Non-current by now (the jump moved current to the target), so the
    // removal is pure bookkeeping; indices shift down to their final
    // positions. Tolerant `_command`: a concurrent surgery that already
    // emptied position 0 must not surface as an openAll error.
    if (retainedOld) {
      if (_disposed || epoch != _loadEpoch) return bailDisposing();
      await _command(['playlist-remove', '0']);
    }
    // Clear per-track state AFTER the jump's reply — see [open] for why
    // the placement (post-reply) is what makes the clear the last word
    // over trailing OLD-file PROPERTY_CHANGE events.
    _clearPerFileState();
  }

  /// Loads a playlist FILE or URL (`.m3u` / `.m3u8` / `.pls` / `.cue`) and
  /// optionally starts playback. Unlike [open] — which loads [playlist] as a
  /// single entry — this parses it with mpv's `loadlist`, so its entries
  /// become the playlist. This is the path for internet-radio station lists
  /// and remote `.m3u` playlists.
  ///
  /// [PlayerStream.playlist] / [PlayerState.playlist] reflect the parsed
  /// entries once mpv expands them. When [play] is null the configuration's
  /// autoplay value decides. Replaces any currently loaded file or playlist.
  ///
  /// Per-[Media] options (`httpHeaders`, `demuxerLavfOptions`, `httpChunkSize`)
  /// are validated but NOT applied to the playlist fetch — `loadlist` has no
  /// file-local options slot. Entries parsed out of the playlist inherit the
  /// global network/demuxer settings.
  @override
  Future<void> openPlaylistFile(Media playlist, {bool? play}) async {
    _checkNotDisposed();
    // Claim the load epoch synchronously — see [open].
    final epoch = ++_loadEpoch;
    await _gate();
    if (epoch != _loadEpoch) return;
    _validateLoadOptions(playlist);
    final shouldPlay = play ?? configuration.autoPlay;
    // Optimistic intent written at the call point — same rationale as [open].
    _updateField(
      (s) => s.copyWith(playWhenReady: shouldPlay),
      _reactives.playWhenReady,
      shouldPlay,
    );
    _mediaCache.clear();
    final resolved = await resolveUri(playlist.uri);
    if (_disposed || epoch != _loadEpoch) {
      await resolved.dispose?.call();
      return;
    }
    // Execute in-flight transport writes before the replace — see
    // [_settleWrites].
    await _settleWrites();
    if (_disposed || epoch != _loadEpoch) {
      await resolved.dispose?.call();
      return;
    }
    // See [open] — parked at EOF the pre-loadlist unpause doesn't survive
    // mpv's keep-open re-pause; a corrective write after the replace does.
    final parkedAtEof = _state.completed;
    await _prop('pause', shouldPlay ? 'no' : 'yes');
    await _commandChecked(['loadlist', resolved.uri, 'replace']);
    if (parkedAtEof && shouldPlay) {
      await _prop('pause', 'no');
    }
    // Clear per-track state AFTER the replace's reply — see [open].
    _clearPerFileState();
  }

  @override
  Future<void> _disposeImpl() async {
    // Release the OS media session BEFORE tearing libmpv down. After
    // the base teardown the FFI handle is gone — leaving the native
    // session published would surface a stale lockscreen entry
    // pointing at a dead Player, and incoming commands (play from
    // the lockscreen) would land on disposed state. New calls are refused
    // from the first line, as the teardown order below says.
    _disposed = true;
    try {
      await _releaseMediaSession();
    } catch (_) {
      // Best effort — session teardown must never block disposal.
    }
    _cancelHookTimers();
    await super._disposeImpl();
  }
}

/// Base class for [Player] containing shared state and native communication
/// logic.
///
/// Owns:
/// - the FFI handle and event-isolate plumbing,
/// - the [PropertyRegistry] for the ~60 simple mpv properties,
/// - the small set of standalone [ReactiveProperty]s and [StreamController]s
///   that back state fields not directly mirrored by an mpv property
///   (lifecycle: `buffering`/`completed`; complex JSON parses: `playlist`,
///   `metadata`, `audioDevices`, `bufferingPercentage`; pure events: log,
///   error, hook, end-of-file, seek-completed).
abstract class _PlayerBase {
  final PlayerConfiguration configuration;

  late final MpvLibrary _lib;
  late final Pointer<MpvHandle> _handle;
  // Bundled with [_lib] + [_handle] inside a single object so a
  // [Finalizer] can keep a reference and reach the lib even after the
  // player itself is GC'd.
  late final PlayerNativeResources _nativeResources;
  // Eagerly instantiated so `dispose()` is safe even when invoked
  // synchronously after construction. The actual mpv init runs
  // inside the isolate, driven by `_ready`.
  final MpvEventIsolate _eventIsolate = MpvEventIsolate();
  bool _disposed = false;

  // Latched true on the first MPV_EVENT_START_FILE. Gates the idle-active
  // intent reset: the initial observe burst delivers `idle-active=true`
  // (the player starts idle) BEFORE any file load is attempted, and that
  // stale value must not clear a `playWhenReady` intent set by an
  // open(play: true) that is still settling. Port delivery is FIFO, so the
  // startup idle-active always precedes the first START_FILE. Latching on
  // START_FILE (which fires even for a load that fails to open) rather than
  // FILE_LOADED means a failed first open() still arms the reset, so its
  // intent doesn't stick true.
  bool _hasLoadedFile = false;

  // `_activeHookIds` is authoritative for [Player.continueHook]: mpv's
  // behaviour on stale ids is undefined across versions, so duplicate
  // continues are rejected here before they reach FFI.
  // `_registeredHookNames` collapses duplicate registrations per name —
  // mpv allows multiples, but its shutdown path can stall when several
  // events for the same hook are still in flight at quit time.
  final _hookTimeouts = <String, Duration>{};
  final _hookTimers = <int, Timer>{};
  final _activeHookIds = <int>{};
  final _registeredHookNames = <String>{};
  // Hook names the CONSUMER registered via [Player.registerHook], a
  // subset of `_registeredHookNames` (the resolver below registers
  // `on_load` / `on_load_fail` internally without adding here). Only
  // user-registered hooks surface on [PlayerStream.hook] and transfer
  // the continue obligation to the consumer; internally-registered ones
  // are continued by the library.
  final _userHookNames = <String>{};

  // The installed [SourceResolver]; null = feature off. Set by
  // [Player.setSourceResolver], consulted by `_routeHookEvent` on every
  // `on_load` / `on_load_fail` event.
  SourceResolver? _sourceResolver;

  // Latched when the resolver services an `on_load_fail` for the current
  // load attempt, cleared on the next START_FILE / `on_load`. Caps the
  // resolver-driven retry at ONE per load: a resolver that keeps minting
  // fresh-but-broken URLs (e.g. a timestamped query string) would
  // otherwise put mpv in an infinite open-fail-reopen loop.
  bool _resolverRetried = false;

  PlayerState _state = const PlayerState();

  /// Reused `commit` callback for every registry dispatch — tearing off (or
  /// closing over) per event would be one piece of garbage per property
  /// change, so the tear-off is captured once.
  late final void Function(PlayerState) _commitState = _assignState;

  void _assignState(PlayerState s) => _state = s;

  final Map<String, Media> _mediaCache = {};

  // Monotonic generation counter for content-replacing transport calls.
  // Bumped synchronously at the head of open() / openAll() /
  // openPlaylistFile() / stop() / clearPlaylist(); every load path
  // re-checks it after each await and aborts when stale. Without it,
  // per-scheme resolve latencies (asset:// does real I/O, a plain path
  // resolves in one microtask) let an EARLIER call issue its loadfile
  // AFTER a later one — the superseded media would win, and an in-flight
  // open() could resume past a stop() and restart playback.
  int _loadEpoch = 0;

  // ── Property registry (the bulk of state — one spec per mpv property) ──
  late final DefaultPropertyReactives _reactives;
  late final PropertyRegistry _registry;

  // ── Standalone reactive properties (no 1:1 mpv property backing) ───────
  // Lifecycle flags driven by file-boundary events, not by a single property.
  final ReactiveProperty<bool> _buffering = ReactiveProperty<bool>(false);
  final ReactiveProperty<bool> _completed = ReactiveProperty<bool>(false);
  // Derived from JSON properties that need access to player-side context.
  final ReactiveProperty<Playlist> _playlist =
      ReactiveProperty<Playlist>(Playlist.empty);
  final ReactiveProperty<Loop> _loop = ReactiveProperty<Loop>(Loop.off);
  final ReactiveProperty<List<Device>> _audioDevices =
      ReactiveProperty<List<Device>>(
    const [Device(name: 'auto', description: 'Auto')],
  );
  final ReactiveProperty<Map<String, String>> _metadata =
      ReactiveProperty<Map<String, String>>(const <String, String>{});
  final ReactiveProperty<double> _bufferingPercentage =
      ReactiveProperty<double>(0.0);
  final ReactiveProperty<DemuxerCacheState> _demuxerCacheState =
      ReactiveProperty<DemuxerCacheState>(DemuxerCacheState.empty);
  // OS media-session config + metadata override. Null = disabled.
  // Updated synchronously by [_MediaSessionModule.setMediaSession].
  final ReactiveProperty<MediaSession?> _mediaSession =
      ReactiveProperty<MediaSession?>(null);

  // Dart-side orchestrator that ferries state from `PlayerStream` to
  // the native media-session channel and routes inbound OS commands
  // back. Null while the session is disabled; lazily allocated on
  // first `setMediaSession(non-null)` and torn down on disable or
  // on `dispose()`.
  MediaSessionController? _mediaSessionController;

  // ── Pure event streams (no current value) ───────────────────────────────
  final StreamController<MpvFileEndedEvent> _endFileCtrl =
      StreamController<MpvFileEndedEvent>.broadcast();
  final StreamController<MpvPlayerError> _errorCtrl =
      StreamController<MpvPlayerError>.broadcast();
  // Log stream from the mpv engine itself (codec / demux / ao / …).
  final StreamController<MpvLogEntry> _logCtrl =
      StreamController<MpvLogEntry>.broadcast();
  // Log stream from the Dart layer itself — JSON parse warnings, hook
  // timeouts, etc. Kept disjoint from `_logCtrl` so library-side noise
  // can be filtered from genuine engine messages without inspecting
  // the prefix.
  final StreamController<MpvLogEntry> _internalLogCtrl =
      StreamController<MpvLogEntry>.broadcast();
  final StreamController<MpvHookEvent> _hookCtrl =
      StreamController<MpvHookEvent>.broadcast();
  final StreamController<void> _seekCompletedCtrl =
      StreamController<void>.broadcast();
  // Nullable payload: each file-loaded transition emits exactly once,
  // with `null` when the new file has no embedded cover. This lets a
  // UI clear / reset on every track change without having to compare
  // against a separate file-transition signal.
  final StreamController<CoverArt?> _coverArtCtrl =
      StreamController<CoverArt?>.broadcast();
  // Incoming commands from the OS media session (lockscreen, BT
  // headset, Siri / Assistant), routed back from the per-platform
  // native implementation.
  final StreamController<MediaSessionCommand> _mediaSessionCommandsCtrl =
      StreamController<MediaSessionCommand>.broadcast();

  // Real-time FFT + raw PCM pipeline. Lazy: the poll loop starts only
  // when something subscribes to `stream.spectrum` or `stream.pcm`.
  late final SpectrumPipeline _spectrumPipeline;

  // Static waveform analyzer. Listener-gated: arms the native
  // analyzer and polls only while `stream.waveform` has a listener.
  late final WaveformPipeline _waveformPipeline;

  // Per-filter pre/post audio tap. Lazy: arms the analyzer-taps
  // property only when at least one [PlayerStream.tap] stream has a
  // listener.
  late final FilterTapPipeline _filterTapPipeline;

  // Live EBU R128 meter. Listener-gated: polls `af-metadata` only while
  // `stream.loudness` has a listener (the `ebur128` effect itself is
  // enabled by the consumer on the AudioEffects bundle).
  late final LoudnessMeterPipeline _loudnessMeterPipeline;

  // Offline loudness scan. Listener-gated: arms the native whole-file
  // scan and polls only while `stream.loudness` has a listener.
  late final LoudnessScanPipeline _loudnessScanPipeline;

  PlayerState get state => _state;
  late final PlayerStream stream;

  /// Test-only; `null` outside [Player.testInstrumented].
  final int? _wakeupCounterAddress;

  // ── Cross-mixin surface ──────────────────────────────────────────────────
  // These members live in the `.part` mixins below but are declared here
  // (abstract) so `_PlayerBase`'s constructor / `dispose` and the sibling
  // domain mixins can call across part boundaries — `on _PlayerBase` only
  // exposes what `_PlayerBase` itself declares.

  /// See `_FfiModule` (player_ffi.part.dart). All writes ride the async
  /// client API (`mpv_*_async`): the call enqueues on the core's dispatch
  /// and the returned future completes when the event isolate forwards the
  /// reply — so the main isolate never waits for the playloop (which can be
  /// stalled for seconds inside audio-output init). The optimistic state
  /// writes in the setters stay synchronous; only the mpv confirmation is
  /// deferred.
  Future<void> _prop(String name, String value);
  Future<int> _propRc(String name, String value);
  Future<int> _command(List<String> args);
  Future<void> _commandChecked(List<String> args);
  Future<int> _setChapterListNode(List<Chapter> chapters);

  /// Async property read (see `_FfiModule`): enqueues
  /// `mpv_get_property_async` and resolves with `(error, decodedValue)`
  /// once the event isolate forwards the reply.
  Future<(int, dynamic)> _getAsync(String name, int format);
  String _errorString(int code);

  // ── Async-reply correlation ────────────────────────────────────────────
  // Every `mpv_*_async` call is tagged with a fresh id; the event isolate
  // forwards the matching reply and `_handleEvent` completes the future.
  // Ids stay unique for the player's lifetime (an int in Dart does not
  // wrap), and never collide with `mpv_observe_property` reply ids — those
  // live in a different event namespace (PROPERTY_CHANGE).
  int _nextReplyId = 1;
  final Map<int, Completer<int>> _pendingReplies = {};
  final Map<int, Completer<(int, dynamic)>> _pendingGetReplies = {};

  /// Set true by dispose AFTER the event isolate has stopped and the pending
  /// replies are about to be drained, immediately before `mpv_terminate_destroy`
  /// frees the handle. The FFI primitives in `_FfiModule` check it so a
  /// continuation the drain resumes (a multi-write setter suspended between
  /// writes) never issues `mpv_*_async` against the freed handle. Distinct from
  /// `_disposed` (set at the very start of dispose) because the dispose `quit`
  /// must still reach mpv — it is issued while this is still false.
  bool _ffiClosed = false;

  /// In-flight `registerHook` runs. `mpv_hook_add` locks the core and has no
  /// async variant, so it executes in a throwaway `Isolate.run` against the
  /// shared handle; dispose must await any outstanding one BEFORE
  /// `mpv_terminate_destroy` frees the handle, or the throwaway isolate would
  /// dereference freed memory (`lock_core(ctx)`).
  final Set<Future<void>> _pendingHookAdds = {};

  /// Completes every still-pending async reply after the event isolate has
  /// stopped (no reply can arrive anymore). Writes resolve as successes —
  /// the request was accepted into the queue, matching the pre-async
  /// behaviour where a call racing dispose still completed normally; reads
  /// resolve as failures so they surface as `null` values.
  void _drainPendingReplies() {
    for (final completer in _pendingReplies.values) {
      if (!completer.isCompleted) completer.complete(0);
    }
    _pendingReplies.clear();
    for (final completer in _pendingGetReplies.values) {
      if (!completer.isCompleted) {
        completer.complete((MpvError.mpvErrorGeneric, null));
      }
    }
    _pendingGetReplies.clear();
  }

  /// See `_LoadValidationModule` (player_load_validation.part.dart).
  String _buildLoadfileOptions(Media media);
  void _validateLoadOptions(Media media);

  /// See `_FfiModule` — the raw property escape hatches, redeclared here
  /// so the source-resolver driver in `_HooksModule` can read and rewrite
  /// `stream-open-filename` across the part boundary.
  Future<String?> getRawProperty(String name);
  Future<void> setRawProperty(String name, String value);

  /// See `_HooksModule` (player_hooks.part.dart) — called by the dispatch
  /// layer for every MPV_EVENT_HOOK: runs the source resolver when one is
  /// installed, then either surfaces the event on [PlayerStream.hook]
  /// (user-registered hook) or continues it internally.
  Future<void> _routeHookEvent(int id, Hook hook, String name);

  // Set by the audio module when af-command updates leave the live graph
  // ahead of the `af` property string; cleared by the dispatch layer when
  // it resyncs the string on the next file load (mpv rebuilds chains from
  // the string, which would otherwise revert the live values).
  bool _afStringStale = false;

  /// See `_InitModule` (player_init.part.dart) — called by the constructor.
  Future<void> _bringUpInIsolate();

  /// See `_DispatchModule` (player_dispatch.part.dart) — wired as the event
  /// isolate's `onEvent` during bring-up.
  void _handleEvent(MpvIsolateEvent event);

  /// See `_DispatchModule` — `setAudioDevice` reuses it to optimistically
  /// resolve the device description from the parsed `audio-device-list`.
  void _updateActiveAudioDevice(String name);

  _PlayerBase({
    this.configuration = const PlayerConfiguration(),
    int? wakeupCounterAddress,
  }) : _wakeupCounterAddress = wakeupCounterAddress {
    // Pure-Dart setup runs on the main isolate (microseconds).
    _reactives = DefaultPropertyReactives();
    _registry = PropertyRegistry()
      ..registerAll(
        buildDefaultSpecs(
          _reactives,
          onIdleActive: (idle) {
            if (idle) {
              _updateLifecycle(playing: false, buffering: false);
              // mpv has entered its idle loop (nothing loaded) → the
              // play/pause intent is spent; settle the OS button on "play".
              // Gated on [_hasLoadedFile] so the startup idle-active burst
              // can't clear a fresh open(play: true) intent. mpv reaches idle
              // after a `stop`, or after a load that ends with no next entry
              // and is NOT held by keep-open (e.g. a failed first open). The
              // natural end of playable content under the shipped
              // `keep-open: yes` does NOT fire idle-active — that path is
              // handled by [onEofReached] instead. A mid-playlist advance
              // also doesn't fire idle-active, so this never flickers.
              if (_hasLoadedFile) {
                _updateField(
                  (s) => s.copyWith(playWhenReady: false),
                  _reactives.playWhenReady,
                  false,
                );
              }
            }
          },
          onAudioOutputState: (state) {
            final err = buildAudioOutputError(state);
            if (err != null) _errorCtrl.add(err);
          },
          onEofReached: (eof) {
            // `keep-open: yes` (shipped pre-init option) makes mpv park
            // paused on the last frame at end-of-content and withhold BOTH
            // MPV_EVENT_END_FILE and idle-active, so the two writers that
            // normally settle the transport (the EndFile completed flag and
            // the idle-active intent reset) never fire for a single track or
            // the last playlist entry. The `eof-reached` rising edge is the
            // signal that DOES fire there.
            if (!_hasLoadedFile) return;
            if (eof) {
              // Only at the GENUINE end of content — not a gapless
              // mid-playlist boundary (where eof-reached can blip) and not
              // while looping (where the file/playlist restarts). Otherwise
              // the OS play/pause button would flicker.
              if (_isEndOfContent()) {
                _updateLifecycle(completed: true);
                _updateField(
                  (s) => s.copyWith(playWhenReady: false),
                  _reactives.playWhenReady,
                  false,
                );
              }
            } else if (_state.completed) {
              // Left the end (a seek back into the track, or a new file):
              // the track is no longer completed.
              _updateLifecycle(completed: false);
            }
          },
        ),
      );

    // Streams that don't need _lib/_handle can be wired immediately —
    // a consumer subscribing right after `Player()` sees no events
    // until init completes, which is the correct semantics.
    //
    // The fft/pcm bridges into the spectrum pipeline are listener-gated:
    // the pipeline arms its 30fps `pcm-tap-frame` poll as soon as its own
    // streams have a listener, so bridging unconditionally would keep the
    // poll running for the player's whole lifetime with zero consumers.
    // Subscribers that land before bring-up are reconciled once the
    // pipeline exists (see `_bringUpInIsolate`).
    _fftCtrl = StreamController<FftFrame>.broadcast(
      onListen: () {
        if (_bringUpCompleted) {
          _fftPipeSub ??= _spectrumPipeline.fftStream.listen(_fftCtrl.add);
        }
      },
      onCancel: () {
        final sub = _fftPipeSub;
        _fftPipeSub = null;
        if (sub != null) unawaited(sub.cancel());
      },
    );
    _pcmStreamCtrl = StreamController<PcmFrame>.broadcast(
      onListen: () {
        if (_bringUpCompleted) {
          _pcmPipeSub ??=
              _spectrumPipeline.pcmStream.listen(_pcmStreamCtrl.add);
        }
      },
      onCancel: () {
        final sub = _pcmPipeSub;
        _pcmPipeSub = null;
        if (sub != null) unawaited(sub.cancel());
      },
    );
    _spectrumCtrl = StreamController<SpectrumSettings>.broadcast();
    // Listener-gated: the native waveform analyzer arms only while a
    // consumer is subscribed. The pipeline is built during isolate
    // bring-up; a subscriber that lands before then is reconciled
    // once bring-up finishes (see `_bringUpInIsolate`).
    _waveformCtrl = StreamController<WaveformData?>.broadcast(
      onListen: () {
        if (_bringUpCompleted) _waveformPipeline.setEnabled(true);
      },
      onCancel: () {
        if (_bringUpCompleted) _waveformPipeline.setEnabled(false);
      },
    );
    // Same listener-gating as the waveform: the af-metadata poll runs
    // only while someone is subscribed to `stream.loudnessMeter`.
    _loudnessMeterCtrl = StreamController<Loudness>.broadcast(
      onListen: () {
        if (_bringUpCompleted) _loudnessMeterPipeline.setEnabled(true);
      },
      onCancel: () {
        if (_bringUpCompleted) _loudnessMeterPipeline.setEnabled(false);
      },
    );
    // Listener-gated like the waveform: the native whole-file scan runs
    // only while someone is subscribed to `stream.loudness`.
    _loudnessScanCtrl = StreamController<LoudnessScan?>.broadcast(
      onListen: () {
        if (_bringUpCompleted) _loudnessScanPipeline.setEnabled(true);
      },
      onCancel: () {
        if (_bringUpCompleted) _loudnessScanPipeline.setEnabled(false);
      },
    );
    stream = PlayerStream.fromInternals(
      reactives: _reactives,
      buffering: _buffering,
      completed: _completed,
      playlist: _playlist,
      loop: _loop,
      audioDevices: _audioDevices,
      metadata: _metadata,
      bufferingPercentage: _bufferingPercentage,
      demuxerCacheState: _demuxerCacheState,
      audioEffects: _reactives.audioEffects,
      mediaSession: _mediaSession,
      endFile: _endFileCtrl.stream,
      error: _errorCtrl.stream,
      log: _logCtrl.stream,
      internalLog: _internalLogCtrl.stream,
      hook: _hookCtrl.stream,
      seekCompleted: _seekCompletedCtrl.stream,
      coverArt: _coverArtCtrl.stream,
      fft: _fftCtrl.stream,
      pcm: _pcmStreamCtrl.stream,
      spectrum: _spectrumCtrl.stream,
      waveform: _waveformCtrl.stream,
      loudnessMeter: _loudnessMeterCtrl.stream,
      loudness: _loudnessScanCtrl.stream,
      tap: (filter, {required side}) => switch (side) {
        TapSide.pre => _filterTapPipeline.tapPre(filter.filterName),
        TapSide.post => _filterTapPipeline.tapPost(filter.filterName),
      },
      mediaSessionCommands: _mediaSessionCommandsCtrl.stream,
    );

    // Build the recipe and hand it to the event isolate. All heavy
    // FFI runs there; the main isolate stays free.
    _ready = _bringUpInIsolate();
  }

  /// Test-only — allows tests to await the post-`Player()` init that
  /// now runs in the background isolate. Public methods already
  /// `await _ready` internally so consumers don't normally need this.
  @visibleForTesting
  Future<void> get ready => _ready;

  late final Future<void> _ready;
  bool _bringUpCompleted = false;

  /// Last playlist-entry `path` the waveform pipeline was reset for. Lets the
  /// FILE_LOADED handler skip the redundant reset mpv fires on internal
  /// reloads of the same source (see the dedup in `_handleEvent`).
  String? _lastWaveformSource;
  late final StreamController<FftFrame> _fftCtrl;
  late final StreamController<PcmFrame> _pcmStreamCtrl;
  // Lazy bridges into the spectrum pipeline — non-null exactly while the
  // matching public stream has a listener (they keep the pipeline's
  // listener-gated poll loop armed; see the controllers' onListen).
  StreamSubscription<FftFrame>? _fftPipeSub;
  StreamSubscription<PcmFrame>? _pcmPipeSub;
  late final StreamController<SpectrumSettings> _spectrumCtrl;
  late final StreamController<WaveformData?> _waveformCtrl;
  late final StreamController<Loudness> _loudnessMeterCtrl;
  late final StreamController<LoudnessScan?> _loudnessScanCtrl;

  void _startHookTimeout(int id, String name, Duration timeout) {
    _hookTimers[id] = Timer(timeout, () {
      _hookTimers.remove(id);
      // The active-id set is the source of truth: if a manual
      // continueHook beat us to it, the id is gone and we skip the
      // redundant FFI call.
      if (!_activeHookIds.remove(id)) return;
      _internalLog(
        'Hook "$name" (id=$id) timed out after ${timeout.inSeconds}s — '
        'auto-continuing to unblock mpv',
        level: LogLevel.warn,
      );
      if (!_disposed) _lib.mpvHookContinue(_handle, id);
    });
  }

  void _cancelHookTimers() {
    for (final timer in _hookTimers.values) {
      timer.cancel();
    }
    _hookTimers.clear();
    // Continue every still-active hook on mpv's side BEFORE we drop
    // them from the active set. Without this, mpv blocks on the
    // pending hooks during its shutdown path: `dispose()` issues
    // `quit`, mpv tries to drain the hook queue first, and never
    // fires MPV_EVENT_SHUTDOWN — so the event isolate never exits.
    // `_cancelHookTimers` is called from dispose BEFORE `_disposed`
    // is flipped, so the handle is still valid here.
    for (final id in _activeHookIds) {
      _lib.mpvHookContinue(_handle, id);
    }
    _activeHookIds.clear();
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('Player has been disposed');
    }
  }

  /// Shared prologue for every public method that touches the FFI handle:
  /// fail fast when already disposed, await bring-up, then verify bring-up
  /// actually assigned the FFI fields. A dispose() that lands while the
  /// caller is parked on [_ready] aborts bring-up early — [_ready] still
  /// completes normally, but `_lib` / `_handle` were never assigned, so
  /// resuming into an FFI call would throw [LateInitializationError]
  /// instead of the [StateError] the API contract promises.
  Future<void> _gate() async {
    _checkNotDisposed();
    await _ready;
    if (!_bringUpCompleted) {
      throw StateError('Player has been disposed');
    }
  }

  /// Completes when every write currently on the wire has been executed
  /// (its reply forwarded, or settled by the dispose drain). Snapshot
  /// semantics: writes enqueued after this call are not waited on.
  ///
  /// The synchronous client API implicitly guaranteed "previous request
  /// EXECUTED before the next public call's request is issued"; with the
  /// async API two requests can coalesce into one core dispatch drain and
  /// interact — e.g. an un-awaited `seek` surviving a replace `loadfile`
  /// (its `queue_seek` entry rides into the NEW file) instead of being
  /// aborted by it. Content-replacing and playlist-navigation methods call
  /// this right before their first write so earlier in-flight transport
  /// commands are executed first, restoring the old inter-call semantics
  /// while the main isolate stays free — under a stalled core the FUTURES
  /// queue up, not the UI thread.
  Future<void> _settleWrites() {
    if (_pendingReplies.isEmpty) return Future.value();
    return Future.wait(
      [for (final completer in _pendingReplies.values) completer.future],
    );
  }

  /// Rejects NaN / +Inf / -Inf before they reach `toStringAsFixed`,
  /// which would emit the literal `'NaN'` / `'Infinity'` and have mpv
  /// reject the property write at the FFI boundary. Catching it on the
  /// wrapper side gives the caller a precise [ArgumentError] naming the
  /// parameter, instead of an opaque [MpvException] from libmpv.
  void _checkFinite(double value, String paramName) {
    if (!value.isFinite) {
      throw ArgumentError.value(
        value,
        paramName,
        'Expected a finite double (got NaN/Infinity)',
      );
    }
  }

  // --- Internal State Pipeline ---

  /// Optimistic state update used by every typed setter after pushing
  /// a value to mpv. Writes [value] into [reactive] (which dedups, so
  /// equal writes are silent on the stream) and folds it into [_state]
  /// via [updater]. Short-circuits on dedup to skip a redundant
  /// [PlayerState] allocation.
  void _updateField<T>(
    PlayerState Function(PlayerState) updater,
    ReactiveProperty<T> reactive,
    T value,
  ) {
    if (!reactive.update(value)) return;
    _state = updater(_state);
  }

  /// Clears the per-track fields a consumer is likely to read
  /// synchronously on a track-change boundary (the public open()
  /// path returns before the new file's MPV_EVENT_FILE_LOADED
  /// fires).
  ///
  /// Restricted to fields where mpv re-emits the new value reliably
  /// after the load. mpv's own observer (see
  /// `player/client.c::send_client_property_changes`) dedupes on
  /// `equal_mpv_value(prop->value, val)`, so any property whose new
  /// value happens to match the previously-observed value (same
  /// `duration` across two tracks; same `embedded-cover-art-data`
  /// for same-album files; same `chapter-list`) would NOT fire
  /// PROPERTY_CHANGE. Wrapper-side reset to defaults on those would
  /// strand the cell at the default until the next genuinely-new
  /// value arrives. `position` is safe because `time-pos` re-emits
  /// at ~30Hz during playback. The remaining fields are handled by
  /// custom paths that do not depend on mpv's observer dedup.
  void _clearPerFileState() {
    final r = _reactives;
    r.position.update(Duration.zero);
    r.currentChapter.update(null);
    r.chapters.update(const <Chapter>[]);
    _state = _state.copyWith(
      position: Duration.zero,
      coverArt: null,
      currentChapter: null,
      chapters: const <Chapter>[],
    );
    _coverArtCtrl.add(null);
  }

  /// Updates the lifecycle triple (playing/buffering/completed) and
  /// emits per-reactive only for fields that actually changed. Used
  /// for compound transitions (start-file, file-loaded, end-file,
  /// shutdown, idle-active). The pure diff lives in [computeLifecycle].
  void _updateLifecycle({bool? playing, bool? buffering, bool? completed}) {
    final result = computeLifecycle(
      prev: _state,
      playing: playing,
      buffering: buffering,
      completed: completed,
    );
    _state = result.newState;
    if (result.playingDidChange) _reactives.playing.update(playing!);
    if (result.bufferingDidChange) _buffering.update(buffering!);
    if (result.completedDidChange) _completed.update(completed!);
  }

  /// Whether an `eof-reached` rising edge marks the genuine end of all
  /// playable content — the last (or only) playlist entry, with no active
  /// loop that will restart it. Used by the `eof-reached` hook to settle the
  /// transport without firing at a gapless mid-playlist boundary or on every
  /// loop wrap (either of which would flicker the play/pause button).
  bool _isEndOfContent() {
    if (_state.loop != Loop.off) return false;
    final items = _state.playlist.items;
    return items.isEmpty || _state.playlist.index >= items.length - 1;
  }

  /// Internal log helper — emits on the library-side log channel
  /// ([PlayerStream.internalLog]), kept separate from mpv's engine log
  /// stream ([PlayerStream.log]).
  void _internalLog(String message, {LogLevel level = LogLevel.info}) =>
      _internalLogCtrl.add(
        MpvLogEntry(prefix: 'mpv_audio_kit', level: level, text: message),
      );

  /// Tears down the player.
  ///
  /// The teardown order is load-bearing. The sequence is:
  ///
  /// 1. **Flip `_disposed`** so any subsequent setter / public-API call
  ///    fails fast via `_checkNotDisposed()`.
  /// 2. **Drop the [OrphanHandleTracker] entry** so a hot-restart that
  ///    fires before the destroy completes doesn't try to clean up a
  ///    handle we're already cleaning up.
  /// 3. **Send the `quit` command** to mpv. mpv processes it
  ///    asynchronously and fires `MPV_EVENT_SHUTDOWN` inside its own
  ///    event queue.
  /// 4. **`requestStop` (stop flag + `mpv_wakeup`)** so the event loop
  ///    unwinds deterministically even if `quit` was dropped or
  ///    `MPV_EVENT_SHUTDOWN` is delayed by a stalled hook.
  /// 5. **Await `_eventIsolate.stop()`**, which returns `true` only once
  ///    the isolate has ACTUALLY exited — so it is provably off
  ///    `mpv_wait_event`.
  /// 6. **`mpvTerminateDestroy(_handle)`** ONLY when `stop()` confirmed the
  ///    exit. Destroying the handle while the isolate is still inside
  ///    `mpv_wait_event` would race the event-loop thread and crash libmpv
  ///    when the handle is freed mid-syscall; on an unconfirmed exit we skip
  ///    destroy and let the OS reclaim the handle.
  /// 7. **Close all reactive properties + controllers**. Order within
  ///    this group does not matter for correctness (they tolerate
  ///    `close()` while a listener is attached); grouping by ownership
  ///    is for auditability.
  ///
  /// Idempotent AND await-safe: every call — including concurrent ones —
  /// returns the same teardown future, so a second `await dispose()`
  /// completes only when the teardown has actually finished (a bare
  /// `_disposed` early-return would let the second caller proceed while
  /// native resources are still being released).
  Future<void> dispose() => _disposeFuture ??= _disposeImpl();

  Future<void>? _disposeFuture;

  Future<void> _disposeImpl() async {
    _disposed = true;

    // Wait for init to settle. The handle / lib / native-resources
    // fields are only assigned when bring-up reaches the very end of
    // its body, so `_bringUpCompleted` is the authoritative gate for
    // touching them — even if `_ready` resolved without throwing it
    // may have early-returned because dispose flipped during init.
    try {
      await _ready;
    } catch (_) {}

    if (_bringUpCompleted) {
      _nativeResources.disposed = true;
      playerFinalizer.detach(this);
      OrphanHandleTracker.instance.remove(_handle);
      await _filterTapPipeline.dispose();
      await _waveformPipeline.dispose();
      await _spectrumPipeline.dispose();
      await _loudnessMeterPipeline.dispose();
      await _loudnessScanPipeline.dispose();
      // Cooperative quit: mpv fires MPV_EVENT_SHUTDOWN and the isolate's
      // mpv_wait_event returns. requestStop (stop flag + mpv_wakeup) unblocks
      // the loop deterministically even if `quit` was dropped or SHUTDOWN is
      // delayed by a stalled hook. mpv_terminate_destroy runs only AFTER the
      // confirmed exit below — destroying mid-syscall would crash libmpv.
      // Fire-and-forget: quit's reply may never be forwarded (the isolate is
      // about to stop) — the drain below settles the dangling future.
      unawaited(_command(['quit']));
      _eventIsolate.requestStop(_lib, _handle);
      final exited = await _eventIsolate.stop();
      // A registerHook may still be running mpv_hook_add in a throwaway
      // isolate against this handle — it MUST finish before the handle is
      // freed below. quit + the stop above have driven the core toward a
      // dispatch point, so the core-locked hook_add is granted and returns.
      // Bounded: if it doesn't settle (a pathologically stuck playloop), skip
      // the destroy and leak the handle rather than free it under the running
      // isolate (same trade-off as an unconfirmed event-isolate exit).
      var hooksSettled = true;
      if (_pendingHookAdds.isNotEmpty) {
        try {
          await Future.wait(_pendingHookAdds).timeout(const Duration(seconds: 2));
        } on TimeoutException {
          hooksSettled = false;
        } catch (_) {}
      }
      // From here no FFI may touch the handle: the drain below resumes any
      // setter suspended between writes, and mpv_terminate_destroy frees the
      // handle on the next synchronous line — the `_ffiClosed` guard in the
      // FFI primitives makes those resumed continuations no-op instead of
      // dereferencing freed memory.
      _ffiClosed = true;
      // No reply can arrive past this point; settle every in-flight call so
      // an `await player.setX(...)` racing dispose never hangs.
      _drainPendingReplies();
      if (exited && hooksSettled) {
        _lib.mpvTerminateDestroy(_handle);
      } else {
        // The worker did not confirm it left mpv_wait_event within the bound.
        // Skip mpv_terminate_destroy: freeing the handle while the isolate may
        // still be inside the syscall would SIGSEGV. The OS reclaims the handle
        // (and the leaked stop flag) at process exit.
        debugLog('mpv_audio_kit: event isolate did not confirm exit; skipping '
            'mpv_terminate_destroy to avoid a parked-handle crash.');
      }
    } else {
      // Bring-up never completed: either init failed, or this dispose
      // aborted it — in which case bring-up's early-return branch (the
      // only code that ever saw the handle) has already quit the core
      // and stopped the worker, and the `await _ready` above waited for
      // that teardown. The stop() here is a best-effort no-op backstop.
      try {
        await _eventIsolate.stop();
      } catch (_) {}
      _ffiClosed = true;
      _drainPendingReplies();
    }

    // Tear down the media-session controller before closing the
    // backing reactives — its subscriptions need live streams to
    // cancel cleanly, and its final `disable()` call to native
    // needs the controller still wired. `Player.dispose()` already
    // calls `setMediaSession(null)` (which tears the controller
    // down) before reaching here, but we double-check for safety in
    // case a future code path skips that step.
    final controller = _mediaSessionController;
    _mediaSessionController = null;
    if (controller != null) {
      try {
        await controller.dispose();
      } catch (_) {
        // Best effort — never block disposal on session teardown.
      }
    }

    // Close registry-backed reactives, then standalone ones, then
    // pure-event controllers. Order is for auditability — close() is
    // safe with attached listeners.
    await _registry.closeAll();
    await Future.wait<void>([
      _buffering.close(),
      _completed.close(),
      _playlist.close(),
      _loop.close(),
      _audioDevices.close(),
      _metadata.close(),
      _bufferingPercentage.close(),
      _demuxerCacheState.close(),
      _mediaSession.close(),
      // Standalone reactives outside the registry and the list above.
      _reactives.playWhenReady.close(),
      _reactives.audioDevice.close(),
      _reactives.audioEffects.close(),
    ]);
    // Drop the lazy spectrum bridges before closing their controllers —
    // a dispose with a live fft/pcm listener must not leave the pipeline's
    // poll loop armed against a torn-down handle.
    await _fftPipeSub?.cancel();
    _fftPipeSub = null;
    await _pcmPipeSub?.cancel();
    _pcmPipeSub = null;
    await Future.wait<void>([
      _endFileCtrl.close(),
      _errorCtrl.close(),
      _logCtrl.close(),
      _internalLogCtrl.close(),
      _hookCtrl.close(),
      _seekCompletedCtrl.close(),
      _coverArtCtrl.close(),
      _mediaSessionCommandsCtrl.close(),
      // Player-side DSP controllers: the pipelines close their own
      // internal streams, which completes the forwarding subscriptions
      // but does NOT propagate `done` to these — without an explicit
      // close, a consumer awaiting `stream.fft.first` (etc.) across a
      // dispose would hang forever.
      _fftCtrl.close(),
      _pcmStreamCtrl.close(),
      _spectrumCtrl.close(),
      _waveformCtrl.close(),
      _loudnessMeterCtrl.close(),
      _loudnessScanCtrl.close(),
    ]);
  }
}
