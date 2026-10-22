import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';

import 'linux_tag_reader.dart';

/// Reads embedded tags, cover art and lyrics in pure Dart. Windows only: the
/// scanner falls back to it when metadata_god is unavailable, the same way
/// Linux falls back to [LinuxTagReader] (Windows has no system ffmpeg).
///
/// Every call returns null when the file can't be parsed; only a timeout
/// throws ([TimeoutException]), matching [LinuxTagReader].
class WindowsTagReader {
  static Future<LinuxTags?> read(
    String path, {
    required Duration timeout,
  }) async {
    final metadata = await _parse(path, getImage: false).timeout(timeout);
    if (metadata == null) return null;
    String? text(String? value) {
      final trimmed = value?.trim();
      return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    }

    final genre = metadata.genres
        .map((g) => g.trim())
        .firstWhere((g) => g.isNotEmpty, orElse: () => '');
    return LinuxTags(
      title: text(metadata.title),
      artist: text(metadata.artist),
      album: text(metadata.album),
      genre: genre.isEmpty ? null : genre,
      durationMs: metadata.duration?.inMilliseconds,
      trackNumber: metadata.trackNumber,
      year: metadata.year?.year,
    );
  }

  static Future<Uint8List?> readCover(
    String path, {
    required Duration timeout,
  }) async {
    final metadata = await _parse(path, getImage: true).timeout(timeout);
    final pictures = metadata?.pictures ?? const [];
    for (final picture in pictures) {
      if (picture.bytes.isNotEmpty) return picture.bytes;
    }
    return null;
  }

  static Future<String?> readLyrics(String path) async {
    final lyrics = (await _parse(path, getImage: false))?.lyrics?.trim();
    return (lyrics == null || lyrics.isEmpty) ? null : lyrics;
  }

  /// Parses off the UI isolate; any parse error becomes null.
  static Future<AudioMetadata?> _parse(String path, {required bool getImage}) {
    return Isolate.run(() {
      try {
        return readMetadata(File(path), getImage: getImage);
      } catch (_) {
        return null;
      }
    });
  }
}
