import 'package:looper_player/core/motion/list_wave.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/library/presentation/providers/library/library_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/ui/android/widgets/genre_card.dart';
import 'library_categories_views.dart';

class GenresGridView extends ConsumerWidget {
  const GenresGridView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Isar doesn't have a distinct query easily for genres if they are just
    // strings in Songs, so the grouping itself is cached in
    // songsByGenreProvider (memoized on the song list, not this screen's
    // build cycle) - only the localized "Unknown" label is applied here.
    final l10n = AppLocalizations.of(context)!;
    final songsByGenre = ref.watch(songsByGenreProvider);
    final genresMap = <String, List<Song>>{};
    for (final entry in songsByGenre.entries) {
      final genre = entry.key ?? l10n.unknown;
      genresMap.putIfAbsent(genre, () => []).addAll(entry.value);
    }

    final sortOptionIndex = ref.watch(
      settingsProvider.select((s) => s.genreSortOptionIndex),
    );
    final sortOption = GenreSortOption
        .values[sortOptionIndex.clamp(0, GenreSortOption.values.length - 1)];
    final genres = genresMap.keys.toList();
    switch (sortOption) {
      case GenreSortOption.nameAsc:
        genres.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        break;
      case GenreSortOption.nameDesc:
        genres.sort((a, b) => b.toLowerCase().compareTo(a.toLowerCase()));
        break;
      case GenreSortOption.songCountDesc:
        genres.sort(
          (a, b) => genresMap[b]!.length.compareTo(genresMap[a]!.length),
        );
        break;
      case GenreSortOption.songCountAsc:
        genres.sort(
          (a, b) => genresMap[a]!.length.compareTo(genresMap[b]!.length),
        );
        break;
    }

    return ListWave(
      child: GridView.builder(
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 200,
        ),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 1.35,
        ),
        itemCount: genres.length,
        itemBuilder: waveItems((context, index) {
          final genre = genres[index];
          return GenreCard(genre: genre, songs: genresMap[genre]!);
        }),
      ),
    );
  }
}
