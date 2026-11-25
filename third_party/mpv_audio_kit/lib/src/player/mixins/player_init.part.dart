// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of '../player.dart';

/// Cold-start bring-up: hands the init recipe to the session, which starts
/// the core and its event pump, then wires the calls, DSP pipelines, orphan
/// tracking and TLS bundle. Also owns the pre-/post-init option recipes and
/// the `mpv_observe_property` spec list. `_start` is what the constructors
/// of [Player] call; the rest are internal to this mixin.
mixin _InitModule on _PlayerBase, _DispatchModule, _TeardownModule {
  /// Builds the recipe and hands it to the session, which starts the core
  /// off the UI thread's way. Called by the constructors of [Player], once
  /// the base set up the registry and the streams. A failed init reaches
  /// every call that awaits [_ready]; a player nobody uses yet must not
  /// report it as an unhandled error.
  void _start() => _ready = _bringUp()..ignore();

  Future<void> _bringUp() async {
    final recipe = CoreRecipe(
      preInitOptions: _buildPreInitOptions(),
      postInitOptions: _buildPostInitOptions(),
      observes: _buildObserveSpecs(),
      logLevel: configuration.logLevel == LogLevel.off
          ? null
          : configuration.logLevel.mpvValue,
    );

    await _session.start(recipe, _handleEvent);

    if (_disposed) {
      // dispose() landed while the core was initializing. dispose()
      // found `_bringUpCompleted == false` and has no core to tear
      // down: this is the only code that ever sees it, so the teardown
      // duty lands here: unwind the event pump deterministically (stop
      // flag + wakeup), then destroy the core only on confirmed exit (same
      // rule as dispose: destroying mid-`mpv_wait_event` SIGSEGVs).
      // dispose() awaits `_ready`, i.e. this very teardown, before
      // proceeding, so it cannot observe a half-released core.
      _session.requestStop();
      if (await _session.stop()) {
        await _session.terminateDestroy();
      } else {
        unawaited(_destroyOnceStopped());
      }
      return;
    }

    _calls = CoreCalls(_session);
    // Every DSP pipeline polls mpv through the async-get path (decoded by
    // the event pump, reply-correlated) rather than a blocking read,
    // so a visualizer's poll loop can never stall the main isolate while the
    // core is busy initializing an audio output. [CoreCalls.get] and
    // [CoreCalls.propRc] are the same async calls the typed setters use.
    _spectrumPipeline = SpectrumPipeline(asyncGet: _calls.get);
    // fft and pcm are NOT bridged here: the pipeline's poll loop arms on its
    // streams' first listener, so the bridges are created lazily by the
    // public controllers' onListen (and reconciled below for subscribers
    // that landed before bring-up). The settings live in the state, where
    // setSpectrum may have put them before bring-up.
    _spectrumPipeline.setSettings(_state.settings.spectrum);
    _waveformPipeline = WaveformPipeline(
      asyncGet: _calls.get,
      asyncSet: _calls.propRc,
    );
    _filterTapPipeline = FilterTapPipeline(
      asyncGet: _calls.get,
      asyncSet: _calls.propRc,
      warn: (message) => _internalLog(message, level: LogLevel.warn),
    );
    _loudnessMeterPipeline = LoudnessMeterPipeline(
      asyncGet: _calls.get,
      label: () => _meterLabel(_state.settings.audioEffects),
    );
    _loudnessScanPipeline = LoudnessScanPipeline(
      asyncGet: _calls.get,
      asyncSet: _calls.propRc,
    );
    // No file is loaded yet, and the analysis is one per process: what mpv
    // holds now is another player's. Both poll from the reset of the first
    // FILE_LOADED on. Before the listens below, so the null of the clear
    // reaches no one.
    _waveformPipeline.clear();
    _loudnessScanPipeline.clear();
    _waveformPipeline.stream.listen((w) {
      _streams.lastWaveform = w;
      _streams.waveform.add(w);
    });
    _loudnessMeterPipeline.stream.listen(_streams.loudnessMeter.add);
    // Paused, stopped or parked at the end, the output writes nothing: the
    // spectrum and tap polls rest until the core plays again.
    void idle(bool playing) {
      _spectrumPipeline.setIdle(!playing);
      _filterTapPipeline.setIdle(!playing);
    }

    idle(_state.playback.playing);
    _reactives.playing.changes.listen(idle);
    _loudnessScanPipeline.stream.listen((s) {
      _streams.lastLoudnessScan = s;
      _streams.loudnessScan.add(s);
    });

    _session.track();

    _bringUpCompleted = true;

    // A setLogLevel call that came before bring-up finished.
    final pendingLevel = _pendingLogLevel;
    if (pendingLevel != null) _calls.requestLogMessages(pendingLevel);

    // A DSP subscriber that landed before bring-up finished missed the
    // `onListen` enable: reconcile it now.
    _streams.reconcile();
  }

  /// Recipe of pre-init `mpv_set_option_string` calls executed by the
  /// session before `mpv_initialize`.
  Map<String, String> _buildPreInitOptions() => {
    'vid': 'no',
    'sid': 'no',
    'vo': 'null',
    // Watch-later and resume. Persist only the audio-relevant props (mpv's
    // default list includes video and sub keys this build can't restore).
    // Not `af`: the effects chain is the player's state, and a chain mpv
    // restored on its own would play without the state knowing.
    'resume-playback': configuration.resumePlayback ? 'yes' : 'no',
    'watch-later-options': 'start,speed,pitch,volume,mute,audio-delay,aid',
    // A-B points belong to the file they were set on: mpv puts back, at
    // the end of each file, the value they had when it started.
    'reset-on-next-file': 'ab-loop-a,ab-loop-b',
    if (configuration.watchLaterDir != null)
      'watch-later-dir': configuration.watchLaterDir!,
    if (configuration.forceSeekable) 'force-seekable': 'yes',
    'hls-bitrate': configuration.hlsBitrate.mpvValue,
    if (configuration.normalizeDownmix) 'audio-normalize-downmix': 'yes',
    if (configuration.demuxerCacheDir != null)
      'demuxer-cache-dir': configuration.demuxerCacheDir!,
    // If the audio device can't be opened (Bluetooth or AirPlay sink gone,
    // a stale device id, an exclusive mode refused), fall back to the null
    // AO and keep the position clock running instead of hard-failing
    // playback. `audio-output-state` then says active, so the player reports
    // the silent fallback on the error stream itself (once per opening).
    'audio-fallback-to-null': 'yes',
    'audio-display': 'embedded-first',
    'cover-art-auto': 'no',
    'image-display-duration': 'inf',
    'keep-open': 'yes',
    'idle': 'yes',
    'osc': 'no',
    'ytdl': 'no',
    'load-stats-overlay': 'no',
    'load-console': 'no',
    'load-commands': 'no',
    'load-auto-profiles': 'no',
    'load-select': 'no',
    'load-context-menu': 'no',
    'load-positioning': 'no',
    'load-scripts': 'no',
    'input-builtin-bindings': 'no',
    'audio-client-name': 'mpv_audio_kit',
    // On by default, as in mpv 0.42 and FFmpeg 9 (0.7 kept it off).
    'tls-verify': configuration.tlsVerify ? 'yes' : 'no',
    'stream-lavf-o': _kStreamLavfDefaults,
  };

  Map<String, String> _buildPostInitOptions() => {
    'volume': canonicalFloat(configuration.initialVolume).toString(),
  };

  /// Specs for `mpv_observe_property`: registry props plus the small
  /// out-of-registry set kept here for cross-reference clarity.
  List<MpvObserveSpec> _buildObserveSpecs() {
    final specs = <MpvObserveSpec>[];
    var replyId = 1;
    for (final spec in _registry.specs) {
      specs.add(MpvObserveSpec(spec.name, spec.format, replyId++));
    }
    // Out-of-registry observers. NODE for structured data; STRING for
    // `loop-*` and `audio-device` (cross-referenced from
    // `audio-device-list`).
    final extras = <(String, int)>[
      ('playlist', MpvFormat.mpvFormatNode),
      ('audio-device-list', MpvFormat.mpvFormatNode),
      ('audio-device', MpvFormat.mpvFormatString),
      ('metadata', MpvFormat.mpvFormatNode),
      ('demuxer-cache-state', MpvFormat.mpvFormatNode),
      ('loop-file', MpvFormat.mpvFormatString),
      ('loop-playlist', MpvFormat.mpvFormatString),
    ];
    var extraReplyId = PropertyRegistry.registryReplyIdMax + 1;
    for (final (name, format) in extras) {
      specs.add(MpvObserveSpec(name, format, extraReplyId++));
    }
    return specs;
  }
}

