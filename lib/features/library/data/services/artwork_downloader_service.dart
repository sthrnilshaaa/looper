import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:looper_player/core/utils/app_links.dart';
import '../../../../core/services/storage/db_service.dart';
import 'package:isar_community/isar.dart';

class ArtworkDownloaderService {
  static const String iTunesSearchUrl = AppLinks.iTunesSearchUrl;

  /// Standard User-Agent header to prevent CDNs from blocking requests
  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'application/json',
  };

  /// Downloads missing artwork for a single song.
  /// Saves the file to app's album_art directory and returns the local file path.
  Future<String?> downloadArtworkForSong(Song song) async {
    final titleLower = song.title.toLowerCase().trim();
    if (titleLower.isEmpty ||
        titleLower == 'track' ||
        RegExp(r'^track\s*\d+$').hasMatch(titleLower)) {
      return null;
    }

    // 1. Smart Title Cleanup
    String cleanTitle = song.title;
    // Strip common video/audio suffixes like (Official Video), [Official Audio], (Lyrics), etc.
    cleanTitle = cleanTitle.replaceAll(
      RegExp(
        r'\s*[\(\[][^\]\)]*(video|audio|lyrics|official|hq|hd|remastered|feat\.|ft\.)[^\]\)]*[\)\]]',
        caseSensitive: false,
      ),
      '',
    );
    // Replace underscores and dashes with spaces for better matching
    cleanTitle = cleanTitle.replaceAll('_', ' ').replaceAll('-', ' ');
    // Remove extra spaces
    cleanTitle = cleanTitle.replaceAll(RegExp(r'\s+'), ' ').trim();

    // 2. Smart Artist Filter
    String query;
    if (song.artist == null ||
        song.artist!.isEmpty ||
        song.artist!.toLowerCase() == 'unknown artist' ||
        song.artist!.toLowerCase() == 'unknown') {
      query = cleanTitle;
    } else {
      query = '${song.artist} $cleanTitle';
    }

    try {
      final url = Uri.parse(iTunesSearchUrl).replace(
        queryParameters: {'term': query, 'limit': '1', 'media': 'music'},
      );

      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final result = data['results'][0];
          // Get high-res artwork URL (convert 100x100bb to 600x600bb)
          String? imageUrl = result['artworkUrl100'];
          if (imageUrl != null) {
            imageUrl = imageUrl.replaceAll('100x100bb', '600x600bb');

            return await _downloadAndSaveArt(song.album ?? 'unknown', imageUrl);
          }
        } else {}
      } else {}
    } catch (e) {}
    return null;
  }

  /// Downloads missing artwork for all songs in the database.
  /// Runs asynchronously.
  Future<void> downloadAllMissingArtworks() async {
    try {
      // Find all songs where artPath is null or empty
      final songsWithMissingArt = await DbService.isar.songs
          .filter()
          .artPathIsNull()
          .or()
          .artPathEqualTo('')
          .findAll();

      if (songsWithMissingArt.isEmpty) {
        return;
      }

      int downloadCount = 0;
      for (final song in songsWithMissingArt) {
        // Check if downloadArtwork setting is still enabled during execution
        final settings = await DbService.isar.appSettings.get(0);
        if (settings == null ||
            !settings.downloadArtwork ||
            !settings.enableInternet) {
          break;
        }

        final artPath = await downloadArtworkForSong(song);
        if (artPath != null) {
          downloadCount++;

          await DbService.isar.writeTxn(() async {
            // Re-fetch to avoid writing stale data
            final freshSong = await DbService.isar.songs.get(song.id);
            if (freshSong != null) {
              freshSong.artPath = artPath;
              await DbService.isar.songs.put(freshSong);
            }

            // Also update associated album & artist
            if (song.album != null) {
              final album = await DbService.isar.albums
                  .filter()
                  .nameEqualTo(song.album!)
                  .findFirst();
              if (album != null &&
                  (album.artPath == null || album.artPath!.isEmpty)) {
                album.artPath = artPath;
                await DbService.isar.albums.put(album);
              }
            }
            if (song.artist != null) {
              final artist = await DbService.isar.artists
                  .filter()
                  .nameEqualTo(song.artist!)
                  .findFirst();
              if (artist != null &&
                  (artist.artPath == null || artist.artPath!.isEmpty)) {
                artist.artPath = artPath;
                await DbService.isar.artists.put(artist);
              }
            }
          });
        }

        // Politeness delay to avoid hitting rate limits
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {}
  }

  Future<String?> _downloadAndSaveArt(String albumName, String url) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final appDir = await getApplicationSupportDirectory();
        final artDir = Directory(p.join(appDir.path, 'album_art'));
        if (!await artDir.exists()) await artDir.create(recursive: true);

        // Sanitize file name
        final safeAlbumName = albumName.replaceAll(RegExp(r'[^\w\s]+'), '');
        final fileName =
            '${safeAlbumName.isEmpty ? 'album' : safeAlbumName}_${url.hashCode}.jpg';
        final file = File(p.join(artDir.path, fileName));
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      } else {}
    } catch (e) {}
    return null;
  }
}
