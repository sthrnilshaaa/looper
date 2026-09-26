import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/ui/widgets/common/app_refresh_indicator.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';
import 'package:looper_player/features/library/presentation/providers/library/library_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/core/theme/app_fonts.dart';

class FoldersListView extends ConsumerWidget {
  const FoldersListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // Grouping is cached in songsByFolderProvider (memoized on the song
    // list, not this screen's build cycle) instead of redone here inline.
    final foldersMap = ref.watch(songsByFolderProvider);
    final folders = foldersMap.keys.toList()..sort();

    return AppRefreshIndicator(
      onRefresh: () => ref
          .read(libraryProvider.notifier)
          .scanSavedFolders(showVisualIndicator: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 200,
        ),
        itemCount: folders.length,
        itemBuilder: (context, index) {
          final folderPath = folders[index];
          final folderName = folderPath.split(Platform.pathSeparator).last;
          final folderSongs = foldersMap[folderPath]!;
          return Material(
            color: Colors.transparent,
            child: ListTile(
              leading: const Icon(
                LucideIcons.folder,
                color: Colors.amberAccent,
              ),
              title: Text(folderName),
              subtitle: Text(
                folderPath,
                style: AppFonts.jostStyle(fontSize: 11, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text('${folderSongs.length} ${l10n.songs}'),
              onTap: () => ref
                  .read(appNavigationProvider.notifier)
                  .showCollection(
                    title: folderName,
                    subtitle: folderPath,
                    songs: folderSongs,
                  ),
            ),
          );
        },
      ),
    );
  }
}
