import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:looper_player/features/settings/presentation/settings_notifier.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/playback/presentation/playback_notifier.dart';
import 'package:looper_player/core/navigation_provider.dart';
import 'package:looper_player/core/db_service.dart';
import 'package:isar_community/isar.dart';
import 'package:looper_player/core/app_fonts.dart';
import 'package:looper_player/l10n/app_localizations.dart';

part 'playlist_view.g.dart';

// Named 'PlaylistList' (not 'Playlist') to avoid colliding with the
// Playlist model class from library/domain/models - `name: 'playlist'`
// keeps the generated provider as `playlistProvider`, matching every
// existing call site.
@Riverpod(keepAlive: true, name: 'playlistProvider')
class PlaylistList extends _$PlaylistList {
  @override
  List<Playlist> build() {
    _loadPlaylists();
    return [];
  }

  void _loadPlaylists() {
    DbService.isar.playlists
        .where()
        .sortByDateModifiedDesc()
        .watch(fireImmediately: true)
        .listen((playlists) {
          state = playlists;
        });
  }

  Future<void> createPlaylist(String name) async {
    final playlist = Playlist()
      ..name = name
      ..songPaths = []
      ..dateCreated = DateTime.now()
      ..dateModified = DateTime.now();

    await DbService.isar.writeTxn(() => DbService.isar.playlists.put(playlist));
  }

  Future<void> deletePlaylist(int id) async {
    await DbService.isar.writeTxn(() => DbService.isar.playlists.delete(id));
  }
}

@Riverpod(keepAlive: true)
Stream<List<Song>> playlistSongs(Ref ref, int playlistId) {
  return DbService.isar.playlists
      .watchObject(playlistId, fireImmediately: true)
      .asyncMap((playlist) async {
        if (playlist == null || playlist.songPaths.isEmpty) return <Song>[];

        final songs = await DbService.isar.songs
            .filter()
            .anyOf(playlist.songPaths, (q, path) => q.pathEqualTo(path))
            .findAll();

        final songMap = {for (var s in songs) s.path: s};
        return playlist.songPaths
            .map((path) => songMap[path])
            .whereType<Song>()
            .toList();
      });
}

class PlaylistView extends ConsumerWidget {
  const PlaylistView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final playlists = ref.watch(playlistProvider);
    final hasActiveSong = ref.watch(playbackProvider.select((s) => s.currentSong != null));

    return Scaffold(
      // Not Colors.transparent - see the comment on CategoryDetailWrapper's
      // Scaffold in library_categories_views.dart for why.
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: playlists.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.listMusic,
                    size: 64,
                    color: Colors.grey.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.noPlaylistsYet, style: AppFonts.jostStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showCreateDialog(context, ref),
                    child: Text(l10n.createPlaylist, style: AppFonts.jostStyle()),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 180),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                childAspectRatio: 0.85,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: playlists.length,
              itemBuilder: (context, index) =>
                  _PlaylistCard(playlist: playlists[index]),
            ),
      floatingActionButton: AnimatedPadding(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.only(bottom: hasActiveSong ? 160 : 90),
        child: FloatingActionButton(
          onPressed: () => _showCreateDialog(context, ref),
          child: const Icon(LucideIcons.plus),
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.newPlaylist),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: l10n.playlistNameHint),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref
                    .read(playlistProvider.notifier)
                    .createPlaylist(controller.text);
                Navigator.pop(context);
              }
            },
            child: Text(l10n.create),
          ),
        ],
      ),
    );
  }
}

class _PlaylistCard extends ConsumerWidget {
  final Playlist playlist;
  const _PlaylistCard({required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () async {
        final songs = await DbService.isar.songs
            .filter()
            .anyOf(playlist.songPaths, (q, path) => q.pathEqualTo(path))
            .findAll();

        final songMap = {for (var s in songs) s.path: s};
        final orderedSongs = playlist.songPaths
            .map((path) => songMap[path])
            .whereType<Song>()
            .toList();

        ref
            .read(appNavigationProvider.notifier)
            .showCollection(
              title: playlist.name,
              subtitle: 'Playlist',
              songs: orderedSongs,
              playlist: playlist,
            );
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.primaryContainer
                    .withValues(alpha: 
                      ref.watch(settingsProvider).enableDynamicTheming
                          ? 0.8
                          : 0.3,
                    ),
              ),
              child: const Center(child: Icon(LucideIcons.listMusic, size: 48)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            playlist.name,
            style: AppFonts.jostStyle(fontWeight: FontWeight.normal),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${playlist.songPaths.length} songs',
            style: AppFonts.jostStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
