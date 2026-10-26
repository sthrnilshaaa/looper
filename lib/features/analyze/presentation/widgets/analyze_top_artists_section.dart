import 'package:looper_player/core/motion/looper_scroll_physics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/l10n.dart';
import 'package:looper_player/features/analyze/domain/analyze_models.dart';
import 'package:looper_player/features/analyze/presentation/widgets/analyze_common.dart';
import 'package:looper_player/features/library/presentation/providers/library/library_notifier.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';

/// Ranked "Top Artists": a carousel of round portraits, each with a ring
/// showing its plays against the #1 artist. Tapping one opens the artist.
class AnalyzeTopArtistsSection extends ConsumerWidget {
  final List<ArtistStat> topArtists;
  final Color accent;

  const AnalyzeTopArtistsSection({
    super.key,
    required this.topArtists,
    required this.accent,
  });

  void _open(WidgetRef ref, BuildContext context, ArtistStat stat) {
    AppHaptics.light();
    final songs = ref
        .read(libraryProvider)
        .songs
        .where((s) => (s.artist ?? 'Unknown Artist') == stat.name)
        .toList();
    final url = stat.imageUrl;
    final isNetwork = url != null && url.startsWith('http');
    ref
        .read(appNavigationProvider.notifier)
        .showCollection(
          title: stat.name,
          subtitle: context.l10n.artist,
          art: url != null && !isNetwork ? url : stat.imagePath,
          imageUrl: isNetwork ? url : null,
          songs: songs,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnalyzeSectionHeader(title: context.l10n.topArtists),
        SizedBox(
          height: 156,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            physics: const LooperScrollPhysics(),
            itemCount: topArtists.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, i) => _ArtistAvatar(
              stat: topArtists[i],
              accent: accent,
              onTap: () => _open(ref, context, topArtists[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArtistAvatar extends StatelessWidget {
  final ArtistStat stat;
  final Color accent;
  final VoidCallback onTap;

  const _ArtistAvatar({
    required this.stat,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final url = stat.imageUrl;
    final isNetwork = url != null && url.startsWith('http');
    final isFirst = stat.rank == 1;

    return SizedBox(
      width: 96,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: stat.share),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, share, _) => SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: share.clamp(0.03, 1.0),
                        strokeWidth: 3,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation(accent),
                      ),
                    ),
                  ),
                  ClipOval(
                    child: SizedBox(
                      width: 82,
                      height: 82,
                      child: OptimizedImage(
                        imageUrl: isNetwork ? url : null,
                        imagePath: url != null && !isNetwork
                            ? url
                            : stat.imagePath,
                        placeholder: Container(
                          color: Colors.white.withValues(alpha: 0.05),
                          child: const Icon(
                            LucideIcons.user,
                            size: 28,
                            color: Colors.white38,
                          ),
                        ),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    bottom: 0,
                    end: 2,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 26),
                      height: 26,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isFirst ? accent : const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: Text(
                        '${stat.rank}',
                        style: AppFonts.jostStyle(
                          color: isFirst
                              ? (accent.computeLuminance() > 0.45
                                    ? Colors.black
                                    : Colors.white)
                              : Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              stat.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppFonts.jostStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              context.l10n.playsCount(stat.totalPlays),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppFonts.jostStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
