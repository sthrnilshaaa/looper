import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/l10n.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _cardFill = Color(0x0DFFFFFF);
final _cardRadius = BorderRadius.circular(10);
final _artRadius = BorderRadius.circular(5);

/// Real queue index of row [row] in Up Next, which starts after the current
/// song and wraps around. With no current song ([current] -1) it is [row].
int upNextQueueIndex(int row, int current, int length) =>
    (current + 1 + row) % length;

/// Desktop queue: the current song beside a reorderable Up Next list.
class DesktopQueueView extends ConsumerWidget {
  const DesktopQueueView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final queue = ref.watch(playbackProvider.select((s) => s.queue));
    final currentPath = ref.watch(
      playbackProvider.select((s) => s.currentSong?.path),
    );
    final currentIndex = queue.indexWhere((s) => s.path == currentPath);
    final current = currentIndex < 0 ? null : queue[currentIndex];

    if (queue.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.listMusic,
              size: 40,
              color: Colors.white.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.queueIsEmpty,
              style: AppFonts.jostStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final upNext = _UpNextList(queue: queue, currentIndex: currentIndex);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  l10n.playQueue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.jostStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  l10n.songsCount(queue.length),
                  style: AppFonts.jostStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 14,
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () =>
                    ref.read(playbackProvider.notifier).clearQueue(),
                icon: const Icon(LucideIcons.trash2, size: 16),
                label: Text(l10n.clearQueue),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (current == null) return upNext;
                if (constraints.maxWidth < 760) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _NowPlayingRow(song: current),
                      const SizedBox(height: 12),
                      Expanded(child: upNext),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: (constraints.maxWidth * 0.32).clamp(260.0, 360.0),
                      child: _NowPlayingCard(song: current),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: upNext),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppFonts.jostStyle(
      color: Colors.white.withValues(alpha: 0.5),
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
  );
}

class _NowPlayingCard extends StatelessWidget {
  const _NowPlayingCard({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _cardFill, borderRadius: _cardRadius),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(context.l10n.nowPlaying),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1,
              child: OptimizedImage(
                imagePath: song.artPath,
                borderRadius: _artRadius,
                cacheWidth: 720,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              song.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.jostStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              song.artist ?? context.l10n.unknownArtist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.jostStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NowPlayingRow extends StatelessWidget {
  const _NowPlayingRow({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: _cardFill, borderRadius: _cardRadius),
      child: Row(
        children: [
          OptimizedImage(
            imagePath: song.artPath,
            width: 56,
            height: 56,
            borderRadius: _artRadius,
            cacheWidth: 168,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel(context.l10n.nowPlaying),
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.jostStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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

class _UpNextList extends ConsumerWidget {
  const _UpNextList({required this.queue, required this.currentIndex});

  final List<Song> queue;
  final int currentIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final playback = ref.read(playbackProvider.notifier);
    final hasCurrent = currentIndex >= 0;
    final count = hasCurrent ? queue.length - 1 : queue.length;
    int real(int row) => upNextQueueIndex(row, currentIndex, queue.length);

    return Material(
      color: _cardFill,
      borderRadius: _cardRadius,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _SectionLabel(l10n.nextUp),
          ),
          Expanded(
            child: count == 0
                ? Center(
                    child: Text(
                      l10n.queueIsEmpty,
                      style: AppFonts.jostStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 14,
                      ),
                    ),
                  )
                : ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: count,
                    proxyDecorator: (child, _, _) => Material(
                      color: const Color(0xFF1E1E20),
                      borderRadius: _cardRadius,
                      child: child,
                    ),
                    // reorderQueue takes positions in the list that starts
                    // at the current song, one above these rows.
                    onReorder: (from, to) => playback.reorderQueue(
                      from + (hasCurrent ? 1 : 0),
                      to + (hasCurrent ? 1 : 0),
                    ),
                    itemBuilder: (context, row) {
                      final song = queue[real(row)];
                      return _QueueRow(
                        key: ValueKey('${song.path}_$row'),
                        row: row,
                        song: song,
                        onPlay: () => playback.playAtIndex(real(row)),
                        onRemove: () => playback.removeFromQueue(real(row)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({
    super.key,
    required this.row,
    required this.song,
    required this.onPlay,
    required this.onRemove,
  });

  final int row;
  final Song song;
  final VoidCallback onPlay;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = Colors.white.withValues(alpha: 0.45);
    final ms = song.duration;
    return InkWell(
      onTap: onPlay,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: row,
              child: MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(LucideIcons.gripVertical, size: 16, color: muted),
                ),
              ),
            ),
            const SizedBox(width: 4),
            OptimizedImage(
              imagePath: song.artPath,
              width: 44,
              height: 44,
              borderRadius: _artRadius,
              cacheWidth: 132,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.jostStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    song.artist ?? l10n.unknownArtist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.jostStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (ms != null) ...[
              const SizedBox(width: 12),
              Text(
                UiUtils.formatPlaybackDuration(Duration(milliseconds: ms)),
                style: AppFonts.jostStyle(color: muted, fontSize: 13),
              ),
            ],
            const SizedBox(width: 4),
            IconButton(
              tooltip: l10n.removeFromQueue,
              onPressed: onRemove,
              icon: Icon(LucideIcons.x, size: 16, color: muted),
            ),
          ],
        ),
      ),
    );
  }
}
