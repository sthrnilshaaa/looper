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
        final isWide =
            Responsive.isLandscape(MediaQuery.sizeOf(context)) ||
            UiUtils.isDesktop;

        Widget surface({
          required double height,
          required VoidCallback onTap,
          required Widget child,
          BoxBorder? border,
        }) =>
            Material(
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

        Widget gridTile(Widget icon, String label, VoidCallback onTap) =>
            surface(
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
                      style: const TextStyle(
                        fontFamily: 'Stack Sans Text',
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        letterSpacing: -0.24,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );

        Widget rowTile(
          Widget icon,
          String label,
          VoidCallback onTap, {
          BoxBorder? border,
        }) =>
            surface(
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
                      style: const TextStyle(
                        fontFamily: 'Stack Sans Text',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        letterSpacing: -0.28,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );

        Widget body = Container(
          decoration: const BoxDecoration(
            color: Color(0xFF080808),
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
                      PlaylistArtwork(
                        songPaths: playlist.songPaths,
                        coverPath: playlist.coverPath,
                        size: 52,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playlist.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                height: 23 / 18,
                                letterSpacing: -0.36,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              l10n.songsCount(playlist.songPaths.length),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                height: 23 / 18,
                                letterSpacing: -0.36,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                          ],
                        ),
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
                              child: gridTile(
                                const Icon(
                                  LucideIcons.edit2,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                l10n.renamePlaylist,
                                () {
                                  AppHaptics.light();
                                  Navigator.pop(context);
                                  _showRenameDialog(context, ref, playlist);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: gridTile(
                                const Icon(
                                  LucideIcons.image,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                l10n.changePlaylistCover,
                                () {
                                  AppHaptics.light();
                                  Navigator.pop(context);
                                  _pickPlaylistCover(playlist);
                                },
                              ),
                            ),
                          ],
                        ),
                        if (playlist.coverPath != null) ...[
                          const SizedBox(height: 13),
                          rowTile(
                            const Icon(
                              LucideIcons.imageOff,
                              size: 18,
                              color: Colors.white,
                            ),
                            l10n.removePlaylistCover,
                            () {
                              AppHaptics.light();
                              Navigator.pop(context);
                              PlaylistService.setCover(playlist, null);
                            },
                          ),
                        ],
                        const SizedBox(height: 16),
                        rowTile(
                          SvgPicture.asset(
                            'assets/icons/player_styles/menu_delete.svg',
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                          l10n.deletePlaylist,
                          () {
                            AppHaptics.warning();
                            Navigator.pop(context);
                            _showDeleteDialog(context, ref, playlist);
                          },
                          border: Border.all(
                            color: const Color(0x05FFAAAA),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        if (isWide) {
          body = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: body,
            ),
          );
        }

        return body;
      },
    );
  }

  Future<void> _pickPlaylistCover(Playlist playlist) async {
    try {
      final result = await FilePicker.pickFile(type: FileType.image);
      final path = result?.path;
      if (path != null) await PlaylistService.setCover(playlist, path);
    } catch (_) {}
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

  void _showEditArtistSheet(BuildContext context, Artist artist) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditArtistSheet(artist: artist),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
  ) {
    final controller = TextEditingController(text: playlist.name);
    showTaskDialog(
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
    showTaskDialog(
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
                await PlaylistService.deleteCoverFile(playlist.coverPath);
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
