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
import '../widgets/settings_previews.dart';
import '../widgets/tiles/theme/theme_settings_tiles.dart';
import '../widgets/tiles/dashboard_settings_tiles.dart';
import '../widgets/tiles/playback_settings_tiles.dart';
import '../widgets/tiles/audio_playback_settings_tiles.dart';
import '../widgets/tiles/library_settings_tiles.dart';
import '../widgets/tiles/about_settings_tiles.dart';
import '../widgets/tiles/backup_logs_settings_tiles.dart';
import 'package:looper_player/core/theme/app_assets.dart';
import 'account_view.dart';
import 'package:looper_player/ui/widgets/common/setup_kit.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/features/playback/data/crossmix/crossmix_settings.dart';

class SettingsCategoryScreen extends ConsumerWidget {
  final String categoryId;
  final String title;

  /// False when shown beside the settings list, where no Back is needed.
  final bool showBack;

  const SettingsCategoryScreen({
    super.key,
    required this.categoryId,
    required this.title,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final crossmix = ref.watch(crossmixSettingsProvider);
    final l10n = AppLocalizations.of(context)!;
    final useBlur = settings.enableDynamicTheming && !settings.disableBlur;

    List<Widget> children = [];
    // Theme is split into titled cards; other categories use one card.
    List<({String title, List<Widget> tiles})> sections = [];
    // Section titles that start folded to keep long pages compact.
    var collapsed = <String>{};
    // Options that only apply while a parent option is on sit indented
    // under it (see _SubGroup).
    _SubGroup sub(bool visible, List<Widget> tiles) =>
        _SubGroup(visible: visible, children: tiles);
    // Long-press shows a looping demo of what the toggle does.
    Widget demo(SettingsDemoKind kind, Widget tile) =>
        SettingsDemo(kind: kind, accent: settings.accent, child: tile);
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
            else ...[
              const AlwaysBlurSheetsTile(),
              const FrostedMusicBarTile(),
              const FrostedNavbarTile(),
            ],
            const NewNavbarTile(),
            const StatusBarBlurTile(),
            // Dynamic theming paints its own background.
            if (!dynamicTheming) ...[
              demo(
                SettingsDemoKind.gradient,
                const KeepBackgroundGradientTile(),
              ),
              sub(settings.keepBackgroundGradient, const [
                AnimateBackgroundGradientTile(),
              ]),
            ],
            if (dynamicTheming || settings.keepBackgroundGradient)
              const HomeDarknessSlider(),
            if (dynamicTheming && UiUtils.isDesktop)
              const DesktopBackgroundDarknessSlider(),
            if (dynamicTheming) ...[
              const SongsDarknessSlider(),
              const LibraryDarknessSlider(),
            ],
          ],
        ),
        (
          title: l10n.sectionDisplay,
          tiles: [
            if (Platform.isAndroid) const HighRefreshRateTile(),
            const GroupArtistByAlbumTile(),
            const ShowAlbumNextToArtistTile(),
            sub(settings.showAlbumNextToArtist, const [
              ShowAlbumInQuickPicksTile(),
            ]),
          ],
        ),
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
          title: l10n.themeGroupFonts,
          tiles: [
            const UiScaleTile(),
            const LetterSpacingTile(),
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
      collapsed = {l10n.themeGroupFonts, l10n.sectionHomeRows};
    } else if (categoryId == 'now_playing') {
      // Desktop has no style picker, so it is always the classic layout.
      final classic =
          UiUtils.isDesktop ||
          settings.playerStyle.isEmpty ||
          settings.playerStyle == 'classic';
      // Arc / linear / card draw their own blurred background and show lyrics from
      // the player menu, so the classic background and line options don't
      // apply there. Dynamic background and the gradient are alternatives:
      // while one is on, the other is hidden.
      final dynamicBg = settings.playerDynamicBackground;
      final gradient = settings.enablePlayerGradient;
      sections = [
        (
          title: l10n.sectionPlayer,
          tiles: [
            if (!UiUtils.isDesktop) const FluidPlayerTile(),
            if (!UiUtils.isDesktop) const PlayerStyleTile(),
            if (classic) ...[
              if (!settings.enableDynamicTheming && (dynamicBg || !gradient))
                const PlayerDynamicBackgroundTile(),
              demo(SettingsDemoKind.lyricLine, const PlayerLyricLineTile()),
              sub(settings.playerLyricLine, const [
                PlayerLyricLineTransitionTile(),
              ]),
            ],
            if (!UiUtils.isDesktop) const KeepScreenAwakeTile(),
          ],
        ),
        if (classic) ...[
          (
            title: l10n.sectionClassicLayout,
            tiles: [
              demo(
                SettingsDemoKind.segmentedButtons,
                const SegmentedUtilityButtonsTile(),
              ),
              if (UiUtils.isDesktop) const FlatProgressBarTile(),
              const ProgressBarStyleTile(),
              const PlainTimestampsTile(),
              const ArtworkVisualizerTile(),
              const ShowQualityBadgeTile(),
              sub(settings.showQualityBadge, const [QualityBadgeStyleTile()]),
            ],
          ),
          if (settings.enableDynamicTheming || !dynamicBg)
            (
              title: l10n.sectionPlayerBackground,
              tiles: [
                demo(
                  SettingsDemoKind.gradient,
                  const EnablePlayerGradientTile(),
                ),
                sub(gradient, const [AnimatePlayerGradientTile()]),
                if (settings.enableDynamicTheming || gradient)
                  const MusicDarknessSlider(),
              ],
            ),
        ],
      ];
    } else if (categoryId == 'lyrics') {
      sections = [
        (
          title: l10n.sectionLook,
          tiles: [
            const DynamicColorActiveLyricsTile(),
            sub(!activeLyricsIsWhite(settings), const [
              ActiveLyricsIntensityTile(),
            ]),
            // White line: no slider, but still show how it looks.
            if (activeLyricsIsWhite(settings)) const ActiveLyricsPreview(),
            const InactiveLyricsOpacityTile(),
            const LyricsAlignmentTile(),
            const LyricsLineGroupingTile(),
            if (UiUtils.isDesktop) const LyricsSizeTile(),
          ],
        ),
        (
          title: l10n.sectionBackground,
          tiles: [
            const LyricsFollowPlayerBackgroundTile(),
            if (settings.lyricsOwnBackground) ...[
              demo(SettingsDemoKind.gradient, const EnableLyricsGradientTile()),
              sub(settings.enableLyricsGradient, const [
                AnimatePlayerGradientTile(),
                AmbientLyricsBgTile(),
              ]),
              const BlurredArtworkLyricsTile(),
            ],
            // Following the player uses Music Darkness instead.
            if (settings.lyricsOwnBackground &&
                (settings.enableDynamicTheming ||
                    settings.ambientColorBackground ||
                    settings.keepBackgroundGradient ||
                    settings.blurredArtworkForLyrics ||
                    settings.enableLyricsGradient))
              const LyricsDarknessSlider(),
          ],
        ),
      ];
    } else if (categoryId == 'library') {
      sections = [
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
        (title: l10n.playlists, tiles: const [ImportM3uPlaylistTile()]),
      ];
    } else if (categoryId == 'audio_playback') {
      sections = [
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
        (
          title: l10n.sectionSound,
          tiles: [
            const EqualizerTile(),
            demo(SettingsDemoKind.fade, const FadePlayPauseStopTile()),
            sub(settings.fadePlayPauseStop, const [FadeDurationSlider()]),
            demo(SettingsDemoKind.crossfade, const CrossfadeTile()),
            sub(crossmix.crossfadeEnabled, const [
              CrossfadeDurationSlider(),
              SmartTransitionsTile(),
              BeatMixingTile(),
            ]),
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
      ];
    } else if (categoryId == 'online') {
      sections = [
        (
          title: l10n.sectionInternet,
          tiles: const [InternetModeTile(), DownloadMissingArtworkTile()],
        ),
        (
          title: l10n.sectionSources,
          tiles: const [LyricsProviderTile(), SyncLyricsOfflineTile()],
        ),
      ];
    } else if (categoryId == 'playback') {
      // "Miscellaneous".
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
        (title: l10n.sectionStorage, tiles: [const ClearLyricsCacheTile()]),
        (
          title: l10n.sectionBackupRestore,
          tiles: const [
            ExportBackupTile(),
            ImportBackupTile(),
            ExportLogsTile(),
            ClearLogsTile(),
          ],
        ),
      ];
    } else if (categoryId == 'account') {
      sections = [
        (
          title: l10n.accountProfile,
          tiles: const [
            ProfilePhotoTile(),
            HeaderProfilePhotoTile(),
            AccountNameTile(),
            SelectAvatarsTile(),
          ],
        ),
      ];
    } else if (categoryId == 'about') {
      children = [
        const LooperVersionTile(), //1
        const Divider(
          height: 1,
          indent: 20,
          endIndent: 20,
          color: kSettingsDivider,
        ), //2
        Padding(
          //3
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.appInfoPrivacy.toUpperCase(),
                style: AppFonts.settingsStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),
              InfoSubTile(
                icon: LucideIcons.music,
                title: l10n.corePurpose,
                description: l10n.corePurposeDesc,
              ),
              if (!UiUtils.isDesktop) ...[
                const SizedBox(height: 16),
                InfoSubTile(
                  icon: LucideIcons.shieldCheck,
                  title: l10n.whyPermissionsUsed,
                  description: l10n.whyPermissionsUsedDesc,
                ),
              ],
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
        const Divider(
          height: 1,
          indent: 20,
          endIndent: 20,
          color: kSettingsDivider,
        ), //4
        LyricsCreditsSection(accentColor: Colors.white), //5
      ];
    }

    if (UiUtils.isDesktop) {
      sections = [
        for (final section in sections)
          (
            title: section.title,
            tiles: [for (final tile in section.tiles) ?_desktopTile(tile)],
          ),
      ];
    }

    // A section whose options all depend on something that's off.
    sections = [
      for (final section in sections)
        if (section.tiles.isNotEmpty) section,
    ];

    return Theme(
      data: settingsTheme(Theme.of(context)),
      child: Scaffold(
        // See the comment on the main SettingsView's Scaffold above - same
        // reasoning applies here. Desktop sits over the shell's background.
        backgroundColor: UiUtils.isDesktop
            ? Colors.transparent
            : Theme.of(context).colorScheme.surface,
        body: _aboutBackground(
          categoryId == 'about',
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
                  child: SettingsHeader(
                    title: title,
                    onBack: !showBack
                        ? null
                        : () {
                            AppHaptics.light();
                            // Go through appNavigationProvider (not a raw
                            // Navigator pop) so its logical history stays in
                            // sync with the physical route stack -- see
                            // showSettingsCategory's call site for why that
                            // matters for the back button.
                            ref.read(appNavigationProvider.notifier).goBack();
                          },
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22.0,
                      vertical: 4.0,
                    ),
                    physics: const LooperScrollPhysics(),
                    children: categoryId == 'about'
                        ? [
                            const SizedBox(height: 20),
                            const AboutHeroCard(),
                            const SizedBox(height: 13),
                            const IntrinsicHeight(
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 176,
                                    child: AboutMaintainersCard(),
                                  ),
                                  SizedBox(width: 18),
                                  Expanded(flex: 164, child: AboutStarsCard()),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            const AboutSocialsCard(),
                            if (ApkInstaller.supported) ...[
                              const SizedBox(height: 14),
                              const CheckForUpdatesTile(card: true),
                            ],
                            const SizedBox(height: 14),
                            AboutLicensesPrivacyCard(
                              content: [
                                ...children.sublist(2),
                                const Divider(
                                  height: 1,
                                  indent: 20,
                                  endIndent: 20,
                                  color: kSettingsDivider,
                                ),
                                const OpenSourceLicensesTile(),
                              ],
                            ),
                            const SizedBox(height: 120),
                          ]
                        : sections.isNotEmpty
                        ? [
                            for (final section in sections)
                              _Section(
                                // Keyed by title so fold state survives the
                                // list changing above it.
                                key: ValueKey(section.title),
                                title: section.title,
                                collapsible: collapsed.contains(section.title),
                                children: [
                                  for (final (i, tile)
                                      in section.tiles.indexed) ...[
                                    if (i > 0 && tile is! _SubGroup)
                                      const Divider(
                                        height: 1,
                                        indent: 20,
                                        endIndent: 20,
                                        color: kSettingsDivider,
                                      ),
                                    tile,
                                  ],
                                ],
                              ),
                            const SizedBox(height: 120),
                          ]
                        : [
                            _SettingsCard(children: children),
                            const SizedBox(height: 120),
                          ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Android-only options: what they change isn't part of the desktop UI.
const _androidOnlyTiles = <Type>{
  AlwaysBlurSheetsTile,
  FrostedMusicBarTile,
  FrostedNavbarTile,
  NewNavbarTile,
  StatusBarBlurTile,
  AnimateBackgroundGradientTile,
  HomeDarknessSlider,
  SongsDarknessSlider,
  LibraryDarknessSlider,
  ShowAlbumInQuickPicksTile,
  ShowAlbumsRowTile,
  ReorderDashboardSectionsTile,
  PlayerStyleTile,
  PlayerDynamicBackgroundTile,
  PlayerLyricLineTile,
  PlayerLyricLineTransitionTile,
  SegmentedUtilityButtonsTile,
  ProgressBarStyleTile,
  ArtworkVisualizerTile,
  ShowQualityBadgeTile,
  QualityBadgeStyleTile,
  EnablePlayerGradientTile,
  AnimatePlayerGradientTile,
  MusicDarknessSlider,
  EnableLyricsGradientTile,
  AmbientLyricsBgTile,
  BlurredArtworkLyricsTile,
  LyricsDarknessSlider,
};

bool isAndroidOnlySetting(Widget tile) =>
    _androidOnlyTiles.contains(tile.runtimeType);

/// [tile] without its Android-only options, or null if none are left.
Widget? _desktopTile(Widget tile) {
  if (isAndroidOnlySetting(tile)) return null;
  if (tile is SettingsDemo && isAndroidOnlySetting(tile.child)) return null;
  if (tile is _SubGroup) {
    final kept = [for (final child in tile.children) ?_desktopTile(child)];
    return kept.isEmpty
        ? null
        : _SubGroup(visible: tile.visible, children: kept);
  }
  return tile;
}

/// Titled card of settings. A collapsible one starts folded; tapping the
/// title (or chevron) opens and shuts it.
class _Section extends StatefulWidget {
  final String title;
  final bool collapsible;
  final List<Widget> children;

  const _Section({
    super.key,
    required this.title,
    required this.collapsible,
    required this.children,
  });

  @override
  State<_Section> createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  late bool _open = !widget.collapsible;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      widget.title,
      style: AppFonts.settingsStyle(
        color: Colors.white.withValues(alpha: 0.7),
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
    final reduced = Motion.reducedOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.collapsible)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 14),
            child: label,
          )
        else
          Semantics(
            button: true,
            expanded: _open,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                AppHaptics.selection();
                setState(() => _open = !_open);
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 4, 14),
                child: Row(
                  children: [
                    Expanded(child: label),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: Duration(milliseconds: reduced ? 0 : 220),
                      child: Icon(
                        LucideIcons.chevronDown,
                        size: 18,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        AnimatedSize(
          duration: Duration(milliseconds: reduced ? 0 : 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _open
              ? _SettingsCard(children: widget.children)
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Rounded neutral card holding a list of settings tiles.
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({this.children = const []});

  @override
  Widget build(BuildContext context) {
    // Material (not a decorated Container) so tile ripples paint on the card.
    return Material(
      color: SettingsCardTint.of(context, kSettingsCard),
      borderRadius: BorderRadius.circular(UiUtils.isDesktop ? 10 : 15),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

/// Options that only apply while the option above them is on: indented
/// under it with an accent rail, sliding open and shut with it.
class _SubGroup extends StatelessWidget {
  final bool visible;
  final List<Widget> children;

  const _SubGroup({required this.visible, required this.children});

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
                const Divider(
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                  color: kSettingsDivider,
                ),
                Container(
                  margin: const EdgeInsets.only(left: 18),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: Colors.white.withValues(alpha: 0.12),
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
                            indent: 20,
                            endIndent: 20,
                            color: kSettingsDivider,
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

/// About wears the setup flow's animated logo backdrop.
Widget _aboutBackground(bool about, Widget child) =>
    about && !UiUtils.isDesktop ? SetupBackground(child: child) : child;
