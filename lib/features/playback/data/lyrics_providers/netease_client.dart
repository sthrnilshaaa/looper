import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:looper_player/core/utils/app_links.dart';
import 'package:looper_player/core/utils/logger_helper.dart';

import '../lyrics_formats/krc_lyrics_parser.dart';
import '../lyrics_formats/timed_lyrics.dart';
import 'lyrics_http.dart';
import 'lyrics_query.dart';

/// NetEase Cloud Music: word-timed "YRC" lyrics for much of its catalogue,
/// line-timed LRC for the rest. No account needed for either.
///
/// Flow: `cloudsearch` -> the hit that is this song and this recording
/// (title, artist, length) -> `song/lyric`.
class NetEaseClient {
  static const Map<String, String> _headers = {
    ...LyricsHttp.browserHeaders,
    'Referer': '${AppLinks.neteaseWeb}/',
  };
  static final RegExp _lrcLine = RegExp(
    r'^\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\](.*)$',
  );

  static Future<String?> fetch({
    required String title,
    required String artist,
    String album = '',
    int durationSeconds = 0,
  }) async {
    final cleanTitle = LyricsQuery.cleanTitle(title);
    try {
      final name = LyricsQuery.artistVariants(artist).last;
      final found = await _get('/cloudsearch/pc', {
        's': '$name $cleanTitle',
        'type': '1',
        'limit': '10',
      });
      final songs = found?['result'] is Map
          ? (found!['result'] as Map)['songs']
          : null;
      if (songs is! List) return null;

      // Several entries can be the same recording (single, album,
      // compilation) and not all of them carry lyrics.
      var asked = 0;
      for (final song in songs.whereType<Map>()) {
        final length = song['dt'];
        final same =
            LyricsQuery.sameSong(
              wantTitle: cleanTitle,
              wantArtist: artist,
              title: '${song['name']}',
              artists: [
                for (final a in (song['ar'] is List ? song['ar'] as List : []))
                  if (a is Map) '${a['name']}',
              ],
            ) &&
            LyricsQuery.sameLength(
              length is num ? length / 1000 : null,
              durationSeconds,
            );
        if (!same || song['id'] == null) continue;
        if (asked++ == 2) break;

        final lyric = await _get('/song/lyric', {
          'id': '${song['id']}',
          'lv': '1',
          'yv': '1',
          'tv': '1',
          'rv': '1',
        });
        final lrc = _toLrc(lyric, cleanTitle);
        if (lrc != null) return lrc;
      }
    } catch (e) {
      LyricsHttp.failed();
      LoggerHelper.write('NetEaseClient: lookup failed ($e)');
    }
    return null;
  }

  static String? _toLrc(Map? lyric, String title) {
    String text(String key) =>
        lyric?[key] is Map ? '${(lyric![key] as Map)['lyric'] ?? ''}' : '';

    var lines = KrcLyricsParser.parseYrc(text('yrc'));
    if (lines.isEmpty) lines = _parseLrc(text('lrc'));
    if (lines.isEmpty) return null;
    final clean = withoutCreditLines(lines, title: title);
    final written = TimedLrcWriter.write(clean);
    if (written == null) return null;

    final translations = _parseLrc(text('tlyric'));
    final romanizations = _parseLrc(text('romalrc'));
    if (translations.isEmpty && romanizations.isEmpty) return written;

    return _attachExtras(written, clean, translations, romanizations);
  }

  /// Appends matching [tlyric] / [romalrc] lines with the exact same timestamp
  /// directly after each main line block (standard enhanced-LRC style).
  static String _attachExtras(
    String written,
    List<TimedLyricLine> mainLines,
    List<TimedLyricLine> translations,
    List<TimedLyricLine> romanizations,
  ) {
    final tsMatch = RegExp(r'^\[(\d{1,3}:\d{2}\.\d{3})\]');
    final trByTs = <String, String>{};
    final roByTs = <String, String>{};
    for (final line in mainLines) {
      final ts = TimedLrcWriter.formatTimestamp(line.startMs);
      final tr = _nearestText(translations, line.startMs);
      if (tr != null) trByTs[ts] = tr;
      final ro = _nearestText(romanizations, line.startMs);
      if (ro != null) roByTs[ts] = ro;
    }

    final rawLines = written.split('\n');
    final out = <String>[];
    for (var i = 0; i < rawLines.length; i++) {
      final raw = rawLines[i];
      out.add(raw);
      final m = tsMatch.firstMatch(raw);
      if (m == null) continue;
      final ts = m.group(1)!;
      // Keep [w:], [v:2], [bg:] lines attached to the main line before extras.
      while (i + 1 < rawLines.length &&
          (rawLines[i + 1].startsWith('[w:') ||
              rawLines[i + 1].startsWith('[v:') ||
              rawLines[i + 1].startsWith('[bg:'))) {
        out.add(rawLines[++i]);
      }
      final tr = trByTs.remove(ts);
      if (tr != null) out.add('[$ts]$tr');
      final ro = roByTs.remove(ts);
      if (ro != null) out.add('[$ts]$ro');
    }
    return out.join('\n');
  }

  static String? _nearestText(List<TimedLyricLine> pool, int targetMs) {
    String? best;
    var bestDiff = 250; // NetEase yrc vs tlyric/romalrc can differ by ~100 ms.
    for (final item in pool) {
      final diff = (item.startMs - targetMs).abs();
      if (diff <= bestDiff) {
        bestDiff = diff;
        best = item.text;
      }
    }
    return best;
  }

  static List<TimedLyricLine> _parseLrc(String lrc) {
    final lines = <TimedLyricLine>[];
    for (final raw in lrc.split(RegExp(r'\r?\n'))) {
      final match = _lrcLine.firstMatch(raw.trim());
      final text = match?.group(4)?.trim() ?? '';
      if (match == null || text.isEmpty) continue;
      final fraction = (match.group(3) ?? '0').padRight(3, '0');
      final ms =
          int.parse(match.group(1)!) * 60000 +
          int.parse(match.group(2)!) * 1000 +
          int.parse(fraction);
      lines.add(TimedLyricLine(startMs: ms, endMs: ms, text: text));
    }
    // Untimed text: nothing here to sync to.
    return lines;
  }

  static Future<Map?> _get(String path, Map<String, String> params) async {
    final response = await http
        .get(
          Uri.parse(
            '${AppLinks.neteaseApiBase}$path',
          ).replace(queryParameters: params),
          headers: _headers,
        )
        .timeout(LyricsHttp.timeout);
    if (!LyricsHttp.ok(response.statusCode)) return null;
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return body is Map ? body : null;
  }
}
