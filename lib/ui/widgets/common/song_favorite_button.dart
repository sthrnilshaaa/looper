import 'package:looper_player/core/utils/ui_utils.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:looper_player/core/theme/app_assets.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/core/utils/l10n.dart';
import 'package:looper_player/features/library/presentation/providers/library/library_notifier.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';

final _favoriteProvider = StreamProvider.autoDispose.family<bool, int>(
  (ref, id) => DbService.isar.songs
      .watchObject(id, fireImmediately: true)
      .map((song) => song?.isFavorite ?? false),
);

class SongFavoriteButton extends ConsumerWidget {
  const SongFavoriteButton({super.key, required this.song});

  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorite =
        ref.watch(_favoriteProvider(song.id)).value ?? song.isFavorite;
    // Linux keeps its original red heart; Android uses a star.
    if (UiUtils.isDesktop) {
      return IconButton(
        visualDensity: VisualDensity.compact,
        tooltip: context.l10n.toggleFavorite,
        icon: SvgPicture.asset(
          favorite ? AppAssets.desktopLiked : AppAssets.desktopLike,
          width: 16,
          height: 16,
          colorFilter: ColorFilter.mode(
            favorite ? Colors.red : Colors.white54,
            BlendMode.srcIn,
          ),
        ),
        onPressed: () => _toggle(ref),
      );
    }
    return IconButton(
      tooltip: context.l10n.toggleFavorite,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 32, height: 36),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(
        favorite ? Icons.star_rounded : Icons.star_outline_rounded,
        size: 18,
        color: favorite
            ? Theme.of(context).colorScheme.primary
            : Colors.white.withValues(alpha: 0.5),
      ),
      onPressed: () => _toggle(ref),
    );
  }

  void _toggle(WidgetRef ref) {
    if (ref.read(playbackProvider).currentSong?.path == song.path) {
      ref.read(playbackProvider.notifier).toggleFavorite();
    } else {
      ref.read(libraryProvider.notifier).toggleFavorite(song);
    }
  }
}
