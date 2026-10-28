import 'package:looper_player/core/utils/desktop_paths.dart';
import 'dart:io';
import 'package:looper_player/core/utils/ui_scale_steps.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:looper_player/features/playback/presentation/widgets/lyrics/lyrics_scale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/features/library/data/services/saf_folder_service.dart';
import 'package:looper_player/features/library/presentation/providers/library/library_notifier.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:looper_player/ui/android/widgets/premium_section.dart';
import 'package:looper_player/core/providers/providers.dart';
import 'package:looper_player/ui/desktop/equalizer/desktop_equalizer_dialog.dart';
import 'package:looper_player/ui/widgets/common/folder_picker_helper.dart';
import 'package:looper_player/core/utils/l10n.dart';
import 'package:looper_player/core/theme/app_assets.dart';
import 'package:looper_player/core/utils/app_links.dart';
import 'package:looper_player/features/settings/presentation/widgets/tiles/about_settings_tiles.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/settings/presentation/widgets/tiles/audio_playback_settings_tiles.dart';
import 'package:looper_player/features/settings/presentation/widgets/tiles/backup_logs_settings_tiles.dart';
import 'package:looper_player/features/settings/presentation/widgets/tiles/dashboard_settings_tiles.dart';
import 'package:looper_player/features/settings/presentation/widgets/tiles/theme/theme_settings_tiles.dart';
import 'package:looper_player/features/playback/data/lyrics_fetcher.dart';
import 'package:looper_player/features/playback/data/lyrics_providers/lyrics_provider_info.dart';
import 'collapsible_settings_section.dart';
part 'settings_rows.dart';
part 'library_folders_list.dart';
part 'maintainer_section.dart';
part 'accent_color_row.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    const divider = Divider(height: 1, indent: 72, color: Colors.white10);
    final dynamicTheming = settings.enableDynamicTheming;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Text(
                  l10n.settings,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),

            // Donate
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: PremiumSection(
                  borderRadius: BorderRadius.circular(20),
                  padding: EdgeInsets.zero,
                  useExpanded: false,
                  useCenter: false,
                  backgroundColor: dynamicTheming
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.06)
                      : null,
                  child: Material(
                    type: MaterialType.transparency,
                    child: _PremiumActionRow(
                      icon: LucideIcons.heart,
                      title: l10n.supportUs,
                      subtitle: l10n.supportUsDesc,
                      textColor: Theme.of(context).colorScheme.primary,
                      trailing: const Icon(
                        LucideIcons.externalLink,
                        size: 16,
                        color: Colors.white38,
                      ),
                      onTap: () {
                        AppHaptics.light();
                        launchUrl(
                          Uri.parse(AppLinks.koFi),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      isLast: true,
                    ),
                  ),
                ),
              ),
            ),

            // Appearance Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _Section(
                  title: l10n.appearance,
                  icon: LucideIcons.palette,
                  initiallyExpanded: true,
                  children: [
                    _PremiumSwitchRow(
                      icon: LucideIcons.palette,
                      title: l10n.dynamicTheming,
                      subtitle: l10n.adaptColorsArtwork,
                      value: settings.enableDynamicTheming,
                      onChanged: (value) {
                        AppHaptics.light();
                        ref
                            .read(settingsProvider.notifier)
                            .updateDynamicTheming(value);
                      },
                      isLast: false,
                    ),
                    if (settings.enableDynamicTheming)
                      _PremiumSwitchRow(
                        icon: LucideIcons.eyeOff,
                        title: l10n.disableBlurEffects,
                        subtitle: l10n.turnOffBlursOptimize,
                        value: settings.disableBlur,
                        onChanged: (value) {
                          AppHaptics.light();
                          ref
                              .read(settingsProvider.notifier)
                              .updateDisableBlur(value);
                        },
                        isLast: false,
                      ),
                    if (settings.enableDynamicTheming)
                      _PremiumSliderRow(
                        icon: LucideIcons.moon,
                        title: l10n.homeDarkness,
                        subtitle: l10n.homeDarknessDesc,
                        value:
                            (settings.desktopBackgroundDarkness.isNaN
                                ? AppSettings.defaultDesktopBackgroundDarkness
                                : settings.desktopBackgroundDarkness) *
                            100,
                        min: 0,
                        max: 100,
                        suffix: '%',
                        onChanged: (val) => ref
                            .read(settingsProvider.notifier)
                            .updateDesktopBackgroundDarkness(val / 100.0),
                        isLast: false,
                      ),
                    if (!settings.enableDynamicTheming) ...[
                      _PremiumSwitchRow(
                        icon: LucideIcons.paintBucket,
                        title: l10n.dynamicAccentColor,
                        subtitle: l10n.dynamicAccentColorDesc,
                        value: settings.dynamicAccentColor,
                        onChanged: (value) {
                          AppHaptics.light();
                          ref
                              .read(settingsProvider.notifier)
                              .updateDynamicAccentColor(value);
                        },
                        isLast: false,
                      ),
                      _PremiumAccentColorRow(
                        icon: LucideIcons.droplet,
                        title: l10n.accentColor,
                        subtitle: l10n.accentColorDesc,
                        selectedColor: settings.accentColor,
                        onColorChanged: (color) {
                          ref
                              .read(settingsProvider.notifier)
                              .updateAccentColor(color);
                        },
                        isLast: false,
                      ),
                    ],
                    _PremiumSwitchRow(
                      icon: LucideIcons.moon,
                      title: l10n.pureBlackOled,
                      subtitle: l10n.pureBlackOledDesc,
                      value: settings.darkTheme,
                      onChanged: (value) {
                        AppHaptics.light();
                        ref
                            .read(settingsProvider.notifier)
                            .updateDarkTheme(value);
                      },
                      isLast: false,
                    ),
                    _PremiumSwitchRow(
                      icon: LucideIcons.palette,
                      title: l10n.dynamicColorActiveLyrics,
                      subtitle: l10n.dynamicColorActiveLyricsDesc,
                      value: settings.dynamicColorActiveLyrics,
                      onChanged: (value) {
                        AppHaptics.light();
                        ref
                            .read(settingsProvider.notifier)
                            .updateDynamicColorActiveLyrics(value);
                      },
                      isLast: false,
                    ),
                    if (!activeLyricsIsWhite(settings))
                      _PremiumSwitchRow(
                        icon: LucideIcons.paintbrush,
                        title: l10n.activeLyricsUseAccent,
                        subtitle: l10n.activeLyricsUseAccentDesc,
                        value: !settings.activeLyricsSoftColor,
                        onChanged: (value) {
                          AppHaptics.light();
                          ref
                              .read(settingsProvider.notifier)
                              .updateActiveLyricsUseAccent(value);
                        },
                        isLast: false,
                      ),
                    if (!activeLyricsIsWhite(settings))
                      _PremiumSliderRow(
                        icon: LucideIcons.sunMedium,
                        title: l10n.activeLyricsIntensity,
                        subtitle: l10n.activeLyricsIntensityDesc,
                        value:
                            (settings.activeLyricsIntensity.isNaN
                                ? 0.35
                                : settings.activeLyricsIntensity) *
                            100,
                        min: 0,
                        max: 100,
                        suffix: '%',
                        onChanged: (val) => ref
                            .read(settingsProvider.notifier)
                            .updateActiveLyricsIntensity(val / 100.0),
                        isLast: false,
                      ),
                    _PremiumDropdownRow<String>(
                      icon: LucideIcons.alignCenter,
                      title: l10n.lyricsAlignment,
                      value: settings.lyricsAlignment,
                      items: [
                        DropdownMenuItem(value: 'left', child: Text(l10n.left)),
                        DropdownMenuItem(
                          value: 'center',
                          child: Text(l10n.center),
                        ),
                        DropdownMenuItem(
                          value: 'right',
                          child: Text(l10n.right),
                        ),
                      ],
                      onChanged: (align) {
                        if (align != null) {
                          AppHaptics.light();
                          ref
                              .read(settingsProvider.notifier)
                              .updateLyricsAlignment(align);
                        }
                      },
                      isLast: false,
                    ),
                    _PremiumSwitchRow(
                      icon: LucideIcons.listCollapse,
                      title: l10n.lyricsLineGrouping,
                      subtitle: l10n.lyricsLineGroupingDesc,
                      value: !settings.lyricsNoLineGrouping,
                      onChanged: (value) {
                        AppHaptics.light();
                        ref
                            .read(settingsProvider.notifier)
                            .updateLyricsLineGrouping(value);
                      },
                      isLast: false,
                    ),
                    if (UiUtils.isDesktop) ...[
                      _PremiumSliderRow(
                        icon: LucideIcons.languages,
                        title: l10n.lyricsSize,
                        subtitle: l10n.lyricsSizeDesc,
                        value:
                            LyricsScale.normalize(settings.lyricsFontScale) *
                            100,
                        min: LyricsScale.min * 100,
                        max: LyricsScale.max * 100,
                        divisions: 19,
                        suffix: '%',
                        onChanged: (val) => ref
                            .read(settingsProvider.notifier)
                            .updateLyricsFontScale((val / 10).round() / 10),
                        isLast: false,
                      ),
                      _PremiumDropdownRow<double>(
                        icon: LucideIcons.sliders,
                        title: l10n.uiScale,
                        value: UiScaleSteps.normalize(settings.desktopUiScale),
                        items: [
                          for (final step in UiScaleSteps.steps)
                            DropdownMenuItem(
                              value: step,
                              child: Text('${(step * 100).round()}%'),
                            ),
                        ],
                        onChanged: (step) {
                          if (step != null) {
                            ref
                                .read(settingsProvider.notifier)
                                .updateDesktopUiScale(step);
                          }
                        },
                        isLast: false,
                      ),
                    ],
                    _PremiumSwitchRow(
                      icon: LucideIcons.sliders,
                      title: l10n.flatProgressBar,
                      subtitle: l10n.disableSquigglyProgressBar,
                      value: settings.disableSquiggle,
                      onChanged: (value) {
                        AppHaptics.light();
                        ref
                            .read(settingsProvider.notifier)
                            .updateDisableSquiggle(value);
                      },
                      isLast: false,
                    ),
                    _PremiumSwitchRow(
                      icon: LucideIcons.clock,
                      title: l10n.plainTimestamps,
                      subtitle: l10n.useStaticTextTimestamps,
                      value: settings.disableAnimatedDuration,
                      onChanged: (value) {
                        AppHaptics.light();
                        ref
                            .read(settingsProvider.notifier)
                            .updateDisableAnimatedDuration(value);
                      },
                      isLast: false,
                    ),
                    _PremiumSwitchRow(
                      icon: LucideIcons.libraryBig,
                      title: l10n.groupByAlbum,
                      subtitle: l10n.groupByAlbumDesc,
                      value: settings.artistGroupByAlbum,
                      onChanged: (value) {
                        AppHaptics.light();
                        ref
                            .read(settingsProvider.notifier)
                            .updateArtistGroupByAlbum(value);
                      },
                      isLast: UiUtils.isDesktop,
                    ),
                    if (!UiUtils.isDesktop)
                      _PremiumSwitchRow(
                        icon: LucideIcons.move,
                        title: l10n.fluidPlayer,
                        subtitle: l10n.fluidPlayerDesc,
                        value: settings.enableSlideGesture,
                        onChanged: (value) {
                          AppHaptics.light();
                          ref
                              .read(settingsProvider.notifier)
                              .updateEnableSlideGesture(value);
                        },
                        isLast: !Platform.isAndroid,
                      ),
                    if (Platform.isAndroid)
                      _PremiumSwitchRow(
                        icon: LucideIcons.power,
                        title: l10n.stopServiceOnAppDismissal,
                        subtitle: l10n.stopServiceOnAppDismissalDesc,
                        value: settings.stopOnTaskRemoved,
                        onChanged: (value) {
                          AppHaptics.light();
                          ref
                              .read(settingsProvider.notifier)
                              .updateStopOnTaskRemoved(value);
                        },
                        isLast: true,
                      ),
                  ],
                ),
              ),
            ),

            // Language Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _Section(
                  title: l10n.language,
                  icon: LucideIcons.languages,
                  children: [
                    _PremiumDropdownRow<String>(
                      icon: LucideIcons.languages,
                      title: l10n.language,
                      value: settings.language,
                      items: [
                        DropdownMenuItem(
                          value: '',
                          child: Text(l10n.systemDefault),
                        ),
                        ...AppLocalizations.supportedLocales.map((locale) {
                          final code = locale.languageCode;
                          final name =
                              {
                                'en': 'English',
                                'es': 'Español',
                                'fr': 'Français',
                                'de': 'Deutsch',
                                'pt': 'Português',
                                'ru': 'Русский',
                                'it': 'Italiano',
                                'zh': '中文',
                                'ja': '日本語',
                                'ko': '한국어',
                                'ar': 'العربية',
                                'tr': 'Türkçe',
                                'nl': 'Nederlands',
                                'hi': 'हिन्दी',
                              }[code] ??
                              code;
                          return DropdownMenuItem(
                            value: code,
                            child: Text(name),
                          );
                        }),
                      ],
                      onChanged: (lang) {
                        if (lang != null) {
                          AppHaptics.light();
                          ref
                              .read(settingsProvider.notifier)
                              .updateLanguage(lang);
                        }
                      },
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),

            // Options shared with the Android settings, built from the same
            // tile widgets.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _Section(
                  title: l10n.themeGroupFonts,
                  icon: LucideIcons.type,
                  children: [
                    const UseNewFontTile(),
                    if (settings.useNewFont) ...[
                      divider,
                      const FontFamilySelectionTile(),
                      divider,
                      const FontWeightSelectionTile(),
                    ],
                    divider,
                    const UseNewFontLyricsTile(),
                    if (settings.useNewFontLyrics) ...[
                      divider,
                      const LyricsFontFamilySelectionTile(),
                      divider,
                      const LyricsFontWeightSelectionTile(),
                    ],
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _Section(
                  title: l10n.lyrics,
                  icon: LucideIcons.micVocal,
                  children: [const LyricsProviderTile()],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _Section(
                  title: l10n.homeDashboardSettings,
                  icon: LucideIcons.layoutDashboard,
                  children: const [
                    ShowRecentRowTile(),
                    divider,
                    ShowPlaylistsRowTile(),
                    divider,
                    ShowGenresRowTile(),
                    divider,
                    ShowArtistsRowTile(),
                  ],
                ),
              ),
            ),

            // Audio & Playback Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _Section(
                  title: l10n.audioPlayback,
                  icon: LucideIcons.audioLines,
                  children: [
                    _PremiumSwitchRow(
                      icon: LucideIcons.music,
                      title: l10n.fadePlayPauseStop,
                      subtitle: l10n.fadePlayPauseStopDesc,
                      value: settings.fadePlayPauseStop,
                      onChanged: (value) {
                        AppHaptics.light();
                        ref
                            .read(settingsProvider.notifier)
                            .updateFadePlayPauseStop(value);
                      },
                      isLast: false,
                    ),
                    if (settings.fadePlayPauseStop)
                      _PremiumSliderRow(
                        icon: LucideIcons.sliders,
                        title: l10n.fadeDuration,
                        subtitle: l10n.fadeDurationDesc,
                        value: settings.playPauseStopFadeLength.toDouble(),
                        min: 10,
                        max: 1000,
                        divisions: 99,
                        suffix: 'ms',
                        onChanged: (value) {
                          ref
                              .read(settingsProvider.notifier)
                              .updatePlayPauseStopFadeLength(value.round());
                        },
                        isLast: false,
                      ),

                    _PremiumActionRow(
                      icon: LucideIcons.sliders,
                      title: l10n.equalizer,
                      subtitle: settings.equalizerEnabled
                          ? l10n.equalizerEnabled18Band
                          : l10n.disabled,
                      onTap: () => showDesktopEqualizer(context),
                      trailing: const Icon(
                        LucideIcons.chevronRight,
                        color: Colors.white38,
                        size: 18,
                      ),
                      isLast: !Platform.isAndroid,
                    ),

                    if (Platform.isAndroid) ...[
                      _PremiumSwitchRow(
                        icon: LucideIcons.phoneCall,
                        title: l10n.manageAudioFocusTitle,
                        subtitle: l10n.manageAudioFocusDesc,
                        value: settings.audioFocus,
                        onChanged: (value) {
                          AppHaptics.light();
                          ref
                              .read(settingsProvider.notifier)
                              .updateAudioFocus(value);
                        },
                        isLast: !settings.audioFocus,
                      ),
                      if (settings.audioFocus) ...[
                        _PremiumSwitchRow(
                          icon: LucideIcons.phoneCall,
                          title: l10n.resumeAfterCallTitle,
                          subtitle: l10n.resumeAfterCallDesc,
                          value: settings.resumeAfterCall,
                          onChanged: (value) {
                            AppHaptics.light();
                            ref
                                .read(settingsProvider.notifier)
                                .updateResumeAfterCall(value);
                          },
                          isLast: false,
                        ),
                        _PremiumSwitchRow(
                          icon: LucideIcons.power,
                          title: l10n.resumeOnStartTitle,
                          subtitle: l10n.resumeOnStartDesc,
                          value: settings.resumeOnStart,
                          onChanged: (value) {
                            AppHaptics.light();
                            ref
                                .read(settingsProvider.notifier)
                                .updateResumeOnStart(value);
                          },
                          isLast: true,
                        ),
                      ],
                    ],
                    divider,
                    const ShuffleTile(),
                    divider,
                    const PersistQueueTile(),
                    divider,
                    const KeepSongProgressTile(),
                  ],
                ),
              ),
            ),

            // Library Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _Section(
                  title: l10n.librarySettings,
                  icon: LucideIcons.folderOpen,
                  children: [
                    const _PremiumLibraryFoldersList(),
                    _PremiumActionRow(
                      icon: LucideIcons.plus,
                      title: l10n.addFolder,
                      subtitle: l10n.selectFolderIndex,
                      onTap: () {
                        AppHaptics.light();
                        FolderPickerHelper.pickFolder(context, ref);
                      },
                      isLast: false,
                    ),
                    _PremiumActionRow(
                      icon: LucideIcons.refreshCcw,
                      title: l10n.rescanLibrary,
                      subtitle: l10n.updateLibraryIndexing,
                      onTap: () {
                        AppHaptics.light();
                        ref
                            .read(libraryProvider.notifier)
                            .scanSavedFolders(fullStorageDiscovery: true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.scanningLibrary)),
                        );
                      },
                      isLast: false,
                    ),
                    _PremiumSwitchRow(
                      icon: LucideIcons.audioLines,
                      title: l10n.includeOtherDeviceAudioTitle,
                      subtitle: l10n.includeOtherDeviceAudioAlarmsDesc,
                      value: settings.includeSystemAndMessagingAudio,
                      onChanged: (value) async {
                        AppHaptics.light();
                        await ref
                            .read(settingsProvider.notifier)
                            .updateIncludeSystemAndMessagingAudio(value);
                        await ref
                            .read(libraryProvider.notifier)
                            .scanSavedFolders(fullStorageDiscovery: true);
                      },
                      isLast: false,
                    ),
                    _PremiumSwitchRow(
                      icon: LucideIcons.globe,
                      title: l10n.internetMode,
                      subtitle: l10n.enableNetworkLyricsArt,
                      value: settings.enableInternet,
                      onChanged: (value) {
                        AppHaptics.light();
                        ref
                            .read(settingsProvider.notifier)
                            .updateEnableInternet(value);
                      },
                      isLast: false,
                    ),
                    _PremiumActionRow(
                      icon: LucideIcons.trash2,
                      title: l10n.resetLibrary,
                      textColor: Colors.redAccent,
                      subtitle: l10n.resetLibraryConfirm,
                      onTap: () {
                        AppHaptics.medium();
                        _showClearDialog(context, ref, l10n);
                      },
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _Section(
                  title: l10n.backupsAndLogs,
                  icon: LucideIcons.databaseBackup,
                  children: const [
                    ExportBackupTile(),
                    divider,
                    ImportBackupTile(),
                    divider,
                    ImportM3uPlaylistTile(),
                    divider,
                    ExportLogsTile(),
                    divider,
                    ClearLogsTile(),
                  ],
                ),
              ),
            ),

            // About Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _Section(
                  title: l10n.aboutApp,
                  icon: LucideIcons.info,
                  children: [
                    Consumer(
                      builder: (context, ref, _) {
                        final ver = ref.watch(appVersionProvider).value ?? '';
                        return _PremiumActionRow(
                          icon: LucideIcons.info,
                          title: l10n.appTitle,
                          subtitle: ver.isEmpty
                              ? l10n.version
                              : l10n.versionLabel(ver),
                          onTap: () {},
                          trailing: Text(
                            ver.isEmpty ? '' : 'v$ver',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 13,
                            ),
                          ),
                          isLast: false,
                        );
                      },
                    ),
                    _PremiumActionRow(
                      icon: LucideIcons.music,
                      title: l10n.lyricsProvider,
                      subtitle: l10n.lyricsProviderDesc,
                      onTap: () async {
                        final url = Uri.parse(
                          LyricsProviderInfo.of(
                                LyricsFetcher.enabledProviders(
                                  settings,
                                ).firstOrNull,
                              )?.url ??
                              AppLinks.lrcRedWeb,
                        );
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      isLast: false,
                    ),
                    _PremiumActionRow(
                      icon: LucideIcons.gitFork,
                      title: l10n.sourceCode,
                      subtitle: l10n.visitOfficialRepository,
                      onTap: () async {
                        final url = Uri.parse(
                          'https://github.com/SthrNilshaaa/looper',
                        );
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      isLast: false,
                    ),
                    const OpenSourceLicensesTile(),
                    divider,
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.appInfoPrivacy.toUpperCase(),
                            style: AppFonts.jostStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(
                                settings.accentColor,
                              ).withValues(alpha: 0.8),
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 16),
                          InfoSubTile(
                            icon: LucideIcons.music,
                            title: l10n.corePurpose,
                            description: l10n.corePurposeDesc,
                          ),
                          const SizedBox(height: 16),
                          InfoSubTile(
                            icon: LucideIcons.globe,
                            title: l10n.whyInternetUsed,
                            description: l10n.whyInternetUsedDesc,
                          ),
                          const SizedBox(height: 16),
                          InfoSubTile(
                            icon: LucideIcons.lock,
                            title: l10n.privacySafety,
                            description: l10n.privacySafetyDesc,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Lyrics Sources (credits)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _Section(
                  title: l10n.lyricsSources,
                  icon: LucideIcons.scroll,
                  children: [
                    for (final (i, credit) in lyricsCredits(l10n).indexed)
                      _PremiumActionRow(
                        icon: LucideIcons.music,
                        title: credit.name,
                        subtitle: credit.description,
                        trailing: const Icon(
                          LucideIcons.externalLink,
                          color: Colors.white38,
                          size: 16,
                        ),
                        onTap: () async {
                          final url = Uri.parse(credit.url);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        isLast: i == lyricsCredits(l10n).length - 1,
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      child: Text(
                        l10n.lyricsCopyrightNote,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Maintainers Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: const _PremiumMaintainerSection(),
              ),
            ),

            // Extra padding to breathe
            const SliverToBoxAdapter(child: SizedBox(height: 180)),
          ],
        ),
      ),
    );
  }

  void _showClearDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.resetLibrary,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          l10n.resetLibraryConfirm,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(libraryProvider.notifier).resetAndRescan();
            },
            child: Text(
              l10n.reset,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
