// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../models/pcm_frame.dart';
import '../mpv_constants.dart';
import 'dsp_async_io.dart';
import 'poll_loop.dart';
import 'shared_property_writer.dart';

/// Upper bound on the channel count reported by the native filter tap.
///
/// The native side clamps to this before writing the ring, so a well-formed
/// frame is always within bound. This mirror is a defensive guard: if the two
/// sides ever drift, a desynced `channels` value can't build a bogus
/// `PcmFrame` downstream.
const int _kMaxTapChannels = 8;

/// How many chain labels the native tap captures at once
/// (`MAX_TAPS` in the libmpv patch); the labels after these stay silent.
const int _kMaxActiveTaps = 8;

/// Per-filter pre and post audio tap pipeline.
///
/// Backed by the `audio-tap-frames` and `analyzer-taps` properties
/// added by the libmpv filter-label-tap patch. The pipeline:
///
///   1. tracks which `(label, side)` pairs have a listener and writes a
///      comma-separated list of the chain labels currently needed to
///      `analyzer-taps`. The C side activates the matching hook in
///      `user_wrapper_process` only for those labels, at most
///      [_kMaxActiveTaps] of them. The list is one per process, so it
///      holds the labels of every player of this isolate.
///   2. polls `audio-tap-frames` every 33 ms while at least one
///      stream has a listener; parses the MAP_NODE into
///      per-stage [PcmFrame]s and dispatches them on broadcast
///      controllers keyed by `(label, side)`.
///
/// Idle cost is exactly zero: the polling timer is unarmed and the
/// active-list is empty until the first listener attaches. While the core
/// is idle ([setIdle]) the timer is unarmed too: a new listener still gets
/// one read, the slice held now.
@internal
class FilterTapPipeline {
  FilterTapPipeline({
    required AsyncPropertyGet asyncGet,
    required AsyncPropertySet asyncSet,
    void Function(String message)? warn,
    // 33 ms ≈ 30 Hz: matches the lib's spectrum pipeline default.
    // The C side now returns the slice of the rolling ring aligned
    // to the AO playback PTS, so the slice walks forward smoothly
    // at the audio output rate regardless of the chain's bursty
    // write cadence. 30 Hz reads are enough; the slice content
    // changes every poll because `playing_audio_pts` is monotonic.
    Duration pollInterval = const Duration(milliseconds: 33),
  }) : _asyncGet = asyncGet,
       _asyncSet = asyncSet,
       _warn = warn,
       _pollInterval = pollInterval;

  final AsyncPropertyGet _asyncGet;
  final AsyncPropertySet _asyncSet;
  final void Function(String message)? _warn;
  final Duration _pollInterval;

  // (name, side) → broadcast controller. Lazy-created on first
  // listener; deactivated when the last subscriber cancels.
  final Map<_TapKey, StreamController<PcmFrame>> _controllers = {};
  // The (name, side) pairs with a listener: drives the analyzer-taps CSV.
  // A broadcast controller calls onListen and onCancel only for its first
  // and last listener, so membership is all there is to count.
  final Set<_TapKey> _active = {};
  // The labels this pipeline adds to [_tapped].
  final Set<String> _labels = {};

  // analyzer-taps is a static of the libmpv process, and a write replaces
  // the whole list: every player of this isolate writes the labels of all.
  // Each label counts the pipelines that tap it, in the order it was first
  // tapped, so a new label never pushes out one already captured (the C
  // side keeps the first [_kMaxActiveTaps]).
  static final Map<String, int> _tapped = {};
  // The list last written, empty as mpv starts. `null` once a write
  // failed: what the process holds is not known, and the next list is
  // written whatever it is.
  static String? _written = '';
  static final SharedPropertyWriter _writer = SharedPropertyWriter(
    'analyzer-taps',
  );
  // The slice last dispatched per (name, side): the ring's write
  // generation (`seq`) and the slice's end (`pts_ns`). Lets the poll loop
  // skip a redundant decode + add() when neither moved (e.g. while paused
  // or at EOF the writer isn't advancing it and the position stands).
  final Map<_TapKey, ({int seq, int ptsNs})> _lastSlice = {};

