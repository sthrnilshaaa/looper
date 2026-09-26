class AppIcons {
  // Base Path
  static const String _base = 'assets/android_icons/';

  // Tab Icons
  static const String home = '${_base}home_tab_icon.svg';
  static const String songs = '${_base}songs_tab_icon.svg';
  static const String library = '${_base}library_tab_icon.svg';
  static const String search = '${_base}Search_icon.svg';
  static const String settings = '${_base}settings_icon.svg';

  // Playback Controls
  static const String play = '${_base}play_icon.svg';
  static const String pause = '${_base}pause_icon.svg';
  static const String next = '${_base}Next_button_icon.svg';
  static const String prev =
      '${_base}Previous_button_icon.svg'; // Using left_arrow for prev
  static const String shuffle = '${_base}shuffle_button_icon.svg';
  static const String shuffleActive = '${_base}shuffle_button_active_icon.svg';
  static const String shuffleHome = '${_base}shuffle.svg';
  static const String repeat = '${_base}repeat_icon_inactive.svg';
  static const String repeatAll = '${_base}repeat_icon_all.svg';
  static const String repeatOne = '${_base}repeat_icon_one.svg';
  static const String queue = '${_base}queue_icon.svg';
  static const String lyrics = '${_base}lyrics_button_icon.svg';

  // Common Actions
  static const String like = '${_base}liked_icon.svg';
  static const String unlike = '${_base}liked_icon.svg';
  static const String heart = '${_base}liked_icon.svg';
  static const String more = '${_base}Menu_button_icon.svg'; // more/menu
  static const String back = '${_base}left_arrow_icon.svg';
  static const String close = '${_base}down_arrow_icon.svg';
  static const String musicIconSession = '${_base}music_icon_session.svg';

  // Icon Sizes (Raw values, will be scaled using .s extension in UI)
  static const double sizeTiny = 14.0;
  static const double sizeSmall = 18.0;
  static const double sizeMedium = 24.0;
  static const double sizeLarge = 28.0;
  static const double sizeExtraLarge = 32.0;
  static const double sizeHuge = 48.0;

  // Specific UI component sizes
  static const double navbarIcon = 19.0;
  static const double miniPlayerIcon = 20.0;
  static const double expandedPlayerMainControl = 28.0;
  static const double expandedPlayerSecondaryControl = 16.0;
  static const double morebuttonsize = 24;
  static const double expandedPlayerPlayPauseIcon = 28.0;
  static const double sidebarIcon = 17.0;
  static const double headerIcon = 12.0;
}
