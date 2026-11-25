import 'package:looper_player/core/motion/list_wave.dart';
import 'package:looper_player/core/motion/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:looper_player/features/playlists/presentation/widgets/playlist_artwork.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/core/services/storage/import_export_service.dart';
import 'package:isar_community/isar.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/core/utils/l10n.dart';

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

// Keep the playlist record and its songs reactive independently: importing,
// enrichment, file removal and metadata edits need not modify the playlist.
final _playlistRecordProvider = StreamProvider.autoDispose
    .family<Playlist?, int>(
      (ref, playlistId) => DbService.isar.playlists.watchObject(
        playlistId,
        fireImmediately: true,
      ),
    );

@Riverpod(keepAlive: true)
Stream<List<Playlist>> dashboardPlaylists(Ref ref) {
  return DbService.isar.playlists
      .where()
      .sortByLastPlayedDesc()
      .thenByDateModifiedDesc()
      .watch(fireImmediately: true);
}

@Riverpod(keepAlive: true)
Stream<List<Song>> playlistSongs(Ref ref, int playlistId) async* {
  final playlist = await ref.watch(_playlistRecordProvider(playlistId).future);
  if (playlist == null || playlist.songPaths.isEmpty) {
    yield <Song>[];
    return;
  }
  yield* DbService.isar.songs
      .filter()
      .anyOf(playlist.songPaths, (q, path) => q.pathEqualTo(path))
      .watch(fireImmediately: true)
      .map((songs) {
        final songMap = {for (final song in songs) song.path: song};
        // Preserve saved order and repeated entries; unavailable songs are
        // omitted consistently with the playable song list.
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
    final accent = ref.watch(settingsProvider).accent;

    return Scaffold(
      // Not Colors.transparent - see the comment on CategoryDetailWrapper's
      // Scaffold in library_categories_views.dart for why. The desktop shell
      // paints its own background behind every page, so there it stays clear.
      backgroundColor: UiUtils.isDesktop
          ? Colors.transparent
          : Theme.of(context).colorScheme.surface,
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
                  Text(
                    l10n.noPlaylistsYet,
                    style: AppFonts.jostStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: _PlaylistActions(
                      accent: accent,
                      onCreate: () => _showCreateDialog(context, ref),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: _PlaylistActions(
                    accent: accent,
                    onCreate: () => _showCreateDialog(context, ref),
                  ),
                ),
                Expanded(
                  child: ListWave(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 180),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                          ),
                      itemCount: playlists.length,
                      itemBuilder: waveItems(
                        (context, index) =>
                            PlaylistCard(playlist: playlists[index]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    showTaskDialog(
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

/// Opens [playlist]'s collection page with its songs in playlist order.
Future<void> openPlaylist(
  BuildContext context,
  WidgetRef ref,
  Playlist playlist,
) async {
  final subtitle = context.l10n.playlist;
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
        subtitle: subtitle,
        songs: orderedSongs,
        playlist: playlist,
      );
}

class PlaylistCard extends ConsumerWidget {
  final Playlist playlist;

  /// Home sets the design's card text; elsewhere the app font.
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  const PlaylistCard({
    super.key,
    required this.playlist,
    this.titleStyle,
    this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => openPlaylist(context, ref, playlist),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: PlaylistArtwork(
              songPaths: playlist.songPaths,
              coverPath: playlist.coverPath,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            playlist.name,
            style:
                titleStyle ?? AppFonts.jostStyle(fontWeight: FontWeight.normal),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            context.l10n.songsCount(playlist.songPaths.length),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                subtitleStyle ??
                AppFonts.jostStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// New playlist and Import, side by side at the top of Playlists.
class _PlaylistActions extends StatelessWidget {
  final Color accent;
  final VoidCallback onCreate;

  const _PlaylistActions({required this.accent, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget button({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
      required bool primary,
    }) => Expanded(
      child: Material(
        color: primary ? accent : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            AppHaptics.light();
            onTap();
          },
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: primary ? _onAccent(accent) : Colors.white,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.jostStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: primary ? _onAccent(accent) : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Row(
      children: [
        button(
          icon: LucideIcons.plus,
          label: l10n.newPlaylist,
          onTap: onCreate,
          primary: true,
        ),
        const SizedBox(width: 10),
        button(
          icon: LucideIcons.fileInput,
          label: l10n.importLabel,
          onTap: () => ImportExportService.importM3uPlaylists(context),
          primary: false,
        ),
      ],
    );
  }

  static Color _onAccent(Color accent) =>
      accent.computeLuminance() > 0.5 ? Colors.black : Colors.white;
}
