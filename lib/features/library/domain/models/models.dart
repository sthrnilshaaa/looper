import 'package:isar_community/isar.dart';

part 'models.g.dart';

@collection
class Song {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String path;

  late String title;

  @Index()
  String? artist;

  @Index()
  String? album;

  String? genre;
  int? duration; // In milliseconds
  int? trackNumber;
  int? year;
  String? artPath;

  @Index()
  late DateTime dateAdded;

  int playCount = 0;
  @Index()
  DateTime? lastPlayed;

  /// Real, actually-listened-to time accumulated across every play, in
  /// milliseconds — wall-clock time mpv reported this song as actively
  /// playing, not `playCount * duration`. A song played for 2 seconds then
  /// skipped only ever adds ~2000 here, never the full track duration.
  int totalListenedMs = 0;

  /// The playback position (in milliseconds) this song was last at when the
  /// user moved on to another track, saved only while "Keep Song Progress"
  /// is enabled. 0 means "start from the beginning" -- also what a song
  /// gets reset to once it plays through to its end, so finishing a track
  /// naturally never leaves it parked at 99%.
  int lastPositionMs = 0;
  bool isFavorite = false;
  String? lyrics;
  bool hasCustomEqualizer = false;
  List<double>? equalizerGains;

  /// This song's own lyrics timing offset in milliseconds (positive =
  /// earlier), set in the lyrics menu. Null = the app default,
  /// [AppSettings.defaultLyricsOffsetMs].
  int? lyricsOffsetMs;

  /// True for a row the scanner inserted quickly (path + whatever MediaStore
  /// had) without yet running the slow part - tag parsing, embedded art,
  /// lyrics. Lets a song appear in the list immediately on first scan while
  /// that enrichment happens in the background; see
  /// LibraryScanner.enrichPendingSongs.
  @Index()
  bool needsEnrichment = false;

  // Metadata for search
  @Index(type: IndexType.value, caseSensitive: false)
  List<String> get searchTerms => [
    title,
    artist ?? '',
    album ?? '',
    lyrics ?? '',
  ];
}

@collection
class Album {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String name;

  String? artist;
  String? artPath;
  int? year;

  @Index()
  late DateTime dateAdded;
}

@collection
class Artist {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String name;

  String? artPath;
  String? artistImageUrl;
  // Set when the user picked or removed the picture: the background fetch
  // then leaves it alone. "Fetch from internet" clears it again.
  bool artistImageLocked = false;
}

/// A single timestamped "song started playing" event, logged alongside the
/// [Song.playCount]/[Song.lastPlayed] aggregate so Looper Analyze can show
/// time-based insights (trend, streaks, busiest listening times) rather than
/// just static totals. Fields are denormalized off the song at play time so
/// history stays meaningful even if the song is later retagged or removed.
@collection
class PlayEvent {
  Id id = Isar.autoIncrement;

  int? songId;
  late String songPath;
  late String songTitle;
  String? artist;
  String? album;
  String? genre;
  int? durationMs; // the song's full track duration, for reference only

  /// Real time actually listened to during this specific play session, in
  /// milliseconds. Starts at 0 and is topped up incrementally as playback
  /// continues (see PlaybackNotifier's listen-segment tracking) — it is
  /// NOT assumed to equal [durationMs].
  int listenedMs = 0;

  @Index()
  late DateTime playedAt;
}

@collection
class Playlist {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String name;

  late List<String> songPaths;
  late DateTime dateCreated;
  late DateTime dateModified;
  DateTime? lastPlayed;
}

@collection
class AppSettings {
  Id id = 0; // Always use ID 0 for single settings object

  List<String> libraryFolders = [];
  int? lastPlayedSongId;
  List<int> lastQueueSongIds = [];
  int lastQueueIndex = -1;
  List<int> lastQueueManualIndices = [];
  List<int> lastQueueOriginalOrder = [];
  double volume = 1.0;
  int lastPositionMs = 0;
  bool shuffle = false;
  int repeatMode = 0; // 0: off, 1: one, 2: all
  String language = 'en';
  bool enableDynamicTheming = false;
  bool darkTheme = true;
  bool saveDynamicColor = true;
  bool dynamicLyrics = false;
  bool blurredArtworkForLyrics = true;
  int accentColor = 0xFF41C25E; // Default Green
  bool audioFocus = true;
  // Unused: audio focus is owned by mpv_audio_kit, which can't honour
  // these (nor pauseOnDuck / permanentAudioFocusChange below). Kept only
  // so the Isar schema and existing databases stay unchanged.
  bool audioFocusRequestOnPlay = true;
  bool audioFocusReleaseOnPause = true;
  bool audioFocusStopOnOtherSession = true;
  bool audioFocusRestartOnGain = true;
  bool disableSquiggle = false;
  bool disableAnimatedDuration = false;

