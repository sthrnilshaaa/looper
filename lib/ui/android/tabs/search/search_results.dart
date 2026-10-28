part of 'android_search_tab.dart';

/// The scrolling results for one [kind]. In [_SearchKind.all] each kind gets
/// a short preview with a "View All" that narrows to it; the other kinds
/// list their matches in full.
class _SearchResultsBody extends ConsumerWidget {
  // How many songs / rows the overview shows per kind before "View All".
  static const _previewSongs = 4;
  static const _previewRows = 3;

  final SearchResults results;
  final String query;
  final _SearchKind kind;
  final Set<String> selected;
  final ValueChanged<_SearchKind> onShowKind;
  final ValueChanged<Song> onToggle;
  final VoidCallback onSelectAll;
  final VoidCallback onRemember;

  const _SearchResultsBody({
    required this.results,
    required this.query,
    required this.kind,
    required this.selected,
    required this.onShowKind,
    required this.onToggle,
    required this.onSelectAll,
    required this.onRemember,
  });

  Widget _song(AppLocalizations l10n, Song song) => SongTile(
    key: ValueKey(song.path),
    song: song,
    l10n: l10n,
    songs: results.songs,
    searchQuery: query,
    highlightTitle: true,
    onPlay: onRemember,
    selectionMode: selected.isNotEmpty,
    selected: selected.contains(song.path),
    onToggleSelect: () => onToggle(song),
    onEnterSelection: () => onToggle(song),
  );

  Widget _artistRow(WidgetRef ref, AppLocalizations l10n, Artist artist) =>
      _ResultRow(
        thumb: _Thumb(
          path: artist.artPath,
          icon: LucideIcons.user,
          round: true,
        ),
        title: artist.name,
        subtitle: l10n.artist,
        query: query,
        onTap: () {
          onRemember();
          _openArtist(ref, l10n, artist);
        },
      );

  Widget _albumRow(WidgetRef ref, AppLocalizations l10n, Album album) =>
      _ResultRow(
        thumb: _Thumb(path: album.artPath, icon: LucideIcons.disc3),
        title: album.name,
        subtitle: album.artist ?? l10n.unknownArtist,
        query: query,
        onTap: () {
          onRemember();
          _openAlbum(ref, l10n, album);
        },
      );

  Widget _playlistRow(
    WidgetRef ref,
    AppLocalizations l10n,
    Playlist playlist,
  ) => _ResultRow(
    thumb: const _Thumb(icon: LucideIcons.listMusic, accent: true),
    title: playlist.name,
    subtitle: l10n.songsCount(playlist.songPaths.length),
    query: query,
    onTap: () {
      onRemember();
      _openPlaylist(ref, l10n, playlist);
    },
  );

  Widget _genreRow(WidgetRef ref, AppLocalizations l10n, String genre) =>
      _ResultRow(
        thumb: const _Thumb(icon: LucideIcons.tag, accent: true),
        title: genre,
        subtitle: l10n.genre,
        query: query,
        onTap: () {
          onRemember();
          _openGenre(ref, l10n, genre);
        },
      );

  /// A titled preview of [items] for the overview: the first few rows, and a
  /// "View All" that switches to [kind] when there are more.
  List<Widget> _previewSection<T>({
    required AppLocalizations l10n,
    required String title,
    required _SearchKind kind,
    required List<T> items,
    required Widget Function(T item) row,
  }) {
    if (items.isEmpty) return const [];
    return [
      SliverToBoxAdapter(
        child: _SectionHeader(
          title: title,
          actionLabel: items.length > _previewRows ? l10n.viewAll : null,
          onAction: () => onShowKind(kind),
        ),
      ),
      SliverList.list(
        children: [for (final item in items.take(_previewRows)) row(item)],
      ),
    ];
  }

