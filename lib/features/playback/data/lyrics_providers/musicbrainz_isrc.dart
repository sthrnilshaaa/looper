import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:looper_player/core/utils/logger_helper.dart';

import 'lyrics_http.dart';
import 'lyrics_query.dart';

/// ISRC lookup on MusicBrainz, for lrc.red's `/s/{isrc}.ttml`, and genre
/// lookup for songs whose tags carry none.
///
/// lrc.red's own search (`match.json`/`search.json`) can hang for minutes
/// while its TTML files still load instantly (seen 2026-09-28), and local
/// files rarely carry an ISRC tag - MusicBrainz is free, keyless and lists
/// ISRCs per recording. Its rules: a descriptive User-Agent and at most
/// one request per second, enforced here across concurrent callers.
class MusicBrainzIsrc {
  static const String _endpoint = 'https://musicbrainz.org/ws/2/recording';
  static const int _maxDurationDriftSec = 4;
  static const Duration _minGap = Duration(milliseconds: 1100);

  static Future<void> _queue = Future.value();

  /// ISRCs of recordings of [title] credited to one of [artists] (the full
  /// credit first, then each name - see LyricsQuery.artistVariants), within
  /// a few seconds of [durationSeconds] when known. Title and length alone
  /// match mostly covers for a popular song, so an unknown artist finds
  /// nothing.
  static Future<List<String>> find({
    required String title,
    required List<String> artists,
    int durationSeconds = 0,
  }) async {
    final recordings = await _recordings(
      title: title,
      artists: artists,
      durationSeconds: durationSeconds,
    );
    return {
      for (final r in recordings)
        if (r['isrcs'] is List) ...(r['isrcs'] as List).whereType<String>(),
    }.toList();
  }

  /// The most-voted genre of the recording of [title] by [artists] (matched
  /// as for [find]), else of its artist - recordings are tagged far less
  /// often than artists. Title-cased like the usual genre tags, so
  /// "alternative rock" groups with a file's "Alternative Rock".
  static Future<String?> genre({
    required String title,
    required List<String> artists,
    int durationSeconds = 0,
  }) async {
    final recordings = await _recordings(
      title: title,
      artists: artists,
      durationSeconds: durationSeconds,
    );
    if (recordings.isEmpty) return null;

    try {
      final body = await _throttled(
        () => http
            .get(
              Uri.parse('$_endpoint/${recordings.first['id']}').replace(
                queryParameters: {'inc': 'genres artists', 'fmt': 'json'},
              ),
              headers: LyricsHttp.headers,
            )
            .timeout(LyricsHttp.timeout),
      );
      if (body == null) return null;

      final recording = jsonDecode(body) as Map;
      final credits = recording['artist-credit'];
      final name =
          _topGenre(recording['genres']) ??
          (credits is List && credits.isNotEmpty
              ? _topGenre(credits.first['artist']?['genres'])
              : null);
      return name?.replaceAllMapped(
        RegExp(r'\b\w'),
        (m) => m[0]!.toUpperCase(),
      );
    } catch (e) {
      LyricsHttp.failed();
      LoggerHelper.write('MusicBrainzIsrc: genre lookup failed ($e)');
      return null;
    }
  }

  /// The name of the genre with the most votes in [genres], if any.
  static String? _topGenre(Object? genres) {
    if (genres is! List) return null;
    final sorted = genres.whereType<Map>().toList()
      ..sort((a, b) => (b['count'] as num).compareTo(a['count'] as num));
    return sorted.isEmpty ? null : '${sorted.first['name']}';
  }

  /// Search hits for [title] credited to one of [artists].
  static Future<List<Map>> _recordings({
    required String title,
    required List<String> artists,
    required int durationSeconds,
  }) async {
    final cleanTitle = LyricsQuery.cleanTitle(title);
    final titleKey = LyricsQuery.key(cleanTitle);
    if (titleKey.isEmpty) return const [];

    // Individual names when the credit splits, else the credit itself.
    final names = (artists.length > 1 ? artists.skip(1) : artists)
        .where((a) => a.toLowerCase() != 'unknown artist')
        .toList();
    if (names.isEmpty) return const [];

    final clauses = [
      'recording:"${_escape(cleanTitle)}"',
      '(${names.map((a) => 'artist:"${_escape(a)}"').join(' OR ')})',
    ];
    if (durationSeconds > 0) {
      final lo = (durationSeconds - _maxDurationDriftSec) * 1000;
      final hi = (durationSeconds + _maxDurationDriftSec) * 1000;
      clauses.add('dur:[$lo TO $hi]');
    }

    try {
      final body = await _throttled(
        () => http
            .get(
              Uri.parse(_endpoint).replace(
                queryParameters: {
                  'query': clauses.join(' AND '),
                  'fmt': 'json',
                  'limit': '10',
                },
              ),
              headers: LyricsHttp.headers,
            )
            .timeout(LyricsHttp.timeout),
      );
      if (body == null) return const [];

      final recordings = (jsonDecode(body) as Map)['recordings'];
      if (recordings is! List) return const [];

      final artistKeys = names.map(LyricsQuery.key).toSet();
      final found = <Map>[];
      for (final r in recordings.whereType<Map>()) {
        if (LyricsQuery.key('${r['title']}') != titleKey) continue;
        final length = r['length'];
        if (durationSeconds > 0 &&
            length is num &&
            (length / 1000 - durationSeconds).abs() > _maxDurationDriftSec) {
          continue;
        }
        final credited =
            r['artist-credit'] is List &&
            (r['artist-credit'] as List)
                .whereType<Map>()
                .map((a) => LyricsQuery.key('${a['name']}'))
                .any(artistKeys.contains);
        if (credited) found.add(r);
      }
      return found;
    } catch (e) {
      LyricsHttp.failed();
      LoggerHelper.write('MusicBrainzIsrc: lookup failed ($e)');
      return const [];
    }
  }

  /// Runs [request] no sooner than [_minGap] after the previous one.
  static Future<String?> _throttled(Future<http.Response> Function() request) {
    final result = Completer<String?>();
    _queue = _queue.then((_) async {
      try {
        final response = await request();
        result.complete(
          LyricsHttp.ok(response.statusCode) ? response.body : null,
        );
      } catch (e) {
        result.completeError(e);
      }
      await Future<void>.delayed(_minGap);
    });
    return result.future;
  }

  static String _escape(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
}
