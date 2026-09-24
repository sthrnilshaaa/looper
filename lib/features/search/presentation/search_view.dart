import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:looper_player/core/app_fonts.dart';
import 'package:looper_player/ui/widgets/app_loading_indicator.dart';
import 'package:looper_player/features/playback/presentation/playback_notifier.dart';
import 'package:looper_player/features/settings/presentation/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/optimized_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/core/db_service.dart';
import 'package:isar_community/isar.dart';
import 'package:looper_player/features/library/presentation/songs_list.dart';
import 'package:looper_player/core/navigation_provider.dart';
import 'package:looper_player/features/playback/presentation/lyrics_search_provider.dart';
import 'package:looper_player/core/local_json_store.dart';

part 'search_view.g.dart';

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

        return SearchResults(songs: sortedSongs, albums: albums, artists: artists);
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
                  loading: () =>
                      const AppLoadingIndicator(),
                  error: (e, s) => Center(child: Text('Error: $e')),
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
            // Not localized - see the equivalent note in songs_list.dart's
            // multi-select bar.
            Text(
              'Recent Searches',
              style: AppFonts.jostStyle(color: Colors.grey, fontSize: 13),
            ),
            TextButton(
              onPressed: () => ref.read(recentSearchesProvider.notifier).clear(),
              child: const Text('Clear'),
            ),
          ],
        ),
        ...recent.map(
          (term) => ListTile(
            leading: const Icon(LucideIcons.history, size: 18, color: Colors.grey),
            title: Text(term, style: AppFonts.jostStyle(color: Colors.white)),
            trailing: IconButton(
              icon: const Icon(LucideIcons.x, size: 16, color: Colors.grey),
              onPressed: () => ref.read(recentSearchesProvider.notifier).remove(term),
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

    final songListToRender = results.songs.length > 1 ? results.songs.sublist(1) : <Song>[];

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
                    style: AppFonts.jostStyle(fontSize: 18, fontWeight: FontWeight.normal),
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
                    style: AppFonts.jostStyle(fontSize: 18, fontWeight: FontWeight.normal),
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
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = songListToRender[index];
                return SongTile(
                  key: ValueKey(song.path),
                  song: song,
                  l10n: l10n,
                  songs: songListToRender,
                  searchQuery: ref.read(searchQueryProvider),
                );
              },
              childCount: songListToRender.length,
            ),
          ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 180),
        ),
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
          style: AppFonts.jostStyle(fontSize: 18, fontWeight: FontWeight.normal),
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

class _SongResultCard extends ConsumerWidget {
  final Song song;
  final String? searchQuery;
  const _SongResultCard({required this.song, this.searchQuery});

