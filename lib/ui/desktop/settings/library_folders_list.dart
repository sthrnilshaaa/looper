part of 'settings_view.dart';

class _PremiumLibraryFoldersList extends ConsumerWidget {
  const _PremiumLibraryFoldersList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(settingsProvider).libraryFolders;

    if (folders.isEmpty) {
      return _PremiumActionRow(
        icon: LucideIcons.folderSearch,
        title: context.l10n.noIndexedFoldersYet,
        subtitle: context.l10n.noIndexedFoldersDesktopDesc,
        onTap: () {},
        isLast: false,
      );
    }

    return Column(
      children: folders
          .map(
            (path) => _PremiumActionRow(
              icon: LucideIcons.folder,
              title: path.split('/').last,
              subtitle: path,
              isLast: false,
              onTap: () {},
              trailing: IconButton(
                icon: const Icon(
                  LucideIcons.x,
                  size: 18,
                  color: Colors.white60,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  if (Platform.isAndroid) {
                    SafFolderService.releaseFolder(path);
                  }
                  final newFolders = List<String>.from(folders)..remove(path);
                  ref
                      .read(settingsProvider.notifier)
                      .updateLibraryFolders(newFolders);
                },
              ),
            ),
          )
          .toList(),
    );
  }
}
