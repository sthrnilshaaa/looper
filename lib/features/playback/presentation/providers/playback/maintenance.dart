part of 'playback_notifier.dart';

extension _PlaybackMaintenance on Playback {
  Future<bool> _requestStoragePermissions() async {
    if (!Platform.isAndroid) return true;
    try {
      if (!await Permission.notification.isGranted) {
        await Permission.notification.request();
      }

      final audioStatusBefore = await Permission.audio.status;
      final storageStatusBefore = await Permission.storage.status;

      // Check if we already have permissions
      if (audioStatusBefore.isGranted || storageStatusBefore.isGranted) {
        return true;
      }

      // Request permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.audio,
        Permission.storage,
      ].request();

      final audioStatusAfter =
          statuses[Permission.audio] ?? PermissionStatus.denied;
      final storageStatusAfter =
          statuses[Permission.storage] ?? PermissionStatus.denied;

      return audioStatusAfter.isGranted || storageStatusAfter.isGranted;
    } catch (e) {
      return true; // Fallback to let the app try physical operations
    }
  }

  Future<void> _cleanUpOrphanedArtistsAndAlbums() async {
    try {
      await DbService.isar.writeTxn(() async {
        final remainingSongs = await DbService.isar.songs.where().findAll();
        final activeAlbumNames = remainingSongs.map((s) => s.album).toSet();
        final activeArtistNames = remainingSongs.map((s) => s.artist).toSet();

        final allAlbums = await DbService.isar.albums.where().findAll();
        final albumsToDelete = allAlbums
            .where((a) => !activeAlbumNames.contains(a.name))
            .map((a) => a.id)
            .toList();
        if (albumsToDelete.isNotEmpty) {
          await DbService.isar.albums.deleteAll(albumsToDelete);
        }

        final allArtists = await DbService.isar.artists.where().findAll();
        final artistsToDelete = allArtists
            .where((art) => !activeArtistNames.contains(art.name))
            .map((art) => art.id)
            .toList();
        if (artistsToDelete.isNotEmpty) {
          await DbService.isar.artists.deleteAll(artistsToDelete);
        }
      });
    } catch (e) {}
  }

  void _showErrorSnackBar(
    String defaultMessage,
    String Function(AppLocalizations) getLocalizedMessage,
  ) {
    final context = scaffoldMessengerKey.currentContext;
    String message = defaultMessage;
    if (context != null) {
      try {
        final l10n = AppLocalizations.of(context);
        if (l10n != null) {
          message = getLocalizedMessage(l10n);
        }
      } catch (e) {}
    }

    scaffoldMessengerKey.currentState?.clearSnackBars();
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.redAccent.shade700,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
      ),
    );
  }
}
