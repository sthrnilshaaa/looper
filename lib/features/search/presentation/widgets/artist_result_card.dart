part of '../screens/search_view.dart';

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
