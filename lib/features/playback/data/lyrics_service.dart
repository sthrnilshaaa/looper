import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:looper_player/core/utils/logger_helper.dart';

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
        LoggerHelper.write(
          'LyricsService: DuckDuckGo rate limited (${response.statusCode}), pausing web searches for 60s',
        );
        return null;
      }

      if (response.statusCode != 200) return null;

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

    switch (provider.toUpperCase()) {
      case 'GENIUS':
        return _fetchGeniusLyrics(trackName, artistName);
      case 'MUSIXMATCH':
        return _fetchMusixmatchLyrics(trackName, artistName);
      case 'AZLYRICS':
        return _fetchAZLyrics(trackName, artistName);
      case 'LYRICSMINT':
        return _fetchLyricsMintLyrics(trackName, artistName);
      case 'LYRICFIND':
        return _fetchLyricFindLyrics(trackName, artistName);
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

  // --- 1. LRCLIB (Default / Existing) ---
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

      if (response.statusCode == 200) {
        return LyricsResponse.fromJson(jsonDecode(response.body));
      }

      // 2nd Attempt: Single fallback search query (max 2 HTTP calls total)
      final searchQuery = '$cleanArtist $cleanTrack';
      url = Uri.parse(
        '$lrclibBaseUrl/search',
      ).replace(queryParameters: {'q': searchQuery});
      response = await http.get(url).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List results = jsonDecode(response.body);
        if (results.isNotEmpty) {
          if (durationSeconds > 0) {
            for (var result in results) {
              final resultDuration = (result['duration'] as num?)?.toInt() ?? 0;
              if ((resultDuration - durationSeconds).abs() < 10) {
                return LyricsResponse.fromJson(result);
              }
            }
          }
          final syncedResult = results.firstWhere(
            (r) =>
                r['syncedLyrics'] != null &&
                r['syncedLyrics'].toString().isNotEmpty,
            orElse: () => results.first,
          );
          return LyricsResponse.fromJson(syncedResult);
        }
      }
    } catch (_) {
      LoggerHelper.write(
        'LyricsService: LRCLIB request timed out or unavailable',
      );
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
      if (response.statusCode != 200) return null;

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
      LoggerHelper.write('LyricsService: Genius lyrics fetch error');
    }
    return null;
  }

  // --- 3. Musixmatch ---
  Future<LyricsResponse?> _fetchMusixmatchLyrics(
    String trackName,
    String artistName,
  ) async {
    try {
      final query = '$artistName $trackName';
      final pageUrl = await _searchUrlOnDuckDuckGo('musixmatch.com', query);
      if (pageUrl == null) return null;

      final response = await http
          .get(Uri.parse(pageUrl), headers: _browserHeaders)
          .timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) return null;

      final nextDataRegex = RegExp(
        r'<script id="__NEXT_DATA__"[^>]*>(.*?)</script>',
        dotAll: true,
      );
      final match = nextDataRegex.firstMatch(response.body);
      if (match != null) {
        final data = jsonDecode(match.group(1)!);
        final trackInfo =
            data['props']?['pageProps']?['data']?['trackInfo']?['data'];
        if (trackInfo != null) {
          final lyricsBody = trackInfo['lyrics']?['body'];
          if (lyricsBody is String && lyricsBody.isNotEmpty) {
            return LyricsResponse(plainLyrics: lyricsBody.trim());
          }
        }
      }
    } catch (_) {
      LoggerHelper.write('LyricsService: Musixmatch lyrics fetch error');
    }
    return null;
  }

  // --- 4. AZLyrics ---
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

      if (response.statusCode == 200) {
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
      LoggerHelper.write('LyricsService: AZLyrics fetch error');
    }
    return null;
  }

  // --- 5. LyricsMINT ---
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
      if (response.statusCode == 200) {
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
      LoggerHelper.write('LyricsService: LyricsMINT fetch error');
    }
    return null;
  }

  // --- 6. LyricFind ---
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
      if (response.statusCode != 200) return null;

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
      LoggerHelper.write('LyricsService: LyricFind fetch error');
    }
    return null;
  }
}
