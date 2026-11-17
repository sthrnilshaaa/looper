import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:looper_player/core/utils/logger_helper.dart';

import '../lyrics_formats/timed_lyrics.dart';
import '../lyrics_formats/ttml_lyrics_parser.dart';
import 'lyrics_http.dart';
import 'lyrics_query.dart';

/// BetterLyrics client: community API serving TTML word-synced lyrics.
/// Also serves QQ Music catalog for Chinese songs under `BETTERLYRICS_QQ`.
class BetterLyricsClient {
  static const String _defaultBase = 'https://lyrics-api.boidu.dev';
  static const String _qqBase = 'https://lyrics-api.boidu.dev/qq';
  static const Duration _timeout = Duration(seconds: 10);

  static Future<String?> fetch({
    required String title,
    required String artist,
    String album = '',
    int durationSeconds = 0,
    bool isQq = false,
  }) async {
    final baseUrl = isQq ? _qqBase : _defaultBase;
    final cleanT = LyricsQuery.cleanTitle(title);
    final cleanA =
        LyricsQuery.artistVariants(artist, max: 1).firstOrNull ?? artist.trim();

    // Inzx retries: exact -> cleaned -> cleaned without duration -> title only
    final attempts = <Map<String, String>>[
      {
        's': title.trim(),
        if (artist.trim().isNotEmpty) 'a': artist.trim(),
        if (album.trim().isNotEmpty) 'al': album.trim(),
        if (durationSeconds > 0) 'd': durationSeconds.toString(),
      },
      if (cleanT != title.trim() || cleanA != artist.trim())
        {
          's': cleanT,
          if (cleanA.isNotEmpty) 'a': cleanA,
          if (album.trim().isNotEmpty) 'al': album.trim(),
          if (durationSeconds > 0) 'd': durationSeconds.toString(),
        },
      {
        's': cleanT,
        if (cleanA.isNotEmpty) 'a': cleanA,
        if (album.trim().isNotEmpty) 'al': album.trim(),
      },
      {'s': cleanT},
    ];

    try {
      for (final params in attempts) {
        if (params['s'] == null || params['s']!.isEmpty) continue;
        final uri = Uri.parse(
          '$baseUrl/getLyrics',
        ).replace(queryParameters: params);
        final response = await http
            .get(uri, headers: LyricsHttp.headers)
            .timeout(_timeout);

        if (!LyricsHttp.ok(response.statusCode)) continue;

        final bodyText = utf8.decode(response.bodyBytes);
        String? ttmlContent;
        int? respDuration;

        try {
          final decoded = jsonDecode(bodyText);
          if (decoded is Map) {
            ttmlContent =
                decoded['ttml']?.toString() ??
                decoded['lyrics']?.toString() ??
                decoded['data']?['ttml']?.toString();
            final dur = decoded['duration'] ?? decoded['d'];
            if (dur is num) respDuration = dur.round();
          } else if (decoded is String) {
            ttmlContent = decoded;
          }
        } catch (_) {
          // If body is raw TTML
          if (bodyText.contains('<tt') || bodyText.contains('<timedtext')) {
            ttmlContent = bodyText;
          }
        }

        if (ttmlContent == null || ttmlContent.trim().isEmpty) continue;

        // Duration guard: reject if duration differs > 10 s
        if (durationSeconds > 0 && respDuration != null) {
          if ((respDuration - durationSeconds).abs() > 10) {
            continue;
          }
        }

        final lines = TtmlLyricsParser.parse(ttmlContent);
        if (lines == null || lines.isEmpty) continue;
        if (durationSeconds > 0 && !fitsDuration(lines, durationSeconds + 10)) {
          continue;
        }

        final lrc = TimedLrcWriter.write(lines);
        if (lrc != null) return lrc;
      }
    } catch (e) {
      LyricsHttp.failed();
      LoggerHelper.write('BetterLyricsClient: lookup error ($e)');
    }
    return null;
  }
}
