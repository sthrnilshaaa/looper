// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of 'player.dart';

/// The reactive properties and stream controllers behind [PlayerStream]
/// that no property spec owns: the lifecycle flags, the parsed nodes, the
/// pure events and the analysis streams. Declared, wired to their
/// pipelines, handed to [PlayerStream] and closed here, so a new stream
/// touches this class and [PlayerStream] only.
final class _StreamHub {
  _StreamHub(this._player) {
    _wireAnalysis();
  }

  final _PlayerBase _player;

  // ── Standalone reactive properties (no 1:1 mpv property backing) ───────
  // Lifecycle flags driven by file-boundary events, not by a single property.
  final ReactiveProperty<bool> buffering = ReactiveProperty<bool>(false);
  final ReactiveProperty<bool> completed = ReactiveProperty<bool>(false);
  // Derived from node properties that need access to player-side context.
  final ReactiveProperty<Playlist> playlist = ReactiveProperty<Playlist>(
    Playlist.empty,
  );
  final ReactiveProperty<Loop> loop = ReactiveProperty<Loop>(Loop.off);
  final ReactiveProperty<List<Device>> audioDevices =
      ReactiveProperty<List<Device>>(const [
        Device(name: 'auto', description: 'Auto'),
      ]);
  final ReactiveProperty<Map<String, String>> metadata =
      ReactiveProperty<Map<String, String>>(const <String, String>{});
  final ReactiveProperty<double> bufferingPercentage = ReactiveProperty<double>(
    0.0,
  );
  final ReactiveProperty<DemuxerCacheState> demuxerCacheState =
      ReactiveProperty<DemuxerCacheState>(DemuxerCacheState.empty);
  // OS media-session config + metadata override. Null = disabled.
  // Updated synchronously by [_MediaSessionModule.setMediaSession].
  final ReactiveProperty<MediaSession?> mediaSession =
      ReactiveProperty<MediaSession?>(null);

  // ── Pure event streams (no current value) ───────────────────────────────
  final StreamController<MpvFileEndedEvent> endFile =
      StreamController<MpvFileEndedEvent>.broadcast();
  final StreamController<PlayerError> errors =
      StreamController<PlayerError>.broadcast();
  // Log stream from the mpv engine itself (codec, demux, ao and so on).
  final StreamController<MpvLogEntry> log =
      StreamController<MpvLogEntry>.broadcast();
  // Log stream from the Dart layer itself: node parse warnings, hook
  // timeouts, etc. Kept disjoint from `log` so library-side noise
  // can be filtered from genuine engine messages without inspecting
  // the prefix.
  final StreamController<MpvLogEntry> internalLog =
      StreamController<MpvLogEntry>.broadcast();
  final StreamController<MpvHookEvent> hook =
      StreamController<MpvHookEvent>.broadcast();
  final StreamController<void> seekCompleted =
      StreamController<void>.broadcast();
  // Nullable payload: each file-loaded transition emits exactly once,
  // with `null` when the new file has no embedded cover. This lets a
  // UI clear or reset on every track change without having to compare
  // against a separate file-transition signal.
  final StreamController<CoverArt?> coverArt =
      StreamController<CoverArt?>.broadcast();
  // Incoming commands from the OS media session (lockscreen, BT
  // headset, Siri, Assistant), routed back from the per-platform
  // native implementation.
  final StreamController<MediaSessionCommand> mediaSessionCommands =
      StreamController<MediaSessionCommand>.broadcast();

  late final StreamController<FftFrame> fft;
  late final StreamController<PcmFrame> pcm;
  // Lazy bridges into the spectrum pipeline: non-null exactly while the
  // matching public stream has a listener (they keep the pipeline's
  // listener-gated poll loop armed; see the controllers' onListen).
  StreamSubscription<FftFrame>? _fftPipeSub;
  StreamSubscription<PcmFrame>? _pcmPipeSub;
  late final StreamController<WaveformData?> waveform;
  // The last envelope and scan result, replayed to a new subscriber of
  // `stream.waveform` and `stream.loudnessScan`.
  WaveformData? lastWaveform;
  LoudnessScan? lastLoudnessScan;
  late final StreamController<Loudness> loudnessMeter;
  late final StreamController<LoudnessScan?> loudnessScan;

