/// Every bundled (non-icon) asset path in one place. Icons for the Android
/// UI live in [AppIcons]; avatars are discovered at runtime from
/// [avatarDir] (see selected_avatar.dart). Build-time-only artwork
/// (launcher/Linux icons, README logos) sits in assets/branding/ and is
/// deliberately not bundled.
class AppAssets {
  AppAssets._();

  // Images
  static const String logo = 'assets/images/logo.svg';
  static const String looperUpdateLogo = 'assets/images/looper_update_logo.svg';
  static const String aboutMark = 'assets/images/about/about_mark.svg';
  static const String aboutDownload = 'assets/images/about/about_download.svg';
  static const String aboutInfo = 'assets/images/about/about_info.svg';
  static const String aboutStar = 'assets/images/about/about_star.svg';
  static const String aboutPattern = 'assets/images/about/about_pattern.png';
  static const String aboutCurve = 'assets/images/about/about_curve.svg';
  static const String aboutDiscord = 'assets/images/about/social_discord.svg';
  static const String aboutGithub = 'assets/images/about/social_github.svg';
  static const String aboutTelegram = 'assets/images/about/social_telegram.svg';
  static const String sessionIcon = 'assets/images/session_icon.png';
  static const String maintainerAvatar =
      'assets/images/about/maintainer_avatar.png';
  static const String designerAvatar =
      'assets/images/about/designer_avatar.png';
  static const String freeRiderAvatar =
      'assets/images/about/free_rider_avatar.png';

  // Animations
  static const String loadingAnimation = 'assets/animations/loading.json';
  static const String playingGif = 'assets/animations/playing.gif';

  // Avatars (directory only - filenames are persisted in settings)
  static const String avatarDir = 'assets/avatars/';

  // Social icons
  static const String github = 'assets/icons/social/github.svg';
  static const String telegram = 'assets/icons/social/telegram.svg';

  // Desktop player bar icons
  static const String _desktop = 'assets/icons/desktop/';
  static const String desktopPrevious = '${_desktop}previous.svg';
  static const String desktopNext = '${_desktop}next.svg';
  static const String desktopShuffle = '${_desktop}shuffle.svg';
  static const String desktopRepeat = '${_desktop}repeat.svg';
  static const String desktopRepeatOne = '${_desktop}repeat_one.svg';
  static const String desktopVolume = '${_desktop}volume.svg';
  static const String desktopMute = '${_desktop}mute.svg';
  static const String desktopLike = '${_desktop}like.svg';
  static const String desktopLiked = '${_desktop}liked.svg';
  static const String desktopLyrics = '${_desktop}lyrics.svg';
}
