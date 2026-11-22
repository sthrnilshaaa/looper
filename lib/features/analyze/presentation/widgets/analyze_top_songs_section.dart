import 'package:looper_player/core/utils/song_metadata.dart';
import 'package:flutter/material.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/analyze/domain/analyze_models.dart';
import 'package:looper_player/features/analyze/presentation/providers/analyze_notifier.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/features/analyze/presentation/widgets/analyze_common.dart';
import 'package:looper_player/ui/widgets/common/song_artwork.dart';
import 'package:looper_player/core/utils/l10n.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';

const List<Color> _rankColors = [
  Color(0xFFFFD54A), // gold
  Color(0xFFD8D8D8), // silver
  Color(0xFFE0A458), // bronze
];

/// The headline "report card" ranking: every played song ordered by play
/// count, with a 10/20 toggle and a fill proportional to the #1 song's plays.
class AnalyzeTopSongsSection extends ConsumerWidget {
  final List<SongStat> topSongs;
  final Color accent;

  const AnalyzeTopSongsSection({
    super.key,
    required this.topSongs,
    required this.accent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limit = ref.watch(analyzeTopSongsLimitProvider);
    final visible = topSongs.take(limit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnalyzeSectionHeader(
          title: context.l10n.topSongs,
          trailing: topSongs.length > 10
              ? _LimitToggle(current: limit, accent: accent)
              : null,
        ),
        AnalyzeCard(
          padding: const EdgeInsets.all(6),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                for (var i = 0; i < visible.length; i++)
                  _TopSongRow(
                    stat: visible[i],
                    accent: accent,
                    onTap: () {
                      AppHaptics.light();
                      ref
                          .read(playbackProvider.notifier)
                          .setPlaylist(
                            topSongs.map((s) => s.song).toList(),
                            initialIndex: i,
                          );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LimitToggle extends ConsumerWidget {
  final int current;
  final Color accent;
  const _LimitToggle({required this.current, required this.accent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget pill(int value) {
      final selected = current == value;
      return GestureDetector(
        onTap: () {
          if (selected) return;
          AppHaptics.selection();
          ref.read(analyzeTopSongsLimitProvider.notifier).set(value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? accent : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$value',
            style: AppFonts.jostStyle(
              color: selected
                  ? Colors.black
                  : Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [pill(10), const SizedBox(width: 4), pill(20)],
      ),
    );
  }
}

class _TopSongRow extends ConsumerWidget {
  final SongStat stat;
  final Color accent;
  final VoidCallback onTap;

  const _TopSongRow({
    required this.stat,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankColor = stat.rank <= 3 ? _rankColors[stat.rank - 1] : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(UiUtils.cardCorner(16)),
        child: Stack(
          children: [
            // Play share vs. the #1 song, drawn as a soft fill behind the
            // row rather than a separate bar under it.
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: stat.share),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, share, _) => FractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: share.clamp(0.0, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        UiUtils.cardCorner(16),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          (rankColor ?? accent).withValues(alpha: 0.03),
                          (rankColor ?? accent).withValues(alpha: 0.10),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 12, 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      '${stat.rank}',
                      textAlign: TextAlign.center,
                      style: AppFonts.jostStyle(
                        color: rankColor ?? Colors.white.withValues(alpha: 0.4),
                        fontSize: rankColor != null ? 17 : 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SongArtwork(
                    song: stat.song,
                    size: 46,
                    borderRadius: BorderRadius.circular(UiUtils.artCorner(11)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          stat.song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.jostStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          artistAlbumLabel(
                            stat.song,
                            context.l10n,
                            showAlbum: watchShowAlbum(ref),
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
                  const SizedBox(width: 10),
                  Text(
                    formatCount(context, stat.playCount),
                    style: AppFonts.jostStyle(
                      color: rankColor ?? accent,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
