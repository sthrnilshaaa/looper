import 'dart:io';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:looper_player/core/services/update/apk_installer.dart';
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
import 'package:looper_player/core/theme/app_assets.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';

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
    // Theme is split into titled cards; other categories use one card.
    List<({String title, List<Widget> tiles})> sections = [];
    if (categoryId == 'theme') {
      final dynamicTheming = settings.enableDynamicTheming;
      sections = [
        (
          title: l10n.themeGroupColors,
          tiles: [
            const DynamicThemingTile(),
            if (!dynamicTheming) ...[
              const DynamicAccentColorTile(),
              if (!settings.dynamicAccentColor) ...[
                const AccentColorTile(),
                const CustomAccentColorTile(),
              ],
              const PureBlackOledTile(),
            ],
          ],
        ),
        (
          title: l10n.themeGroupBlurBackgrounds,
          tiles: [
            if (dynamicTheming) const DisableBlurTile(),
            if (!dynamicTheming) const AlwaysBlurSheetsTile(),
            const EnablePlayerGradientTile(),
            if (settings.enablePlayerGradient) ...[
              const AnimatePlayerGradientTile(),
              const KeepBackgroundGradientTile(),
              if (settings.keepBackgroundGradient)
                const AnimateBackgroundGradientTile(),
            ],
          ],
        ),
        (
          title: l10n.themeGroupDarkness,
          tiles: [
            if (dynamicTheming || settings.keepBackgroundGradient)
              const HomeDarknessSlider(),
            if (dynamicTheming) ...[
              const SongsDarknessSlider(),
              const LibraryDarknessSlider(),
            ],
            if (dynamicTheming || settings.enablePlayerGradient)
              const MusicDarknessSlider(),
            if (dynamicTheming ||
                settings.ambientColorBackground ||
                settings.keepBackgroundGradient ||
                settings.blurredArtworkForLyrics)
              const LyricsDarknessSlider(),
          ],
        ),
        (
          title: l10n.nowPlaying,
          tiles: [
            const ProgressBarStyleTile(),
            const ArtworkVisualizerTile(),
            const PlainTimestampsTile(),
            const ShowQualityBadgeTile(),
            if (settings.showQualityBadge) const QualityBadgeStyleTile(),
            const SegmentedUtilityButtonsTile(),
            const ShowAlbumNextToArtistTile(),
            if (settings.showAlbumNextToArtist)
              const ShowAlbumInQuickPicksTile(),
          ],
        ),
        (title: l10n.library, tiles: const [GroupArtistByAlbumTile()]),
        (
          title: l10n.lyrics,
          tiles: [
            const AmbientLyricsBgTile(),
            const BlurredArtworkLyricsTile(),
            const DynamicColorActiveLyricsTile(),
            // Both do nothing while the active line is plain white.
            if (!activeLyricsIsWhite(settings)) ...[
              const ActiveLyricsUseAccentTile(),
              const ActiveLyricsIntensityTile(),
            ],
            const LyricsAlignmentTile(),
            const LyricsProviderTile(),
          ],
        ),
        (
          title: l10n.themeGroupFonts,
          tiles: [
            const UseNewFontTile(),
            if (settings.useNewFont) ...[
              const FontFamilySelectionTile(),
              const FontWeightSelectionTile(),
            ],
            const UseNewFontLyricsTile(),
            if (settings.useNewFontLyrics) ...[
              const LyricsFontFamilySelectionTile(),
              const LyricsFontWeightSelectionTile(),
            ],
          ],
        ),
        (title: l10n.themeGroupProfile, tiles: const [SelectAvatarsTile()]),
      ].where((section) => section.tiles.isNotEmpty).toList();
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
        const ShowPlaylistsRowTile(),
        const Divider(height: 1, indent: 72, color: Colors.white10),
        const ReorderDashboardSectionsTile(),
      ];
    } else if (categoryId == 'playback') {
      children = [
        const LanguageTile(),
        if (!UiUtils.isDesktop) ...[
          const Divider(height: 1, indent: 72, color: Colors.white10),
          const FluidPlayerTile(),
        ],
        if (Platform.isAndroid) ...[
          const Divider(height: 1, indent: 72, color: Colors.white10),
          const HapticFeedbackTile(),
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
        const ClearLyricsCacheTile(),
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
        const ImportM3uPlaylistTile(),
        const Divider(height: 1, indent: 72, color: Colors.white10),
        const ExportLogsTile(),
        const Divider(height: 1, indent: 72, color: Colors.white10),
        const ClearLogsTile(),
      ];
    } else if (categoryId == 'about') {
      children = [
        const LooperVersionTile(), //1
        const Divider(height: 1, indent: 72, color: Colors.white10), //2
        Padding(
          //3
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
        const Divider(height: 1, indent: 72, color: Colors.white10), //4
        LyricsCreditsSection(accentColor: Color(settings.accentColor)), //5
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
                      AppHaptics.light();
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
                                AppAssets.logo,
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
                                  AppHaptics.light();
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
                                      AppAssets.github,
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
                        if (ApkInstaller.supported) const CheckForUpdatesTile(),

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
                          child: const MaintainersRow(),
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
                          child: Column(children: children.sublist(2, 5)),
                        ),
                        const SizedBox(height: 120),
                        const OpenSourceLicensesTile(),
                      ]
                    : sections.isNotEmpty
                    ? [
                        for (final section in sections) ...[
                          _SectionHeader(
                            title: section.title,
                            color: Color(settings.accentColor),
                          ),
                          _SettingsCard(
                            useBlur: useBlur,
                            children: [
                              for (final (i, tile)
                                  in section.tiles.indexed) ...[
                                if (i > 0)
                                  const Divider(
                                    height: 1,
                                    indent: 72,
                                    color: Colors.white10,
                                  ),
                                tile,
                              ],
                            ],
                          ),
                        ],
                        const SizedBox(height: 120),
                      ]
                    : [
                        _SettingsCard(useBlur: useBlur, children: children),
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

/// Small accent-colored label above a group of settings.
class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Text(
        title.toUpperCase(),
        style: AppFonts.jostStyle(
          color: color.withValues(alpha: 0.8),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

/// Rounded card holding a list of settings tiles.
class _SettingsCard extends StatelessWidget {
  final bool useBlur;
  final List<Widget> children;

  const _SettingsCard({required this.useBlur, required this.children});

  @override
  Widget build(BuildContext context) {
    return PremiumSection(
      useBlur: useBlur,
      forceNoBlur: true,
      borderRadius: BorderRadius.circular(24),
      useExpanded: false,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}
