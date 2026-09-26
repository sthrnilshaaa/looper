import 'package:flutter/material.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/analyze/domain/analyze_models.dart';
import 'package:looper_player/ui/android/widgets/premium_section.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:looper_player/core/utils/l10n.dart';

/// Ranked "Top Artists" card: every artist's play count summed across their
/// songs, ordered descending.
class AnalyzeTopArtistsSection extends StatelessWidget {
  final List<ArtistStat> topArtists;
  final Color accent;

  const AnalyzeTopArtistsSection({
    super.key,
    required this.topArtists,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.topArtists,
          style: AppFonts.jostStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        PremiumSection(
          borderRadius: BorderRadius.circular(20),
          padding: EdgeInsets.zero,
          useExpanded: false,
          child: Column(
            children: [
              for (var i = 0; i < topArtists.length; i++) ...[
                _ArtistRow(stat: topArtists[i], accent: accent),
                if (i != topArtists.length - 1)
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

class _ArtistRow extends StatelessWidget {
  final ArtistStat stat;
  final Color accent;
  const _ArtistRow({required this.stat, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${stat.rank}',
              textAlign: TextAlign.center,
              style: AppFonts.jostStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ClipOval(
            child: SizedBox(
              width: 44,
              height: 44,
              child: OptimizedImage(
                imageUrl: stat.imageUrl,
                imagePath: stat.imagePath,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stat.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.jostStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  context.l10n.songsPlayedCount(stat.songCount),
                  style: AppFonts.jostStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _MiniRing(share: stat.share, accent: accent, plays: stat.totalPlays),
        ],
      ),
    );
  }
}

class _MiniRing extends StatelessWidget {
  final double share;
  final int plays;
  final Color accent;
  const _MiniRing({
    required this.share,
    required this.plays,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: share),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, animatedShare, _) => SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: animatedShare.clamp(0.03, 1.0),
              strokeWidth: 3,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(accent),
            ),
            Text(
              '$plays',
              style: AppFonts.jostStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
