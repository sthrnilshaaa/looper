// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// The load-time options of a [Media]: their validation, which every load
/// runs before its first await, and the file-local `<options>` argument of
/// `loadfile` built from them. Pure functions of the [Media].
library;

import 'dart:convert';

import '../internals/duration_seconds.dart';
import '../models/media.dart';
import '../pcm/pcm_source.dart';

/// Throws [ArgumentError] for a live PCM [media] on a path that cannot
/// give it its load options (`audio-add`, `loadlist`): mpv would open it
/// without them and use up its single reader. [name] is the parameter
/// that took it.
void rejectPcm(Media media, String name) {
  if (!isPcmUri(media.uri)) return;
  throw ArgumentError.value(
    media.uri,
    name,
    'a live PcmSource plays only as a playlist entry '
    '(open, openAll, add, replace)',
  );
}

/// The `loadfile` command of [uri] with [flags] (`replace`, `append`,
/// `insert-at`), at the index [at] for `insert-at`, and the per-entry
/// [options] of [loadfileOptions]. The options need the index argument
/// (mpv 0.38+), `-1` when the flags take none.
List<String> loadfileArgs(
  String uri,
  String flags,
  String options, {
  int? at,
}) => [
  'loadfile',
  uri,
  flags,
  if (at != null) '$at' else if (options.isNotEmpty) '-1',
  if (options.isNotEmpty) options,
];

/// Builds the `loadfile` `<options>` argument from a [Media]'s
/// `httpHeaders`, `httpChunkSize`, `streamLavfOptions`, `demuxerLavfOptions`,
/// `start`, `end` and `waveformDurationHint`, and the raw audio demuxer
/// of a live PCM source. Each
/// value is length-prefixed
/// (`%N%`) so the outer option-list parser doesn't split on the commas
/// inside it. The headers still refuse some characters
/// ([_validateHeaderKey], [_validateHeaderValue]): `,`, since
/// `http-header-fields` is itself a comma-separated list; CR, LF and NUL,
/// which would inject into the HTTP request; and `:` in keys.
/// Returns `''` when the media carries none.
///
/// Validates [media] as [validateLoadOptions] does: a load builds the
/// options of its media before its first await, once, and so fails
/// before any side effect.
String loadfileOptions(Media media) {
  _checkPlayRange(media);
  _checkDurationHint(media);
  final parts = <String>[];

  // A live PCM source: mpv's raw audio demuxer in the source's format.
  final pcm = pcmLoadOptions(media.uri);
  if (pcm != null) parts.add(pcm);

  final headers = media.httpHeaders;
  if (headers != null && headers.isNotEmpty) {
    for (final e in headers.entries) {
      _validateHeaderKey(e.key);
      _validateHeaderValue(e.key, e.value);
    }
    final joined = headers.entries.map((e) => '${e.key}: ${e.value}').join(',');
    parts.add('http-header-fields=%${utf8.encode(joined).length}%$joined');
  }

  // Added to the global `stream-lavf-o` (the reconnect defaults of
  // [_kStreamLavfDefaults], or what the app set) for this entry only.
  final stream = _streamOptions(media);
  if (stream.isNotEmpty) {
    parts.add(_keyValueOption('stream-lavf-o-add', stream));
  }

  final lavf = media.demuxerLavfOptions;
  if (lavf != null && lavf.isNotEmpty) {
    for (final e in lavf.entries) {
      _validateLavfOption(e.key, e.value, 'demuxerLavfOptions');
    }
    // File-local `demuxer-lavf-o`, scoped to this entry like the options
    // above.
    parts.add(_keyValueOption('demuxer-lavf-o', lavf));
  }

  // mpv applies it after a resume point it loads for the file, so it wins.
  final start = media.start;
  if (start != null) parts.add('start=${durationToOption(start)}');
  final end = media.end;
  if (end != null) parts.add('end=${durationToOption(end)}');

  // Read by the analysis only.
  final hint = media.waveformDurationHint;
  if (hint != null) {
    parts.add('waveform-duration-hint=${durationToOption(hint)}');
  }

  return parts.join(',');
}

/// The `stream-lavf-o` entries of [media], each key once: those of its
/// chunk size, then its own options, a later value replacing an earlier
/// one.
Map<String, String> _streamOptions(Media media) {
  final stream = <String, String>{};
  final chunk = media.httpChunkSize;
  if (chunk != null) {
    if (chunk <= 0) {
      throw ArgumentError.value(
        chunk,
        'httpChunkSize',
        'must be a positive byte count (or null to disable)',
      );
    }
    // Cap every HTTP range request to `chunk` bytes so a CDN that throttles
    // open-ended requests keeps serving at full speed instead of slowing an
    // unbounded whole-file request to a crawl; `reconnect_*` recover genuine
    // drops (mpv already sets `reconnect=1`).
    //
    // Why BOTH options (verified against FFmpeg 9.0.2 `libavformat/http.c`):
    //   • `request_size` bounds EVERY request, the first one included: the
    //     gate is `if ((s->initial_requests || s->request_size) &&
    //     s->seekable != 0)` (http.c:1602)
    //     and mpv leaves `seekable` unset (→ -1, ≠ 0), so the bounded-range
    //     branch is taken even for the opening probe.
    //   • `initial_request_size` only overrides the size used for that probe;
    //     after the first chunk ffmpeg clears `initial_requests` (http.c:1868),
    //     so on its own the steady-state reads would revert to an unbounded
    //     `Range: bytes=off-`.
    // Setting both keeps the probe AND every steady-state read bounded.
    // (`request_size` alone would also suffice here; `initial_request_size`
    // alone would NOT: chunk 2+ would go unbounded.)
    stream.addAll({
      'initial_request_size': '$chunk',
      'request_size': '$chunk',
      'reconnect_streamed': '1',
      'reconnect_on_network_error': '1',
    });
  }
  final own = media.streamLavfOptions;
  if (own != null) {
    for (final e in own.entries) {
      _validateLavfOption(e.key, e.value, 'streamLavfOptions');
    }
    stream.addAll(own);
  }
  return stream;
}

