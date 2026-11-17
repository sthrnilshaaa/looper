import 'package:isar_community/isar.dart';
import 'package:looper_player/features/settings/domain/app_defaults.dart';

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
  // A picture the user picked, copied into the app. Null = song covers.
  String? coverPath;
}

@collection
class AppSettings {
  Id id = 0; // Always use ID 0 for single settings object

  List<String> libraryFolders = [];
  int? lastPlayedSongId;
  List<int> lastQueueSongIds = [];
  int lastQueueIndex = -1;
  double volume = AppDefaults.volume;
  int lastPositionMs = 0;
  bool shuffle = AppDefaults.shuffle;
  int repeatMode = AppDefaults.repeatMode; // 0: off, 1: one, 2: all
  String language = AppDefaults.language;
  bool enableDynamicTheming = AppDefaults.enableDynamicTheming;
  bool darkTheme = AppDefaults.darkTheme;
  bool saveDynamicColor = AppDefaults.saveDynamicColor;
  bool dynamicLyrics = AppDefaults.dynamicLyrics;
  bool blurredArtworkForLyrics = AppDefaults.blurredArtworkForLyrics;
  int accentColor = AppDefaults.accentColor; // Default Green
  bool audioFocus = AppDefaults.audioFocus;
  // Unused: audio focus is owned by mpv_audio_kit, which can't honour
  // these (nor pauseOnDuck / permanentAudioFocusChange below). Kept only
  // so the Isar schema and existing databases stay unchanged.
  bool audioFocusRequestOnPlay = AppDefaults.audioFocusRequestOnPlay;
  bool audioFocusReleaseOnPause = AppDefaults.audioFocusReleaseOnPause;
  bool audioFocusStopOnOtherSession = AppDefaults.audioFocusStopOnOtherSession;
  bool audioFocusRestartOnGain = AppDefaults.audioFocusRestartOnGain;
  bool disableSquiggle = AppDefaults.disableSquiggle;
  bool disableAnimatedDuration = AppDefaults.disableAnimatedDuration;

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
  bool progressWaveFromStart = AppDefaults.progressWaveFromStart;
  bool progressFreezeWhenPaused = AppDefaults.progressFreezeWhenPaused;
  bool progressGrowThumbOnDrag = AppDefaults.progressGrowThumbOnDrag;

  // Now Playing artwork visualizer, see ArtworkVisualizerType. Null means
  // none / the default intensity / artwork colors.
  int? artworkVisualizer;
  int? artworkVisualizerIntensity;
  int? artworkVisualizerColors;
  // How long the effect waits after the audio is analysed, to line up
  // with what's actually heard (output buffers, Bluetooth).
  int? artworkVisualizerSyncMs;
  bool disableBlur = AppDefaults.disableBlur;
  // Forces the blur behind bottom sheets on regardless of Dynamic Theming --
  // that toggle changes accent colors/gradients app-wide too, so this gives
  // sheets their blur without needing all of that. Independent of disableBlur,
  // which only gates the Dynamic Theming blur path (see app_bottom_sheet.dart).
  bool alwaysBlurSheets = AppDefaults.alwaysBlurSheets;
  // The Dynamic Theming art background on the player screen only, without
  // the app-wide accent/gradient changes.
  bool playerDynamicBackground = AppDefaults.playerDynamicBackground;
  bool enableInternet = AppDefaults.enableInternet;
  bool downloadArtwork = AppDefaults.downloadArtwork;
  bool includeSystemAndMessagingAudio =
      AppDefaults.includeSystemAndMessagingAudio;
  bool keepBackgroundGradient = AppDefaults.keepBackgroundGradient;

