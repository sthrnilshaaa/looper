import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:metadata_god/metadata_god.dart';

class MetadataService {
  static const MethodChannel _broadcastChannel = MethodChannel(
    'com.looper.player/broadcast',
  );

  static Future<String?> getEmbeddedLyrics(String path) async {
    if (Platform.isAndroid) {
      return await _getLyricsAndroid(path);
    }
    if (Platform.isLinux) {
      return await _getLyricsLinux(path);
    }
    return null;
  }

  static Future<String?> _getLyricsAndroid(String path) async {
    try {
      // See LibraryScanner._fetchNativeEmbeddedPicture's doc comment - same
      // reasoning: this runs inside enrichPendingSongs' batched Future.wait,
      // so one file that hangs the native side here would otherwise stall
      // every song batched after it, not just this one's lyrics.
      final lyrics = await _broadcastChannel
          .invokeMethod<String>('getEmbeddedLyrics', {'path': path})
          .timeout(const Duration(seconds: 6));
      return (lyrics != null && lyrics.isNotEmpty) ? lyrics : null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _getLyricsLinux(String path) async {
    try {
      final result = await Process.run('ffprobe', [
        '-v',
        'quiet',
        '-print_format',
        'json',
        '-show_format',
        path,
      ]);

      if (result.exitCode == 0) {
        final data = jsonDecode(result.stdout);
        return _extractLyricsFromJson(data);
      }
    } catch (_) {}
    return null;
  }

  static String? _extractLyricsFromJson(Map<String, dynamic> data) {
    final tags = data['format']?['tags'];
    if (tags != null) {
      return _extractLyricsFromMap(Map<String, dynamic>.from(tags));
    }
    return null;
  }

  static String? _extractLyricsFromMap(Map<String, dynamic> tags) {
    // Look for common lyrics tags (case-insensitive)
    for (final key in tags.keys) {
      final lowerKey = key.toLowerCase();
      if (lowerKey == 'lyrics' ||
          lowerKey == 'unsync-lyrics' ||
          lowerKey == 'unsyncedlyrics' ||
          lowerKey == 'uslt') {
        return tags[key]?.toString();
      }
    }
    return null;
  }
}
