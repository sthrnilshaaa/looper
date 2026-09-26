import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';
import 'package:looper_player/core/utils/responsive.dart';
import 'package:looper_player/features/analyze/domain/analyze_models.dart';
import 'package:looper_player/features/analyze/presentation/providers/analyze_notifier.dart';
import 'package:looper_player/features/analyze/presentation/widgets/analyze_activity_heatmap.dart';
import 'package:looper_player/features/analyze/presentation/widgets/analyze_genre_donut.dart';
import 'package:looper_player/features/analyze/presentation/widgets/analyze_top_albums_section.dart';
import 'package:looper_player/features/analyze/presentation/widgets/analyze_top_artists_section.dart';
import 'package:looper_player/features/analyze/presentation/widgets/analyze_top_songs_section.dart';
import 'package:looper_player/features/analyze/presentation/widgets/analyze_trend_chart.dart';
import 'package:looper_player/features/analyze/presentation/widgets/staggered_reveal.dart';
import 'package:looper_player/features/analyze/presentation/widgets/stat_tile.dart';
import 'package:looper_player/ui/android/widgets/premium_section.dart';
import 'package:looper_player/ui/widgets/common/empty_state_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/core/utils/l10n.dart';

/// Looper Analyze — a personal listening "report card": top played songs,
/// top artists/albums/genres, and time-based insights (trend, streaks,
/// activity pattern) derived from [analyzeSnapshotProvider].
class LooperAnalyzeView extends ConsumerWidget {
  const LooperAnalyzeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(analyzeSnapshotProvider);
    final accent = Theme.of(context).colorScheme.primary;
    final topSong = snapshot.topSongs.isNotEmpty
        ? snapshot.topSongs.first.song
        : null;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop &&
            ref.read(appNavigationProvider).activeItem == NavItem.analyze) {
          ref.read(appNavigationProvider.notifier).goBack();
        }
      },
      child: Material(
        color: Colors.transparent,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Positioned.fill(
                child: topSong?.artPath != null
                    ? _BlurredBackgroundArt(artPath: topSong!.artPath!)
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              accent.withValues(alpha: 0.25),
                              Colors.black,
                            ],
                          ),
                        ),
                      ),
              ),
              Positioned.fill(
                child: Container(color: Colors.black.withValues(alpha: 0.72)),
              ),
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(accent: accent, snapshot: snapshot),
                    Expanded(
                      child: snapshot.hasHistory
                          ? _AnalyzeBody(snapshot: snapshot, accent: accent)
                          : EmptyStateCard(
                              icon: LucideIcons.barChart3,
                              title: context.l10n.noListeningHistoryYet,
                              subtitle: context.l10n.noListeningHistoryYetDesc,
                              accentColor: accent,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  final Color accent;
  final AnalyzeSnapshot snapshot;
  const _Header({required this.accent, required this.snapshot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          PremiumSection(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              bottomLeft: Radius.circular(32),
              topRight: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
            width: 48,
            height: 48,
            useExpanded: false,
            forceNoBlur: true,
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(appNavigationProvider.notifier).goBack();
            },
            child: const Icon(
              LucideIcons.arrowLeft,
              color: Colors.white,
              size: 20,
            ),
          ),
          Column(
            children: [
              Text(
                context.l10n.looperAnalyze,
                style: AppFonts.jostStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              if (snapshot.hasHistory)
                Text(
                  context.l10n.analyzePlaysAndSongs(
                    snapshot.totalPlays,
                    snapshot.uniqueSongsPlayed,
                  ),
                  style: AppFonts.jostStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11.5,
                  ),
                ),
            ],
          ),
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
                topRight: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Icon(LucideIcons.trophy, color: accent, size: 20),
          ),
        ],
      ),
    );
  }
}

class _AnalyzeBody extends StatelessWidget {
  final AnalyzeSnapshot snapshot;
  final Color accent;
  const _AnalyzeBody({required this.snapshot, required this.accent});

  String _formatListeningTime(int ms) {
    final totalMinutes = (ms / 60000).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    // Was a fixed 2 columns regardless of width - on a landscape phone/
    // tablet that leaves 4 needlessly wide tiles instead of using the extra
    // width for more columns. Same target tile width the original 2-column
    // math implied on a portrait phone (~168dp), just computed instead of
    // hardcoded to exactly 2.
    const spacing = 12.0;
    const targetTileWidth = 168.0;
    final availableWidth = MediaQuery.sizeOf(context).width - 32;
    final columns = Responsive.isLandscape(MediaQuery.sizeOf(context))
        ? math.max(
            2,
            ((availableWidth + spacing) / (targetTileWidth + spacing)).floor(),
          )
        : 2;
    final tileWidth = (availableWidth - spacing * (columns - 1)) / columns;

    final sections = <Widget>[
      Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          SizedBox(
            width: tileWidth,
            child: StatTile(
              icon: LucideIcons.play,
              value: snapshot.totalPlays,
              label: context.l10n.totalPlays,
              accent: accent,
            ),
          ),
          SizedBox(
            width: tileWidth,
            child: StatTile(
              icon: LucideIcons.clock,
              value: snapshot.totalListenedMs,
              label: context.l10n.listeningTime,
              accent: accent,
              formatter: _formatListeningTime,
            ),
          ),
          SizedBox(
            width: tileWidth,
            child: StatTile(
              icon: LucideIcons.flame,
              value: snapshot.streak.current,
              label: context.l10n.currentStreakDays,
              accent: accent,
            ),
          ),
          SizedBox(
            width: tileWidth,
            child: StatTile(
              icon: LucideIcons.award,
              value: snapshot.streak.longest,
              label: context.l10n.longestStreakDays,
              accent: accent,
            ),
          ),
        ],
      ),
      if (snapshot.topSongs.isNotEmpty)
        AnalyzeTopSongsSection(topSongs: snapshot.topSongs, accent: accent),
      if (snapshot.topArtists.isNotEmpty)
        AnalyzeTopArtistsSection(
          topArtists: snapshot.topArtists,
          accent: accent,
        ),
      if (snapshot.topAlbums.isNotEmpty)
        AnalyzeTopAlbumsSection(topAlbums: snapshot.topAlbums, accent: accent),
      if (snapshot.topGenres.isNotEmpty)
        AnalyzeGenreDonut(genres: snapshot.topGenres),
      AnalyzeTrendChart(dailyCounts: snapshot.dailyCounts, accent: accent),
      AnalyzeActivityHeatmap(grid: snapshot.activityGrid, accent: accent),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 160),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      children: [
        for (var i = 0; i < sections.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: StaggeredReveal(
              delay: Duration(milliseconds: 60 * i),
              child: sections[i],
            ),
          ),
      ],
    );
  }
}

/// Ambient blurred cover-art background for the #1 top song, giving the
/// report card a personalized feel. Mirrors the blurred-art background
/// already used elsewhere in the app (e.g. the expanded player).
class _BlurredBackgroundArt extends StatelessWidget {
  final String artPath;
  const _BlurredBackgroundArt({required this.artPath});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Image.file(
          File(artPath),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          filterQuality: FilterQuality.low,
          cacheWidth: 80,
          cacheHeight: 80,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
