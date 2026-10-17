import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/ui/widgets/common/queue_entry_fade.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:looper_player/ui/widgets/sheets/app_bottom_sheet.dart';
import 'package:looper_player/core/theme/app_fonts.dart';

import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/core/utils/l10n.dart';

class QueueBottomSheet extends ConsumerStatefulWidget {
  const QueueBottomSheet({super.key});

  @override
  ConsumerState<QueueBottomSheet> createState() => _QueueBottomSheetState();
}

class _QueueBottomSheetState extends ConsumerState<QueueBottomSheet> {
  int? _initialEntryId;

  @override
  void initState() {
    super.initState();
    final playback = ref.read(playbackProvider);
    if (playback.currentQueueIndex >= 0 &&
        playback.currentQueueIndex < playback.queueEntryIds.length) {
      _initialEntryId = playback.queueEntryIds[playback.currentQueueIndex];
    }
  }

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(
      playbackProvider.select(
        (s) => (
          queue: s.queue,
          ids: s.queueEntryIds,
          manual: s.manualQueueEntryIds,
          index: s.currentQueueIndex,
        ),
      ),
    );
    final queue = playback.queue;
    final accentColor = Color(
      ref.watch(settingsProvider.select((s) => s.accentColor)),
    );
    final l10n = AppLocalizations.of(context)!;
    final anchor = playback.ids.indexOf(_initialEntryId ?? -1);
    // Keep rows still while open, but never present earlier history as upcoming.
    final startIndex = anchor >= 0
        ? anchor
        : playback.index.clamp(0, queue.length);
    final displayedQueue = queue.sublist(startIndex);

    return AppBottomSheetContainer(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.playQueue,
                  style: AppFonts.jostStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${displayedQueue.length} ${l10n.songs.toLowerCase()}',
                  style: AppFonts.jostStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: displayedQueue.isEmpty
                ? Center(
                    child: Text(
                      l10n.queueIsEmpty,
                      style: AppFonts.jostStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    itemCount: displayedQueue.length,
                    onReorder: (oldIndex, newIndex) {
                      ref
                          .read(playbackProvider.notifier)
                          .reorderQueue(
                            startIndex + oldIndex,
                            startIndex + newIndex,
                          );
                    },
                    itemBuilder: (context, index) {
                      final song = displayedQueue[index];
                      final absoluteIndex = startIndex + index;
                      final entryId = playback.ids[absoluteIndex];
                      final isCurrent = absoluteIndex == playback.index;
                      final automatic =
                          !isCurrent && !playback.manual.contains(entryId);

                      return Material(
                        key: ValueKey('queue_sheet_$entryId'),
                        color: Colors.transparent,
                        child: ListTile(
                          leading: QueueEntryFade(
                            automatic: automatic,
                            automaticOpacity: 0.4,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: OptimizedImage(
                                imagePath: song.artPath,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          title: QueueEntryFade(
                            automatic: automatic,
                            automaticOpacity: 0.5,
                            child: Text(
                              song.title,
                              style: AppFonts.jostStyle(
                                color: isCurrent ? accentColor : Colors.white,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          subtitle: QueueEntryFade(
                            automatic: automatic,
                            child: Text(
                              song.artist ?? context.l10n.unknownArtist,
                              style: AppFonts.jostStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          trailing: isCurrent
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.volume2,
                                      color: accentColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        LucideIcons.x,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        ref
                                            .read(playbackProvider.notifier)
                                            .removeFromQueue(absoluteIndex);
                                      },
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        LucideIcons.x,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        ref
                                            .read(playbackProvider.notifier)
                                            .removeFromQueue(absoluteIndex);
                                      },
                                    ),
                                    if (absoluteIndex > playback.index)
                                      ReorderableDragStartListener(
                                        index: index,
                                        child: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(
                                            LucideIcons.gripVertical,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                          onTap: () {
                            ref
                                .read(playbackProvider.notifier)
                                .playAtIndex(absoluteIndex);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
