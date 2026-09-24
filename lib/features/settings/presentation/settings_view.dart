import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:looper_player/core/app_fonts.dart';
import 'package:looper_player/core/app_links.dart';
import 'package:looper_player/core/providers.dart';
import 'package:looper_player/core/navigation_provider.dart';
import 'package:looper_player/core/responsive.dart';
import 'package:looper_player/features/settings/presentation/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/screens/android/widgets/premium_section.dart';
import 'package:looper_player/core/ui_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:looper_player/ui/widgets/app_bottom_sheet.dart';

import 'widgets/settings_widgets.dart';
import 'widgets/theme_settings_tiles.dart';
import 'widgets/dashboard_settings_tiles.dart';
import 'widgets/playback_settings_tiles.dart';
import 'widgets/audio_playback_settings_tiles.dart';
import 'widgets/library_settings_tiles.dart';
import 'widgets/about_settings_tiles.dart';
import 'widgets/backup_logs_settings_tiles.dart';

part 'settings_view.g.dart';

@Riverpod(keepAlive: true)
class SupportUsSheetVisible extends _$SupportUsSheetVisible {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSupportUsDialog(
    BuildContext context,
    ColorScheme colorScheme,
    bool useBlur,
  ) {
    ref.read(supportUsSheetVisibleProvider.notifier).set(true);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black54,
      builder: (context) {
        const coffeeUrl = AppLinks.buyMeACoffee;
        final l10n = AppLocalizations.of(context)!;

        return AppBottomSheetContainer(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(context).padding.bottom + 24,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _PulsingHeart(),
                const SizedBox(height: 16),
                Text(
                  l10n.supportDevelopment,
                  style: AppFonts.jostStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.supportDevelopmentDesc,
                  textAlign: TextAlign.center,
                  style: AppFonts.jostStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFFFFDD00),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFDD00).withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        HapticFeedback.mediumImpact();
                        final upiUri = Uri.parse(AppLinks.upiPay);
                        final webUri = Uri.parse(AppLinks.buyMeACoffee);
                        try {
                          final launched = await launchUrl(
                            upiUri,
                            mode: LaunchMode.externalApplication,
                          );
                          if (!launched) {
                            await launchUrl(
                              webUri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        } catch (_) {
                          try {
                            await launchUrl(
                              webUri,
                              mode: LaunchMode.externalApplication,
                            );
                          } catch (_) {}
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.coffee,
                              size: 20,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              l10n.buyMeCoffee,
                              style: AppFonts.jostStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      ref.read(supportUsSheetVisibleProvider.notifier).set(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final useBlur = settings.enableDynamicTheming && !settings.disableBlur;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          if (ref.read(appNavigationProvider).activeItem == NavItem.settings) {
            ref.read(appNavigationProvider.notifier).goBack();
          }
        }
      },
      // Not Colors.transparent on either widget below - this subtree is
      // reached via a non-opaque PageRoute (_createPremiumRoute) meant to
      // let the black root screen underneath show through, but that
      // compositing isn't reliable on every device/renderer combo (seen as
      // a white/native-window-background flash on some devices). Painting
      // an explicit opaque background here removes the dependency on that
      // compositing entirely.
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: Column(
              children: [
                // Header title / Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _isSearching
                        ? Row(
                            key: const ValueKey('searching_header'),
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
                                useExpanded: false,
                                forceNoBlur: true,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    _isSearching = false;
                                    _searchController.clear();
                                  });
                                },
                                child: const Icon(
                                  LucideIcons.arrowLeft,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.06),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      bottomLeft: Radius.circular(10),
                                      topRight: Radius.circular(32),
                                      bottomRight: Radius.circular(32),
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.08,
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    child: TextField(
                                      controller: _searchController,
                                      autofocus: true,
                                      style: AppFonts.jostStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: l10n.searchSettingsHint,
                                        hintStyle: AppFonts.jostStyle(
                                          color: Colors.white38,
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                        suffixIcon:
                                            _searchController.text.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(
                                                  LucideIcons.x,
                                                  color: Colors.white70,
                                                  size: 18,
                                                ),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                                onPressed: () {
                                                  _searchController.clear();
                                                  setState(() {});
                                                },
                                              )
                                            : null,
                                      ),
                                      onChanged: (val) {
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            key: const ValueKey('standard_header'),
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
                                  ref
                                      .read(appNavigationProvider.notifier)
                                      .goBack();
                                },
                                child: const Icon(
                                  LucideIcons.arrowLeft,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              Text(
                                l10n.settings,
                                style: AppFonts.jostStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              PremiumSection(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  bottomLeft: Radius.circular(10),
                                  topRight: Radius.circular(32),
                                  bottomRight: Radius.circular(32),
                                ),
                                width: 48,
                                height: 48,
                                useExpanded: false,
                                forceNoBlur: true,
                                useBlur: useBlur,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    _isSearching = true;
                                  });
                                },
                                child: const Icon(
                                  LucideIcons.search,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                // Settings Body
                //
                // In landscape the list is capped to a readable width and
                // centered instead of stretching every settings tile
                // edge-to-edge across the whole window.
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: Responsive.isLandscape(MediaQuery.sizeOf(context))
                            ? 640
                            : double.infinity,
                      ),
                      child: _isSearching
                          ? _buildSearchResults(context, ref, settings, l10n)
                          : ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          physics: const BouncingScrollPhysics(),
                          children: [
                            // 1. Theme & Appearance
                            _buildCategoryGroup(
                              context: context,
                              id: 'theme',
                              title: l10n.theme,
                              subtitle: l10n.customizeColorsTheme,
                              icon: LucideIcons.palette,
                              colorScheme: Theme.of(context).colorScheme,
                              useBlur: useBlur,
                              settings: settings,
                            ),

                            // 2. Home Screen Customization
                            _buildCategoryGroup(
                              context: context,
                              id: 'dashboard',
                              title: l10n.homeDashboardSettings,
                              subtitle: l10n.homeDashboardSettingsDesc,
                              icon: LucideIcons.layout,
                              colorScheme: Theme.of(context).colorScheme,
                              useBlur: useBlur,
                              settings: settings,
                            ),

                            // 3. Playback & Language
                            _buildCategoryGroup(
                              context: context,
                              id: 'playback',
                              title: l10n.playbackAudio,
                              subtitle: l10n.manageLanguageAndFocus,
                              icon: LucideIcons.playCircle,
                              colorScheme: Theme.of(context).colorScheme,
                              useBlur: useBlur,
                              settings: settings,
                            ),

                            // 4. Audio & Playback
                            _buildCategoryGroup(
                              context: context,
                              id: 'audio_playback',
                              title: l10n.audioPlayback,
                              subtitle: l10n.audioPlaybackDesc,
                              icon: LucideIcons.music,
                              colorScheme: Theme.of(context).colorScheme,
                              useBlur: useBlur,
                              settings: settings,
                            ),

                            // 5. Music Library
                            _buildCategoryGroup(
                              context: context,
                              id: 'library',
                              title: l10n.musicLibrary,
                              subtitle: l10n.libraryFoldersSync,
                              icon: LucideIcons.database,
                              colorScheme: Theme.of(context).colorScheme,
                              useBlur: useBlur,
                              settings: settings,
                            ),

                            // 6. Backups & Logs
                            _buildCategoryGroup(
                              context: context,
                              id: 'backups_logs',
                              title: l10n.backupsAndLogs,
                              subtitle: l10n.backupsAndLogsDesc,
                              icon: LucideIcons.databaseBackup,
                              colorScheme: Theme.of(context).colorScheme,
                              useBlur: useBlur,
                              settings: settings,
                            ),

                            // 7. About & Creators
                            _buildCategoryGroup(
                              context: context,
                              id: 'about',
                              title: l10n.aboutAndMaintainers,
                              subtitle: l10n.appDetailsCreator,
                              icon: LucideIcons.info,
                              colorScheme: Theme.of(context).colorScheme,
                              useBlur: useBlur,
                              settings: settings,
                            ),

                            // 7. Support Us
                            _buildCategoryGroup(
                              context: context,
                              id: 'support_us',
                              title: l10n.supportUs,
                              subtitle: l10n.supportUsDesc,
                              icon: LucideIcons.heart,
                              colorScheme: Theme.of(context).colorScheme,
                              useBlur: useBlur,
                              settings: settings,
                            ),

                            const SizedBox(
                              height: 140,
                            ), // Bottom breathing room for expanded player bar
                          ],
                        ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGroup({
    required BuildContext context,
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required ColorScheme colorScheme,
    required bool useBlur,
    required AppSettings settings,
  }) {
    return Column(
      children: [
        PremiumSection(
          useBlur: useBlur,
          forceNoBlur: true,
          borderRadius: BorderRadius.circular(20),
          useExpanded: false,
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              if (id == 'support_us') {
                _showSupportUsDialog(context, colorScheme, useBlur);
                return;
              }
              // Routed through appNavigationProvider (not a raw Navigator
              // push) so the sub-page is tracked in nav history -- otherwise
              // the system back button's PopScope handler (which always
              // resolves through appNavigationProvider.goBack()) has no
              // record of this level and collapses straight past both this
              // screen and Settings back to the main tab in one shot.
              ref
                  .read(appNavigationProvider.notifier)
                  .showSettingsCategory(id: id, title: title);
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(
                        settings.accentColor,
                      ).withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: Color(settings.accentColor),
                      size: 20.s,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppFonts.jostStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: AppFonts.jostStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    color: Colors.white.withValues(alpha: 0.4),
                    size: 18.s,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

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
              'No settings found for "$query"',
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
          title: 'Dynamic Accent Color',
          subtitle: 'Update only the accent color dynamically from the artwork',
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
            subtitle: 'Choose quick accent colors',
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
          title: 'Blurred Artwork for Lyrics',
          subtitle:
              'Show blurred album art as background instead of dynamic/static gradient',
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
          title: l10n.keepBackgroundGradient,
          subtitle: l10n.keepBackgroundGradientDesc,
          category: l10n.theme,
          widget: const KeepBackgroundGradientTile(),
        ),
      SettingsSearchItem(
        title: 'Use Custom Font',
        subtitle: 'Use Jost or other custom fonts. Otherwise, DM Sans is used.',
        category: l10n.theme,
        widget: const UseNewFontTile(),
      ),
      if (settings.useNewFont) ...[
        SettingsSearchItem(
          title: 'Select Font Family',
          subtitle: 'Active font: ${settings.customFontFamily}',
          category: l10n.theme,
          widget: const FontFamilySelectionTile(),
        ),
        SettingsSearchItem(
          title: 'Font Weight',
          subtitle: 'Change base weight of custom font',
          category: l10n.theme,
          widget: const FontWeightSelectionTile(),
        ),
      ],
      SettingsSearchItem(
        title: 'Use Custom Font for Lyrics',
        subtitle: 'Use custom font and weight for synchronized lyrics view',
        category: l10n.theme,
        widget: const UseNewFontLyricsTile(),
      ),
      if (settings.useNewFontLyrics) ...[
        SettingsSearchItem(
          title: 'Lyrics Font Family',
          subtitle: 'Active lyrics font: ${settings.customFontFamilyLyrics}',
          category: l10n.theme,
          widget: const LyricsFontFamilySelectionTile(),
        ),
        SettingsSearchItem(
          title: 'Lyrics Font Weight',
          subtitle:
              'Lyrics font weight: ${700 + settings.activeLyricsFontWeightDelta * 100}',
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
        subtitle: 'Select application language',
        category: l10n.playbackAudio,
        widget: const LanguageTile(),
      ),
      if (!Platform.isLinux)
        SettingsSearchItem(
          title: 'Vertical Motion Effect Player',
          subtitle: 'Swipe down on the expanded player to dismiss it',
          category: l10n.playbackAudio,
          widget: const VerticalMotionEffectTile(),
        ),
      SettingsSearchItem(
        title: 'Equalizer',
        subtitle: 'Adjust 18-band equalizer and audio presets',
        category: l10n.playbackAudio,
        widget: const EqualizerTile(),
      ),
      if (Platform.isAndroid)
        SettingsSearchItem(
          title: 'Stop Service on App Dismissal',
          subtitle:
              'Stop playback and close the app when swiped away from recent panel',
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
        subtitle: 'Scan a new folder for audio files',
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
        title: 'Include other device audio',
        subtitle: 'Ringtones, notifications and messaging audio',
        category: l10n.musicLibrary,
        widget: const IncludeSystemAndMessagingAudioTile(),
      ),
      SettingsSearchItem(
        title: 'Excluded Folders',
        subtitle: 'Skip specific folders when scanning',
        category: l10n.musicLibrary,
        widget: const ExcludedFoldersTile(),
      ),
      SettingsSearchItem(
        title: l10n.resetLibrary,
        subtitle: 'Clear library data',
        category: l10n.musicLibrary,
        widget: const ResetLibraryTile(),
      ),

      // About
      SettingsSearchItem(
        title: 'Looper Player Version',
        subtitle: 'Version ${ref.watch(appVersionProvider).value ?? ""}'.trim(),
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
          const KeepBackgroundGradientTile(),
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
          const VerticalMotionEffectTile(),
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

class _PulsingHeart extends StatefulWidget {
  const _PulsingHeart();

  @override
  State<_PulsingHeart> createState() => _PulsingHeartState();
}

class _PulsingHeartState extends State<_PulsingHeart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.redAccent.withValues(alpha: 0.1),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withValues(alpha: 0.2),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(LucideIcons.heart, color: Colors.redAccent, size: 32),
      ),
    );
  }
}
