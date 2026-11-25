// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../internals/duration_seconds.dart';
import '../models/audio_params.dart';
import '../models/chapter.dart';
import '../models/demuxer_cache_state.dart';
import '../models/device.dart';
import '../models/media.dart';
import '../models/mpv_track.dart';
import '../models/playlist.dart';
import '../types/enums/format.dart';
import '../types/sealed/channels.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Pure parsers for mpv properties delivered as `MPV_FORMAT_NODE`.
//
// Each function takes a Dart-native tree decoded by [decodeMpvNode] in
// `event_isolate.dart` (`Map<String, dynamic>`, `List<dynamic>`, scalar or
// `null`) and produces a typed model value. They are deliberately
// side-effect-free so the property dispatch pipeline can stay testable
// without spinning up a real player. The lists and maps they return
// cannot be changed: they become the state, which the streams compare.
// ─────────────────────────────────────────────────────────────────────────────

/// Decodes mpv's `playlist` property (`MPV_FORMAT_NODE_ARRAY`) into a
/// [Playlist].
///
/// [mediaByEntry] maps mpv's playlist entry `id` to the [Media] that
/// loaded it, and [mediaCache] maps a URI to one: both retain the `extras`
/// and `httpHeaders` (mpv only echoes back the filename, never the extras
/// attached at construction). The entry id comes first, so two entries
/// with the same URI keep their own [Media]; the URI covers entries this
/// player didn't load itself (a `loadlist`, a raw command). On a miss of
/// both we fall back to a bare `Media(uri)` so the playlist stays
/// consistent rather than dropping entries silently.
///
/// [previous] is the previous [Playlist] state, used to recover a reasonable
/// `index` when mpv's payload omits the `current` flag (which it does
/// transiently during `playlist-move`). Without this fallback the index
/// would snap to 0 mid-reorder, briefly highlighting the wrong entry in the
/// UI. When no entry has EVER been current (entries appended on an idle
/// core, before playback starts) the index is `-1` instead; see
/// [Playlist.index].
Playlist parsePlaylistNode({
  required dynamic raw,
  required Map<String, Media> mediaCache,
  Map<int, Media> mediaByEntry = const {},
  required Playlist previous,
  int? skip,
  int? heldId,
}) {
  // Defensive: a non-list payload means mpv emitted something unexpected
  // for `playlist`. Preserve the previous value rather than clobber the
  // current view with an empty playlist.
  if (raw is! List) {
    return previous;
  }
  // An entry mpv still lists that the state leaves out: see
  // [retainedEntryAt].
  final entries = _without(raw, skip);
  final medias = <Media>[];
  // mpv's current entry, or during a kept stop (no current entry) the one
  // that stopped, found by its id so a duplicate before it is not taken.
  var currentIndex = _indexOfId(entries, heldId);
  for (var i = 0; i < entries.length; i++) {
    final entry = entries[i];
    if (entry is! Map) {
      medias.add(const Media(''));
      continue;
    }
    final filename = entry['filename'] as String? ?? '';
    final id = entry['id'];
    medias.add(
      (id is int ? mediaByEntry[id] : null) ??
          mediaCache[filename] ??
          Media(filename),
    );
    if (entry['current'] == true) currentIndex = i;
  }
  final int idx;
  if (currentIndex >= 0) {
    idx = currentIndex;
  } else if (medias.isEmpty) {
    // Documented empty-playlist value (matches [Playlist.empty]).
    idx = 0;
  } else if (previous.index >= 0 && previous.index < previous.items.length) {
    // Transient current-flag omission (playlist-move, or a coalesced
    // burst of playlist surgery). Follow the previously-current entry
    // BY MEDIA, not by raw position: during a move the entry may have
    // shifted, and during [Player.openAll]'s rebuild it is gone
    // entirely: mpv coalesces rapid notifications, so the payload can
    // jump straight from the old playlist to the fully-swapped one with
    // no current flag in between. Pinning the old NUMBER would mark an
    // unrelated incoming entry as active; following the Media keeps the
    // real track highlighted through a move and reports -1 ("no active
    // entry yet") through a swap. The Media, not its uri, is compared
    // because mpv names the entry by the loaded form (a `file://` URL
    // decoded to a path, an `asset://` copied to a temp file), which the
    // uri the caller passed does not match. With duplicate entries the
    // first occurrence wins; the transient lasts one event either way.
    idx = medias.indexOf(previous.items[previous.index]);
  } else {
    // Entries exist but none has EVER been current: the append build-up
    // phase of [Player.openAll] (entries queued on an idle core before
    // the playlist-play-index). Reporting a clamped 0 here would flash
    // "track 1 active" in a UI bound to the index; -1 says "no active
    // entry yet" and consumers guarding `index >= 0` skip the frame.
    idx = -1;
  }
  return Playlist(List.unmodifiable(medias), index: idx);
}

