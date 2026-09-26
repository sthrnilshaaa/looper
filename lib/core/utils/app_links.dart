/// Centralized repository for all external URLs, API endpoints, developer social links,
/// support links, and provider URLs used throughout Looper Player.
class AppLinks {
  AppLinks._();

  // App GitHub & Releases Links
  static const String githubRepo = 'https://github.com/SthrNilshaaa/looper';
  static const String githubReleasesApi =
      'https://api.github.com/repos/SthrNilshaaa/looper/releases/latest';
  static const String githubReleasesWeb =
      'https://github.com/SthrNilshaaa/looper/releases';
  static const String playStoreWeb =
      'https://play.google.com/store/apps/details?id=com.looper.player';

  // Support & Donation (UPI payment & Web fallback)
  static const String upiPay = 'https://ko-fi.com/sthrnilshaaa';
  static const String buyMeACoffee = 'https://buymeacoffee.com/sthrnilshaaa';

  // Maintainers & Developer Profiles
  static const String nileshGithub = 'https://github.com/SthrNilshaaa';
  static const String nileshTelegram = 'https://t.me/neelshy';

  static const String karanGithub = 'https://github.com/sthrkaran';
  static const String karanTelegram = 'https://t.me/karanwhy';

  static const String madanGithub = 'https://github.com/';
  static const String madanTelegram = 'https://t.me/madansthr';

  // Media & Metadata API Endpoints
  static const String deezerApiBase = 'https://api.deezer.com';
  static const String iTunesSearchUrl = 'https://itunes.apple.com/search';
  static const String lrclibApiBase = 'https://lrclib.net/api';

  // Lyrics Providers Web Links
  static const String lrclibWeb = 'https://lrclib.net';
  static const String geniusWeb = 'https://genius.com';
  static const String musixmatchWeb = 'https://www.musixmatch.com';
  static const String azlyricsWeb = 'https://www.azlyrics.com';
  static const String lyricsmintWeb = 'https://www.lyricsmint.com';
  static const String lyricfindWeb = 'https://www.lyricfind.com';

  static const Map<String, String> lyricsProviderUrls = {
    'LRCLIB': lrclibWeb,
    'Genius': geniusWeb,
    'Musixmatch': musixmatchWeb,
    'AZLyrics': azlyricsWeb,
    'LyricsMINT': lyricsmintWeb,
    'LyricFind': lyricfindWeb,
  };
}
