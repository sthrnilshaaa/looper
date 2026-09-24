import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/ui/widgets/app_loading_indicator.dart';
import 'package:looper_player/core/app_fonts.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/playback/presentation/playback_notifier.dart';
import 'package:looper_player/features/library/presentation/library_notifier.dart';
import 'package:looper_player/features/playlists/presentation/playlist_view.dart';
import 'package:looper_player/ui/widgets/optimized_image.dart';
import 'package:looper_player/ui/screens/android/widgets/song_details_bottom_sheet.dart';
import 'package:looper_player/ui/screens/android/song/song_info_screen.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/core/db_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/ui/screens/android/widgets/premium_section.dart';
import 'package:looper_player/features/playlists/data/playlist_service.dart';
import 'package:looper_player/features/settings/presentation/settings_notifier.dart';
import 'package:looper_player/core/providers.dart';
import 'package:looper_player/ui/screens/android/player/android_equalizer_screen.dart';

// Extracted modular components
import 'package:looper_player/ui/widgets/menu_option_tile.dart';
import 'package:looper_player/ui/widgets/edit_song_sheet.dart';
import 'package:looper_player/ui/widgets/sleep_timer_sheet_content.dart';

void showSongOptionsBottomSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Song song,
  Playlist? playlist,
  bool showDeleteOption = true,
  bool showRenameOption = true,
  bool showEqualizerAndTechnicalInfoOptions = true,
}) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    isScrollControlled: true,
    builder: (modalContext) => _SongOptionsSheetContent(
      song: song,
      playlist: playlist,
      showDeleteOption: showDeleteOption,
      showRenameOption: showRenameOption,
      showEqualizerAndTechnicalInfoOptions: showEqualizerAndTechnicalInfoOptions,
      parentContext: context,
    ),
  );
}

class _SongOptionsSheetContent extends ConsumerWidget {
  final Song song;
  final Playlist? playlist;
  final bool showDeleteOption;
  final bool showRenameOption;
  final bool showEqualizerAndTechnicalInfoOptions;
  final BuildContext parentContext;

  const _SongOptionsSheetContent({
    required this.song,
    this.playlist,
    required this.showDeleteOption,
    required this.showRenameOption,
    required this.showEqualizerAndTechnicalInfoOptions,
    required this.parentContext,
  });

