import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:looper_player/features/library/data/services/saf_folder_service.dart';
import 'package:looper_player/features/library/presentation/providers/library/library_notifier.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/l10n.dart';

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
        HapticFeedback.lightImpact();
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
        style: AppFonts.jostStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        role,
        style: AppFonts.jostStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/about/github_icon.svg',
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
              leading: const Icon(LucideIcons.folder, color: Colors.white70),
              title: Text(
                path.split('/').last,
                style: AppFonts.jostStyle(color: Colors.white, fontSize: 14),
              ),
              subtitle: Text(
                path,
                style: AppFonts.jostStyle(color: Colors.white54, fontSize: 11),
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

class SettingsSliderTile extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String suffix;
  final ValueChanged<double> onChanged;

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
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppFonts.jostStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppFonts.jostStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${value.round()}$suffix',
                style: AppFonts.jostStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: Color(ref.watch(settingsProvider).accentColor),
              inactiveTrackColor: Colors.white10,
              thumbColor: Color(ref.watch(settingsProvider).accentColor),
              overlayColor: Color(
                ref.watch(settingsProvider).accentColor,
              ).withValues(alpha: 0.12),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
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
