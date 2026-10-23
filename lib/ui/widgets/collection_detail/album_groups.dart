part of 'collection_detail_view.dart';

/// One album section of an artist page grouped by album.
class _AlbumGroup {
  final String? album;
  final int? year;
  final String? artPath;
  final List<Song> songs;

  /// Index of this group's first song in the flattened song list.
  final int start;

  const _AlbumGroup({
    required this.album,
    required this.year,
    required this.artPath,
    required this.songs,
    required this.start,
  });
}

/// Splits [sorted] into album sections. Albums run newest first (oldest
/// first for "Year oldest", A-Z for "Album"), with songs without an album
/// last. Inside an album songs follow the track order, unless a title or
/// duration sort is picked, which then applies within each album.
List<_AlbumGroup> _groupByAlbum(List<Song> sorted, CollectionSortOption sort) {
  final byAlbum = <String, List<Song>>{};
  for (final song in sorted) {
    final key = song.album?.trim().toLowerCase() ?? '';
    byAlbum.putIfAbsent(key, () => []).add(song);
  }

  const keepSongOrder = {
    CollectionSortOption.titleAsc,
    CollectionSortOption.titleDesc,
    CollectionSortOption.duration,
  };
  final entries = byAlbum.entries.map((e) {
    final songs = e.value;
    if (!keepSongOrder.contains(sort)) {
      songs.sort((a, b) {
        final ta = a.trackNumber ?? 1 << 30;
        final tb = b.trackNumber ?? 1 << 30;
        if (ta != tb) return ta.compareTo(tb);
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    }
    final years = songs.map((s) => s.year).whereType<int>().where((y) => y > 0);
    return (
      key: e.key,
      songs: songs,
      year: years.isEmpty ? null : years.reduce((a, b) => a > b ? a : b),
      art: songs
          .map((s) => s.artPath)
          .firstWhere((p) => p != null, orElse: () => null),
    );
  }).toList();

  entries.sort((a, b) {
    // Songs without an album go last.
    if (a.key.isEmpty != b.key.isEmpty) return a.key.isEmpty ? 1 : -1;
    if (sort != CollectionSortOption.albumAsc) {
      if ((a.year == null) != (b.year == null)) return a.year == null ? 1 : -1;
      if (a.year != null && a.year != b.year) {
        return sort == CollectionSortOption.yearOldest
            ? a.year!.compareTo(b.year!)
            : b.year!.compareTo(a.year!);
      }
    }
    return a.key.compareTo(b.key);
  });

  var start = 0;
  return [
    for (final e in entries)
      _AlbumGroup(
        album: e.key.isEmpty ? null : e.songs.first.album,
        year: e.year,
        artPath: e.art,
        songs: e.songs,
        start: (start += e.songs.length) - e.songs.length,
      ),
  ];
}

/// The header above each album section: cover, name, year and song count,
/// and a button that plays just that album.
class _AlbumGroupHeader extends ConsumerWidget {
  final _AlbumGroup group;
  final EdgeInsetsGeometry padding;

  const _AlbumGroupHeader({required this.group, required this.padding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final accent = Color(
      ref.watch(settingsProvider.select((s) => s.accentColor)),
    );
    final details = [
      if (group.year != null) '${group.year}',
      l10n.songsCount(group.songs.length),
    ].join(' • ');

    return Padding(
      padding: padding,
      child: Row(
        children: [
          OptimizedImage(
            imagePath: group.artPath,
            width: 52,
            height: 52,
            borderRadius: BorderRadius.circular(8),
            placeholder: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                LucideIcons.disc3,
                size: 22,
                color: Colors.white24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.album ?? l10n.unknownAlbum,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.jostStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  details,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.jostStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.play,
            onPressed: () {
              AppHaptics.light();
              ref
                  .read(playbackProvider.notifier)
                  .setPlaylist(group.songs, initialIndex: 0);
            },
            style: IconButton.styleFrom(
              backgroundColor: accent.withValues(alpha: 0.15),
            ),
            icon: Icon(LucideIcons.play, size: 18, color: accent),
          ),
        ],
      ),
    );
  }
}
