// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../models/pcm_frame.dart';
import '../mpv_bindings.dart';
import 'dsp_async_io.dart';

/// Upper bound on the channel count reported by the native filter tap.
///
/// The native side clamps to this before writing the ring, so a well-formed
/// frame is always within bound. This mirror is a defensive guard: if the two
/// sides ever drift, a desynced `channels` value can't build a bogus
/// `PcmFrame` downstream.
const int _kMaxTapChannels = 8;

/// Per-filter pre/post audio tap pipeline.
///
/// Backed by the `audio-tap-frames` and `analyzer-taps` properties
/// added by the libmpv filter-label-tap patch. The pipeline:
///
///   1. tracks per-`(name, side)` subscriber counts and writes a
///      comma-separated list of currently-needed filter names to
///      `analyzer-taps`. The C side activates the matching hook in
///      `user_wrapper_process` only for those names.
///   2. polls `audio-tap-frames` at a configurable cadence while at
///      least one stream has a listener; parses the MAP_NODE into
///      per-filter [PcmFrame]s and dispatches them on broadcast
///      controllers keyed by `(name, side)`.
///
/// Idle cost is exactly zero — the polling timer is unarmed and the
/// active-list is empty until the first listener attaches.
@internal
class FilterTapPipeline {
  FilterTapPipeline({
    required AsyncPropertyGet asyncGet,
    required AsyncPropertySet asyncSet,
    // 33 ms ≈ 30 Hz — matches the lib's spectrum pipeline default.
    // The C side now returns the slice of the rolling ring aligned
    // to the AO playback PTS, so the slice walks forward smoothly
    // at the audio output rate regardless of the chain's bursty
    // write cadence. 30 Hz reads are enough; the slice content
    // changes every poll because `playing_audio_pts` is monotonic.
    Duration pollInterval = const Duration(milliseconds: 33),
  })  : _asyncGet = asyncGet,
        _asyncSet = asyncSet,
        _pollInterval = pollInterval;

  final AsyncPropertyGet _asyncGet;
  final AsyncPropertySet _asyncSet;
  final Duration _pollInterval;

  // (name, side) → broadcast controller. Lazy-created on first
  // listener; deactivated when the last subscriber cancels.
  final Map<_TapKey, StreamController<PcmFrame>> _controllers = {};
  // Refcount per (name, side) — drives the analyzer-taps CSV.
  final Map<_TapKey, int> _refs = {};
  // Last native write generation (ring `seq`) dispatched per (name, side).
  // Lets the poll loop skip a redundant decode + add() when the ring is
  // unchanged (e.g. while paused / at EOF the writer isn't advancing it).
  final Map<_TapKey, int> _lastSeq = {};

  Timer? _pollTimer;
  // Guards against overlapping async polls — see [LoudnessMeterPipeline].
  bool _polling = false;
  bool _disposed = false;

  /// Returns a broadcast stream of PCM frames captured **before**
  /// [filterName] is applied. The first listener arms the tap; the
  /// last cancel disarms it. Live streams: the stream may emit no
  /// frames until audio actually flows through the chain.
  Stream<PcmFrame> tapPre(String filterName) =>
      _streamFor(_mpvName(filterName), false);

  /// Same as [tapPre] but captures the frame **after** [filterName]
  /// has processed it.
  Stream<PcmFrame> tapPost(String filterName) =>
      _streamFor(_mpvName(filterName), true);

  /// mpv exposes every libavfilter filter under the `lavfi-` prefix
  /// inside the user-filter chain — `u->name` for `equalizer` reads
  /// as `"lavfi-equalizer"`. The pipeline keeps the prefix in every
  /// internal map / CSV write so `find_slot()` on the C side matches.
  /// The public API hides it.
  static String _mpvName(String publicName) => 'lavfi-$publicName';

  Stream<PcmFrame> _streamFor(String name, bool isPost) {
    if (_disposed) {
      return const Stream<PcmFrame>.empty();
    }
    final key = (name: name, isPost: isPost);
    return _controllers
        .putIfAbsent(key, () {
          late StreamController<PcmFrame> ctrl;
          ctrl = StreamController<PcmFrame>.broadcast(
            onListen: () => _onListen(key),
            onCancel: () {
              if (!ctrl.hasListener) _onCancelLast(key);
            },
          );
          return ctrl;
        })
        .stream;
  }

