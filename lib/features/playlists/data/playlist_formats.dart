import 'dart:convert';
import 'dart:typed_data';

import 'package:looper_player/features/playlists/data/m3u_parser.dart';
import 'package:xml/xml.dart';

/// Reads the common playlist files into [M3uEntry]s, which [M3uSongMatcher]
/// then matches against the library: M3U / M3U8, PLS, XSPF, WPL, ZPL, SMIL,
/// MPC-HC (MPCPL) and AIMP (AIMPPL / AIMPPL4).
abstract final class PlaylistFormats {
  static const extensions = {
    'm3u',
    'm3u8',
    'pls',
    'xspf',
    'wpl',
    'zpl',
    'smil',
    'smi',
    'mpcpl',
    'aimppl',
    'aimppl4',
  };

  static String _ext(String fileName) {
    final dot = fileName.lastIndexOf('.');
    return dot == -1 ? '' : fileName.substring(dot + 1).toLowerCase();
  }

  static bool isSupported(String fileName) =>
      extensions.contains(_ext(fileName));

  /// The local-file entries of the playlist [bytes] named [fileName], in
  /// order. Network streams are skipped, as in [M3uParser].
  static List<M3uEntry> parse(String fileName, Uint8List bytes) {
    final content = decode(bytes);
    return switch (_ext(fileName)) {
      'pls' => _pls(content),
      'xspf' => _xspf(content),
      'wpl' || 'zpl' || 'smil' || 'smi' => _smil(content),
      'mpcpl' => _mpcpl(content),
      'aimppl' || 'aimppl4' => _aimp(content),
      _ => M3uParser.parse(content),
    };
  }

  /// UTF-16 (AIMP writes it, with a BOM), UTF-8, or Latin-1 for older files.
  static String decode(Uint8List bytes) {
    if (bytes.length >= 2) {
      final le = bytes[0] == 0xFF && bytes[1] == 0xFE;
      final be = bytes[0] == 0xFE && bytes[1] == 0xFF;
      if (le || be) {
        final units = <int>[];
        for (var i = 2; i + 1 < bytes.length; i += 2) {
          units.add(
            le
                ? bytes[i] | (bytes[i + 1] << 8)
                : (bytes[i] << 8) | bytes[i + 1],
          );
        }
        return String.fromCharCodes(units);
      }
    }
    try {
      return utf8.decode(bytes).replaceFirst('\uFEFF', '');
    } on FormatException {
      return latin1.decode(bytes);
    }
  }

  /// A raw location as an entry, through M3U's path rules (file:// URLs,
  /// backslashes, network streams dropped).
  static M3uEntry? _entry(String? location, {String? title, String? artist}) {
    if (location == null || location.trim().isEmpty) return null;
    final parsed = M3uParser.parse(location.trim());
    if (parsed.isEmpty) return null;
    return M3uEntry(path: parsed.first.path, title: title, artist: artist);
  }

  static Iterable<String> _lines(String content) => content
      .split(RegExp(r'\r\n|\r|\n'))
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty);

  /// `File1=...`, `Title1=...`, in the order of their numbers.
  static List<M3uEntry> _pls(String content) {
    final files = <int, String>{};
    final titles = <int, String>{};
    final re = RegExp(r'^(file|title)(\d+)\s*=\s*(.*)$', caseSensitive: false);
    for (final line in _lines(content)) {
      final m = re.firstMatch(line);
      if (m == null) continue;
      final n = int.parse(m.group(2)!);
      (m.group(1)!.toLowerCase() == 'file' ? files : titles)[n] = m.group(3)!;
    }
    final keys = files.keys.toList()..sort();
    return [for (final n in keys) ?_entry(files[n], title: titles[n])];
  }

  static XmlDocument? _xml(String content) {
    try {
      return XmlDocument.parse(content);
    } catch (_) {
      return null;
    }
  }

  static String? _child(XmlElement e, String name) {
    for (final c in e.childElements) {
      if (c.name.local == name) return c.innerText.trim();
    }
    return null;
  }

  /// `<track><location/><title/><creator/></track>`.
  static List<M3uEntry> _xspf(String content) {
    final doc = _xml(content);
    if (doc == null) return const [];
    return [
      for (final track in doc.descendantElements.where(
        (e) => e.name.local == 'track',
      ))
        ?_entry(
          _child(track, 'location'),
          title: _child(track, 'title'),
          artist: _child(track, 'creator'),
        ),
    ];
  }

  /// WPL, ZPL and SMIL: `<media src="..."/>` (or `<audio>` in SMIL).
  static List<M3uEntry> _smil(String content) {
    final doc = _xml(content);
    if (doc == null) return const [];
    return [
      for (final e in doc.descendantElements.where(
        (e) => const {'media', 'audio', 'ref'}.contains(e.name.local),
      ))
        ?_entry(e.getAttribute('src'), title: e.getAttribute('title')),
    ];
  }

  /// MPC-HC: `1,type,0` / `1,filename,C:\a.mp3`, ordered by the number.
  static List<M3uEntry> _mpcpl(String content) {
    final files = <int, String>{};
    final re = RegExp(r'^(\d+),filename,(.*)$', caseSensitive: false);
    for (final line in _lines(content)) {
      final m = re.firstMatch(line);
      if (m != null) files[int.parse(m.group(1)!)] = m.group(2)!;
    }
    final keys = files.keys.toList()..sort();
    return [for (final n in keys) ?_entry(files[n])];
  }

  /// AIMP: after `#-----CONTENT-----#`, one `path|title|artist|...` per
  /// track; `-Group` lines head groups.
  static List<M3uEntry> _aimp(String content) {
    final entries = <M3uEntry>[];
    var inContent = false;
    for (final line in _lines(content)) {
      if (line.startsWith('#-----')) {
        inContent = line.toUpperCase().contains('CONTENT');
        continue;
      }
      if (!inContent || line.startsWith('-')) continue;
      final fields = line.split('|');
      final entry = _entry(
        fields[0],
        title: fields.length > 1 && fields[1].isNotEmpty ? fields[1] : null,
        artist: fields.length > 2 && fields[2].isNotEmpty ? fields[2] : null,
      );
      if (entry != null) entries.add(entry);
    }
    return entries;
  }
}
