import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:looper_player/ui/android/player/equalizer/android_equalizer_screen.dart';
import 'package:looper_player/ui/widgets/common/folder_picker_helper.dart';
import 'package:looper_player/core/utils/l10n.dart';
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

            // Appearance Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _Section(
                  title: l10n.appearance,
                  children: [
                    _PremiumSwitchRow(
                      icon: LucideIcons.palette,
                      title: l10n.dynamicTheming,
                      subtitle: l10n.adaptColorsArtwork,
                      value: settings.enableDynamicTheming,
                      onChanged: (value) {
                        HapticFeedback.lightImpact();
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
                          HapticFeedback.lightImpact();
                          ref
                              .read(settingsProvider.notifier)
                              .updateDisableBlur(value);
                        },
                        isLast: false,
                      ),
                    if (!settings.enableDynamicTheming) ...[
                      _PremiumSwitchRow(
                        icon: LucideIcons.paintBucket,
                        title: l10n.dynamicAccentColor,
                        subtitle: l10n.dynamicAccentColorDesc,
                        value: settings.dynamicAccentColor,
                        onChanged: (value) {
                          HapticFeedback.lightImpact();
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
                        HapticFeedback.lightImpact();
                        ref
                            .read(settingsProvider.notifier)
                            .updateDarkTheme(value);
                      },
                      isLast: false,
                    ),
                    _PremiumSwitchRow(
                      icon: LucideIcons.music,
                      title: l10n.dynamicLyricsBg,
                      subtitle: l10n.dynamicLyricsBgDesc,
                      value: settings.dynamicLyrics,
                      onChanged: (value) {
                        HapticFeedback.lightImpact();
                        ref
                            .read(settingsProvider.notifier)
                            .updateDynamicLyrics(value);
                      },
                      isLast: false,
                    ),
                    if (settings.enableDynamicTheming || settings.dynamicLyrics)
                      _PremiumSwitchRow(
                        icon: LucideIcons.palette,
                        title: l10n.dynamicColorActiveLyrics,
                        subtitle: l10n.dynamicColorActiveLyricsDesc,
                        value: settings.dynamicColorActiveLyrics,
                        onChanged: (value) {
                          HapticFeedback.lightImpact();
                          ref
                              .read(settingsProvider.notifier)
                              .updateDynamicColorActiveLyrics(value);
                        },
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
                          HapticFeedback.lightImpact();
                          ref
                              .read(settingsProvider.notifier)
                              .updateLyricsAlignment(align);
                        }
                      },
                      isLast: false,
                    ),
                    _PremiumSwitchRow(
                      icon: LucideIcons.sliders,
                      title: l10n.flatProgressBar,
                      subtitle: l10n.disableSquigglyProgressBar,
                      value: settings.disableSquiggle,
                      onChanged: (value) {
                        HapticFeedback.lightImpact();
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
                        HapticFeedback.lightImpact();
                        ref
                            .read(settingsProvider.notifier)
                            .updateDisableAnimatedDuration(value);
                      },
                      isLast: false,
                    ),
                    if (!Platform.isLinux)
                      _PremiumSwitchRow(
                        icon: LucideIcons.move,
                        title: l10n.fluidPlayer,
                        subtitle: l10n.fluidPlayerDesc,
                        value: settings.enableSlideGesture,
                        onChanged: (value) {
                          HapticFeedback.lightImpact();
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
                          HapticFeedback.lightImpact();
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
                          HapticFeedback.lightImpact();
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

            // Audio & Playback Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _Section(
                  title: l10n.audioPlayback,
                  children: [
                    _PremiumSwitchRow(
                      icon: LucideIcons.music,
                      title: l10n.fadePlayPauseStop,
                      subtitle: l10n.fadePlayPauseStopDesc,
                      value: settings.fadePlayPauseStop,
                      onChanged: (value) {
                        HapticFeedback.lightImpact();
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
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const AndroidEqualizerScreen(),
                        );
                      },
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
                          HapticFeedback.lightImpact();
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
                            HapticFeedback.lightImpact();
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
                            HapticFeedback.lightImpact();
                            ref
                                .read(settingsProvider.notifier)
                                .updateResumeOnStart(value);
                          },
                          isLast: true,
                        ),
                      ],
                    ],
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
                  children: [
                    const _PremiumLibraryFoldersList(),
                    _PremiumActionRow(
                      icon: LucideIcons.plus,
                      title: l10n.addFolder,
                      subtitle: l10n.selectFolderIndex,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        FolderPickerHelper.pickFolder(context, ref);
                      },
                      isLast: false,
                    ),
                    _PremiumActionRow(
                      icon: LucideIcons.refreshCcw,
                      title: l10n.rescanLibrary,
                      subtitle: l10n.updateLibraryIndexing,
                      onTap: () {
                        HapticFeedback.lightImpact();
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
                        HapticFeedback.lightImpact();
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
                        HapticFeedback.lightImpact();
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
                      subtitle: l10n.resetLibraryDesc,
                      onTap: () {
                        HapticFeedback.heavyImpact();
                        _showClearDialog(context, l10n);
                      },
                      isLast: true,
                    ),
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
                        final url = Uri.parse('https://lrclib.net');
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
                      isLast: true,
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

  void _showClearDialog(BuildContext context, AppLocalizations l10n) {
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
          l10n.resetLibraryConfirmNew,
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
            onPressed: () async {
              await DbService.isar.writeTxn(() async {
                await DbService.isar.songs.clear();
                await DbService.isar.albums.clear();
                await DbService.isar.artists.clear();
              });
              Navigator.pop(context);
            },
            child: Text(
              l10n.clear,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
