import 'package:flutter/material.dart';
import 'package:looper_player/features/library/domain/models/models.dart';

/// A coarse bucket of the day, used to group [PlayEvent]s for the "when do
/// you listen most" activity heatmap.
enum DayPart {
  morning, // 05:00 - 11:59
  afternoon, // 12:00 - 16:59
  evening, // 17:00 - 20:59
  night; // 21:00 - 04:59

  static DayPart fromHour(int hour) {
    if (hour >= 5 && hour < 12) return DayPart.morning;
    if (hour >= 12 && hour < 17) return DayPart.afternoon;
    if (hour >= 17 && hour < 21) return DayPart.evening;
    return DayPart.night;
  }

  String get label => switch (this) {
    DayPart.morning => 'Morning',
    DayPart.afternoon => 'Afternoon',
    DayPart.evening => 'Evening',
    DayPart.night => 'Night',
  };
}

/// A single ranked song entry in the "Top Songs" report.
class SongStat {
  final int rank;
  final Song song;
  final int playCount;

  /// Play count relative to the #1 song, in [0, 1] — drives proportional
  /// bar widths in the ranked list.
  final double share;

  const SongStat({
    required this.rank,
    required this.song,
    required this.playCount,
    required this.share,
  });
}

/// A ranked artist entry, aggregated across every song credited to them.
class ArtistStat {
  final int rank;
  final String name;
  final int totalPlays;
  final int songCount;
  final String? imagePath;
  final String? imageUrl;
  final double share;

  const ArtistStat({
    required this.rank,
    required this.name,
    required this.totalPlays,
    required this.songCount,
    required this.share,
    this.imagePath,
    this.imageUrl,
  });
}

/// A ranked album entry, aggregated across its tracks.
class AlbumStat {
  final int rank;
  final String name;
  final String? artist;
  final int totalPlays;
  final int songCount;
  final String? artPath;
  final double share;

  const AlbumStat({
    required this.rank,
    required this.name,
    required this.totalPlays,
    required this.songCount,
    required this.share,
    this.artist,
    this.artPath,
  });
}

/// A genre slice for the donut breakdown, aggregated across its tracks.
class GenreStat {
  final String name;
  final int totalPlays;
  final int songCount;
  final double fraction; // share of totalPlays across all genres, [0, 1]
  final Color color;

  const GenreStat({
    required this.name,
    required this.totalPlays,
    required this.songCount,
    required this.fraction,
    required this.color,
  });

  /// Deterministic, vibrant color derived from the genre name so the same
  /// genre always renders the same color across the donut and its legend —
  /// mirrors the hue-hash trick already used for genre cards in
  /// GenresGridView (lib/ui/screens/android/tabs/views/library_categories_views.dart).
  static Color colorFor(String name) {
    final int hash = name.hashCode;
    final double hue = (hash.abs() % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.65, 0.58).toColor();
  }
}

/// Play count for a single calendar day, used by the listening-trend chart.
class DailyCount {
  final DateTime date; // normalized to midnight, local time
  final int plays;

  const DailyCount({required this.date, required this.plays});
}

/// Play count for one (weekday, day-part) cell of the activity heatmap.
/// [weekday] follows [DateTime.weekday] (1 = Monday .. 7 = Sunday).
class DayPartCount {
  final int weekday;
  final DayPart part;
  final int plays;

  const DayPartCount({
    required this.weekday,
    required this.part,
    required this.plays,
  });
}

/// Current and longest run of consecutive calendar days with at least one
/// play, computed from the [PlayEvent] log.
class StreakInfo {
  final int current;
  final int longest;

  const StreakInfo({required this.current, required this.longest});

  static const zero = StreakInfo(current: 0, longest: 0);
}

/// A fully computed snapshot of everything Looper Analyze shows, derived
/// once per rebuild from the current song library and play-event log. Pure
/// synchronous Dart — no Isar/async calls — so it's cheap to recompute
/// reactively and trivial to unit test.
class AnalyzeSnapshot {
  final int totalPlays;
  final int totalListenedMs;
  final int uniqueSongsPlayed;
  final int totalSongsInLibrary;
  final List<SongStat> topSongs; // capped at 20, rank order
  final List<ArtistStat> topArtists; // capped at 8
  final List<AlbumStat> topAlbums; // capped at 8
  final List<GenreStat> topGenres; // top 6 + rolled-up "Other"
  final List<DailyCount> dailyCounts; // last 30 days, oldest -> newest
  final List<DayPartCount> activityGrid; // 7 weekdays x 4 dayparts
  final StreakInfo streak;

