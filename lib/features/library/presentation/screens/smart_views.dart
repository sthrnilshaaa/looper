import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/l10n.dart';
import 'package:looper_player/features/library/presentation/widgets/songs/songs_list.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/common/filter_pill.dart';
import 'package:looper_player/ui/widgets/common/app_loading_indicator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:looper_player/features/library/presentation/providers/library/paged_songs_notifier.dart';
import 'package:looper_player/ui/android/tabs/library/categories/category_detail_wrapper.dart'
    show CategorySearch;
export 'package:looper_player/features/library/presentation/providers/library/paged_songs_notifier.dart';

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) => _PagedSongsView(
    kind: PagedQueryKind.favorites,
    emptyIcon: LucideIcons.heart,
    emptyText: AppLocalizations.of(context)!.noFavoritesYet,
  );
}

class RecentlyPlayedView extends StatelessWidget {
  const RecentlyPlayedView({super.key});

  @override
  Widget build(BuildContext context) => _PagedSongsView(
    kind: PagedQueryKind.history,
    emptyIcon: LucideIcons.clock,
    emptyText: AppLocalizations.of(context)!.noHistoryYet,
  );
}

/// Favorites / History: one page of songs, and a page switcher at the end of the list.
class _PagedSongsView extends ConsumerWidget {
  const _PagedSongsView({
    required this.kind,
    required this.emptyIcon,
    required this.emptyText,
  });

  final PagedQueryKind kind;
  final IconData emptyIcon;
  final String emptyText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = pagedSongsProvider(kind);
    final pagedAsync = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final q = CategorySearch.of(context);

    return pagedAsync.when(
      data: (paged) {
        final list = q.isNotEmpty
            ? _SearchedSongs(query: q, fetch: notifier.fetchAll)
            : paged.items.isEmpty
            ? _buildEmpty(context, emptyIcon, emptyText)
            : SongsList(
                // New page: fresh list scrolled to the top.
                key: ValueKey(paged.page),
                songs: paged.items,
                totalCount: paged.total,
                onRefresh: notifier.refresh,
                resolveQueue: notifier.fetchAll,
                footer: paged.pageCount > 1
                    ? _PageBar(
                        page: paged.page,
                        pageCount: paged.pageCount,
                        onPage: notifier.goToPage,
                      )
                    : null,
              );
        return list;
      },
      loading: () => const AppLoadingIndicator(),
      error: (e, s) => Center(child: Text(context.l10n.errorWithDetails('$e'))),
    );
  }
}

class _PageBar extends StatelessWidget {
  const _PageBar({
    required this.page,
    required this.pageCount,
    required this.onPage,
  });

  final int page;
  final int pageCount;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    void go(int p) {
      AppHaptics.selection();
      onPage(p);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronLeft, size: 20),
            tooltip: 'Previous page',
            onPressed: page > 0 ? () => go(page - 1) : null,
          ),
          const SizedBox(width: 8),
          Text(
            'Page ${page + 1} of $pageCount',
            style: AppFonts.jostStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(LucideIcons.chevronRight, size: 20),
            tooltip: 'Next page',
            onPressed: page < pageCount - 1 ? () => go(page + 1) : null,
          ),
        ],
      ),
    );
  }
}

Widget _buildEmpty(BuildContext context, IconData icon, String text) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64, color: Colors.grey.withValues(alpha: 0.2)),
        const SizedBox(height: 16),
        Text(text),
      ],
    ),
  );
}

/// Every song of a paged list matching [query] (title or artist), not just
/// the page on screen.
class _SearchedSongs extends StatefulWidget {
  const _SearchedSongs({required this.query, required this.fetch});

  final String query;
  final Future<List<Song>> Function({String? search}) fetch;

  @override
  State<_SearchedSongs> createState() => _SearchedSongsState();
}

class _SearchedSongsState extends State<_SearchedSongs> {
  late Future<List<Song>> _results = _load();

  Future<List<Song>> _load() async => [
    for (final s in await widget.fetch(search: widget.query))
      if (CategorySearch.matches(widget.query, [s.title, s.artist])) s,
  ];

  @override
  void didUpdateWidget(_SearchedSongs old) {
    super.didUpdateWidget(old);
    if (old.query != widget.query) _results = _load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Song>>(
      future: _results,
      builder: (context, snap) {
        final songs = snap.data;
        if (songs == null) return const AppLoadingIndicator();
        if (songs.isEmpty) {
          return _buildEmpty(
            context,
            LucideIcons.searchX,
            context.l10n.noSongsFound,
          );
        }
        return SongsList(songs: songs, searchQuery: widget.query);
      },
    );
  }
}