  /// The controllers of the analysis streams (fft, pcm, waveform, loudness
  /// meter and scan), whose listeners arm the pipelines built at bring-up.
  void _wireAnalysis() {
    // The fft and pcm bridges into the spectrum pipeline are listener-gated:
    // the pipeline arms its 30fps `pcm-tap-frame` poll as soon as its own
    // streams have a listener, so bridging unconditionally would keep the
    // poll running for the player's whole lifetime with zero consumers.
    // Subscribers that land before bring-up are reconciled once the
    // pipeline exists (see `_bringUp`).
    fft = StreamController<FftFrame>.broadcast(
      onListen: () {
        if (_player._bringUpCompleted) {
          _fftPipeSub ??= _player._spectrumPipeline.fftStream.listen(fft.add);
        }
      },
      onCancel: () {
        final sub = _fftPipeSub;
        _fftPipeSub = null;
        if (sub != null) unawaited(sub.cancel());
      },
    );
    pcm = StreamController<PcmFrame>.broadcast(
      onListen: () {
        if (_player._bringUpCompleted) {
          _pcmPipeSub ??= _player._spectrumPipeline.pcmStream.listen(pcm.add);
        }
      },
      onCancel: () {
        final sub = _pcmPipeSub;
        _pcmPipeSub = null;
        if (sub != null) unawaited(sub.cancel());
      },
    );
    // Listener-gated: the native waveform analyzer arms only while a
    // consumer is subscribed. The pipeline is built during bring-up; a
    // subscriber that lands before then is reconciled once bring-up
    // finishes (see `_bringUp`).
    waveform = StreamController<WaveformData?>.broadcast(
      onListen: () {
        if (_player._bringUpCompleted) {
          _player._waveformPipeline.setEnabled(true);
        }
      },
      onCancel: () {
        if (!_player._bringUpCompleted) return;
        _player._waveformPipeline.setEnabled(false);
      },
    );
    // Same listener-gating as the waveform: the af-metadata poll runs
    // only while someone is subscribed to `stream.loudnessMeter`.
    loudnessMeter = StreamController<Loudness>.broadcast(
      onListen: () {
        if (_player._bringUpCompleted) {
          _player._loudnessMeterPipeline.setEnabled(true);
        }
      },
      onCancel: () {
        if (_player._bringUpCompleted) {
          _player._loudnessMeterPipeline.setEnabled(false);
        }
      },
    );
    // Listener-gated like the waveform: the native whole-file scan runs
    // only while someone is subscribed to `stream.loudnessScan`.
    loudnessScan = StreamController<LoudnessScan?>.broadcast(
      onListen: () {
        if (_player._bringUpCompleted) {
          _player._loudnessScanPipeline.setEnabled(true);
        }
      },
      onCancel: () {
        if (_player._bringUpCompleted) {
          _player._loudnessScanPipeline.setEnabled(false);
        }
      },
    );
  }

  /// The [PlayerStream] of the player, over these and the cells of the
  /// registry.
  PlayerStream build() => PlayerStream.fromInternals(
    reactives: _player._reactives,
    buffering: buffering,
    completed: completed,
    playlist: playlist,
    loop: loop,
    audioDevices: audioDevices,
    metadata: metadata,
    bufferingPercentage: bufferingPercentage,
    demuxerCacheState: demuxerCacheState,
    audioEffects: _player._reactives.audioEffects,
    mediaSession: mediaSession,
    endFile: endFile.stream,
    error: errors.stream,
    log: log.stream,
    internalLog: internalLog.stream,
    hook: hook.stream,
    seekCompleted: seekCompleted.stream,
    coverArt: replayStream(() => _player._state.file.coverArt, coverArt.stream),
    fft: fft.stream,
    pcm: pcm.stream,
    spectrum: _player._reactives.spectrum.stream,
    waveform: replayStream(() => lastWaveform, waveform.stream),
    loudnessMeter: loudnessMeter.stream,
    loudnessScan: replayStream(() => lastLoudnessScan, loudnessScan.stream),
    tap: (filter, {instance = 0, required side}) => switch (side) {
      TapSide.pre => _player._filterTapPipeline.tapPre(
        audioEffectLabel(filter.filterName, instance),
      ),
      TapSide.post => _player._filterTapPipeline.tapPost(
        audioEffectLabel(filter.filterName, instance),
      ),
    },
    mediaSessionCommands: mediaSessionCommands.stream,
  );

  /// Bring-up finished: a DSP subscriber that landed before it missed the
  /// `onListen` enable.
  void reconcile() {
    if (fft.hasListener) {
      _fftPipeSub ??= _player._spectrumPipeline.fftStream.listen(fft.add);
    }
    if (pcm.hasListener) {
      _pcmPipeSub ??= _player._spectrumPipeline.pcmStream.listen(pcm.add);
    }
    if (waveform.hasListener) _player._waveformPipeline.setEnabled(true);
    if (loudnessMeter.hasListener) {
      _player._loudnessMeterPipeline.setEnabled(true);
    }
    if (loudnessScan.hasListener) {
      _player._loudnessScanPipeline.setEnabled(true);
    }
  }

  /// The last step of the teardown: closes every reactive and controller
  /// here, so each of their streams ends. None is awaited: a listener the
  /// app keeps paused takes the done only when it resumes, so waiting
  /// would hold dispose forever. An active listener gets it right after.
  Future<void> closeAll() async {
    unawaited(
      Future.wait<void>([
        buffering.close(),
        completed.close(),
        playlist.close(),
        loop.close(),
        audioDevices.close(),
        metadata.close(),
        bufferingPercentage.close(),
        demuxerCacheState.close(),
        mediaSession.close(),
      ]),
    );
    // Drop the lazy spectrum bridges before closing their controllers:
    // a dispose with a live fft or pcm listener must not leave the pipeline's
    // poll loop armed against a torn-down handle.
    await _fftPipeSub?.cancel();
    _fftPipeSub = null;
    await _pcmPipeSub?.cancel();
    _pcmPipeSub = null;
    unawaited(
      Future.wait<void>([
        endFile.close(),
        errors.close(),
        log.close(),
        internalLog.close(),
        hook.close(),
        seekCompleted.close(),
        coverArt.close(),
        mediaSessionCommands.close(),
        // Player-side DSP controllers: the pipelines close their own
        // internal streams, which completes the forwarding subscriptions
        // but does NOT propagate `done` to these: without an explicit
        // close, a consumer awaiting `stream.fft.first` (etc.) across a
        // dispose would hang forever.
        fft.close(),
        pcm.close(),
        waveform.close(),
        loudnessMeter.close(),
        loudnessScan.close(),
      ]),
    );
  }
}
