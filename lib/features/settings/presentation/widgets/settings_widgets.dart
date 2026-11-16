import 'package:looper_player/core/utils/desktop_paths.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:looper_player/features/library/data/services/saf_folder_service.dart';
import 'package:looper_player/features/library/presentation/providers/library/library_notifier.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/l10n.dart';
import 'package:looper_player/core/theme/app_assets.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/utils/motion.dart';

class ColorCircle extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const ColorCircle({
    super.key,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AppHaptics.light();
        onTap();
      },
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.white, width: 2)
              : Border.all(color: Colors.white24, width: 1),
        ),
      ),
    );
  }
}

class MaintainerTile extends StatelessWidget {
  final String name;
  final String role;
  final String avatar;
  final String github;
  final String telegram;

  const MaintainerTile({
    super.key,
    required this.name,
    required this.role,
    required this.avatar,
    required this.github,
    required this.telegram,
  });

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {}
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white10,
        backgroundImage: AssetImage(avatar),
      ),
      title: Text(
        name,
        style: AppFonts.settingsStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        role,
        style: AppFonts.settingsStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: SvgPicture.asset(
              AppAssets.github,
              width: 18,
              height: 18,
              colorFilter: const ColorFilter.mode(
                Colors.white54,
                BlendMode.srcIn,
              ),
            ),
            onPressed: () => _launchUrl(github),
          ),
          IconButton(
            icon: const Icon(LucideIcons.send, size: 18, color: Colors.white54),
            onPressed: () => _launchUrl(telegram),
          ),
        ],
      ),
    );
  }
}

class LibraryFoldersList extends ConsumerWidget {
  const LibraryFoldersList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(settingsProvider).libraryFolders;

    if (folders.isEmpty) {
      return ListTile(
        leading: Icon(LucideIcons.folderSearch, color: Colors.white38),
        title: Text(
          context.l10n.noIndexedFoldersYet,
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
        subtitle: Text(
          context.l10n.noIndexedFoldersYetDesc,
          style: TextStyle(color: Colors.white38, fontSize: 11),
        ),
      );
    }

    return Column(
      children: folders
          .map(
            (path) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: const Icon(LucideIcons.folder),
              title: Text(
                displayFileName(path),
                style: AppFonts.settingsStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                path,
                style: AppFonts.settingsStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(
                  LucideIcons.x,
                  size: 16,
                  color: Colors.white60,
                ),
                onPressed: () async {
                  if (Platform.isAndroid) {
                    SafFolderService.releaseFolder(path);
                  }
                  final newFolders = List<String>.from(folders)..remove(path);
                  await ref
                      .read(settingsProvider.notifier)
                      .updateLibraryFolders(newFolders);
                  // Also records it as excluded, not just dropped from this
                  // list - otherwise MediaStore's device-wide index (merged
                  // into every scan regardless of which folder was
                  // requested) would just rediscover these same songs and
                  // re-add the folder on the very next refresh. This also
                  // deletes the folder's already-indexed songs immediately,
                  // instead of waiting for a scan to notice they're gone.
                  await ref.read(excludedFoldersProvider.notifier).add(path);
                },
              ),
            ),
          )
          .toList(),
    );
  }
}

/// A slider row that reads like a toggle row: the value sits in a pill on
/// the right, and tapping the row slides the track open below it.
class SettingsSliderTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String suffix;
  final ValueChanged<double> onChanged;

  /// Called once when the drag ends (for settings too costly to apply on
  /// every step).
  final ValueChanged<double>? onChangeEnd;

  /// Extra content (e.g. a live preview) shown under the track while open.
  final Widget? expandedChild;

  const SettingsSliderTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    this.divisions = 100,
    required this.suffix,
    required this.onChanged,
    this.onChangeEnd,
    this.expandedChild,
  });

  @override
  State<SettingsSliderTile> createState() => _SettingsSliderTileState();
}

class _SettingsSliderTileState extends State<SettingsSliderTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reducedOf(context);
    final value = widget.value.clamp(widget.min, widget.max).toDouble();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          expanded: _open,
          child: InkWell(
            onTap: () {
              AppHaptics.selection();
              setState(() => _open = !_open);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Icon(widget.icon, color: Colors.white70, size: 22),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: AppFonts.settingsStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          style: AppFonts.settingsStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Same footprint as a switch so rows line up.
                  AnimatedContainer(
                    duration: Duration(milliseconds: reduced ? 0 : 200),
                    constraints: const BoxConstraints(minWidth: 52),
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: _open ? 0.18 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '${value.round()}${widget.suffix}',
                      style: AppFonts.settingsStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: Duration(milliseconds: reduced ? 0 : 240),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !_open
              ? const SizedBox(width: double.infinity)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(44, 0, 12, 8),
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 16,
                          ),
                        ),
                        child: Slider(
                          value: value,
                          min: widget.min,
                          max: widget.max,
                          divisions: widget.divisions,
                          onChanged: widget.onChanged,
                          onChangeEnd: widget.onChangeEnd,
                        ),
                      ),
                    ),
                    ?widget.expandedChild,
                  ],
                ),
        ),
      ],
    );
  }
}

class SettingsSearchItem {
  final String title;
  final String subtitle;
  final String category;
  final Widget widget;