  const AnalyzeSnapshot({
    required this.totalPlays,
    required this.totalListenedMs,
    required this.uniqueSongsPlayed,
    required this.totalSongsInLibrary,
    required this.topSongs,
    required this.topArtists,
    required this.topAlbums,
    required this.topGenres,
    required this.dailyCounts,
    required this.activityGrid,
    required this.streak,
  });

  bool get hasHistory => totalPlays > 0;

  String? get topGenreName =>
      topGenres.isEmpty || topGenres.first.name == 'Other'
      ? null
      : topGenres.first.name;

  static const empty = AnalyzeSnapshot(
    totalPlays: 0,
    totalListenedMs: 0,
    uniqueSongsPlayed: 0,
    totalSongsInLibrary: 0,
    topSongs: [],
    topArtists: [],
    topAlbums: [],
    topGenres: [],
    dailyCounts: [],
    activityGrid: [],
    streak: StreakInfo.zero,
  );

  factory AnalyzeSnapshot.compute({
    required List<Song> songs,
    required List<PlayEvent> events,
    List<Artist> artists = const [],
    String unknownLabel = 'Unknown',
    DateTime? now,
  }) {
    final playedSongs = songs.where((s) => s.playCount > 0).toList()
      ..sort((a, b) => b.playCount.compareTo(a.playCount));

    final totalPlays = songs.fold<int>(0, (sum, s) => sum + s.playCount);
    // Real, tracked listening time - a sum of Song.totalListenedMs, which is
    // topped up from actual mpv playback (see PlaybackNotifier's listen-
    // segment tracking), never assumed from playCount * duration. A song
    // played for 2 seconds then skipped only ever contributes ~2000ms here.
    final totalListenedMs = songs.fold<int>(
      0,
      (sum, s) => sum + s.totalListenedMs,
    );

    final topSongPlayCount = playedSongs.isNotEmpty
        ? playedSongs.first.playCount
        : 0;
    final topSongs = <SongStat>[
      for (var i = 0; i < playedSongs.length && i < 20; i++)
        SongStat(
          rank: i + 1,
          song: playedSongs[i],
          playCount: playedSongs[i].playCount,
          share: topSongPlayCount == 0
              ? 0
              : playedSongs[i].playCount / topSongPlayCount,
        ),
    ];

    final artistImages = <String, Artist>{for (final a in artists) a.name: a};
    final topArtists = _rankBy<ArtistStat>(
      playedSongs,
      keyOf: (s) => s.artist ?? 'Unknown Artist',
      cap: 8,
      build: (name, plays, count, share, rank, sample) => ArtistStat(
        rank: rank,
        name: name,
        totalPlays: plays,
        songCount: count,
        share: share,
        imagePath: sample.artPath,
        imageUrl: artistImages[name]?.artistImageUrl,
      ),
    );

    final topAlbums = _rankBy<AlbumStat>(
      playedSongs,
      keyOf: (s) => s.album ?? 'Unknown Album',
      cap: 8,
      build: (name, plays, count, share, rank, sample) => AlbumStat(
        rank: rank,
        name: name,
        artist: sample.artist,
        totalPlays: plays,
        songCount: count,
        share: share,
        artPath: sample.artPath,
      ),
    );

    final topGenres = _computeGenres(playedSongs, unknownLabel);

    final dailyCounts = _computeDailyCounts(events, now: now);
    final activityGrid = _computeActivityGrid(events);
    final streak = _computeStreak(events, now: now);

    return AnalyzeSnapshot(
      totalPlays: totalPlays,
      totalListenedMs: totalListenedMs,
      uniqueSongsPlayed: playedSongs.length,
      totalSongsInLibrary: songs.length,
      topSongs: topSongs,
      topArtists: topArtists,
      topAlbums: topAlbums,
      topGenres: topGenres,
      dailyCounts: dailyCounts,
      activityGrid: activityGrid,
      streak: streak,
    );
  }

