import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/app_links.dart';
import 'package:looper_player/core/providers/providers.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/android/widgets/premium_section.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/tiles/theme/theme_settings_tiles.dart';
import '../widgets/tiles/dashboard_settings_tiles.dart';
import '../widgets/tiles/playback_settings_tiles.dart';
import '../widgets/tiles/audio_playback_settings_tiles.dart';
import '../widgets/tiles/library_settings_tiles.dart';
import '../widgets/tiles/about_settings_tiles.dart';
import '../widgets/tiles/backup_logs_settings_tiles.dart';

class SettingsCategoryScreen extends ConsumerWidget {
  final String categoryId;
  final String title;

  const SettingsCategoryScreen({
    super.key,
    required this.categoryId,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    final useBlur = settings.enableDynamicTheming && !settings.disableBlur;

    List<Widget> children = [];
    if (categoryId == 'theme') {
      children = [
        const DynamicThemingTile(),
        const Divider(height: 1, indent: 72, color: Colors.white10),
        const SelectAvatarsTile(),
        if (settings.enableDynamicTheming) ...[
          const Divider(height: 1, indent: 72, color: Colors.white10),
          const DisableBlurTile(),
        ],
        if (!settings.enableDynamicTheming) ...[
          const Divider(height: 1, indent: 72, color: Colors.white10),
          const DynamicAccentColorTile(),
          const Divider(height: 1, indent: 72, color: Colors.white10),
          const PureBlackOledTile(),
          const Divider(height: 1, indent: 72, color: Colors.white10),
          const AlwaysBlurSheetsTile(),
          if (!settings.dynamicAccentColor) ...[
            const Divider(height: 1, indent: 72, color: Colors.white10),
            const AccentColorTile(),
            const Divider(height: 1, indent: 72, color: Colors.white10),
            const CustomAccentColorTile(),
          ],
        ],
        // if (!settings.enableDynamicTheming) ...[
        const Divider(height: 1, indent: 72, color: Colors.white10),
        const AmbientLyricsBgTile(),
        // ],
        const Divider(height: 1, indent: 72, color: Colors.white10),
        const BlurredArtworkLyricsTile(),
        if (settings.enableDynamicTheming ||
            settings.ambientColorBackground) ...[
          const Divider(height: 1, indent: 72, color: Colors.white10),
          const DynamicColorActiveLyricsTile(),
        ],
        const Divider(height: 1, indent: 72, color: Colors.white10),
        const LyricsAlignmentTile(),
        const Divider(height: 1, indent: 72, color: Colors.white10),
        const LyricsProviderTile(),
        const Divider(height: 1, indent: 72, color: Colors.white10),
        const FlatProgressBarTile(),
        const Divider(height: 1, indent: 72, color: Colors.white10),
        const PlainTimestampsTile(),
        const Divider(height: 1, indent: 72, color: Colors.white10),
        const ShowQualityBadgeTile(),
        const Divider(height: 1, indent: 72, color: Colors.white10),
        const EnablePlayerGradientTile(),
        if (settings.enablePlayerGradient) ...[
          const Divider(height: 1, indent: 72, color: Colors.white10),
          const AnimatePlayerGradientTile(),
          const Divider(height: 1, indent: 72, color: Colors.white10),
          const KeepBackgroundGradientTile(),
          if (settings.keepBackgroundGradient) ...[
            const Divider(height: 1, indent: 72, color: Colors.white10),
            const AnimateBackgroundGradientTile(),
          ],
        ],
        const Divider(height: 1, indent: 72, color: Colors.white10),
        const UseNewFontTile(),
        if (settings.useNewFont) ...[
          const Divider(height: 1, indent: 72, color: Colors.white10),
          const FontFamilySelectionTile(),
          const Divider(height: 1, indent: 72, color: Colors.white10),
          const FontWeightSelectionTile(),
        ],
        const Divider(height: 1, indent: 72, color: Colors.white10),
        const UseNewFontLyricsTile(),
        if (settings.useNewFontLyrics) ...[
          const Divider(height: 1, indent: 72, color: Colors.white10),
          const LyricsFontFamilySelectionTile(),
          const Divider(height: 1, indent: 72, color: Colors.white10),
          const LyricsFontWeightSelectionTile(),
        ],
        // Darkness sliders
        if (settings.enableDynamicTheming) ...[
          const Divider(height: 1, indent: 72, color: Colors.white10),
          const HomeDarknessSlider(),
          const Divider(height: 1, indent: 72, color: Colors.white10),
          const SongsDarknessSlider(),
          const Divider(height: 1, indent: 72, color: Colors.white10),
          const LibraryDarknessSlider(),
          const Divider(height: 1, indent: 72, color: Colors.white10),
          const MusicDarknessSlider(),
          const Divider(height: 1, indent: 72, color: Colors.white10),
          const LyricsDarknessSlider(),
        ] else ...[
          if (settings.keepBackgroundGradient) ...[
            const Divider(height: 1, indent: 72, color: Colors.white10),
            const HomeDarknessSlider(),
          ],
          if (settings.enablePlayerGradient) ...[
            const Divider(height: 1, indent: 72, color: Colors.white10),
            const MusicDarknessSlider(),
          ],
          if (settings.ambientColorBackground ||
              settings.keepBackgroundGradient ||
              settings.blurredArtworkForLyrics) ...[
            const Divider(height: 1, indent: 72, color: Colors.white10),
            const LyricsDarknessSlider(),
          ],
        ],
        //const PerformanceOptimizerTile(),
      ];
    } else if (categoryId == 'dashboard') {
      children = [
        const ShowArtistsRowTile(),
        const Divider(height: 1, indent: 72, color: Colors.white10),
        const ShowAlbumsRowTile(),
        const Divider(height: 1, indent: 72, color: Colors.white10),
        const ShowGenresRowTile(),
        const Divider(height: 1, indent: 72, color: Colors.white10),
        const ShowRecentRowTile(),
        const Divider(height: 1, indent: 72, color: Colors.white10),
        const ReorderDashboardSectionsTile(),
      ];
    } else if (categoryId == 'playback') {
      children = [
        const LanguageTile(),
        if (!Platform.isLinux) ...[
          const Divider(height: 1, indent: 72, color: Colors.white10),
          const FluidPlayerTile(),
        ],
        if (Platform.isAndroid) ...[
          const Divider(height: 1, indent: 72, color: Colors.white10),
          const StopServiceTile(),
        ],
        const Divider(height: 1, indent: 72, color: Colors.white10),
        const InternetModeTile(),
        const Divider(height: 1, indent: 72, color: Colors.white10),
        const DownloadMissingArtworkTile(),
      ];
    } else if (categoryId == 'audio_playback') {
      children = [
        const EqualizerTile(),
        const Divider(height: 1, indent: 72, color: Colors.white10),
        const FadePlayPauseStopTile(),
        if (settings.fadePlayPauseStop) ...[
          const Divider(height: 1, indent: 72, color: Colors.white10),
          const FadeDurationSlider(),
        ],

        const Divider(height: 1, indent: 72, color: Colors.white10),
        const ShuffleTile(),
        const Divider(height: 1, indent: 72, color: Colors.white10),
        const PersistQueueTile(),
        const Divider(height: 1, indent: 72, color: Colors.white10),
        const KeepSongProgressTile(),
        if (!Platform.isAndroid) ...[
          const Divider(height: 1, indent: 72, color: Colors.white10),
          const ResumeOnStartTile(),
        ],
        if (Platform.isAndroid) ...[
          const Divider(height: 1, indent: 72, color: Colors.white10),
          const ManageAudioFocusTile(),
          if (settings.audioFocus) ...[
            const Divider(height: 1, indent: 72, color: Colors.white10),
            const ResumeAfterCallTile(),
            const Divider(height: 1, indent: 72, color: Colors.white10),
            const ResumeOnBluetoothConnectTile(),
          ],
          const Divider(height: 1, indent: 72, color: Colors.white10),
          const ResumeOnStartTile(),
        ],
      ];
    } else if (categoryId == 'library') {
      children = [
        const LibraryFoldersList(),
        const Divider(height: 1, indent: 72, color: Colors.white10),
        const AddFolderTile(),
        const Divider(height: 1, indent: 72, color: Colors.white10),
        const SyncLyricsOfflineTile(),
        const Divider(height: 1, indent: 72, color: Colors.white10),
        const IncludeSystemAndMessagingAudioTile(),
        const Divider(height: 1, indent: 72, color: Colors.white10),
        const ExcludedFoldersTile(),
        const Divider(height: 1, indent: 72, color: Colors.white10),
        const RescanLibraryTile(),
        const Divider(height: 1, indent: 72, color: Colors.white10),
        const ResetLibraryTile(),
      ];
    } else if (categoryId == 'backups_logs') {
      children = [
        const ExportBackupTile(),
        const Divider(height: 1, indent: 72, color: Colors.white10),
        const ImportBackupTile(),
        const Divider(height: 1, indent: 72, color: Colors.white10),
        const ExportLogsTile(),
        const Divider(height: 1, indent: 72, color: Colors.white10),
        const ClearLogsTile(),
      ];
    } else if (categoryId == 'about') {
      children = [
        const LooperVersionTile(), //1
        const Divider(height: 1, indent: 72, color: Colors.white10), //2
        AboutMaintainerRow(
          //3
          name: 'Nilesh Suthar',
          role: l10n.creatorAndMaintainer,
          avatar: 'assets/about/maintainer_avatar.png',
          github: AppLinks.nileshGithub,
          telegram: AppLinks.nileshTelegram,
        ),
        const Divider(height: 1, indent: 72, color: Colors.white10), //4
        AboutMaintainerRow(
          //5
          name: 'Krn.',
          role: l10n.designerAndMaintainer,
          avatar: 'assets/about/designer_avatar.png',
          github: AppLinks.karanGithub,
          telegram: AppLinks.karanTelegram,
        ),
        const Divider(height: 1, indent: 72, color: Colors.white10), //6
        AboutMaintainerRow(
          //7
          name: 'Madan Suthar',
          role: 'Free Rider',
          avatar: 'assets/about/free_rider_avatar.png',
          github: AppLinks.madanGithub,
          telegram: AppLinks.madanTelegram,
        ),
        const Divider(height: 1, indent: 72, color: Colors.white10), //8
        Padding(
          //11
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.appInfoPrivacy.toUpperCase(),
                style: AppFonts.jostStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(settings.accentColor).withValues(alpha: 0.8),
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
                icon: LucideIcons.shieldCheck,
                title: l10n.whyPermissionsUsed,
                description: l10n.whyPermissionsUsedDesc,
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
      ];
    }

    return Scaffold(
      // See the comment on the main SettingsView's Scaffold above - same
      // reasoning applies here.
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PremiumSection(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      bottomLeft: Radius.circular(32),
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                    width: 48,
                    height: 48,
                    useBlur: useBlur,
                    forceNoBlur: true,
                    useExpanded: false,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      // Go through appNavigationProvider (not a raw Navigator
                      // pop) so its logical history stays in sync with the
                      // physical route stack -- see showSettingsCategory's
                      // call site for why that matters for the back button.
                      ref.read(appNavigationProvider.notifier).goBack();
                    },
                    child: const Icon(
                      LucideIcons.arrowLeft,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        title,
                        style: AppFonts.jostStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48, height: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                physics: const BouncingScrollPhysics(),
                children: categoryId == 'about'
                    ? [
                        // Top Section Card
                        PremiumSection(
                          useBlur: useBlur,
                          forceNoBlur: true,
                          borderRadius: BorderRadius.circular(14),
                          useExpanded: false,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                'assets/main_logo_transparent.svg',
                                height: 36,
                                fit: BoxFit.contain,
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(32),
                                    bottomLeft: Radius.circular(32),
                                    topRight: Radius.circular(10),
                                    bottomRight: Radius.circular(10),
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'v${ref.watch(appVersionProvider).value ?? ""}'
                                      .trim(),
                                  style: AppFonts.jostStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () async {
                                  HapticFeedback.lightImpact();
                                  final Uri uri = Uri.parse(
                                    AppLinks.githubRepo,
                                  );
                                  try {
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } catch (e) {}
                                },
                                child: SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: Center(
                                    child: SvgPicture.asset(
                                      'assets/about/github_icon.svg',
                                      width: 32,
                                      height: 32,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Give Star on Github Card
                        const GitHubStarTile(),

                        const SizedBox(height: 32),
                        // Maintainers Header
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.maintainersLabel,
                                style: AppFonts.jostStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.personBehindLooperPlayer,
                                style: AppFonts.jostStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Maintainers Card
                        PremiumSection(
                          useBlur: useBlur,
                          forceNoBlur: true,
                          borderRadius: BorderRadius.circular(14),
                          useExpanded: false,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: children.sublist(2, 7), //.sublist(2, 5),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // App Info & Privacy Card
                        PremiumSection(
                          useBlur: useBlur,
                          forceNoBlur: true,
                          borderRadius: BorderRadius.circular(14),
                          useExpanded: false,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          child: children.last,
                        ),
                        const SizedBox(height: 120),
                        const OpenSourceLicensesTile(),
                      ]
                    : [
                        PremiumSection(
                          useBlur: useBlur,
                          forceNoBlur: true,
                          borderRadius: BorderRadius.circular(24),
                          useExpanded: false,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: children,
                          ),
                        ),
                        const SizedBox(height: 120),
                      ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
