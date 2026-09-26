import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/analyze/domain/analyze_models.dart';
import 'package:looper_player/features/analyze/presentation/providers/analyze_notifier.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/ui/android/widgets/premium_section.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:looper_player/core/utils/l10n.dart';

const List<Color> _rankColors = [
  Color(0xFFFFD54A), // gold
  Color(0xFFD8D8D8), // silver
  Color(0xFFE0A458), // bronze
];

/// The headline "report card" ranking: every played song ordered by play
/// count, with a 10/20 toggle and a bar proportional to the #1 song's plays.
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.topSongs,
              style: AppFonts.jostStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            _LimitToggle(current: limit, accent: accent),
          ],
        ),
        const SizedBox(height: 12),
        PremiumSection(
          borderRadius: BorderRadius.circular(20),
          padding: EdgeInsets.zero,
          useExpanded: false,
          child: Column(
            children: [
              for (var i = 0; i < visible.length; i++) ...[
                _TopSongRow(
                  stat: visible[i],
                  accent: accent,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref
                        .read(playbackProvider.notifier)
                        .setPlaylist(
                          topSongs.map((s) => s.song).toList(),
                          initialIndex: i,
                        );
                  },
                ),
                if (i != visible.length - 1)
                  Divider(
                    height: 1,
                    thickness: 0.8,
                    color: Colors.white.withValues(alpha: 0.08),
                    indent: 20,
                    endIndent: 20,
                  ),
              ],
            ],
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
          HapticFeedback.selectionClick();
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

class _TopSongRow extends StatelessWidget {
  final SongStat stat;
  final Color accent;
  final VoidCallback onTap;

  const _TopSongRow({
    required this.stat,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rankColor = stat.rank <= 3 ? _rankColors[stat.rank - 1] : null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 28,
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: OptimizedImage(imagePath: stat.song.artPath),
                  ),
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
                        stat.song.artist ?? context.l10n.unknownArtist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.jostStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${stat.playCount}',
                  style: AppFonts.jostStyle(
                    color: accent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: stat.share),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, animatedShare, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: animatedShare.clamp(0.02, 1.0),
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation(rankColor ?? accent),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
