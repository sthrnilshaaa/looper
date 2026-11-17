import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:looper_player/core/utils/logger_helper.dart';

import '../lyrics_formats/timed_lyrics.dart';
import '../lyrics_formats/ttml_lyrics_parser.dart';
import 'lyrics_http.dart';
import 'lyrics_query.dart';

/// BiniLyrics client: searches Binimum lyrics index and fetches TTML from `lyricsUrl`.
class BiniLyricsClient {
  static const String _baseUrl = 'https://lyrics-api.binimum.org/';
  static const Duration _timeout = Duration(seconds: 10);

  static Future<String?> fetch({
    required String title,
    required String artist,
    String album = '',
    int durationSeconds = 0,
  }) async {
    final cleanT = LyricsQuery.cleanTitle(title);
    final cleanA =
        LyricsQuery.artistVariants(artist, max: 1).firstOrNull ?? artist.trim();

    try {
      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'track': cleanT,
          if (cleanA.isNotEmpty) 'artist': cleanA,
          if (album.trim().isNotEmpty) 'album': album.trim(),
          if (durationSeconds > 0) 'duration': durationSeconds.toString(),
        },
      );

      final response = await http
          .get(uri, headers: LyricsHttp.headers)
          .timeout(_timeout);

      if (!LyricsHttp.ok(response.statusCode)) return null;

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      List? results;
      if (body is Map) {
        results = body['results'] as List?;
      } else if (body is List) {
        results = body;
      }

      if (results == null || results.isEmpty) return null;

      // Filter and check duration guard (§2.3)
      Map? chosen;
      for (final r in results.whereType<Map>()) {
        final dur = r['duration'];
        if (durationSeconds > 0 && dur is num) {
          if ((dur - durationSeconds).abs() > 10) continue;
        }
        chosen = r;
        break;
      }

      if (chosen == null) return null;

      final lyricsUrl = chosen['lyricsUrl']?.toString();
      if (lyricsUrl == null || lyricsUrl.isEmpty) return null;

      final lyricsRes = await http
          .get(Uri.parse(lyricsUrl), headers: LyricsHttp.headers)
          .timeout(_timeout);

      if (!LyricsHttp.ok(lyricsRes.statusCode)) return null;

      final ttmlBody = utf8.decode(lyricsRes.bodyBytes);
      final lines = TtmlLyricsParser.parse(ttmlBody);
      if (lines == null || lines.isEmpty) return null;
      if (durationSeconds > 0 && !fitsDuration(lines, durationSeconds + 10)) {
        return null;
      }

      return TimedLrcWriter.write(lines);
    } catch (e) {
      LyricsHttp.failed();
      LoggerHelper.write('BiniLyricsClient: lookup error ($e)');
    }
    return null;
  }
}
