import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Paths of the songs still to come, or null when nothing is loaded. Built
/// once per queue change, so rows never scan the queue on a position tick.
final upcomingPathsProvider = Provider<Set<String>?>((ref) {
  final current = ref.watch(
    playbackProvider.select((s) => s.currentSong?.path),
  );
  if (current == null) return null;
  final queue = ref.watch(playbackProvider.select((s) => s.queue));
  final at = queue.indexWhere((s) => s.path == current);
  return {for (final s in queue.skip(at + 1)) s.path};
});

/// A list row's track number. While a song is playing it becomes a button
/// that adds this song to the queue, and removes it on the next tap. The
/// playing song itself keeps its number.
class QueueToggle extends ConsumerWidget {
  const QueueToggle({
    super.key,
    required this.song,
    required this.number,
    required this.width,
    required this.height,
    this.alignment = Alignment.center,
    this.enabled = true,
  });

  final Song song;
  final Widget number;
  final double width;
  final double height;
  final Alignment alignment;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queued = ref.watch(
      upcomingPathsProvider.select((u) => u?.contains(song.path)),
    );
    final isCurrent = ref.watch(
      playbackProvider.select((s) => s.currentSong?.path == song.path),
    );
    if (!enabled || queued == null || isCurrent) {
      return SizedBox(
        width: width,
        height: height,
        child: Align(alignment: alignment, child: number),
      );
    }
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      toggled: queued,
      label: queued ? l10n.removeFromQueue : l10n.addToQueue,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            AppHaptics.light();
            ref.read(playbackProvider.notifier).toggleInQueue(song);
          },
          child: SizedBox(
            width: width,
            height: height,
            child: Align(
              alignment: alignment,
              child: SizedBox(
                width: 20,
                child: Icon(
                  queued ? LucideIcons.listCheck : LucideIcons.listPlus,
                  size: 18,
                  color: queued
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