  /// Set once the Home redesign's new defaults (▶▶ avatar, no kept
  /// background gradient) were applied to settings saved before it.
  bool homeRedesignV1 = false;
  bool showQualityBadge = AppDefaults.showQualityBadge;
  // Quality badge style (see QualityBadgeStyle); enum indices, null = default.
  int? qualityBadgeLook;
  int? qualityBadgeIcon;
  int? qualityBadgeColors;
  int? qualityBadgeSeparator;
  int? qualityBadgeShape;
  int? qualityBadgeLayout;
  // Bitmask of QualityBadgeField indices; null = all details.
  int? qualityBadgeFields;
  bool enablePlayerGradient = AppDefaults.enablePlayerGradient;
  // Swaps the static player gradient for slow drifting primary/tertiary
  // color blobs with grain that react to the music (FFT). Only takes effect
  // while enablePlayerGradient is on.
  bool animatePlayerGradient = AppDefaults.animatePlayerGradient;
  // Replaces the player's shuffle/repeat/next up/lyrics pill groups with
  // four icon-only tiles styled like the prev/play/next transport row.
  bool segmentedUtilityButtons = AppDefaults.segmentedUtilityButtons;
  // How much more saturated the app accent is drawn (0..1, Android). Null
  // = AppAccent.defaultVibrancy.
  double? accentVibrancy;
  // Shows the current lyric line under the cover on the portrait player.
  bool playerLyricLine = AppDefaults.playerLyricLine;
  // How that line changes: 'cube', 'roll', 'flip' or 'blur' ('' = cube).
  String playerLyricLineTransition = AppDefaults.playerLyricLineTransition;
  // Portrait Now Playing layout: 'classic', 'arc' or 'linear' ('' = classic).
  String playerStyle = AppDefaults.playerStyle;
  // Arc / linear players: paint the active lyric line and the seek bar in
  // the accent colour (classic always does).
  bool playerStyleAccent = AppDefaults.playerStyleAccent;
  // Card player only: plain black background (wins over the accent one).
  bool cardBlackBackground = AppDefaults.cardBlackBackground;
  // Card player only: darkened accent (or the gradient) as the background.
  bool cardAccentBackground = AppDefaults.cardAccentBackground;
  // Styled players (card / arc / linear): paint the active lyric line and progress bar in the
  // accent colour (independent of the background choice).
  bool cardAccentColors = AppDefaults.cardAccentColors;
  // Styled players (card / arc / linear): show blurred album artwork as the background
  // when neither plain black nor accent background is active.
  bool playerStyleBlur = AppDefaults.playerStyleBlur;
  // Shows "Artist • Album" instead of just the artist under song titles
  // (lists, players, Home, Analyze, share card).
  bool showAlbumNextToArtist = AppDefaults.showAlbumNextToArtist;
  // Quick Picks stay artist-only unless this is on too.
  bool showAlbumInQuickPicks = AppDefaults.showAlbumInQuickPicks;
  // Master switch for every haptic (AppHaptics). Stored inverted so rows
  // saved before it existed read back as "haptics on".
  bool disableHaptics = AppDefaults.disableHaptics;
  // Haptic strength: 0 = Low (the original tuning), 1 = Medium, 2 = High.
  // Rows saved before it existed read back as 0, i.e. unchanged.
  int hapticStrength = AppDefaults.hapticStrength;
  // Same animated gradient on the Home/Songs/Library background. Only takes
  // effect while keepBackgroundGradient is on.
  bool animateBackgroundGradient = AppDefaults.animateBackgroundGradient;
  bool settingsV2 = false;
  bool settingsV3 = false;
  bool showPerformanceOptimizer = AppDefaults.showPerformanceOptimizer;
  String? customBackgroundImagePath;
  double bgBrightness = AppDefaults.bgBrightness;
  double bgOpacity = AppDefaults.bgOpacity;
  bool showHomeArtists = AppDefaults.showHomeArtists;
  bool showHomeAlbums = AppDefaults.showHomeAlbums;
  bool showHomeGenres = AppDefaults.showHomeGenres;
  bool showHomeRecent = AppDefaults.showHomeRecent;
  // Null enables the new row for libraries created before this setting existed.
  bool? showHomePlaylists;
  static const defaultHomeSectionOrder = AppDefaults.defaultHomeSectionOrder;
  List<String> homeSectionOrder = [...defaultHomeSectionOrder];
  bool enableSlideGesture = AppDefaults.enableSlideGesture;
  bool stopOnTaskRemoved = AppDefaults.stopOnTaskRemoved;
  bool persistQueue = AppDefaults.persistQueue;

