import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/l10n.dart';

class QueueView extends ConsumerWidget {
  const QueueView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(playbackProvider.select((s) => s.queue));
    final currentSongPath = ref.watch(
      playbackProvider.select((s) => s.currentSong?.path),
    );
    final l10n = AppLocalizations.of(context)!;

    // Rotate the queue list so that the current song is at the top
    final currentIdx = queue.indexWhere((s) => s.path == currentSongPath);
    final List<Song> displayedQueue;
    if (currentIdx != -1) {
      displayedQueue = [
        ...queue.sublist(currentIdx),
        ...queue.sublist(0, currentIdx),
      ];
    } else {
      displayedQueue = List.from(queue);
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: Platform.isAndroid ? 12 : 24,
          ),
          child: Row(
            children: [
              if (!Platform.isAndroid)
                Text(
                  l10n.playQueue,
                  style: AppFonts.jostStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              const Spacer(),
              if (queue.isNotEmpty)
                TextButton.icon(
                  onPressed: () =>
                      ref.read(playbackProvider.notifier).clearQueue(),
                  icon: const Icon(LucideIcons.trash2, size: 18),
                  label: Text(l10n.clearQueue),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
            ],
          ),
        ),
        Expanded(
          child: displayedQueue.isEmpty
              ? Center(
                  child: Text(
                    l10n.queueIsEmpty,
                    style: AppFonts.jostStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 16,
                    bottom: Platform.isAndroid ? 200 : 16,
                  ),
                  itemCount: displayedQueue.length,
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex == 0) newIndex = 1;
                    ref
                        .read(playbackProvider.notifier)
                        .reorderQueue(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final song = displayedQueue[index];
                    final isCurrent = currentSongPath == song.path;
                    final originalIndex = queue.indexWhere(
                      (s) => s.path == song.path,
                    );

                    return Dismissible(
                      key: ValueKey('queue_view_${song.path}_$index'),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) {
                        ref
                            .read(playbackProvider.notifier)
                            .removeFromQueue(originalIndex);
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        color: Colors.red.withValues(alpha: 0.1),
                        child: const Icon(LucideIcons.x, color: Colors.red),
                      ),
                      child: AnimatedContainer(
                        key: ValueKey('queue_tile_${song.path}_$index'),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: ListTile(
                            leading: OptimizedImage(
                              imagePath: song.artPath,
                              width: 44,
                              height: 44,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            title: Text(
                              song.title,
                              style: AppFonts.jostStyle(
                                fontWeight: isCurrent
                                    ? FontWeight.normal
                                    : FontWeight.normal,
                                color: isCurrent
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              song.artist ?? context.l10n.unknownArtist,
                              style: AppFonts.jostStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: isCurrent
                                ? const Padding(
                                    padding: EdgeInsets.only(right: 20.0),
                                    child: Icon(
                                      LucideIcons.volume2,
                                      color: Colors.yellow,
                                      size: 20,
                                    ),
                                  )
                                : ReorderableDragStartListener(
                                    index: index,
                                    child: const Padding(
                                      padding: EdgeInsets.only(right: 20.0),
                                      child: Icon(
                                        LucideIcons.gripVertical,
                                        size: 24,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                            onTap: () => ref
                                .read(playbackProvider.notifier)
                                .playAtIndex(originalIndex),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
