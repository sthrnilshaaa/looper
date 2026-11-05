import 'package:looper_player/core/motion/looper_scroll_physics.dart';
import 'dart:io';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:looper_player/core/utils/motion.dart';
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
    // Options that only apply while a parent option is on sit indented
    // under it (see _SubGroup).
    _SubGroup sub(bool visible, List<Widget> tiles) =>
        _SubGroup(visible: visible, accent: settings.accent, children: tiles);
    if (categoryId == 'theme') {
      final dynamicTheming = settings.enableDynamicTheming;
      sections = [
        (
          title: l10n.themeGroupColors,
          tiles: [
            const DynamicThemingTile(),
            sub(!dynamicTheming, [
              const DynamicAccentColorTile(),
              sub(!settings.dynamicAccentColor, const [
                AccentColorTile(),
                CustomAccentColorTile(),
              ]),
              const PureBlackOledTile(),
            ]),
            const AccentVibrancyTile(),
          ],
        ),
        (
          title: l10n.themeGroupBlurBackgrounds,
          tiles: [
            if (dynamicTheming)
              const DisableBlurTile()
            else
              const AlwaysBlurSheetsTile(),
            const EnablePlayerGradientTile(),
            sub(settings.enablePlayerGradient, [
              const AnimatePlayerGradientTile(),
              const KeepBackgroundGradientTile(),
              sub(settings.keepBackgroundGradient, const [
                AnimateBackgroundGradientTile(),
              ]),
            ]),
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
          ],
        ),
        (
          title: l10n.themeGroupFonts,
          tiles: [
            // Desktop has its own UI scale row in its settings view.
            if (!UiUtils.isDesktop) const UiScaleTile(),
            const UseNewFontTile(),
            sub(settings.useNewFont, const [
              FontFamilySelectionTile(),
              FontWeightSelectionTile(),
            ]),
            const UseNewFontLyricsTile(),
            sub(settings.useNewFontLyrics, const [
              LyricsFontFamilySelectionTile(),
              LyricsFontWeightSelectionTile(),
            ]),
          ],
        ),
      ];
    } else if (categoryId == 'now_playing') {
      sections = [
        (
          title: l10n.sectionPlayer,
          tiles: [
            if (!UiUtils.isDesktop) const FluidPlayerTile(),
            const SegmentedUtilityButtonsTile(),
          ],
        ),
        (
          title: l10n.sectionSeekBarVisuals,
          tiles: const [
            ProgressBarStyleTile(),
            PlainTimestampsTile(),
            ArtworkVisualizerTile(),
          ],
        ),
        (
          title: l10n.sectionTrackInfo,
          tiles: [
            const ShowQualityBadgeTile(),
            sub(settings.showQualityBadge, const [QualityBadgeStyleTile()]),
          ],
        ),
        (
          title: l10n.sectionLyricLine,
          tiles: [
            const PlayerLyricLineTile(),
            sub(settings.playerLyricLine, const [
              PlayerLyricLineTransitionTile(),
            ]),
          ],
        ),
      ];
    } else if (categoryId == 'lyrics') {
      sections = [
        (
          title: l10n.sectionLook,
          tiles: [
            const DynamicColorActiveLyricsTile(),
            sub(!activeLyricsIsWhite(settings), const [
              ActiveLyricsUseAccentTile(),
              ActiveLyricsIntensityTile(),
            ]),
            const InactiveLyricsOpacityTile(),
            const LyricsAlignmentTile(),
            const LyricsLineGroupingTile(),
          ],
        ),
        (
          title: l10n.sectionBackground,
          tiles: [
            const AmbientLyricsBgTile(),
            const BlurredArtworkLyricsTile(),
            if (settings.enableDynamicTheming ||
                settings.ambientColorBackground ||
                settings.keepBackgroundGradient ||
                settings.blurredArtworkForLyrics)
              const LyricsDarknessSlider(),
          ],
        ),
        (
          title: l10n.sectionSources,
          tiles: const [
            LyricsProviderTile(),
            SyncLyricsOfflineTile(),
            ClearLyricsCacheTile(),
          ],
        ),
      ];
    } else if (categoryId == 'library') {
      sections = [
        (
          title: l10n.sectionHomeRows,
          tiles: const [
            ShowArtistsRowTile(),
            ShowAlbumsRowTile(),
            ShowGenresRowTile(),
            ShowRecentRowTile(),
            ShowPlaylistsRowTile(),
            ReorderDashboardSectionsTile(),
          ],
        ),
        (
          title: l10n.sectionDisplay,
          tiles: [
            const GroupArtistByAlbumTile(),
            const ShowAlbumNextToArtistTile(),
            sub(settings.showAlbumNextToArtist, const [
              ShowAlbumInQuickPicksTile(),
            ]),
          ],
        ),
        (
          title: l10n.sectionFolders,
          tiles: const [
            LibraryFoldersList(),
            AddFolderTile(),
            ExcludedFoldersTile(),
            IncludeSystemAndMessagingAudioTile(),
            RescanLibraryTile(),
            ResetLibraryTile(),
          ],
        ),
      ];
    } else if (categoryId == 'audio_playback') {
      sections = [
        (
          title: l10n.sectionSound,
          tiles: [
            const EqualizerTile(),
            const FadePlayPauseStopTile(),
            sub(settings.fadePlayPauseStop, const [FadeDurationSlider()]),
          ],
        ),
        (
          title: l10n.queue,
          tiles: [
            const ShuffleTile(),
            const PersistQueueTile(),
            const KeepSongProgressTile(),
            if (!Platform.isAndroid) const ResumeOnStartTile(),
          ],
        ),
        if (Platform.isAndroid)
          (
            title: l10n.sectionInterruptions,
            tiles: [
              const ManageAudioFocusTile(),
              sub(settings.audioFocus, const [
                ResumeAfterCallTile(),
                ResumeOnBluetoothConnectTile(),
              ]),
              const ResumeOnStartTile(),
            ],
          ),
      ];
    } else if (categoryId == 'playback') {
      // "General".
      sections = [
        (
          title: l10n.sectionApp,
          tiles: [
            const LanguageTile(),
            if (Platform.isAndroid) ...[
              const HapticFeedbackTile(),
              const StopServiceTile(),
            ],
          ],
        ),
        (
          title: l10n.sectionInternet,
          tiles: const [InternetModeTile(), DownloadMissingArtworkTile()],
        ),
        (title: l10n.themeGroupProfile, tiles: const [SelectAvatarsTile()]),
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
                  color: settings.accent.withValues(alpha: 0.8),
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
        LyricsCreditsSection(accentColor: settings.accent), //5
      ];
    }

    // A section whose options all depend on something that's off.
    sections = [
      for (final section in sections)
        if (section.tiles.isNotEmpty) section,
    ];

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
                physics: const LooperScrollPhysics(),
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
                            color: settings.accent,
                          ),
                          _SettingsCard(
                            useBlur: useBlur,
                            children: [
                              for (final (i, tile)
                                  in section.tiles.indexed) ...[
                                if (i > 0 && tile is! _SubGroup)
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

/// Options that only apply while the option above them is on: indented
/// under it with an accent rail, sliding open and shut with it.
class _SubGroup extends StatelessWidget {
  final bool visible;
  final Color accent;
  final List<Widget> children;

  const _SubGroup({
    required this.visible,
    required this.accent,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: Duration(milliseconds: Motion.reducedOf(context) ? 0 : 260),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: !visible
          ? const SizedBox(width: double.infinity)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(height: 1, indent: 72, color: Colors.white10),
                Container(
                  margin: const EdgeInsets.only(left: 18),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: accent.withValues(alpha: 0.45),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final (i, tile) in children.indexed) ...[
                        if (i > 0 && tile is! _SubGroup)
                          const Divider(
                            height: 1,
                            indent: 44,
                            color: Colors.white10,
                          ),
                        tile,
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
