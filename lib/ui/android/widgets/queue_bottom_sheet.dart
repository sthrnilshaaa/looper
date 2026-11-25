import 'package:looper_player/ui/widgets/common/queue_add_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/l10n.dart';
import 'package:looper_player/core/utils/motion.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/related_songs_provider.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/android/widgets/animated_dice_button.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:looper_player/ui/widgets/sheets/app_bottom_sheet.dart';
import 'package:looper_player/ui/widgets/sheets/song_options_bottom_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum _QueueTab { next, related }

class QueueBottomSheet extends ConsumerStatefulWidget {
  const QueueBottomSheet({super.key});

  @override
  ConsumerState<QueueBottomSheet> createState() => _QueueBottomSheetState();
}

class _QueueBottomSheetState extends ConsumerState<QueueBottomSheet>
    with SingleTickerProviderStateMixin {
  String? _initialSongPath;
  bool _isReorderMode = false;
  _QueueTab _currentTab = _QueueTab.next;

  late final AnimationController _shuffleController;
  late final Animation<double> _shuffleAnimation;
  Map<String, int> _previousIndices = {};

  @override
  void initState() {
    super.initState();
    _initialSongPath = ref.read(playbackProvider).currentSong?.path;
    _shuffleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shuffleAnimation = CurvedAnimation(
      parent: _shuffleController,
      curve: Curves.easeOutCubic,
    );
    _shuffleController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _previousIndices.clear();
        });
      }
    });
  }

  @override
  void dispose() {
    _shuffleController.dispose();
    super.dispose();
  }

  void _onShuffleTap(List<Song> currentUpcoming) {
    if (currentUpcoming.length <= 1) return;
    final reduced = Motion.reducedOf(context);
    if (!reduced) {
      _previousIndices = {
        for (int i = 0; i < currentUpcoming.length; i++)
          currentUpcoming[i].path: i,
      };
      _shuffleController.forward(from: 0.0);
    }
    ref
        .read(playbackProvider.notifier)
        .shuffleUpcomingQueue(rotationSongPath: _initialSongPath);
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(playbackProvider.select((s) => s.queue));
    final currentSong = ref.watch(
      playbackProvider.select((s) => s.currentSong),
    );
    final isPlaying = ref.watch(playbackProvider.select((s) => s.isPlaying));
    final settings = ref.watch(settingsProvider);
    final accentColor = settings.accent;
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

    final hasPinnedCard = currentSong != null;
    final List<Song> upcomingQueue = hasPinnedCard && displayedQueue.isNotEmpty
        ? displayedQueue.sublist(1)
        : displayedQueue;

    return AppBottomSheetContainer(
      height: MediaQuery.of(context).size.height * 0.78,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHeaderTabs(
                  context,
                  accentColor: accentColor,
                  upcomingCount: upcomingQueue.length,
                ),
                AnimatedDiceButton(
                  tooltip: l10n.reshuffleQueue,
                  size: 22,
                  color: accentColor,
                  onTap: () {
                    if (_currentTab == _QueueTab.next) {
                      _onShuffleTap(upcomingQueue);
                    } else if (currentSong != null) {
                      ref.invalidate(
                        relatedSongsProvider(
                          RelatedSongQuery.fromSong(currentSong),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          // Pinned Continuation Card for Currently Playing Song
          if (hasPinnedCard) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF282828),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: OptimizedImage(
                        imagePath: currentSong.artPath,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              l10n.nowPlayingAllCaps,
                              style: AppFonts.jostStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentSong.title,
                            style: AppFonts.jostStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentSong.artist ?? context.l10n.unknownArtist,
                            style: AppFonts.jostStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isPlaying ? LucideIcons.pause : LucideIcons.play,
                        color: accentColor,
                        size: 22,
                      ),
                      onPressed: () {
                        ref.read(playbackProvider.notifier).togglePlay();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],

          if (_currentTab == _QueueTab.next) ...[
            // Section Bar: Next in Queue & Reorder Toggle
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.nextInQueue.toUpperCase(),
                    style: AppFonts.jostStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  InkWell(
                    key: const ValueKey('queue_reorder_toggle'),
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      setState(() {
                        _isReorderMode = !_isReorderMode;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _isReorderMode
                            ? accentColor.withOpacity(0.2)
                            : Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isReorderMode
                              ? accentColor
                              : Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.arrowUpDown,
                            size: 13,
                            color: _isReorderMode
                                ? accentColor
                                : Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.reorderQueue,
                            style: AppFonts.jostStyle(
                              color: _isReorderMode
                                  ? accentColor
                                  : Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Upcoming Queue List
            Expanded(
              child: upcomingQueue.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          l10n.queueIsEmpty,
                          style: AppFonts.jostStyle(
                            color: Colors.white38,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  : ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      itemCount: upcomingQueue.length,
                      onReorder: (oldIndex, newIndex) {
                        final oldAbs = hasPinnedCard ? oldIndex + 1 : oldIndex;
                        final newAbs = hasPinnedCard ? newIndex + 1 : newIndex;
                        ref
                            .read(playbackProvider.notifier)
                            .reorderQueue(
                              oldAbs,
                              newAbs,
                              rotationSongPath: _initialSongPath,
                            );
                      },
                      itemBuilder: (context, index) {
                        final song = upcomingQueue[index];
                        final displayedIndex = hasPinnedCard
                            ? index + 1
                            : index;
                        final absoluteIndex = rotationIdx != -1
                            ? (rotationIdx + displayedIndex) % queue.length
                            : displayedIndex;

                        final oldIndex = _previousIndices[song.path];
                        final int delta = oldIndex != null
                            ? (oldIndex - index)
                            : 0;

                        Widget itemTile = Material(
                          color: Colors.transparent,
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: OptimizedImage(
                                imagePath: song.artPath,
                                width: 46,
                                height: 46,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(
                              song.title,
                              style: AppFonts.jostStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              song.artist ?? context.l10n.unknownArtist,
                              style: AppFonts.jostStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: _isReorderMode
                                ? ReorderableDragStartListener(
                                    index: index,
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(
                                        LucideIcons.gripVertical,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(
                                      LucideIcons.ellipsisVertical,
                                      color: Colors.grey,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      showSongOptionsBottomSheet(
                                        context: context,
                                        ref: ref,
                                        song: song,
                                      );
                                    },
                                  ),
                            onTap: () {
                              ref
                                  .read(playbackProvider.notifier)
                                  .playAtIndex(absoluteIndex);
                            },
                          ),
                        );

                        // Animate items gliding from old position to new position on shuffle
                        if (delta != 0 && _shuffleController.isAnimating) {
                          final effectiveDelta = delta.clamp(-5, 5);
                          final double initialDy = effectiveDelta * 64.0;
                          itemTile = AnimatedBuilder(
                            animation: _shuffleAnimation,
                            builder: (context, child) {
                              final t = _shuffleAnimation.value;
                              final double currentDy = initialDy * (1.0 - t);
                              final double opacity = 0.65 + 0.35 * t;
                              return Transform.translate(
                                offset: Offset(0, currentDy),
                                child: Opacity(
                                  opacity: opacity.clamp(0.0, 1.0),
                                  child: child,
                                ),
                              );
                            },
                            child: itemTile,
                          );
                        }

                        return Dismissible(
                          key: ValueKey(
                            'queue_dismiss_${song.path}_$absoluteIndex',
                          ),
                          direction: DismissDirection.horizontal,
                          background: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            color: Colors.red.withOpacity(0.85),
                            child: const Icon(
                              LucideIcons.trash2,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          secondaryBackground: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            color: Colors.red.withOpacity(0.85),
                            child: const Icon(
                              LucideIcons.trash2,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          onDismissed: (_) {
                            ref
                                .read(playbackProvider.notifier)
                                .removeFromQueue(absoluteIndex);
                          },
                          child: itemTile,
                        );
                      },
                    ),
            ),
          ] else ...[
            // Section Bar: Related Tracks
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.relatedLabel.toUpperCase(),
                    style: AppFonts.jostStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Related Songs List
            Expanded(
              child: _buildRelatedSongsList(
                context,
                currentSong: currentSong,
                accentColor: accentColor,
                l10n: l10n,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderTabs(
    BuildContext context, {
    required Color accentColor,
    required int upcomingCount,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final isAccentDark =
        ThemeData.estimateBrightnessForColor(accentColor) == Brightness.dark;
    final selectedTextColor = isAccentDark ? Colors.white : Colors.black;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabPill(
            key: const ValueKey('queue_tab_next'),
            title: l10n.nextLabel,
            badgeCount: upcomingCount,
            isSelected: _currentTab == _QueueTab.next,
            accentColor: accentColor,
            selectedTextColor: selectedTextColor,
            onTap: () {
              if (_currentTab != _QueueTab.next) {
                AppHaptics.light();
                setState(() => _currentTab = _QueueTab.next);
              }
            },
          ),
          _buildTabPill(
            key: const ValueKey('queue_tab_related'),
            title: l10n.relatedLabel,
            isSelected: _currentTab == _QueueTab.related,
            accentColor: accentColor,
            selectedTextColor: selectedTextColor,
            onTap: () {
              if (_currentTab != _QueueTab.related) {
                AppHaptics.light();
                setState(() => _currentTab = _QueueTab.related);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill({
    Key? key,
    required String title,
    int? badgeCount,
    required bool isSelected,
    required Color accentColor,
    required Color selectedTextColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: AppFonts.jostStyle(
                color: isSelected ? selectedTextColor : Colors.white70,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            if (badgeCount != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? selectedTextColor.withOpacity(0.18)
                      : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: AppFonts.jostStyle(
                    color: isSelected ? selectedTextColor : Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedSongsList(
    BuildContext context, {
    required Song? currentSong,
    required Color accentColor,
    required AppLocalizations l10n,
  }) {
    if (currentSong == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
          child: Text(
            l10n.noRelatedTracks,
            style: AppFonts.jostStyle(color: Colors.white38, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final query = RelatedSongQuery.fromSong(currentSong);
    final relatedAsync = ref.watch(relatedSongsProvider(query));

    return relatedAsync.when(
      loading: () => Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
          ),
        ),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
          child: Text(
            l10n.noRelatedTracks,
            style: AppFonts.jostStyle(color: Colors.white38, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (songs) {
        if (songs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
              child: Text(
                l10n.noRelatedTracks,
                style: AppFonts.jostStyle(color: Colors.white38, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return Material(
              color: Colors.transparent,
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: OptimizedImage(
                    imagePath: song.artPath,
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  song.title,
                  style: AppFonts.jostStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  song.artist ?? context.l10n.unknownArtist,
                  style: AppFonts.jostStyle(color: Colors.grey, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: l10n.addToQueue,
                      icon: QueueAddIcon(color: accentColor),
                      onPressed: () {
                        AppHaptics.light();
                        ref.read(playbackProvider.notifier).addToQueue(song);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.addedToQueue),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.ellipsisVertical,
                        color: Colors.grey,
                        size: 18,
                      ),
                      onPressed: () {
                        showSongOptionsBottomSheet(
                          context: context,
                          ref: ref,
                          song: song,
                        );
                      },
                    ),
                  ],
                ),
                onTap: () {
                  AppHaptics.light();
                  ref.read(playbackProvider.notifier).play(song);
                },
              ),
            );
          },
        );
      },
    );
  }
}