/// The position of the entry [id] in [entries], or -1.
int _indexOfId(List<Object?> entries, int? id) =>
    id == null ? -1 : entries.indexWhere((e) => e is Map && e['id'] == id);

/// [raw] without its entry at [skip], when there is one.
List<Object?> _without(List<Object?> raw, int? skip) =>
    skip == null || skip >= raw.length ? raw : (List.of(raw)..removeAt(skip));

/// Where the `playlist` node [raw] lists the entry [id] while it is not
/// the current one, or `null`. [Player.openAll] keeps the entry that
/// plays until the new ones are in, jumps to the new one, then removes the
/// old: in between mpv lists it ahead of the new entries, and the state
/// leaves it out ([parsePlaylistNode]'s `skip`).
int? retainedEntryAt(dynamic raw, int? id) {
  if (id == null || raw is! List) return null;
  for (var i = 0; i < raw.length; i++) {
    final entry = raw[i];
    if (entry is Map && entry['id'] == id) {
      return entry['current'] == true ? null : i;
    }
  }
  return null;
}

/// Decodes mpv's `audio-device-list` property (`MPV_FORMAT_NODE_ARRAY`).
///
/// Each entry in the array is a `MPV_FORMAT_NODE_MAP` with `name` and
/// `description` fields. Missing fields fall back to `'unknown'` and `''`
/// rather than throwing: `audio-device-list` is queried on every
/// `audio-reconfig` and a single malformed entry shouldn't tear down the
/// stream.
List<Device> parseDeviceListNode(dynamic raw) {
  if (raw is! List) return const [];
  return List.unmodifiable(
    raw.map((entry) {
      final m = entry is Map ? entry : const <String, dynamic>{};
      return Device(
        name: m['name'] as String? ?? 'unknown',
        description: m['description'] as String? ?? '',
      );
    }),
  );
}

/// Decodes mpv's `metadata` property (`MPV_FORMAT_NODE_MAP`) into a flat
/// `String → String` map.
///
/// An empty map is a file without tags and gives an empty map, so the
/// previous file's tags don't stay (#25). Returns `null`, which the caller
/// treats as "no update", only for input that is not a map; an unavailable
/// property goes through the player's reset instead.
Map<String, String>? parseMetadataNode(dynamic raw) {
  if (raw == null) return null;
  if (raw is! Map) return null;
  if (raw.isEmpty) return const <String, String>{};
  return Map.unmodifiable(
    raw.map((k, v) => MapEntry(k.toString(), v.toString())),
  );
}