  /// Shows the advanced Edit Song sheet (bottom sheet).
  void _showEditSongSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      isScrollControlled: true,
      builder: (ctx) => EditSongSheet(song: song),
    );
  }

  /// Shows a confirmation dialog for deleting a song.
  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(playbackProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 22),
                const SizedBox(width: 10),
                Text(l10n.deleteSong, style: AppFonts.jostStyle(color: Colors.white)),
              ],
            ),
            content: Text(
              l10n.deleteSongConfirm,
              style: AppFonts.jostStyle(color: Colors.white60, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(dialogContext),
                child: Text(l10n.cancel, style: AppFonts.jostStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: isDeleting
                    ? null
                    : () async {
                        setDialogState(() => isDeleting = true);
                        final result = await notifier.deleteSong(song);
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        String message;
                        Color bgColor;
                        if (result == FileActionResult.success) {
                          message = l10n.songDeletedSuccess;
                          bgColor = Colors.green.shade800;
                        } else if (result == FileActionResult.dbOnly) {
                          message = l10n.songDeletedDbOnly;
                          bgColor = Colors.orange.shade800;
                        } else {
                          message = l10n.songDeleteFailed;
                          bgColor = Colors.red.shade800;
                        }
                        scaffoldMessengerKey.currentState?.clearSnackBars();
                        scaffoldMessengerKey.currentState?.showSnackBar(
                          SnackBar(
                            content: Text(message,
                                style: AppFonts.jostStyle(color: Colors.white)),
                            backgroundColor: bgColor,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isDeleting
                    ? const AppLoadingIndicator(size: 36)
                    : Text(l10n.delete),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPlaylistSelector(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final playlists = ref.watch(playlistProvider);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).colorScheme.surfaceContainer,
        title: Text('${l10n.addToFavorites.split(' ')[0]} ${l10n.playlists}'),
        content: playlists.isEmpty
            ? Text(l10n.noPlaylistsCreated)
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (dialogContext, index) {
                    final p = playlists[index];
                    return ListTile(
                      leading: const Icon(LucideIcons.listMusic),
                      title: Text(p.name),
                      onTap: () async {
                        if (!p.songPaths.contains(song.path)) {
                          p.songPaths = [...p.songPaths, song.path];
                          p.dateModified = DateTime.now();
                          await DbService.isar.writeTxn(
                            () => DbService.isar.playlists.put(p),
                          );
                        }
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                          scaffoldMessengerKey.currentState?.clearSnackBars();
                          scaffoldMessengerKey.currentState?.showSnackBar(
                            SnackBar(
                              content: Text(l10n.addedTo(p.name)),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final (isSleepTimerActive, sleepTimerDurationRemaining, sleepTimerSongsRemaining) =
        ref.watch(
      playbackProvider.select(
        (s) => (
          s.isSleepTimerActive,
          s.sleepTimerDurationRemaining,
          s.sleepTimerSongsRemaining,
        ),
      ),
    );
    final useBlur = settings.alwaysBlurSheets ||
        (!settings.disableBlur && settings.enableDynamicTheming);
    final isPureBlack = settings.darkTheme;
    final accentColor = Color(settings.accentColor);

    final sheetBg = isPureBlack
        ? Colors.black
        : (useBlur ? Colors.black.withValues(alpha: 0.6) : const Color(0xFF1E1E1E));

    Widget sheetContent = Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
            child: Row(
              children: [
                OptimizedImage(
                  imagePath: song.artPath,
                  width: 52,
                  height: 52,
                  borderRadius: BorderRadius.circular(12),
                  placeholder: Container(
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.music, color: Colors.white54),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: AppFonts.jostStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist ?? l10n.unknownArtist,
                        style: AppFonts.jostStyle(
                          fontSize: 13,
                          color: Colors.white54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Builder(
                  builder: (context) {
                    final options = <Widget>[
                      MenuOptionTile(
                        label: l10n.playNext,
                        icon: LucideIcons.playCircle,
                        iconColor: accentColor,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ref.read(playbackProvider.notifier).addNext(song);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.willPlayNext),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      MenuOptionTile(
                        label: l10n.addToQueue,
                        icon: LucideIcons.listPlus,
                        iconColor: accentColor,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ref.read(playbackProvider.notifier).addToQueue(song);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.addedToQueue),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      MenuOptionTile(
                        label: l10n.addToPlaylists,
                        icon: LucideIcons.listMusic,
                        iconColor: accentColor,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                          _showPlaylistSelector(parentContext, ref, l10n);
                        },
                      ),
                      MenuOptionTile(
                        label: isSleepTimerActive
                            ? 'Sleep Timer (${formatSleepTimerRemaining(
                                durationRemaining: sleepTimerDurationRemaining,
                                songsRemaining: sleepTimerSongsRemaining,
                              )})'
                            : 'Sleep Timer',
                        icon: LucideIcons.timer,
                        iconColor: isSleepTimerActive ? Colors.white70 : accentColor,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                          showSleepTimerBottomSheet(parentContext, ref);
                        },
                      ),
                      MenuOptionTile(
                        label: song.isFavorite ? l10n.removeFromFavorites : l10n.addToFavorites,
                        icon: song.isFavorite ? Icons.favorite : Icons.favorite_border,
                        iconColor: song.isFavorite ? Colors.redAccent : accentColor,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ref.read(libraryProvider.notifier).toggleFavorite(song);
                          Navigator.pop(context);
                        },
                      ),
                      if (playlist != null)
                        MenuOptionTile(
                          label: l10n.removeFromPlaylist,
                          icon: LucideIcons.trash2,
                          iconColor: Colors.redAccent,
                          onTap: () async {
                            HapticFeedback.mediumImpact();
                            final messenger = ScaffoldMessenger.of(context);
                            await PlaylistService.removeSongFromPlaylist(playlist!, song);
                            if (context.mounted) {
                              Navigator.pop(context);
                              messenger.showSnackBar(
                                SnackBar(content: Text(l10n.removedFromPlaylist)),
                              );
                            }
                          },
                        ),
                      if (showRenameOption)
                        MenuOptionTile(
                          label: l10n.editSongInfo,
                          icon: LucideIcons.edit3,
                          iconColor: accentColor,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                            _showEditSongSheet(parentContext, ref);
                          },
                        ),
                      if (showEqualizerAndTechnicalInfoOptions)
                        MenuOptionTile(
                          label: l10n.equalizer,
                          icon: LucideIcons.sliders,
                          iconColor: accentColor,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                            Navigator.push(
                              parentContext,
                              MaterialPageRoute(
                                builder: (context) => const AndroidEqualizerScreen(),
                              ),
                            );
                          },
                        ),
                      MenuOptionTile(
                        label: l10n.songDetails,
                        icon: LucideIcons.info,
                        iconColor: accentColor,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                          showModalBottomSheet(
                            context: context,
                            useRootNavigator: true,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => SongDetailsBottomSheet(song: song),
                          );
                        },
                      ),
                      if (showEqualizerAndTechnicalInfoOptions)
                        MenuOptionTile(
                          label: l10n.technicalInfoFrequency,
                          icon: LucideIcons.activity,
                          iconColor: accentColor,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SongInfoScreen(song: song),
                              ),
                            );
                          },
                        ),
                      MenuOptionTile(
                        label: l10n.share,
                        icon: LucideIcons.share2,
                        iconColor: accentColor,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ref.read(playbackProvider.notifier).shareSong(song);
                          Navigator.pop(context);
                        },
                      ),
                      if (showDeleteOption)
                        MenuOptionTile(
                          label: l10n.deleteFile,
                          icon: LucideIcons.trash2,
                          iconColor: Colors.redAccent,
                          onTap: () {
                            HapticFeedback.heavyImpact();
                            Navigator.pop(context);
                            _showDeleteDialog(parentContext, ref);
                          },
                        ),
                    ];

                    return PremiumSection(
                      borderRadius: BorderRadius.circular(20),
                      padding: EdgeInsets.zero,
                      useExpanded: false,
                      backgroundColor: sheetBg,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(options.length * 2 - 1, (index) {
                          if (index.isOdd) {
                            return Divider(
                              height: 1,
                              thickness: 0.8,
                              color: Colors.white.withValues(alpha: 0.04),
                              indent: 20,
                              endIndent: 20,
                            );
                          }
                          return options[index ~/ 2];
                        }),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );

    if (useBlur && !isPureBlack) {
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: sheetContent,
          ),
        ),
      );
    }

    return sheetContent;
  }
}