/// The file-local option [name] holding [entries] as `key=value` pairs,
/// comma-joined (each validated comma-free) and length-prefixed.
String _keyValueOption(String name, Map<String, String> entries) {
  final value = entries.entries.map((e) => '${e.key}=${e.value}').join(',');
  return '$name=%${utf8.encode(value).length}%$value';
}

/// Throws [ArgumentError] for a negative [Media.start], an [Media.end]
/// not later than the start (or zero), or either on a live PCM entry,
/// which is not seekable and plays from its first chunk to its last.
void _checkPlayRange(Media media) {
  final start = media.start;
  final end = media.end;
  if (start != null && start.isNegative) {
    throw ArgumentError.value(start, 'start', 'must not be negative');
  }
  if (end != null && end <= (start ?? Duration.zero)) {
    throw ArgumentError.value(
      end,
      'end',
      start == null ? 'must be later than zero' : 'must be later than start',
    );
  }
  if (isPcmUri(media.uri)) {
    if (start != null) {
      throw ArgumentError.value(
        start,
        'start',
        'a live PcmSource plays from its first chunk',
      );
    }
    if (end != null) {
      throw ArgumentError.value(
        end,
        'end',
        'a live PcmSource plays to its last chunk',
      );
    }
  }
}

/// Throws [ArgumentError] for a `waveformDurationHint` that is not
/// positive.
void _checkDurationHint(Media media) {
  final hint = media.waveformDurationHint;
  if (hint != null && hint <= Duration.zero) {
    throw ArgumentError.value(hint, 'waveformDurationHint', 'must be positive');
  }
}

final RegExp _kForbiddenInHeaderKey = RegExp(r'[\r\n,:\x00]');
final RegExp _kForbiddenInHeaderValue = RegExp(r'[\r\n,\x00]');

/// Up-front validator for a [Media]'s load-time options: the checks of
/// [loadfileOptions] without the build, for a load that gives its media no
/// options (`loadlist`, `audio-add`). Called before `resolveUri` runs so a
/// bad value fails fast, before any optimistic state write.
void validateLoadOptions(Media media) {
  _checkPlayRange(media);
  _checkDurationHint(media);
  pcmLoadOptions(media.uri);
  final headers = media.httpHeaders;
  if (headers != null && headers.isNotEmpty) {
    for (final e in headers.entries) {
      _validateHeaderKey(e.key);
      _validateHeaderValue(e.key, e.value);
    }
  }
  final chunk = media.httpChunkSize;
  if (chunk != null && chunk <= 0) {
    throw ArgumentError.value(
      chunk,
      'httpChunkSize',
      'must be a positive byte count (or null to disable)',
    );
  }
  for (final (name, options) in [
    ('streamLavfOptions', media.streamLavfOptions),
    ('demuxerLavfOptions', media.demuxerLavfOptions),
  ]) {
    for (final e in options?.entries ?? const <MapEntry<String, String>>[]) {
      _validateLavfOption(e.key, e.value, name);
    }
  }
}

final RegExp _kForbiddenInLavfOption = RegExp(r'[\r\n,\x00]');

/// A `stream-lavf-o` or `demuxer-lavf-o` entry sits in a comma-separated
/// list, so its key must be non-empty and the key and value free of comma,
/// CR, LF and NUL. [name] is the [Media] field it came from. Mirrors the
/// header validators. The error names the key only: a value can carry
/// credentials, as [Media.toString] says.
void _validateLavfOption(String key, String value, String name) {
  if (key.isEmpty) {
    throw ArgumentError.value(key, '$name key', 'must not be empty');
  }
  if (_kForbiddenInLavfOption.hasMatch(key) ||
      _kForbiddenInLavfOption.hasMatch(value)) {
    throw ArgumentError.value(
      key,
      name,
      'must not contain CR, LF, NUL, or comma in its key or value',
    );
  }
}

void _validateHeaderKey(String key) {
  if (key.isEmpty) {
    throw ArgumentError.value(key, 'header name', 'must not be empty');
  }
  if (_kForbiddenInHeaderKey.hasMatch(key)) {
    throw ArgumentError.value(
      key,
      'header name',
      'must not contain CR, LF, NUL, comma, or colon',
    );
  }
}

/// The error names the header, not its value, which often holds a token.
void _validateHeaderValue(String key, String value) {
  if (_kForbiddenInHeaderValue.hasMatch(value)) {
    throw ArgumentError(
      'the value of $key must not contain CR, LF, NUL, or comma (would '
          'split or inject the HTTP request)',
      'header value',
    );
  }
}