/// Decodes mpv's `demuxer-cache-state` property (`MPV_FORMAT_NODE_MAP`)
/// into a 0..100 buffering percentage normalized against the user's
/// `cache-secs` target.
///
/// With mpv's default `cache-secs` (1000 hours) the result stays near 0:
/// a minute of cache is 0.0017 %. Falls back to a 1-second denominator if
/// [cacheSecsTarget] is zero (a `cache-secs` of 0 set by the app). The
/// result is clamped to `[0, 100]` because mpv may overshoot the target
/// briefly when rebuffering.
double parseDemuxerCacheStateNode(dynamic raw, Duration cacheSecsTarget) {
  if (raw is! Map) return 0.0;
  final cacheDuration = (raw['cache-duration'] as num?)?.toDouble() ?? 0.0;
  final targetSecs = cacheSecsTarget > Duration.zero
      ? durationToSeconds(cacheSecsTarget)
      : 1.0;
  return (cacheDuration / targetSecs * 100.0).clamp(0.0, 100.0);
}

/// Decodes the rich part of mpv's `demuxer-cache-state` node: the buffered
/// time ranges and network-cache flags useful to a streaming UI. Empty for
/// directly-seekable local files (mpv leaves the cache state unpopulated).
DemuxerCacheState parseDemuxerCacheStateFull(dynamic raw) {
  if (raw is! Map) return DemuxerCacheState.empty;
  final ranges = <CacheRange>[];
  final rangesRaw = raw['seekable-ranges'];
  if (rangesRaw is List) {
    for (final r in rangesRaw) {
      if (r is! Map) continue;
      final s = (r['start'] as num?)?.toDouble();
      final e = (r['end'] as num?)?.toDouble();
      if (s != null && e != null) {
        ranges.add(CacheRange(secondsToDuration(s), secondsToDuration(e)));
      }
    }
  }
  return DemuxerCacheState(
    seekableRanges: List.unmodifiable(ranges),
    rawInputRate: (raw['raw-input-rate'] as num?)?.toDouble(),
    eofCached: raw['eof-cached'] == true,
    bofCached: raw['bof-cached'] == true,
    underrun: raw['underrun'] == true,
  );
}

/// Decodes mpv's `audio-params` (or `audio-out-params`) property
/// (`MPV_FORMAT_NODE_MAP`) into an [AudioParams] populated with the 5 fields
/// mpv exposes on the wire (`format`, `sampleRate`, `channels`,
/// `channel-count`, `hr-channels`).
///
/// `codec` and `codecName` are NOT emitted by these node maps; they live
/// on separate properties (`audio-codec`, `audio-codec-name`). The caller's
/// `reduce` function should `copyWith` only the fields this parser
/// populates so the codec fields, populated by their own observers, survive
/// the merge.
AudioParams parseAudioParamsNode(dynamic raw) {
  if (raw is! Map) return const AudioParams();
  final formatStr = _stringOrNull(raw['format']);
  final channelsStr = _stringOrNull(raw['channels']);
  return AudioParams(
    format: formatStr == null ? null : Format.fromMpv(formatStr),
    sampleRate: _intOrNull(raw['samplerate']),
    channels: channelsStr == null ? null : Channels.fromMpv(channelsStr),
    channelCount: _intOrNull(raw['channel-count']),
    hrChannels: _stringOrNull(raw['hr-channels']),
  );
}

/// Decodes mpv's `track-list` property (`MPV_FORMAT_NODE_ARRAY`).
///
/// Each entry is a `MPV_FORMAT_NODE_MAP` describing one track. Missing
/// `id` entries fall back to `-1` and missing `type` to `''` rather
/// than throwing, since mpv occasionally emits transient malformed entries
/// during track reconfig.
List<MpvTrack> parseTrackListNode(dynamic raw) {
  if (raw is! List) return const [];
  return List.unmodifiable(raw.map(_parseTrackEntry));
}

/// Decodes mpv's `current-tracks/audio` property (`MPV_FORMAT_NODE_MAP`):
/// the metadata of the currently-active audio track. Returns `null`
/// when no audio track is active (mpv emits `null` or a non-map).
MpvTrack? parseCurrentTrackNode(dynamic raw) {
  if (raw is! Map) return null;
  return _parseTrackEntry(raw);
}

