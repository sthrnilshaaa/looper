part of 'home_dashboard.dart';

class _FeaturedArtistCard extends ConsumerWidget {
  final Artist artist;
  final bool isNarrow;

  const _FeaturedArtistCard({required this.artist, required this.isNarrow});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: () async {
          final artistSongs = await DbService.isar.songs
              .filter()
              .artistEqualTo(artist.name)
              .findAll();
          ref
              .read(appNavigationProvider.notifier)
              .showCollection(
                title: artist.name,
                subtitle: context.l10n.artist,
                art: artist.artPath,
                imageUrl: artist.artistImageUrl,
                songs: artistSongs,
              );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: isNarrow ? 80 : 100,
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Container(
                width: isNarrow ? 64 : 80,
                height: isNarrow ? 64 : 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: OptimizedImage(
                    imageUrl: artist.artistImageUrl,
                    imagePath: artist.artPath,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      color: Colors.grey.withValues(alpha: 0.1),
                      child: const Icon(LucideIcons.user, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                artist.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
