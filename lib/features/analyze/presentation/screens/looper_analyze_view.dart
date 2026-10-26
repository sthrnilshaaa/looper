import 'package:looper_player/core/motion/looper_scroll_physics.dart';
import 'dart:io';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';
import 'package:looper_player/features/analyze/domain/analyze_models.dart';
import 'package:looper_player/features/analyze/presentation/providers/analyze_notifier.dart';
import 'package:looper_player/features/analyze/presentation/widgets/analyze_activity_heatmap.dart';
import 'package:looper_player/features/analyze/presentation/widgets/analyze_genre_donut.dart';
import 'package:looper_player/features/analyze/presentation/widgets/analyze_hero_card.dart';
import 'package:looper_player/features/analyze/presentation/widgets/analyze_highlights.dart';
import 'package:looper_player/features/analyze/presentation/widgets/analyze_overview.dart';
import 'package:looper_player/features/analyze/presentation/widgets/analyze_top_albums_section.dart';
import 'package:looper_player/features/analyze/presentation/widgets/analyze_top_artists_section.dart';
import 'package:looper_player/features/analyze/presentation/widgets/analyze_top_songs_section.dart';
import 'package:looper_player/features/analyze/presentation/widgets/analyze_trend_chart.dart';
import 'package:looper_player/features/analyze/presentation/widgets/staggered_reveal.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/ui/android/widgets/premium_section.dart';
import 'package:looper_player/ui/widgets/common/empty_state_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/core/utils/l10n.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';

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
              // The Linux shell already paints the current song's artwork
              // behind every page, so this page adds no background of its own.
              if (!UiUtils.isDesktop)
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
              if (!UiUtils.isDesktop)
                Positioned.fill(
                  child: Container(color: Colors.black.withValues(alpha: 0.72)),
                ),
              if (!UiUtils.isDesktop)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [
                          accent.withValues(alpha: 0.16),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(snapshot: snapshot),
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
  final AnalyzeSnapshot snapshot;
  const _Header({required this.snapshot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          PremiumSection(
            borderRadius: BorderRadius.circular(24),
            width: 48,
            height: 48,
            useExpanded: false,
            forceNoBlur: true,
            onTap: () {
              AppHaptics.light();
              ref.read(appNavigationProvider.notifier).goBack();
            },
            child: const Icon(
              LucideIcons.arrowLeft,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.looperAnalyze,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.jostStyle(
                    color: Colors.white,
                    fontSize: 22,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.jostStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyzeBody extends ConsumerWidget {
  final AnalyzeSnapshot snapshot;
  final Color accent;
  const _AnalyzeBody({required this.snapshot, required this.accent});

  /// Past this width the report splits into two columns (landscape phones,
  /// tablets); below it, one column.
  static const double _twoColumnWidth = 720;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topSong = snapshot.topSongs.isNotEmpty
        ? snapshot.topSongs.first
        : null;

    final lead = <Widget>[
      if (topSong != null)
        AnalyzeHeroCard(
          stat: topSong,
          accent: accent,
          onPlay: () => ref
              .read(playbackProvider.notifier)
              .setPlaylist(snapshot.topSongs.map((s) => s.song).toList()),
        ),
      AnalyzeOverview(snapshot: snapshot, accent: accent),
      AnalyzeHighlights(snapshot: snapshot, accent: accent),
      if (snapshot.topSongs.isNotEmpty)
        AnalyzeTopSongsSection(topSongs: snapshot.topSongs, accent: accent),
    ];
    final rest = <Widget>[
      if (snapshot.topArtists.isNotEmpty)
        AnalyzeTopArtistsSection(
          topArtists: snapshot.topArtists,
          accent: accent,
        ),
      AnalyzeTrendChart(dailyCounts: snapshot.dailyCounts, accent: accent),
      if (snapshot.topGenres.isNotEmpty)
        AnalyzeGenreDonut(genres: snapshot.topGenres),
      if (snapshot.topAlbums.isNotEmpty)
        AnalyzeTopAlbumsSection(topAlbums: snapshot.topAlbums, accent: accent),
      AnalyzeActivityHeatmap(grid: snapshot.activityGrid, accent: accent),
    ];

    Widget column(List<Widget> sections, {int delayOffset = 0}) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < sections.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 26),
            child: StaggeredReveal(
              delay: Duration(milliseconds: 60 * (i + delayOffset)),
              child: sections[i],
            ),
          ),
      ],
    );

    final twoColumns = MediaQuery.sizeOf(context).width >= _twoColumnWidth;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 160),
      physics: const LooperScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      child: twoColumns
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: column(lead)),
                const SizedBox(width: 20),
                Expanded(child: column(rest, delayOffset: 1)),
              ],
            )
          : column([...lead, ...rest]),
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
    // On a desktop window the 80px art is stretched much further than on a
    // phone, so it needs a wider blur and smooth upscaling to not look blocky.
    final desktop = UiUtils.isDesktop;
    final sigma = desktop ? 48.0 : 18.0;
    return RepaintBoundary(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Image.file(
          File(artPath),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          filterQuality: desktop ? FilterQuality.medium : FilterQuality.low,
          cacheWidth: 80,
          cacheHeight: 80,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
