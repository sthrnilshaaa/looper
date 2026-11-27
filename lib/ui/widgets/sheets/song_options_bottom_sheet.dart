import 'package:looper_player/ui/widgets/common/queue_add_icon.dart';
import 'package:looper_player/core/motion/app_routes.dart';
import 'package:looper_player/core/utils/responsive.dart';
import 'package:looper_player/core/motion/looper_scroll_physics.dart';
import 'dart:ui';

import 'package:looper_player/core/utils/song_metadata.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:looper_player/ui/widgets/common/app_loading_indicator.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/features/library/presentation/providers/library/library_notifier.dart';
import 'package:looper_player/features/playlists/presentation/screens/playlist_view.dart';
import 'package:looper_player/ui/widgets/common/song_artwork.dart';
import 'package:looper_player/ui/android/widgets/song_details_bottom_sheet.dart';
import 'package:looper_player/ui/android/song_info/song_info_screen.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/ui/android/widgets/premium_section.dart';
import 'package:looper_player/features/playlists/data/services/playlist_service.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/core/providers/providers.dart';
import 'package:looper_player/ui/android/player/equalizer/android_equalizer_screen.dart';
import 'package:looper_player/ui/android/player/expanded/player_style_picker.dart';

// Extracted modular components
import 'package:looper_player/ui/widgets/common/menu_option_tile.dart';
import 'package:looper_player/ui/widgets/sheets/edit_song_sheet.dart';
import 'package:looper_player/ui/widgets/sheets/add_to_playlist_sheet.dart';
import 'package:looper_player/ui/widgets/sheets/sleep_timer_sheet_content.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:looper_player/ui/desktop/equalizer/desktop_equalizer_dialog.dart';

void showSongOptionsBottomSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Song song,
  Playlist? playlist,
  bool showDeleteOption = true,
  bool showRenameOption = true,
  bool showEqualizerAndTechnicalInfoOptions = true,
  // The Now Playing menu (Figma player sheet) applied app-wide to three-dot clicks.
  bool styled = true,
  bool showPlayerStyleOption = false,
}) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    isScrollControlled: true,
    builder: (modalContext) =>
        (styled ? _PlayerSongOptionsSheet.new : _SongOptionsSheetContent.new)(
          song: song,
          playlist: playlist,
          showDeleteOption: showDeleteOption,
          showRenameOption: showRenameOption,
          showEqualizerAndTechnicalInfoOptions:
              showEqualizerAndTechnicalInfoOptions,
          showPlayerStyleOption: showPlayerStyleOption,
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
  final bool showPlayerStyleOption;
  final BuildContext parentContext;

  const _SongOptionsSheetContent({
    required this.song,
    this.playlist,
    required this.showDeleteOption,
    required this.showRenameOption,
    required this.showEqualizerAndTechnicalInfoOptions,
    this.showPlayerStyleOption = false,
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

    showTaskDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                const Icon(
                  LucideIcons.trash2,
                  color: Colors.redAccent,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.deleteSong,
                  style: AppFonts.jostStyle(color: Colors.white),
                ),
              ],
            ),
            content: Text(
              l10n.deleteSongConfirm,
              style: AppFonts.jostStyle(color: Colors.white60, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: isDeleting
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: Text(
                  l10n.cancel,
                  style: AppFonts.jostStyle(color: Colors.white54),
                ),
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
                            content: Text(
                              message,
                              style: AppFonts.jostStyle(color: Colors.white),
                            ),
                            backgroundColor: bgColor,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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

  Future<void> _showPlaylistSelector(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final name = await showAddToPlaylistSheet(context, [song]);
    if (name == null) return;
    scaffoldMessengerKey.currentState?.clearSnackBars();
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(l10n.addedTo(name)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showAlbum = watchShowAlbum(ref);
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final (
      isSleepTimerActive,
      sleepTimerDurationRemaining,
      sleepTimerSongsRemaining,
    ) = ref.watch(
      playbackProvider.select(
        (s) => (
          s.isSleepTimerActive,
          s.sleepTimerDurationRemaining,
          s.sleepTimerSongsRemaining,
        ),
      ),
    );
    final useBlur = settings.sheetShouldBlur;
    final isPureBlack = settings.darkTheme;
    final accentColor = settings.accent;

    // Blur wins over Pure Black, as in AppBottomSheetContainer.
    final sheetBg = useBlur
        ? Colors.black.withValues(alpha: 0.6)
        : (isPureBlack ? Colors.black : const Color(0xFF1E1E1E));

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
                SongArtwork(
                  song: song,
                  size: 52,
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
                        artistAlbumLabel(song, l10n, showAlbum: showAlbum),
                        style: AppFonts.jostStyle(
                          fontSize: 12,
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
              physics: const LooperScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 8.0,
                ),
                child: Builder(
                  builder: (context) {
                    final options = <Widget>[
                      MenuOptionTile(
                        label: l10n.playNext,
                        icon: LucideIcons.playCircle,
                        iconColor: accentColor,
                        onTap: () {
                          AppHaptics.light();
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
                        iconWidget: QueueAddIcon(size: 22, color: accentColor),
                        iconColor: accentColor,
                        onTap: () {
                          AppHaptics.light();
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
                          AppHaptics.light();
                          Navigator.pop(context);
                          _showPlaylistSelector(parentContext, l10n);
                        },
                      ),
                      MenuOptionTile(
                        label: isSleepTimerActive
                            ? l10n.sleepTimerWithRemaining(
                                formatSleepTimerRemaining(
                                  l10n,
                                  durationRemaining:
                                      sleepTimerDurationRemaining,
                                  songsRemaining: sleepTimerSongsRemaining,
                                ),
                              )
                            : l10n.sleepTimer,
                        icon: LucideIcons.timer,
                        iconColor: isSleepTimerActive
                            ? Colors.white70
                            : accentColor,
                        onTap: () {
                          AppHaptics.light();
                          Navigator.pop(context);
                          showSleepTimerBottomSheet(parentContext, ref);
                        },
                      ),
                      MenuOptionTile(
                        label: song.isFavorite
                            ? l10n.removeFromFavorites
                            : l10n.addToFavorites,
                        icon: song.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        iconColor: song.isFavorite
                            ? Colors.redAccent
                            : accentColor,
                        onTap: () {
                          AppHaptics.light();
                          ref
                              .read(libraryProvider.notifier)
                              .toggleFavorite(song);
                          Navigator.pop(context);
                        },
                      ),
                      if (playlist != null)
                        MenuOptionTile(
                          label: l10n.removeFromPlaylist,
                          icon: LucideIcons.trash2,
                          iconColor: Colors.redAccent,
                          onTap: () async {
                            AppHaptics.medium();
                            final messenger = ScaffoldMessenger.of(context);
                            await PlaylistService.removeSongFromPlaylist(
                              playlist!,
                              song,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(l10n.removedFromPlaylist),
                                ),
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
                            AppHaptics.light();
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
                            AppHaptics.light();
                            Navigator.pop(context);
                            if (UiUtils.isDesktop) {
                              showDesktopEqualizer(parentContext);
                              return;
                            }
                            Navigator.push(
                              parentContext,
                              riseRoute(const AndroidEqualizerScreen()),
                            );
                          },
                        ),
                      MenuOptionTile(
                        label: l10n.songDetails,
                        icon: LucideIcons.info,
                        iconColor: accentColor,
                        onTap: () {
                          AppHaptics.light();
                          Navigator.pop(context);
                          showModalBottomSheet(
                            context: context,
                            useRootNavigator: true,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) =>
                                SongDetailsBottomSheet(song: song),
                          );
                        },
                      ),
                      if (showEqualizerAndTechnicalInfoOptions)
                        MenuOptionTile(
                          label: l10n.technicalInfoFrequency,
                          icon: LucideIcons.activity,
                          iconColor: accentColor,
                          onTap: () {
                            AppHaptics.light();
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              riseRoute(SongInfoScreen(song: song)),
                            );
                          },
                        ),
                      MenuOptionTile(
                        label: l10n.share,
                        icon: LucideIcons.share2,
                        iconColor: accentColor,
                        onTap: () {
                          AppHaptics.light();
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
                            AppHaptics.warning();
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
                        children: List.generate(options.length * 2 - 1, (
                          index,
                        ) {
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

    if (useBlur) {
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

/// The Now Playing menu (Figma): a few big tiles up top, full-width rows
/// below and Edit / Delete side by side at the bottom. Same actions as the
/// list sheet it extends.
class _PlayerSongOptionsSheet extends _SongOptionsSheetContent {
  const _PlayerSongOptionsSheet({
    required super.song,
    super.playlist,
    required super.showDeleteOption,
    required super.showRenameOption,
    required super.showEqualizerAndTechnicalInfoOptions,
    super.showPlayerStyleOption,
    required super.parentContext,
  });

  static const _icons = 'assets/icons/player_styles';

  static TextStyle _label(double size) => TextStyle(
    fontFamily: 'Stack Sans Text',
    fontWeight: FontWeight.w500,
    fontSize: size,
    letterSpacing: -0.02 * size,
    color: Colors.white,
  );

  static Widget _svg(String name, {Color? color, double? size}) =>
      SvgPicture.asset(
        '$_icons/$name.svg',
        width: size,
        height: size,
        colorFilter: color == null
            ? null
            : ColorFilter.mode(color, BlendMode.srcIn),
      );

  static Widget _surface({
    required double height,
    required VoidCallback onTap,
    required Widget child,
    BoxBorder? border,
  }) => Material(
    color: Colors.white.withValues(alpha: 0.05),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: border is Border ? border.top : BorderSide.none,
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: SizedBox(height: height, child: child),
    ),
  );

  /// Square-ish tile: icon top left, label bottom left.
  static Widget _gridTile(Widget icon, String label, VoidCallback onTap) =>
      _surface(
        height: 69,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 15, 8, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(height: 12, child: icon),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _label(12),
              ),
            ],
          ),
        ),
      );

  /// Full-width row: icon then label.
  static Widget _rowTile(
    Widget icon,
    String label,
    VoidCallback onTap, {
    BoxBorder? border,
  }) => _surface(
    height: 62,
    onTap: onTap,
    border: border,
    child: Row(
      children: [
        const SizedBox(width: 20),
        SizedBox.square(dimension: 18, child: Center(child: icon)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _label(14),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final (
      isSleepTimerActive,
      sleepTimerDurationRemaining,
      sleepTimerSongsRemaining,
    ) = ref.watch(
      playbackProvider.select(
        (s) => (
          s.isSleepTimerActive,
          s.sleepTimerDurationRemaining,
          s.sleepTimerSongsRemaining,
        ),
      ),
    );
    final playback = ref.read(playbackProvider.notifier);

    void snack(String text) {
      if (!parentContext.mounted) return;
      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
      );
    }

    // Play next takes the grid slot.
    final playNext = _gridTile(
      const Icon(Icons.playlist_play_rounded, size: 16, color: Colors.white),
      l10n.playNext,
      () {
        AppHaptics.light();
        playback.addNext(song);
        Navigator.pop(context);
        snack(l10n.willPlayNext);
      },
    );

    final rows = <Widget>[
      _rowTile(_svg('menu_queue'), l10n.addToQueue, () {
        AppHaptics.light();
        playback.addToQueue(song);
        Navigator.pop(context);
        snack(l10n.addedToQueue);
      }),
      _rowTile(
        _svg(
          'star',
          size: 18,
          color: Colors.white.withValues(alpha: song.isFavorite ? 1 : 0.3),
        ),
        song.isFavorite ? l10n.removeFromFavorites : l10n.addToFavorites,
        () {
          AppHaptics.light();
          ref.read(libraryProvider.notifier).toggleFavorite(song);
          Navigator.pop(context);
        },
      ),
      _rowTile(
        _svg('menu_sleep'),
        isSleepTimerActive
            ? l10n.sleepTimerWithRemaining(
                formatSleepTimerRemaining(
                  l10n,
                  durationRemaining: sleepTimerDurationRemaining,
                  songsRemaining: sleepTimerSongsRemaining,
                ),
              )
            : l10n.sleepTimer,
        () {
          AppHaptics.light();
          Navigator.pop(context);
          showSleepTimerBottomSheet(parentContext, ref);
        },
      ),
      _rowTile(_svg('menu_share'), l10n.share, () {
        AppHaptics.light();
        playback.shareSong(song);
        Navigator.pop(context);
      }),
      if (playlist != null)
        _rowTile(
          const Icon(LucideIcons.listX, size: 18, color: Colors.white),
          l10n.removeFromPlaylist,
          () async {
            AppHaptics.medium();
            await PlaylistService.removeSongFromPlaylist(playlist!, song);
            if (context.mounted) Navigator.pop(context);
            snack(l10n.removedFromPlaylist);
          },
        ),
      if (showEqualizerAndTechnicalInfoOptions)
        _rowTile(
          const Icon(LucideIcons.activity, size: 18, color: Colors.white),
          l10n.technicalInfoFrequency,
          () {
            AppHaptics.light();
            Navigator.pop(context);
            Navigator.push(
              parentContext,
              riseRoute(SongInfoScreen(song: song)),
            );
          },
        ),
      if (showPlayerStyleOption)
        _rowTile(
          const Icon(LucideIcons.layoutTemplate, size: 18, color: Colors.white),
          l10n.playerStyle,
          () {
            AppHaptics.light();
            Navigator.pop(context);
            openPlayerStylePicker(parentContext);
          },
        ),
    ];

    final bool canEdit = showRenameOption;
    final bool canDelete = showDeleteOption;

    final isWide =
        Responsive.isLandscape(MediaQuery.sizeOf(context)) || UiUtils.isDesktop;

    final bool useBlur = ref.watch(
      settingsProvider.select((s) => s.sheetShouldBlur),
    );
    Widget body = Container(
      decoration: BoxDecoration(
        color: useBlur
            ? Colors.black.withValues(alpha: 0.6)
            : const Color(0xFF080808),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 53,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 21, 36, 20),
              child: Row(
                children: [
                  SongArtwork(
                    song: song,
                    size: 52,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final (text, alpha) in [
                          (song.title, 1.0),
                          (artistAlbumLabel(song, l10n, showAlbum: false), 0.3),
                        ])
                          Text(
                            text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              height: 23 / 18,
                              letterSpacing: -0.36,
                              color: Colors.white.withValues(alpha: alpha),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.songDetails,
                    onPressed: () {
                      AppHaptics.light();
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: parentContext,
                        useRootNavigator: true,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) =>
                            SongDetailsBottomSheet(song: song),
                      );
                    },
                    icon: _svg('menu_info'),
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 30),
              color: Colors.white.withValues(alpha: 0.02),
            ),
            Flexible(
              child: SingleChildScrollView(
                physics: const LooperScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 37),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _gridTile(
                            _svg('menu_playlist'),
                            l10n.addToPlaylists,
                            () {
                              AppHaptics.light();
                              Navigator.pop(context);
                              _showPlaylistSelector(parentContext, l10n);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: playNext),
                        if (showEqualizerAndTechnicalInfoOptions) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: _gridTile(
                              _svg('menu_eq'),
                              l10n.equalizer,
                              () {
                                AppHaptics.light();
                                Navigator.pop(context);
                                if (UiUtils.isDesktop) {
                                  showDesktopEqualizer(parentContext);
                                  return;
                                }
                                Navigator.push(
                                  parentContext,
                                  riseRoute(const AndroidEqualizerScreen()),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                    for (final row in rows) ...[
                      const SizedBox(height: 13),
                      row,
                    ],
                    if (canEdit || canDelete) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (canEdit)
                            Expanded(
                              flex: 234,
                              child: _rowTile(
                                _svg('menu_edit'),
                                l10n.editSongInfo,
                                () {
                                  AppHaptics.light();
                                  Navigator.pop(context);
                                  _showEditSongSheet(parentContext, ref);
                                },
                              ),
                            ),
                          if (canEdit && canDelete) const SizedBox(width: 9),
                          if (canDelete)
                            Expanded(
                              flex: 115,
                              child: _rowTile(
                                _svg('menu_delete'),
                                l10n.delete,
                                () {
                                  AppHaptics.warning();
                                  Navigator.pop(context);
                                  _showDeleteDialog(parentContext, ref);
                                },
                                border: Border.all(
                                  color: const Color(0x05FFAAAA),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (useBlur) {
      body = RepaintBoundary(
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: body,
          ),
        ),
      );
    }

    if (isWide) {
      body = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: body,
        ),
      );
    }

    return body;
  }
}