  // Progress bar style (Android player + lyrics screen), see
  // ProgressBarStyle. Nullable so databases from before these existed read
  // back as "use the default" - Isar fills a missing double with NaN and a
  // missing int with its min value, not the Dart initializer.
  double? progressBarThickness;
  double? progressWaveHeight;
  double? progressWaveLength;
  double? progressWaveSpeed;
  int? progressThumbStyle;
  double? progressThumbWidth;
  double? progressThumbHeight;
  double? progressThumbGap;
  double? progressInactiveOpacity;
  bool progressWaveFromStart = false;
  bool progressFreezeWhenPaused = false;
  bool progressGrowThumbOnDrag = false;

  // Now Playing artwork visualizer, see ArtworkVisualizerType. Null means
  // none / the default intensity / artwork colors.
  int? artworkVisualizer;
  int? artworkVisualizerIntensity;
  int? artworkVisualizerColors;
  // How long the effect waits after the audio is analysed, to line up
  // with what's actually heard (output buffers, Bluetooth).
  int? artworkVisualizerSyncMs;
  bool disableBlur = true;
  // Forces the blur behind bottom sheets on regardless of Dynamic Theming --
  // that toggle changes accent colors/gradients app-wide too, so this gives
  // sheets their blur without needing all of that. Independent of disableBlur,
  // which only gates the Dynamic Theming blur path (see app_bottom_sheet.dart).
  bool alwaysBlurSheets = true;
  bool enableInternet = true;
  bool downloadArtwork = false;
  bool includeSystemAndMessagingAudio = false;
  bool keepBackgroundGradient = false;
  bool showQualityBadge = true;
  // Quality badge style (see QualityBadgeStyle); enum indices, null = default.
  int? qualityBadgeLook;
  int? qualityBadgeIcon;
  int? qualityBadgeColors;
  int? qualityBadgeSeparator;
  int? qualityBadgeShape;
  int? qualityBadgeLayout;
  // Bitmask of QualityBadgeField indices; null = all details.
  int? qualityBadgeFields;
  bool enablePlayerGradient = true;
  // Swaps the static player gradient for slow drifting primary/tertiary
  // color blobs with grain that react to the music (FFT). Only takes effect
  // while enablePlayerGradient is on.
  bool animatePlayerGradient = false;
  // Replaces the player's shuffle/repeat/next up/lyrics pill groups with
  // four icon-only tiles styled like the prev/play/next transport row.
  bool segmentedUtilityButtons = false;
  // Shows "Artist • Album" instead of just the artist under song titles
  // (lists, players, Home, Analyze, share card).
  bool showAlbumNextToArtist = false;
  // Quick Picks stay artist-only unless this is on too.
  bool showAlbumInQuickPicks = false;
  // Master switch for every haptic (AppHaptics). Stored inverted so rows
  // saved before it existed read back as "haptics on".
  bool disableHaptics = false;
  // Same animated gradient on the Home/Songs/Library background. Only takes
  // effect while keepBackgroundGradient is on.
  bool animateBackgroundGradient = false;
  bool settingsV2 = false;
  bool settingsV3 = false;
  bool showPerformanceOptimizer = false;
  String? customBackgroundImagePath;
  double bgBrightness = 0.5;
  double bgOpacity = 0.3;
  bool showHomeArtists = true;
  bool showHomeAlbums = false;
  bool showHomeGenres = true;
  bool showHomeRecent = true;
  // Null enables the new row for libraries created before this setting existed.
  bool? showHomePlaylists;
  List<String> homeSectionOrder = [
    'quick_picks',
    'playlists',
    'songs',
    'albums',
    'artists',
    'genres',
    'recent',
  ];
  bool enableSlideGesture = false;
  bool stopOnTaskRemoved = true;
  bool persistQueue = false;

  /// Remembers each song's own playback position (Song.lastPositionMs) so
  /// resuming it later -- even after playing other songs in between --
  /// starts back where it was left off, rather than from the beginning.
  /// Independent of persistQueue/resumeOnStart, which only resume whatever
  /// single song was playing when the app was last closed.
  bool keepSongProgress = false;

  bool fadePlayPauseStop = true;
  int playPauseStopFadeLength = 150; // ms (10ms-1000ms)
  bool resumeAfterCall = true;
  bool pauseOnDuck = false; // Unused, see audioFocusRequestOnPlay.
  bool resumeOnBluetoothConnect = false;
  bool resumeOnStart = false;
  bool permanentAudioFocusChange = false; // Unused, see above.
  bool dynamicColorActiveLyrics = true;
  // 0..1, makes the active lyric line's color more vibrant (0 = as is).
  // Rows saved before this field existed come back as NaN - treat as 0.
  double activeLyricsIntensity = 0.0;
  // "Accent Color Active Line" off: the active lyric line uses the accent
  // blended with white instead of the pure accent. Stored inverted so the
  // toggle defaults to on, also for settings saved before it existed.
  bool activeLyricsSoftColor = false;
  bool ambientColorBackground = true;
  String lyricsAlignment = 'left'; // 'left', 'center', 'right'
  bool dynamicAccentColor = true;
  int sortStrategyIndex = 0;
  bool sortAscending = false;
  int albumSortOptionIndex = 0;
  int artistSortOptionIndex = 0;
  int genreSortOptionIndex = 0;
  int collectionSortOptionIndex = 0;