MpvTrack _parseTrackEntry(dynamic entry) {
  final m = entry is Map ? entry : const <String, dynamic>{};
  return MpvTrack(
    id: m['id'] is int ? m['id'] as int : -1,
    type: m['type'] is String ? m['type'] as String : '',
    selected: m['selected'] == true,
    title: _stringOrNull(m['title']),
    lang: _stringOrNull(m['lang']),
    defaultTrack: m['default'] == true,
    forced: m['forced'] == true,
    dependent: m['dependent'] == true,
    visualImpaired: m['visual-impaired'] == true,
    hearingImpaired: m['hearing-impaired'] == true,
    image: m['image'] == true,
    albumArt: m['albumart'] == true,
    external: m['external'] == true,
    externalFilename: _stringOrNull(m['external-filename']),
    codec: _stringOrNull(m['codec']),
    codecDesc: _stringOrNull(m['codec-desc']),
    codecProfile: _stringOrNull(m['codec-profile']),
    decoder: _stringOrNull(m['decoder']),
    decoderDesc: _stringOrNull(m['decoder-desc']),
    formatName: _stringOrNull(m['format-name']),
    sampleRate: _intOrNull(m['demux-samplerate']),
    channels: _stringOrNull(m['demux-channels']),
    channelCount: _intOrNull(m['demux-channel-count']),
    demuxBitrate: _doubleOrNull(m['demux-bitrate']),
    hlsBitrate: _doubleOrNull(m['hls-bitrate']),
    replayGainTrackGain: _doubleKeepZero(m['replaygain-track-gain']),
    replayGainTrackPeak: _doubleKeepZero(m['replaygain-track-peak']),
    replayGainAlbumGain: _doubleKeepZero(m['replaygain-album-gain']),
    replayGainAlbumPeak: _doubleKeepZero(m['replaygain-album-peak']),
    metadata: _stringMap(m['metadata']),
  );
}

/// Decodes mpv's `chapter-list` property (`MPV_FORMAT_NODE_ARRAY`).
///
/// Each entry is a `MPV_FORMAT_NODE_MAP` with `time` (seconds, double)
/// and an optional `title`. Missing or malformed entries fall back to
/// `Duration.zero` and `null` rather than throwing; a single bad
/// chapter shouldn't tear down the whole list.
List<Chapter> parseChapterListNode(dynamic raw) {
  if (raw is! List) return const [];
  return List.unmodifiable(
    raw.map((entry) {
      final m = entry is Map ? entry : const <String, dynamic>{};
      final t = m['time'];
      final time = t is num ? secondsToDuration(t.toDouble()) : Duration.zero;
      return Chapter(time: time, title: _stringOrNull(m['title']));
    }),
  );
}

String? _stringOrNull(dynamic v) {
  if (v is! String) return null;
  if (v.isEmpty) return null;
  return v;
}

// Treats `0` as missing, for the audio-track node fields where the
// caller cannot distinguish "explicit zero" from "absent", and zero
// would not be a meaningful sample rate or channel count anyway.
int? _intOrNull(dynamic v) {
  if (v is int) return v == 0 ? null : v;
  if (v is num) return v == 0 ? null : v.toInt();
  return null;
}

double? _doubleOrNull(dynamic v) {
  if (v is! num) return null;
  final d = v.toDouble();
  return d == 0.0 ? null : d;
}

// Keeps `0`: for the ReplayGain fields, which mpv adds only when the file
// carries the tags, so +0.00 dB (or a 0 peak) is a real value.
double? _doubleKeepZero(dynamic v) => v is num ? v.toDouble() : null;

Map<String, String> _stringMap(dynamic v) {
  if (v is! Map) return const <String, String>{};
  if (v.isEmpty) return const <String, String>{};
  return Map.unmodifiable(
    v.map((k, val) => MapEntry(k.toString(), val.toString())),
  );
}
