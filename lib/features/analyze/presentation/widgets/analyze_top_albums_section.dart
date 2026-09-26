import 'package:flutter/material.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/analyze/domain/analyze_models.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:looper_player/core/utils/l10n.dart';

/// Ranked "Top Albums" carousel — a horizontally scrolling row of cards
/// rather than a plain list, so the report card doesn't read as one long
/// column of identical rows.
class AnalyzeTopAlbumsSection extends StatelessWidget {
  final List<AlbumStat> topAlbums;
  final Color accent;

  const AnalyzeTopAlbumsSection({
    super.key,
    required this.topAlbums,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.topAlbums,
          style: AppFonts.jostStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: topAlbums.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) =>
                _AlbumCard(stat: topAlbums[i], accent: accent),
          ),
        ),
      ],
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final AlbumStat stat;
  final Color accent;
  const _AlbumCard({required this.stat, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 112,
                  height: 112,
                  child: OptimizedImage(imagePath: stat.artPath),
                ),
              ),
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#${stat.rank}',
                    style: AppFonts.jostStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            stat.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.jostStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            stat.artist ?? context.l10n.unknownArtist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.jostStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.play_arrow_rounded, color: accent, size: 14),
              const SizedBox(width: 2),
              Text(
                context.l10n.playsCount(stat.totalPlays),
                style: AppFonts.jostStyle(
                  color: accent,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
