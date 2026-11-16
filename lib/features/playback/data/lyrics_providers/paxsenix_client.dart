import 'dart:convert';
import 'dart:ui' show PlatformDispatcher;
import 'package:http/http.dart' as http;
import 'package:looper_player/core/services/apple_web_token.dart';
import 'package:looper_player/core/utils/logger_helper.dart';

import '../lyrics_formats/timed_lyrics.dart';
import '../lyrics_formats/ttml_lyrics_parser.dart';
import 'lyrics_http.dart';
import 'lyrics_query.dart';

/// PaxSenix lyrics client: searches Apple Music catalog via official web token
/// to find the Apple song ID, then fetches word-synced TTML or duets from PaxSenix.
class PaxSenixClient {
  static const String _paxBase = 'https://lyrics.paxsenix.org/apple-music/lyrics';
  static const Duration _timeout = Duration(seconds: 10);

  static Future<String?> fetch({
    required String title,
    required String artist,
    String album = '',
    int durationSeconds = 0,
    http.Client? client,
  }) async {
    final token = await AppleWebToken.getToken(client: client);
    if (token == null) return null;

    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;

    try {
      final storefront =
          PlatformDispatcher.instance.locale.countryCode?.toLowerCase() ?? 'us';
      final cleanT = LyricsQuery.cleanTitle(title);
      final query = '$cleanT $artist'.trim();

      final searchUri = Uri.parse(
        'https://amp-api.music.apple.com/v1/catalog/$storefront/search',
      ).replace(
        queryParameters: {
          'term': query,
          'types': 'songs',
          'limit': '10',
        },
      );

      final searchRes = await httpClient.get(
        searchUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Origin': 'https://music.apple.com',
          'Referer': 'https://music.apple.com/',
          'Accept': 'application/json',
        },
      ).timeout(_timeout);

      if (searchRes.statusCode == 401 || searchRes.statusCode == 403) {
        AppleWebToken.invalidate();
        LyricsHttp.failed();
        return null;
      }

      if (!LyricsHttp.ok(searchRes.statusCode)) return null;

      final searchJson = jsonDecode(utf8.decode(searchRes.bodyBytes));
      final List songs =
          searchJson['results']?['songs']?['data'] as List? ?? const [];
      if (songs.isEmpty) return null;

      // Score candidates
      String? bestAppleId;
      int highestScore = -1;

      final normWantTitle = cleanT.toLowerCase().trim();
      final normWantArtist = artist.toLowerCase().trim();

      for (final s in songs.whereType<Map>()) {
        final id = s['id']?.toString();
        final attr = s['attributes'] as Map? ?? const {};
        final name = (attr['name']?.toString() ?? '').toLowerCase().trim();
        final artistName =
            (attr['artistName']?.toString() ?? '').toLowerCase().trim();
        final durMs = attr['durationInMillis'] as num?;

        if (id == null || id.isEmpty) continue;

        // Duration guard
        if (durationSeconds > 0 && durMs != null) {
          final songSec = (durMs / 1000).round();
          if ((songSec - durationSeconds).abs() > 10) {
            continue; // Reject if duration differs > 10s
          }
        }

        int score = 0;
        if (name == normWantTitle) {
          score += 80;
        } else if (name.contains(normWantTitle) || normWantTitle.contains(name)) {
          score += 40;
        }

        if (artistName.contains(normWantArtist) ||
            normWantArtist.contains(artistName)) {
          score += 40;
        }

        if (score > highestScore && score >= 40) {
          highestScore = score;
          bestAppleId = id;
        }
      }

      if (bestAppleId == null) return null;

      // Call PaxSenix with Apple Song ID
      final paxUri = Uri.parse(_paxBase).replace(
        queryParameters: {'id': bestAppleId},
      );

      final paxRes = await httpClient
          .get(paxUri, headers: LyricsHttp.headers)
          .timeout(_timeout);

      if (!LyricsHttp.ok(paxRes.statusCode)) return null;

      final paxJson = jsonDecode(utf8.decode(paxRes.bodyBytes));
      if (paxJson is! Map) return null;

      // 1. TTML content
      final ttml = paxJson['ttmlContent']?.toString() ??
          paxJson['ttml']?.toString();
      if (ttml != null && ttml.trim().isNotEmpty) {
        final lines = TtmlLyricsParser.parse(ttml);
        if (lines != null && lines.isNotEmpty) {
          if (durationSeconds <= 0 || fitsDuration(lines, durationSeconds + 10)) {
            final lrc = TimedLrcWriter.write(lines);
            if (lrc != null) return lrc;
          }
        }
      }

      // 2. ELRC multi-person / ELRC
      final elrcMulti = paxJson['elrcMultiPerson']?.toString();
      if (elrcMulti != null && elrcMulti.trim().isNotEmpty) {
        return elrcMulti.trim();
      }

      final elrc = paxJson['elrc']?.toString();
      if (elrc != null && elrc.trim().isNotEmpty) {
        return elrc.trim();
      }

      // 3. Plain lyrics
      final plain = paxJson['plainLyrics']?.toString();
      if (plain != null && plain.trim().isNotEmpty) {
        return plain.trim();
      }
    } catch (e) {
      LyricsHttp.failed();
      LoggerHelper.write('PaxSenixClient: lookup error ($e)');
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
    return null;
  }
}
