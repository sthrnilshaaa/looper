import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import '../../../data/lyrics_cache.dart';
import '../../../data/lyrics_fetcher.dart';
import '../../../data/lyrics_service.dart';
import '../../../data/metadata_service.dart';
import '../../../domain/lyric_models.dart';

part 'lyrics_notifier.g.dart';

class LyricsState {
  final String? rawLrc;
  final bool isLoading;
  final int? songId;
  final List<LyricLine> parsedLines;
  final String? source;

  LyricsState({
    this.rawLrc,
    this.isLoading = false,
    this.songId,
    this.parsedLines = const [],
    this.source,
  });

  LyricsState copyWith({
    String? rawLrc,
    bool? isLoading,
    int? songId,
    List<LyricLine>? parsedLines,
    String? source,
  }) {
    return LyricsState(
      rawLrc: rawLrc ?? this.rawLrc,
      isLoading: isLoading ?? this.isLoading,
      songId: songId ?? this.songId,
      parsedLines: parsedLines ?? this.parsedLines,
      source: source ?? this.source,
    );
  }
}

@Riverpod(keepAlive: true)
class Lyrics extends _$Lyrics {
  @override
  LyricsState build() => LyricsState();

  void fetchForSong(Song song, {bool force = false}) {
    _fetchLyrics(song, force: force);
  }

  Future<void> _fetchLyrics(Song song, {bool force = false}) async {
    if (!force && state.songId == song.id && state.rawLrc != null) return;

    state = LyricsState(
      isLoading: true,
      songId: song.id,
      rawLrc: null,
      parsedLines: [],
      source: null,
    );

    final lrc = await LyricsFetcher.fetchLyrics(song);

    if (state.songId == song.id) {
      _applyLrcToState(song, lrc);
    }
  }

  Future<bool> fetchWithProvider(Song song, String provider) async {
    state = state.copyWith(isLoading: true);

    final artist = (song.artist ?? 'Unknown Artist').trim();
    final title = song.title.trim();

    if (provider.toUpperCase() == 'LOCAL') {
      // 1. Try embedded metadata
      final embeddedLrc = await MetadataService.getEmbeddedLyrics(song.path);
      if (embeddedLrc != null && embeddedLrc.isNotEmpty) {
        final taggedLrc = '[source:embedded]\n$embeddedLrc';
        await LyricsCache.save(artist, title, taggedLrc);
        await DbService.isar.writeTxn(() async {
          final dbSong = await DbService.isar.songs.get(song.id);
          if (dbSong != null) {
            dbSong.lyrics = taggedLrc;
            await DbService.isar.songs.put(dbSong);
          }
        });
        _applyLrcToState(song, taggedLrc);
        return true;
      }

      // 2. Try local sidecar files (.lrc/.txt)
      final songFile = File(song.path);
      final songDir = songFile.parent.path;
      final songBaseName = p.basenameWithoutExtension(song.path);
      final searchPaths = [
        p.join(songDir, '$songBaseName.lrc'),
        p.join(songDir, '$songBaseName.txt'),
        p.join(songDir, 'lyrics', '$songBaseName.lrc'),
        p.join(songDir, 'lyrics', '$songBaseName.txt'),
        p.join(songDir, 'Lyrics', '$songBaseName.lrc'),
      ];

      for (final path in searchPaths) {
        try {
          final file = File(path);
          if (await file.exists()) {
            final content = await file.readAsString();
            if (content.isNotEmpty) {
              final taggedLrc = '[source:local]\n$content';
              await LyricsCache.save(artist, title, taggedLrc);
              await DbService.isar.writeTxn(() async {
                final dbSong = await DbService.isar.songs.get(song.id);
                if (dbSong != null) {
                  dbSong.lyrics = taggedLrc;
                  await DbService.isar.songs.put(dbSong);
                }
              });
              _applyLrcToState(song, taggedLrc);
              return true;
            }
          }
        } catch (_) {}
      }

      state = state.copyWith(isLoading: false);
      return false;
    }

    final service = LyricsService();

    try {
      final response = await service.getLyrics(
        trackName: title,
        artistName: artist,
        albumName: (song.album ?? '').trim(),
        durationSeconds: (song.duration ?? 0) ~/ 1000,
        provider: provider,
      );

      final raw = response?.syncedLyrics ?? response?.plainLyrics;
      if (raw != null && raw.isNotEmpty) {
        final lrc = '[source:${provider.toLowerCase()}]\n$raw';
        await LyricsCache.save(artist, title, lrc);
        await DbService.isar.writeTxn(() async {
          final dbSong = await DbService.isar.songs.get(song.id);
          if (dbSong != null) {
            dbSong.lyrics = lrc;
            await DbService.isar.songs.put(dbSong);
          }
        });
        _applyLrcToState(song, lrc);
        return true;
      }
    } catch (_) {}

    state = state.copyWith(isLoading: false);
    return false;
  }

  Future<void> applyCustomLyrics(Song song, String rawContent) async {
    state = state.copyWith(isLoading: true);
    final artist = (song.artist ?? 'Unknown Artist').trim();
    final title = song.title.trim();
    final lrc = '[source:custom_file]\n$rawContent';

    await LyricsCache.save(artist, title, lrc);
    await DbService.isar.writeTxn(() async {
      final dbSong = await DbService.isar.songs.get(song.id);
      if (dbSong != null) {
        dbSong.lyrics = lrc;
        await DbService.isar.songs.put(dbSong);
      }
    });

    _applyLrcToState(song, lrc);
  }

  void _applyLrcToState(Song song, String? lrc) {
    // Keep cleanLrc nullable -- null means "no lyrics found" and must reach
    // LyricsState.rawLrc as null too (that's what the lyrics screen checks
    // to show its empty state). Defaulting it to '' here used to make every
    // not-found case (offline, no provider match, disabled internet, etc.)
    // render as an empty AdvancedLyricRenderer instead: a blank screen with
    // no "no lyrics found" message at all.
    String? source;
    String? cleanLrc = lrc;
    if (lrc != null && lrc.startsWith('[source:')) {
      final sourceMatch = RegExp(r'^\[source:(.*)\]').firstMatch(lrc);
      if (sourceMatch != null) {
        source = sourceMatch.group(1);
        cleanLrc = lrc.replaceFirst(RegExp(r'^\[source:.*\]\n?'), '');
      }
    }

    final lines = cleanLrc != null
        ? LrcParser.parse(cleanLrc, Duration(milliseconds: song.duration ?? 0))
        : <LyricLine>[];

    // A fresh LyricsState (not copyWith) -- copyWith's null-coalescing
    // pattern can't null out rawLrc once it's set, which would silently
    // resurrect a previous song's lyrics text here.
    state = LyricsState(
      rawLrc: cleanLrc,
      isLoading: false,
      parsedLines: lines,
      source: source,
      songId: song.id,
    );
  }
}

@Riverpod(keepAlive: true)
class LyricsManualScroll extends _$LyricsManualScroll {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

/// Whether the currently active lyric line's row is within the lyrics
/// list's visible viewport right now - kept up to date by
/// AdvancedLyricRenderer. Lets the "re-sync" button (see
/// AndroidLyricsScreen) only show once the user has actually scrolled the
/// active line out of view, instead of on every scroll touch regardless of
/// whether the line ever left the screen.
@Riverpod(keepAlive: true)
class LyricsActiveLineVisible extends _$LyricsActiveLineVisible {
  @override
  bool build() => true;

  void set(bool value) => state = value;
}
