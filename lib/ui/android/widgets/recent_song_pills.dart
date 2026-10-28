import 'package:looper_player/core/motion/looper_scroll_physics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/ui/widgets/common/song_artwork.dart';

import 'premium_section.dart';

/// Recently played songs as tappable pills, in one horizontally scrolling
/// strip of up to two rows (songs alternate between the rows). Tapping a
/// pill plays [songs] from that song. Shared by the home and library tabs,
/// which differ only in [horizontalPadding].
class RecentSongPills extends ConsumerWidget {
  final List<Song> songs;
  final double horizontalPadding;

  const RecentSongPills({
    super.key,
    required this.songs,
    required this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final row1Songs = <Song>[];
    final row2Songs = <Song>[];
    for (int i = 0; i < songs.length; i++) {
      if (i % 2 == 0) {
        row1Songs.add(songs[i]);
      } else {
        row2Songs.add(songs[i]);
      }
    }

    final hasTwoRows = songs.length > 1;

    Widget row(List<Song> rowSongs) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final song in rowSongs) _pill(ref, song, songs.indexOf(song)),
      ],
    );

    return SizedBox(
      height: hasTwoRows ? 100 : 50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const LooperScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            row(row1Songs),
            if (hasTwoRows) ...[const SizedBox(height: 8), row(row2Songs)],
          ],
        ),
      ),
    );
  }

  Widget _pill(WidgetRef ref, Song song, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: PremiumSection(
        borderRadius: BorderRadius.circular(36),
        useExpanded: false,
        onTap: () {
          AppHaptics.light();
          ref
              .read(playbackProvider.notifier)
              .setPlaylist(songs, initialIndex: index);
        },
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SongArtwork(
              song: song,
              size: 24,
              borderRadius: BorderRadius.circular(4),
              indicatorSize: 16,
            ),
            const SizedBox(width: 6),
            Text(
              song.title,
              style: AppFonts.jostStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
