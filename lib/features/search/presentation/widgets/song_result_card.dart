part of '../screens/search_view.dart';

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
        spans.add(
          TextSpan(text: text.substring(start, indexOfMatch), style: baseStyle),
        );
      }
      // Add matched text
      spans.add(
        TextSpan(
          text: text.substring(indexOfMatch, indexOfMatch + query.length),
          style: highlightStyle,
        ),
      );
      start = indexOfMatch + query.length;
    }

    // Add remaining text
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: baseStyle));
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
    final isCurrent = ref.watch(
      playbackProvider.select((s) => s.currentSong?.path == song.path),
    );
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
                              style: AppFonts.jostStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
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
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  if (lyricSnippet != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
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
                              backgroundColor: colorScheme.primary.withValues(
                                alpha: 0.12,
                              ),
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
                              style: AppFonts.jostStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
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
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  if (lyricSnippet != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
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
                              backgroundColor: colorScheme.primary.withValues(
                                alpha: 0.12,
                              ),
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
