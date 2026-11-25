/// Centralized default settings and default orderings for Looper Player.
///
/// Modifying defaults here updates initial values across the entire application,
/// including Isar database schemas, local JSON stores, fallback migrations,
/// and default list/section orderings.
abstract final class AppDefaults {
  AppDefaults._();

  // ===========================================================================
  // SECTION 1: ORDERS
  // ===========================================================================

  /// Default Android Home screen sections order.
  static const List<String> defaultHomeSectionOrder = [
    'quick_picks',
    'playlists',
    'songs',
    'albums',
    'artists',
    'genres',
    'recent',
  ];

  /// Default Desktop Home sections candidate order.
  static const List<String> defaultDesktopHomeSectionOrder = [
    'quick_picks',
    'playlists',
    'recently_played',
    'featured_artists',
    'albums',
    'genres',
    'artists',
  ];

  /// Default lookup order for online lyrics services.
  static const List<String> defaultLyricsProviderOrder = [
    'LRC.RED',
    'LYRICSPLUS',
    'AMLL',
    'NETEASE',
    'KUGOU',
    'MUSIXMATCH',
    'LYRICIFY',
    'BETTERLYRICS',
    'PAXSENIX',
    'BINILYRICS',
    'UNISON',
    'BETTERLYRICS_QQ',
    'LRCLIB',
    'GENIUS',
    'AZLYRICS',
    'LYRICSMINT',
    'LYRICFIND',
    'LYRICSOVH',
  ];

  /// Default bottom navigation bar items order (Android).
  static const List<String> defaultNavTabsOrder = ['home', 'songs', 'library'];

  /// Default settings categories order (Android).
  static const List<String> defaultSettingsCategoriesOrder = [
    'theme',
    'now_playing',
    'lyrics',
    'audio_playback',
    'online',
    'library',
    'playback',
    'about',
    'support_us',
  ];

  /// Default sort strategy indices.
  static const int defaultSongSortStrategyIndex = 0; // Title A-Z
  static const bool defaultSortAscending = false;
  static const int defaultAlbumSortOptionIndex = 0; // Name A-Z
  static const int defaultArtistSortOptionIndex = 0; // Name A-Z
  static const int defaultGenreSortOptionIndex = 0; // Name A-Z
  static const int defaultCollectionSortOptionIndex = 0; // Default/Track Order

  // ===========================================================================
  // SECTION 2: AUDIO & PLAYBACK DEFAULTS
  // ===========================================================================
  static const double volume = 1.0;
  static const bool shuffle = false;
  static const int repeatMode = 0; // 0: off, 1: one, 2: all
  static const bool audioFocus = true;
  static const bool audioFocusRequestOnPlay = true;
  static const bool audioFocusReleaseOnPause = true;
  static const bool audioFocusStopOnOtherSession = true;
  static const bool audioFocusRestartOnGain = true;
  static const bool stopOnTaskRemoved = true;
  static const bool persistQueue = false;
  static const bool keepSongProgress = false;
  static const bool fadePlayPauseStop = true;
  static const int playPauseStopFadeLength = 150; // ms (10ms-1000ms)
  static const bool resumeAfterCall = true;
  static const bool pauseOnDuck = false;
  static const bool resumeOnBluetoothConnect = false;
  static const bool resumeOnStart = false;
  static const bool permanentAudioFocusChange = false;
  static const bool enableAudioCache = true;
  static const int audioCacheSizeMB = 200;
  static const int audioCacheSecs = 120;
  static const int audioBackCacheSizeMB = 100;
  static const bool exclusiveHardwareMode = false;
  static const bool equalizerEnabled = false;
  static const bool equalizerGlobalMode = true;
  static const bool firstTimeEqualizer = true;

  /// Default 48-band Equalizer / DSP gains.
  static List<double> createDefaultEqualizerGains() {
    final list = List<double>.filled(48, 0.0);
    list[20] = -50.0; // Silence remove threshold dB
    list[22] = 0.2; // Crossfeed strength
    list[24] = -20.0; // Compressor threshold dB
    list[25] = 2.0; // Compressor ratio
    list[26] = 20.0; // Compressor attack ms
    list[27] = 250.0; // Compressor release ms
    list[29] = -24.0; // Loudnorm target
    list[31] = 2.5; // Stereo width factor
    list[34] = 1.0; // Pitch shift
    list[35] = 1.0; // Tempo shift
    list[36] = 0.0; // ReplayGain mode
    list[37] = 0.0; // ReplayGain preamp
    list[39] = 150.0; // Speech highpass
    list[40] = 4000.0; // Speech lowpass
    list[44] = 1.0; // Tone shelving enabled
    list[45] = 1.0; // Pitch/tempo enabled
    return list;
  }

