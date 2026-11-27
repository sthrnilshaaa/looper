import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:looper_player/core/utils/app_links.dart';

/// Cooperative cancellation token for a lyrics race. Closing [cancel] aborts
/// any in-flight [LyricsHttp.get] calls and lets callers discard late results.
class LyricsCancelToken {
  bool _cancelled = false;
  final List<void Function()> _listeners = [];

  bool get isCancelled => _cancelled;

  void onCancel(void Function() listener) {
    if (_cancelled) {
      listener();
    } else {
      _listeners.add(listener);
    }
  }

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final listener in List.of(_listeners)) {
      try {
        listener();
      } catch (_) {}
    }
    _listeners.clear();
  }
}

/// Shared request settings for the community lyrics APIs (lrc.red,
/// LyricsPlus). They're free, volunteer-run services: identify the app
/// honestly so operators can reach out, and give up quickly instead of
/// stalling the fallback chain.
class LyricsHttp {
  static const Map<String, String> headers = {
    'User-Agent': 'LooperPlayer (${AppLinks.githubRepo})',
    'Accept': 'application/json, application/ttml+xml, */*',
  };

  /// For the commercial catalogues (NetEase, KuGou), which turn away
  /// clients that don't look like a browser.
  static const Map<String, String> browserHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36',
    'Accept': 'application/json, text/plain, */*',
  };

  static const Duration timeout = Duration(seconds: 6);

  static const Object _reportKey = #lyricsLookupReport;
  static const Object _cancelKey = #lyricsCancelToken;

  /// Runs one provider lookup so that the clients underneath can say it
  /// didn't get through ([failed]) - which a "no lyrics" answer must not be
  /// mistaken for: only a real "no" is remembered for the song.
  static Future<T> tracked<T>(
    LyricsLookupReport report,
    Future<T> Function() lookup, {
    LyricsCancelToken? cancelToken,
  }) => runZoned(
    lookup,
    zoneValues: {
      _reportKey: report,
      _cancelKey: ?cancelToken,
    },
  );

  static bool get isCancelled {
    final token = Zone.current[_cancelKey];
    return token is LyricsCancelToken && token.isCancelled;
  }

  /// HTTP GET that aborts its socket when the active [LyricsCancelToken] is
  /// cancelled.
  static Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final token = Zone.current[_cancelKey];
    if (token is! LyricsCancelToken) {
      return http.get(uri, headers: headers).timeout(timeout ?? LyricsHttp.timeout);
    }
    if (token.isCancelled) {
      throw const SocketException('Lyrics lookup cancelled');
    }
    final client = http.Client();
    token.onCancel(client.close);
    try {
      return await client
          .get(uri, headers: headers)
          .timeout(timeout ?? LyricsHttp.timeout);
    } finally {
      client.close();
    }
  }

  /// Called by a client when its service couldn't be asked properly: a
  /// timeout, no network, a rate limit, a block.
  static void failed() {
    final report = Zone.current[_reportKey];
    if (report is LyricsLookupReport) report.failed = true;
  }

  /// Whether a response is a usable answer. Anything else is "no lyrics",
  /// except the statuses that mean the service turned the request away -
  /// those count as [failed].
  static bool ok(int statusCode, {Map<String, String>? headers}) {
    if (statusCode == 200) return true;
    if (statusCode == 429) {
      final report = Zone.current[_reportKey];
      if (report is LyricsLookupReport) {
        report.rateLimited = true;
        report.retryAfter = _parseRetryAfter(headers);
      }
      failed();
      return false;
    }
    if (statusCode == 401 ||
        statusCode == 403 ||
        statusCode == 408 ||
        statusCode >= 500) {
      failed();
    }
    return false;
  }

  static Duration? _parseRetryAfter(Map<String, String>? headers) {
    if (headers == null) return null;
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == 'retry-after') {
        final seconds = int.tryParse(entry.value.trim());
        if (seconds != null && seconds > 0) {
          return Duration(seconds: seconds);
        }
      }
    }
    return null;
  }
}

/// What [LyricsHttp.tracked] learns about a lookup besides its answer.
class LyricsLookupReport {
  bool failed = false;
  bool rateLimited = false;
  Duration? retryAfter;
}