  /// Remembers each song's own playback position (Song.lastPositionMs) so
  /// resuming it later -- even after playing other songs in between --
  /// starts back where it was left off, rather than from the beginning.
  /// Independent of persistQueue/resumeOnStart, which only resume whatever
  /// single song was playing when the app was last closed.
  bool keepSongProgress = AppDefaults.keepSongProgress;

  bool fadePlayPauseStop = AppDefaults.fadePlayPauseStop;
  int playPauseStopFadeLength =
      AppDefaults.playPauseStopFadeLength; // ms (10ms-1000ms)
  bool resumeAfterCall = AppDefaults.resumeAfterCall;
  bool pauseOnDuck =
      AppDefaults.pauseOnDuck; // Unused, see audioFocusRequestOnPlay.
  bool resumeOnBluetoothConnect = AppDefaults.resumeOnBluetoothConnect;
  bool resumeOnStart = AppDefaults.resumeOnStart;
  bool permanentAudioFocusChange =
      AppDefaults.permanentAudioFocusChange; // Unused, see above.
  bool dynamicColorActiveLyrics = AppDefaults.dynamicColorActiveLyrics;
  // 0..1, makes the active lyric line's color more vibrant (0 = as is).
  // Default 35 %. Rows saved before this field existed come back as NaN -
  // treat as the default.
  double activeLyricsIntensity = AppDefaults.activeLyricsIntensity;
  // Opacity of the lyric lines around the playing one, 0.1 (most see-through)
  // to 1 (solid). Null = the default 35 %.
  double? inactiveLyricsOpacity;
  // "Accent Color Active Line" off: the active lyric line uses the accent
  // blended with white instead of the pure accent. Stored inverted so the
  // toggle defaults to on, also for settings saved before it existed.
  bool activeLyricsSoftColor = AppDefaults.activeLyricsSoftColor;
  // "Group Continued Lines" off: two lyric lines sung in one breath are no
  // longer shown as one (LyricLine.pairHeads). Stored inverted so grouping
  // stays on by default, also for settings saved before it existed.
  bool lyricsNoLineGrouping = AppDefaults.lyricsNoLineGrouping;
  bool enableLyricsGradient = AppDefaults.enableLyricsGradient;
  bool ambientColorBackground = AppDefaults.ambientColorBackground;
  String lyricsAlignment =
      AppDefaults.lyricsAlignment; // 'left', 'center', 'right'
  bool dynamicAccentColor = AppDefaults.dynamicAccentColor;
  int sortStrategyIndex = AppDefaults.defaultSongSortStrategyIndex;
  bool sortAscending = AppDefaults.defaultSortAscending;
  int albumSortOptionIndex = AppDefaults.defaultAlbumSortOptionIndex;
  int artistSortOptionIndex = AppDefaults.defaultArtistSortOptionIndex;
  int genreSortOptionIndex = AppDefaults.defaultGenreSortOptionIndex;
  int collectionSortOptionIndex = AppDefaults.defaultCollectionSortOptionIndex;

  /// Artist pages list songs under album headers instead of one list.
  bool artistGroupByAlbum = AppDefaults.artistGroupByAlbum;

  double homeDarkness = AppDefaults.homeDarkness;
  double songsDarkness = AppDefaults.songsDarkness;
  double libraryDarkness = AppDefaults.libraryDarkness;
  double musicDarkness = AppDefaults.musicDarkness;
  double lyricsDarkness = AppDefaults.lyricsDarkness;

  /// Desktop only: darkness of the overlay on the window's artwork background.
  /// Rows saved before the setting existed read back as NaN (treated as the
  /// default).
  static const double defaultDesktopBackgroundDarkness =
      AppDefaults.defaultDesktopBackgroundDarkness;
  double desktopBackgroundDarkness = defaultDesktopBackgroundDarkness;

