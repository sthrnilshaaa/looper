import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:looper_player/core/utils/logger_helper.dart';
import 'package:looper_player/features/playback/domain/lyric_models.dart';

import 'lyrics_providers/amll_client.dart';
import 'lyrics_providers/betterlyrics_client.dart';
import 'lyrics_providers/binilyrics_client.dart';
import 'lyrics_providers/kugou_client.dart';
import 'lyrics_providers/lrc_red_client.dart';
import 'lyrics_providers/lyricify_client.dart';
import 'lyrics_providers/lyrics_http.dart';
import 'lyrics_providers/lyrics_plus_client.dart';
import 'lyrics_providers/musixmatch_client.dart';
import 'lyrics_providers/netease_client.dart';
import 'lyrics_providers/paxsenix_client.dart';
import 'lyrics_providers/unison_client.dart';

class LyricsResponse {
  final String? lyrics;
  final bool? instrumental;
  final String? plainLyrics;
  final String? syncedLyrics;

  LyricsResponse({
    this.lyrics,
    this.instrumental,
    this.plainLyrics,
    this.syncedLyrics,
  });

  factory LyricsResponse.fromJson(Map<String, dynamic> json) {
    return LyricsResponse(
      lyrics: json['lyrics']?.toString(),
      instrumental: json['instrumental'] as bool?,
      plainLyrics: json['plainLyrics']?.toString(),
      syncedLyrics: json['syncedLyrics']?.toString(),
    );
  }
}

class LyricsService {
  static const String lrclibBaseUrl = 'https://lrclib.net/api';

  /// Seconds a recording may differ from the song and keep its timings.
  static const lengthTolerance = 3;

  /// LRCLIB search results for a song of [durationSeconds]: a result of
  /// the same length, else only untimed text. A recording of another
  /// length (an edit, an intro, a slowed upload) drifts against timings.
  static LyricsResponse? pickLrcLibResult(List results, int durationSeconds) {
    final rows = results.whereType<Map>().map((r) => r.cast<String, dynamic>());
    bool synced(Map<String, dynamic> r) =>
        (r['syncedLyrics']?.toString() ?? '').isNotEmpty;
    if (rows.isEmpty) return null;
    if (durationSeconds <= 0) {
      return LyricsResponse.fromJson(rows.firstWhere(synced, orElse: () => rows.first));
    }
    final sameLength = rows.where((r) {
      final d = (r['duration'] as num?)?.toDouble();
      return d != null && (d - durationSeconds).abs() <= lengthTolerance;
    });
    if (sameLength.isNotEmpty) {
      return LyricsResponse.fromJson(
        sameLength.firstWhere(synced, orElse: () => sameLength.first),
      );
    }
    for (final r in rows) {
      final plain = r['plainLyrics']?.toString() ?? '';
      final text = plain.isNotEmpty
          ? plain
          : synced(r)
          ? LrcParser.plainText(r['syncedLyrics'].toString())
          : '';
      if (text.isNotEmpty) return LyricsResponse(plainLyrics: text);
    }
    return null;
  }

