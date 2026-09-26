import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/app_links.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';

import 'package:looper_player/core/providers/providers.dart';
import 'package:looper_player/core/utils/l10n.dart';

class LooperVersionTile extends ConsumerWidget {
  const LooperVersionTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionAsync = ref.watch(appVersionProvider);
    final versionStr = versionAsync.value != null
        ? context.l10n.versionLabel('${versionAsync.value}')
        : context.l10n.versionLabel('...');

    return ListTile(
      leading: const Icon(LucideIcons.info, color: Colors.white70),
      title: Text(
        'Looper Player',
        style: AppFonts.jostStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        versionStr,
        style: AppFonts.jostStyle(color: Colors.white54, fontSize: 12),
      ),
      onTap: () async {
        final Uri uri = Uri.parse(AppLinks.githubRepo);
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {}
      },
    );
  }
}

class LyricsProviderTile extends ConsumerWidget {
  const LyricsProviderTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;

    final availableProviders = [
      'LRCLIB',
      'Genius',
      'Musixmatch',
      'AZLyrics',
      'LyricsMINT',
      'LyricFind',
    ];

    final providerUrls = AppLinks.lyricsProviderUrls;

    final currentProvider = settings.lyricsProvider;

    return ListTile(
      leading: const Icon(LucideIcons.music, color: Colors.white70),
      title: Text(
        l10n.lyricsProvider,
        style: AppFonts.jostStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        providerUrls[currentProvider] ?? 'lrclib.net',
        style: AppFonts.jostStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: DropdownButton<String>(
        value: availableProviders.contains(currentProvider)
            ? currentProvider
            : 'LRCLIB',
        dropdownColor: const Color(0xFF1A1A1A),
        underline: const SizedBox(),
        items: availableProviders.map((prov) {
          return DropdownMenuItem<String>(
            value: prov,
            child: Text(prov, style: AppFonts.jostStyle(color: Colors.white)),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            ref.read(settingsProvider.notifier).updateLyricsProvider(value);
          }
        },
      ),
    );
  }
}

class OpenSourceLicensesTile extends ConsumerWidget {
  const OpenSourceLicensesTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final versionAsync = ref.watch(appVersionProvider);

    return ListTile(
      leading: const Icon(LucideIcons.scrollText, color: Colors.white70),
      title: Text(
        l10n.openSourceLicenses,
        style: AppFonts.jostStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        l10n.openSourceLicensesDesc,
        style: AppFonts.jostStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: Icon(
        LucideIcons.chevronRight,
        color: Colors.white.withValues(alpha: 0.4),
        size: 18,
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (context) => LicensePage(
              applicationName: 'Looper Player',
              applicationVersion: versionAsync.value,
            ),
          ),
        );
      },
    );
  }
}

class GitHubStarTile extends StatelessWidget {
  const GitHubStarTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
      ),
      title: Text(
        l10n.giveStarOnGithub,
        style: AppFonts.jostStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        l10n.supportProjectLove,
        style: AppFonts.jostStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        LucideIcons.chevronRight,
        color: Colors.white.withValues(alpha: 0.4),
        size: 18,
      ),
      onTap: () async {
        HapticFeedback.lightImpact();
        final Uri uri = Uri.parse(AppLinks.githubRepo);
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {}
      },
    );
  }
}

class InfoSubTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const InfoSubTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16.s, color: Colors.white60),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppFonts.jostStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppFonts.jostStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AboutMaintainerRow extends StatelessWidget {
  final String name;
  final String role;
  final String avatar;
  final String github;
  final String telegram;

  const AboutMaintainerRow({
    super.key,
    required this.name,
    required this.role,
    required this.avatar,
    required this.github,
    required this.telegram,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white10,
            backgroundImage: AssetImage(avatar),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppFonts.jostStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: AppFonts.jostStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              HapticFeedback.lightImpact();
              final Uri uri = Uri.parse(github);
              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (e) {}
            },
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              child: SvgPicture.asset(
                'assets/about/github_icon.svg',
                width: 24,
                height: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () async {
              HapticFeedback.lightImpact();
              final Uri uri = Uri.parse(telegram);
              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (e) {}
            },
            child: SizedBox(
              width: 24,
              height: 24,
              child: SvgPicture.asset(
                'assets/about/telegram_icon.svg',
                width: 24,
                height: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
