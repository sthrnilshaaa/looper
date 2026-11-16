import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:looper_player/core/utils/logger_helper.dart';

import '../lyrics_formats/timed_lyrics.dart';
import '../lyrics_formats/ttml_lyrics_parser.dart';
import 'lyrics_http.dart';
import 'lyrics_query.dart';

/// Unison lyrics client: multi-format provider (TTML word, LRC line, or plain).
class UnisonClient {
  static const String _baseUrl = 'https://unison.boidu.dev/lyrics';
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
          'song': cleanT,
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
      if (body is! Map) return null;

      final data = body['data'];
      if (data is! Map) return null;

      final rawLyrics = data['lyrics']?.toString();
      final format = (data['format']?.toString() ?? '').toLowerCase();

      if (rawLyrics == null || rawLyrics.trim().isEmpty) return null;

      if (format.contains('ttml') || rawLyrics.contains('<tt')) {
        final lines = TtmlLyricsParser.parse(rawLyrics);
        if (lines != null && lines.isNotEmpty) {
          if (durationSeconds <= 0 || fitsDuration(lines, durationSeconds + 10)) {
            final lrc = TimedLrcWriter.write(lines);
            if (lrc != null) return lrc;
          }
        }
      }

      return rawLyrics.trim();
    } catch (e) {
      LyricsHttp.failed();
      LoggerHelper.write('UnisonClient: lookup error ($e)');
    }
    return null;
  }
}