  // ===========================================================================
  // SECTION 3: THEME, UI & DISPLAY DEFAULTS
  // ===========================================================================
  static const String language = 'en';
  static const bool darkTheme = true;
  static const bool enableDynamicTheming = false;
  static const bool saveDynamicColor = true;
  static const int accentColor = 0xFF41C25E; // Default Green
  static const double defaultAccentVibrancy = 0.3;
  static const bool disableBlur = true;
  static const bool alwaysBlurSheets = false;
  static const bool frostedMusicBar = false;
  static const bool frostedNavbar = false;
  static const bool statusBarBlur = false;
  static const bool playerDynamicBackground = false;
  static const bool keepBackgroundGradient = false;
  static const bool animateBackgroundGradient = false;
  static const bool enablePlayerGradient = true;
  static const bool animatePlayerGradient = true;
  static const bool segmentedUtilityButtons = false;
  static const bool playerLyricLine = true;
  static const String playerLyricLineTransition = 'cube';
  static const String playerStyle = 'arc';
  static const bool playerStyleAccent = false;
  static const bool cardBlackBackground = false;
  static const bool cardAccentBackground = false;
  static const bool cardAccentColors = false;
  static const bool playerStyleBlur = true;
  static const bool showAlbumNextToArtist = true;
  static const bool showAlbumInQuickPicks = true;
  static const bool disableHaptics = false;
  static const int hapticStrength = 0; // 0 = Low, 1 = Medium, 2 = High
  static const double homeDarkness = 0.35;
  static const double songsDarkness = 0.72;
  static const double libraryDarkness = 0.72;
  static const double musicDarkness = 0.39;
  static const double lyricsDarkness = 0.35;
  static const double defaultDesktopBackgroundDarkness = 0.92;
  static const double bgBrightness = 0.5;
  static const double bgOpacity = 0.3;
  static const double desktopUiScale = 1.0;
  static const double lyricsFontScale = 1.0;
  static const bool keepScreenAwake = true;
  static const bool forceHighRefreshRate = true;

  /// The ▶▶ mark from the Home design, drawn in a round header button.
  static const String selectedAvatarAsset = 'looper_mark.svg';
  static const bool avatarDynamicColor = false;
  static const bool showPerformanceOptimizer = false;
  static const bool showHomeArtists = true;
  static const bool showHomeAlbums = false;
  static const bool showHomeGenres = true;
  static const bool showHomeRecent = true;
  static const bool showHomePlaylists = true;
  static const bool artistGroupByAlbum = true;
  static const bool enableSlideGesture = true;

  // Fonts
  static const bool useNewFont = true;
  static const String customFontFamily = 'DM Sans';
  static const int customFontWeight = 400;
  static const int customFontWeightDelta = 0;

  /// Letter spacing for all app text, in percent of the font size (Figma's
  /// unit): -2 tightens every line by 2% of its size.
  static const double letterSpacingPercent = -2.0;
  static const bool useNewFontLyrics = true;
  static const String customFontFamilyLyrics = 'Stack Sans Text';
  static const String customFontWeightLyrics = 'Normal';
  static const int customFontWeightLyricsDelta = 0;
  static const int activeLyricsFontWeightDelta = 0;

  // ===========================================================================
  // SECTION 4: LYRICS DEFAULTS
  // ===========================================================================
  static const bool dynamicLyrics = false;
  static const bool blurredArtworkForLyrics = true;
  static const bool dynamicColorActiveLyrics = true;
  static const double activeLyricsIntensity = 0.7;
  static const double defaultInactiveLyricsOpacity = 0.35;
  static const bool activeLyricsSoftColor = false;
  static const bool lyricsNoLineGrouping = false;
  static const bool enableLyricsGradient = true;
  static const bool ambientColorBackground = true;
  static const String lyricsAlignment = 'left';
  static const bool dynamicAccentColor = true;
  static const String lyricsSyncStyle = 'char';
  static const int defaultLyricsOffsetMs = 200;
  static const String defaultLyricsProvider = 'lrc.red';
  static const bool autoLyricsFallback = true;
  static const bool lyricsGestureTutorialSeen = false;

  // ===========================================================================
  // SECTION 5: PROGRESS BAR STYLE DEFAULTS
  // ===========================================================================
  static const double progressBarThickness = 6.0;
  static const double progressWaveHeight = 4.0;
  static const double progressWaveLength = 45.0;
  static const double progressWaveSpeed = 0.05;
  static const int progressThumbStyle = 0;
  static const double progressThumbWidth = 6.0;
  static const double progressThumbHeight = 16.0;
  static const double progressThumbGap = 7.25;
  static const double progressInactiveOpacity = 0.23;
  static const bool progressWaveFromStart = false;
  static const bool progressFreezeWhenPaused = false;
  static const bool progressGrowThumbOnDrag = true;
  static const bool disableSquiggle = false;
  static const bool disableAnimatedDuration = false;

  // ===========================================================================
  // SECTION 6: ARTWORK VISUALIZER DEFAULTS
  // ===========================================================================
  static const int artworkVisualizerType = 0; // none
  static const int artworkVisualizerIntensity = 1; // normal
  static const int artworkVisualizerColors = 0; // artwork
  static const int artworkVisualizerSyncMs = 150;

  // ===========================================================================
  // SECTION 7: QUALITY BADGE DEFAULTS
  // ===========================================================================
  static const bool showQualityBadge = true;
  static const int qualityBadgeLook = 0; // pill
  static const int qualityBadgeIcon = 4; // headphones
  static const int qualityBadgeColors = 0; // white
  static const int qualityBadgeSeparator = 2; // bar
  static const int qualityBadgeShape = 1; // rounded
  static const int qualityBadgeLayout = 0; // details
  static const int qualityBadgeFields = 0x1f;

  // ===========================================================================
  // SECTION 8: NETWORK & SCAN DEFAULTS
  // ===========================================================================
  static const bool enableInternet = true;
  static const bool downloadArtwork = true;
  static const bool includeSystemAndMessagingAudio = false;

  // ===========================================================================
  // SECTION 9: CROSSMIX & AUDIO TRANSITIONS DEFAULTS (LocalJsonStore)
  // ===========================================================================
  static const bool crossfadeEnabled = false;
  static const double crossmixDurationSeconds = 6.0;
  static const bool crossmixSmartTransitions = true;
  static const bool crossmixBeatMixing = true;
}
