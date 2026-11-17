import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:looper_player/core/utils/logger_helper.dart';

/// Scrapes and caches Apple Music's web token from music.apple.com.
/// Shared by PaxSenix lyrics lookup and Apple Music catalog motion artwork.
class AppleWebToken {
  static String? _cachedToken;
  static DateTime? _expiresAt;
  static DateTime? _backoffUntil;

  /// Visible for testing.
  static void resetForTesting({
    String? token,
    DateTime? expiresAt,
    DateTime? backoffUntil,
  }) {
    _cachedToken = token;
    _expiresAt = expiresAt;
    _backoffUntil = backoffUntil;
  }

  /// Clears the cached token immediately (e.g. on 401/403 HTTP response).
  static void invalidate() {
    _cachedToken = null;
    _expiresAt = null;
  }

  /// Returns a valid Apple Music developer web token, or null if retrieval fails.
  static Future<String?> getToken({
    bool forceRefresh = false,
    http.Client? client,
  }) async {
    final now = DateTime.now();

    if (!forceRefresh && _cachedToken != null && _expiresAt != null) {
      if (now.isBefore(_expiresAt!)) {
        return _cachedToken;
      }
    }

    if (_backoffUntil != null && now.isBefore(_backoffUntil!)) {
      LoggerHelper.write('AppleWebToken: in backoff until $_backoffUntil');
      return null;
    }

    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;

    try {
      // Step 1: GET https://music.apple.com/us/browse
      final browseUri = Uri.parse('https://music.apple.com/us/browse');
      final browseRes = await httpClient
          .get(
            browseUri,
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36',
              'Accept':
                  'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (browseRes.statusCode != 200) {
        _setBackoff();
        return null;
      }

      // Step 2: Extract index JS script path
      final scriptRegex = RegExp(
        r'''/(?:assets/index(?:-legacy)?(?:[~-][a-zA-Z0-9_\.]*)?\.js)''',
      );
      final match = scriptRegex.firstMatch(browseRes.body);
      String? scriptPath = match?.group(0);
      if (scriptPath == null) {
        final fallbackRegex = RegExp(r'''/assets/index[a-zA-Z0-9_\-\.]*\.js''');
        final fbMatch = fallbackRegex.firstMatch(browseRes.body);
        scriptPath = fbMatch?.group(0);
      }

      if (scriptPath == null) {
        LoggerHelper.write('AppleWebToken: script path not found in HTML');
        _setBackoff();
        return null;
      }

      final scriptUri = Uri.parse('https://music.apple.com$scriptPath');
      final scriptRes = await httpClient
          .get(
            scriptUri,
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36',
              'Accept': '*/*',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (scriptRes.statusCode != 200) {
        _setBackoff();
        return null;
      }

      // Step 3: Extract JWT
      final jwtRegex = RegExp(
        r'''"(ey[a-zA-Z0-9_-]+\.ey[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+)"''',
      );
      final jwtMatches = jwtRegex.allMatches(scriptRes.body);
      String? foundJwt;
      for (final m in jwtMatches) {
        final token = m.group(1);
        if (token != null && token.length > 50) {
          foundJwt = token;
          break;
        }
      }

      if (foundJwt == null) {
        final rawJwt = RegExp(
          r'''ey[a-zA-Z0-9_-]{20,}\.ey[a-zA-Z0-9_-]{20,}\.[a-zA-Z0-9_-]{20,}''',
        );
        foundJwt = rawJwt.firstMatch(scriptRes.body)?.group(0);
      }

      if (foundJwt == null) {
        LoggerHelper.write('AppleWebToken: JWT not found in script');
        _setBackoff();
        return null;
      }

      final exp = _extractExpFromJwt(foundJwt);
      if (exp != null) {
        _expiresAt = DateTime.fromMillisecondsSinceEpoch(
          exp * 1000,
        ).subtract(const Duration(minutes: 1));
      } else {
        _expiresAt = DateTime.now().add(const Duration(hours: 12));
      }

      _cachedToken = foundJwt;
      _backoffUntil = null;
      return _cachedToken;
    } catch (e) {
      LoggerHelper.write('AppleWebToken: error fetching token: $e');
      _setBackoff();
      return null;
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  static void _setBackoff() {
    _backoffUntil = DateTime.now().add(const Duration(minutes: 15));
  }

  static int? _extractExpFromJwt(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length < 2) return null;
      var payload = parts[1];
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final decoded = utf8.decode(base64Url.decode(payload));
      final map = jsonDecode(decoded);
      if (map is Map && map['exp'] is int) {
        return map['exp'] as int;
      }
    } catch (_) {}
    return null;
  }
}
