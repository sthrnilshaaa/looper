// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of 'pcm_source.dart';

// The sources not yet released, by id, for the player that loads their
// media.

// A source the app dropped: the native side lets go, and its media is
// refused from then on.
final Finalizer<_NativeRef> _finalizer = Finalizer<_NativeRef>((ref) {
  ref.native.release(ref.id);
  _forget(ref.id);
});

void _forget(int id) {
  _formats.remove(id);
  _lowLatency.remove(id);
  _live.remove(id);
}

// The native side refuses a larger buffer.
const int _maxCapacity = 1 << 30;

const String _scheme = 'mak-pcm://';

// The format of every source not yet released, for the load options of
// its media.
final Map<int, PcmFormat> _formats = {};
final Set<int> _lowLatency = {};

// Every source not yet released, for the player that loads its media.
final Map<int, WeakReference<PcmSource>> _live = {};

// The source of each media [toMedia] made: a source the app keeps only
// through its media (`player.add(make().toMedia())`) must not be
// collected between toMedia and the player holding its entry.
final Expando<PcmSource> _byMedia = Expando<PcmSource>('pcm');

final class _NativeRef {
  _NativeRef(this.native, this.id);
  final PcmNative native;
  final int id;
}

/// The live source [uri] names, while it is not released.
@internal
PcmSource? pcmSourceFor(String uri) {
  if (!isPcmUri(uri)) return null;
  final id = int.tryParse(uri.substring(_scheme.length));
  return id == null ? null : _live[id]?.target;
}

/// Whether [uri] names a live PCM source.
@internal
bool isPcmUri(String uri) => uri.startsWith(_scheme);

/// The file-local `loadfile` options that play the `mak-pcm://` [uri]:
/// mpv's raw audio demuxer set to the source's format, and no gapless
/// audio, so the entry ends once its last sample has played rather than
/// once the audio output holds it (a buffer earlier, with nothing after
/// it to join). `null` when [uri] is not one. Throws [ArgumentError] for
/// a source that is released or was never created in this isolate.
@internal
String? pcmLoadOptions(String uri) {
  if (!isPcmUri(uri)) return null;
  final id = int.tryParse(uri.substring(_scheme.length));
  final format = id == null ? null : _formats[id];
  if (format == null) {
    throw ArgumentError.value(
      uri,
      'media',
      'is not a live PcmSource: it is done, or was not created here',
    );
  }
  // cache-pause=no: a pause in the input (between two sentences) would
  // otherwise hold playback until a second is buffered, a lag that stays
  // for the rest of the entry. demuxer-termination-timeout=0: stop, next
  // or a dispose with a starved reader return at once instead of after
  // 100 ms. demuxer-seekable-cache=no: with the cache forced on (cache=yes)
  // mpv would seek back into what it cached of the live input and keep a
  // back buffer of up to 50 MiB for it.
  return 'demuxer=rawaudio,'
      'demuxer-rawaudio-format=${format.encoding.mpvValue},'
      'demuxer-rawaudio-rate=${format.sampleRate},'
      'demuxer-rawaudio-channels=${format.channels},'
      'cache-pause=no,'
      'demuxer-termination-timeout=0,'
      'demuxer-seekable-cache=no,'
      'gapless-audio=no'
      '${_lowLatency.contains(id) ? ',audio-buffer=0.1' : ''}';
}

extension on PcmFormat {
  /// The bytes of [d] of audio, whole frames. Past [_durationFramesCap]
  /// frames it stops growing, far above the 1 GiB a source holds, so no
  /// duration wraps it to a negative size.
  int durationBytes(Duration d) {
    const second = Duration.microsecondsPerSecond;
    final us = d.inMicroseconds;
    // The seconds and the rest apart: their sum is the frames of the
    // whole, and neither product passes 64 bits.
    final frames =
        us ~/ second * sampleRate + us.remainder(second) * sampleRate ~/ second;
    return math.min(frames, _durationFramesCap) * bytesPerFrame;
  }
}

/// The most frames `durationBytes` counts: 2^40, about a month at 384 kHz.
const int _durationFramesCap = 1 << 40;
