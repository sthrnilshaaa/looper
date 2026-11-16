/// Centralized repository for all external URLs, API endpoints, developer social links,
/// support links, and provider URLs used throughout Looper Player.
class AppLinks {
  AppLinks._();

  // App GitHub & Releases Links
  static const String githubRepo = 'https://github.com/SthrNilshaaa/looper';
  static const String githubReleasesApi =
      'https://api.github.com/repos/SthrNilshaaa/looper/releases/latest';

  /// Everyone who has committed to the repo; the About screen's maintainers
  /// row is built from it, so new contributors show up without a release.
  static const String githubContributorsApi =
      'https://api.github.com/repos/SthrNilshaaa/looper/contributors';

  /// Public repo whose star count and page the About screen shows.
  static const String githubStatsRepoApi =
      'https://api.github.com/repos/sthrnilshaaa/looper';
  static const String githubStatsRepo =
      'https://github.com/sthrnilshaaa/looper';
  static const String githubReleasesWeb =
      'https://github.com/SthrNilshaaa/looper/releases';
  static const String playStoreWeb =
      'https://play.google.com/store/apps/details?id=com.looper.player';

  // About > Socials. Empty until the channels exist; empty links do nothing.
  static const String socialDiscord = 'https://discord.gg/9nFHhg94wn';
  static const String socialGithub = 'https://github.com/sthrnilshaaa/looper';
  static const String socialTelegram = 'https://t.me/looperPlayer';

  // Support & Donation
  static const String koFi = 'https://ko-fi.com/L2L124TL7L';

  /// UPI payment link (`upi://pay?pa=<vpa>&pn=Looper`). Empty hides the
  /// "Support Via UPI" row in setup.
  static const String upi = '';

  // Maintainers & Developer Profiles
  static const String nileshGithub = 'https://github.com/SthrNilshaaa';
  static const String nileshTelegram = 'https://t.me/neelshy';

  static const String karanGithub = 'https://github.com/sthrkaran';
  static const String karanTelegram = 'https://t.me/karanwhy';

  static const String madanGithub = '';
  static const String madanTelegram = '';

  // Media & Metadata API Endpoints
  static const String deezerApiBase = 'https://api.deezer.com';
  static const String iTunesSearchUrl = 'https://itunes.apple.com/search';
  static const String lrcRedApiBase = 'https://lrc.red';

  /// Primary first. (The two vercel.app mirrors am-lyrics also lists were
  /// returning 402 DEPLOYMENT_DISABLED as of 2026-09-27, so they're gone.)
  static const List<String> lyricsPlusMirrors = [
    'https://lyricsplus.binimum.org',
    'https://lyricsplus.prjktla.workers.dev',
  ];

  // Lyrics Providers Web Links
  static const String lrcRedWeb = 'https://lrc.red';
  static const String lyricsPlusWeb = 'https://lyricsplus.binimum.org';
  static const String lrclibWeb = 'https://lrclib.net';
  static const String musicBrainzWeb = 'https://musicbrainz.org';
  static const String geniusWeb = 'https://genius.com';
  static const String musixmatchWeb = 'https://www.musixmatch.com';
  static const String azlyricsWeb = 'https://www.azlyrics.com';
  static const String lyricsmintWeb = 'https://www.lyricsmint.com';
  static const String lyricfindWeb = 'https://www.lyricfind.com';
  static const String lyricsOvhWeb = 'https://lyrics.ovh';
  static const String amllWeb = 'https://amll.dev';
  static const String neteaseWeb = 'https://music.163.com';
  static const String kugouWeb = 'https://www.kugou.com';
  static const String lyricifyWeb = 'https://lyricify.app';
  static const String betterLyricsWeb = 'https://lyrics-api.boidu.dev';
  static const String betterLyricsQqWeb = 'https://lyrics-api.boidu.dev/qq';
  static const String paxsenixWeb = 'https://lyrics.paxsenix.org';
  static const String unisonWeb = 'https://unison.boidu.dev';
  static const String biniLyricsWeb = 'https://lyrics-api.binimum.org';

  // Lyrics API endpoints (the ones above are the sites credited in About).
  static const String amllApiBase = 'https://api.amll.dev/v1/lyrics';
  static const String neteaseApiBase = 'https://music.163.com/api';
  static const String kugouSongSearchUrl =
      'https://mobiles.kugou.com/api/v3/search/song';
  static const String kugouLyricsBase = 'https://lyrics.kugou.com';
  static const String musixmatchApiBase = 'https://apic.musixmatch.com/ws/1.1';
  static const String lyricifyApiUrl =
      'https://api.lyricify.app/lyrics/get/mobile/new';
  static const String creditsFmResolveUrl =
      'https://api.credits.fm/v1/resolve/track';

  // Credits: projects our word-synced lyrics build on (see About).
  static const String lyricsPlusSource =
      'https://github.com/ibratabian17/lyricsplus';
  static const String amLyricsSource = 'https://github.com/binimum/am-lyrics';
  static const String morphePatchesSource =
      'https://github.com/MorpheApp/morphe-patches';
}
