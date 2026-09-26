import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/ui/widgets/common/app_loading_indicator.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:isar_community/isar.dart';
import 'package:looper_player/features/library/presentation/widgets/songs/songs_list.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';
import 'package:looper_player/features/playback/presentation/providers/lyrics/lyrics_search_provider.dart';
import 'package:looper_player/core/services/storage/local_json_store.dart';
import 'package:looper_player/core/utils/l10n.dart';

part 'search_view.g.dart';
part '../widgets/song_result_card.dart';
part '../widgets/artist_result_card.dart';
part '../widgets/album_result_card.dart';

@Riverpod(keepAlive: true)
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void set(String value) => state = value;
}

/// Search terms the user has actually submitted (keyboard "search" action),
/// not every partial string typed while the live-filter results were
/// updating - most-recent first, deduplicated, capped so the list stays a
/// quick-glance shortlist rather than a full search log.
@Riverpod(keepAlive: true)
class RecentSearches extends _$RecentSearches {
  static const _storeKey = 'recent_searches';
  static const _maxEntries = 10;

  @override
  List<String> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final raw = await LocalJsonStore.read(_storeKey);
    if (raw is! List) return;
    state = raw.whereType<String>().toList();
  }

  Future<void> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    state = [
      trimmed,
      ...state.where((q) => q.toLowerCase() != trimmed.toLowerCase()),
    ].take(_maxEntries).toList();
    await LocalJsonStore.write(_storeKey, state);
  }

  Future<void> remove(String query) async {
    state = state.where((q) => q != query).toList();
    await LocalJsonStore.write(_storeKey, state);
  }

  Future<void> clear() async {
    state = [];
    await LocalJsonStore.write(_storeKey, state);
  }
}

class SearchResults {
  final List<Song> songs;
  final List<Album> albums;
  final List<Artist> artists;

  SearchResults({
    required this.songs,
    required this.albums,
    required this.artists,
  });
}

/// Ranks how well [song] matches [lowerQuery] (already lower-cased) for
/// search-result ordering: exact/prefix/substring title match, then a
/// lyrics match, then an artist/album match, highest first. A pure function
/// (no Isar/DB dependency) so it's unit-testable independently of
/// [searchResultsProvider]'s DB-backed stream.
int songSearchScore(Song song, String lowerQuery) {
  final title = song.title.toLowerCase();
  final lyrics = (song.lyrics ?? '').toLowerCase();
  final artist = (song.artist ?? '').toLowerCase();
  final album = (song.album ?? '').toLowerCase();

  // 1. Top Match Songs Name
  if (title == lowerQuery) return 100;
  if (title.startsWith(lowerQuery)) return 90;
  if (title.contains(lowerQuery)) return 80;

  // 2. Lyrics Match
  if (lyrics.contains(lowerQuery)) return 50;

  // 3. Others (Artist or Album contain query)
  if (artist.contains(lowerQuery) || album.contains(lowerQuery)) return 30;

  return 0;
}

@Riverpod(keepAlive: true)
Stream<SearchResults> searchResults(Ref ref) {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) {
    return Stream.value(SearchResults(songs: [], albums: [], artists: []));
  }

  return DbService.isar.songs
      .filter()
      .titleContains(query, caseSensitive: false)
      .or()
      .artistContains(query, caseSensitive: false)
      .or()
      .albumContains(query, caseSensitive: false)
      .or()
      .lyricsContains(query, caseSensitive: false)
      .watch(fireImmediately: true)
      .asyncMap((songs) async {
        final albums = await DbService.isar.albums
            .filter()
            .nameContains(query, caseSensitive: false)
            .findAll();
        final artists = await DbService.isar.artists
            .filter()
            .nameContains(query, caseSensitive: false)
            .findAll();

        // Sort songs: top match songs name > lyrics match > others
        final lowerQuery = query.toLowerCase();
        final sortedSongs = List<Song>.from(songs);
        sortedSongs.sort((a, b) {
          final scoreA = songSearchScore(a, lowerQuery);
          final scoreB = songSearchScore(b, lowerQuery);

          if (scoreA != scoreB) {
            return scoreB.compareTo(scoreA); // Higher score first
          }

          // Secondary sort: alphabetical by title
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });

        return SearchResults(
          songs: sortedSongs,
          albums: albums,
          artists: artists,
        );
      });
}

class SearchView extends ConsumerWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);

    return Column(
      children: [
        Expanded(
          child: query.isEmpty
              ? _buildRecentSearches(context, ref)
              : resultsAsync.when(
                  data: (results) => _buildResults(results, ref, context),
                  loading: () => const AppLoadingIndicator(),
                  error: (e, s) =>
                      Center(child: Text(context.l10n.errorWithDetails('$e'))),
                ),
        ),
      ],
    );
  }

  Widget _buildRecentSearches(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final recent = ref.watch(recentSearchesProvider);

    if (recent.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.search,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.searchLibraryHint,
              style: AppFonts.jostStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.recentSearches,
              style: AppFonts.jostStyle(color: Colors.grey, fontSize: 13),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(recentSearchesProvider.notifier).clear(),
              child: Text(context.l10n.clear),
            ),
          ],
        ),
        ...recent.map(
          (term) => ListTile(
            leading: const Icon(
              LucideIcons.history,
              size: 18,
              color: Colors.grey,
            ),
            title: Text(term, style: AppFonts.jostStyle(color: Colors.white)),
            trailing: IconButton(
              icon: const Icon(LucideIcons.x, size: 16, color: Colors.grey),
              onPressed: () =>
                  ref.read(recentSearchesProvider.notifier).remove(term),
            ),
            onTap: () => ref.read(searchQueryProvider.notifier).set(term),
          ),
        ),
      ],
    );
  }

  Widget _buildResults(
    SearchResults results,
    WidgetRef ref,
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (results.songs.isEmpty &&
        results.albums.isEmpty &&
        results.artists.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(l10n.noResultsFound),
        ),
      );
    }

    final songListToRender = results.songs.length > 1
        ? results.songs.sublist(1)
        : <Song>[];

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: _buildTopResult(results, ref, context),
          ),
        ),
        if (results.artists.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    l10n.artists,
                    style: AppFonts.jostStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: results.artists.length,
                    itemBuilder: (context, index) =>
                        _ArtistResultCard(artist: results.artists[index]),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        if (results.albums.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    l10n.albums,
                    style: AppFonts.jostStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: results.albums.length,
                    itemBuilder: (context, index) =>
                        _AlbumResultCard(album: results.albums[index]),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        if (songListToRender.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final song = songListToRender[index];
              return SongTile(
                key: ValueKey(song.path),
                song: song,
                l10n: l10n,
                songs: songListToRender,
                searchQuery: ref.read(searchQueryProvider),
              );
            }, childCount: songListToRender.length),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 180)),
      ],
    );
  }

  Widget _buildTopResult(
    SearchResults results,
    WidgetRef ref,
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (results.songs.isEmpty) return const SizedBox.shrink();
    final topSong = results.songs.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.topResult,
          style: AppFonts.jostStyle(
            fontSize: 18,
            fontWeight: FontWeight.normal,
          ),
        ),
        const SizedBox(height: 12),
        _SongResultCard(
          song: topSong,
          searchQuery: ref.read(searchQueryProvider),
        ),
      ],
    );
  }
}
