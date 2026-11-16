import 'package:looper_player/core/utils/app_links.dart';
import 'package:looper_player/features/settings/domain/app_defaults.dart';

/// An online lyrics service: how it's stored ([id], also the lowercase
/// `[source:]` tag on saved lyrics), shown ([label]) and credited ([url]).
class LyricsProviderInfo {
  final String id;
  final String label;
  final String url;

  /// Can return word timing. Lookups hold a line-synced answer from one of
  /// these while the others are asked for real word timing.
  final bool wordCapable;

  /// Can time pieces smaller than a word (syllables, letters).
  final bool letterCapable;

  /// Returns plain text only - never asked when synced lyrics are wanted.
  final bool plainOnly;

  const LyricsProviderInfo(
    this.id,
    this.label,
    this.url, {
    this.wordCapable = false,
    this.letterCapable = false,
    this.plainOnly = false,
  });

  /// The best kind of lyrics this service can return, on
  /// LyricsFetcher's scale: 1 plain text, 2 line by line, 3 word by word,
  /// 4 letter by letter.
  int get bestLevel => letterCapable
      ? 4
      : wordCapable
      ? 3
      : plainOnly
      ? 1
      : 2;

  /// The default lookup order IDs, defined in [AppDefaults.defaultLyricsProviderOrder].
  static const List<String> defaultOrder = AppDefaults.defaultLyricsProviderOrder;

  /// Every service, in the default lookup order: word-synced sources first
  /// (the two Apple-quality ones, then the catalogues that are searched by
  /// title and artist), then line-synced LRCLIB, then the plain-text
  /// scrapers.
  static const List<LyricsProviderInfo> all = [
    LyricsProviderInfo(
      'LRC.RED',
      'lrc.red',
      AppLinks.lrcRedWeb,
      wordCapable: true,
      letterCapable: true,
    ),
    LyricsProviderInfo(
      'LYRICSPLUS',
      'LyricsPlus',
      AppLinks.lyricsPlusWeb,
      wordCapable: true,
      letterCapable: true,
    ),
    LyricsProviderInfo(
      'AMLL',
      'AMLL',
      AppLinks.amllWeb,
      wordCapable: true,
      letterCapable: true,
    ),
    LyricsProviderInfo(
      'NETEASE',
      'NetEase',
      AppLinks.neteaseWeb,
      wordCapable: true,
    ),
    LyricsProviderInfo('KUGOU', 'KuGou', AppLinks.kugouWeb, wordCapable: true),
    LyricsProviderInfo(
      'MUSIXMATCH',
      'Musixmatch',
      AppLinks.musixmatchWeb,
      wordCapable: true,
    ),
    LyricsProviderInfo(
      'LYRICIFY',
      'Lyricify',
      AppLinks.lyricifyWeb,
      wordCapable: true,
      letterCapable: true,
    ),
    LyricsProviderInfo(
      'BETTERLYRICS',
      'BetterLyrics',
      AppLinks.betterLyricsWeb,
      wordCapable: true,
      letterCapable: true,
    ),
    LyricsProviderInfo(
      'PAXSENIX',
      'PaxSenix',
      AppLinks.paxsenixWeb,
      wordCapable: true,
      letterCapable: true,
    ),
    LyricsProviderInfo(
      'BINILYRICS',
      'BiniLyrics',
      AppLinks.biniLyricsWeb,
      wordCapable: true,
    ),
    LyricsProviderInfo(
      'UNISON',
      'Unison',
      AppLinks.unisonWeb,
      wordCapable: true,
    ),
    LyricsProviderInfo(
      'BETTERLYRICS_QQ',
      'BetterLyrics (QQ)',
      AppLinks.betterLyricsQqWeb,
      wordCapable: true,
    ),
    LyricsProviderInfo('LRCLIB', 'LRCLIB', AppLinks.lrclibWeb),
    LyricsProviderInfo('GENIUS', 'Genius', AppLinks.geniusWeb, plainOnly: true),
    LyricsProviderInfo(
      'AZLYRICS',
      'AZLyrics',
      AppLinks.azlyricsWeb,
      plainOnly: true,
    ),
    LyricsProviderInfo(
      'LYRICSMINT',
      'LyricsMINT',
      AppLinks.lyricsmintWeb,
      plainOnly: true,
    ),
    LyricsProviderInfo(
      'LYRICFIND',
      'LyricFind',
      AppLinks.lyricfindWeb,
      plainOnly: true,
    ),
    LyricsProviderInfo(
      'LYRICSOVH',
      'lyrics.ovh',
      AppLinks.lyricsOvhWeb,
      plainOnly: true,
    ),
  ];


  /// By [id], a `[source:]` tag or a [label] - any letter case.
  static LyricsProviderInfo? of(String? name) {
    if (name == null) return null;
    final id = name.toUpperCase();
    for (final provider in all) {
      if (provider.id == id) return provider;
    }
    return null;
  }

  /// [stored] (ids, as the user arranged them) made complete and valid:
  /// unknown ids dropped, services added since it was saved slotted in at
  /// their default position. Nothing stored yet: the default order, with
  /// [legacyPrimary] - the provider picked before the list existed - first.
  static List<String> order(List<String> stored, {String? legacyPrimary}) {
    final known = [for (final p in all) p.id];
    final result = <String>[
      for (final id in stored.map((s) => s.toUpperCase()))
        if (known.contains(id)) id,
    ];
    if (result.isEmpty) {
      final primary = legacyPrimary?.toUpperCase();
      return [
        if (known.contains(primary)) primary!,
        for (final id in known)
          if (id != primary) id,
      ];
    }
    for (var i = 0; i < known.length; i++) {
      if (result.contains(known[i])) continue;
      // After the nearest earlier service that is already placed.
      var at = 0;
      for (var j = i - 1; j >= 0; j--) {
        final before = result.indexOf(known[j]);
        if (before != -1) {
          at = before + 1;
          break;
        }
      }
      result.insert(at, known[i]);
    }
    return result.toSet().toList();
  }
}