  late final PollLoop _loop = PollLoop(_poll, _doPoll);
  bool _disposed = false;
  bool _idle = false;

  /// Returns a broadcast stream of PCM frames captured **before** the
  /// chain stage labelled [label] (e.g. `aek_equalizer_1`, see
  /// `audioEffectLabel`). The native tap matches stages by chain label,
  /// so each instance of a repeated filter has its own. The first
  /// listener arms the tap; the last cancel disarms it. Live streams:
  /// the stream may emit no frames until audio actually flows through
  /// the chain.
  Stream<PcmFrame> tapPre(String label) => _streamFor(label, false);

  /// Same as [tapPre] but captures the frame **after** the stage
  /// labelled [label] has processed it.
  Stream<PcmFrame> tapPost(String label) => _streamFor(label, true);

  Stream<PcmFrame> _streamFor(String name, bool isPost) {
    if (_disposed) {
      return const Stream<PcmFrame>.empty();
    }
    final key = (name: name, isPost: isPost);
    return _controllers.putIfAbsent(key, () {
      late StreamController<PcmFrame> ctrl;
      ctrl = StreamController<PcmFrame>.broadcast(
        onListen: () => _onListen(key),
        onCancel: () {
          if (!ctrl.hasListener) _onCancelLast(key);
        },
      );
      return ctrl;
    }).stream;
  }

  /// Stops the poll loop while the core is idle (mpv's `core-idle`) and
  /// starts it again when it plays: idle, the ring and the playback
  /// position stand still and every read returns the slices already sent.
  void setIdle(bool idle) {
    if (_disposed || idle == _idle) return;
    _idle = idle;
    if (idle) {
      _loop.disarm();
    } else if (_active.isNotEmpty) {
      _loop.arm(_pollInterval);
    }
  }

  void _onListen(_TapKey key) {
    if (_disposed) return;
    if (_active.add(key)) _writeActiveList();
    if (_idle) {
      _poll();
    } else if (!_loop.isArmed) {
      _loop.arm(_pollInterval);
      _poll();
    }
  }

  void _onCancelLast(_TapKey key) {
    if (_disposed) return;
    _active.remove(key);
    // Drop the retained slice. The native ring `seq` is monotonic and never
    // reset, so keeping a stale one would make a FRESH re-subscriber to this
    // tap, paused or at EOF, skip the currently-buffered slice (its seq and
    // pts still equal the retained ones) until the next write.
    _lastSlice.remove(key);
    _writeActiveList();
    if (_active.isEmpty) _loop.disarm();
  }

  /// Builds the `analyzer-taps` CSV from the union of every distinct
  /// chain label with a pre or post listener, in this pipeline and in the
  /// other players' of this isolate, and pushes it to mpv. The C side
  /// replaces its active set on every write; an empty CSV disables every
  /// tap.
  void _writeActiveList() {
    final labels = {for (final k in _active) k.name};
    for (final label in _labels.difference(labels)) {
      _untap(label);
    }
    for (final label in labels.difference(_labels)) {
      _tapped.update(label, (n) => n + 1, ifAbsent: () => 1);
    }
    _labels
      ..clear()
      ..addAll(labels);
    if (_tapped.length > _kMaxActiveTaps) {
      _warn?.call(
        '${_tapped.length} stages are tapped; libmpv captures '
        '$_kMaxActiveTaps at a time, so the others stay silent.',
      );
    }
    _publish();
  }

  static void _untap(String label) {
    final n = _tapped[label]! - 1;
    if (n == 0) {
      _tapped.remove(label);
    } else {
      _tapped[label] = n;
    }
  }

