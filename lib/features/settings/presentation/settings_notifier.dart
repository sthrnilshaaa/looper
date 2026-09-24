import 'dart:io';
import 'package:isar_community/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/db_service.dart';
import '../../library/domain/models/models.dart';

import '../../library/data/artwork_downloader_service.dart';
import '../../../core/app_fonts.dart';

part 'settings_notifier.g.dart';

@Riverpod(keepAlive: true)
class Settings extends _$Settings {
  late Future<void> initialization;

  @override
  AppSettings build() {
    initialization = _loadSettings();
    return AppSettings();
  }

  List<double> _createDefaultGains() {
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

  Future<void> _loadSettings() async {
    final settings = await DbService.isar.appSettings.get(0);
    if (settings != null) {
      bool needsSave = false;
      // Recover folder settings from an existing library after older scans
      // cleared or failed to persist the folder list.
      if (settings.libraryFolders.isEmpty) {
        final indexedSongs = await DbService.isar.songs.where().findAll();
        final recoveredFolders =
            indexedSongs
                .map((song) => File(song.path).parent.path)
                .where((path) => Directory(path).existsSync())
                .toSet()
                .toList()
              ..sort();
        if (recoveredFolders.isNotEmpty) {
          settings.libraryFolders = recoveredFolders;
          needsSave = true;
        }
      }
      // Only run legacy defaults migration ONCE if settingsV3 is not yet set
      if (!settings.settingsV3) {
        if (settings.bgBrightness == 0.0) {
          settings.bgBrightness = 0.5;
        }
        if (settings.bgOpacity == 0.0) {
          settings.bgOpacity = 0.3;
        }
        if (!settings.showHomeArtists &&
            !settings.showHomeAlbums &&
            !settings.showHomeGenres) {
          settings.showHomeArtists = true;
          settings.showHomeAlbums = false;
          settings.showHomeGenres = true;
        }
        if (settings.homeDarkness.isNaN || settings.homeDarkness == 0.0) {
          settings.homeDarkness = 0.72;
        }
        if (settings.songsDarkness.isNaN || settings.songsDarkness == 0.0) {
          settings.songsDarkness = 0.72;
        }
        if (settings.libraryDarkness.isNaN || settings.libraryDarkness == 0.0) {
          settings.libraryDarkness = 0.72;
        }
        if (settings.musicDarkness.isNaN || settings.musicDarkness == 0.0) {
          settings.musicDarkness = 0.62;
        }
        if (settings.lyricsDarkness.isNaN || settings.lyricsDarkness == 0.0) {
          settings.lyricsDarkness = 0.55;
        }
        settings.showQualityBadge = true;
        settings.enablePlayerGradient = true;
        settings.settingsV2 = true;
        settings.dynamicLyrics = false;
        settings.blurredArtworkForLyrics = true;
        settings.settingsV3 = true;
        needsSave = true;
      }
      if (settings.homeSectionOrder.isEmpty) {
        settings.homeSectionOrder = [
          'quick_picks',
          'songs',
          'albums',
          'artists',
          'genres',
          'recent',
        ];
        needsSave = true;
      } else if (!settings.homeSectionOrder.contains('recent')) {
        // Migration: append the newly added Recent section to existing
        // custom orderings instead of resetting the user's preference.
        settings.homeSectionOrder = [...settings.homeSectionOrder, 'recent'];
        needsSave = true;
      }
      if (settings.globalEqualizerGains.length < 48) {
        settings.globalEqualizerGains = _createDefaultGains();
        needsSave = true;
      }
      if (needsSave) {
        await DbService.isar.writeTxn(() async {
          await DbService.isar.appSettings.put(settings);
        });
      }
      state = settings;
    } else {
      // Initialize default settings
      // Default to off on Android, but enabled on Linux
      final defaultSettings = AppSettings()
        ..enableDynamicTheming = !Platform.isAndroid
        ..bgBrightness = 0.5
        ..bgOpacity = 0.3
        ..showHomeArtists = true
        ..showHomeAlbums = false
        ..showHomeGenres = true
        ..showHomeRecent = true
        ..homeSectionOrder = [
          'quick_picks',
          'songs',
          'albums',
          'artists',
          'genres',
          'recent',
        ]
        ..homeDarkness = 0.72
        ..songsDarkness = 0.72
        ..libraryDarkness = 0.72
        ..musicDarkness = 0.62
        ..lyricsDarkness = 0.55
        ..showQualityBadge = true
        ..enablePlayerGradient = true
        ..settingsV2 = true
        ..settingsV3 = true
        ..dynamicLyrics = false
        ..blurredArtworkForLyrics = true
        ..showPerformanceOptimizer = false
        ..equalizerEnabled = false
        ..enableAudioCache = true
        ..audioCacheSizeMB = 200
        ..audioCacheSecs = 120
        ..audioBackCacheSizeMB = 100
        ..persistQueue = false
        ..globalEqualizerGains = _createDefaultGains();
      await DbService.isar.writeTxn(() async {
        await DbService.isar.appSettings.put(defaultSettings);
      });
      state = defaultSettings;
    }

    _updateActiveFont();

    if (state.downloadArtwork && state.enableInternet) {
      ArtworkDownloaderService().downloadAllMissingArtworks();
    }
  }

  void _updateActiveFont([AppSettings? customState]) {
    final activeState = customState ?? state;
    AppFonts.activeFontFamily = activeState.useNewFont
        ? (activeState.customFontFamily ?? 'Jost')
        : 'DM Sans';
    AppFonts.appFontWeightDelta = activeState.useNewFont
        ? activeState.customFontWeightDelta
        : 0;
    AppFonts.lyricsFontWeightDelta = activeState.useNewFontLyrics
        ? activeState.customFontWeightLyricsDelta
        : 0;
  }

  /// Clones [state], applies [mutate] to the clone, persists it, and makes
  /// it the new state - the one "clone -> mutate -> Isar writeTxn -> state ="
  /// sequence every `updateX` method below used to repeat by hand (~90
  /// times, in two slightly different inline forms). [mutate] returns the
  /// same clone it's given so call sites can use a cascade (`s..field =
  /// value`) directly.
  Future<void> _update(AppSettings Function(AppSettings clone) mutate) async {
    final newState = mutate(_clone(state));
    await DbService.isar.writeTxn(() async {
      await DbService.isar.appSettings.put(newState);
    });
    state = newState;
  }

  /// Field-by-field copy of [AppSettings] - every field must be listed here
  /// explicitly. Isar model objects aren't immutable/copyWith-friendly, so
  /// this is what makes [_update] able to mutate a clone without touching
  /// the live [state] object until the write succeeds. If a new field is
  /// added to [AppSettings] and forgotten here, updates silently drop it -
  /// the settings screens are the fastest way to notice (a new toggle that
  /// never seems to persist).
  AppSettings _clone(AppSettings s) {
    return AppSettings()
      ..id = s.id
      ..libraryFolders = List.from(s.libraryFolders)
      ..lastPlayedSongId = s.lastPlayedSongId
      ..lastQueueSongIds = List.from(s.lastQueueSongIds)
      ..lastQueueIndex = s.lastQueueIndex
      ..volume = s.volume
      ..lastPositionMs = s.lastPositionMs
      ..shuffle = s.shuffle
      ..repeatMode = s.repeatMode
      ..language = s.language
      ..enableDynamicTheming = s.enableDynamicTheming
      ..darkTheme = s.darkTheme
      ..saveDynamicColor = s.saveDynamicColor
      ..dynamicLyrics = s.dynamicLyrics
      ..accentColor = s.accentColor
      ..audioFocus = s.audioFocus
      ..audioFocusRequestOnPlay = s.audioFocusRequestOnPlay
      ..audioFocusReleaseOnPause = s.audioFocusReleaseOnPause
      ..audioFocusStopOnOtherSession = s.audioFocusStopOnOtherSession
      ..audioFocusRestartOnGain = s.audioFocusRestartOnGain
      ..disableSquiggle = s.disableSquiggle
      ..disableAnimatedDuration = s.disableAnimatedDuration
      ..disableBlur = s.disableBlur
      ..alwaysBlurSheets = s.alwaysBlurSheets
      ..enableInternet = s.enableInternet
      ..downloadArtwork = s.downloadArtwork
      ..includeSystemAndMessagingAudio = s.includeSystemAndMessagingAudio
      ..keepBackgroundGradient = s.keepBackgroundGradient
      ..showQualityBadge = s.showQualityBadge
      ..enablePlayerGradient = s.enablePlayerGradient
      ..settingsV2 = s.settingsV2
      ..settingsV3 = s.settingsV3
      ..blurredArtworkForLyrics = s.blurredArtworkForLyrics
      ..customBackgroundImagePath = s.customBackgroundImagePath
      ..bgBrightness = s.bgBrightness
      ..bgOpacity = s.bgOpacity
      ..showHomeArtists = s.showHomeArtists
      ..showHomeAlbums = s.showHomeAlbums
      ..showHomeGenres = s.showHomeGenres
      ..showHomeRecent = s.showHomeRecent
      ..homeSectionOrder = List.from(
        s.homeSectionOrder.isEmpty
            ? ['quick_picks', 'songs', 'albums', 'artists', 'genres', 'recent']
            : s.homeSectionOrder,
      )
      ..enableSlideGesture = s.enableSlideGesture
      ..stopOnTaskRemoved = s.stopOnTaskRemoved
      ..persistQueue = s.persistQueue
      ..keepSongProgress = s.keepSongProgress
      ..fadePlayPauseStop = s.fadePlayPauseStop
      ..playPauseStopFadeLength = s.playPauseStopFadeLength
      ..resumeAfterCall = s.resumeAfterCall
      ..pauseOnDuck = s.pauseOnDuck
      ..resumeOnBluetoothConnect = s.resumeOnBluetoothConnect
      ..resumeOnStart = s.resumeOnStart
      ..permanentAudioFocusChange = s.permanentAudioFocusChange
      ..dynamicColorActiveLyrics = s.dynamicColorActiveLyrics
      ..ambientColorBackground = s.ambientColorBackground
      ..lyricsAlignment = s.lyricsAlignment
      ..dynamicAccentColor = s.dynamicAccentColor
      ..sortStrategyIndex = s.sortStrategyIndex
      ..sortAscending = s.sortAscending
      ..albumSortOptionIndex = s.albumSortOptionIndex
      ..artistSortOptionIndex = s.artistSortOptionIndex
      ..genreSortOptionIndex = s.genreSortOptionIndex
      ..collectionSortOptionIndex = s.collectionSortOptionIndex
      ..homeDarkness = s.homeDarkness
      ..songsDarkness = s.songsDarkness
      ..libraryDarkness = s.libraryDarkness
      ..musicDarkness = s.musicDarkness
      ..lyricsDarkness = s.lyricsDarkness
      ..selectedAvatarAsset = s.selectedAvatarAsset
      ..avatarDynamicColor = s.avatarDynamicColor
      ..showPerformanceOptimizer = s.showPerformanceOptimizer
      ..useNewFont = s.useNewFont
      ..customFontFamily = s.customFontFamily
      ..customFontWeight = s.customFontWeight
      ..customFontWeightDelta = s.customFontWeightDelta
      ..useNewFontLyrics = s.useNewFontLyrics
      ..customFontFamilyLyrics = s.customFontFamilyLyrics
      ..customFontWeightLyrics = s.customFontWeightLyrics
      ..customFontWeightLyricsDelta = s.customFontWeightLyricsDelta
      ..activeLyricsFontWeightDelta = s.activeLyricsFontWeightDelta
      ..equalizerEnabled = s.equalizerEnabled
      ..globalEqualizerGains = List.from(
        s.globalEqualizerGains.isEmpty
            ? _createDefaultGains()
            : s.globalEqualizerGains,
      )
      ..enableAudioCache = s.enableAudioCache
      ..audioCacheSizeMB = s.audioCacheSizeMB
      ..audioCacheSecs = s.audioCacheSecs
      ..audioBackCacheSizeMB = s.audioBackCacheSizeMB
      ..exclusiveHardwareMode = s.exclusiveHardwareMode
      ..lyricsProvider = s.lyricsProvider
      ..autoLyricsFallback = s.autoLyricsFallback
      ..equalizerGlobalMode = s.equalizerGlobalMode
      ..firstTimeEqualizer = s.firstTimeEqualizer
      ..lyricsGestureTutorialSeen = s.lyricsGestureTutorialSeen;
  }

  Future<void> updateLibraryFolders(List<String> folders) =>
      _update((s) => s..libraryFolders = folders);

  Future<void> updateLanguage(String lang) =>
      _update((s) => s..language = lang);

  Future<void> updateShuffle(bool shuffle) =>
      _update((s) => s..shuffle = shuffle);

  Future<void> updateRepeatMode(int mode) =>
      _update((s) => s..repeatMode = mode);

  Future<void> updateHomeSectionOrder(List<String> newOrder) =>
      _update((s) => s..homeSectionOrder = newOrder);

  Future<void> updateIncludeSystemAndMessagingAudio(bool value) =>
      _update((s) => s..includeSystemAndMessagingAudio = value);

  Future<void> updateLyricsProvider(String value) =>
      _update((s) => s..lyricsProvider = value);

  Future<void> updateAutoLyricsFallback(bool value) =>
      _update((s) => s..autoLyricsFallback = value);

  Future<void> updateBlurredArtworkForLyrics(bool value) =>
      _update((s) => s..blurredArtworkForLyrics = value);

  Future<void> updateAmbientColorBackground(bool value) =>
      _update((s) => s..ambientColorBackground = value);

  Future<void> updateShowQualityBadge(bool value) =>
      _update((s) => s..showQualityBadge = value);

  Future<void> updateShowPerformanceOptimizer(bool value) =>
      _update((s) => s..showPerformanceOptimizer = value);

  Future<void> updateEnablePlayerGradient(bool value) => _update((s) {
    s.enablePlayerGradient = value;
    if (!value) {
      s.keepBackgroundGradient = false;
    }
    return s;
  });

  Future<void> updateEnableSlideGesture(bool value) =>
      _update((s) => s..enableSlideGesture = value);

  Future<void> updateStopOnTaskRemoved(bool value) =>
      _update((s) => s..stopOnTaskRemoved = value);

  Future<void> updateFadePlayPauseStop(bool value) =>
      _update((s) => s..fadePlayPauseStop = value);

  Future<void> updatePlayPauseStopFadeLength(int value) =>
      _update((s) => s..playPauseStopFadeLength = value);

  Future<void> updateResumeAfterCall(bool value) =>
      _update((s) => s..resumeAfterCall = value);

  Future<void> updatePauseOnDuck(bool value) =>
      _update((s) => s..pauseOnDuck = value);

  Future<void> updateResumeOnBluetoothConnect(bool value) =>
      _update((s) => s..resumeOnBluetoothConnect = value);

  Future<void> updateResumeOnStart(bool value) =>
      _update((s) => s..resumeOnStart = value);

  Future<void> updatePersistQueue(bool value) => _update((s) {
    s.persistQueue = value;
    if (!value) {
      s.lastQueueSongIds = [];
      s.lastQueueIndex = -1;
      s.lastPlayedSongId = null;
      s.lastPositionMs = 0;
    }
    return s;
  });

  Future<void> updatePermanentAudioFocusChange(bool value) =>
      _update((s) => s..permanentAudioFocusChange = value);

  Future<void> updateDownloadArtwork(bool enabled) async {
    await _update((s) => s..downloadArtwork = enabled);

    if (enabled && state.enableInternet) {
      // Trigger full async scan to download all missing artworks
      ArtworkDownloaderService().downloadAllMissingArtworks();
    }
  }

  Future<void> updateKeepBackgroundGradient(bool value) =>
      _update((s) => s..keepBackgroundGradient = value);

  Future<void> updateCustomBackgroundImagePath(String? path) =>
      _update((s) => s..customBackgroundImagePath = path);

  Future<void> updateBgBrightness(double value) =>
      _update((s) => s..bgBrightness = value);

  Future<void> updateBgOpacity(double value) =>
      _update((s) => s..bgOpacity = value);

  Future<void> updateShowHomeArtists(bool value) =>
      _update((s) => s..showHomeArtists = value);

  Future<void> updateShowHomeAlbums(bool value) =>
      _update((s) => s..showHomeAlbums = value);

  Future<void> updateShowHomeGenres(bool value) =>
      _update((s) => s..showHomeGenres = value);

  Future<void> updateShowHomeRecent(bool value) =>
      _update((s) => s..showHomeRecent = value);

  Future<void> updateDisableSquiggle(bool disabled) =>
      _update((s) => s..disableSquiggle = disabled);

  Future<void> updateDisableAnimatedDuration(bool disabled) =>
      _update((s) => s..disableAnimatedDuration = disabled);

  Future<void> updateDisableBlur(bool disabled) =>
      _update((s) => s..disableBlur = disabled);

  Future<void> updateKeepSongProgress(bool value) =>
      _update((s) => s..keepSongProgress = value);

  Future<void> updateAlwaysBlurSheets(bool value) =>
      _update((s) => s..alwaysBlurSheets = value);

  Future<void> updateEnableInternet(bool enabled) =>
      _update((s) => s..enableInternet = enabled);

  Future<void> updateAudioFocus(bool enabled) =>
      _update((s) => s..audioFocus = enabled);

  Future<void> updateAudioFocusRequestOnPlay(bool enabled) =>
      _update((s) => s..audioFocusRequestOnPlay = enabled);

  Future<void> updateAudioFocusReleaseOnPause(bool enabled) =>
      _update((s) => s..audioFocusReleaseOnPause = enabled);

  Future<void> updateAudioFocusStopOnOtherSession(bool enabled) =>
      _update((s) => s..audioFocusStopOnOtherSession = enabled);

  Future<void> updateAudioFocusRestartOnGain(bool enabled) =>
      _update((s) => s..audioFocusRestartOnGain = enabled);

  Future<void> updateDynamicTheming(bool enabled) => _update((s) {
    s.enableDynamicTheming = enabled;
    if (!enabled) {
      // If dynamic theming is disabled, ensure accent color resets to default Green (0xFF41C25E)
      // if the current color is not one of the manual selection options.
      const allowedColors = [
        0xFF41C25E,
        0xFFF7EAA6,
        0xFF448AFF,
      ]; // Green, Yellow, Blue Accent
      if (!allowedColors.contains(s.accentColor)) {
        s.accentColor = 0xFF41C25E;
      }
    }
    return s;
  });

  Future<void> updateDarkTheme(bool enabled) =>
      _update((s) => s..darkTheme = enabled);

  Future<void> updateDynamicLyrics(bool enabled) =>
      _update((s) => s..dynamicLyrics = enabled);

  Future<void> updateAccentColor(int color) =>
      _update((s) => s..accentColor = color);

  Future<void> updateSaveDynamicColor(bool enabled) =>
      _update((s) => s..saveDynamicColor = enabled);

  Future<void> updateLastPlayedSong(int? songId) =>
      _update((s) => s..lastPlayedSongId = songId);

  Future<void> updateLastQueueState(
    List<int> queueIds,
    int index,
    int? lastSongId, {
    int? positionMs,
  }) => _update(
    (s) => s
      ..lastQueueSongIds = queueIds
      ..lastQueueIndex = index
      ..lastPlayedSongId = lastSongId
      ..lastPositionMs = positionMs ?? 0,
  );

  Future<void> updateLastPosition(int positionMs) =>
      _update((s) => s..lastPositionMs = positionMs);

  Future<void> updateVolume(double volume) =>
      _update((s) => s..volume = volume);

  Future<void> updateDynamicColorActiveLyrics(bool enabled) =>
      _update((s) => s..dynamicColorActiveLyrics = enabled);

  Future<void> updateLyricsAlignment(String alignment) =>
      _update((s) => s..lyricsAlignment = alignment);

  Future<void> updateDynamicAccentColor(bool enabled) =>
      _update((s) => s..dynamicAccentColor = enabled);

  Future<void> updateSortStrategy(int strategyIndex) =>
      _update((s) => s..sortStrategyIndex = strategyIndex);

  Future<void> updateSortAscending(bool ascending) =>
      _update((s) => s..sortAscending = ascending);

  Future<void> updateAlbumSortOptionIndex(int index) =>
      _update((s) => s..albumSortOptionIndex = index);

  Future<void> updateArtistSortOptionIndex(int index) =>
      _update((s) => s..artistSortOptionIndex = index);

  Future<void> updateGenreSortOptionIndex(int index) =>
      _update((s) => s..genreSortOptionIndex = index);

  Future<void> updateCollectionSortOptionIndex(int index) =>
      _update((s) => s..collectionSortOptionIndex = index);

  Future<void> updateHomeDarkness(double value) =>
      _update((s) => s..homeDarkness = value);

  Future<void> updateSongsDarkness(double value) =>
      _update((s) => s..songsDarkness = value);

  Future<void> updateLibraryDarkness(double value) =>
      _update((s) => s..libraryDarkness = value);

  Future<void> updateMusicDarkness(double value) =>
      _update((s) => s..musicDarkness = value);

  Future<void> updateLyricsDarkness(double value) =>
      _update((s) => s..lyricsDarkness = value);

  Future<void> updateSelectedAvatar(String assetFileName) =>
      _update((s) => s..selectedAvatarAsset = assetFileName);

  Future<void> updateAvatarDynamicColor(bool value) =>
      _update((s) => s..avatarDynamicColor = value);

  Future<void> updateUseNewFont(bool value) async {
    await _update((s) => s..useNewFont = value);
    _updateActiveFont();
  }

  Future<void> updateCustomFontFamily(String value) async {
    await _update((s) => s..customFontFamily = value);
    _updateActiveFont();
  }

  Future<void> updateCustomFontWeight(int value) async {
    await _update((s) => s..customFontWeight = value);
    _updateActiveFont();
  }

  Future<void> updateCustomFontWeightDelta(int value) async {
    await _update((s) => s..customFontWeightDelta = value);
    _updateActiveFont();
  }

  Future<void> updateUseNewFontLyrics(bool value) async {
    await _update((s) => s..useNewFontLyrics = value);
    _updateActiveFont();
  }

  Future<void> updateCustomFontFamilyLyrics(String value) async {
    await _update((s) => s..customFontFamilyLyrics = value);
    _updateActiveFont();
  }

  Future<void> updateCustomFontWeightLyrics(String value) async {
    await _update((s) => s..customFontWeightLyrics = value);
    _updateActiveFont();
  }

  Future<void> updateCustomFontWeightLyricsDelta(int value) async {
    await _update((s) => s..customFontWeightLyricsDelta = value);
    _updateActiveFont();
  }

  Future<void> updateActiveLyricsFontWeightDelta(int value) async {
    await _update((s) => s..activeLyricsFontWeightDelta = value);
    _updateActiveFont();
  }

  Future<void> updateEqualizerEnabled(bool value) =>
      _update((s) => s..equalizerEnabled = value);

  Future<void> updateGlobalEqualizerGains(List<double> value) =>
      _update((s) => s..globalEqualizerGains = value);

  Future<void> updateEnableAudioCache(bool value) =>
      _update((s) => s..enableAudioCache = value);

  Future<void> updateAudioCacheSizeMB(int value) =>
      _update((s) => s..audioCacheSizeMB = value);

  Future<void> updateAudioCacheSecs(int value) =>
      _update((s) => s..audioCacheSecs = value);

  Future<void> updateAudioBackCacheSizeMB(int value) =>
      _update((s) => s..audioBackCacheSizeMB = value);

  Future<void> updateExclusiveHardwareMode(bool value) =>
      _update((s) => s..exclusiveHardwareMode = value);

  Future<void> updateEqualizerGlobalMode(bool value) =>
      _update((s) => s..equalizerGlobalMode = value);

  Future<void> updateFirstTimeEqualizer(bool value) =>
      _update((s) => s..firstTimeEqualizer = value);

  Future<void> updateLyricsGestureTutorialSeen(bool value) =>
      _update((s) => s..lyricsGestureTutorialSeen = value);
}