  List<Widget> _overview(WidgetRef ref, AppLocalizations l10n) {
    final songs = results.songs;
    final moreSongs = songs.skip(1).take(_previewSongs).toList();
    return [
      if (songs.isNotEmpty) ...[
        SliverToBoxAdapter(child: _SectionHeader(title: l10n.topResult)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: _TopResultCard(
              song: songs.first,
              query: query,
              onPlay: onRemember,
            ),
          ),
        ),
      ],
      if (moreSongs.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: l10n.songs,
            actionLabel: songs.length > _previewSongs + 1 ? l10n.viewAll : null,
            onAction: () => onShowKind(_SearchKind.songs),
          ),
        ),
        SliverList.list(
          children: [for (final song in moreSongs) _song(l10n, song)],
        ),
      ],
      if (results.artists.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: l10n.artists,
            actionLabel: results.artists.length > 4 ? l10n.viewAll : null,
            onAction: () => onShowKind(_SearchKind.artists),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 132,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: results.artists.length,
              itemBuilder: (context, index) {
                final artist = results.artists[index];
                return _ArtistBubble(
                  artist: artist,
                  onTap: () {
                    onRemember();
                    _openArtist(ref, l10n, artist);
                  },
                );
              },
            ),
          ),
        ),
      ],
      if (results.albums.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: l10n.albums,
            actionLabel: results.albums.length > 3 ? l10n.viewAll : null,
            onAction: () => onShowKind(_SearchKind.albums),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 184,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: results.albums.length,
              itemBuilder: (context, index) {
                final album = results.albums[index];
                return _AlbumCard(
                  album: album,
                  onTap: () {
                    onRemember();
                    _openAlbum(ref, l10n, album);
                  },
                );
              },
            ),
          ),
        ),
      ],
      ..._previewSection(
        l10n: l10n,
        title: l10n.playlists,
        kind: _SearchKind.playlists,
        items: results.playlists,
        row: (playlist) => _playlistRow(ref, l10n, playlist),
      ),
      ..._previewSection(
        l10n: l10n,
        title: l10n.genres,
        kind: _SearchKind.genres,
        items: results.genres,
        row: (genre) => _genreRow(ref, l10n, genre),
      ),
    ];
  }

  List<Widget> _allSongs(AppLocalizations l10n) => [
    SliverToBoxAdapter(
      child: _SectionHeader(
        title: l10n.songsCount(results.songs.length),
        quiet: true,
        actionLabel: l10n.selectAll,
        onAction: onSelectAll,
      ),
    ),
    SliverList.builder(
      itemCount: results.songs.length,
      itemBuilder: (context, index) => _song(l10n, results.songs[index]),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final slivers = switch (kind) {
      _SearchKind.all => _overview(ref, l10n),
      _SearchKind.songs => _allSongs(l10n),
      _SearchKind.artists => [
        SliverList.builder(
          itemCount: results.artists.length,
          itemBuilder: (context, index) =>
              _artistRow(ref, l10n, results.artists[index]),
        ),
      ],
      _SearchKind.albums => [
        SliverList.builder(
          itemCount: results.albums.length,
          itemBuilder: (context, index) =>
              _albumRow(ref, l10n, results.albums[index]),
        ),
      ],
      _SearchKind.playlists => [
        SliverList.builder(
          itemCount: results.playlists.length,
          itemBuilder: (context, index) =>
              _playlistRow(ref, l10n, results.playlists[index]),
        ),
      ],
      _SearchKind.genres => [
        SliverList.builder(
          itemCount: results.genres.length,
          itemBuilder: (context, index) =>
              _genreRow(ref, l10n, results.genres[index]),
        ),
      ],
    };

    return CustomScrollView(
      // A fresh scroll position per kind, so switching chips starts at the
      // top instead of wherever the previous list was left.
      key: ValueKey(kind),
      physics: const LooperScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        ...slivers,
        // Clears the mini player and navigation bar.
        const SliverToBoxAdapter(child: SizedBox(height: 180)),
      ],
    );
  }
}