  SettingsSearchItem({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.widget,
  });
}

/// Card fill for the settings screens (Figma devvlooper). Neutral on
/// purpose: settings chrome never takes the accent colour.
const kSettingsCard = Color(0xFF101010);
const kSettingsDivider = Color(0x0FFFFFFF);

/// Icons exported from the Figma devvlooper settings/account screens.
abstract final class SettingsIcons {
  static const _d = 'assets/icons/settings';
  static const backButton = '$_d/back_button.svg';
  static const arrow = '$_d/arrow.svg';
  static const chevron = '$_d/chevron.svg';
  static const search = '$_d/search.svg';
  static const gear = '$_d/gear.svg';
  static const headerGear = '$_d/header_gear.svg';
  static const userCircle = '$_d/user_circle.svg';
  static const edit = '$_d/edit.svg';
  static const forward = '$_d/forward.svg';
  static const palette = '$_d/palette.svg';
  static const musicManage = '$_d/music_manage.svg';
  static const gesture = '$_d/gesture.svg';
  static const info = '$_d/info.svg';
  static const check = '$_d/check.svg';
}

/// Circle back button + title, used by Settings and every sub-screen.
class SettingsHeader extends StatelessWidget {
  const SettingsHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.centerTitle = false,
  });

  final String title;
  final VoidCallback onBack;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    return Row(
      children: [
        Semantics(
          button: true,
          label: material.backButtonTooltip,
          child: InkWell(
            onTap: onBack,
            customBorder: const CircleBorder(),
            child: SvgPicture.asset(
              SettingsIcons.backButton,
              width: 41,
              height: 40,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: centerTitle ? TextAlign.center : TextAlign.start,
            style: AppFonts.settingsStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Balances the back button so a centred title sits truly centred.
        if (centerTitle) const SizedBox(width: 55),
      ],
    );
  }
}

/// Rounded neutral card; children are separated by inset hairlines.
class SettingsGroupCard extends StatelessWidget {
  const SettingsGroupCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kSettingsCard,
      borderRadius: BorderRadius.circular(15),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0)
              const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: kSettingsDivider,
              ),
            child,
          ],
        ],
      ),
    );
  }
}

/// Icon + title/subtitle + chevron row that opens a settings sub-screen.
class SettingsNavRow extends StatelessWidget {
  const SettingsNavRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.svg,
  });

  final IconData icon;

  /// Figma icon; takes precedence over [icon] when set.
  final String? svg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Center(
                child: svg != null
                    ? SvgPicture.asset(svg!, width: 20, height: 20)
                    : Icon(icon, color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.settingsStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.settingsStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(LucideIcons.chevronRight, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Theme for settings sub-screens: neutral white/grey switches, sliders
/// and icons instead of the accent colour (Figma devvlooper 2162:1359).
/// [t] in DM Sans with zero letter spacing, for text in settings that
/// doesn't set its own style (chips, dialogs, default list text).
TextTheme _settingsText(TextTheme t) {
  TextStyle? z(TextStyle? s) =>
      s?.copyWith(fontFamily: AppFonts.dmSans, letterSpacing: 0);
  return t.copyWith(
    displayLarge: z(t.displayLarge),
    displayMedium: z(t.displayMedium),
    displaySmall: z(t.displaySmall),
    headlineLarge: z(t.headlineLarge),
    headlineMedium: z(t.headlineMedium),
    headlineSmall: z(t.headlineSmall),
    titleLarge: z(t.titleLarge),
    titleMedium: z(t.titleMedium),
    titleSmall: z(t.titleSmall),
    bodyLarge: z(t.bodyLarge),
    bodyMedium: z(t.bodyMedium),
    bodySmall: z(t.bodySmall),
    labelLarge: z(t.labelLarge),
    labelMedium: z(t.labelMedium),
    labelSmall: z(t.labelSmall),
  );
}

ThemeData settingsTheme(ThemeData base) => base.copyWith(
  textTheme: _settingsText(base.textTheme),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.selected)
          ? Colors.white
          : const Color(0xFF3A3A3A),
    ),
    trackColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.selected)
          ? Colors.white.withValues(alpha: 0.5)
          : Colors.white.withValues(alpha: 0.05),
    ),
    trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    thumbIcon: const WidgetStatePropertyAll(null),
  ),
  sliderTheme: base.sliderTheme.copyWith(
    trackHeight: 5,
    activeTrackColor: Colors.white,
    inactiveTrackColor: Colors.white.withValues(alpha: 0.05),
    thumbColor: Colors.white,
    overlayColor: Colors.white.withValues(alpha: 0.08),
    activeTickMarkColor: Colors.transparent,
    inactiveTickMarkColor: Colors.transparent,
    valueIndicatorColor: kSettingsCard,
  ),
  listTileTheme: base.listTileTheme.copyWith(
    iconColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    // Compact rows so long categories read as fewer options.
    visualDensity: VisualDensity.compact,
    minVerticalPadding: 6,
  ),
  radioTheme: RadioThemeData(
    fillColor: const WidgetStatePropertyAll(Colors.white),
  ),
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.selected) ? Colors.white : null,
    ),
    checkColor: const WidgetStatePropertyAll(Colors.black),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(color: Colors.white),
);