  Widget _buildHighlightedText({
    required BuildContext context,
    required String text,
    required String query,
    required TextStyle baseStyle,
    required TextStyle highlightStyle,
  }) {
    if (query.isEmpty) {
      return Text(text, style: baseStyle);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      return Text(text, style: baseStyle);
    }

    final List<TextSpan> spans = [];
    int start = 0;
    int indexOfMatch;

    while ((indexOfMatch = lowerText.indexOf(lowerQuery, start)) != -1) {
      // Add text before match
      if (indexOfMatch > start) {
        spans.add(TextSpan(
          text: text.substring(start, indexOfMatch),
          style: baseStyle,
        ));
      }
      // Add matched text
      spans.add(TextSpan(
        text: text.substring(indexOfMatch, indexOfMatch + query.length),
        style: highlightStyle,
      ));
      start = indexOfMatch + query.length;
    }

    // Add remaining text
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: baseStyle,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCurrent = ref.watch(playbackProvider.select((s) => s.currentSong?.path == song.path));
    final l10n = AppLocalizations.of(context)!;

    String? lyricSnippet;
    if (searchQuery != null && searchQuery!.isNotEmpty && song.lyrics != null) {
      lyricSnippet = _getLyricSnippet(song.lyrics!, searchQuery!);
    }

    return InkWell(
      onTap: () {
        ref.read(lyricsSearchQueryProvider.notifier).clear();
        ref.read(playbackProvider.notifier).play(song);
      },
      borderRadius: BorderRadius.circular(16),
      child: isCurrent
          ? AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: OptimizedImage(
                          imagePath: song.artPath,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              style: AppFonts.jostStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              song.artist ?? l10n.unknownArtist,
                              style: AppFonts.jostStyle(fontSize: 14, color: Colors.grey),
                            ),
                            if (lyricSnippet == null) ...[
                              const SizedBox(height: 2),
                              Text(
                                song.album ?? l10n.unknownAlbum,
                                style: AppFonts.jostStyle(
                                  fontSize: 12,
                                  color: Colors.grey.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white),
                      ),
                    ],
                  ),
                  if (lyricSnippet != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.quote,
                                size: 11,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                l10n.matchingLyrics,
                                style: AppFonts.jostStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _buildHighlightedText(
                            context: context,
                            text: lyricSnippet,
                            query: searchQuery ?? '',
                            baseStyle: AppFonts.jostStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.85),
                              fontStyle: FontStyle.italic,
                            ),
                            highlightStyle: AppFonts.jostStyle(
                              fontSize: 13,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                              backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            )
          : Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white10.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: OptimizedImage(
                          imagePath: song.artPath,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              style: AppFonts.jostStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              song.artist ?? l10n.unknownArtist,
                              style: AppFonts.jostStyle(fontSize: 14, color: Colors.grey),
                            ),
                            if (lyricSnippet == null) ...[
                              const SizedBox(height: 2),
                              Text(
                                song.album ?? l10n.unknownAlbum,
                                style: AppFonts.jostStyle(
                                  fontSize: 12,
                                  color: Colors.grey.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white),
                      ),
                    ],
                  ),
                  if (lyricSnippet != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.quote,
                                size: 11,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                l10n.matchingLyrics,
                              style: AppFonts.jostStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _buildHighlightedText(
                            context: context,
                            text: lyricSnippet,
                            query: searchQuery ?? '',
                            baseStyle: AppFonts.jostStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.85),
                              fontStyle: FontStyle.italic,
                            ),
                            highlightStyle: AppFonts.jostStyle(
                              fontSize: 13,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                              backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  String? _getLyricSnippet(String lyrics, String query) {
    final lowerLyrics = lyrics.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerLyrics.indexOf(lowerQuery);
    if (index == -1) return null;

    int start = index;
    bool truncatedStart = false;
    while (start > 0 && lyrics[start - 1] != '\n') {
      start--;
      if (index - start > 40) {
        truncatedStart = true;
        break;
      }
    }

    int end = index + query.length;
    bool truncatedEnd = false;
    while (end < lyrics.length && lyrics[end] != '\n') {
      end++;
      if (end - index > 60) {
        truncatedEnd = true;
        break;
      }
    }

    String snippet = lyrics.substring(start, end).trim();
    if (truncatedStart) snippet = '...$snippet';
    if (truncatedEnd) snippet = '$snippet...';
    return snippet;
  }
}

class _ArtistResultCard extends ConsumerWidget {
  final Artist artist;
  const _ArtistResultCard({required this.artist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: () async {
        final songs = await DbService.isar.songs
            .filter()
            .artistEqualTo(artist.name)
            .findAll();
        ref
            .read(appNavigationProvider.notifier)
            .showCollection(
              title: artist.name,
              subtitle: l10n.artist,
              songs: songs,
              art: artist.artPath,
            );
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey.withValues(alpha: 0.1),
              backgroundImage: artist.artPath != null
                  ? FileImage(File(artist.artPath!))
                  : null,
              child: artist.artPath == null
                  ? const Icon(LucideIcons.user)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              artist.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.jostStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumResultCard extends ConsumerWidget {
  final Album album;
  const _AlbumResultCard({required this.album});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: () async {
        final songs = await DbService.isar.songs
            .filter()
            .albumEqualTo(album.name)
            .findAll();
        ref
            .read(appNavigationProvider.notifier)
            .showCollection(
              title: album.name,
              subtitle: album.artist ?? l10n.unknownArtist,
              songs: songs,
              art: album.artPath,
              album: album,
            );
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: OptimizedImage(
                  imagePath: album.artPath,
                  fit: BoxFit.cover,
                  placeholder: Container(
                    color: Colors.grey.withValues(alpha:
                      ref.watch(settingsProvider).enableDynamicTheming ? 0.8 : 0.1,
                    ),
                    child: const Center(child: Icon(LucideIcons.music)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              album.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.jostStyle(
                fontWeight: FontWeight.normal,
                fontSize: 13,
              ),
            ),
            Text(
              album.artist ?? l10n.unknownArtist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.jostStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
