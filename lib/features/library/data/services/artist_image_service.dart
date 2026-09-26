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
      ).replace(queryParameters: {'q': artistName, 'limit': '1'});

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && data['data'].isNotEmpty) {
          final imageUrl =
              data['data'][0]['picture_big'] ??
              data['data'][0]['picture_medium'];

          if (imageUrl != null) {
            return await _downloadAndSaveImage(artistName, imageUrl);
          }
        }
      }
    } catch (e) {}
    return null;
  }

  Future<String?> _downloadAndSaveImage(String artistName, String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final appDir = await getApplicationSupportDirectory();
        final artistDir = Directory(p.join(appDir.path, 'artist_images'));
        if (!await artistDir.exists()) await artistDir.create(recursive: true);

        final fileName =
            '${artistName.replaceAll(RegExp(r'[^\w\s]+'), '')}.jpg';
        final file = File(p.join(artistDir.path, fileName));
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      }
    } catch (e) {}
    return null;
  }
}
