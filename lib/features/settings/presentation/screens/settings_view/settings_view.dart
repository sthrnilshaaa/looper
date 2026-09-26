import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/app_links.dart';
import 'package:looper_player/core/providers/providers.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';
import 'package:looper_player/core/utils/responsive.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/android/widgets/premium_section.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:looper_player/ui/widgets/sheets/app_bottom_sheet.dart';

import '../../widgets/settings_widgets.dart';
import '../../widgets/tiles/theme/theme_settings_tiles.dart';
import '../../widgets/tiles/dashboard_settings_tiles.dart';
import '../../widgets/tiles/playback_settings_tiles.dart';
import '../../widgets/tiles/audio_playback_settings_tiles.dart';
import '../../widgets/tiles/library_settings_tiles.dart';
import '../../widgets/tiles/about_settings_tiles.dart';
export '../settings_category_screen.dart';

part 'settings_view.g.dart';
part 'pulsing_heart.dart';
part 'support_us_dialog.dart';
part 'settings_search.dart';
part 'settings_category_group.dart';

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
                        maxWidth:
                            Responsive.isLandscape(MediaQuery.sizeOf(context))
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
}
