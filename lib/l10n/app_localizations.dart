import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('nl'),
    Locale('pt'),
    Locale('ru'),
    Locale('tr'),
    Locale('zh'),
  ];

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutAndMaintainers.
  ///
  /// In en, this message translates to:
  /// **'About & Maintainers'**
  String get aboutAndMaintainers;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutApp;

  /// No description provided for @aboutLooperPlayer.
  ///
  /// In en, this message translates to:
  /// **'ABOUT LOOPER PLAYER'**
  String get aboutLooperPlayer;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get accentColor;

  /// No description provided for @accentColorDesc.
  ///
  /// In en, this message translates to:
  /// **'Select manual theme accent color'**
  String get accentColorDesc;

  /// No description provided for @acousticSpectralAnalysis.
  ///
  /// In en, this message translates to:
  /// **'ACOUSTIC & SPECTRAL ANALYSIS'**
  String get acousticSpectralAnalysis;

  /// No description provided for @activeCallCannotPlay.
  ///
  /// In en, this message translates to:
  /// **'Playback blocked: Cannot play music during an active call'**
  String get activeCallCannotPlay;

  /// No description provided for @adaptColorsArtwork.
  ///
  /// In en, this message translates to:
  /// **'Adapt app colors to album artwork'**
  String get adaptColorsArtwork;

  /// No description provided for @addedTo.
  ///
  /// In en, this message translates to:
  /// **'Added to {name}'**
  String addedTo(String name);

  /// No description provided for @addedToQueue.
  ///
  /// In en, this message translates to:
  /// **'Added to queue'**
  String get addedToQueue;

  /// No description provided for @addFolder.
  ///
  /// In en, this message translates to:
  /// **'Add Folder'**
  String get addFolder;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get addToFavorites;

  /// No description provided for @addToPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Add to Playlists'**
  String get addToPlaylists;

  /// No description provided for @addToQueue.
  ///
  /// In en, this message translates to:
  /// **'Add to Queue'**
  String get addToQueue;

  /// No description provided for @album.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get album;

  /// No description provided for @albums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get albums;

  /// No description provided for @albumsRowDesc.
  ///
  /// In en, this message translates to:
  /// **'Horizontal shelf of albums'**
  String get albumsRowDesc;

  /// No description provided for @allFilesAccess.
  ///
  /// In en, this message translates to:
  /// **'ALL FILES ACCESS (RECOMMENDED)'**
  String get allFilesAccess;

  /// No description provided for @allSongs.
  ///
  /// In en, this message translates to:
  /// **'All Songs'**
  String get allSongs;

  /// No description provided for @appDetailsCreator.
  ///
  /// In en, this message translates to:
  /// **'Application details, creator, and design team info'**
  String get appDetailsCreator;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appInfoPrivacy.
  ///
  /// In en, this message translates to:
  /// **'APP INFO & PRIVACY'**
  String get appInfoPrivacy;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Looper Player'**
  String get appTitle;

  /// No description provided for @artist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get artist;

  /// No description provided for @artists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get artists;

  /// No description provided for @artistsRowDesc.
  ///
  /// In en, this message translates to:
  /// **'Horizontal shelf of artists'**
  String get artistsRowDesc;

  /// No description provided for @ascending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get ascending;

  /// No description provided for @audioCrossfade.
  ///
  /// In en, this message translates to:
  /// **'Audio Crossfade'**
  String get audioCrossfade;

  /// No description provided for @audioCrossfadeDesc.
  ///
  /// In en, this message translates to:
  /// **'When one song ends and the next begins, the current track fades out while the next track fades in at the same time. This gives a continuous, DJ-like flow.'**
  String get audioCrossfadeDesc;

  /// No description provided for @audioFocusDenied.
  ///
  /// In en, this message translates to:
  /// **'Playback paused: Audio focus denied by system'**
  String get audioFocusDenied;

  /// No description provided for @audioPlayback.
  ///
  /// In en, this message translates to:
  /// **'Audio & Playback'**
  String get audioPlayback;

  /// No description provided for @audioPlaybackDesc.
  ///
  /// In en, this message translates to:
  /// **'Crossfade, silence gap, and fading settings'**
  String get audioPlaybackDesc;

  /// No description provided for @autoCrossfadeDuration.
  ///
  /// In en, this message translates to:
  /// **'Auto Crossfade Duration'**
  String get autoCrossfadeDuration;

  /// No description provided for @autoCrossfadeDurationDesc.
  ///
  /// In en, this message translates to:
  /// **'The overlap time used when the app automatically advances to the next track. Example: 2300ms means the next song starts 2.3 seconds before the current song fully ends.'**
  String get autoCrossfadeDurationDesc;

  /// No description provided for @backToMainView.
  ///
  /// In en, this message translates to:
  /// **'BACK TO MAIN VIEW'**
  String get backToMainView;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @center.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get center;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @clearQueue.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearQueue;

  /// No description provided for @connectDevice.
  ///
  /// In en, this message translates to:
  /// **'CONNECT DEVICE'**
  String get connectDevice;

  /// No description provided for @corePurpose.
  ///
  /// In en, this message translates to:
  /// **'Core Purpose'**
  String get corePurpose;

  /// No description provided for @corePurposeDesc.
  ///
  /// In en, this message translates to:
  /// **'Looper Player is an offline-first, high-fidelity audio player designed for music enthusiasts who want absolute control over their local library, gapless playback, and fluid, synchronized lyrics scrolling.'**
  String get corePurposeDesc;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @createPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Create Playlist'**
  String get createPlaylist;

  /// No description provided for @creatorAndMaintainer.
  ///
  /// In en, this message translates to:
  /// **'Creator and Maintainer'**
  String get creatorAndMaintainer;

  /// No description provided for @customAccentColor.
  ///
  /// In en, this message translates to:
  /// **'Custom Accent Color'**
  String get customAccentColor;

  /// No description provided for @customizeColorsTheme.
  ///
  /// In en, this message translates to:
  /// **'Customize app colors, theme, and lyrics backgrounds'**
  String get customizeColorsTheme;

  /// No description provided for @dateAdded.
  ///
  /// In en, this message translates to:
  /// **'Date Added'**
  String get dateAdded;

  /// No description provided for @deepStorageScanProgress.
  ///
  /// In en, this message translates to:
  /// **'DEEP STORAGE SCAN IN PROGRESS...'**
  String get deepStorageScanProgress;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteFile.
  ///
  /// In en, this message translates to:
  /// **'Delete File'**
  String get deleteFile;

  /// No description provided for @deletePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Delete Playlist'**
  String get deletePlaylist;

  /// No description provided for @deletePlaylistConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deletePlaylistConfirm(String name);

  /// No description provided for @deleteSong.
  ///
  /// In en, this message translates to:
  /// **'Delete Song'**
  String get deleteSong;

  /// No description provided for @deleteSongConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this song from disk?'**
  String get deleteSongConfirm;

  /// No description provided for @descending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get descending;

  /// No description provided for @designerAndMaintainer.
  ///
  /// In en, this message translates to:
  /// **'Designer and Maintainer'**
  String get designerAndMaintainer;

  /// No description provided for @disableBlurEffects.
  ///
  /// In en, this message translates to:
  /// **'Disable Blur Effects'**
  String get disableBlurEffects;

  /// No description provided for @disableSquigglyProgressBar.
  ///
  /// In en, this message translates to:
  /// **'Disable squiggly wave progress bar animation'**
  String get disableSquigglyProgressBar;

  /// No description provided for @downloadAudioDirectly.
  ///
  /// In en, this message translates to:
  /// **'DOWNLOAD AUDIO DIRECTLY'**
  String get downloadAudioDirectly;

  /// No description provided for @downloadingLyricsOffline.
  ///
  /// In en, this message translates to:
  /// **'Downloading lyrics for offline use...'**
  String get downloadingLyricsOffline;

  /// No description provided for @downloadMissingArtwork.
  ///
  /// In en, this message translates to:
  /// **'Download Missing Artwork'**
  String get downloadMissingArtwork;

  /// No description provided for @downloadMissingArtworkDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically download high-resolution cover artwork for songs from iTunes'**
  String get downloadMissingArtworkDesc;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @dynamicAccentColor.
  ///
  /// In en, this message translates to:
  /// **'Dynamic Accent Color'**
  String get dynamicAccentColor;

  /// No description provided for @dynamicAccentColorDesc.
  ///
  /// In en, this message translates to:
  /// **'Update only the accent color dynamically from the artwork'**
  String get dynamicAccentColorDesc;

  /// No description provided for @dynamicBgOnlyLyrics.
  ///
  /// In en, this message translates to:
  /// **'Dynamic background only for lyrics'**
  String get dynamicBgOnlyLyrics;

  /// No description provided for @dynamicColorActiveLyrics.
  ///
  /// In en, this message translates to:
  /// **'Dynamic Color Active Line'**
  String get dynamicColorActiveLyrics;

  /// No description provided for @dynamicColorActiveLyricsDesc.
  ///
  /// In en, this message translates to:
  /// **'Use extracted artwork colors for the currently playing lyrics line'**
  String get dynamicColorActiveLyricsDesc;

  /// No description provided for @dynamicLyricsBg.
  ///
  /// In en, this message translates to:
  /// **'Dynamic Lyrics BG'**
  String get dynamicLyricsBg;

  /// No description provided for @dynamicLyricsBgDesc.
  ///
  /// In en, this message translates to:
  /// **'Apply album-art blur to lyrics screen'**
  String get dynamicLyricsBgDesc;

  /// No description provided for @dynamicTheming.
  ///
  /// In en, this message translates to:
  /// **'Dynamic Theming'**
  String get dynamicTheming;

  /// No description provided for @emptyLibraryDesc.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find any supported music files in your library. Add folders or run a search scan.'**
  String get emptyLibraryDesc;

  /// No description provided for @enableNetworkLyricsArt.
  ///
  /// In en, this message translates to:
  /// **'Enable network use for online lyrics & artist art'**
  String get enableNetworkLyricsArt;

  /// No description provided for @enablePlayerGradient.
  ///
  /// In en, this message translates to:
  /// **'Music Screen Gradient'**
  String get enablePlayerGradient;

  /// No description provided for @enablePlayerGradientDesc.
  ///
  /// In en, this message translates to:
  /// **'Enable the radial accent gradient background on the now playing screen'**
  String get enablePlayerGradientDesc;

  /// No description provided for @fadeDuration.
  ///
  /// In en, this message translates to:
  /// **'Fade Duration'**
  String get fadeDuration;

  /// No description provided for @fadeDurationDesc.
  ///
  /// In en, this message translates to:
  /// **'How long the fade takes for play, pause, and stop actions. Example: 150ms means the audio becomes audible or silent very quickly, but still smoothly.'**
  String get fadeDurationDesc;

  /// No description provided for @fadeOnSeek.
  ///
  /// In en, this message translates to:
  /// **'Fade on Seek'**
  String get fadeOnSeek;

  /// No description provided for @fadeOnSeekDesc.
  ///
  /// In en, this message translates to:
  /// **'Temporarily lower the volume while the user scrubs or jumps to another position, then bring it back up after the seek completes. This prevents pops, glitches, or harsh jumps during seeking.'**
  String get fadeOnSeekDesc;

  /// No description provided for @fadePlayPauseStop.
  ///
  /// In en, this message translates to:
  /// **'Fade Play/Pause/Stop'**
  String get fadePlayPauseStop;

  /// No description provided for @fadePlayPauseStopDesc.
  ///
  /// In en, this message translates to:
  /// **'Smoothly ramp volume up when playback starts, and ramp it down when pausing or stopping. This avoids clicks and makes transitions feel natural.'**
  String get fadePlayPauseStopDesc;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @fileInformation.
  ///
  /// In en, this message translates to:
  /// **'File Information'**
  String get fileInformation;

  /// No description provided for @flatProgressBar.
  ///
  /// In en, this message translates to:
  /// **'Flat Progress Bar'**
  String get flatProgressBar;

  /// No description provided for @folders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get folders;

  /// No description provided for @genre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get genre;

  /// No description provided for @genres.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get genres;

  /// No description provided for @genresRowDesc.
  ///
  /// In en, this message translates to:
  /// **'Horizontal shelf of music genres'**
  String get genresRowDesc;

  /// No description provided for @goStart.
  ///
  /// In en, this message translates to:
  /// **'GO START'**
  String get goStart;

  /// No description provided for @grant.
  ///
  /// In en, this message translates to:
  /// **'GRANT'**
  String get grant;

  /// No description provided for @granted.
  ///
  /// In en, this message translates to:
  /// **'GRANTED'**
  String get granted;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @homeDarkness.
  ///
  /// In en, this message translates to:
  /// **'Home Screen Darkness'**
  String get homeDarkness;

  /// No description provided for @homeDarknessDesc.
  ///
  /// In en, this message translates to:
  /// **'Adjust background overlay darkness for the Home screen'**
  String get homeDarknessDesc;

  /// No description provided for @homeDashboardSettings.
  ///
  /// In en, this message translates to:
  /// **'Home Dashboard Settings'**
  String get homeDashboardSettings;

  /// No description provided for @homeDashboardSettingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Customize horizontal rows on your Home screen'**
  String get homeDashboardSettingsDesc;

  /// No description provided for @internetMode.
  ///
  /// In en, this message translates to:
  /// **'Internet Mode'**
  String get internetMode;

  /// No description provided for @keepBackgroundGradient.
  ///
  /// In en, this message translates to:
  /// **'Keep Background Gradient'**
  String get keepBackgroundGradient;

  /// No description provided for @keepBackgroundGradientDesc.
  ///
  /// In en, this message translates to:
  /// **'Keep the background gradient across all application screens'**
  String get keepBackgroundGradientDesc;

  /// No description provided for @animatePlayerGradient.
  ///
  /// In en, this message translates to:
  /// **'Animated Gradient'**
  String get animatePlayerGradient;

  /// No description provided for @animatePlayerGradientDesc.
  ///
  /// In en, this message translates to:
  /// **'Slowly moves the primary and tertiary colors with a soft grain, reacting to the music'**
  String get animatePlayerGradientDesc;

  /// No description provided for @animateBackgroundGradient.
  ///
  /// In en, this message translates to:
  /// **'Animated Background'**
  String get animateBackgroundGradient;

  /// No description provided for @animateBackgroundGradientDesc.
  ///
  /// In en, this message translates to:
  /// **'Uses the animated gradient on the Home, Songs and Library backgrounds'**
  String get animateBackgroundGradientDesc;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @left.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get left;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @libraryDarkness.
  ///
  /// In en, this message translates to:
  /// **'Library Screen Darkness'**
  String get libraryDarkness;

  /// No description provided for @libraryDarknessDesc.
  ///
  /// In en, this message translates to:
  /// **'Adjust background overlay darkness for the Library screen'**
  String get libraryDarknessDesc;

  /// No description provided for @libraryFoldersSync.
  ///
  /// In en, this message translates to:
  /// **'Folders, rescan triggers, reset database, and offline sync'**
  String get libraryFoldersSync;

  /// No description provided for @librarySettings.
  ///
  /// In en, this message translates to:
  /// **'Library Settings'**
  String get librarySettings;

  /// No description provided for @loadingMusicLibrary.
  ///
  /// In en, this message translates to:
  /// **'LOADING MUSIC LIBRARY'**
  String get loadingMusicLibrary;

  /// No description provided for @loadingMusicLibraryDesc.
  ///
  /// In en, this message translates to:
  /// **'Building premium indexes, setting up hardware listeners, and optimizing visual caches.'**
  String get loadingMusicLibraryDesc;

  /// No description provided for @loadingPhase1.
  ///
  /// In en, this message translates to:
  /// **'INTERROGATING AUDIO STORAGE...'**
  String get loadingPhase1;

  /// No description provided for @loadingPhase2.
  ///
  /// In en, this message translates to:
  /// **'REFRESHING MUSIC ENGINE...'**
  String get loadingPhase2;

  /// No description provided for @loadingPhase3.
  ///
  /// In en, this message translates to:
  /// **'EXTRACTING ACOUSTIC DATA...'**
  String get loadingPhase3;

  /// No description provided for @loadingPhase4.
  ///
  /// In en, this message translates to:
  /// **'OPTIMIZING PLAYBACK MEMORY...'**
  String get loadingPhase4;

  /// No description provided for @lyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get lyrics;

  /// No description provided for @lyricsAlignment.
  ///
  /// In en, this message translates to:
  /// **'Lyrics Alignment'**
  String get lyricsAlignment;

  /// No description provided for @lyricsAlignmentDesc.
  ///
  /// In en, this message translates to:
  /// **'Align text positions for scrolling lyrics'**
  String get lyricsAlignmentDesc;

  /// No description provided for @lyricsDarkness.
  ///
  /// In en, this message translates to:
  /// **'Lyrics Screen Darkness'**
  String get lyricsDarkness;

  /// No description provided for @lyricsDarknessDesc.
  ///
  /// In en, this message translates to:
  /// **'Adjust background overlay darkness for the Lyrics screen'**
  String get lyricsDarknessDesc;

  /// No description provided for @lyricsProvider.
  ///
  /// In en, this message translates to:
  /// **'Lyrics Provider'**
  String get lyricsProvider;

  /// No description provided for @lyricsProviderDesc.
  ///
  /// In en, this message translates to:
  /// **'Online lyrics fetched from lrclib.net (LRCLIB)'**
  String get lyricsProviderDesc;

  /// No description provided for @maintainersAndDesigners.
  ///
  /// In en, this message translates to:
  /// **'Maintainers & Designers'**
  String get maintainersAndDesigners;

  /// No description provided for @manageAudioFocus.
  ///
  /// In en, this message translates to:
  /// **'Manage Audio Focus'**
  String get manageAudioFocus;

  /// No description provided for @manageAudioFocusDesc.
  ///
  /// In en, this message translates to:
  /// **'Respond properly to system audio focus changes.'**
  String get manageAudioFocusDesc;

  /// No description provided for @manageAudioFocusTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Audio Focus'**
  String get manageAudioFocusTitle;

  /// No description provided for @manageLanguageAndFocus.
  ///
  /// In en, this message translates to:
  /// **'Manage language preferences and caller focus state'**
  String get manageLanguageAndFocus;

  /// No description provided for @audioFocusGetFocus.
  ///
  /// In en, this message translates to:
  /// **'Get Focus'**
  String get audioFocusGetFocus;

  /// No description provided for @audioFocusGetFocusDesc.
  ///
  /// In en, this message translates to:
  /// **'Request audio focus when playback begins.'**
  String get audioFocusGetFocusDesc;

  /// No description provided for @audioFocusReleaseFocus.
  ///
  /// In en, this message translates to:
  /// **'Release Focus'**
  String get audioFocusReleaseFocus;

  /// No description provided for @audioFocusReleaseFocusDesc.
  ///
  /// In en, this message translates to:
  /// **'Release audio focus when playback pauses or stops.'**
  String get audioFocusReleaseFocusDesc;

  /// No description provided for @audioFocusStopOnOtherSession.
  ///
  /// In en, this message translates to:
  /// **'Stop Music on Other Music Session'**
  String get audioFocusStopOnOtherSession;

  /// No description provided for @audioFocusStopOnOtherSessionDesc.
  ///
  /// In en, this message translates to:
  /// **'Pause playback when another app starts playing audio.'**
  String get audioFocusStopOnOtherSessionDesc;

  /// No description provided for @audioFocusRestartOnGain.
  ///
  /// In en, this message translates to:
  /// **'Restart Music on Focus Gain'**
  String get audioFocusRestartOnGain;

  /// No description provided for @audioFocusRestartOnGainDesc.
  ///
  /// In en, this message translates to:
  /// **'Resume playback automatically when audio focus returns, only if playback was interrupted by focus loss.'**
  String get audioFocusRestartOnGainDesc;

  /// No description provided for @pauseOnDuckTitle.
  ///
  /// In en, this message translates to:
  /// **'Pause on Duck'**
  String get pauseOnDuckTitle;

  /// No description provided for @pauseOnDuckDesc.
  ///
  /// In en, this message translates to:
  /// **'Pause playback instead of lowering volume when another app plays a transient sound (e.g. notifications, navigation directions).'**
  String get pauseOnDuckDesc;

  /// No description provided for @resumeOnBluetoothConnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Resume on Bluetooth Connect'**
  String get resumeOnBluetoothConnectTitle;

  /// No description provided for @resumeOnBluetoothConnectDesc.
  ///
  /// In en, this message translates to:
  /// **'Resume playback automatically when a Bluetooth audio device (headphones, car kit) reconnects.'**
  String get resumeOnBluetoothConnectDesc;

  /// No description provided for @manualCrossfadeDuration.
  ///
  /// In en, this message translates to:
  /// **'Manual Crossfade Duration'**
  String get manualCrossfadeDuration;

  /// No description provided for @manualCrossfadeDurationDesc.
  ///
  /// In en, this message translates to:
  /// **'The overlap time used when the user manually skips to the next or previous track. Usually this can be different from auto-crossfade so manual skips feel more controlled.'**
  String get manualCrossfadeDurationDesc;

  /// No description provided for @matchingLyrics.
  ///
  /// In en, this message translates to:
  /// **'MATCHING LYRICS'**
  String get matchingLyrics;

  /// No description provided for @metadataDetails.
  ///
  /// In en, this message translates to:
  /// **'Metadata Details'**
  String get metadataDetails;

  /// No description provided for @mostPlayed.
  ///
  /// In en, this message translates to:
  /// **'Most Played'**
  String get mostPlayed;

  /// No description provided for @musicAudioAccess.
  ///
  /// In en, this message translates to:
  /// **'MUSIC & AUDIO ACCESS'**
  String get musicAudioAccess;

  /// No description provided for @musicDarkness.
  ///
  /// In en, this message translates to:
  /// **'Music Player Darkness'**
  String get musicDarkness;

  /// No description provided for @musicDarknessDesc.
  ///
  /// In en, this message translates to:
  /// **'Adjust background overlay darkness for the Music Player screen'**
  String get musicDarknessDesc;

  /// No description provided for @musicLibrary.
  ///
  /// In en, this message translates to:
  /// **'Music Library'**
  String get musicLibrary;

  /// No description provided for @muteOrPauseCalls.
  ///
  /// In en, this message translates to:
  /// **'Mute or pause during calls and other audio activity'**
  String get muteOrPauseCalls;

  /// No description provided for @newPlaylist.
  ///
  /// In en, this message translates to:
  /// **'New Playlist'**
  String get newPlaylist;

  /// No description provided for @newTitle.
  ///
  /// In en, this message translates to:
  /// **'New Title'**
  String get newTitle;

  /// No description provided for @nextUp.
  ///
  /// In en, this message translates to:
  /// **'Next Up'**
  String get nextUp;

  /// No description provided for @noAlbumsFound.
  ///
  /// In en, this message translates to:
  /// **'No albums found'**
  String get noAlbumsFound;

  /// No description provided for @noArtistsFound.
  ///
  /// In en, this message translates to:
  /// **'No artists found'**
  String get noArtistsFound;

  /// No description provided for @noFavoritesYet.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get noFavoritesYet;

  /// No description provided for @noHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get noHistoryYet;

  /// No description provided for @noLyrics.
  ///
  /// In en, this message translates to:
  /// **'No Lyrics Found'**
  String get noLyrics;

  /// No description provided for @noMusicDetected.
  ///
  /// In en, this message translates to:
  /// **'NO MUSIC DETECTED'**
  String get noMusicDetected;

  /// No description provided for @noPlaylistsCreated.
  ///
  /// In en, this message translates to:
  /// **'No playlists created yet.'**
  String get noPlaylistsCreated;

  /// No description provided for @noPlaylistsYet.
  ///
  /// In en, this message translates to:
  /// **'No playlists yet'**
  String get noPlaylistsYet;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @noSongsFound.
  ///
  /// In en, this message translates to:
  /// **'No songs found'**
  String get noSongsFound;

  /// No description provided for @notificationAccess.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATION ACCESS'**
  String get notificationAccess;

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now Playing'**
  String get nowPlaying;

  /// No description provided for @performanceOptimizerDashboard.
  ///
  /// In en, this message translates to:
  /// **'Performance Optimizer Dashboard'**
  String get performanceOptimizerDashboard;

  /// No description provided for @performanceOptimizerDashboardDesc.
  ///
  /// In en, this message translates to:
  /// **'Show real-time performance optimizer stats overlay'**
  String get performanceOptimizerDashboardDesc;

  /// No description provided for @permanentFocusChangePause.
  ///
  /// In en, this message translates to:
  /// **'Permanent Focus Change Pause'**
  String get permanentFocusChangePause;

  /// No description provided for @permanentFocusChangePauseDesc.
  ///
  /// In en, this message translates to:
  /// **'Pause playing automatically on permanent audio focus loss'**
  String get permanentFocusChangePauseDesc;

  /// No description provided for @plainTimestamps.
  ///
  /// In en, this message translates to:
  /// **'Plain Timestamps'**
  String get plainTimestamps;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @playAll.
  ///
  /// In en, this message translates to:
  /// **'Play All'**
  String get playAll;

  /// No description provided for @playbackAudio.
  ///
  /// In en, this message translates to:
  /// **'Playback & Language'**
  String get playbackAudio;

  /// No description provided for @playlists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get playlists;

  /// No description provided for @playNext.
  ///
  /// In en, this message translates to:
  /// **'Play Next'**
  String get playNext;

  /// No description provided for @playQueue.
  ///
  /// In en, this message translates to:
  /// **'Play Queue'**
  String get playQueue;

  /// No description provided for @pressBackExit.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get pressBackExit;

  /// No description provided for @privacySafety.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Safety'**
  String get privacySafety;

  /// No description provided for @privacySafetyDesc.
  ///
  /// In en, this message translates to:
  /// **'100% private and offline-first. Your tracks, playback history, favorites, and configuration stay strictly inside a secure Isar database on your local device. We do not track, collect, or share your usage data or preferences.'**
  String get privacySafetyDesc;

  /// No description provided for @pureBlackOled.
  ///
  /// In en, this message translates to:
  /// **'Pure Black (OLED)'**
  String get pureBlackOled;

  /// No description provided for @pureBlackOledDesc.
  ///
  /// In en, this message translates to:
  /// **'Use absolute black backgrounds'**
  String get pureBlackOledDesc;

  /// No description provided for @queue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queue;

  /// No description provided for @queueIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Queue is empty'**
  String get queueIsEmpty;

  /// No description provided for @quickPicks.
  ///
  /// In en, this message translates to:
  /// **'Quick Picks'**
  String get quickPicks;

  /// No description provided for @quickPicksRowDesc.
  ///
  /// In en, this message translates to:
  /// **'Your most played grid of songs'**
  String get quickPicksRowDesc;

  /// No description provided for @readyToScan.
  ///
  /// In en, this message translates to:
  /// **'Ready to Scan'**
  String get readyToScan;

  /// No description provided for @recentlyAddedSongsRowDesc.
  ///
  /// In en, this message translates to:
  /// **'A list of your latest imports'**
  String get recentlyAddedSongsRowDesc;

  /// No description provided for @recentlyPlayed.
  ///
  /// In en, this message translates to:
  /// **'Recently Played'**
  String get recentlyPlayed;

  /// No description provided for @recentPlayed.
  ///
  /// In en, this message translates to:
  /// **'Recent Played'**
  String get recentPlayed;

  /// No description provided for @recentRowDesc.
  ///
  /// In en, this message translates to:
  /// **'Horizontal shelf of recently played tracks'**
  String get recentRowDesc;

  /// No description provided for @removedFromPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Removed from Playlist'**
  String get removedFromPlaylist;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get removeFromFavorites;

  /// No description provided for @removeFromPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Remove from Playlist'**
  String get removeFromPlaylist;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @renameFile.
  ///
  /// In en, this message translates to:
  /// **'Rename File'**
  String get renameFile;

  /// No description provided for @renamePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Rename Playlist'**
  String get renamePlaylist;

  /// No description provided for @renameSong.
  ///
  /// In en, this message translates to:
  /// **'Rename Song'**
  String get renameSong;

  /// No description provided for @reorderDashboardSections.
  ///
  /// In en, this message translates to:
  /// **'Reorder Dashboard Sections'**
  String get reorderDashboardSections;

  /// No description provided for @reorderDashboardSectionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Drag and drop to set preferred dashboard order'**
  String get reorderDashboardSectionsDesc;

  /// No description provided for @includeOtherDeviceAudioTitle.
  ///
  /// In en, this message translates to:
  /// **'Include other device audio'**
  String get includeOtherDeviceAudioTitle;

  /// No description provided for @includeOtherDeviceAudioDesc.
  ///
  /// In en, this message translates to:
  /// **'Scan ringtones, notifications, alarms, WhatsApp and Telegram audio'**
  String get includeOtherDeviceAudioDesc;

  /// No description provided for @rescanLibrary.
  ///
  /// In en, this message translates to:
  /// **'Rescan Library'**
  String get rescanLibrary;

  /// No description provided for @rescanStorage.
  ///
  /// In en, this message translates to:
  /// **'RESCAN STORAGE'**
  String get rescanStorage;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @resetLibrary.
  ///
  /// In en, this message translates to:
  /// **'Reset & Rescan'**
  String get resetLibrary;

  /// No description provided for @resetLibraryConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will clear all songs, albums, and artists and perform a full rescan of your folders.'**
  String get resetLibraryConfirm;

  /// No description provided for @resetLibraryConfirmNew.
  ///
  /// In en, this message translates to:
  /// **'This will remove all songs from your library. Your music files will not be deleted.'**
  String get resetLibraryConfirmNew;

  /// No description provided for @resetLibraryDesc.
  ///
  /// In en, this message translates to:
  /// **'Remove all songs from your indexed library'**
  String get resetLibraryDesc;

  /// No description provided for @resumeAfterCallDesc.
  ///
  /// In en, this message translates to:
  /// **'Resume playing automatically on call hang up (if paused by call)'**
  String get resumeAfterCallDesc;

  /// No description provided for @resumeAfterCallTitle.
  ///
  /// In en, this message translates to:
  /// **'Resume after Call'**
  String get resumeAfterCallTitle;

  /// No description provided for @resumeOnStartDesc.
  ///
  /// In en, this message translates to:
  /// **'Restore the previous playback state when the app or player service starts again.'**
  String get resumeOnStartDesc;

  /// No description provided for @resumeOnStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Resume on Start'**
  String get resumeOnStartTitle;

  /// No description provided for @persistQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Persist Last Queue'**
  String get persistQueueTitle;

  /// No description provided for @persistQueueDesc.
  ///
  /// In en, this message translates to:
  /// **'Saves the last played song, queue order, and playback position so the app can restore the same session after restart. In real use, this means when the app is reopened, the user can continue from the same song list instead of starting over.'**
  String get persistQueueDesc;

  /// No description provided for @keepSongProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep Song Progress'**
  String get keepSongProgressTitle;

  /// No description provided for @keepSongProgressDesc.
  ///
  /// In en, this message translates to:
  /// **'Remembers each song\'s own playback position separately. Switch to another song partway through and come back later — even after playing other songs in between — and it resumes right where you left off instead of starting over.'**
  String get keepSongProgressDesc;

  /// No description provided for @right.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get right;

  /// No description provided for @scanCompleteSongsDetected.
  ///
  /// In en, this message translates to:
  /// **'SCAN COMPLETE: {count} SONGS DETECTED!'**
  String scanCompleteSongsDetected(int count);

  /// No description provided for @scanForMusic.
  ///
  /// In en, this message translates to:
  /// **'SCAN FOR MUSIC'**
  String get scanForMusic;

  /// No description provided for @scanIndexLocalDesc.
  ///
  /// In en, this message translates to:
  /// **'Scan & index local music files'**
  String get scanIndexLocalDesc;

  /// No description provided for @scanLibrary.
  ///
  /// In en, this message translates to:
  /// **'Scan Library'**
  String get scanLibrary;

  /// No description provided for @scanningInBackground.
  ///
  /// In en, this message translates to:
  /// **'Scanning in background...'**
  String get scanningInBackground;

  /// No description provided for @scanningLibrary.
  ///
  /// In en, this message translates to:
  /// **'Scanning library...'**
  String get scanningLibrary;

  /// No description provided for @scanningStorage.
  ///
  /// In en, this message translates to:
  /// **'SCANNING STORAGE...'**
  String get scanningStorage;

  /// No description provided for @scanningStorageDesc.
  ///
  /// In en, this message translates to:
  /// **'Traversing directory trees to discover audio tracks. Please hold on...'**
  String get scanningStorageDesc;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchLibraryHint.
  ///
  /// In en, this message translates to:
  /// **'Search your entire library'**
  String get searchLibraryHint;

  /// No description provided for @searchSongsHint.
  ///
  /// In en, this message translates to:
  /// **'Search songs'**
  String get searchSongsHint;

  /// No description provided for @seekFadeDuration.
  ///
  /// In en, this message translates to:
  /// **'Seek Fade Duration'**
  String get seekFadeDuration;

  /// No description provided for @seekFadeDurationDesc.
  ///
  /// In en, this message translates to:
  /// **'How long the seek fade-out and fade-in takes. Example: 50ms is a very short protective fade around seek changes.'**
  String get seekFadeDurationDesc;

  /// No description provided for @selectAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select application language'**
  String get selectAppLanguage;

  /// No description provided for @selectCustomColor.
  ///
  /// In en, this message translates to:
  /// **'Select Custom Color'**
  String get selectCustomColor;

  /// No description provided for @selectCustomFolder.
  ///
  /// In en, this message translates to:
  /// **'SELECT CUSTOM FOLDER'**
  String get selectCustomFolder;

  /// No description provided for @selectFolderIndex.
  ///
  /// In en, this message translates to:
  /// **'Select folder to index music files'**
  String get selectFolderIndex;

  /// No description provided for @selectSpecificFolder.
  ///
  /// In en, this message translates to:
  /// **'SELECT SPECIFIC FOLDER'**
  String get selectSpecificFolder;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @shareFile.
  ///
  /// In en, this message translates to:
  /// **'Share File'**
  String get shareFile;

  /// No description provided for @showAlbumsRow.
  ///
  /// In en, this message translates to:
  /// **'Show Albums Row'**
  String get showAlbumsRow;

  /// No description provided for @showAlbumsRowDesc.
  ///
  /// In en, this message translates to:
  /// **'Display a horizontal list of albums on your Home screen'**
  String get showAlbumsRowDesc;

  /// No description provided for @showArtistsRow.
  ///
  /// In en, this message translates to:
  /// **'Show Artists Row'**
  String get showArtistsRow;

  /// No description provided for @showArtistsRowDesc.
  ///
  /// In en, this message translates to:
  /// **'Display a horizontal list of artists on your Home screen'**
  String get showArtistsRowDesc;

  /// No description provided for @showGenresRow.
  ///
  /// In en, this message translates to:
  /// **'Show Genres Row'**
  String get showGenresRow;

  /// No description provided for @showGenresRowDesc.
  ///
  /// In en, this message translates to:
  /// **'Display a horizontal list of genres on your Home screen'**
  String get showGenresRowDesc;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show Less'**
  String get showLess;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show More'**
  String get showMore;

  /// No description provided for @showQualityBadge.
  ///
  /// In en, this message translates to:
  /// **'Show Quality Badge'**
  String get showQualityBadge;

  /// No description provided for @showQualityBadgeDesc.
  ///
  /// In en, this message translates to:
  /// **'Display audio quality information badge on the now playing screen'**
  String get showQualityBadgeDesc;

  /// No description provided for @showRecentRow.
  ///
  /// In en, this message translates to:
  /// **'Show Recent Row'**
  String get showRecentRow;

  /// No description provided for @showRecentRowDesc.
  ///
  /// In en, this message translates to:
  /// **'Display a horizontal list of recently played tracks on your Home screen'**
  String get showRecentRowDesc;

  /// No description provided for @silenceBetweenTracksDesc.
  ///
  /// In en, this message translates to:
  /// **'Adds a gap between songs. At 0ms, tracks play gaplessly. At a higher value, the app inserts a pause between tracks, which is useful for live recordings, playlists that need breathing room, or older-style album playback.'**
  String get silenceBetweenTracksDesc;

  /// No description provided for @silenceBetweenTracksTitle.
  ///
  /// In en, this message translates to:
  /// **'Silence Between Tracks'**
  String get silenceBetweenTracksTitle;

  /// No description provided for @songDeletedDbOnly.
  ///
  /// In en, this message translates to:
  /// **'Song removed from library (physical file read-only)'**
  String get songDeletedDbOnly;

  /// No description provided for @songDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Song deleted successfully'**
  String get songDeletedSuccess;

  /// No description provided for @songDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete song'**
  String get songDeleteFailed;

  /// No description provided for @songDetails.
  ///
  /// In en, this message translates to:
  /// **'Song Details'**
  String get songDetails;

  /// No description provided for @songDetailsAndFrequency.
  ///
  /// In en, this message translates to:
  /// **'Song Details & Frequency'**
  String get songDetailsAndFrequency;

  /// No description provided for @songRenamedDbOnly.
  ///
  /// In en, this message translates to:
  /// **'Song renamed in app library (physical file read-only)'**
  String get songRenamedDbOnly;

  /// No description provided for @songRenamedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Song renamed successfully'**
  String get songRenamedSuccess;

  /// No description provided for @songRenameFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to rename song'**
  String get songRenameFailed;

  /// No description provided for @songs.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get songs;

  /// No description provided for @songsDarkness.
  ///
  /// In en, this message translates to:
  /// **'Songs Screen Darkness'**
  String get songsDarkness;

  /// No description provided for @songsDarknessDesc.
  ///
  /// In en, this message translates to:
  /// **'Adjust background overlay darkness for the Songs screen'**
  String get songsDarknessDesc;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @sortOrder.
  ///
  /// In en, this message translates to:
  /// **'Sort Order'**
  String get sortOrder;

  /// No description provided for @sourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source Code'**
  String get sourceCode;

  /// No description provided for @stopServiceOnAppDismissal.
  ///
  /// In en, this message translates to:
  /// **'Stop Service on App Dismissal'**
  String get stopServiceOnAppDismissal;

  /// No description provided for @stopServiceOnAppDismissalDesc.
  ///
  /// In en, this message translates to:
  /// **'Stop background service and close app when dismissed'**
  String get stopServiceOnAppDismissalDesc;

  /// No description provided for @storagePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Storage permissions are required to scan device memory.'**
  String get storagePermissionRequired;

  /// No description provided for @syncLyricsOffline.
  ///
  /// In en, this message translates to:
  /// **'Sync Lyrics (Offline)'**
  String get syncLyricsOffline;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @systemPermissionChecklist.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM PERMISSION CHECKLIST'**
  String get systemPermissionChecklist;

  /// No description provided for @technicalInfoFrequency.
  ///
  /// In en, this message translates to:
  /// **'Technical Info & Frequency'**
  String get technicalInfoFrequency;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @todayMixForYou.
  ///
  /// In en, this message translates to:
  /// **'Today Mix for you'**
  String get todayMixForYou;

  /// No description provided for @toggleFavorite.
  ///
  /// In en, this message translates to:
  /// **'Toggle Favorite'**
  String get toggleFavorite;

  /// No description provided for @shuffleTitle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get shuffleTitle;

  /// No description provided for @shuffleDisabledDesc.
  ///
  /// In en, this message translates to:
  /// **'Play songs in their original queue order. Turning shuffle off keeps the current song playing and restores the remaining queue to its original sequence without affecting playback or playback history.'**
  String get shuffleDisabledDesc;

  /// No description provided for @shuffleEnabledDesc.
  ///
  /// In en, this message translates to:
  /// **'Randomize the remaining songs while keeping the current song unchanged. The generated shuffle order remains consistent until the queue changes or a new shuffle is requested, preventing repeated or skipped tracks.'**
  String get shuffleEnabledDesc;

  /// No description provided for @shuffleSwitchingDesc.
  ///
  /// In en, this message translates to:
  /// **'Toggling shuffle never restarts the current song. It only changes the order of upcoming tracks—randomized when enabled and restored to the original queue order when disabled.'**
  String get shuffleSwitchingDesc;

  /// No description provided for @topResult.
  ///
  /// In en, this message translates to:
  /// **'Top Result'**
  String get topResult;

  /// No description provided for @transferMusicFiles.
  ///
  /// In en, this message translates to:
  /// **'TRANSFER MUSIC FILES'**
  String get transferMusicFiles;

  /// No description provided for @turnOffBlursOptimize.
  ///
  /// In en, this message translates to:
  /// **'Turn off heavy blurs to optimize performance'**
  String get turnOffBlursOptimize;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @unknownAlbum.
  ///
  /// In en, this message translates to:
  /// **'Unknown Album'**
  String get unknownAlbum;

  /// No description provided for @unknownArtist.
  ///
  /// In en, this message translates to:
  /// **'Unknown Artist'**
  String get unknownArtist;

  /// No description provided for @updateLibraryIndexing.
  ///
  /// In en, this message translates to:
  /// **'Update library files indexing'**
  String get updateLibraryIndexing;

  /// No description provided for @useAbsoluteBlackBg.
  ///
  /// In en, this message translates to:
  /// **'Use absolute black for backgrounds'**
  String get useAbsoluteBlackBg;

  /// No description provided for @useStaticTextTimestamps.
  ///
  /// In en, this message translates to:
  /// **'Use static text instead of rolling animation for progress duration'**
  String get useStaticTextTimestamps;

  /// No description provided for @fluidPlayer.
  ///
  /// In en, this message translates to:
  /// **'Fluid Player'**
  String get fluidPlayer;

  /// No description provided for @fluidPlayerDesc.
  ///
  /// In en, this message translates to:
  /// **'Drag the mini player up to morph it into the full player'**
  String get fluidPlayerDesc;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @visitOfficialRepository.
  ///
  /// In en, this message translates to:
  /// **'Visit official repository on GitHub'**
  String get visitOfficialRepository;

  /// No description provided for @welcomeAboutDesc.
  ///
  /// In en, this message translates to:
  /// **'Looper Player is a next-generation Music-OS built for premium offline audio playback. Features real-time dynamic lyrics generation, advanced audio session management with call mute handling, adaptive background theming, and multi-format music library support. Fully optimized for maximum battery efficiency.'**
  String get welcomeAboutDesc;

  /// No description provided for @welcomeAllFilesDesc.
  ///
  /// In en, this message translates to:
  /// **'Highly recommended for professional scanning to locate songs in non-standard directories (Downloads, Telegram, custom folders).'**
  String get welcomeAllFilesDesc;

  /// No description provided for @welcomeInstructionConnectDesc.
  ///
  /// In en, this message translates to:
  /// **'Plug your phone or device into a personal computer using a standard USB data cable.'**
  String get welcomeInstructionConnectDesc;

  /// No description provided for @welcomeInstructionDownloadDesc.
  ///
  /// In en, this message translates to:
  /// **'Alternatively, download files directly using a web browser or other downloader utility on the device itself.'**
  String get welcomeInstructionDownloadDesc;

  /// No description provided for @welcomeInstructionTransferDesc.
  ///
  /// In en, this message translates to:
  /// **'Copy your offline music files (supports .mp3, .flac, .m4a, .wav) directly into the standard \'Music\' or \'Download\' folder of your device.'**
  String get welcomeInstructionTransferDesc;

  /// No description provided for @welcomeMusicAudioDesc.
  ///
  /// In en, this message translates to:
  /// **'Required to discover and play standard offline audio tracks on your device memory.'**
  String get welcomeMusicAudioDesc;

  /// No description provided for @welcomeNoSongsDesc.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find any supported audio files (MP3, FLAC, WAV, M4A, OGG) on your device storage.'**
  String get welcomeNoSongsDesc;

  /// No description provided for @welcomeNotificationDesc.
  ///
  /// In en, this message translates to:
  /// **'Required to show playback controls and active notification widgets in your system bar.'**
  String get welcomeNotificationDesc;

  /// No description provided for @welcomeScanningFoldersDesc.
  ///
  /// In en, this message translates to:
  /// **'Scanning all folders and subfolders for audio files.'**
  String get welcomeScanningFoldersDesc;

  /// No description provided for @whyInternetUsed.
  ///
  /// In en, this message translates to:
  /// **'Why Internet is Used'**
  String get whyInternetUsed;

  /// No description provided for @whyInternetUsedDesc.
  ///
  /// In en, this message translates to:
  /// **'• Dynamic Lyrics Syncing: Used solely to securely fetch and download synchronized lyrics (LRC formats) from online databases. No personal data, settings, or media files are ever uploaded or shared.'**
  String get whyInternetUsedDesc;

  /// No description provided for @whyPermissionsUsed.
  ///
  /// In en, this message translates to:
  /// **'Why Permissions are Used'**
  String get whyPermissionsUsed;

  /// No description provided for @whyPermissionsUsedDesc.
  ///
  /// In en, this message translates to:
  /// **'• Storage / Media Access: Required to discover, read, and index local audio tracks stored on your device.\n• Notifications: Required to display active playback control widgets in your status bar and system drawer.'**
  String get whyPermissionsUsedDesc;

  /// No description provided for @willPlayNext.
  ///
  /// In en, this message translates to:
  /// **'Will play next'**
  String get willPlayNext;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @supportUs.
  ///
  /// In en, this message translates to:
  /// **'Support Us'**
  String get supportUs;

  /// No description provided for @supportUsDesc.
  ///
  /// In en, this message translates to:
  /// **'Help keep Looper Player alive & open-source'**
  String get supportUsDesc;

  /// No description provided for @supportDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Support the Development'**
  String get supportDevelopment;

  /// No description provided for @supportDevelopmentDesc.
  ///
  /// In en, this message translates to:
  /// **'Looper Player is 100% free and open-source. If you enjoy using it, please consider supporting the creator with a donation. Every contribution helps keep the project active!'**
  String get supportDevelopmentDesc;

  /// No description provided for @useCustomFont.
  ///
  /// In en, this message translates to:
  /// **'Use Custom Font'**
  String get useCustomFont;

  /// No description provided for @useCustomFontDesc.
  ///
  /// In en, this message translates to:
  /// **'Use Jost or other custom fonts. Otherwise, DM Sans is used.'**
  String get useCustomFontDesc;

  /// No description provided for @selectFontFamily.
  ///
  /// In en, this message translates to:
  /// **'Select Font Family'**
  String get selectFontFamily;

  /// No description provided for @activeFont.
  ///
  /// In en, this message translates to:
  /// **'Active font: {fontName}'**
  String activeFont(String fontName);

  /// No description provided for @fontWeightAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Font Weight Adjustment'**
  String get fontWeightAdjustment;

  /// No description provided for @currentWeight.
  ///
  /// In en, this message translates to:
  /// **'Current weight'**
  String get currentWeight;

  /// No description provided for @useCustomFontLyrics.
  ///
  /// In en, this message translates to:
  /// **'Use Custom Font for Lyrics'**
  String get useCustomFontLyrics;

  /// No description provided for @useCustomFontLyricsDesc.
  ///
  /// In en, this message translates to:
  /// **'Use custom font and weight for synchronized lyrics view'**
  String get useCustomFontLyricsDesc;

  /// No description provided for @lyricsFontFamily.
  ///
  /// In en, this message translates to:
  /// **'Lyrics Font Family'**
  String get lyricsFontFamily;

  /// No description provided for @activeLyricsFont.
  ///
  /// In en, this message translates to:
  /// **'Active lyrics font: {fontName}'**
  String activeLyricsFont(String fontName);

  /// No description provided for @lyricsFontWeightAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Lyrics Font Weight Adjustment'**
  String get lyricsFontWeightAdjustment;

  /// No description provided for @giveStarOnGithub.
  ///
  /// In en, this message translates to:
  /// **'Give Star on GitHub'**
  String get giveStarOnGithub;

  /// No description provided for @supportProjectLove.
  ///
  /// In en, this message translates to:
  /// **'Support the project and show some love!'**
  String get supportProjectLove;

  /// No description provided for @sortAlphabeticalAZ.
  ///
  /// In en, this message translates to:
  /// **'Alphabetical (A-Z)'**
  String get sortAlphabeticalAZ;

  /// No description provided for @sortAlphabeticalZA.
  ///
  /// In en, this message translates to:
  /// **'Alphabetical (Z-A)'**
  String get sortAlphabeticalZA;

  /// No description provided for @sortRecentlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently Added'**
  String get sortRecentlyAdded;

  /// No description provided for @sortOldestAdded.
  ///
  /// In en, this message translates to:
  /// **'Oldest Added'**
  String get sortOldestAdded;

  /// No description provided for @sortYearNewest.
  ///
  /// In en, this message translates to:
  /// **'Year (Newest)'**
  String get sortYearNewest;

  /// No description provided for @sortYearOldest.
  ///
  /// In en, this message translates to:
  /// **'Year (Oldest)'**
  String get sortYearOldest;

  /// No description provided for @sortMostSongs.
  ///
  /// In en, this message translates to:
  /// **'Most Songs'**
  String get sortMostSongs;

  /// No description provided for @sortLeastSongs.
  ///
  /// In en, this message translates to:
  /// **'Least Songs'**
  String get sortLeastSongs;

  /// No description provided for @sortDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get sortDefault;

  /// No description provided for @sortArtistAsc.
  ///
  /// In en, this message translates to:
  /// **'Artist (A-Z)'**
  String get sortArtistAsc;

  /// No description provided for @sortAlbumAsc.
  ///
  /// In en, this message translates to:
  /// **'Album (A-Z)'**
  String get sortAlbumAsc;

  /// No description provided for @sortDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get sortDuration;

  /// No description provided for @myAlbums.
  ///
  /// In en, this message translates to:
  /// **'My Albums'**
  String get myAlbums;

  /// No description provided for @featuredArtists.
  ///
  /// In en, this message translates to:
  /// **'Featured Artists'**
  String get featuredArtists;

  /// No description provided for @noSongPlaying.
  ///
  /// In en, this message translates to:
  /// **'No song playing'**
  String get noSongPlaying;

  /// No description provided for @nextLabel.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextLabel;

  /// No description provided for @previousLabel.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previousLabel;

  /// No description provided for @resync.
  ///
  /// In en, this message translates to:
  /// **'Re-sync'**
  String get resync;

  /// No description provided for @equalizer.
  ///
  /// In en, this message translates to:
  /// **'Equalizer'**
  String get equalizer;

  /// No description provided for @presets.
  ///
  /// In en, this message translates to:
  /// **'PRESETS'**
  String get presets;

  /// No description provided for @preAmpGain.
  ///
  /// In en, this message translates to:
  /// **'Pre-amp Gain'**
  String get preAmpGain;

  /// No description provided for @outputVolume.
  ///
  /// In en, this message translates to:
  /// **'Output Volume'**
  String get outputVolume;

  /// No description provided for @customFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Type custom libavfilter audio filter parameters directly (e.g. volume=3dB, aecho=0.8:0.88:60:0.4):'**
  String get customFilterHint;

  /// No description provided for @flowGlobalActions.
  ///
  /// In en, this message translates to:
  /// **'Flow & Global Actions'**
  String get flowGlobalActions;

  /// No description provided for @equalizerModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Equalizer Mode:'**
  String get equalizerModeLabel;

  /// No description provided for @currentGainsAppliedGlobal.
  ///
  /// In en, this message translates to:
  /// **'Current gains applied as global default settings.'**
  String get currentGainsAppliedGlobal;

  /// No description provided for @applyToGlobal.
  ///
  /// In en, this message translates to:
  /// **'Apply to Global'**
  String get applyToGlobal;

  /// No description provided for @songSpecificResetGlobal.
  ///
  /// In en, this message translates to:
  /// **'Song-specific settings reset to global default.'**
  String get songSpecificResetGlobal;

  /// No description provided for @resetToGlobal.
  ///
  /// In en, this message translates to:
  /// **'Reset to Global'**
  String get resetToGlobal;

  /// No description provided for @resetAllSongsEq.
  ///
  /// In en, this message translates to:
  /// **'Reset All Songs EQ'**
  String get resetAllSongsEq;

  /// No description provided for @resetAllSongsEqConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear custom equalizer settings for all songs in your library?'**
  String get resetAllSongsEqConfirm;

  /// No description provided for @allSongsEqDataReset.
  ///
  /// In en, this message translates to:
  /// **'All song-specific equalizer data has been reset.'**
  String get allSongsEqDataReset;

  /// No description provided for @resetAllSongsEqData.
  ///
  /// In en, this message translates to:
  /// **'Reset All Songs EQ Data'**
  String get resetAllSongsEqData;

  /// No description provided for @equalizerTargetMode.
  ///
  /// In en, this message translates to:
  /// **'Equalizer Target Mode'**
  String get equalizerTargetMode;

  /// No description provided for @equalizerTargetModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Select how equalizer settings are applied across your music library.'**
  String get equalizerTargetModeDesc;

  /// No description provided for @globalMode.
  ///
  /// In en, this message translates to:
  /// **'Global Mode'**
  String get globalMode;

  /// No description provided for @globalModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Applies effects to all songs universally. Equalizer settings remain the same when the song changes.'**
  String get globalModeDesc;

  /// No description provided for @songSpecificMode.
  ///
  /// In en, this message translates to:
  /// **'Song-Specific Mode'**
  String get songSpecificMode;

  /// No description provided for @songSpecificModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Saves custom settings for the current song only. Next song defaults to no/flat equalizer unless it has its own profile.'**
  String get songSpecificModeDesc;

  /// No description provided for @viewDeviceAudioCapabilities.
  ///
  /// In en, this message translates to:
  /// **'View Device Audio Capabilities'**
  String get viewDeviceAudioCapabilities;

  /// No description provided for @deviceAudioCapabilities.
  ///
  /// In en, this message translates to:
  /// **'Device Audio Capabilities'**
  String get deviceAudioCapabilities;

  /// No description provided for @noPlaybackActiveCapabilities.
  ///
  /// In en, this message translates to:
  /// **'No playback active or capabilities information unavailable.'**
  String get noPlaybackActiveCapabilities;

  /// No description provided for @changeLyricsProvider.
  ///
  /// In en, this message translates to:
  /// **'Change Lyrics Provider'**
  String get changeLyricsProvider;

  /// No description provided for @autoFallbackProviders.
  ///
  /// In en, this message translates to:
  /// **'Auto Fallback Providers'**
  String get autoFallbackProviders;

  /// No description provided for @autoFallbackProvidersDesc.
  ///
  /// In en, this message translates to:
  /// **'Try remaining providers automatically if primary has no lyrics'**
  String get autoFallbackProvidersDesc;

  /// No description provided for @ambientColorBackground.
  ///
  /// In en, this message translates to:
  /// **'Ambient Color Background'**
  String get ambientColorBackground;

  /// No description provided for @ambientColorBackgroundDesc.
  ///
  /// In en, this message translates to:
  /// **'Smooth, subtle ambient gradients derived from song artwork'**
  String get ambientColorBackgroundDesc;

  /// No description provided for @exportLyricsLrc.
  ///
  /// In en, this message translates to:
  /// **'Export Lyrics (.lrc file)'**
  String get exportLyricsLrc;

  /// No description provided for @saveLyricsToDevice.
  ///
  /// In en, this message translates to:
  /// **'Save current lyrics to device storage'**
  String get saveLyricsToDevice;

  /// No description provided for @noLyricsToExport.
  ///
  /// In en, this message translates to:
  /// **'No lyrics available to export'**
  String get noLyricsToExport;

  /// No description provided for @useCustomLyricsLrc.
  ///
  /// In en, this message translates to:
  /// **'Use Custom Lyrics (LRC File)'**
  String get useCustomLyricsLrc;

  /// No description provided for @selectLocalLrcFile.
  ///
  /// In en, this message translates to:
  /// **'Select local .lrc or .txt file for this song'**
  String get selectLocalLrcFile;

  /// No description provided for @customLyricsAppliedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Custom lyrics applied successfully!'**
  String get customLyricsAppliedSuccess;

  /// No description provided for @noRecentlyPlayedTracks.
  ///
  /// In en, this message translates to:
  /// **'No recently played tracks'**
  String get noRecentlyPlayedTracks;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @audioQualityAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Audio Quality Analysis'**
  String get audioQualityAnalysis;

  /// No description provided for @audioQualityAnalysisDesc.
  ///
  /// In en, this message translates to:
  /// **'Perform deep spectral and audio format analysis'**
  String get audioQualityAnalysisDesc;

  /// No description provided for @audioStreamDetails.
  ///
  /// In en, this message translates to:
  /// **'Audio Stream Details'**
  String get audioStreamDetails;

  /// No description provided for @perChannelMetrics.
  ///
  /// In en, this message translates to:
  /// **'Per-Channel Metrics'**
  String get perChannelMetrics;

  /// No description provided for @sleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep Timer'**
  String get sleepTimer;

  /// No description provided for @stopByTime.
  ///
  /// In en, this message translates to:
  /// **'STOP BY TIME'**
  String get stopByTime;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @stopBySongCount.
  ///
  /// In en, this message translates to:
  /// **'STOP BY SONG COUNT'**
  String get stopBySongCount;

  /// No description provided for @cancelSleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Cancel Sleep Timer'**
  String get cancelSleepTimer;

  /// No description provided for @nowPlayingAllCaps.
  ///
  /// In en, this message translates to:
  /// **'NOW PLAYING'**
  String get nowPlayingAllCaps;

  /// No description provided for @settingsAndBackups.
  ///
  /// In en, this message translates to:
  /// **'Settings & Backups'**
  String get settingsAndBackups;

  /// No description provided for @managePreferencesLibraryData.
  ///
  /// In en, this message translates to:
  /// **'Manage preferences and library data'**
  String get managePreferencesLibraryData;

  /// No description provided for @logsClearedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Logs cleared successfully'**
  String get logsClearedSuccess;

  /// No description provided for @editSongInfo.
  ///
  /// In en, this message translates to:
  /// **'Edit Song Info'**
  String get editSongInfo;

  /// No description provided for @editAlbumInfo.
  ///
  /// In en, this message translates to:
  /// **'Edit Album Info'**
  String get editAlbumInfo;

  /// No description provided for @tapFieldToEdit.
  ///
  /// In en, this message translates to:
  /// **'Tap a field to edit'**
  String get tapFieldToEdit;

  /// No description provided for @alwaysBlurSheets.
  ///
  /// In en, this message translates to:
  /// **'Always Blur Sheets'**
  String get alwaysBlurSheets;

  /// No description provided for @alwaysBlurSheetsDesc.
  ///
  /// In en, this message translates to:
  /// **'Blur popup sheets even when Dynamic Theming is off'**
  String get alwaysBlurSheetsDesc;

  /// No description provided for @removeArtwork.
  ///
  /// In en, this message translates to:
  /// **'Remove artwork'**
  String get removeArtwork;

  /// No description provided for @resetArtworkToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get resetArtworkToDefault;

  /// No description provided for @artworkResetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Artwork reset to default'**
  String get artworkResetToDefault;

  /// No description provided for @noEmbeddedArtworkFound.
  ///
  /// In en, this message translates to:
  /// **'No embedded artwork found for this album'**
  String get noEmbeddedArtworkFound;

  /// No description provided for @saveChangesBtn.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChangesBtn;

  /// No description provided for @enterFolderPathManually.
  ///
  /// In en, this message translates to:
  /// **'Enter Folder Path Manually'**
  String get enterFolderPathManually;

  /// No description provided for @folderPickerManualHint.
  ///
  /// In en, this message translates to:
  /// **'If the system directory picker is not opening, type or paste the full directory path below:'**
  String get folderPickerManualHint;

  /// No description provided for @noSupportedSongsFoundFolder.
  ///
  /// In en, this message translates to:
  /// **'No supported songs found in the selected folder'**
  String get noSupportedSongsFoundFolder;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @folderPickerClosed.
  ///
  /// In en, this message translates to:
  /// **'Folder picker closed'**
  String get folderPickerClosed;

  /// No description provided for @buyMeCoffee.
  ///
  /// In en, this message translates to:
  /// **'Buy Me a Coffee'**
  String get buyMeCoffee;

  /// No description provided for @typeToSearchSettings.
  ///
  /// In en, this message translates to:
  /// **'Type to search settings...'**
  String get typeToSearchSettings;

  /// No description provided for @maintainersLabel.
  ///
  /// In en, this message translates to:
  /// **'Maintainers'**
  String get maintainersLabel;

  /// No description provided for @personBehindLooperPlayer.
  ///
  /// In en, this message translates to:
  /// **'Person behind LooperPlayer'**
  String get personBehindLooperPlayer;

  /// No description provided for @blurredArtworkForLyrics.
  ///
  /// In en, this message translates to:
  /// **'Blurred Artwork for Lyrics'**
  String get blurredArtworkForLyrics;

  /// No description provided for @blurredArtworkForLyricsDesc.
  ///
  /// In en, this message translates to:
  /// **'Show blurred album art as background instead of dynamic/static gradient'**
  String get blurredArtworkForLyricsDesc;

  /// No description provided for @lyricsFontWeight.
  ///
  /// In en, this message translates to:
  /// **'Lyrics Font Weight'**
  String get lyricsFontWeight;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get openSourceLicenses;

  /// No description provided for @openSourceLicensesDesc.
  ///
  /// In en, this message translates to:
  /// **'Third-party libraries used in this app'**
  String get openSourceLicensesDesc;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @lyricsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Lyrics not available.'**
  String get lyricsNotAvailable;

  /// No description provided for @lyricsNotAvailableHint.
  ///
  /// In en, this message translates to:
  /// **'Import a .lrc or .txt file to add lyrics for this song'**
  String get lyricsNotAvailableHint;

  /// No description provided for @importLyricsFile.
  ///
  /// In en, this message translates to:
  /// **'Import Lyrics File'**
  String get importLyricsFile;

  /// No description provided for @approximatedSyncNoWordTimings.
  ///
  /// In en, this message translates to:
  /// **'Approximated Sync (No Word Timings)'**
  String get approximatedSyncNoWordTimings;

  /// No description provided for @lyricsSyncHelp.
  ///
  /// In en, this message translates to:
  /// **'Lyrics Sync Help'**
  String get lyricsSyncHelp;

  /// No description provided for @simpleModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Simple Mode'**
  String get simpleModeLabel;

  /// No description provided for @advancedModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Advanced Mode'**
  String get advancedModeLabel;

  /// No description provided for @tips.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get tips;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @lyricsSyncStudio.
  ///
  /// In en, this message translates to:
  /// **'Lyrics Sync Studio'**
  String get lyricsSyncStudio;

  /// No description provided for @lyricsTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Lyrics Text'**
  String get lyricsTextLabel;

  /// No description provided for @lyricsTextHelperDesc.
  ///
  /// In en, this message translates to:
  /// **'One line per lyric row. The sync tools below attach timestamps to these lines.'**
  String get lyricsTextHelperDesc;

  /// No description provided for @quickSync.
  ///
  /// In en, this message translates to:
  /// **'Quick Sync'**
  String get quickSync;

  /// No description provided for @autoAdvanceAfterStamping.
  ///
  /// In en, this message translates to:
  /// **'Auto-advance after stamping'**
  String get autoAdvanceAfterStamping;

  /// No description provided for @advancedSync.
  ///
  /// In en, this message translates to:
  /// **'Advanced Sync'**
  String get advancedSync;

  /// No description provided for @useCurrentTime.
  ///
  /// In en, this message translates to:
  /// **'Use Current Time'**
  String get useCurrentTime;

  /// No description provided for @playbackAssist.
  ///
  /// In en, this message translates to:
  /// **'Playback Assist'**
  String get playbackAssist;

  /// No description provided for @timeShift.
  ///
  /// In en, this message translates to:
  /// **'Time Shift'**
  String get timeShift;

  /// No description provided for @timeShiftDesc.
  ///
  /// In en, this message translates to:
  /// **'Move every stamped lyric forward or backward together.'**
  String get timeShiftDesc;

  /// No description provided for @lyricsSaveLrcExplain.
  ///
  /// In en, this message translates to:
  /// **'Save writes an `.lrc` sidecar file beside the song audio if possible, and saves it in the local player database. Unstamped lines will be interpolated automatically.'**
  String get lyricsSaveLrcExplain;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @appSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettingsLabel;

  /// No description provided for @backupsAndLogs.
  ///
  /// In en, this message translates to:
  /// **'Backups & Logs'**
  String get backupsAndLogs;

  /// No description provided for @backupsAndLogsDesc.
  ///
  /// In en, this message translates to:
  /// **'Export, import & manage app data'**
  String get backupsAndLogsDesc;

  /// No description provided for @exportBackupJson.
  ///
  /// In en, this message translates to:
  /// **'Export Backup (JSON)'**
  String get exportBackupJson;

  /// No description provided for @exportBackupJsonDesc.
  ///
  /// In en, this message translates to:
  /// **'Saves your liked songs and playlists to a JSON file you can keep or share. Nothing else is included.'**
  String get exportBackupJsonDesc;

  /// No description provided for @importBackupJson.
  ///
  /// In en, this message translates to:
  /// **'Import Backup (JSON)'**
  String get importBackupJson;

  /// No description provided for @importBackupJsonDesc.
  ///
  /// In en, this message translates to:
  /// **'Merges liked songs and playlists from a backup file into your library. Existing data is never overwritten or removed.'**
  String get importBackupJsonDesc;

  /// No description provided for @exportDiagnosticsLogs.
  ///
  /// In en, this message translates to:
  /// **'Export Diagnostics Logs'**
  String get exportDiagnosticsLogs;

  /// No description provided for @exportDiagnosticsLogsDesc.
  ///
  /// In en, this message translates to:
  /// **'Shares the app\'s diagnostic log file so it can be reviewed for troubleshooting.'**
  String get exportDiagnosticsLogsDesc;

  /// No description provided for @clearDiagnosticsLogs.
  ///
  /// In en, this message translates to:
  /// **'Clear Diagnostics Logs'**
  String get clearDiagnosticsLogs;

  /// No description provided for @clearDiagnosticsLogsDesc.
  ///
  /// In en, this message translates to:
  /// **'Permanently erases the diagnostic log file stored on this device. This cannot be undone.'**
  String get clearDiagnosticsLogsDesc;

  /// No description provided for @lyricsPlainTextOrLrc.
  ///
  /// In en, this message translates to:
  /// **'Lyrics (Plain text or LRC)'**
  String get lyricsPlainTextOrLrc;

  /// No description provided for @syncModeLine.
  ///
  /// In en, this message translates to:
  /// **'LINE'**
  String get syncModeLine;

  /// No description provided for @syncModeWord.
  ///
  /// In en, this message translates to:
  /// **'WORD'**
  String get syncModeWord;

  /// No description provided for @syncModeChar.
  ///
  /// In en, this message translates to:
  /// **'CHAR'**
  String get syncModeChar;

  /// No description provided for @enterManually.
  ///
  /// In en, this message translates to:
  /// **'Enter Manually'**
  String get enterManually;

  /// No description provided for @rawFilterParametersHint.
  ///
  /// In en, this message translates to:
  /// **'Raw filter parameters...'**
  String get rawFilterParametersHint;

  /// No description provided for @searchSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'Search settings...'**
  String get searchSettingsHint;

  /// No description provided for @repeatTooltip.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeatTooltip;

  /// No description provided for @favoriteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get favoriteTooltip;

  /// No description provided for @instructionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructionsTooltip;

  /// No description provided for @pasteLyricsHint.
  ///
  /// In en, this message translates to:
  /// **'Paste or type the song lyrics here'**
  String get pasteLyricsHint;

  /// No description provided for @timestampMmSsHint.
  ///
  /// In en, this message translates to:
  /// **'Timestamp (mm:ss.xx)'**
  String get timestampMmSsHint;

  /// No description provided for @nowLabel.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get nowLabel;

  /// No description provided for @playlistNameHint.
  ///
  /// In en, this message translates to:
  /// **'Playlist name'**
  String get playlistNameHint;

  /// No description provided for @songInfoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Song info updated!'**
  String get songInfoUpdated;

  /// No description provided for @albumInfoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Album info updated!'**
  String get albumInfoUpdated;

  /// No description provided for @failedToSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Failed to save changes.'**
  String get failedToSaveChanges;

  /// No description provided for @sleepTimerStoppingIn.
  ///
  /// In en, this message translates to:
  /// **'Active: Stopping in {time}'**
  String sleepTimerStoppingIn(String time);

  /// No description provided for @sleepTimerStoppingAfter.
  ///
  /// In en, this message translates to:
  /// **'Active: Stopping after {time}'**
  String sleepTimerStoppingAfter(String time);

  /// No description provided for @selectWhenToPause.
  ///
  /// In en, this message translates to:
  /// **'Select when to pause music playback'**
  String get selectWhenToPause;

  /// No description provided for @selectAvatars.
  ///
  /// In en, this message translates to:
  /// **'Select Avatars'**
  String get selectAvatars;

  /// No description provided for @selectAvatarsDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose the avatar shown on your Home screen'**
  String get selectAvatarsDesc;

  /// No description provided for @dynamicAvatarColor.
  ///
  /// In en, this message translates to:
  /// **'Dynamic Avatar Color'**
  String get dynamicAvatarColor;

  /// No description provided for @dynamicAvatarColorDesc.
  ///
  /// In en, this message translates to:
  /// **'Match the avatar\'s accent color to your current theme'**
  String get dynamicAvatarColorDesc;

  /// No description provided for @enrichingSongs.
  ///
  /// In en, this message translates to:
  /// **'Enriching {count} songs…'**
  String enrichingSongs(int count);

  /// No description provided for @noListeningHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No listening history yet'**
  String get noListeningHistoryYet;

  /// No description provided for @noListeningHistoryYetDesc.
  ///
  /// In en, this message translates to:
  /// **'Play a few songs and your personal report card — top songs, artists, albums and genres — will come to life here.'**
  String get noListeningHistoryYetDesc;

  /// No description provided for @looperAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Looper Analyze'**
  String get looperAnalyze;

  /// No description provided for @totalPlays.
  ///
  /// In en, this message translates to:
  /// **'Total Plays'**
  String get totalPlays;

  /// No description provided for @listeningTime.
  ///
  /// In en, this message translates to:
  /// **'Listening Time'**
  String get listeningTime;

  /// No description provided for @currentStreakDays.
  ///
  /// In en, this message translates to:
  /// **'Current Streak (days)'**
  String get currentStreakDays;

  /// No description provided for @longestStreakDays.
  ///
  /// In en, this message translates to:
  /// **'Longest Streak (days)'**
  String get longestStreakDays;

  /// No description provided for @analyzePlaysAndSongs.
  ///
  /// In en, this message translates to:
  /// **'{plays} plays • {songs} songs'**
  String analyzePlaysAndSongs(int plays, int songs);

  /// No description provided for @dayPartMorningShort.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get dayPartMorningShort;

  /// No description provided for @dayPartAfternoonShort.
  ///
  /// In en, this message translates to:
  /// **'Aft'**
  String get dayPartAfternoonShort;

  /// No description provided for @dayPartEveningShort.
  ///
  /// In en, this message translates to:
  /// **'Eve'**
  String get dayPartEveningShort;

  /// No description provided for @dayPartNightShort.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get dayPartNightShort;

  /// No description provided for @activityPattern.
  ///
  /// In en, this message translates to:
  /// **'Activity Pattern'**
  String get activityPattern;

  /// No description provided for @whenYouListenMost.
  ///
  /// In en, this message translates to:
  /// **'When you listen most'**
  String get whenYouListenMost;

  /// No description provided for @genreBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Genre Breakdown'**
  String get genreBreakdown;

  /// No description provided for @otherGenre.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherGenre;

  /// No description provided for @topAlbums.
  ///
  /// In en, this message translates to:
  /// **'Top Albums'**
  String get topAlbums;

  /// No description provided for @topArtists.
  ///
  /// In en, this message translates to:
  /// **'Top Artists'**
  String get topArtists;

  /// No description provided for @topSongs.
  ///
  /// In en, this message translates to:
  /// **'Top Songs'**
  String get topSongs;

  /// No description provided for @playsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 play} other{{count} plays}}'**
  String playsCount(int count);

  /// No description provided for @songsPlayedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song played} other{{count} songs played}}'**
  String songsPlayedCount(int count);

  /// No description provided for @listeningTrend.
  ///
  /// In en, this message translates to:
  /// **'Listening Trend'**
  String get listeningTrend;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get last30Days;

  /// No description provided for @errorWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithDetails(String error);

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @playlist.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get playlist;

  /// No description provided for @songsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song} other{{count} songs}}'**
  String songsCount(int count);

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get recentSearches;

  /// No description provided for @lyricsSourceLocalFile.
  ///
  /// In en, this message translates to:
  /// **'Local File'**
  String get lyricsSourceLocalFile;

  /// No description provided for @lyricsSourceEmbedded.
  ///
  /// In en, this message translates to:
  /// **'Embedded Metadata'**
  String get lyricsSourceEmbedded;

  /// No description provided for @lyricsProvidedBy.
  ///
  /// In en, this message translates to:
  /// **'Lyrics provided by {source}'**
  String lyricsProvidedBy(String source);

  /// No description provided for @failedToImportLyrics.
  ///
  /// In en, this message translates to:
  /// **'Failed to import lyrics: {error}'**
  String failedToImportLyrics(String error);

  /// No description provided for @lyricsEditorLines.
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get lyricsEditorLines;

  /// No description provided for @lyricsEditorStamped.
  ///
  /// In en, this message translates to:
  /// **'Stamped'**
  String get lyricsEditorStamped;

  /// No description provided for @lyricsEditorLineNumber.
  ///
  /// In en, this message translates to:
  /// **'Line {number}'**
  String lyricsEditorLineNumber(int number);

  /// No description provided for @lyricsEditorEmptyLine.
  ///
  /// In en, this message translates to:
  /// **'(Empty line)'**
  String get lyricsEditorEmptyLine;

  /// No description provided for @lyricsEditorNotStamped.
  ///
  /// In en, this message translates to:
  /// **'Not stamped yet'**
  String get lyricsEditorNotStamped;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @lyricsEditorAddLineFirst.
  ///
  /// In en, this message translates to:
  /// **'Add at least one lyric line first.'**
  String get lyricsEditorAddLineFirst;

  /// No description provided for @lyricsEditorSavedWithSidecar.
  ///
  /// In en, this message translates to:
  /// **'Saved lyrics to database and beside the song file.'**
  String get lyricsEditorSavedWithSidecar;

  /// No description provided for @lyricsEditorSavedDbOnly.
  ///
  /// In en, this message translates to:
  /// **'Saved lyrics to player database.'**
  String get lyricsEditorSavedDbOnly;

  /// No description provided for @lyricsEditorSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the lyrics.'**
  String get lyricsEditorSaveFailed;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @saveLrc.
  ///
  /// In en, this message translates to:
  /// **'Save LRC'**
  String get saveLrc;

  /// No description provided for @lyricsEditorSelectedLine.
  ///
  /// In en, this message translates to:
  /// **'Selected line {index} of {total}'**
  String lyricsEditorSelectedLine(int index, int total);

  /// No description provided for @lyricsEditorPickLine.
  ///
  /// In en, this message translates to:
  /// **'Pick a lyric line from the list below.'**
  String get lyricsEditorPickLine;

  /// No description provided for @stampAndNext.
  ///
  /// In en, this message translates to:
  /// **'Stamp & Next'**
  String get stampAndNext;

  /// No description provided for @stampNow.
  ///
  /// In en, this message translates to:
  /// **'Stamp Now'**
  String get stampNow;

  /// No description provided for @lyricsEditorSimpleSteps.
  ///
  /// In en, this message translates to:
  /// **'1. Paste or type one lyric line per row.\n2. Play the song.\n3. Select the current lyric line.\n4. Tap \"Stamp & Next\" when you hear that line.\n5. Save when done.'**
  String get lyricsEditorSimpleSteps;

  /// No description provided for @lyricsEditorAdvancedSteps.
  ///
  /// In en, this message translates to:
  /// **'1. Edit timestamps directly for each line.\n2. Use \"Use Current Time\" to capture the live playback time.\n3. Use the shift controls to move all stamped lyrics together.\n4. Save to generate the final `.lrc` file.'**
  String get lyricsEditorAdvancedSteps;

  /// No description provided for @lyricsEditorTipsText.
  ///
  /// In en, this message translates to:
  /// **'- If some lines are not stamped, Flick\'s engine fills their times automatically.\n- Save writes beside the song when possible, otherwise it stores a linked copy in the DB.'**
  String get lyricsEditorTipsText;

  /// No description provided for @fileNotFoundOrInaccessible.
  ///
  /// In en, this message translates to:
  /// **'File not found or inaccessible: {title}'**
  String fileNotFoundOrInaccessible(String title);

  /// No description provided for @playbackFailedCorrupted.
  ///
  /// In en, this message translates to:
  /// **'Playback failed: Unable to load or play \"{title}\". Please verify the file is not corrupted.'**
  String playbackFailedCorrupted(String title);

  /// No description provided for @shareSongText.
  ///
  /// In en, this message translates to:
  /// **'Check out this song: {title}'**
  String shareSongText(String title);

  /// No description provided for @shareSongsText.
  ///
  /// In en, this message translates to:
  /// **'Check out these {count} songs'**
  String shareSongsText(int count);

  /// No description provided for @noSettingsFoundFor.
  ///
  /// In en, this message translates to:
  /// **'No settings found for \"{query}\"'**
  String noSettingsFoundFor(String query);

  /// No description provided for @chooseQuickAccentColors.
  ///
  /// In en, this message translates to:
  /// **'Choose quick accent colors'**
  String get chooseQuickAccentColors;

  /// No description provided for @fontWeight.
  ///
  /// In en, this message translates to:
  /// **'Font Weight'**
  String get fontWeight;

  /// No description provided for @changeBaseFontWeight.
  ///
  /// In en, this message translates to:
  /// **'Change base weight of custom font'**
  String get changeBaseFontWeight;

  /// No description provided for @lyricsFontWeightValue.
  ///
  /// In en, this message translates to:
  /// **'Lyrics font weight: {weight}'**
  String lyricsFontWeightValue(int weight);

  /// No description provided for @equalizerSearchDesc.
  ///
  /// In en, this message translates to:
  /// **'Adjust 18-band equalizer and audio presets'**
  String get equalizerSearchDesc;

  /// No description provided for @stopServiceSearchDesc.
  ///
  /// In en, this message translates to:
  /// **'Stop playback and close the app when swiped away from recent panel'**
  String get stopServiceSearchDesc;

  /// No description provided for @scanNewFolderDesc.
  ///
  /// In en, this message translates to:
  /// **'Scan a new folder for audio files'**
  String get scanNewFolderDesc;

  /// No description provided for @includeOtherDeviceAudioShortDesc.
  ///
  /// In en, this message translates to:
  /// **'Ringtones, notifications and messaging audio'**
  String get includeOtherDeviceAudioShortDesc;

  /// No description provided for @excludedFolders.
  ///
  /// In en, this message translates to:
  /// **'Excluded Folders'**
  String get excludedFolders;

  /// No description provided for @excludedFoldersSearchDesc.
  ///
  /// In en, this message translates to:
  /// **'Skip specific folders when scanning'**
  String get excludedFoldersSearchDesc;

  /// No description provided for @clearLibraryData.
  ///
  /// In en, this message translates to:
  /// **'Clear library data'**
  String get clearLibraryData;

  /// No description provided for @looperPlayerVersion.
  ///
  /// In en, this message translates to:
  /// **'Looper Player Version'**
  String get looperPlayerVersion;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @foldersSkippedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 folder skipped when scanning} other{{count} folders skipped when scanning}}'**
  String foldersSkippedCount(int count);

  /// No description provided for @excludedFoldersDesc.
  ///
  /// In en, this message translates to:
  /// **'Songs in these folders are skipped during a scan, even if they sit inside a folder you added.'**
  String get excludedFoldersDesc;

  /// No description provided for @noExcludedFoldersYet.
  ///
  /// In en, this message translates to:
  /// **'No excluded folders yet.'**
  String get noExcludedFoldersYet;

  /// No description provided for @excludeAFolder.
  ///
  /// In en, this message translates to:
  /// **'Exclude a Folder'**
  String get excludeAFolder;

  /// No description provided for @equalizerEnabled18Band.
  ///
  /// In en, this message translates to:
  /// **'Enabled (18-band MPV EQ)'**
  String get equalizerEnabled18Band;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @noIndexedFoldersYet.
  ///
  /// In en, this message translates to:
  /// **'No indexed folders yet'**
  String get noIndexedFoldersYet;

  /// No description provided for @noIndexedFoldersYetDesc.
  ///
  /// In en, this message translates to:
  /// **'Use Rescan Library to discover folders across storage.'**
  String get noIndexedFoldersYetDesc;

  /// No description provided for @eqDynamicRangeCompressor.
  ///
  /// In en, this message translates to:
  /// **'Dynamic Range Compressor'**
  String get eqDynamicRangeCompressor;

  /// No description provided for @eqThreshold.
  ///
  /// In en, this message translates to:
  /// **'Threshold'**
  String get eqThreshold;

  /// No description provided for @eqRatio.
  ///
  /// In en, this message translates to:
  /// **'Ratio'**
  String get eqRatio;

  /// No description provided for @eqAttack.
  ///
  /// In en, this message translates to:
  /// **'Attack'**
  String get eqAttack;

  /// No description provided for @eqRelease.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get eqRelease;

  /// No description provided for @eqHeadphoneCrossfeedWidth.
  ///
  /// In en, this message translates to:
  /// **'Headphone Crossfeed & Width'**
  String get eqHeadphoneCrossfeedWidth;

  /// No description provided for @eqBinauralCrossfeed.
  ///
  /// In en, this message translates to:
  /// **'Binaural Crossfeed'**
  String get eqBinauralCrossfeed;

  /// No description provided for @eqCrossfeedStrength.
  ///
  /// In en, this message translates to:
  /// **'Crossfeed Strength'**
  String get eqCrossfeedStrength;

  /// No description provided for @eqStereoWidening.
  ///
  /// In en, this message translates to:
  /// **'Stereo Widening'**
  String get eqStereoWidening;

  /// No description provided for @eqWideningFactor.
  ///
  /// In en, this message translates to:
  /// **'Widening Factor'**
  String get eqWideningFactor;

  /// No description provided for @eqLoudnessNormalization.
  ///
  /// In en, this message translates to:
  /// **'Loudness Normalization'**
  String get eqLoudnessNormalization;

  /// No description provided for @eqTargetLoudness.
  ///
  /// In en, this message translates to:
  /// **'Target Loudness'**
  String get eqTargetLoudness;

  /// No description provided for @eqToneShelving.
  ///
  /// In en, this message translates to:
  /// **'Tone Shelving (Bass / Treble)'**
  String get eqToneShelving;

  /// No description provided for @eqBassShelf.
  ///
  /// In en, this message translates to:
  /// **'Bass Shelf'**
  String get eqBassShelf;

  /// No description provided for @eqTrebleShelf.
  ///
  /// In en, this message translates to:
  /// **'Treble Shelf'**
  String get eqTrebleShelf;

  /// No description provided for @eqTempoPitchControls.
  ///
  /// In en, this message translates to:
  /// **'Tempo & Pitch Controls'**
  String get eqTempoPitchControls;

  /// No description provided for @eqPitchShift.
  ///
  /// In en, this message translates to:
  /// **'Pitch Shift'**
  String get eqPitchShift;

  /// No description provided for @eqTempoSpeed.
  ///
  /// In en, this message translates to:
  /// **'Tempo Speed'**
  String get eqTempoSpeed;

  /// No description provided for @eqVoiceSilenceControls.
  ///
  /// In en, this message translates to:
  /// **'Voice & Silence controls'**
  String get eqVoiceSilenceControls;

  /// No description provided for @eqSilenceTrimming.
  ///
  /// In en, this message translates to:
  /// **'Silence Trimming'**
  String get eqSilenceTrimming;

  /// No description provided for @eqSilenceThreshold.
  ///
  /// In en, this message translates to:
  /// **'Silence Threshold'**
  String get eqSilenceThreshold;

  /// No description provided for @eqSpeechEnhancementFilter.
  ///
  /// In en, this message translates to:
  /// **'Speech Enhancement Filter'**
  String get eqSpeechEnhancementFilter;

  /// No description provided for @eqHighpassCutoff.
  ///
  /// In en, this message translates to:
  /// **'Highpass Cutoff'**
  String get eqHighpassCutoff;

  /// No description provided for @eqLowpassCutoff.
  ///
  /// In en, this message translates to:
  /// **'Lowpass Cutoff'**
  String get eqLowpassCutoff;

  /// No description provided for @eqRetroRoomEffects.
  ///
  /// In en, this message translates to:
  /// **'Retro & Room Effects'**
  String get eqRetroRoomEffects;

  /// No description provided for @eqLofiEffect.
  ///
  /// In en, this message translates to:
  /// **'Lofi Effect (8-bit Crusher)'**
  String get eqLofiEffect;

  /// No description provided for @eqStudioRoomReverb.
  ///
  /// In en, this message translates to:
  /// **'Studio Room Reverb (Echo)'**
  String get eqStudioRoomReverb;

  /// No description provided for @eqVirtualSurround.
  ///
  /// In en, this message translates to:
  /// **'Virtual 5.1 Surround Sound'**
  String get eqVirtualSurround;

  /// No description provided for @eqRawFilterConsole.
  ///
  /// In en, this message translates to:
  /// **'Raw FFMpeg Filter console'**
  String get eqRawFilterConsole;

  /// No description provided for @eqSwitchToSliders.
  ///
  /// In en, this message translates to:
  /// **'Switch to Sliders'**
  String get eqSwitchToSliders;

  /// No description provided for @eqSwitchToGraph.
  ///
  /// In en, this message translates to:
  /// **'Switch to Graph'**
  String get eqSwitchToGraph;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @eqSongSpecificActive.
  ///
  /// In en, this message translates to:
  /// **'Song-specific settings active'**
  String get eqSongSpecificActive;

  /// No description provided for @eqUsingGlobalDefault.
  ///
  /// In en, this message translates to:
  /// **'Using global settings default'**
  String get eqUsingGlobalDefault;

  /// No description provided for @eqInteractiveGraphHint.
  ///
  /// In en, this message translates to:
  /// **'INTERACTIVE GRAPH (DRAG DOTS VERTICALLY)'**
  String get eqInteractiveGraphHint;

  /// No description provided for @eq18BandHint.
  ///
  /// In en, this message translates to:
  /// **'18-BAND EQUALIZER (SCROLL HORIZONTALLY)'**
  String get eq18BandHint;

  /// No description provided for @eqSongSpecific.
  ///
  /// In en, this message translates to:
  /// **'Song-Specific'**
  String get eqSongSpecific;

  /// No description provided for @eqGlobalDefault.
  ///
  /// In en, this message translates to:
  /// **'Global Default'**
  String get eqGlobalDefault;

  /// No description provided for @eqEditScopeNote.
  ///
  /// In en, this message translates to:
  /// **'Edits made when a song is playing apply to that song only. To set the global default, edit when no song is playing, or use the \'Apply to Global\' action.'**
  String get eqEditScopeNote;

  /// No description provided for @presetFlat.
  ///
  /// In en, this message translates to:
  /// **'Flat'**
  String get presetFlat;

  /// No description provided for @presetBassBooster.
  ///
  /// In en, this message translates to:
  /// **'Bass Booster'**
  String get presetBassBooster;

  /// No description provided for @presetTrebleBooster.
  ///
  /// In en, this message translates to:
  /// **'Treble Booster'**
  String get presetTrebleBooster;

  /// No description provided for @presetVocalBooster.
  ///
  /// In en, this message translates to:
  /// **'Vocal Booster'**
  String get presetVocalBooster;

  /// No description provided for @presetElectronic.
  ///
  /// In en, this message translates to:
  /// **'Electronic'**
  String get presetElectronic;

  /// No description provided for @presetRock.
  ///
  /// In en, this message translates to:
  /// **'Rock'**
  String get presetRock;

  /// No description provided for @presetPop.
  ///
  /// In en, this message translates to:
  /// **'Pop'**
  String get presetPop;

  /// No description provided for @presetJazz.
  ///
  /// In en, this message translates to:
  /// **'Jazz'**
  String get presetJazz;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @savePreset.
  ///
  /// In en, this message translates to:
  /// **'Save Preset'**
  String get savePreset;

  /// No description provided for @presetName.
  ///
  /// In en, this message translates to:
  /// **'Preset name'**
  String get presetName;

  /// No description provided for @deletePreset.
  ///
  /// In en, this message translates to:
  /// **'Delete Preset'**
  String get deletePreset;

  /// No description provided for @deletePresetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete the \"{name}\" preset?'**
  String deletePresetConfirm(String name);

  /// No description provided for @noLyricsSource.
  ///
  /// In en, this message translates to:
  /// **'No Lyrics Source'**
  String get noLyricsSource;

  /// No description provided for @lyricsSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String lyricsSourceLabel(String source);

  /// No description provided for @lyricsSourceLocalSidecar.
  ///
  /// In en, this message translates to:
  /// **'Local Sidecar (.lrc)'**
  String get lyricsSourceLocalSidecar;

  /// No description provided for @lyricsSourceCustomFile.
  ///
  /// In en, this message translates to:
  /// **'Custom LRC File'**
  String get lyricsSourceCustomFile;

  /// No description provided for @lyricsSourceNotFoundOnline.
  ///
  /// In en, this message translates to:
  /// **'Not Found Online'**
  String get lyricsSourceNotFoundOnline;

  /// No description provided for @lyricsProviderLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get lyricsProviderLocal;

  /// No description provided for @checkingLocalLyrics.
  ///
  /// In en, this message translates to:
  /// **'Checking local/embedded lyrics...'**
  String get checkingLocalLyrics;

  /// No description provided for @fetchingLyricsFrom.
  ///
  /// In en, this message translates to:
  /// **'Fetching lyrics from {provider}...'**
  String fetchingLyricsFrom(String provider);

  /// No description provided for @loadedLocalLyrics.
  ///
  /// In en, this message translates to:
  /// **'Loaded local/embedded lyrics!'**
  String get loadedLocalLyrics;

  /// No description provided for @noLocalLyricsFound.
  ///
  /// In en, this message translates to:
  /// **'No local or embedded lyrics found'**
  String get noLocalLyricsFound;

  /// No description provided for @lyricsUpdatedFrom.
  ///
  /// In en, this message translates to:
  /// **'Lyrics updated from {provider}!'**
  String lyricsUpdatedFrom(String provider);

  /// No description provided for @noLyricsFoundOn.
  ///
  /// In en, this message translates to:
  /// **'No lyrics found on {provider}'**
  String noLyricsFoundOn(String provider);

  /// No description provided for @gestureTips.
  ///
  /// In en, this message translates to:
  /// **'Gesture Tips'**
  String get gestureTips;

  /// No description provided for @gestureTipsDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap, long-press, pinch to zoom & more'**
  String get gestureTipsDesc;

  /// No description provided for @exportLyrics.
  ///
  /// In en, this message translates to:
  /// **'Export Lyrics'**
  String get exportLyrics;

  /// No description provided for @lyricsExportedTo.
  ///
  /// In en, this message translates to:
  /// **'Lyrics exported to: {path}'**
  String lyricsExportedTo(String path);

  /// No description provided for @failedToExportLyrics.
  ///
  /// In en, this message translates to:
  /// **'Failed to export lyrics: {error}'**
  String failedToExportLyrics(String error);

  /// No description provided for @gestureTapLine.
  ///
  /// In en, this message translates to:
  /// **'Tap a line'**
  String get gestureTapLine;

  /// No description provided for @gestureTapLineDesc.
  ///
  /// In en, this message translates to:
  /// **'Jump playback straight to that lyric.'**
  String get gestureTapLineDesc;

  /// No description provided for @gestureLongPressLine.
  ///
  /// In en, this message translates to:
  /// **'Long-press a line'**
  String get gestureLongPressLine;

  /// No description provided for @gestureLongPressLineDesc.
  ///
  /// In en, this message translates to:
  /// **'Start selecting lines to turn into a shareable lyrics card. Tap more lines to extend the selection.'**
  String get gestureLongPressLineDesc;

  /// No description provided for @gesturePinch.
  ///
  /// In en, this message translates to:
  /// **'Pinch with two fingers'**
  String get gesturePinch;

  /// No description provided for @gesturePinchDesc.
  ///
  /// In en, this message translates to:
  /// **'Resize the lyrics text to your liking.'**
  String get gesturePinchDesc;

  /// No description provided for @gestureSwipeDown.
  ///
  /// In en, this message translates to:
  /// **'Swipe down'**
  String get gestureSwipeDown;

  /// No description provided for @gestureSwipeDownDesc.
  ///
  /// In en, this message translates to:
  /// **'Close the lyrics screen and return to the player.'**
  String get gestureSwipeDownDesc;

  /// No description provided for @lyricsGestures.
  ///
  /// In en, this message translates to:
  /// **'Lyrics Gestures'**
  String get lyricsGestures;

  /// No description provided for @lyricsGesturesIntro.
  ///
  /// In en, this message translates to:
  /// **'A few things this screen can do that aren\'t always obvious:'**
  String get lyricsGesturesIntro;

  /// No description provided for @linesSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 line selected} other{{count} lines selected}}'**
  String linesSelected(int count);

  /// No description provided for @couldNotGenerateShareImage.
  ///
  /// In en, this message translates to:
  /// **'Could not generate the share image.'**
  String get couldNotGenerateShareImage;

  /// No description provided for @couldNotGenerateImage.
  ///
  /// In en, this message translates to:
  /// **'Could not generate the image.'**
  String get couldNotGenerateImage;

  /// No description provided for @savedToGallery.
  ///
  /// In en, this message translates to:
  /// **'Saved to gallery.'**
  String get savedToGallery;

  /// No description provided for @galleryPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission to access the gallery was denied.'**
  String get galleryPermissionDenied;

  /// No description provided for @couldNotSaveToGallery.
  ///
  /// In en, this message translates to:
  /// **'Could not save the image to the gallery.'**
  String get couldNotSaveToGallery;

  /// No description provided for @shareLyrics.
  ///
  /// In en, this message translates to:
  /// **'Share Lyrics'**
  String get shareLyrics;

  /// No description provided for @backgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Background Color'**
  String get backgroundColor;

  /// No description provided for @lyricsTextColor.
  ///
  /// In en, this message translates to:
  /// **'Lyrics Text Color'**
  String get lyricsTextColor;

  /// No description provided for @saveToGallery.
  ///
  /// In en, this message translates to:
  /// **'Save to Gallery'**
  String get saveToGallery;

  /// No description provided for @preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing...'**
  String get preparing;

  /// No description provided for @trackTitle.
  ///
  /// In en, this message translates to:
  /// **'Track Title'**
  String get trackTitle;

  /// No description provided for @composer.
  ///
  /// In en, this message translates to:
  /// **'Composer'**
  String get composer;

  /// No description provided for @unknownGenre.
  ///
  /// In en, this message translates to:
  /// **'Unknown Genre'**
  String get unknownGenre;

  /// No description provided for @releaseYear.
  ///
  /// In en, this message translates to:
  /// **'Release Year'**
  String get releaseYear;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @recordLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get recordLabel;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'Copyright'**
  String get copyright;

  /// No description provided for @encoder.
  ///
  /// In en, this message translates to:
  /// **'Encoder'**
  String get encoder;

  /// No description provided for @fileName.
  ///
  /// In en, this message translates to:
  /// **'File Name'**
  String get fileName;

  /// No description provided for @fileFormat.
  ///
  /// In en, this message translates to:
  /// **'File Format'**
  String get fileFormat;

  /// No description provided for @fileSize.
  ///
  /// In en, this message translates to:
  /// **'File Size'**
  String get fileSize;

  /// No description provided for @absolutePath.
  ///
  /// In en, this message translates to:
  /// **'Absolute Path'**
  String get absolutePath;

  /// No description provided for @playCount.
  ///
  /// In en, this message translates to:
  /// **'Play Count'**
  String get playCount;

  /// No description provided for @playCountTimes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 time} other{{count} times}}'**
  String playCountTimes(int count);

  /// No description provided for @lastPlayed.
  ///
  /// In en, this message translates to:
  /// **'Last Played'**
  String get lastPlayed;

  /// No description provided for @filePath.
  ///
  /// In en, this message translates to:
  /// **'File Path'**
  String get filePath;

  /// No description provided for @rescan.
  ///
  /// In en, this message translates to:
  /// **'Rescan'**
  String get rescan;

  /// No description provided for @codec.
  ///
  /// In en, this message translates to:
  /// **'Codec'**
  String get codec;

  /// No description provided for @container.
  ///
  /// In en, this message translates to:
  /// **'Container'**
  String get container;

  /// No description provided for @sampleRate.
  ///
  /// In en, this message translates to:
  /// **'Sample Rate'**
  String get sampleRate;

  /// No description provided for @bitDepth.
  ///
  /// In en, this message translates to:
  /// **'Bit Depth'**
  String get bitDepth;

  /// No description provided for @decodedFormat.
  ///
  /// In en, this message translates to:
  /// **'Decoded Format'**
  String get decodedFormat;

  /// No description provided for @bitrate.
  ///
  /// In en, this message translates to:
  /// **'Bitrate'**
  String get bitrate;

  /// No description provided for @channels.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get channels;

  /// No description provided for @nyquist.
  ///
  /// In en, this message translates to:
  /// **'Nyquist'**
  String get nyquist;

  /// No description provided for @dynamicRange.
  ///
  /// In en, this message translates to:
  /// **'Dynamic Range'**
  String get dynamicRange;

  /// No description provided for @peak.
  ///
  /// In en, this message translates to:
  /// **'Peak'**
  String get peak;

  /// No description provided for @truePeak.
  ///
  /// In en, this message translates to:
  /// **'True Peak'**
  String get truePeak;

  /// No description provided for @clipping.
  ///
  /// In en, this message translates to:
  /// **'Clipping'**
  String get clipping;

  /// No description provided for @cutoff.
  ///
  /// In en, this message translates to:
  /// **'Cutoff'**
  String get cutoff;

  /// No description provided for @samples.
  ///
  /// In en, this message translates to:
  /// **'Samples'**
  String get samples;

  /// No description provided for @channelShort.
  ///
  /// In en, this message translates to:
  /// **'Ch {channel}'**
  String channelShort(int channel);

  /// No description provided for @noneClean.
  ///
  /// In en, this message translates to:
  /// **'None (Clean)'**
  String get noneClean;

  /// No description provided for @reanalyzingAudio.
  ///
  /// In en, this message translates to:
  /// **'Re-analyzing audio stream...'**
  String get reanalyzingAudio;

  /// No description provided for @analyzingAudio.
  ///
  /// In en, this message translates to:
  /// **'Analyzing audio stream...'**
  String get analyzingAudio;

  /// No description provided for @sampleRateHz.
  ///
  /// In en, this message translates to:
  /// **'Sample Rate: {rate} Hz'**
  String sampleRateHz(int rate);

  /// No description provided for @nyquistKhz.
  ///
  /// In en, this message translates to:
  /// **'Nyquist: {khz} kHz'**
  String nyquistKhz(String khz);

  /// No description provided for @qualityLossless.
  ///
  /// In en, this message translates to:
  /// **'Lossless'**
  String get qualityLossless;

  /// No description provided for @qualityHigh.
  ///
  /// In en, this message translates to:
  /// **'High Quality'**
  String get qualityHigh;

  /// No description provided for @qualityStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard Quality'**
  String get qualityStandard;

  /// No description provided for @qualityAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get qualityAudio;

  /// No description provided for @addCustomFolder.
  ///
  /// In en, this message translates to:
  /// **'Add a Custom Folder'**
  String get addCustomFolder;

  /// No description provided for @addCustomFolderDesc.
  ///
  /// In en, this message translates to:
  /// **'If your music lives in a folder with a different name, or on an SD card, add it directly.'**
  String get addCustomFolderDesc;

  /// No description provided for @indexingYourLibrary.
  ///
  /// In en, this message translates to:
  /// **'INDEXING YOUR LIBRARY...'**
  String get indexingYourLibrary;

  /// No description provided for @indexingYourLibraryDesc.
  ///
  /// In en, this message translates to:
  /// **'Filling in titles, artwork and lyrics for your songs.'**
  String get indexingYourLibraryDesc;

  /// No description provided for @welcomeStep.
  ///
  /// In en, this message translates to:
  /// **'STEP {step}: {title}'**
  String welcomeStep(String step, String title);

  /// No description provided for @includeOtherDeviceAudioAlarmsDesc.
  ///
  /// In en, this message translates to:
  /// **'Ringtones, notifications, alarms and messaging audio'**
  String get includeOtherDeviceAudioAlarmsDesc;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @noIndexedFoldersDesktopDesc.
  ///
  /// In en, this message translates to:
  /// **'Use Rescan Library to discover storage folders'**
  String get noIndexedFoldersDesktopDesc;

  /// No description provided for @playedLabel.
  ///
  /// In en, this message translates to:
  /// **'Played'**
  String get playedLabel;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Min} other{{count} Mins}}'**
  String minutesShort(int count);

  /// No description provided for @minuteChip.
  ///
  /// In en, this message translates to:
  /// **'{count} Min'**
  String minuteChip(int count);

  /// No description provided for @songsCountTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Song} other{{count} Songs}}'**
  String songsCountTitle(int count);

  /// No description provided for @songsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song left} other{{count} songs left}}'**
  String songsLeft(int count);

  /// No description provided for @sleepTimerWithRemaining.
  ///
  /// In en, this message translates to:
  /// **'Sleep Timer ({remaining})'**
  String sleepTimerWithRemaining(String remaining);

  /// No description provided for @trackInfoSection.
  ///
  /// In en, this message translates to:
  /// **'TRACK INFO'**
  String get trackInfoSection;

  /// No description provided for @detailsSection.
  ///
  /// In en, this message translates to:
  /// **'DETAILS'**
  String get detailsSection;

  /// No description provided for @lyricsSection.
  ///
  /// In en, this message translates to:
  /// **'LYRICS'**
  String get lyricsSection;

  /// No description provided for @editLyricsHint.
  ///
  /// In en, this message translates to:
  /// **'Enter plain lyrics or synchronized LRC lyrics format [00:00.00]...'**
  String get editLyricsHint;

  /// No description provided for @addedSongsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Added 1 song} other{Added {count} songs}}'**
  String addedSongsCount(int count);

  /// No description provided for @chooseInternalStorageFolder.
  ///
  /// In en, this message translates to:
  /// **'Please choose a folder on this device\'s internal storage or SD card.'**
  String get chooseInternalStorageFolder;

  /// No description provided for @appCrashedTitle.
  ///
  /// In en, this message translates to:
  /// **'Looper Player Crashed'**
  String get appCrashedTitle;

  /// No description provided for @appCrashedDesc.
  ///
  /// In en, this message translates to:
  /// **'An unexpected initialization error occurred. A diagnostic crash report has been generated.'**
  String get appCrashedDesc;

  /// No description provided for @appCrashedDetails.
  ///
  /// In en, this message translates to:
  /// **'An error occurred during app database or service initialization. This can happen if storage access is restricted or database files are corrupted.'**
  String get appCrashedDetails;

  /// No description provided for @crashReportSaved.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic crash report saved to application support folder.'**
  String get crashReportSaved;

  /// No description provided for @shareLog.
  ///
  /// In en, this message translates to:
  /// **'Share Log'**
  String get shareLog;

  /// No description provided for @restartApp.
  ///
  /// In en, this message translates to:
  /// **'Restart App'**
  String get restartApp;

  /// No description provided for @updateAvailableOnPlay.
  ///
  /// In en, this message translates to:
  /// **'A new version is available on Google Play.'**
  String get updateAvailableOnPlay;

  /// No description provided for @updateAvailableOnGithub.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is available on GitHub.'**
  String updateAvailableOnGithub(String version);

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailable;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Available!'**
  String get updateAvailableTitle;

  /// No description provided for @visit.
  ///
  /// In en, this message translates to:
  /// **'VISIT'**
  String get visit;

  /// No description provided for @updateDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Update downloaded'**
  String get updateDownloaded;

  /// No description provided for @restartToInstallUpdate.
  ///
  /// In en, this message translates to:
  /// **'Restart Looper Player to install it.'**
  String get restartToInstallUpdate;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'RESTART'**
  String get restart;

  /// No description provided for @backupImportedSummary.
  ///
  /// In en, this message translates to:
  /// **'Backup imported: Merged {favorites} favorites, {stats} play stats, synced {playlists} playlists'**
  String backupImportedSummary(int favorites, int stats, int playlists);

  /// No description provided for @backupExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to export backup: An internal error occurred while saving the backup file.'**
  String get backupExportFailed;

  /// No description provided for @backupImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to import backup: The file could not be read or the backup format is invalid.'**
  String get backupImportFailed;

  /// No description provided for @stereo.
  ///
  /// In en, this message translates to:
  /// **'Stereo'**
  String get stereo;

  /// No description provided for @mono.
  ///
  /// In en, this message translates to:
  /// **'Mono'**
  String get mono;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'it',
    'ja',
    'ko',
    'nl',
    'pt',
    'ru',
    'tr',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'nl':
      return AppLocalizationsNl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
