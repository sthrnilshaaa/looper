import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:looper_player/core/motion/looper_scroll_physics.dart';
import 'package:looper_player/core/providers/providers.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/services/update/apk_update_notifier.dart';
import 'package:looper_player/core/services/update/github_release.dart';
import 'package:looper_player/core/theme/app_assets.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/app_links.dart';
import 'package:looper_player/core/utils/l10n.dart';
import 'package:looper_player/core/utils/responsive.dart';
import 'package:looper_player/l10n/app_localizations.dart';

/// Shows the redesigned in-app update sheet matching the design spec.
void showApkUpdateSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.8),
    isScrollControlled: true,
    builder: (context) => const ApkUpdateSheet(),
  );
}

/// Format file size: `12.3 MB`
String formatUpdateSize(int bytes) =>
    '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

/// Strips leading `v` or prefix non-digit chars from release tag.
String cleanVersion(String? tag) {
  if (tag == null || tag.isEmpty) return '';
  final match = RegExp(r'\d+(\.\d+)*').firstMatch(tag);
  return match != null ? match.group(0)! : tag;
}

/// Extracts bullet points and clean changes from release notes.
String parseChangelog(String rawNotes) {
  if (rawNotes.trim().isEmpty) {
    return 'General improvements and bug fixes.';
  }

  // Look for "## What's New" or similar section if present
  final whatsNewMatch = RegExp(
    r'##\s*What(?:\x27|’)?s\s*New([\s\S]*?)(?=\r?\n##\s+[^#]|$)',
    caseSensitive: false,
  ).firstMatch(rawNotes);

  final textToParse = whatsNewMatch != null
      ? whatsNewMatch.group(1)!
      : rawNotes;
  final lines = textToParse.split('\n');
  final items = <String>[];

  for (var line in lines) {
    line = line.trim();
    if (line.isEmpty) continue;

    // Skip Markdown images, tables, html tags, and footer notes
    if (line.startsWith('![') ||
        line.startsWith('<') ||
        line.startsWith('|') ||
        line.startsWith('* **') ||
        line.toLowerCase().contains('full changelog') ||
        line.toLowerCase().contains('verify downloads')) {
      continue;
    }

    // Skip section headers like ### New, ### Improved, ### Fixed
    if (line.startsWith('#')) continue;

    // Remove bullet prefixes: "- ", "* ", "• ", or numbered bullets
    line = line
        .replaceFirst(RegExp(r'^(?:[-*•]\s*|\d+\.\s*|[-*•]\s*\d+\.\s*)'), '')
        .trim();

    if (line.isNotEmpty) {
      items.add(line);
    }
  }

  if (items.isEmpty) {
    final cleanLines = rawNotes
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('#') && !l.startsWith('|'))
        .toList();
    if (cleanLines.isNotEmpty) {
      return cleanLines.take(8).join('\n');
    }
    return 'General improvements and bug fixes.';
  }

  return items.join('\n');
}

class ApkUpdateSheet extends ConsumerWidget {
  const ApkUpdateSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final update = ref.watch(apkUpdateProvider);
    final appVersionAsync = ref.watch(appVersionProvider);
    final currentAppVersion = cleanVersion(appVersionAsync.value);

    final release = update.release;
    final asset = update.asset;
    final isUpToDate = update.phase == ApkUpdatePhase.upToDate;

    // Version to show in the header:
    // When up to date: show the current app version (e.g. 3.0.0 or 2.7.5).
    // When update available: show the new version from release tag.
    final displayVersion = isUpToDate
        ? (currentAppVersion.isNotEmpty
              ? currentAppVersion
              : cleanVersion(release?.tag))
        : (cleanVersion(release?.tag).isNotEmpty
              ? cleanVersion(release?.tag)
              : currentAppVersion);

    // Version to show in "What changed on <version>":
    final changelogVersion = cleanVersion(release?.tag).isNotEmpty
        ? cleanVersion(release?.tag)
        : displayVersion;

    final changelogText = release != null && release.notes.isNotEmpty
        ? parseChangelog(release.notes)
        : 'General improvements and bug fixes.';

    final isLandscape = Responsive.isLandscape(MediaQuery.sizeOf(context));