  /// Writes the labels of every player, unless mpv has them already (the
  /// other side of a tapped label leaves the list as it is).
  ///
  /// The list counts as written while its write is in flight, so the same
  /// list is not sent twice. A write that fails (mpv refused it, or the
  /// core closed on it) leaves the process with a list from before.
  void _publish() => _writer.write(
    _asyncSet,
    () {
      final csv = _tapped.keys.join(',');
      if (csv == _written) return null;
      _written = csv;
      return csv;
    },
    anyCore: true,
    onFailed: (csv) {
      if (_written == csv) _written = null;
    },
  );

  void _poll() {
    if (_disposed) return;
    if (_active.isEmpty) return;
    _loop.run();
  }

  Future<void> _doPoll() async {
    final (rc, value) = await _asyncGet(
      'audio-tap-frames',
      MpvFormat.mpvFormatNode,
    );
    if (_disposed) return;
    if (rc < 0 || value is! Map) return;
    _parseRoot(value);
  }

  void _parseRoot(Map<dynamic, dynamic> root) {
    // root: { label: { pre: <ring>, post: <ring> } }
    root.forEach((filterKey, entry) {
      if (filterKey is! String || entry is! Map) return;
      entry.forEach((sideKey, ring) {
        if (ring is! Map) return;
        final isPost = sideKey == 'post';
        // The root keys are the chain labels (`u->label`), the same keys
        // `_streamFor` gives `_controllers`.
        final key = (name: filterKey, isPost: isPost);
        // A controller of [_controllers], closed by [dispose].
        // ignore: close_sinks
        final ctrl = _controllers[key];
        if (ctrl == null || !ctrl.hasListener) return;
        // Skip the decode + dispatch when the slice is the one dispatched
        // last. The C side bumps the ring `seq` on every write, once per
        // decoded frame (about 104 ms with a FLAC), and returns the slice
        // that ends at the playback position: between two writes the same
        // seq comes with a later `pts_ns`, a new slice. Paused or at EOF
        // both stand still, and re-emitting the slice would only churn a
        // Float32List + StreamController.add() for no new data.
        // seq == 0 means "unavailable"; fall back to always emitting.
        final seq = ring['seq'] is int ? ring['seq'] as int : 0;
        final ptsNs = ring['pts_ns'] is int ? ring['pts_ns'] as int : 0;
        final slice = (seq: seq, ptsNs: ptsNs);
        if (seq != 0 && _lastSlice[key] == slice) return;
        _lastSlice[key] = slice;
        final frame = _decodeRing(ring);
        if (frame == null) return;
        if (!ctrl.isClosed) ctrl.add(frame);
      });
    });
  }

  PcmFrame? _decodeRing(Map<dynamic, dynamic> ring) {
    final sampleRate = ring['sample_rate'] is int
        ? ring['sample_rate'] as int
        : 0;
    final channels = ring['channels'] is int ? ring['channels'] as int : 0;
    final ptsNs = ring['pts_ns'] is int ? ring['pts_ns'] as int : 0;
    final samples = float32FromByteValue(ring['samples']);
    if (samples == null ||
        sampleRate <= 0 ||
        channels <= 0 ||
        channels > _kMaxTapChannels ||
        ptsNs == 0) {
      return null;
    }
    return PcmFrame(
      samples: samples,
      timestamp: Duration(microseconds: ptsNs ~/ 1000),
      sampleRate: sampleRate,
      channels: channels,
    );
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _loop.disarm();
    // This player's labels leave the list, the other players' stay. The
    // player disposes the taps after its quit: the core still serves this
    // write before it is destroyed.
    _labels.forEach(_untap);
    _labels.clear();
    _publish();
    // Not awaited: the controllers are the app's own subscriptions, and a
    // paused one takes the done only when it resumes, so waiting would
    // hold the player's dispose forever. An active one gets it right after.
    for (final c in _controllers.values) {
      if (!c.isClosed) unawaited(c.close());
    }
    _controllers.clear();
    _active.clear();
    _lastSlice.clear();
  }
}

typedef _TapKey = ({String name, bool isPost});
