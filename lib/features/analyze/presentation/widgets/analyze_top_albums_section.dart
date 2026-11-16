import 'package:looper_player/core/motion/looper_scroll_physics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/analyze/domain/analyze_models.dart';
import 'package:looper_player/features/analyze/presentation/widgets/analyze_common.dart';
import 'package:looper_player/features/library/presentation/providers/library/library_notifier.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:looper_player/core/utils/l10n.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';

/// Ranked "Top Albums" carousel — a horizontally scrolling row of cards
/// rather than a plain list, so the report card doesn't read as one long
/// column of identical rows. Tapping a card opens the album.
class AnalyzeTopAlbumsSection extends ConsumerWidget {
  final List<AlbumStat> topAlbums;
  final Color accent;

  const AnalyzeTopAlbumsSection({
    super.key,
    required this.topAlbums,
    required this.accent,
  });

  void _open(WidgetRef ref, BuildContext context, AlbumStat stat) {
    AppHaptics.light();
    final songs = ref
        .read(libraryProvider)
        .songs
        .where((s) => (s.album ?? 'Unknown Album') == stat.name)
        .toList();
    ref
        .read(appNavigationProvider.notifier)
        .showCollection(
          title: stat.name,
          subtitle: stat.artist ?? context.l10n.unknownArtist,
          art: stat.artPath,
          songs: songs,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnalyzeSectionHeader(title: context.l10n.topAlbums),
        SizedBox(
          height: 206,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            physics: const LooperScrollPhysics(),
            itemCount: topAlbums.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _AlbumCard(
              stat: topAlbums[i],
              accent: accent,
              onTap: () => _open(ref, context, topAlbums[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final AlbumStat stat;
  final Color accent;
  final VoidCallback onTap;
  const _AlbumCard({
    required this.stat,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.055),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 120,
                      height: 120,
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
        ),
      ),
    );
  }
}