/// mpv's global `stream-lavf-o`, the options of every stream FFmpeg opens,
/// so a dropped connection does not end a track early (verified against
/// FFmpeg 9.0.2 and mpv 0.42.0). A protocol takes the ones it knows and
/// leaves the others, as `smb2` already does with mpv's own `reconnect`:
/// mpv lists the leftovers at verbose level only (stream_lavf.c). An entry
/// with `Media.streamLavfOptions` or `Media.httpChunkSize` adds to them
/// (`stream-lavf-o-add`); the app's own global value replaces them.
/// - `reconnect` and `reconnect_delay_max` are mpv's own values for a
///   progressive stream (stream_lavf.c), which it does not pass to the
///   segments of an HLS or DASH stream. Through `stream-lavf-o` they reach
///   them: demux_lavf.c hands the network options to every nested open.
///   FFmpeg then requests a body cut short again from where it stopped, on
///   a server that accepts ranges (http.c, http_read_stream), after 0, 1,
///   3 and 7 s.
/// - `reconnect_on_network_error` tries a connection that fails to open
///   (refused, reset, DNS, TLS) again on the same schedule (http.c,
///   http_open_cnx), for the open and for each of those reconnects.
/// - `seg_max_retry` is an option of the HLS demuxer, which takes the
///   network options as its own (demux_lavf.c sets them on a demuxer that
///   opens its URL itself). With FFmpeg's 0 a segment that fails to open
///   is skipped at once (hls.c, read_data_continuous). 4 gives it as many
///   retries as a progressive stream gets reconnects. In `demuxer-lavf-o`
///   it would rebuild the demuxer of every entry that sets it, and drop
///   its prefetch.
/// `reconnect_streamed` is not among them: on a server without range
/// support FFmpeg reconnects from the first byte, so a file cut short
/// plays again from its start, and one sent with no length plays over and
/// over. A live stream asks for it with `Media.streamLavfOptions`.
const String _kStreamLavfDefaults =
    'reconnect=1,reconnect_delay_max=7,'
    'reconnect_on_network_error=1,seg_max_retry=4';