  double homeDarkness = 0.62;
  double songsDarkness = 0.45;
  double libraryDarkness = 0.62;
  double musicDarkness = 0.62;
  double lyricsDarkness = 0.35;

  /// Desktop only: darkness of the overlay on the window's artwork background.
  /// Rows saved before the setting existed read back as NaN (treated as the
  /// default).
  static const double defaultDesktopBackgroundDarkness = 0.92;
  double desktopBackgroundDarkness = defaultDesktopBackgroundDarkness;

  // Home screen app-bar avatar. Filename only (not a full path) - it's
  // always resolved against AppAssets.avatarDir, so renaming that
  // folder is a one-place change instead of a data migration.
  String selectedAvatarAsset = 'logo_full.svg';
  // Only the default avatar (looper_main.svg) contains the swappable
  // "#C0E200" accent color - see SelectedAvatar's doc comment.
  bool avatarDynamicColor = false;

  bool useNewFont = true;
  String customFontFamily = 'Stack Sans Text';
  int customFontWeight = 400;
  int customFontWeightDelta = 0;
  bool useNewFontLyrics = true;
  String customFontFamilyLyrics = 'Stack Sans Text';
  String customFontWeightLyrics = 'Normal';
  int customFontWeightLyricsDelta = 0;
  int activeLyricsFontWeightDelta = 0;
  bool equalizerEnabled = false;
  List<double> globalEqualizerGains = [];
  bool equalizerGlobalMode = true;
  bool firstTimeEqualizer = true;
  bool enableAudioCache = true;
  int audioCacheSizeMB = 200;
  int audioCacheSecs = 120;
  int audioBackCacheSizeMB = 100;
  bool exclusiveHardwareMode = false;

  /// Legacy: the single provider picked before [lyricsProviderOrder]
  /// existed. It heads the order until the user arranges the list.
  String lyricsProvider = 'lrc.red';
  bool autoLyricsFallback = true;

  /// The lyrics services (LyricsProviderInfo ids) in the order lookups ask
  /// them. Empty = the default order; services added in a later version
  /// slot in at their default position.
  List<String> lyricsProviderOrder = [];

  /// Services the user switched off - skipped by automatic lookups.
  List<String> lyricsProvidersOff = [];

  /// One-time move of installs still on the old LRCLIB default to lrc.red
  /// (word-synced lyrics). Set once so a later deliberate LRCLIB pick sticks.
  bool lyricsProviderWordSyncMigrated = false;

  /// How the active lyric line is highlighted: 'line' (whole line), 'word'
  /// (each word lights up as it's sung) or 'char' (smooth wipe through the
  /// letters). Word/char use real word timing when the lyrics have it and
  /// approximate it otherwise.
  String lyricsSyncStyle = 'char';

  /// The lyrics timing offset every song starts with, in ms (positive =
  /// earlier). A song the user re-times keeps its own value in
  /// [Song.lyricsOffsetMs].
  static const int defaultLyricsOffsetMs = 200;

  /// Legacy: the old user-adjustable offset for all songs. Only read by the
  /// [lyricsOffsetPerSongMigrated] migration.
  int lyricsOffsetMs = defaultLyricsOffsetMs;

  /// [Song.lyricsOffsetMs] used to be added on top of [lyricsOffsetMs]; set
  /// once stored song offsets have been turned into the song's full offset.
  bool lyricsOffsetPerSongMigrated = false;

  /// [lyricsOffsetMs] used to mean positive = later; set once stored values
  /// have been flipped to the positive = earlier meaning.
  bool lyricsOffsetEarlierMigrated = false;

  /// One-time move of installs still on the old default app font (Space
  /// Grotesk) to Stack Sans Text. Set once so a later deliberate pick sticks.
  bool stackSansDefaultMigrated = false;

  /// Whether the user has already been shown the one-time "hidden gestures"
  /// tutorial on the Lyrics screen (tap to seek, long-press to select lines
  /// to share, pinch to resize, swipe down to close).
  bool lyricsGestureTutorialSeen = false;

  /// Desktop only: whole-UI scale, one of UiScaleSteps.steps. Rows saved
  /// before this field existed come back as NaN - read it through
  /// UiScaleSteps.normalize.
  double desktopUiScale = 1.0;

  /// Desktop only: lyrics text scale chosen by the user, multiplied by the
  /// automatic window-based scale. NaN on old rows - read it through
  /// LyricsScale.normalize.
  double lyricsFontScale = 1.0;
}
