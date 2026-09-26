// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get about => 'About';

  @override
  String get aboutAndMaintainers => 'About & Maintainers';

  @override
  String get aboutApp => 'About App';

  @override
  String get aboutLooperPlayer => 'ABOUT LOOPER PLAYER';

  @override
  String get accentColor => 'Accent Color';

  @override
  String get accentColorDesc => 'Select manual theme accent color';

  @override
  String get acousticSpectralAnalysis => 'ACOUSTIC & SPECTRAL ANALYSIS';

  @override
  String get activeCallCannotPlay =>
      'Playback blocked: Cannot play music during an active call';

  @override
  String get adaptColorsArtwork => 'Adapt app colors to album artwork';

  @override
  String addedTo(String name) {
    return 'Added to $name';
  }

  @override
  String get addedToQueue => 'Added to queue';

  @override
  String get addFolder => 'Add Folder';

  @override
  String get addToFavorites => 'Add to Favorites';

  @override
  String get addToPlaylists => 'Add to Playlists';

  @override
  String get addToQueue => 'Add to Queue';

  @override
  String get album => 'Album';

  @override
  String get albums => 'Albums';

  @override
  String get albumsRowDesc => 'Horizontal shelf of albums';

  @override
  String get allFilesAccess => 'ALL FILES ACCESS (RECOMMENDED)';

  @override
  String get allSongs => 'All Songs';

  @override
  String get appDetailsCreator =>
      'Application details, creator, and design team info';

  @override
  String get appearance => 'Appearance';

  @override
  String get appInfoPrivacy => 'APP INFO & PRIVACY';

  @override
  String get appTitle => 'Looper Player';

  @override
  String get artist => 'Artist';

  @override
  String get artists => 'Artists';

  @override
  String get artistsRowDesc => 'Horizontal shelf of artists';

  @override
  String get ascending => 'Ascending';

  @override
  String get audioCrossfade => 'Audio Crossfade';

  @override
  String get audioCrossfadeDesc =>
      'When one song ends and the next begins, the current track fades out while the next track fades in at the same time. This gives a continuous, DJ-like flow.';

  @override
  String get audioFocusDenied =>
      'Playback paused: Audio focus denied by system';

  @override
  String get audioPlayback => 'Audio & Playback';

  @override
  String get audioPlaybackDesc => 'Crossfade, silence gap, and fading settings';

  @override
  String get autoCrossfadeDuration => 'Auto Crossfade Duration';

  @override
  String get autoCrossfadeDurationDesc =>
      'The overlap time used when the app automatically advances to the next track. Example: 2300ms means the next song starts 2.3 seconds before the current song fully ends.';

  @override
  String get backToMainView => 'BACK TO MAIN VIEW';

  @override
  String get cancel => 'Cancel';

  @override
  String get categories => 'Categories';

  @override
  String get center => 'Center';

  @override
  String get clear => 'Clear';

  @override
  String get clearQueue => 'Clear';

  @override
  String get connectDevice => 'CONNECT DEVICE';

  @override
  String get corePurpose => 'Core Purpose';

  @override
  String get corePurposeDesc =>
      'Looper Player is an offline-first, high-fidelity audio player designed for music enthusiasts who want absolute control over their local library, gapless playback, and fluid, synchronized lyrics scrolling.';

  @override
  String get create => 'Create';

  @override
  String get createPlaylist => 'Create Playlist';

  @override
  String get creatorAndMaintainer => 'Creator and Maintainer';

  @override
  String get customAccentColor => 'Custom Accent Color';

  @override
  String get customizeColorsTheme =>
      'Customize app colors, theme, and lyrics backgrounds';

  @override
  String get dateAdded => 'Date Added';

  @override
  String get deepStorageScanProgress => 'DEEP STORAGE SCAN IN PROGRESS...';

  @override
  String get delete => 'Delete';

  @override
  String get deleteFile => 'Delete File';

  @override
  String get deletePlaylist => 'Delete Playlist';

  @override
  String deletePlaylistConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get deleteSong => 'Delete Song';

  @override
  String get deleteSongConfirm =>
      'Are you sure you want to delete this song from disk?';

  @override
  String get descending => 'Descending';

  @override
  String get designerAndMaintainer => 'Designer and Maintainer';

  @override
  String get disableBlurEffects => 'Disable Blur Effects';

  @override
  String get disableSquigglyProgressBar =>
      'Disable squiggly wave progress bar animation';

  @override
  String get downloadAudioDirectly => 'DOWNLOAD AUDIO DIRECTLY';

  @override
  String get downloadingLyricsOffline =>
      'Downloading lyrics for offline use...';

  @override
  String get downloadMissingArtwork => 'Download Missing Artwork';

  @override
  String get downloadMissingArtworkDesc =>
      'Automatically download high-resolution cover artwork for songs from iTunes';

  @override
  String get duration => 'Duration';

  @override
  String get dynamicAccentColor => 'Dynamic Accent Color';

  @override
  String get dynamicAccentColorDesc =>
      'Update only the accent color dynamically from the artwork';

  @override
  String get dynamicBgOnlyLyrics => 'Dynamic background only for lyrics';

  @override
  String get dynamicColorActiveLyrics => 'Dynamic Color Active Line';

  @override
  String get dynamicColorActiveLyricsDesc =>
      'Use extracted artwork colors for the currently playing lyrics line';

  @override
  String get dynamicLyricsBg => 'Dynamic Lyrics BG';

  @override
  String get dynamicLyricsBgDesc => 'Apply album-art blur to lyrics screen';

  @override
  String get dynamicTheming => 'Dynamic Theming';

  @override
  String get emptyLibraryDesc =>
      'We couldn\'t find any supported music files in your library. Add folders or run a search scan.';

  @override
  String get enableNetworkLyricsArt =>
      'Enable network use for online lyrics & artist art';

  @override
  String get enablePlayerGradient => 'Music Screen Gradient';

  @override
  String get enablePlayerGradientDesc =>
      'Enable the radial accent gradient background on the now playing screen';

  @override
  String get fadeDuration => 'Fade Duration';

  @override
  String get fadeDurationDesc =>
      'How long the fade takes for play, pause, and stop actions. Example: 150ms means the audio becomes audible or silent very quickly, but still smoothly.';

  @override
  String get fadeOnSeek => 'Fade on Seek';

  @override
  String get fadeOnSeekDesc =>
      'Temporarily lower the volume while the user scrubs or jumps to another position, then bring it back up after the seek completes. This prevents pops, glitches, or harsh jumps during seeking.';

  @override
  String get fadePlayPauseStop => 'Fade Play/Pause/Stop';

  @override
  String get fadePlayPauseStopDesc =>
      'Smoothly ramp volume up when playback starts, and ramp it down when pausing or stopping. This avoids clicks and makes transitions feel natural.';

  @override
  String get favorites => 'Favorites';

  @override
  String get fileInformation => 'File Information';

  @override
  String get flatProgressBar => 'Flat Progress Bar';

  @override
  String get folders => 'Folders';

  @override
  String get genre => 'Genre';

  @override
  String get genres => 'Genres';

  @override
  String get genresRowDesc => 'Horizontal shelf of music genres';

  @override
  String get goStart => 'GO START';

  @override
  String get grant => 'GRANT';

  @override
  String get granted => 'GRANTED';

  @override
  String get history => 'History';

  @override
  String get home => 'Home';

  @override
  String get homeDarkness => 'Home Screen Darkness';

  @override
  String get homeDarknessDesc =>
      'Adjust background overlay darkness for the Home screen';

  @override
  String get homeDashboardSettings => 'Home Dashboard Settings';

  @override
  String get homeDashboardSettingsDesc =>
      'Customize horizontal rows on your Home screen';

  @override
  String get internetMode => 'Internet Mode';

  @override
  String get keepBackgroundGradient => 'Keep Background Gradient';

  @override
  String get keepBackgroundGradientDesc =>
      'Keep the background gradient across all application screens';

  @override
  String get animatePlayerGradient => 'Animated Gradient';

  @override
  String get animatePlayerGradientDesc =>
      'Slowly moves the primary and tertiary colors with a soft grain, reacting to the music';

  @override
  String get animateBackgroundGradient => 'Animated Background';

  @override
  String get animateBackgroundGradientDesc =>
      'Uses the animated gradient on the Home, Songs and Library backgrounds';

  @override
  String get language => 'Language';

  @override
  String get left => 'Left';

  @override
  String get library => 'Library';

  @override
  String get libraryDarkness => 'Library Screen Darkness';

  @override
  String get libraryDarknessDesc =>
      'Adjust background overlay darkness for the Library screen';

  @override
  String get libraryFoldersSync =>
      'Folders, rescan triggers, reset database, and offline sync';

  @override
  String get librarySettings => 'Library Settings';

  @override
  String get loadingMusicLibrary => 'LOADING MUSIC LIBRARY';

  @override
  String get loadingMusicLibraryDesc =>
      'Building premium indexes, setting up hardware listeners, and optimizing visual caches.';

  @override
  String get loadingPhase1 => 'INTERROGATING AUDIO STORAGE...';

  @override
  String get loadingPhase2 => 'REFRESHING MUSIC ENGINE...';

  @override
  String get loadingPhase3 => 'EXTRACTING ACOUSTIC DATA...';

  @override
  String get loadingPhase4 => 'OPTIMIZING PLAYBACK MEMORY...';

  @override
  String get lyrics => 'Lyrics';

  @override
  String get lyricsAlignment => 'Lyrics Alignment';

  @override
  String get lyricsAlignmentDesc => 'Align text positions for scrolling lyrics';

  @override
  String get lyricsDarkness => 'Lyrics Screen Darkness';

  @override
  String get lyricsDarknessDesc =>
      'Adjust background overlay darkness for the Lyrics screen';

  @override
  String get lyricsProvider => 'Lyrics Provider';

  @override
  String get lyricsProviderDesc =>
      'Online lyrics fetched from lrclib.net (LRCLIB)';

  @override
  String get maintainersAndDesigners => 'Maintainers & Designers';

  @override
  String get manageAudioFocus => 'Manage Audio Focus';

  @override
  String get manageAudioFocusDesc =>
      'Respond properly to system audio focus changes.';

  @override
  String get manageAudioFocusTitle => 'Manage Audio Focus';

  @override
  String get manageLanguageAndFocus =>
      'Manage language preferences and caller focus state';

  @override
  String get audioFocusGetFocus => 'Get Focus';

  @override
  String get audioFocusGetFocusDesc =>
      'Request audio focus when playback begins.';

  @override
  String get audioFocusReleaseFocus => 'Release Focus';

  @override
  String get audioFocusReleaseFocusDesc =>
      'Release audio focus when playback pauses or stops.';

  @override
  String get audioFocusStopOnOtherSession =>
      'Stop Music on Other Music Session';

  @override
  String get audioFocusStopOnOtherSessionDesc =>
      'Pause playback when another app starts playing audio.';

  @override
  String get audioFocusRestartOnGain => 'Restart Music on Focus Gain';

  @override
  String get audioFocusRestartOnGainDesc =>
      'Resume playback automatically when audio focus returns, only if playback was interrupted by focus loss.';

  @override
  String get pauseOnDuckTitle => 'Pause on Duck';

  @override
  String get pauseOnDuckDesc =>
      'Pause playback instead of lowering volume when another app plays a transient sound (e.g. notifications, navigation directions).';

  @override
  String get resumeOnBluetoothConnectTitle => 'Resume on Bluetooth Connect';

  @override
  String get resumeOnBluetoothConnectDesc =>
      'Resume playback automatically when a Bluetooth audio device (headphones, car kit) reconnects.';

  @override
  String get manualCrossfadeDuration => 'Manual Crossfade Duration';

  @override
  String get manualCrossfadeDurationDesc =>
      'The overlap time used when the user manually skips to the next or previous track. Usually this can be different from auto-crossfade so manual skips feel more controlled.';

  @override
  String get matchingLyrics => 'MATCHING LYRICS';

  @override
  String get metadataDetails => 'Metadata Details';

  @override
  String get mostPlayed => 'Most Played';

  @override
  String get musicAudioAccess => 'MUSIC & AUDIO ACCESS';

  @override
  String get musicDarkness => 'Music Player Darkness';

  @override
  String get musicDarknessDesc =>
      'Adjust background overlay darkness for the Music Player screen';

  @override
  String get musicLibrary => 'Music Library';

  @override
  String get muteOrPauseCalls =>
      'Mute or pause during calls and other audio activity';

  @override
  String get newPlaylist => 'New Playlist';

  @override
  String get newTitle => 'New Title';

  @override
  String get nextUp => 'Next Up';

  @override
  String get noAlbumsFound => 'No albums found';

  @override
  String get noArtistsFound => 'No artists found';

  @override
  String get noFavoritesYet => 'No favorites yet';

  @override
  String get noHistoryYet => 'No history yet';

  @override
  String get noLyrics => 'No Lyrics Found';

  @override
  String get noMusicDetected => 'NO MUSIC DETECTED';

  @override
  String get noPlaylistsCreated => 'No playlists created yet.';

  @override
  String get noPlaylistsYet => 'No playlists yet';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get noSongsFound => 'No songs found';

  @override
  String get notificationAccess => 'NOTIFICATION ACCESS';

  @override
  String get nowPlaying => 'Now Playing';

  @override
  String get performanceOptimizerDashboard => 'Performance Optimizer Dashboard';

  @override
  String get performanceOptimizerDashboardDesc =>
      'Show real-time performance optimizer stats overlay';

  @override
  String get permanentFocusChangePause => 'Permanent Focus Change Pause';

  @override
  String get permanentFocusChangePauseDesc =>
      'Pause playing automatically on permanent audio focus loss';

  @override
  String get plainTimestamps => 'Plain Timestamps';

  @override
  String get play => 'Play';

  @override
  String get playAll => 'Play All';

  @override
  String get playbackAudio => 'Playback & Language';

  @override
  String get playlists => 'Playlists';

  @override
  String get playNext => 'Play Next';

  @override
  String get playQueue => 'Play Queue';

  @override
  String get pressBackExit => 'Press back again to exit';

  @override
  String get privacySafety => 'Privacy & Safety';

  @override
  String get privacySafetyDesc =>
      '100% private and offline-first. Your tracks, playback history, favorites, and configuration stay strictly inside a secure Isar database on your local device. We do not track, collect, or share your usage data or preferences.';

  @override
  String get pureBlackOled => 'Pure Black (OLED)';

  @override
  String get pureBlackOledDesc => 'Use absolute black backgrounds';

  @override
  String get queue => 'Queue';

  @override
  String get queueIsEmpty => 'Queue is empty';

  @override
  String get quickPicks => 'Quick Picks';

  @override
  String get quickPicksRowDesc => 'Your most played grid of songs';

  @override
  String get readyToScan => 'Ready to Scan';

  @override
  String get recentlyAddedSongsRowDesc => 'A list of your latest imports';

  @override
  String get recentlyPlayed => 'Recently Played';

  @override
  String get recentPlayed => 'Recent Played';

  @override
  String get recentRowDesc => 'Horizontal shelf of recently played tracks';

  @override
  String get removedFromPlaylist => 'Removed from Playlist';

  @override
  String get removeFromFavorites => 'Remove from Favorites';

  @override
  String get removeFromPlaylist => 'Remove from Playlist';

  @override
  String get rename => 'Rename';

  @override
  String get renameFile => 'Rename File';

  @override
  String get renamePlaylist => 'Rename Playlist';

  @override
  String get renameSong => 'Rename Song';

  @override
  String get reorderDashboardSections => 'Reorder Dashboard Sections';

  @override
  String get reorderDashboardSectionsDesc =>
      'Drag and drop to set preferred dashboard order';

  @override
  String get includeOtherDeviceAudioTitle => 'Include other device audio';

  @override
  String get includeOtherDeviceAudioDesc =>
      'Scan ringtones, notifications, alarms, WhatsApp and Telegram audio';

  @override
  String get rescanLibrary => 'Rescan Library';

  @override
  String get rescanStorage => 'RESCAN STORAGE';

  @override
  String get reset => 'Reset';

  @override
  String get resetLibrary => 'Reset & Rescan';

  @override
  String get resetLibraryConfirm =>
      'This will clear all songs, albums, and artists and perform a full rescan of your folders.';

  @override
  String get resetLibraryConfirmNew =>
      'This will remove all songs from your library. Your music files will not be deleted.';

  @override
  String get resetLibraryDesc => 'Remove all songs from your indexed library';

  @override
  String get resumeAfterCallDesc =>
      'Resume playing automatically on call hang up (if paused by call)';

  @override
  String get resumeAfterCallTitle => 'Resume after Call';

  @override
  String get resumeOnStartDesc =>
      'Restore the previous playback state when the app or player service starts again.';

  @override
  String get resumeOnStartTitle => 'Resume on Start';

  @override
  String get persistQueueTitle => 'Persist Last Queue';

  @override
  String get persistQueueDesc =>
      'Saves the last played song, queue order, and playback position so the app can restore the same session after restart. In real use, this means when the app is reopened, the user can continue from the same song list instead of starting over.';

  @override
  String get keepSongProgressTitle => 'Keep Song Progress';

  @override
  String get keepSongProgressDesc =>
      'Remembers each song\'s own playback position separately. Switch to another song partway through and come back later — even after playing other songs in between — and it resumes right where you left off instead of starting over.';

  @override
  String get right => 'Right';

  @override
  String scanCompleteSongsDetected(int count) {
    return 'SCAN COMPLETE: $count SONGS DETECTED!';
  }

  @override
  String get scanForMusic => 'SCAN FOR MUSIC';

  @override
  String get scanIndexLocalDesc => 'Scan & index local music files';

  @override
  String get scanLibrary => 'Scan Library';

  @override
  String get scanningInBackground => 'Scanning in background...';

  @override
  String get scanningLibrary => 'Scanning library...';

  @override
  String get scanningStorage => 'SCANNING STORAGE...';

  @override
  String get scanningStorageDesc =>
      'Traversing directory trees to discover audio tracks. Please hold on...';

  @override
  String get search => 'Search';

  @override
  String get searchLibraryHint => 'Search your entire library';

  @override
  String get searchSongsHint => 'Search songs';

  @override
  String get seekFadeDuration => 'Seek Fade Duration';

  @override
  String get seekFadeDurationDesc =>
      'How long the seek fade-out and fade-in takes. Example: 50ms is a very short protective fade around seek changes.';

  @override
  String get selectAppLanguage => 'Select application language';

  @override
  String get selectCustomColor => 'Select Custom Color';

  @override
  String get selectCustomFolder => 'SELECT CUSTOM FOLDER';

  @override
  String get selectFolderIndex => 'Select folder to index music files';

  @override
  String get selectSpecificFolder => 'SELECT SPECIFIC FOLDER';

  @override
  String get settings => 'Settings';

  @override
  String get share => 'Share';

  @override
  String get shareFile => 'Share File';

  @override
  String get showAlbumsRow => 'Show Albums Row';

  @override
  String get showAlbumsRowDesc =>
      'Display a horizontal list of albums on your Home screen';

  @override
  String get showArtistsRow => 'Show Artists Row';

  @override
  String get showArtistsRowDesc =>
      'Display a horizontal list of artists on your Home screen';

  @override
  String get showGenresRow => 'Show Genres Row';

  @override
  String get showGenresRowDesc =>
      'Display a horizontal list of genres on your Home screen';

  @override
  String get showLess => 'Show Less';

  @override
  String get showMore => 'Show More';

  @override
  String get showQualityBadge => 'Show Quality Badge';

  @override
  String get showQualityBadgeDesc =>
      'Display audio quality information badge on the now playing screen';

  @override
  String get showRecentRow => 'Show Recent Row';

  @override
  String get showRecentRowDesc =>
      'Display a horizontal list of recently played tracks on your Home screen';

  @override
  String get silenceBetweenTracksDesc =>
      'Adds a gap between songs. At 0ms, tracks play gaplessly. At a higher value, the app inserts a pause between tracks, which is useful for live recordings, playlists that need breathing room, or older-style album playback.';

  @override
  String get silenceBetweenTracksTitle => 'Silence Between Tracks';

  @override
  String get songDeletedDbOnly =>
      'Song removed from library (physical file read-only)';

  @override
  String get songDeletedSuccess => 'Song deleted successfully';

  @override
  String get songDeleteFailed => 'Failed to delete song';

  @override
  String get songDetails => 'Song Details';

  @override
  String get songDetailsAndFrequency => 'Song Details & Frequency';

  @override
  String get songRenamedDbOnly =>
      'Song renamed in app library (physical file read-only)';

  @override
  String get songRenamedSuccess => 'Song renamed successfully';

  @override
  String get songRenameFailed => 'Failed to rename song';

  @override
  String get songs => 'Songs';

  @override
  String get songsDarkness => 'Songs Screen Darkness';

  @override
  String get songsDarknessDesc =>
      'Adjust background overlay darkness for the Songs screen';

  @override
  String get sortBy => 'Sort By';

  @override
  String get sortOrder => 'Sort Order';

  @override
  String get sourceCode => 'Source Code';

  @override
  String get stopServiceOnAppDismissal => 'Stop Service on App Dismissal';

  @override
  String get stopServiceOnAppDismissalDesc =>
      'Stop background service and close app when dismissed';

  @override
  String get storagePermissionRequired =>
      'Storage permissions are required to scan device memory.';

  @override
  String get syncLyricsOffline => 'Sync Lyrics (Offline)';

  @override
  String get systemDefault => 'System Default';

  @override
  String get systemPermissionChecklist => 'SYSTEM PERMISSION CHECKLIST';

  @override
  String get technicalInfoFrequency => 'Technical Info & Frequency';

  @override
  String get theme => 'Theme';

  @override
  String get title => 'Title';

  @override
  String get todayMixForYou => 'Today Mix for you';

  @override
  String get toggleFavorite => 'Toggle Favorite';

  @override
  String get shuffleTitle => 'Shuffle';

  @override
  String get shuffleDisabledDesc =>
      'Play songs in their original queue order. Turning shuffle off keeps the current song playing and restores the remaining queue to its original sequence without affecting playback or playback history.';

  @override
  String get shuffleEnabledDesc =>
      'Randomize the remaining songs while keeping the current song unchanged. The generated shuffle order remains consistent until the queue changes or a new shuffle is requested, preventing repeated or skipped tracks.';

  @override
  String get shuffleSwitchingDesc =>
      'Toggling shuffle never restarts the current song. It only changes the order of upcoming tracks—randomized when enabled and restored to the original queue order when disabled.';

  @override
  String get topResult => 'Top Result';

  @override
  String get transferMusicFiles => 'TRANSFER MUSIC FILES';

  @override
  String get turnOffBlursOptimize =>
      'Turn off heavy blurs to optimize performance';

  @override
  String get unknown => 'Unknown';

  @override
  String get unknownAlbum => 'Unknown Album';

  @override
  String get unknownArtist => 'Unknown Artist';

  @override
  String get updateLibraryIndexing => 'Update library files indexing';

  @override
  String get useAbsoluteBlackBg => 'Use absolute black for backgrounds';

  @override
  String get useStaticTextTimestamps =>
      'Use static text instead of rolling animation for progress duration';

  @override
  String get fluidPlayer => 'Fluid Player';

  @override
  String get fluidPlayerDesc =>
      'Drag the mini player up to morph it into the full player';

  @override
  String get viewAll => 'View All';

  @override
  String get visitOfficialRepository => 'Visit official repository on GitHub';

  @override
  String get welcomeAboutDesc =>
      'Looper Player is a next-generation Music-OS built for premium offline audio playback. Features real-time dynamic lyrics generation, advanced audio session management with call mute handling, adaptive background theming, and multi-format music library support. Fully optimized for maximum battery efficiency.';

  @override
  String get welcomeAllFilesDesc =>
      'Highly recommended for professional scanning to locate songs in non-standard directories (Downloads, Telegram, custom folders).';

  @override
  String get welcomeInstructionConnectDesc =>
      'Plug your phone or device into a personal computer using a standard USB data cable.';

  @override
  String get welcomeInstructionDownloadDesc =>
      'Alternatively, download files directly using a web browser or other downloader utility on the device itself.';

  @override
  String get welcomeInstructionTransferDesc =>
      'Copy your offline music files (supports .mp3, .flac, .m4a, .wav) directly into the standard \'Music\' or \'Download\' folder of your device.';

  @override
  String get welcomeMusicAudioDesc =>
      'Required to discover and play standard offline audio tracks on your device memory.';

  @override
  String get welcomeNoSongsDesc =>
      'We couldn\'t find any supported audio files (MP3, FLAC, WAV, M4A, OGG) on your device storage.';

  @override
  String get welcomeNotificationDesc =>
      'Required to show playback controls and active notification widgets in your system bar.';

  @override
  String get welcomeScanningFoldersDesc =>
      'Scanning all folders and subfolders for audio files.';

  @override
  String get whyInternetUsed => 'Why Internet is Used';

  @override
  String get whyInternetUsedDesc =>
      '• Dynamic Lyrics Syncing: Used solely to securely fetch and download synchronized lyrics (LRC formats) from online databases. No personal data, settings, or media files are ever uploaded or shared.';

  @override
  String get whyPermissionsUsed => 'Why Permissions are Used';

  @override
  String get whyPermissionsUsedDesc =>
      '• Storage / Media Access: Required to discover, read, and index local audio tracks stored on your device.\n• Notifications: Required to display active playback control widgets in your status bar and system drawer.';

  @override
  String get willPlayNext => 'Will play next';

  @override
  String get year => 'Year';

  @override
  String get supportUs => 'Support Us';

  @override
  String get supportUsDesc => 'Help keep Looper Player alive & open-source';

  @override
  String get supportDevelopment => 'Support the Development';

  @override
  String get supportDevelopmentDesc =>
      'Looper Player is 100% free and open-source. If you enjoy using it, please consider supporting the creator with a donation. Every contribution helps keep the project active!';

  @override
  String get useCustomFont => 'Use Custom Font';

  @override
  String get useCustomFontDesc =>
      'Use Jost or other custom fonts. Otherwise, DM Sans is used.';

  @override
  String get selectFontFamily => 'Select Font Family';

  @override
  String activeFont(String fontName) {
    return 'Active font: $fontName';
  }

  @override
  String get fontWeightAdjustment => 'Font Weight Adjustment';

  @override
  String get currentWeight => 'Current weight';

  @override
  String get useCustomFontLyrics => 'Use Custom Font for Lyrics';

  @override
  String get useCustomFontLyricsDesc =>
      'Use custom font and weight for synchronized lyrics view';

  @override
  String get lyricsFontFamily => 'Lyrics Font Family';

  @override
  String activeLyricsFont(String fontName) {
    return 'Active lyrics font: $fontName';
  }

  @override
  String get lyricsFontWeightAdjustment => 'Lyrics Font Weight Adjustment';

  @override
  String get giveStarOnGithub => 'Give Star on GitHub';

  @override
  String get supportProjectLove => 'Support the project and show some love!';

  @override
  String get sortAlphabeticalAZ => 'Alphabetical (A-Z)';

  @override
  String get sortAlphabeticalZA => 'Alphabetical (Z-A)';

  @override
  String get sortRecentlyAdded => 'Recently Added';

  @override
  String get sortOldestAdded => 'Oldest Added';

  @override
  String get sortYearNewest => 'Year (Newest)';

  @override
  String get sortYearOldest => 'Year (Oldest)';

  @override
  String get sortMostSongs => 'Most Songs';

  @override
  String get sortLeastSongs => 'Least Songs';

  @override
  String get sortDefault => 'Default';

  @override
  String get sortArtistAsc => 'Artist (A-Z)';

  @override
  String get sortAlbumAsc => 'Album (A-Z)';

  @override
  String get sortDuration => 'Duration';

  @override
  String get myAlbums => 'My Albums';

  @override
  String get featuredArtists => 'Featured Artists';

  @override
  String get noSongPlaying => 'No song playing';

  @override
  String get nextLabel => 'Next';

  @override
  String get previousLabel => 'Previous';

  @override
  String get resync => 'Re-sync';

  @override
  String get equalizer => 'Equalizer';

  @override
  String get presets => 'PRESETS';

  @override
  String get preAmpGain => 'Pre-amp Gain';

  @override
  String get outputVolume => 'Output Volume';

  @override
  String get customFilterHint =>
      'Type custom libavfilter audio filter parameters directly (e.g. volume=3dB, aecho=0.8:0.88:60:0.4):';

  @override
  String get flowGlobalActions => 'Flow & Global Actions';

  @override
  String get equalizerModeLabel => 'Equalizer Mode:';

  @override
  String get currentGainsAppliedGlobal =>
      'Current gains applied as global default settings.';

  @override
  String get applyToGlobal => 'Apply to Global';

  @override
  String get songSpecificResetGlobal =>
      'Song-specific settings reset to global default.';

  @override
  String get resetToGlobal => 'Reset to Global';

  @override
  String get resetAllSongsEq => 'Reset All Songs EQ';

  @override
  String get resetAllSongsEqConfirm =>
      'Are you sure you want to clear custom equalizer settings for all songs in your library?';

  @override
  String get allSongsEqDataReset =>
      'All song-specific equalizer data has been reset.';

  @override
  String get resetAllSongsEqData => 'Reset All Songs EQ Data';

  @override
  String get equalizerTargetMode => 'Equalizer Target Mode';

  @override
  String get equalizerTargetModeDesc =>
      'Select how equalizer settings are applied across your music library.';

  @override
  String get globalMode => 'Global Mode';

  @override
  String get globalModeDesc =>
      'Applies effects to all songs universally. Equalizer settings remain the same when the song changes.';

  @override
  String get songSpecificMode => 'Song-Specific Mode';

  @override
  String get songSpecificModeDesc =>
      'Saves custom settings for the current song only. Next song defaults to no/flat equalizer unless it has its own profile.';

  @override
  String get viewDeviceAudioCapabilities => 'View Device Audio Capabilities';

  @override
  String get deviceAudioCapabilities => 'Device Audio Capabilities';

  @override
  String get noPlaybackActiveCapabilities =>
      'No playback active or capabilities information unavailable.';

  @override
  String get changeLyricsProvider => 'Change Lyrics Provider';

  @override
  String get autoFallbackProviders => 'Auto Fallback Providers';

  @override
  String get autoFallbackProvidersDesc =>
      'Try remaining providers automatically if primary has no lyrics';

  @override
  String get ambientColorBackground => 'Ambient Color Background';

  @override
  String get ambientColorBackgroundDesc =>
      'Smooth, subtle ambient gradients derived from song artwork';

  @override
  String get exportLyricsLrc => 'Export Lyrics (.lrc file)';

  @override
  String get saveLyricsToDevice => 'Save current lyrics to device storage';

  @override
  String get noLyricsToExport => 'No lyrics available to export';

  @override
  String get useCustomLyricsLrc => 'Use Custom Lyrics (LRC File)';

  @override
  String get selectLocalLrcFile =>
      'Select local .lrc or .txt file for this song';

  @override
  String get customLyricsAppliedSuccess =>
      'Custom lyrics applied successfully!';

  @override
  String get noRecentlyPlayedTracks => 'No recently played tracks';

  @override
  String get close => 'Close';

  @override
  String get audioQualityAnalysis => 'Audio Quality Analysis';

  @override
  String get audioQualityAnalysisDesc =>
      'Perform deep spectral and audio format analysis';

  @override
  String get audioStreamDetails => 'Audio Stream Details';

  @override
  String get perChannelMetrics => 'Per-Channel Metrics';

  @override
  String get sleepTimer => 'Sleep Timer';

  @override
  String get stopByTime => 'STOP BY TIME';

  @override
  String get start => 'Start';

  @override
  String get stopBySongCount => 'STOP BY SONG COUNT';

  @override
  String get cancelSleepTimer => 'Cancel Sleep Timer';

  @override
  String get nowPlayingAllCaps => 'NOW PLAYING';

  @override
  String get settingsAndBackups => 'Settings & Backups';

  @override
  String get managePreferencesLibraryData =>
      'Manage preferences and library data';

  @override
  String get logsClearedSuccess => 'Logs cleared successfully';

  @override
  String get editSongInfo => 'Edit Song Info';

  @override
  String get editAlbumInfo => 'Edit Album Info';

  @override
  String get tapFieldToEdit => 'Tap a field to edit';

  @override
  String get alwaysBlurSheets => 'Always Blur Sheets';

  @override
  String get alwaysBlurSheetsDesc =>
      'Blur popup sheets even when Dynamic Theming is off';

  @override
  String get removeArtwork => 'Remove artwork';

  @override
  String get resetArtworkToDefault => 'Reset to default';

  @override
  String get artworkResetToDefault => 'Artwork reset to default';

  @override
  String get noEmbeddedArtworkFound =>
      'No embedded artwork found for this album';

  @override
  String get saveChangesBtn => 'Save Changes';

  @override
  String get enterFolderPathManually => 'Enter Folder Path Manually';

  @override
  String get folderPickerManualHint =>
      'If the system directory picker is not opening, type or paste the full directory path below:';

  @override
  String get noSupportedSongsFoundFolder =>
      'No supported songs found in the selected folder';

  @override
  String get add => 'Add';

  @override
  String get folderPickerClosed => 'Folder picker closed';

  @override
  String get buyMeCoffee => 'Buy Me a Coffee';

  @override
  String get typeToSearchSettings => 'Type to search settings...';

  @override
  String get maintainersLabel => 'Maintainers';

  @override
  String get personBehindLooperPlayer => 'Person behind LooperPlayer';

  @override
  String get blurredArtworkForLyrics => 'Blurred Artwork for Lyrics';

  @override
  String get blurredArtworkForLyricsDesc =>
      'Show blurred album art as background instead of dynamic/static gradient';

  @override
  String get lyricsFontWeight => 'Lyrics Font Weight';

  @override
  String get openSourceLicenses => 'Open Source Licenses';

  @override
  String get openSourceLicensesDesc => 'Third-party libraries used in this app';

  @override
  String get done => 'Done';

  @override
  String get lyricsNotAvailable => 'Lyrics not available.';

  @override
  String get lyricsNotAvailableHint =>
      'Import a .lrc or .txt file to add lyrics for this song';

  @override
  String get importLyricsFile => 'Import Lyrics File';

  @override
  String get approximatedSyncNoWordTimings =>
      'Approximated Sync (No Word Timings)';

  @override
  String get lyricsSyncHelp => 'Lyrics Sync Help';

  @override
  String get simpleModeLabel => 'Simple Mode';

  @override
  String get advancedModeLabel => 'Advanced Mode';

  @override
  String get tips => 'Tips';

  @override
  String get gotIt => 'Got it';

  @override
  String get lyricsSyncStudio => 'Lyrics Sync Studio';

  @override
  String get lyricsTextLabel => 'Lyrics Text';

  @override
  String get lyricsTextHelperDesc =>
      'One line per lyric row. The sync tools below attach timestamps to these lines.';

  @override
  String get quickSync => 'Quick Sync';

  @override
  String get autoAdvanceAfterStamping => 'Auto-advance after stamping';

  @override
  String get advancedSync => 'Advanced Sync';

  @override
  String get useCurrentTime => 'Use Current Time';

  @override
  String get playbackAssist => 'Playback Assist';

  @override
  String get timeShift => 'Time Shift';

  @override
  String get timeShiftDesc =>
      'Move every stamped lyric forward or backward together.';

  @override
  String get lyricsSaveLrcExplain =>
      'Save writes an `.lrc` sidecar file beside the song audio if possible, and saves it in the local player database. Unstamped lines will be interpolated automatically.';

  @override
  String get back => 'Back';

  @override
  String get appSettingsLabel => 'App Settings';

  @override
  String get backupsAndLogs => 'Backups & Logs';

  @override
  String get backupsAndLogsDesc => 'Export, import & manage app data';

  @override
  String get exportBackupJson => 'Export Backup (JSON)';

  @override
  String get exportBackupJsonDesc =>
      'Saves your liked songs and playlists to a JSON file you can keep or share. Nothing else is included.';

  @override
  String get importBackupJson => 'Import Backup (JSON)';

  @override
  String get importBackupJsonDesc =>
      'Merges liked songs and playlists from a backup file into your library. Existing data is never overwritten or removed.';

  @override
  String get exportDiagnosticsLogs => 'Export Diagnostics Logs';

  @override
  String get exportDiagnosticsLogsDesc =>
      'Shares the app\'s diagnostic log file so it can be reviewed for troubleshooting.';

  @override
  String get clearDiagnosticsLogs => 'Clear Diagnostics Logs';

  @override
  String get clearDiagnosticsLogsDesc =>
      'Permanently erases the diagnostic log file stored on this device. This cannot be undone.';

  @override
  String get lyricsPlainTextOrLrc => 'Lyrics (Plain text or LRC)';

  @override
  String get syncModeLine => 'LINE';

  @override
  String get syncModeWord => 'WORD';

  @override
  String get syncModeChar => 'CHAR';

  @override
  String get enterManually => 'Enter Manually';

  @override
  String get rawFilterParametersHint => 'Raw filter parameters...';

  @override
  String get searchSettingsHint => 'Search settings...';

  @override
  String get repeatTooltip => 'Repeat';

  @override
  String get favoriteTooltip => 'Favorite';

  @override
  String get instructionsTooltip => 'Instructions';

  @override
  String get pasteLyricsHint => 'Paste or type the song lyrics here';

  @override
  String get timestampMmSsHint => 'Timestamp (mm:ss.xx)';

  @override
  String get nowLabel => 'Now';

  @override
  String get playlistNameHint => 'Playlist name';

  @override
  String get songInfoUpdated => 'Song info updated!';

  @override
  String get albumInfoUpdated => 'Album info updated!';

  @override
  String get failedToSaveChanges => 'Failed to save changes.';

  @override
  String sleepTimerStoppingIn(String time) {
    return 'Active: Stopping in $time';
  }

  @override
  String sleepTimerStoppingAfter(String time) {
    return 'Active: Stopping after $time';
  }

  @override
  String get selectWhenToPause => 'Select when to pause music playback';

  @override
  String get selectAvatars => 'Select Avatars';

  @override
  String get selectAvatarsDesc => 'Choose the avatar shown on your Home screen';

  @override
  String get dynamicAvatarColor => 'Dynamic Avatar Color';

  @override
  String get dynamicAvatarColorDesc =>
      'Match the avatar\'s accent color to your current theme';

  @override
  String enrichingSongs(int count) {
    return 'Enriching $count songs…';
  }

  @override
  String get noListeningHistoryYet => 'No listening history yet';

  @override
  String get noListeningHistoryYetDesc =>
      'Play a few songs and your personal report card — top songs, artists, albums and genres — will come to life here.';

  @override
  String get looperAnalyze => 'Looper Analyze';

  @override
  String get totalPlays => 'Total Plays';

  @override
  String get listeningTime => 'Listening Time';

  @override
  String get currentStreakDays => 'Current Streak (days)';

  @override
  String get longestStreakDays => 'Longest Streak (days)';

  @override
  String analyzePlaysAndSongs(int plays, int songs) {
    return '$plays plays • $songs songs';
  }

  @override
  String get dayPartMorningShort => 'AM';

  @override
  String get dayPartAfternoonShort => 'Aft';

  @override
  String get dayPartEveningShort => 'Eve';

  @override
  String get dayPartNightShort => 'Night';

  @override
  String get activityPattern => 'Activity Pattern';

  @override
  String get whenYouListenMost => 'When you listen most';

  @override
  String get genreBreakdown => 'Genre Breakdown';

  @override
  String get otherGenre => 'Other';

  @override
  String get topAlbums => 'Top Albums';

  @override
  String get topArtists => 'Top Artists';

  @override
  String get topSongs => 'Top Songs';

  @override
  String playsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plays',
      one: '1 play',
    );
    return '$_temp0';
  }

  @override
  String songsPlayedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs played',
      one: '1 song played',
    );
    return '$_temp0';
  }

  @override
  String get listeningTrend => 'Listening Trend';

  @override
  String get last30Days => 'Last 30 days';

  @override
  String errorWithDetails(String error) {
    return 'Error: $error';
  }

  @override
  String get selectAll => 'Select All';

  @override
  String get playlist => 'Playlist';

  @override
  String songsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return '$_temp0';
  }

  @override
  String get recentSearches => 'Recent Searches';

  @override
  String get lyricsSourceLocalFile => 'Local File';

  @override
  String get lyricsSourceEmbedded => 'Embedded Metadata';

  @override
  String lyricsProvidedBy(String source) {
    return 'Lyrics provided by $source';
  }

  @override
  String failedToImportLyrics(String error) {
    return 'Failed to import lyrics: $error';
  }

  @override
  String get lyricsEditorLines => 'Lines';

  @override
  String get lyricsEditorStamped => 'Stamped';

  @override
  String lyricsEditorLineNumber(int number) {
    return 'Line $number';
  }

  @override
  String get lyricsEditorEmptyLine => '(Empty line)';

  @override
  String get lyricsEditorNotStamped => 'Not stamped yet';

  @override
  String get pause => 'Pause';

  @override
  String get lyricsEditorAddLineFirst => 'Add at least one lyric line first.';

  @override
  String get lyricsEditorSavedWithSidecar =>
      'Saved lyrics to database and beside the song file.';

  @override
  String get lyricsEditorSavedDbOnly => 'Saved lyrics to player database.';

  @override
  String get lyricsEditorSaveFailed => 'Could not save the lyrics.';

  @override
  String get saving => 'Saving...';

  @override
  String get saveLrc => 'Save LRC';

  @override
  String lyricsEditorSelectedLine(int index, int total) {
    return 'Selected line $index of $total';
  }

  @override
  String get lyricsEditorPickLine => 'Pick a lyric line from the list below.';

  @override
  String get stampAndNext => 'Stamp & Next';

  @override
  String get stampNow => 'Stamp Now';

  @override
  String get lyricsEditorSimpleSteps =>
      '1. Paste or type one lyric line per row.\n2. Play the song.\n3. Select the current lyric line.\n4. Tap \"Stamp & Next\" when you hear that line.\n5. Save when done.';

  @override
  String get lyricsEditorAdvancedSteps =>
      '1. Edit timestamps directly for each line.\n2. Use \"Use Current Time\" to capture the live playback time.\n3. Use the shift controls to move all stamped lyrics together.\n4. Save to generate the final `.lrc` file.';

  @override
  String get lyricsEditorTipsText =>
      '- If some lines are not stamped, Flick\'s engine fills their times automatically.\n- Save writes beside the song when possible, otherwise it stores a linked copy in the DB.';

  @override
  String fileNotFoundOrInaccessible(String title) {
    return 'File not found or inaccessible: $title';
  }

  @override
  String playbackFailedCorrupted(String title) {
    return 'Playback failed: Unable to load or play \"$title\". Please verify the file is not corrupted.';
  }

  @override
  String shareSongText(String title) {
    return 'Check out this song: $title';
  }

  @override
  String shareSongsText(int count) {
    return 'Check out these $count songs';
  }

  @override
  String noSettingsFoundFor(String query) {
    return 'No settings found for \"$query\"';
  }

  @override
  String get chooseQuickAccentColors => 'Choose quick accent colors';

  @override
  String get fontWeight => 'Font Weight';

  @override
  String get changeBaseFontWeight => 'Change base weight of custom font';

  @override
  String lyricsFontWeightValue(int weight) {
    return 'Lyrics font weight: $weight';
  }

  @override
  String get equalizerSearchDesc =>
      'Adjust 18-band equalizer and audio presets';

  @override
  String get stopServiceSearchDesc =>
      'Stop playback and close the app when swiped away from recent panel';

  @override
  String get scanNewFolderDesc => 'Scan a new folder for audio files';

  @override
  String get includeOtherDeviceAudioShortDesc =>
      'Ringtones, notifications and messaging audio';

  @override
  String get excludedFolders => 'Excluded Folders';

  @override
  String get excludedFoldersSearchDesc => 'Skip specific folders when scanning';

  @override
  String get clearLibraryData => 'Clear library data';

  @override
  String get looperPlayerVersion => 'Looper Player Version';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get none => 'None';

  @override
  String foldersSkippedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count folders skipped when scanning',
      one: '1 folder skipped when scanning',
    );
    return '$_temp0';
  }

  @override
  String get excludedFoldersDesc =>
      'Songs in these folders are skipped during a scan, even if they sit inside a folder you added.';

  @override
  String get noExcludedFoldersYet => 'No excluded folders yet.';

  @override
  String get excludeAFolder => 'Exclude a Folder';

  @override
  String get equalizerEnabled18Band => 'Enabled (18-band MPV EQ)';

  @override
  String get disabled => 'Disabled';

  @override
  String get noIndexedFoldersYet => 'No indexed folders yet';

  @override
  String get noIndexedFoldersYetDesc =>
      'Use Rescan Library to discover folders across storage.';

  @override
  String get eqDynamicRangeCompressor => 'Dynamic Range Compressor';

  @override
  String get eqThreshold => 'Threshold';

  @override
  String get eqRatio => 'Ratio';

  @override
  String get eqAttack => 'Attack';

  @override
  String get eqRelease => 'Release';

  @override
  String get eqHeadphoneCrossfeedWidth => 'Headphone Crossfeed & Width';

  @override
  String get eqBinauralCrossfeed => 'Binaural Crossfeed';

  @override
  String get eqCrossfeedStrength => 'Crossfeed Strength';

  @override
  String get eqStereoWidening => 'Stereo Widening';

  @override
  String get eqWideningFactor => 'Widening Factor';

  @override
  String get eqLoudnessNormalization => 'Loudness Normalization';

  @override
  String get eqTargetLoudness => 'Target Loudness';

  @override
  String get eqToneShelving => 'Tone Shelving (Bass / Treble)';

  @override
  String get eqBassShelf => 'Bass Shelf';

  @override
  String get eqTrebleShelf => 'Treble Shelf';

  @override
  String get eqTempoPitchControls => 'Tempo & Pitch Controls';

  @override
  String get eqPitchShift => 'Pitch Shift';

  @override
  String get eqTempoSpeed => 'Tempo Speed';

  @override
  String get eqVoiceSilenceControls => 'Voice & Silence controls';

  @override
  String get eqSilenceTrimming => 'Silence Trimming';

  @override
  String get eqSilenceThreshold => 'Silence Threshold';

  @override
  String get eqSpeechEnhancementFilter => 'Speech Enhancement Filter';

  @override
  String get eqHighpassCutoff => 'Highpass Cutoff';

  @override
  String get eqLowpassCutoff => 'Lowpass Cutoff';

  @override
  String get eqRetroRoomEffects => 'Retro & Room Effects';

  @override
  String get eqLofiEffect => 'Lofi Effect (8-bit Crusher)';

  @override
  String get eqStudioRoomReverb => 'Studio Room Reverb (Echo)';

  @override
  String get eqVirtualSurround => 'Virtual 5.1 Surround Sound';

  @override
  String get eqRawFilterConsole => 'Raw FFMpeg Filter console';

  @override
  String get eqSwitchToSliders => 'Switch to Sliders';

  @override
  String get eqSwitchToGraph => 'Switch to Graph';

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get eqSongSpecificActive => 'Song-specific settings active';

  @override
  String get eqUsingGlobalDefault => 'Using global settings default';

  @override
  String get eqInteractiveGraphHint =>
      'INTERACTIVE GRAPH (DRAG DOTS VERTICALLY)';

  @override
  String get eq18BandHint => '18-BAND EQUALIZER (SCROLL HORIZONTALLY)';

  @override
  String get eqSongSpecific => 'Song-Specific';

  @override
  String get eqGlobalDefault => 'Global Default';

  @override
  String get eqEditScopeNote =>
      'Edits made when a song is playing apply to that song only. To set the global default, edit when no song is playing, or use the \'Apply to Global\' action.';

  @override
  String get presetFlat => 'Flat';

  @override
  String get presetBassBooster => 'Bass Booster';

  @override
  String get presetTrebleBooster => 'Treble Booster';

  @override
  String get presetVocalBooster => 'Vocal Booster';

  @override
  String get presetElectronic => 'Electronic';

  @override
  String get presetRock => 'Rock';

  @override
  String get presetPop => 'Pop';

  @override
  String get presetJazz => 'Jazz';

  @override
  String get save => 'Save';

  @override
  String get savePreset => 'Save Preset';

  @override
  String get presetName => 'Preset name';

  @override
  String get deletePreset => 'Delete Preset';

  @override
  String deletePresetConfirm(String name) {
    return 'Delete the \"$name\" preset?';
  }

  @override
  String get noLyricsSource => 'No Lyrics Source';

  @override
  String lyricsSourceLabel(String source) {
    return 'Source: $source';
  }

  @override
  String get lyricsSourceLocalSidecar => 'Local Sidecar (.lrc)';

  @override
  String get lyricsSourceCustomFile => 'Custom LRC File';

  @override
  String get lyricsSourceNotFoundOnline => 'Not Found Online';

  @override
  String get lyricsProviderLocal => 'Local';

  @override
  String get checkingLocalLyrics => 'Checking local/embedded lyrics...';

  @override
  String fetchingLyricsFrom(String provider) {
    return 'Fetching lyrics from $provider...';
  }

  @override
  String get loadedLocalLyrics => 'Loaded local/embedded lyrics!';

  @override
  String get noLocalLyricsFound => 'No local or embedded lyrics found';

  @override
  String lyricsUpdatedFrom(String provider) {
    return 'Lyrics updated from $provider!';
  }

  @override
  String noLyricsFoundOn(String provider) {
    return 'No lyrics found on $provider';
  }

  @override
  String get gestureTips => 'Gesture Tips';

  @override
  String get gestureTipsDesc => 'Tap, long-press, pinch to zoom & more';

  @override
  String get exportLyrics => 'Export Lyrics';

  @override
  String lyricsExportedTo(String path) {
    return 'Lyrics exported to: $path';
  }

  @override
  String failedToExportLyrics(String error) {
    return 'Failed to export lyrics: $error';
  }

  @override
  String get gestureTapLine => 'Tap a line';

  @override
  String get gestureTapLineDesc => 'Jump playback straight to that lyric.';

  @override
  String get gestureLongPressLine => 'Long-press a line';

  @override
  String get gestureLongPressLineDesc =>
      'Start selecting lines to turn into a shareable lyrics card. Tap more lines to extend the selection.';

  @override
  String get gesturePinch => 'Pinch with two fingers';

  @override
  String get gesturePinchDesc => 'Resize the lyrics text to your liking.';

  @override
  String get gestureSwipeDown => 'Swipe down';

  @override
  String get gestureSwipeDownDesc =>
      'Close the lyrics screen and return to the player.';

  @override
  String get lyricsGestures => 'Lyrics Gestures';

  @override
  String get lyricsGesturesIntro =>
      'A few things this screen can do that aren\'t always obvious:';

  @override
  String linesSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines selected',
      one: '1 line selected',
    );
    return '$_temp0';
  }

  @override
  String get couldNotGenerateShareImage =>
      'Could not generate the share image.';

  @override
  String get couldNotGenerateImage => 'Could not generate the image.';

  @override
  String get savedToGallery => 'Saved to gallery.';

  @override
  String get galleryPermissionDenied =>
      'Permission to access the gallery was denied.';

  @override
  String get couldNotSaveToGallery =>
      'Could not save the image to the gallery.';

  @override
  String get shareLyrics => 'Share Lyrics';

  @override
  String get backgroundColor => 'Background Color';

  @override
  String get lyricsTextColor => 'Lyrics Text Color';

  @override
  String get saveToGallery => 'Save to Gallery';

  @override
  String get preparing => 'Preparing...';

  @override
  String get trackTitle => 'Track Title';

  @override
  String get composer => 'Composer';

  @override
  String get unknownGenre => 'Unknown Genre';

  @override
  String get releaseYear => 'Release Year';

  @override
  String get notAvailable => 'N/A';

  @override
  String get recordLabel => 'Label';

  @override
  String get copyright => 'Copyright';

  @override
  String get encoder => 'Encoder';

  @override
  String get fileName => 'File Name';

  @override
  String get fileFormat => 'File Format';

  @override
  String get fileSize => 'File Size';

  @override
  String get absolutePath => 'Absolute Path';

  @override
  String get playCount => 'Play Count';

  @override
  String playCountTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: '1 time',
    );
    return '$_temp0';
  }

  @override
  String get lastPlayed => 'Last Played';

  @override
  String get filePath => 'File Path';

  @override
  String get rescan => 'Rescan';

  @override
  String get codec => 'Codec';

  @override
  String get container => 'Container';

  @override
  String get sampleRate => 'Sample Rate';

  @override
  String get bitDepth => 'Bit Depth';

  @override
  String get decodedFormat => 'Decoded Format';

  @override
  String get bitrate => 'Bitrate';

  @override
  String get channels => 'Channels';

  @override
  String get nyquist => 'Nyquist';

  @override
  String get dynamicRange => 'Dynamic Range';

  @override
  String get peak => 'Peak';

  @override
  String get truePeak => 'True Peak';

  @override
  String get clipping => 'Clipping';

  @override
  String get cutoff => 'Cutoff';

  @override
  String get samples => 'Samples';

  @override
  String channelShort(int channel) {
    return 'Ch $channel';
  }

  @override
  String get noneClean => 'None (Clean)';

  @override
  String get reanalyzingAudio => 'Re-analyzing audio stream...';

  @override
  String get analyzingAudio => 'Analyzing audio stream...';

  @override
  String sampleRateHz(int rate) {
    return 'Sample Rate: $rate Hz';
  }

  @override
  String nyquistKhz(String khz) {
    return 'Nyquist: $khz kHz';
  }

  @override
  String get qualityLossless => 'Lossless';

  @override
  String get qualityHigh => 'High Quality';

  @override
  String get qualityStandard => 'Standard Quality';

  @override
  String get qualityAudio => 'Audio';

  @override
  String get addCustomFolder => 'Add a Custom Folder';

  @override
  String get addCustomFolderDesc =>
      'If your music lives in a folder with a different name, or on an SD card, add it directly.';

  @override
  String get indexingYourLibrary => 'INDEXING YOUR LIBRARY...';

  @override
  String get indexingYourLibraryDesc =>
      'Filling in titles, artwork and lyrics for your songs.';

  @override
  String welcomeStep(String step, String title) {
    return 'STEP $step: $title';
  }

  @override
  String get includeOtherDeviceAudioAlarmsDesc =>
      'Ringtones, notifications, alarms and messaging audio';

  @override
  String get version => 'Version';

  @override
  String get noIndexedFoldersDesktopDesc =>
      'Use Rescan Library to discover storage folders';

  @override
  String get playedLabel => 'Played';

  @override
  String minutesShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mins',
      one: '1 Min',
    );
    return '$_temp0';
  }

  @override
  String minuteChip(int count) {
    return '$count Min';
  }

  @override
  String songsCountTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Songs',
      one: '1 Song',
    );
    return '$_temp0';
  }

  @override
  String songsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs left',
      one: '1 song left',
    );
    return '$_temp0';
  }

  @override
  String sleepTimerWithRemaining(String remaining) {
    return 'Sleep Timer ($remaining)';
  }

  @override
  String get trackInfoSection => 'TRACK INFO';

  @override
  String get detailsSection => 'DETAILS';

  @override
  String get lyricsSection => 'LYRICS';

  @override
  String get editLyricsHint =>
      'Enter plain lyrics or synchronized LRC lyrics format [00:00.00]...';

  @override
  String addedSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count songs',
      one: 'Added 1 song',
    );
    return '$_temp0';
  }

  @override
  String get chooseInternalStorageFolder =>
      'Please choose a folder on this device\'s internal storage or SD card.';

  @override
  String get appCrashedTitle => 'Looper Player Crashed';

  @override
  String get appCrashedDesc =>
      'An unexpected initialization error occurred. A diagnostic crash report has been generated.';

  @override
  String get appCrashedDetails =>
      'An error occurred during app database or service initialization. This can happen if storage access is restricted or database files are corrupted.';

  @override
  String get crashReportSaved =>
      'Diagnostic crash report saved to application support folder.';

  @override
  String get shareLog => 'Share Log';

  @override
  String get restartApp => 'Restart App';

  @override
  String get updateAvailableOnPlay =>
      'A new version is available on Google Play.';

  @override
  String updateAvailableOnGithub(String version) {
    return 'Version $version is available on GitHub.';
  }

  @override
  String get updateAvailable => 'Update available';

  @override
  String get updateAvailableTitle => 'Update Available!';

  @override
  String get visit => 'VISIT';

  @override
  String get updateDownloaded => 'Update downloaded';

  @override
  String get restartToInstallUpdate => 'Restart Looper Player to install it.';

  @override
  String get restart => 'RESTART';

  @override
  String backupImportedSummary(int favorites, int stats, int playlists) {
    return 'Backup imported: Merged $favorites favorites, $stats play stats, synced $playlists playlists';
  }

  @override
  String get backupExportFailed =>
      'Failed to export backup: An internal error occurred while saving the backup file.';

  @override
  String get backupImportFailed =>
      'Failed to import backup: The file could not be read or the backup format is invalid.';

  @override
  String get stereo => 'Stereo';

  @override
  String get mono => 'Mono';
}
