import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
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
  String? _initialSongPath;

  @override
  void initState() {
    super.initState();
    _initialSongPath = ref.read(playbackProvider).currentSong?.path;
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(playbackProvider.select((s) => s.queue));
    final currentSongPath = ref.watch(
      playbackProvider.select((s) => s.currentSong?.path),
    );
    final settings = ref.watch(settingsProvider);
    final accentColor = Color(settings.accentColor);
    final l10n = AppLocalizations.of(context)!;

    // Rotate the queue list so that the initial song is at the top,
    // preventing list items from jumping around while the sheet is open.
    final rotationIdx = _initialSongPath != null
        ? queue.indexWhere((s) => s.path == _initialSongPath)
        : -1;

    final List<Song> displayedQueue;
    if (rotationIdx != -1) {
      displayedQueue = [
        ...queue.sublist(rotationIdx),
        ...queue.sublist(0, rotationIdx),
      ];
    } else {
      displayedQueue = List.from(queue);
    }

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
                  '${queue.length} ${l10n.songs.toLowerCase()}',
                  style: AppFonts.jostStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: displayedQueue.length,
              onReorder: (oldIndex, newIndex) {
                ref
                    .read(playbackProvider.notifier)
                    .reorderQueue(
                      oldIndex,
                      newIndex,
                      rotationSongPath: _initialSongPath,
                    );
              },
              itemBuilder: (context, index) {
                final song = displayedQueue[index];
                final isCurrent = currentSongPath == song.path;
                final absoluteIndex = rotationIdx != -1
                    ? (rotationIdx + index) % queue.length
                    : index;

                return Material(
                  key: ValueKey('queue_sheet_${song.path}_$absoluteIndex'),
                  color: Colors.transparent,
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: OptimizedImage(
                        imagePath: song.artPath,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
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
                    subtitle: Text(
                      song.artist ?? context.l10n.unknownArtist,
                      style: AppFonts.jostStyle(color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