  /// Groups [songs] by a string key, sums their play counts, sorts
  /// descending, and hands each group (plus a representative "sample" song
  /// for art/metadata) to [build]. Shared by the artist/album rankings.
  static List<T> _rankBy<T>(
    List<Song> songs, {
    required String Function(Song) keyOf,
    required int cap,
    required T Function(
      String name,
      int totalPlays,
      int songCount,
      double share,
      int rank,
      Song sample,
    )
    build,
  }) {
    final plays = <String, int>{};
    final counts = <String, int>{};
    final samples = <String, Song>{};
    for (final song in songs) {
      final key = keyOf(song);
      plays[key] = (plays[key] ?? 0) + song.playCount;
      counts[key] = (counts[key] ?? 0) + 1;
      // Prefer a sample that has artwork, for a nicer thumbnail.
      final existing = samples[key];
      if (existing == null ||
          (existing.artPath == null && song.artPath != null)) {
        samples[key] = song;
      }
    }

    final keys = plays.keys.toList()
      ..sort((a, b) => plays[b]!.compareTo(plays[a]!));
    final topPlays = keys.isNotEmpty ? plays[keys.first]! : 0;

    return [
      for (var i = 0; i < keys.length && i < cap; i++)
        build(
          keys[i],
          plays[keys[i]]!,
          counts[keys[i]]!,
          topPlays == 0 ? 0 : plays[keys[i]]! / topPlays,
          i + 1,
          samples[keys[i]]!,
        ),
    ];
  }

  static List<GenreStat> _computeGenres(List<Song> songs, String unknownLabel) {
    final plays = <String, int>{};
    final counts = <String, int>{};
    for (final song in songs) {
      final key = (song.genre == null || song.genre!.trim().isEmpty)
          ? unknownLabel
          : song.genre!;
      plays[key] = (plays[key] ?? 0) + song.playCount;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    if (plays.isEmpty) return [];

    final keys = plays.keys.toList()
      ..sort((a, b) => plays[b]!.compareTo(plays[a]!));
    final totalPlays = plays.values.fold<int>(0, (a, b) => a + b);

    const maxSlices = 6;
    final result = <GenreStat>[];
    var otherPlays = 0;
    var otherSongs = 0;
    for (var i = 0; i < keys.length; i++) {
      final key = keys[i];
      if (i < maxSlices || keys.length == maxSlices + 1) {
        result.add(
          GenreStat(
            name: key,
            totalPlays: plays[key]!,
            songCount: counts[key]!,
            fraction: totalPlays == 0 ? 0 : plays[key]! / totalPlays,
            color: GenreStat.colorFor(key),
          ),
        );
      } else {
        otherPlays += plays[key]!;
        otherSongs += counts[key]!;
      }
    }
    if (otherPlays > 0) {
      result.add(
        GenreStat(
          name: 'Other',
          totalPlays: otherPlays,
          songCount: otherSongs,
          fraction: totalPlays == 0 ? 0 : otherPlays / totalPlays,
          color: Colors.white.withValues(alpha: 0.25),
        ),
      );
    }
    return result;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static List<DailyCount> _computeDailyCounts(
    List<PlayEvent> events, {
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());
    final counts = <DateTime, int>{};
    for (final e in events) {
      final day = _dateOnly(e.playedAt);
      counts[day] = (counts[day] ?? 0) + 1;
    }

    return [
      for (var i = 29; i >= 0; i--)
        DailyCount(
          date: today.subtract(Duration(days: i)),
          plays: counts[today.subtract(Duration(days: i))] ?? 0,
        ),
    ];
  }

  static List<DayPartCount> _computeActivityGrid(List<PlayEvent> events) {
    final grid = <int, int>{}; // key = weekday * 10 + dayPartIndex
    for (final e in events) {
      final part = DayPart.fromHour(e.playedAt.hour);
      final key = e.playedAt.weekday * 10 + part.index;
      grid[key] = (grid[key] ?? 0) + 1;
    }

    return [
      for (var weekday = 1; weekday <= 7; weekday++)
        for (final part in DayPart.values)
          DayPartCount(
            weekday: weekday,
            part: part,
            plays: grid[weekday * 10 + part.index] ?? 0,
          ),
    ];
  }

  static StreakInfo _computeStreak(List<PlayEvent> events, {DateTime? now}) {
    if (events.isEmpty) return StreakInfo.zero;

    final days = events.map((e) => _dateOnly(e.playedAt)).toSet().toList()
      ..sort();

    var longest = 1;
    var run = 1;
    for (var i = 1; i < days.length; i++) {
      if (days[i].difference(days[i - 1]).inDays == 1) {
        run++;
        if (run > longest) longest = run;
      } else {
        run = 1;
      }
    }

    final today = _dateOnly(now ?? DateTime.now());
    final daySet = days.toSet();
    var current = 0;
    var cursor = today;
    // A streak is still "current" if today OR yesterday has a play (so it
    // doesn't reset to 0 the moment midnight passes before today's first
    // listen), then walks backward while consecutive days have a play.
    if (!daySet.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (daySet.contains(cursor)) {
      current++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return StreakInfo(current: current, longest: longest);
  }
}
