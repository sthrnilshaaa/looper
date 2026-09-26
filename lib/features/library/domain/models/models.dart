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
}

@collection
class AppSettings {
  Id id = 0; // Always use ID 0 for single settings object

  List<String> libraryFolders = [];
  int? lastPlayedSongId;
  List<int> lastQueueSongIds = [];
  int lastQueueIndex = -1;
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
  bool enablePlayerGradient = true;
  // Swaps the static player gradient for slow drifting primary/tertiary
  // color blobs with grain that react to the music (FFT). Only takes effect
  // while enablePlayerGradient is on.
  bool animatePlayerGradient = false;
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
  List<String> homeSectionOrder = [
    'quick_picks',
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
  double lyricsDarkness = 0.50;

  // Home screen app-bar avatar. Filename only (not a full path) - it's
  // always resolved against assets/android_icons/avatars/, so renaming that
  // folder is a one-place change instead of a data migration.
  String selectedAvatarAsset = 'looper_player_logo.svg';
  // Only the default avatar (looper_main.svg) contains the swappable
  // "#C0E200" accent color - see SelectedAvatar's doc comment.
  bool avatarDynamicColor = false;

  bool useNewFont = true;
  String customFontFamily = 'Space Grotesk';
  int customFontWeight = 400;
  int customFontWeightDelta = 0;
  bool useNewFontLyrics = true;
  String customFontFamilyLyrics = 'Space Grotesk';
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
  String lyricsProvider = 'LRCLIB';
  bool autoLyricsFallback = true;

  /// Whether the user has already been shown the one-time "hidden gestures"
  /// tutorial on the Lyrics screen (tap to seek, long-press to select lines
  /// to share, pinch to resize, swipe down to close).
  bool lyricsGestureTutorialSeen = false;
}
