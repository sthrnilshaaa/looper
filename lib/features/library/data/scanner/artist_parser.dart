class ArtistParser {
  /// Splits strings like "Artist A feat. Artist B", "Artist A / Artist B", "Artist A; Artist B", "Artist A & Artist B"
  static List<String> parse(String? rawArtist) {
    if (rawArtist == null ||
        rawArtist.trim().isEmpty ||
        rawArtist.trim().toLowerCase() == 'unknown artist') {
      return ['Unknown Artist'];
    }

    final regex = RegExp(
      r'\s*(?:;|\/|\\|&|feat\.|ft\.|,|AND)\s*',
      caseSensitive: false,
    );
    final parts = rawArtist
        .split(regex)
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList();

    return parts.isNotEmpty ? parts : [rawArtist.trim()];
  }

  static String primaryArtist(String? rawArtist) {
    final parsed = parse(rawArtist);
    return parsed.first;
  }
}