  // Home screen app-bar avatar. Filename only (not a full path) - it's
  // always resolved against AppAssets.avatarDir, so renaming that
  // folder is a one-place change instead of a data migration.
  String selectedAvatarAsset = AppDefaults.selectedAvatarAsset;
  // Name shown on the Account screen greeting. Empty = not set yet.
  String userName = '';
  // Profile photo the user picked, copied into app support storage.
  String userPhotoPath = '';
  // Only the default avatar (looper_main.svg) contains the swappable
  // "#C0E200" accent color - see SelectedAvatar's doc comment.
  bool avatarDynamicColor = AppDefaults.avatarDynamicColor;

  bool useNewFont = AppDefaults.useNewFont;
  String customFontFamily = AppDefaults.customFontFamily;
  int customFontWeight = AppDefaults.customFontWeight;
  int customFontWeightDelta = AppDefaults.customFontWeightDelta;
  // NaN on rows saved before this field existed; read through the getter.
  double letterSpacingPercent = AppDefaults.letterSpacingPercent;
  bool useNewFontLyrics = AppDefaults.useNewFontLyrics;
  String customFontFamilyLyrics = AppDefaults.customFontFamilyLyrics;
  String customFontWeightLyrics = AppDefaults.customFontWeightLyrics;
  int customFontWeightLyricsDelta = AppDefaults.customFontWeightLyricsDelta;
  int activeLyricsFontWeightDelta = AppDefaults.activeLyricsFontWeightDelta;
  bool equalizerEnabled = AppDefaults.equalizerEnabled;
  List<double> globalEqualizerGains = [];
  bool equalizerGlobalMode = AppDefaults.equalizerGlobalMode;
  bool firstTimeEqualizer = AppDefaults.firstTimeEqualizer;
  bool enableAudioCache = AppDefaults.enableAudioCache;
  int audioCacheSizeMB = AppDefaults.audioCacheSizeMB;
  int audioCacheSecs = AppDefaults.audioCacheSecs;
  int audioBackCacheSizeMB = AppDefaults.audioBackCacheSizeMB;
  bool exclusiveHardwareMode = AppDefaults.exclusiveHardwareMode;

  /// Legacy: the single provider picked before [lyricsProviderOrder]
  /// existed. It heads the order until the user arranges the list.
  String lyricsProvider = AppDefaults.defaultLyricsProvider;
  bool autoLyricsFallback = AppDefaults.autoLyricsFallback;

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
  String lyricsSyncStyle = AppDefaults.lyricsSyncStyle;

  /// The lyrics timing offset every song starts with, in ms (positive =
  /// earlier). A song the user re-times keeps its own value in
  /// [Song.lyricsOffsetMs].
  static const int defaultLyricsOffsetMs = AppDefaults.defaultLyricsOffsetMs;

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

  /// One-time move of installs still on the old 0 % active-line intensity
  /// default to the new 35 %. Set once so a later deliberate 0 % sticks.
  bool activeLyricsIntensityDefaultMigrated = false;

  /// Whether the user has already been shown the one-time "hidden gestures"
  /// tutorial on the Lyrics screen (tap to seek, long-press to select lines
  /// to share, pinch to resize, swipe down to close).
  bool lyricsGestureTutorialSeen = AppDefaults.lyricsGestureTutorialSeen;

  /// Whole-UI scale on every platform, one of UiScaleSteps.steps. The name
  /// predates Android support; renaming it would drop saved values. Rows
  /// saved before this field existed come back as NaN - read it through
  /// UiScaleSteps.normalize.
  double desktopUiScale = AppDefaults.desktopUiScale;

  /// Desktop only: lyrics text scale chosen by the user, multiplied by the
  /// automatic window-based scale. NaN on old rows - read it through
  /// LyricsScale.normalize.
  double lyricsFontScale = AppDefaults.lyricsFontScale;

  /// Whether to keep the screen on while the player or lyrics are open.
  /// Null on existing installs, treated as true.
  bool? keepScreenAwake;

  /// Whether to lock display to the highest available refresh rate (e.g. 120Hz).
  /// Null on existing installs, treated as true.
  bool? forceHighRefreshRate;
}