    Widget content = Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D0D),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Drag Handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 65,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF323232),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Header Row (Logo, Title/Version, Info Button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  SvgPicture.asset(
                    AppAssets.looperUpdateLogo,
                    width: 52,
                    height: 38,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isUpToDate
                              ? l10n.updateAlreadyLatest
                              : l10n.updateAvailable,
                          style: AppFonts.familyStyle(
                            AppFonts.stackSansText,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withValues(alpha: 0.25),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'v',
                                style: AppFonts.familyStyle(
                                  AppFonts.stackSansText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              TextSpan(
                                text: displayVersion,
                                style: AppFonts.familyStyle(
                                  AppFonts.stackSansText,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        AppHaptics.light();
                        _showReleaseDetails(
                          context,
                          release,
                          asset,
                          isUpToDate,
                          l10n,
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 31,
                        height: 31,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          LucideIcons.info,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // What changed section
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.updateWhatChangedOn(changelogVersion),
                    style: AppFonts.familyStyle(
                      AppFonts.dmSans,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.22,
                    ),
                    child: SingleChildScrollView(
                      physics: const LooperScrollPhysics(),
                      child: Text(
                        changelogText,
                        style: AppFonts.familyStyle(
                          AppFonts.stackSansText,
                          fontSize: 15,
                          fontWeight: FontWeight.normal,
                          height: 1.6,
                          color: Colors.white.withValues(alpha: 0.8),
                          letterSpacing: -0.32,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Progress / Status indicator when busy or failed
            if (update.phase == ApkUpdatePhase.downloading ||
                update.phase == ApkUpdatePhase.verifying ||
                update.phase == ApkUpdatePhase.installing ||
                update.phase == ApkUpdatePhase.failed) ...[
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: _UpdateProgressStatus(update: update),
              ),
            ],

            // Primary Action Button ("Install here.")
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
              child: SizedBox(
                height: 60,
                width: double.infinity,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () => _handlePrimaryAction(context, ref, update),
                    borderRadius: BorderRadius.circular(10),
                    child: Center(
                      child: _buildPrimaryButtonContent(update, l10n),
                    ),
                  ),
                ),
              ),
            ),

            // Secondary Buttons Row ("Open in web" | "No thanks")
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () async {
                            AppHaptics.light();
                            final url =
                                release?.htmlUrl ?? AppLinks.githubReleasesWeb;
                            try {
                              await launchUrl(
                                Uri.parse(url),
                                mode: LaunchMode.externalApplication,
                              );
                            } catch (_) {}
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Center(
                            child: Text(
                              l10n.updateOpenInWeb,
                              style: AppFonts.familyStyle(
                                AppFonts.stackSansText,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.6),
                                letterSpacing: -0.32,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () {
                            AppHaptics.light();
                            ref.read(apkUpdateProvider.notifier).dismiss();
                            Navigator.of(context).pop();
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Center(
                            child: Text(
                              l10n.updateNoThanks,
                              style: AppFonts.familyStyle(
                                AppFonts.stackSansText,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.6),
                                letterSpacing: -0.32,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (isLandscape) {
      content = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildPrimaryButtonContent(
    ApkUpdateState update,
    AppLocalizations l10n,
  ) {
    switch (update.phase) {
      case ApkUpdatePhase.downloading:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: update.progress,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${l10n.updateDownloading} (${l10n.cancel})',
              style: AppFonts.familyStyle(
                AppFonts.stackSansText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.32,
              ),
            ),
          ],
        );
      case ApkUpdatePhase.verifying:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.updateVerifying,
              style: AppFonts.familyStyle(
                AppFonts.stackSansText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.32,
              ),
            ),
          ],
        );
      case ApkUpdatePhase.installing:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.updateWaitingForInstaller,
              style: AppFonts.familyStyle(
                AppFonts.stackSansText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.32,
              ),
            ),
          ],
        );
      case ApkUpdatePhase.failed:
        return Text(
          l10n.retry,
          style: AppFonts.familyStyle(
            AppFonts.stackSansText,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: -0.32,
          ),
        );
      case ApkUpdatePhase.ready:
      case ApkUpdatePhase.available:
      case ApkUpdatePhase.idle:
      case ApkUpdatePhase.upToDate:
        return Text(
          l10n.updateInstallHere,
          style: AppFonts.familyStyle(
            AppFonts.stackSansText,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: -0.32,
          ),
        );
    }
  }

  void _handlePrimaryAction(
    BuildContext context,
    WidgetRef ref,
    ApkUpdateState update,
  ) async {
    final notifier = ref.read(apkUpdateProvider.notifier);
    AppHaptics.medium();

    switch (update.phase) {
      case ApkUpdatePhase.downloading:
        notifier.cancel();
        break;
      case ApkUpdatePhase.verifying:
      case ApkUpdatePhase.installing:
        // Already busy
        break;
      case ApkUpdatePhase.ready:
        await notifier.install();
        break;
      case ApkUpdatePhase.failed:
        await notifier.retry();
        break;
      case ApkUpdatePhase.available:
      case ApkUpdatePhase.idle:
      case ApkUpdatePhase.upToDate:
        if (update.asset != null) {
          await notifier.download();
        } else if (update.release != null) {
          try {
            await launchUrl(
              Uri.parse(update.release!.htmlUrl),
              mode: LaunchMode.externalApplication,
            );
          } catch (_) {}
        }
        break;
    }
  }

  void _showReleaseDetails(
    BuildContext context,
    GithubRelease? release,
    ApkAsset? asset,
    bool isUpToDate,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161616),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(LucideIcons.info, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Release Details',
                  style: AppFonts.familyStyle(
                    AppFonts.stackSansText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (release != null) ...[
                _detailRow('Tag', release.tag),
                if (release.name.isNotEmpty && release.name != release.tag)
                  _detailRow('Name', release.name),
              ],
              if (asset != null) ...[
                _detailRow('Package', asset.name),
                _detailRow('Size', formatUpdateSize(asset.size)),
                if (asset.sha256 != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'SHA-256 Checksum',
                    style: AppFonts.familyStyle(
                      AppFonts.dmSans,
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            asset.sha256!,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            LucideIcons.copy,
                            size: 14,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: asset.sha256!),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Checksum copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                l10n.close,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            if (release != null)
              TextButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  try {
                    await launchUrl(
                      Uri.parse(release.htmlUrl),
                      mode: LaunchMode.externalApplication,
                    );
                  } catch (_) {}
                },
                child: Text(
                  l10n.updateOpenInWeb,
                  style: const TextStyle(color: Color(0xFFC0E200)),
                ),
              ),
          ],
        );
      },
    );
  }

  static Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: AppFonts.familyStyle(
                AppFonts.dmSans,
                fontSize: 13,
                color: Colors.white38,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppFonts.familyStyle(
                AppFonts.dmSans,
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateProgressStatus extends StatelessWidget {
  final ApkUpdateState update;

  const _UpdateProgressStatus({required this.update});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    switch (update.phase) {
      case ApkUpdatePhase.idle:
      case ApkUpdatePhase.available:
      case ApkUpdatePhase.ready:
      case ApkUpdatePhase.upToDate:
        return const SizedBox.shrink();
      case ApkUpdatePhase.downloading:
        final progress = update.progress;
        final amount =
            '${formatUpdateSize(update.received)} / ${formatUpdateSize(update.total)}';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation(Color(0xFFC0E200)),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.updateDownloading,
                    style: AppFonts.familyStyle(
                      AppFonts.dmSans,
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ),
                Text(
                  progress == null
                      ? amount
                      : '$amount · ${(progress * 100).round()}%',
                  style: AppFonts.familyStyle(
                    AppFonts.dmSans,
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ],
        );
      case ApkUpdatePhase.verifying:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                value: null,
                minHeight: 5,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation(Color(0xFFC0E200)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.updateVerifying,
              style: AppFonts.familyStyle(
                AppFonts.dmSans,
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        );
      case ApkUpdatePhase.installing:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                value: null,
                minHeight: 5,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation(Color(0xFFC0E200)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.updateWaitingForInstaller,
              style: AppFonts.familyStyle(
                AppFonts.dmSans,
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        );
      case ApkUpdatePhase.failed:
        final detail = update.errorDetail;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _errorText(l10n, update.error),
              style: AppFonts.familyStyle(
                AppFonts.dmSans,
                fontSize: 13,
                color: Colors.redAccent,
              ),
            ),
            if (detail != null && detail.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.familyStyle(
                  AppFonts.dmSans,
                  fontSize: 11,
                  color: Colors.white38,
                ),
              ),
            ],
          ],
        );
    }
  }

  static String _errorText(AppLocalizations l10n, ApkUpdateError? error) =>
      switch (error) {
        ApkUpdateError.checksum => l10n.updateErrorChecksum,
        ApkUpdateError.storage => l10n.updateErrorStorage,
        ApkUpdateError.install => l10n.updateErrorInstall,
        ApkUpdateError.network || null => l10n.updateErrorNetwork,
      };
}