  static const Map<String, String> _browserHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/115.0',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.5',
    'Connection': 'keep-alive',
    'Upgrade-Insecure-Requests': '1',
  };

  static DateTime? _duckDuckGoCoolDownUntil;
  static final Map<String, String> _ddgUrlCache = {};

  String _sanitize(String text) {
    return text
        .replaceAll(
          RegExp(r'\((feat|with|ft)\.?.*?\)', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'\[(feat|with|ft)\.?.*?\]', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(
            r'\((Remastered|Live|Official|Video).*?\)',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'\[(Remastered|Live|Official|Video).*?\]',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\s{2,}', caseSensitive: false), ' ')
        .trim();
  }

  String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  Future<String?> _searchUrlOnDuckDuckGo(String site, String query) async {
    final cacheKey = '$site:${query.toLowerCase().trim()}';
    if (_ddgUrlCache.containsKey(cacheKey)) {
      return _ddgUrlCache[cacheKey];
    }

    if (_duckDuckGoCoolDownUntil != null &&
        DateTime.now().isBefore(_duckDuckGoCoolDownUntil!)) {
      LyricsHttp.failed();
      return null;
    }

    try {
      final searchUrl = Uri.parse(
        'https://html.duckduckgo.com/html/',
      ).replace(queryParameters: {'q': 'site:$site $query'});
      final response = await http
          .get(searchUrl, headers: _browserHeaders)
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 429 || response.statusCode == 403) {
        _duckDuckGoCoolDownUntil = DateTime.now().add(
          const Duration(seconds: 60),
        );
        LyricsHttp.failed();
        LoggerHelper.write(
          'LyricsService: DuckDuckGo rate limited (${response.statusCode}), pausing web searches for 60s',
        );
        return null;
      }

      if (!LyricsHttp.ok(response.statusCode)) return null;

      final regex = RegExp(r'href="([^"]*' + RegExp.escape(site) + r'[^"]*)"');
      final matches = regex.allMatches(response.body);
      for (var match in matches) {
        String url = match.group(1)!;
        if (url.startsWith('//')) {
          url = 'https:$url';
        }
        if (url.contains('uddg=')) {
          final uri = Uri.parse(url);
          final uddg = uri.queryParameters['uddg'];
          if (uddg != null) {
            final decoded = Uri.decodeComponent(uddg);
            _ddgUrlCache[cacheKey] = decoded;
            return decoded;
          }
        }
        _ddgUrlCache[cacheKey] = url;
        return url;
      }
    } catch (_) {
      _duckDuckGoCoolDownUntil = DateTime.now().add(
        const Duration(seconds: 45),
      );
      LyricsHttp.failed();
      LoggerHelper.write(
        'LyricsService: DuckDuckGo search unavailable for $site $query',
      );
    }
    return null;
  }

  Future<LyricsResponse?> getLyrics({
    required String trackName,
    required String artistName,
    required String albumName,
    required int durationSeconds,
    String provider = 'LRCLIB',
  }) async {
    LoggerHelper.write(
      'LyricsService: Fetching lyrics using provider: $provider for $artistName - $trackName',
    );

    // The API clients share one shape and hand back LRC (with Looper's
    // word-timing lines when the source has word timing).
    final client = switch (provider.toUpperCase()) {
      'LRC.RED' => LrcRedClient.fetch,
      'LYRICSPLUS' => LyricsPlusClient.fetch,
      'AMLL' => AmllClient.fetch,
      'NETEASE' => NetEaseClient.fetch,
      'KUGOU' => KuGouClient.fetch,
      'MUSIXMATCH' => MusixmatchClient.fetch,
      'LYRICIFY' => LyricifyClient.fetch,
      'BETTERLYRICS' => BetterLyricsClient.fetch,
      'BINILYRICS' => BiniLyricsClient.fetch,
      'UNISON' => UnisonClient.fetch,
      _ => null,
    };
    if (client != null) {
      final lrc = await client(
        title: trackName,
        artist: artistName,
        album: albumName,
        durationSeconds: durationSeconds,
      );
      return lrc == null ? null : LyricsResponse(syncedLyrics: lrc);
    }

    switch (provider.toUpperCase()) {
      case 'BETTERLYRICS_QQ':
        final lrc = await BetterLyricsClient.fetch(
          title: trackName,
          artist: artistName,
          album: albumName,
          durationSeconds: durationSeconds,
          isQq: true,
        );
        return lrc == null ? null : LyricsResponse(syncedLyrics: lrc);
      case 'PAXSENIX':
        final lrc = await PaxSenixClient.fetch(
          title: trackName,
          artist: artistName,
          album: albumName,
          durationSeconds: durationSeconds,
        );
        return lrc == null ? null : LyricsResponse(syncedLyrics: lrc);
      case 'GENIUS':
        return _fetchGeniusLyrics(trackName, artistName);
      case 'AZLYRICS':
        return _fetchAZLyrics(trackName, artistName);
      case 'LYRICSMINT':
        return _fetchLyricsMintLyrics(trackName, artistName);
      case 'LYRICFIND':
        return _fetchLyricFindLyrics(trackName, artistName);
      case 'LYRICSOVH':
        return _fetchLyricsOvh(trackName, artistName);
      case 'LRCLIB':
      default:
        return _fetchLrcLibLyrics(
          trackName,
          artistName,
          albumName,
          durationSeconds,
        );
    }
  }

  // --- 1. LRCLIB ---
  Future<LyricsResponse?> _fetchLrcLibLyrics(
    String trackName,
    String artistName,
    String albumName,
    int durationSeconds,
  ) async {
    final cleanTrack = _sanitize(trackName);
    final cleanArtist = _sanitize(artistName);

    try {
      // 1st Attempt: Direct exact GET lookup
      final getParams = {
        'track_name': cleanTrack,
        'artist_name': cleanArtist,
        if (durationSeconds > 0) 'duration': durationSeconds.toString(),
      };

      var url = Uri.parse(
        '$lrclibBaseUrl/get',
      ).replace(queryParameters: getParams);
      var response = await http.get(url).timeout(const Duration(seconds: 4));

      if (LyricsHttp.ok(response.statusCode)) {
        return LyricsResponse.fromJson(jsonDecode(response.body));
      }

      // 2nd Attempt: Single fallback search query (max 2 HTTP calls total)
      final searchQuery = '$cleanArtist $cleanTrack';
      url = Uri.parse(
        '$lrclibBaseUrl/search',
      ).replace(queryParameters: {'q': searchQuery});
      response = await http.get(url).timeout(const Duration(seconds: 4));

      if (LyricsHttp.ok(response.statusCode)) {
        final List results = jsonDecode(response.body);
        return pickLrcLibResult(results, durationSeconds);
      }
    } catch (_) {
      LyricsHttp.failed();
      LoggerHelper.write(
        'LyricsService: LRCLIB request timed out or unavailable',
      );
    }
    return null;
  }

  // --- lyrics.ovh: free JSON API, plain text only ---
  Future<LyricsResponse?> _fetchLyricsOvh(
    String trackName,
    String artistName,
  ) async {
    try {
      final url = Uri(
        scheme: 'https',
        host: 'api.lyrics.ovh',
        pathSegments: ['v1', _sanitize(artistName), _sanitize(trackName)],
      );
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (!LyricsHttp.ok(response.statusCode)) return null;
      final text = (jsonDecode(response.body)['lyrics'] as String?)
          ?.replaceAll('\r\n', '\n')
          .trim();
      return text == null || text.isEmpty
          ? null
          : LyricsResponse(plainLyrics: text);
    } catch (_) {
      LyricsHttp.failed();
      LoggerHelper.write('LyricsService: lyrics.ovh fetch error');
    }
    return null;
  }

  // --- 2. Genius ---
  Future<LyricsResponse?> _fetchGeniusLyrics(
    String trackName,
    String artistName,
  ) async {
    try {
      final query = '$artistName $trackName';
      final pageUrl = await _searchUrlOnDuckDuckGo('genius.com', query);
      if (pageUrl == null) return null;

      final response = await http
          .get(Uri.parse(pageUrl), headers: _browserHeaders)
          .timeout(const Duration(seconds: 4));
      if (!LyricsHttp.ok(response.statusCode)) return null;

      final regex = RegExp(
        r'<div[^>]*data-lyrics-container="true"[^>]*>(.*?)</div>',
        dotAll: true,
      );
      final matches = regex.allMatches(response.body);
      if (matches.isNotEmpty) {
        final buffer = StringBuffer();
        for (var match in matches) {
          buffer.writeln(_cleanHtml(match.group(1)!));
        }
        return LyricsResponse(plainLyrics: buffer.toString().trim());
      }

      final regexOld = RegExp(
        r'<div[^>]*class="lyrics"[^>]*>(.*?)</div>',
        dotAll: true,
      );
      final matchOld = regexOld.firstMatch(response.body);
      if (matchOld != null) {
        return LyricsResponse(plainLyrics: _cleanHtml(matchOld.group(1)!));
      }
    } catch (_) {
      LyricsHttp.failed();
      LoggerHelper.write('LyricsService: Genius lyrics fetch error');
    }
    return null;
  }

  // --- 3. AZLyrics ---
  Future<LyricsResponse?> _fetchAZLyrics(
    String trackName,
    String artistName,
  ) async {
    try {
      final cleanArtist = artistName.toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9]'),
        '',
      );
      final cleanTrack = trackName.toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9]'),
        '',
      );

      String? pageUrl =
          'https://www.azlyrics.com/lyrics/$cleanArtist/$cleanTrack.html';

      var response = await http
          .get(Uri.parse(pageUrl), headers: _browserHeaders)
          .timeout(const Duration(seconds: 3));
      if (response.statusCode != 200) {
        final query = '$artistName $trackName';
        pageUrl = await _searchUrlOnDuckDuckGo('azlyrics.com', query);
        if (pageUrl == null) return null;
        response = await http
            .get(Uri.parse(pageUrl), headers: _browserHeaders)
            .timeout(const Duration(seconds: 4));
      }

      if (LyricsHttp.ok(response.statusCode)) {
        final html = response.body;
        final startTag =
            '<!-- Usage of azlyrics.com content by any third-party lyrics provider is prohibited by our licensing agreement. Sorry about that. -->';
        final startIdx = html.indexOf(startTag);
        if (startIdx != -1) {
          final endIdx = html.indexOf('</div>', startIdx + startTag.length);
          if (endIdx != -1) {
            final rawLyrics = html.substring(
              startIdx + startTag.length,
              endIdx,
            );
            return LyricsResponse(plainLyrics: _cleanHtml(rawLyrics));
          }
        }
      }
    } catch (_) {
      LyricsHttp.failed();
      LoggerHelper.write('LyricsService: AZLyrics fetch error');
    }
    return null;
  }

  // --- 4. LyricsMINT ---
  Future<LyricsResponse?> _fetchLyricsMintLyrics(
    String trackName,
    String artistName,
  ) async {
    try {
      final query = '$artistName $trackName';
      final pageUrl = await _searchUrlOnDuckDuckGo('lyricsmint.com', query);
      if (pageUrl == null) return null;

      final response = await http
          .get(Uri.parse(pageUrl), headers: _browserHeaders)
          .timeout(const Duration(seconds: 4));
      if (LyricsHttp.ok(response.statusCode)) {
        final html = response.body;
        final lyricRegex = RegExp(
          r'<div[^>]*class="[^"]*text-base[^"]*lg:text-lg[^"]*"[^>]*>(.*?)</div>',
          dotAll: true,
        );
        final lyricMatch = lyricRegex.firstMatch(html);
        if (lyricMatch != null) {
          final content = lyricMatch
              .group(1)!
              .replaceAll(RegExp(r'<p>', caseSensitive: false), '')
              .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
              .trim();
          return LyricsResponse(plainLyrics: _cleanHtml(content));
        }
      }
    } catch (_) {
      LyricsHttp.failed();
      LoggerHelper.write('LyricsService: LyricsMINT fetch error');
    }
    return null;
  }

  // --- 5. LyricFind ---
  Future<LyricsResponse?> _fetchLyricFindLyrics(
    String trackName,
    String artistName,
  ) async {
    try {
      final query = '$artistName $trackName';
      final pageUrl = await _searchUrlOnDuckDuckGo('lyricfind.com', query);
      if (pageUrl == null) return null;

      final response = await http
          .get(Uri.parse(pageUrl), headers: _browserHeaders)
          .timeout(const Duration(seconds: 4));
      if (!LyricsHttp.ok(response.statusCode)) return null;

      final html = response.body;

      final ldJsonRegex = RegExp(
        r'<script[^>]*type="application/ld\+json"[^>]*>(.*?)</script>',
        dotAll: true,
      );
      final ldMatches = ldJsonRegex.allMatches(html);
      for (var match in ldMatches) {
        try {
          final data = jsonDecode(match.group(1)!);
          if (data is Map<String, dynamic>) {
            final lyricsText = data['lyrics']?['text'] ?? data['text'];
            if (lyricsText is String && lyricsText.trim().isNotEmpty) {
              return LyricsResponse(plainLyrics: _cleanHtml(lyricsText));
            }
          }
        } catch (_) {}
      }

      final containerRegex = RegExp(
        r'<div[^>]*class="[^"]*(?:lf-lyrics|lyric-text|lyrics-body|lyric-body)[^"]*"[^>]*>(.*?)</div>',
        dotAll: true,
      );
      final containerMatch = containerRegex.firstMatch(html);
      if (containerMatch != null) {
        final content = containerMatch.group(1)!;
        return LyricsResponse(plainLyrics: _cleanHtml(content));
      }

      final lineRegex = RegExp(
        r'<(?:p|span)[^>]*class="[^"]*lf-lyric[^"]*"[^>]*>(.*?)</(?:p|span)>',
        dotAll: true,
      );
      final lineMatches = lineRegex.allMatches(html);
      if (lineMatches.isNotEmpty) {
        final buffer = StringBuffer();
        for (var m in lineMatches) {
          buffer.writeln(_cleanHtml(m.group(1)!));
        }
        final lyrics = buffer.toString().trim();
        if (lyrics.isNotEmpty) {
          return LyricsResponse(plainLyrics: lyrics);
        }
      }
    } catch (_) {
      LyricsHttp.failed();
      LoggerHelper.write('LyricsService: LyricFind fetch error');
    }
    return null;
  }
}
