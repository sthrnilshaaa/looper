import 'package:looper_player/core/motion/pause_when_offscreen.dart';
import 'package:looper_player/core/motion/looper_scroll_physics.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:looper_player/core/utils/motion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:looper_player/core/services/update/apk_installer.dart';
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
import 'package:looper_player/ui/widgets/common/mochy_card_row.dart';
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
import '../../widgets/lyrics_services_sheet.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import '../account_view.dart';
import '../settings_category_screen.dart';
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
  const SettingsView({super.key, this.selectedCategoryId});

  /// Row shown as selected when a category is open beside this list.
  final String? selectedCategoryId;

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  bool get _isSearching => _searchController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _back() {
    AppHaptics.light();
    if (_isSearching) {
      setState(_searchController.clear);
      _searchFocus.unfocus();
      return;
    }
    ref.read(appNavigationProvider.notifier).goBack();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final useBlur = settings.enableDynamicTheming && !settings.disableBlur;
    final colorScheme = Theme.of(context).colorScheme;

    _CategoryEntry entry(
      String id,
      String title,
      String subtitle,
      IconData icon, [
      String? svg,
    ]) => (id: id, title: title, subtitle: subtitle, icon: icon, svg: svg);

    // Grouped by what the user is trying to do: how it looks, how it
    // sounds, where music comes from, then app chores and info.
    final groups = <List<_CategoryEntry>>[
      [
        if (UiUtils.isDesktop)
          entry(
            'account',
            l10n.account,
            l10n.accountSettings,
            LucideIcons.userRound,
            SettingsIcons.userCircle,
          ),
        entry(
          'theme',
          l10n.catPlayerInterface,
          l10n.catPlayerInterfaceDesc,
          LucideIcons.palette,
          SettingsIcons.palette,
        ),
        entry(
          'now_playing',
          l10n.nowPlaying,
          l10n.nowPlayingSettingsDesc,
          LucideIcons.disc3,
        ),
        entry(
          'lyrics',
          l10n.lyrics,
          l10n.lyricsSettingsDesc,
          LucideIcons.micVocal,
        ),
      ],
      [
        entry(
          'audio_playback',
          l10n.playbackAndAudio,
          l10n.playbackAudioSettingsDesc,
          LucideIcons.audioLines,
        ),
        entry(
          'online',
          l10n.catNetwork,
          l10n.catNetworkDesc,
          LucideIcons.cloud,
        ),
        entry(
          'library',
          l10n.catMusicManagement,
          l10n.catMusicManagementDesc,
          LucideIcons.library,
          SettingsIcons.musicManage,
        ),
      ],
      [
        entry(
          'playback',
          l10n.catMisc,
          l10n.catMiscDesc,
          LucideIcons.settings2,
          SettingsIcons.gesture,
        ),
        entry(
          'about',
          l10n.catAbout,
          l10n.catAboutDesc,
          LucideIcons.info,
          SettingsIcons.info,
        ),
        entry(
          'support_us',
          l10n.supportUs,
          l10n.supportUsDesc,
          LucideIcons.heart,
        ),
      ],
    ];

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
      child: Theme(
        data: settingsTheme(Theme.of(context)),
        child: Material(
          // Desktop embeds this page in the shell, over its artwork background.
          color: UiUtils.isDesktop ? Colors.transparent : colorScheme.surface,
          child: Scaffold(
            backgroundColor: UiUtils.isDesktop
                ? Colors.transparent
                : colorScheme.surface,
            body: SafeArea(
              // In landscape the list is capped to a readable width and
              // centered instead of stretching every tile edge-to-edge.
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Responsive.isLandscape(MediaQuery.sizeOf(context))
                        ? 640
                        : double.infinity,
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
                        child: SettingsHeader(
                          title: l10n.settings,
                          centerTitle: !UiUtils.isDesktop,
                          onBack: UiUtils.isDesktop ? null : _back,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: _SearchField(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          hint: l10n.settingsSearchShort,
                          onChanged: () => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Expanded(
                        child: _isSearching
                            ? _buildSearchResults(context, ref, settings, l10n)
                            : ListView(
                                padding: const EdgeInsets.fromLTRB(
                                  22,
                                  0,
                                  22,
                                  140,
                                ),
                                physics: const LooperScrollPhysics(),
                                children: [
                                  if (UiUtils.isDesktop) ...[
                                    const AccountSummary(),
                                    const SizedBox(height: 17),
                                  ],
                                  for (final group in groups)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 11,
                                      ),
                                      child: SettingsGroupCard(
                                        children: [
                                          for (final e in group)
                                            SettingsNavRow(
                                              icon: e.icon,
                                              title: e.title,
                                              subtitle: e.subtitle,
                                              selected:
                                                  e.id ==
                                                  widget.selectedCategoryId,
                                              onTap: () => _openCategory(
                                                context,
                                                e.id,
                                                e.title,
                                                colorScheme,
                                                useBlur,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

typedef _CategoryEntry = ({
  String id,
  String title,
  String subtitle,
  IconData icon,
  String? svg,
});

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      padding: const EdgeInsets.only(left: 21, right: 8),
      decoration: BoxDecoration(
        color: SettingsCardTint.of(context, kSettingsCard),
        borderRadius: BorderRadius.circular(UiUtils.isDesktop ? 10 : 15),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              cursorColor: Colors.white,
              style: AppFonts.settingsStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppFonts.settingsStyle(
                  color: Colors.white.withValues(alpha: 0.1),
                  fontSize: 16,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          IconButton(
            onPressed: () {
              if (controller.text.isEmpty) {
                focusNode.requestFocus();
              } else {
                controller.clear();
                onChanged();
              }
            },
            icon: controller.text.isEmpty
                ? SvgPicture.asset(SettingsIcons.search, width: 16, height: 15)
                : Icon(
                    LucideIcons.x,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
          ),
        ],
      ),
    );
  }
}
