import 'package:looper_player/core/motion/app_routes.dart';
import 'package:looper_player/core/motion/looper_scroll_physics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/l10n.dart';
import 'package:looper_player/features/playlists/data/services/playlist_service.dart';
import 'package:looper_player/features/playlists/presentation/screens/playlist_view.dart';
import 'package:looper_player/features/playlists/presentation/widgets/playlist_artwork.dart';
import 'package:looper_player/ui/android/widgets/premium_section.dart';
import 'package:looper_player/ui/widgets/sheets/app_bottom_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Picks a playlist for [songs] from a bottom sheet - each playlist with its
/// cover and song count, plus a button to create a new one - and adds them.
/// Returns the playlist's name, or null if the sheet was dismissed.
///
/// [suggestedName] pre-fills the new-playlist name field.
Future<String?> showAddToPlaylistSheet(
  BuildContext context,
  List<Song> songs, {
  String suggestedName = '',
}) async {
  if (songs.isEmpty) return null;
  final choice = await showModalBottomSheet<Object>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddToPlaylistSheet(songs: songs),
  );
  if (choice == null || !context.mounted) return null;

  if (choice is Playlist) {
    await PlaylistService.addSongsToPlaylist(choice, songs);
    return choice.name;
  }

  final name = await _askPlaylistName(context, suggestedName);
  if (name == null || !context.mounted) return null;
  // Playlist names are unique, so "new" with a name already in use adds to
  // that playlist instead of failing.
  final sameName = await DbService.isar.playlists
      .filter()
      .nameEqualTo(name)
      .findFirst();
  if (sameName != null) {
    await PlaylistService.addSongsToPlaylist(sameName, songs);
  } else {
    await PlaylistService.createWithSongs(name, songs);
  }
  return name;
}

/// Popped from the sheet when "New Playlist" is tapped.
const _createNew = Object();

Future<String?> _askPlaylistName(BuildContext context, String suggested) {
  final l10n = context.l10n;
  final controller = TextEditingController(text: suggested)
    ..selection = TextSelection(baseOffset: 0, extentOffset: suggested.length);
  return showTaskDialog<String>(
    context: context,
    builder: (dialogContext) {
      void submit() {
        final name = controller.text.trim();
        if (name.isNotEmpty) Navigator.pop(dialogContext, name);
      }

      return AlertDialog(
        backgroundColor: Theme.of(dialogContext).colorScheme.surfaceContainer,
        title: Text(l10n.newPlaylist),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => submit(),
          decoration: InputDecoration(hintText: l10n.playlistNameHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(onPressed: submit, child: Text(l10n.create)),
        ],
      );
    },
  ).whenComplete(controller.dispose);
}

class _AddToPlaylistSheet extends ConsumerWidget {
  final List<Song> songs;

  const _AddToPlaylistSheet({required this.songs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final playlists = ref.watch(playlistProvider);
    final accent = Theme.of(context).colorScheme.primary;
    final paths = {for (final song in songs) song.path};

    return AppBottomSheetContainer(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.addToPlaylists,
            textAlign: TextAlign.center,
            style: AppFonts.jostStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          PremiumSection(
            borderRadius: BorderRadius.circular(16),
            height: 56,
            useExpanded: false,
            onTap: () {
              AppHaptics.light();
              Navigator.pop(context, _createNew);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.plus, size: 20, color: accent),
                const SizedBox(width: 8),
                Text(
                  l10n.newPlaylist,
                  style: AppFonts.jostStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (playlists.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                l10n.noPlaylistsCreated,
                textAlign: TextAlign.center,
                style: AppFonts.jostStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            )
          else
            // Grows with the list up to about half the screen, then scrolls.
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.5,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const LooperScrollPhysics(),
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  final hasAll = paths.every(playlist.songPaths.contains);
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      AppHaptics.light();
                      Navigator.pop(context, playlist);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          PlaylistArtwork(
                            songPaths: playlist.songPaths,
                            size: 52,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  playlist.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppFonts.jostStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.songsCount(playlist.songPaths.length),
                                  style: AppFonts.jostStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Already holds every song being added.
                          if (hasAll)
                            Icon(
                              LucideIcons.checkCircle2,
                              size: 20,
                              color: accent,
                            ),
                        ],
                      ),
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
