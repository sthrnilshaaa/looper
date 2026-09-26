part of 'collection_detail_view.dart';

extension _CollectionPlaylistOptions on CollectionDetailView {
  void _showPlaylistOptions(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
  ) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      isScrollControlled: true,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        final settings = ref.watch(settingsProvider);
        final useBlur = settings.enableDynamicTheming && !settings.disableBlur;
        final isPureBlack = settings.darkTheme;

        final sheetBg = isPureBlack
            ? Colors.black
            : (useBlur
                  ? Colors.black.withValues(alpha: 0.6)
                  : const Color(0xFF1E1E1E));

        Widget sheetContent = Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isPureBlack
                  ? Colors.white10
                  : Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SafeArea(
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
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.listMusic,
                        size: 24,
                        color: Colors.orangeAccent,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          playlist.name,
                          style: AppFonts.jostStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 8),
                PremiumSection(
                  borderRadius: BorderRadius.circular(20),
                  padding: EdgeInsets.zero,
                  useExpanded: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _showRenameDialog(context, ref, playlist);
                        },
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.edit2,
                                size: 22,
                                color: Colors.greenAccent,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  l10n.renamePlaylist,
                                  style: AppFonts.jostStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Icon(
                                LucideIcons.chevronRight,
                                color: Colors.white.withValues(alpha: 0.9),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(
                        height: 1,
                        thickness: 0.8,
                        color: Colors.white.withValues(alpha: 0.04),
                        indent: 20,
                        endIndent: 20,
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _showDeleteDialog(context, ref, playlist);
                        },
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.trash2,
                                size: 22,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  l10n.deletePlaylist,
                                  style: AppFonts.jostStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Icon(
                                LucideIcons.chevronRight,
                                color: Colors.white.withValues(alpha: 0.9),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );

        if (useBlur && !isPureBlack) {
          return RepaintBoundary(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: sheetContent,
              ),
            ),
          );
        }

        return sheetContent;
      },
    );
  }

  void _showEditAlbumSheet(BuildContext context, WidgetRef ref, Album album) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditAlbumSheet(album: album),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
  ) {
    final controller = TextEditingController(text: playlist.name);
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          title: Text(l10n.renamePlaylist),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: l10n.newPlaylist),
            autofocus: true,
            style: AppFonts.jostStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                if (controller.text.isNotEmpty &&
                    controller.text != playlist.name) {
                  await DbService.isar.writeTxn(() async {
                    playlist.name = controller.text;
                    playlist.dateModified = DateTime.now();
                    await DbService.isar.playlists.put(playlist);
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(l10n.rename),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          title: Text(l10n.deletePlaylist),
          content: Text(l10n.deletePlaylistConfirm(playlist.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                await DbService.isar.writeTxn(
                  () => DbService.isar.playlists.delete(playlist.id),
                );
                Navigator.pop(context); // Close dialog
                ref
                    .read(appNavigationProvider.notifier)
                    .goBack(); // Go back using appNavigationProvider to stay in sync
              },
              child: Text(
                l10n.delete,
                style: AppFonts.jostStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }
}
