part of 'settings_view.dart';

extension _SettingsSearch on _SettingsViewState {
  Widget _buildSearchResults(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
    AppLocalizations l10n,
  ) {
    final query = _searchController.text.toLowerCase();
    final allSearchItems = _getSearchItems(context, ref, settings, l10n);
    final filteredItems = allSearchItems.where((item) {
      return item.title.toLowerCase().contains(query) ||
          item.subtitle.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
    }).toList();

    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.search, size: 48, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              l10n.typeToSearchSettings,
              style: AppFonts.jostStyle(
                color: Colors.white38,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.alertCircle,
              size: 48,
              color: Colors.white24,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noSettingsFoundFor(query),
              style: AppFonts.jostStyle(
                color: Colors.white38,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      physics: const BouncingScrollPhysics(),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        final useBlur = settings.enableDynamicTheming && !settings.disableBlur;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: PremiumSection(
            useBlur: useBlur,
            forceNoBlur: true,
            borderRadius: BorderRadius.circular(16),
            useExpanded: false,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    top: 8.0,
                    bottom: 4.0,
                  ),
                  child: Text(
                    item.category.toUpperCase(),
                    style: AppFonts.jostStyle(
                      color: Color(settings.accentColor).withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                item.widget,
              ],
            ),
          ),
        );
      },
    );
  }

  List<SettingsSearchItem> _getSearchItems(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
    AppLocalizations l10n,
  ) {
    return [
      // Theme
      SettingsSearchItem(
        title: l10n.dynamicTheming,
        subtitle: l10n.adaptColorsArtwork,
        category: l10n.theme,
        widget: const DynamicThemingTile(),
      ),
      SettingsSearchItem(
        title: l10n.selectAvatars,
        subtitle: l10n.selectAvatarsDesc,
        category: l10n.theme,
        widget: const SelectAvatarsTile(),
      ),
      if (settings.enableDynamicTheming)
        SettingsSearchItem(
          title: l10n.disableBlurEffects,
          subtitle: l10n.turnOffBlursOptimize,
          category: l10n.theme,
          widget: const DisableBlurTile(),
        ),
      if (!settings.enableDynamicTheming) ...[
        SettingsSearchItem(
          title: l10n.dynamicAccentColor,
          subtitle: l10n.dynamicAccentColorDesc,
          category: l10n.theme,
          widget: const DynamicAccentColorTile(),
        ),
        SettingsSearchItem(
          title: l10n.pureBlackOled,
          subtitle: l10n.useAbsoluteBlackBg,
          category: l10n.theme,
          widget: const PureBlackOledTile(),
        ),
        SettingsSearchItem(
          title: l10n.alwaysBlurSheets,
          subtitle: l10n.alwaysBlurSheetsDesc,
          category: l10n.theme,
          widget: const AlwaysBlurSheetsTile(),
        ),
        if (!settings.dynamicAccentColor) ...[
          SettingsSearchItem(
            title: l10n.accentColor,
            subtitle: l10n.chooseQuickAccentColors,
            category: l10n.theme,
            widget: const AccentColorTile(),
          ),
          SettingsSearchItem(
            title: l10n.customAccentColor,
            subtitle: l10n.selectCustomColor,
            category: l10n.theme,
            widget: const CustomAccentColorTile(),
          ),
        ],
      ],
      //if (!settings.enableDynamicTheming)
      SettingsSearchItem(
        title: l10n.ambientColorBackground,
        subtitle: l10n.ambientColorBackgroundDesc,
        category: l10n.theme,
        widget: const AmbientLyricsBgTile(),
      ),
      if (!settings.ambientColorBackground)
        SettingsSearchItem(
          title: l10n.blurredArtworkForLyrics,
          subtitle: l10n.blurredArtworkForLyricsDesc,
          category: l10n.theme,
          widget: const BlurredArtworkLyricsTile(),
        ),
      if (settings.enableDynamicTheming || settings.dynamicLyrics)
        SettingsSearchItem(
          title: l10n.dynamicColorActiveLyrics,
          subtitle: l10n.dynamicColorActiveLyricsDesc,
          category: l10n.theme,
          widget: const DynamicColorActiveLyricsTile(),
        ),
      SettingsSearchItem(
        title: l10n.lyricsAlignment,
        subtitle: l10n.lyricsAlignmentDesc,
        category: l10n.theme,
        widget: const LyricsAlignmentTile(),
      ),
      SettingsSearchItem(
        title: l10n.flatProgressBar,
        subtitle: l10n.disableSquigglyProgressBar,
        category: l10n.theme,
        widget: const FlatProgressBarTile(),
      ),
      SettingsSearchItem(
        title: l10n.plainTimestamps,
        subtitle: l10n.useStaticTextTimestamps,
        category: l10n.theme,
        widget: const PlainTimestampsTile(),
      ),
      SettingsSearchItem(
        title: l10n.showQualityBadge,
        subtitle: l10n.showQualityBadgeDesc,
        category: l10n.theme,
        widget: const ShowQualityBadgeTile(),
      ),
      SettingsSearchItem(
        title: l10n.enablePlayerGradient,
        subtitle: l10n.enablePlayerGradientDesc,
        category: l10n.theme,
        widget: const EnablePlayerGradientTile(),
      ),
      if (settings.enablePlayerGradient)
        SettingsSearchItem(
          title: l10n.animatePlayerGradient,
          subtitle: l10n.animatePlayerGradientDesc,
          category: l10n.theme,
          widget: const AnimatePlayerGradientTile(),
        ),
      if (settings.enablePlayerGradient)
        SettingsSearchItem(
          title: l10n.keepBackgroundGradient,
          subtitle: l10n.keepBackgroundGradientDesc,
          category: l10n.theme,
          widget: const KeepBackgroundGradientTile(),
        ),
      if (settings.enablePlayerGradient && settings.keepBackgroundGradient)
        SettingsSearchItem(
          title: l10n.animateBackgroundGradient,
          subtitle: l10n.animateBackgroundGradientDesc,
          category: l10n.theme,
          widget: const AnimateBackgroundGradientTile(),
        ),
      SettingsSearchItem(
        title: l10n.useCustomFont,
        subtitle: l10n.useCustomFontDesc,
        category: l10n.theme,
        widget: const UseNewFontTile(),
      ),
      if (settings.useNewFont) ...[
        SettingsSearchItem(
          title: l10n.selectFontFamily,
          subtitle: l10n.activeFont(settings.customFontFamily),
          category: l10n.theme,
          widget: const FontFamilySelectionTile(),
        ),
        SettingsSearchItem(
          title: l10n.fontWeight,
          subtitle: l10n.changeBaseFontWeight,
          category: l10n.theme,
          widget: const FontWeightSelectionTile(),
        ),
      ],
      SettingsSearchItem(
        title: l10n.useCustomFontLyrics,
        subtitle: l10n.useCustomFontLyricsDesc,
        category: l10n.theme,
        widget: const UseNewFontLyricsTile(),
      ),
      if (settings.useNewFontLyrics) ...[
        SettingsSearchItem(
          title: l10n.lyricsFontFamily,
          subtitle: l10n.activeLyricsFont(settings.customFontFamilyLyrics),
          category: l10n.theme,
          widget: const LyricsFontFamilySelectionTile(),
        ),
        SettingsSearchItem(
          title: l10n.lyricsFontWeight,
          subtitle: l10n.lyricsFontWeightValue(
            700 + settings.activeLyricsFontWeightDelta * 100,
          ),
          category: l10n.theme,
          widget: const LyricsFontWeightSelectionTile(),
        ),
      ],

      // Dashboard
      SettingsSearchItem(
        title: l10n.showArtistsRow,
        subtitle: l10n.showArtistsRowDesc,
        category: l10n.homeDashboardSettings,
        widget: const ShowArtistsRowTile(),
      ),
      SettingsSearchItem(
        title: l10n.showAlbumsRow,
        subtitle: l10n.showAlbumsRowDesc,
        category: l10n.homeDashboardSettings,
        widget: const ShowAlbumsRowTile(),
      ),
      SettingsSearchItem(
        title: l10n.showGenresRow,
        subtitle: l10n.showGenresRowDesc,
        category: l10n.homeDashboardSettings,
        widget: const ShowGenresRowTile(),
      ),
      SettingsSearchItem(
        title: l10n.showRecentRow,
        subtitle: l10n.showRecentRowDesc,
        category: l10n.homeDashboardSettings,
        widget: const ShowRecentRowTile(),
      ),
      SettingsSearchItem(
        title: l10n.reorderDashboardSections,
        subtitle: l10n.reorderDashboardSectionsDesc,
        category: l10n.homeDashboardSettings,
        widget: const ReorderDashboardSectionsTile(),
      ),

      // Playback
      SettingsSearchItem(
        title: l10n.language,
        subtitle: l10n.selectAppLanguage,
        category: l10n.playbackAudio,
        widget: const LanguageTile(),
      ),
      if (!Platform.isLinux)
        SettingsSearchItem(
          title: l10n.fluidPlayer,
          subtitle: l10n.fluidPlayerDesc,
          category: l10n.playbackAudio,
          widget: const FluidPlayerTile(),
        ),
      SettingsSearchItem(
        title: l10n.equalizer,
        subtitle: l10n.equalizerSearchDesc,
        category: l10n.playbackAudio,
        widget: const EqualizerTile(),
      ),
      if (Platform.isAndroid)
        SettingsSearchItem(
          title: l10n.stopServiceOnAppDismissal,
          subtitle: l10n.stopServiceSearchDesc,
          category: l10n.playbackAudio,
          widget: const StopServiceTile(),
        ),
      SettingsSearchItem(
        title: l10n.internetMode,
        subtitle: l10n.enableNetworkLyricsArt,
        category: l10n.playbackAudio,
        widget: const InternetModeTile(),
      ),
      SettingsSearchItem(
        title: l10n.downloadMissingArtwork,
        subtitle: l10n.downloadMissingArtworkDesc,
        category: l10n.playbackAudio,
        widget: const DownloadMissingArtworkTile(),
      ),

      // Audio Playback
      SettingsSearchItem(
        title: l10n.fadePlayPauseStop,
        subtitle: l10n.fadePlayPauseStopDesc,
        category: l10n.audioPlayback,
        widget: const FadePlayPauseStopTile(),
      ),
      if (settings.fadePlayPauseStop)
        SettingsSearchItem(
          title: l10n.fadeDuration,
          subtitle: l10n.fadeDurationDesc,
          category: l10n.audioPlayback,
          widget: const FadeDurationSlider(),
        ),

      if (Platform.isAndroid) ...[
        SettingsSearchItem(
          title: l10n.manageAudioFocusTitle,
          subtitle: l10n.manageAudioFocusDesc,
          category: l10n.audioPlayback,
          widget: const ManageAudioFocusTile(),
        ),
        if (settings.audioFocus) ...[
          SettingsSearchItem(
            title: l10n.resumeAfterCallTitle,
            subtitle: l10n.resumeAfterCallDesc,
            category: l10n.audioPlayback,
            widget: const ResumeAfterCallTile(),
          ),
          SettingsSearchItem(
            title: l10n.resumeOnBluetoothConnectTitle,
            subtitle: l10n.resumeOnBluetoothConnectDesc,
            category: l10n.audioPlayback,
            widget: const ResumeOnBluetoothConnectTile(),
          ),
        ],
      ],
      SettingsSearchItem(
        title: l10n.resumeOnStartTitle,
        subtitle: l10n.resumeOnStartDesc,
        category: l10n.audioPlayback,
        widget: const ResumeOnStartTile(),
      ),
      SettingsSearchItem(
        title: l10n.shuffleTitle,
        subtitle: l10n.shuffleSwitchingDesc,
        category: l10n.audioPlayback,
        widget: const ShuffleTile(),
      ),
      SettingsSearchItem(
        title: l10n.persistQueueTitle,
        subtitle: l10n.persistQueueDesc,
        category: l10n.audioPlayback,
        widget: const PersistQueueTile(),
      ),
      SettingsSearchItem(
        title: l10n.keepSongProgressTitle,
        subtitle: l10n.keepSongProgressDesc,
        category: l10n.audioPlayback,
        widget: const KeepSongProgressTile(),
      ),

      // Library
      SettingsSearchItem(
        title: l10n.addFolder,
        subtitle: l10n.scanNewFolderDesc,
        category: l10n.musicLibrary,
        widget: const AddFolderTile(),
      ),
      SettingsSearchItem(
        title: l10n.syncLyricsOffline,
        subtitle: l10n.downloadingLyricsOffline,
        category: l10n.musicLibrary,
        widget: const SyncLyricsOfflineTile(),
      ),
      SettingsSearchItem(
        title: l10n.rescanLibrary,
        subtitle: l10n.scanningLibrary,
        category: l10n.musicLibrary,
        widget: const RescanLibraryTile(),
      ),
      SettingsSearchItem(
        title: l10n.includeOtherDeviceAudioTitle,
        subtitle: l10n.includeOtherDeviceAudioShortDesc,
        category: l10n.musicLibrary,
        widget: const IncludeSystemAndMessagingAudioTile(),
      ),
      SettingsSearchItem(
        title: l10n.excludedFolders,
        subtitle: l10n.excludedFoldersSearchDesc,
        category: l10n.musicLibrary,
        widget: const ExcludedFoldersTile(),
      ),
      SettingsSearchItem(
        title: l10n.resetLibrary,
        subtitle: l10n.clearLibraryData,
        category: l10n.musicLibrary,
        widget: const ResetLibraryTile(),
      ),

      // About
      SettingsSearchItem(
        title: l10n.looperPlayerVersion,
        subtitle: l10n
            .versionLabel(ref.watch(appVersionProvider).value ?? '')
            .trim(),
        category: l10n.aboutAndMaintainers,
        widget: const LooperVersionTile(),
      ),
      SettingsSearchItem(
        title: l10n.lyricsProvider,
        subtitle: settings.lyricsProvider,
        category: l10n.theme,
        widget: const LyricsProviderTile(),
      ),
    ];
  }
}
