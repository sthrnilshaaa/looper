import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/l10n.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/library/presentation/providers/library/library_notifier.dart';
import 'package:looper_player/ui/desktop/widgets/hover_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Desktop Folders page: every folder that holds songs. Opening one shows
/// its songs in the collection page.
class DesktopFoldersView extends ConsumerWidget {
  const DesktopFoldersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final foldersMap = ref.watch(songsByFolderProvider);
    final folders = foldersMap.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          Text(
            l10n.folders,
            style: AppFonts.jostStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _confirmResetAndRescan(context, ref),
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: Text(
              l10n.resetLibrary,
              style: AppFonts.jostStyle(fontSize: 13),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              foregroundColor: Colors.red[300],
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Expanded(
          child: folders.isEmpty
              ? Center(
                  child: Text(
                    l10n.noIndexedFoldersYet,
                    style: AppFonts.jostStyle(
                      color: Colors.white54,
                      fontSize: 15,
                    ),
                  ),
                )
              : _list(context, ref, foldersMap, folders),
        ),
      ],
    );
  }

  Future<void> _confirmResetAndRescan(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetLibrary),
        content: Text(l10n.resetLibraryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.reset,
              style: AppFonts.jostStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(libraryProvider.notifier).resetAndRescan();
    }
  }

  Widget _list(
    BuildContext context,
    WidgetRef ref,
    Map<String, List<Song>> foldersMap,
    List<String> folders,
  ) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 48),
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final path = folders[index];
        final name = path.split(Platform.pathSeparator).last;
        final songs = foldersMap[path]!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: HoverCard(
            borderRadius: BorderRadius.circular(10),
            onTap: () => ref
                .read(appNavigationProvider.notifier)
                .showCollection(
                  title: name.isEmpty ? path : name,
                  subtitle: path,
                  art: songs
                      .map((s) => s.artPath)
                      .firstWhere((p) => p != null, orElse: () => null),
                  songs: songs,
                ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Icon(
                      LucideIcons.folder,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? path : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.jostStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          path,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.jostStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    context.l10n.songsCount(songs.length),
                    style: AppFonts.jostStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