  void _onListen(_TapKey key) {
    if (_disposed) return;
    final next = (_refs[key] ?? 0) + 1;
    _refs[key] = next;
    if (next == 1) _writeActiveList();
    if (_pollTimer == null) {
      _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
      _poll();
    }
  }

  void _onCancelLast(_TapKey key) {
    if (_disposed) return;
    final cur = _refs[key] ?? 0;
    if (cur <= 1) {
      _refs.remove(key);
      // Drop the retained native write-generation. The native ring `seq` is
      // monotonic and never reset, so keeping a stale `_lastSeq` would make a
      // FRESH re-subscriber to this paused/EOF tap skip the currently-buffered
      // slice (its seq still equals the retained value) until the next write.
      _lastSeq.remove(key);
    } else {
      _refs[key] = cur - 1;
    }
    if (_refs.isEmpty) {
      _writeActiveList();
      _pollTimer?.cancel();
      _pollTimer = null;
    } else {
      _writeActiveList();
    }
  }

  /// Builds the `analyzer-taps` CSV from the union of every distinct
  /// filter name with at least one (pre or post) refcount > 0, and
  /// pushes it to mpv. The C side replaces its active set on every
  /// write; an empty CSV disables every tap.
  void _writeActiveList() {
    final names = <String>{};
    for (final k in _refs.keys) {
      names.add(k.name);
    }
    unawaited(_asyncSet('analyzer-taps', names.join(',')));
  }

  void _poll() {
    if (_disposed || _polling) return;
    if (_refs.isEmpty) return;
    _polling = true;
    unawaited(_doPoll().whenComplete(() => _polling = false));
  }

  Future<void> _doPoll() async {
    final (rc, value) =
        await _asyncGet('audio-tap-frames', MpvFormat.mpvFormatNode);
    if (_disposed) return;
    if (rc < 0 || value is! Map) return;
    _parseRoot(value);
  }

  void _parseRoot(Map<dynamic, dynamic> root) {
    // root: { filterName: { pre: <ring>, post: <ring> } }
    root.forEach((filterKey, entry) {
      if (filterKey is! String || entry is! Map) return;
      entry.forEach((sideKey, ring) {
        if (ring is! Map) return;
        final isPost = sideKey == 'post';
        // The root keys already carry the `lavfi-` prefix the C side emits
        // (`u->name`), matching how `_streamFor` keys `_controllers`.
        final key = (name: filterKey, isPost: isPost);
        final ctrl = _controllers[key];
        if (ctrl == null || !ctrl.hasListener) return;
        // Skip the decode + dispatch when the native write generation is
        // unchanged since the last poll. The C side bumps the ring `seq`
        // on every write and holds it stable while paused / at EOF, so an
        // unchanged seq means an identical slice — re-emitting it only
        // churns a Float32List + StreamController.add() for no new data.
        // seq == 0 means "unavailable"; fall back to always emitting.
        final seq = ring['seq'] is int ? ring['seq'] as int : 0;
        if (seq != 0 && _lastSeq[key] == seq) return;
        _lastSeq[key] = seq;
        final frame = _decodeRing(ring);
        if (frame == null) return;
        if (!ctrl.isClosed) ctrl.add(frame);
      });
    });
  }

  PcmFrame? _decodeRing(Map<dynamic, dynamic> ring) {
    final sampleRate =
        ring['sample_rate'] is int ? ring['sample_rate'] as int : 0;
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
    _pollTimer?.cancel();
    _pollTimer = null;
    // Best-effort: clear analyzer-taps so the C side stops capturing.
    unawaited(_asyncSet('analyzer-taps', ''));
    final closes = <Future<void>>[];
    for (final c in _controllers.values) {
      if (!c.isClosed) closes.add(c.close());
    }
    _controllers.clear();
    _refs.clear();
    _lastSeq.clear();
    await Future.wait(closes);
  }
}

typedef _TapKey = ({String name, bool isPost});
