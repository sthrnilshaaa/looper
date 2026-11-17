import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:looper_player/core/utils/app_links.dart';
import 'package:looper_player/core/services/storage/db_service.dart';

class ArtistImageService {
  static const String baseUrl = AppLinks.deezerApiBase;

  Future<String?> getArtistImage(String artistName) async {
    try {
      final settings = await DbService.isar.appSettings.get(0);
      if (settings != null && !settings.enableInternet) {
        return null;
      }
      final url = Uri.parse(
        '$baseUrl/search/artist',
      ).replace(queryParameters: {'q': artistName, 'limit': '10'});

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['data'];
        if (results is List) {
          final match = bestMatch(
            artistName,
            results.whereType<Map>().map((r) => r['name']?.toString() ?? ''),
          );
          if (match != null) {
            // 1000 px when Deezer has it; picture_big is only 500 px.
            final imageUrl =
                results[match]['picture_xl'] ??
                results[match]['picture_big'] ??
                results[match]['picture_medium'];
            if (imageUrl != null && !isPlaceholderUrl(imageUrl.toString())) {
              return await _downloadAndSaveImage(artistName, imageUrl);
            }
          }
        }
      }
    } catch (e) {}
    return null;
  }

  /// Deezer gives artists without a photo an empty picture hash
  /// (".../images/artist//1000x1000-...jpg"), which serves a grey silhouette.
  static bool isPlaceholderUrl(String url) => url.contains('/artist//');

  /// Whether [path] is a copy of that silhouette saved before
  /// [isPlaceholderUrl] existed (byte sizes of its xl / big / medium JPEGs).
  /// shortcut: matches by size only, switch to a hash if Deezer changes it.
  static Future<bool> isSavedPlaceholder(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return false;
      return const {16802, 5922, 2603}.contains(await file.length());
    } catch (_) {
      return false;
    }
  }

  /// Index of the search result that is actually [artistName], ignoring
  /// case, accents and punctuation, or null. Deezer ranks by popularity, so
  /// its first hit for "Negrita" can be "Le Boy & Negrita"; no picture beats
  /// a wrong one.
  static int? bestMatch(String artistName, Iterable<String> resultNames) {
    final wanted = normalizeName(artistName);
    if (wanted.isEmpty) return null;
    var index = 0;
    for (final name in resultNames) {
      if (normalizeName(name) == wanted) return index;
      index++;
    }
    return null;
  }

  static final _letterOrDigit = RegExp(r'[\p{L}\p{N}]', unicode: true);

  static const _accents = {
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'å': 'a',
    'ç': 'c',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'ì': 'i',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ñ': 'n',
    'ò': 'o',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ø': 'o',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ý': 'y',
    'ÿ': 'y',
  };

  /// Lower case, common accents folded, "&" read as "and", and everything
  /// but letters and digits dropped ("AC/DC" == "ACDC", "Beyoncé" ==
  /// "Beyonce"). Non-Latin letters are kept as they are.
  static String normalizeName(String name) {
    final buffer = StringBuffer();
    for (final rune in name.toLowerCase().replaceAll('&', 'and').runes) {
      final char = String.fromCharCode(rune);
      final folded = _accents[char] ?? char;
      if (_letterOrDigit.hasMatch(folded)) {
        buffer.write(folded);
      }
    }
    return buffer.toString();
  }

  /// Copies a picture the user chose into the app's own folder (the file
  /// picker's copy can be cleaned up by the system) and returns its path.
  /// A fresh name every time, so image caches never show the old picture.
  Future<String?> saveCustomImage(String artistName, String sourcePath) async {
    try {
      final appDir = await getApplicationSupportDirectory();
      final artistDir = Directory(p.join(appDir.path, 'artist_images'));
      if (!await artistDir.exists()) await artistDir.create(recursive: true);
      final safeName = artistName.replaceAll(RegExp(r'[^\w\s]+'), '');
      final extension = p.extension(sourcePath).isEmpty
          ? '.jpg'
          : p.extension(sourcePath);
      final file = File(
        p.join(
          artistDir.path,
          '${safeName}_custom_${DateTime.now().millisecondsSinceEpoch}$extension',
        ),
      );
      await File(sourcePath).copy(file.path);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _downloadAndSaveImage(String artistName, String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final appDir = await getApplicationSupportDirectory();
        final artistDir = Directory(p.join(appDir.path, 'artist_images'));
        if (!await artistDir.exists()) await artistDir.create(recursive: true);

        // A fresh name per download, so a re-fetched picture never shows
        // the cached old one.
        final fileName =
            '${artistName.replaceAll(RegExp(r'[^\w\s]+'), '')}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File(p.join(artistDir.path, fileName));
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      }
    } catch (e) {}
    return null;
  }
}
