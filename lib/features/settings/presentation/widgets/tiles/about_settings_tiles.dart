import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui' show lerpDouble;

import 'package:looper_player/core/motion/looper_scroll_physics.dart';
import 'package:looper_player/core/motion/pause_when_offscreen.dart';
import 'package:looper_player/core/utils/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:looper_player/features/settings/data/github_contributors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/app_links.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';

import 'package:looper_player/core/providers/providers.dart';
import 'package:looper_player/core/utils/l10n.dart';
import 'package:looper_player/core/theme/app_assets.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/services/update/apk_update_notifier.dart';
import 'package:looper_player/ui/widgets/sheets/apk_update_sheet.dart';
import 'package:looper_player/features/settings/presentation/widgets/lyrics_services_sheet.dart';
import 'package:looper_player/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:google_fonts/google_fonts.dart';

class LooperVersionTile extends ConsumerWidget {
  const LooperVersionTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionAsync = ref.watch(appVersionProvider);
    final versionStr = versionAsync.value != null
        ? context.l10n.versionLabel('${versionAsync.value}')
        : context.l10n.versionLabel('...');

    return ListTile(
      leading: const Icon(LucideIcons.info),
      title: Text(
        'Looper Player',
        style: AppFonts.settingsStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        versionStr,
        style: AppFonts.settingsStyle(color: Colors.white54, fontSize: 12),
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

/// Opens the lyrics services sheet (order + on/off per service).
class LyricsProviderTile extends ConsumerWidget {
  const LyricsProviderTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;

    return ListTile(
      leading: const Icon(LucideIcons.music),
      title: Text(
        l10n.lyricsServices,
        style: AppFonts.settingsStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        lyricsServiceChain(settings),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppFonts.settingsStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: Icon(
        LucideIcons.chevronRight,
        color: Colors.white.withValues(alpha: 0.4),
        size: 18,
      ),
      onTap: () {
        AppHaptics.light();
        showLyricsServicesSheet(context);
      },
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
      leading: const Icon(LucideIcons.scrollText),
      title: Text(
        l10n.openSourceLicenses,
        style: AppFonts.settingsStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        l10n.openSourceLicensesDesc,
        style: AppFonts.settingsStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: Icon(
        LucideIcons.chevronRight,
        color: Colors.white.withValues(alpha: 0.4),
        size: 18,
      ),
      onTap: () {
        AppHaptics.light();
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
        style: AppFonts.settingsStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        l10n.supportProjectLove,
        style: AppFonts.settingsStyle(
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
        AppHaptics.light();
        final Uri uri = Uri.parse(AppLinks.githubRepo);
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {}
      },
    );
  }
}

/// Manual update check for the github build (see [ApkInstaller.supported]);
/// opens the in-app update sheet when a newer release exists.
class CheckForUpdatesTile extends ConsumerStatefulWidget {
  const CheckForUpdatesTile({super.key, this.card = false});

  /// Render as the About screen's action card instead of a list tile.
  final bool card;

  @override
  ConsumerState<CheckForUpdatesTile> createState() =>
      _CheckForUpdatesTileState();
}

class _CheckForUpdatesTileState extends ConsumerState<CheckForUpdatesTile> {
  bool _checking = false;

  Future<void> _check() async {
    if (_checking) return;
    AppHaptics.light();
    setState(() => _checking = true);
    final result = await ref.read(apkUpdateProvider.notifier).check();
    if (!mounted) return;
    setState(() => _checking = false);

    if (result == ApkCheckResult.available ||
        result == ApkCheckResult.upToDate) {
      showApkUpdateSheet(context);
      return;
    }
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(l10n.updateCheckFailed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final update = ref.watch(apkUpdateProvider);
    final release = update.release;
    const accentColor = Colors.white;
    final busy = _checking || update.phase == ApkUpdatePhase.downloading;

    if (widget.card) {
      return AboutActionCard(
        label: l10n.checkForUpdates,
        onTap: _check,
        icon: Container(
          width: 33,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: busy
              ? SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: accentColor,
                    value: _checking ? null : update.progress,
                  ),
                )
              : SvgPicture.asset(
                  AppAssets.aboutDownload,
                  width: 10.9412,
                  height: 12.0007,
                ),
        ),
      );
    }

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(LucideIcons.download, color: accentColor, size: 22),
      ),
      title: Text(
        l10n.checkForUpdates,
        style: AppFonts.settingsStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: release == null
          ? null
          : Text(
              l10n.updateAvailableOnGithub(release.tag),
              style: AppFonts.settingsStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
      trailing: _checking || update.phase == ApkUpdatePhase.downloading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: accentColor,
                value: _checking ? null : update.progress,
              ),
            )
          : Icon(
              LucideIcons.chevronRight,
              color: Colors.white.withValues(alpha: 0.4),
              size: 18,
            ),
      onTap: _check,
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
                style: AppFonts.settingsStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppFonts.settingsStyle(
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

/// The About screen's maintainers card body: one avatar per contributor from
/// GitHub (see [githubContributorsProvider]), each opening that person's
/// GitHub profile.
class MaintainersRow extends ConsumerWidget {
  const MaintainersRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(githubContributorsProvider).value ?? const [];
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const LooperScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        itemCount: people.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final person = people[index];
          final ImageProvider? image = person.avatarUrl != null
              ? CachedNetworkImageProvider('${person.avatarUrl}&s=144')
              : person.avatarAsset != null
              ? AssetImage(person.avatarAsset!)
              : null;
          return Tooltip(
            message: person.login,
            child: GestureDetector(
              onTap: () async {
                AppHaptics.light();
                try {
                  await launchUrl(
                    Uri.parse(person.profileUrl),
                    mode: LaunchMode.externalApplication,
                  );
                } catch (e) {}
              },
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white10,
                backgroundImage: image,
                child: image == null
                    ? Text(
                        person.login.characters.first.toUpperCase(),
                        style: AppFonts.settingsStyle(color: Colors.white),
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Services and projects Looper's online lyrics rely on, credited in About on
/// both Android and desktop. None publish terms of use, so each gets a name,
/// what it provides, its license where it has one, and a link.
typedef LyricsCredit = ({String name, String description, String url});

List<LyricsCredit> lyricsCredits(AppLocalizations l10n) => [
  (
    name: 'lrc.red',
    description: l10n.creditLrcRedDesc,
    url: AppLinks.lrcRedWeb,
  ),
  (
    name: 'LyricsPlus',
    description: l10n.creditLyricsPlusDesc,
    url: AppLinks.lyricsPlusSource,
  ),
  for (final (name, url) in const [
    ('AMLL', AppLinks.amllWeb),
    ('NetEase', AppLinks.neteaseWeb),
    ('KuGou', AppLinks.kugouWeb),
    ('Musixmatch', AppLinks.musixmatchWeb),
    ('Lyricify', AppLinks.lyricifyWeb),
    ('BetterLyrics', AppLinks.betterLyricsWeb),
    ('PaxSenix', AppLinks.paxsenixWeb),
    ('Unison', AppLinks.unisonWeb),
    ('BiniLyrics', AppLinks.biniLyricsWeb),
  ])
    (name: name, description: l10n.creditWordSyncedDesc, url: url),
  (name: 'LRCLIB', description: l10n.creditLrclibDesc, url: AppLinks.lrclibWeb),
  (
    name: 'MusicBrainz',
    description: l10n.creditMusicBrainzDesc,
    url: AppLinks.musicBrainzWeb,
  ),
  (
    name: 'am-lyrics',
    description: l10n.creditAmLyricsDesc,
    url: AppLinks.amLyricsSource,
  ),
  (
    name: 'Morphe Patches',
    description: l10n.creditMorpheDesc,
    url: AppLinks.morphePatchesSource,
  ),
];

class LyricsCreditsSection extends StatelessWidget {
  final Color accentColor;
  final String? title;
  final List<LyricsCredit>? credits;
  final String? footnote;

  const LyricsCreditsSection({
    super.key,
    required this.accentColor,
    this.title,
    this.credits,
    this.footnote,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = credits ?? lyricsCredits(l10n);
    final header = title ?? l10n.lyricsSources;
    final note =
        footnote ?? (credits == null ? l10n.lyricsCopyrightNote : null);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            header.toUpperCase(),
            style: AppFonts.settingsStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: accentColor.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          for (final credit in items)
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                AppHaptics.light();
                try {
                  await launchUrl(
                    Uri.parse(credit.url),
                    mode: LaunchMode.externalApplication,
                  );
                } catch (e) {}
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: InfoSubTile(
                        icon: LucideIcons.music,
                        title: credit.name,
                        description: credit.description,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      LucideIcons.externalLink,
                      size: 14.s,
                      color: Colors.white38,
                    ),
                  ],
                ),
              ),
            ),
          if (note != null) ...[
            const SizedBox(height: 8),
            Text(
              note,
              style: AppFonts.settingsStyle(
                fontSize: 11,
                height: 1.5,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _openUrl(String url) async {
  AppHaptics.light();
  if (url.isEmpty) return;
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (e) {}
}

// Opaque: 5% white over #0A0A0A, so the animated backdrop stays behind it.
const _aboutCardFill = Color(0xFF161616);

TextStyle _dmSans(double size, FontWeight weight, Color color) =>
    AppFonts.settingsStyle(fontSize: size, fontWeight: weight, color: color);

/// Top card: brand mark, app name and the installed version.
class AboutHeroCard extends ConsumerWidget {
  const AboutHeroCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionProvider).value ?? '';
    return GestureDetector(
      onTap: () => _openUrl(AppLinks.githubStatsRepo),
      child: Container(
        height: 212,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            stops: [0.128, 0.496, 0.872],
            colors: [Color(0xFF101010), Color(0xFF181818), Color(0xFF131313)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  const rad = 30.55 * math.pi / 180;
                  final cosT = math.cos(rad);
                  final sinT = math.sin(rad);
                  final boxW = (w * cosT + h * sinT) + 60.0;
                  final boxH = (w * sinT + h * cosT) + 60.0;
                  return OverflowBox(
                    minWidth: boxW,
                    maxWidth: boxW,
                    minHeight: boxH,
                    maxHeight: boxH,
                    child: Transform.rotate(
                      angle: -rad,
                      child: _AboutScrollingPattern(
                        width: boxW,
                        height: boxH,
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: -8,
              top: -19.64,
              child: SvgPicture.asset(AppAssets.aboutCurve),
            ),
            Positioned(
              left: 26,
              top: 135,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 29, 28, 26),
              child: _heroContent(version),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroContent(String version) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SvgPicture.asset(AppAssets.aboutMark, width: 46, height: 33),
      const Spacer(),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 2,
            height: 12,
            margin: const EdgeInsets.only(bottom: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFC0E200),
              borderRadius: BorderRadius.circular(0.4),
            ),
          ),
          const SizedBox(width: 3),
          Text(
            'Looper Player',
            style: GoogleFonts.pixelifySans(
              fontSize: 16,
              height: 13 / 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.48,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          if (version.isNotEmpty)
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'v',
                    style: _dmSans(20, FontWeight.w700, Colors.white),
                  ),
                  TextSpan(
                    text: version,
                    style: _dmSans(40, FontWeight.w700, Colors.white),
                  ),
                ],
              ),
              style: const TextStyle(height: 1),
            ),
        ],
      ),
    ],
  );
}

/// Animated alternating diagonal marquee texture for [AboutHeroCard].
/// Even rows scroll forward, odd rows scroll backward.
class _AboutScrollingPattern extends StatefulWidget {
  final double width;
  final double height;

  const _AboutScrollingPattern({
    required this.width,
    required this.height,
  });

  @override
  State<_AboutScrollingPattern> createState() => _AboutScrollingPatternState();
}

class _AboutScrollingPatternState extends State<_AboutScrollingPattern>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  ImageStream? _imageStream;
  ImageStreamListener? _listener;
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
    if (Motion.reducedOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  void _resolveImage() {
    final stream = const AssetImage(AppAssets.aboutPattern)
        .resolve(createLocalImageConfiguration(context));
    if (stream.key == _imageStream?.key) return;

    if (_imageStream != null && _listener != null) {
      _imageStream!.removeListener(_listener!);
    }
    _imageStream = stream;
    _listener = ImageStreamListener((info, _) {
      if (!mounted) return;
      setState(() => _image = info.image);
    });
    _imageStream!.addListener(_listener!);
  }

  @override
  void dispose() {
    if (_imageStream != null && _listener != null) {
      _imageStream!.removeListener(_listener!);
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) {
      return SizedBox(width: widget.width, height: widget.height);
    }
    return PauseWhenOffscreen(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _AboutPatternPainter(
            image: image,
            animation: _controller,
          ),
        ),
      ),
    );
  }
}

class _AboutPatternPainter extends CustomPainter {
  final ui.Image image;
  final Animation<double> animation;

  // The seamless repeating "Looper music" unit in about_pattern.png is 114x20px,
  // starting at x=38. In the original design, the 708x314 asset was scaled by
  // 753.375 / 708 = 1.064089. Odd rows were staggered by 37px.
  static const _srcTileRect = Rect.fromLTWH(38, 0, 114, 20);
  static const _scale = 1.064089;
  static const _tileWidth = 114.0 * _scale;
  static const _rowHeight = 20.0 * _scale;
  static const _stagger = 37.0 * _scale;

  final Paint _paint = Paint()
    ..color = const Color.fromRGBO(255, 255, 255, 0.035)
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.medium;

  _AboutPatternPainter({
    required this.image,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final t = animation.value;
    final rowCount = (size.height / _rowHeight).ceil() + 1;

    for (int i = 0; i < rowCount; i++) {
      final y = i * _rowHeight;
      // ponytail: Alternating continuous marquee. Even rows glide forward,
      // odd rows glide backward, wrapping seamlessly modulo _tileWidth.
      final double dx = (i % 2 == 0)
          ? (t * _tileWidth) % _tileWidth
          : (_stagger - t * _tileWidth) % _tileWidth;

      if (dx.isNaN || dx.isInfinite) continue;

      double x = dx - _tileWidth;
      while (x < size.width + _tileWidth) {
        canvas.drawImageRect(
          image,
          _srcTileRect,
          Rect.fromLTWH(x, y, _tileWidth + 0.5, _rowHeight + 0.5),
          _paint,
        );
        x += _tileWidth;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AboutPatternPainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.animation != animation;
  }
}

/// Small card with a dim title, divider and a body (maintainers / stars).
class _AboutStatCard extends StatelessWidget {
  final String title;
  final Widget body;
  final VoidCallback onTap;

  const _AboutStatCard({
    required this.title,
    required this.body,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _aboutCardFill,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 115,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  '$title >',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _dmSans(14, FontWeight.w500, Colors.white30),
                ),
                const SizedBox(height: 15),
                const Divider(height: 1, thickness: 1, color: kSettingsDivider),
                Expanded(child: body),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Overlapping contributor avatars from GitHub ([githubContributorsProvider]).
class AboutMaintainersCard extends ConsumerWidget {
  const AboutMaintainersCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(githubContributorsProvider).value ?? const [];
    final shown = people.take(5).toList();
    final title = '${context.l10n.maintainersLabel} & Contributors';
    return Hero(
      tag: _maintainersHeroTag,
      flightShuttleBuilder: _dialogShuttle(10),
      child: _AboutStatCard(
        title: title,
        onTap: () => _showAboutGridDialog(
          context,
          heroTag: _maintainersHeroTag,
          cardRadius: 10,
          title: title,
          entries: [
            for (final p in people)
              (
                label: p.login,
                url: p.profileUrl,
                icon: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white10,
                  backgroundImage: _avatarImage(p, 144),
                ),
              ),
          ],
        ),
        body: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            height: 35,
            width: shown.isEmpty ? 0 : 35 + 21.0 * (shown.length - 1),
            child: Stack(
              children: [
                // Later avatars sit underneath earlier ones, as in the design.
                for (final (i, person) in shown.indexed.toList().reversed)
                  Positioned(
                    left: 21.0 * i,
                    child: Tooltip(
                      message: person.login,
                      child: Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white10,
                          border: Border.all(
                            color: const Color(0xFF151515),
                            width: 3,
                          ),
                          image: switch (_avatarImage(person, 96)) {
                            final image? => DecorationImage(
                              fit: BoxFit.cover,
                              image: image,
                            ),
                            null => null,
                          },
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

ImageProvider? _avatarImage(GithubContributor person, int size) =>
    person.avatarUrl != null
    ? CachedNetworkImageProvider('${person.avatarUrl}&s=$size')
    : person.avatarAsset != null
    ? AssetImage(person.avatarAsset!)
    : null;

const _maintainersHeroTag = 'about-maintainers';
const _socialsHeroTag = 'about-socials';
const _dialogFill = Color(0xFF151515);
const double _dialogRadius = 20;

/// Social channels shown on the Socials card and in its dialog.
List<_GridEntry> _socials() => [
  (
    label: 'Discord',
    url: AppLinks.socialDiscord,
    icon: SvgPicture.asset(AppAssets.aboutDiscord, width: 48, height: 48),
  ),
  (
    label: 'GitHub',
    url: AppLinks.socialGithub,
    icon: SvgPicture.asset(AppAssets.aboutGithub, width: 48, height: 48),
  ),
  (
    label: 'Telegram',
    url: AppLinks.socialTelegram,
    icon: SvgPicture.asset(AppAssets.aboutTelegram, width: 48, height: 48),
  ),
];

/// "Socials" row card with the overlapping Discord / GitHub / Telegram marks.
class AboutSocialsCard extends StatelessWidget {
  const AboutSocialsCard({super.key});

  // Bordered so overlapping icons stay separated, as in the design.
  static Widget _ringed(String asset) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF151515),
      borderRadius: BorderRadius.circular(11),
    ),
    padding: const EdgeInsets.all(3),
    child: SvgPicture.asset(asset, width: 32, height: 32),
  );

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: _socialsHeroTag,
      flightShuttleBuilder: _dialogShuttle(15),
      child: AboutActionCard(
        label: 'Socials',
        onTap: () => _showAboutGridDialog(
          context,
          heroTag: _socialsHeroTag,
          cardRadius: 15,
          title: 'Socials',
          entries: _socials(),
        ),
        // Telegram first so GitHub, then Discord, overlap it (design order).
        icon: SizedBox(
          width: 82,
          height: 38,
          child: Stack(
            children: [
              Positioned(
                left: 47,
                top: 3,
                child: SvgPicture.asset(
                  AppAssets.aboutTelegram,
                  width: 32,
                  height: 32,
                ),
              ),
              Positioned(left: 20, child: _ringed(AppAssets.aboutGithub)),
              Positioned(left: 0, child: _ringed(AppAssets.aboutDiscord)),
            ],
          ),
        ),
      ),
    );
  }
}

typedef _GridEntry = ({String label, String url, Widget icon});

/// The card grows (hero) into a centered dialog listing [entries] in a grid.
Future<void> _showAboutGridDialog(
  BuildContext context, {
  required Object heroTag,
  required double cardRadius,
  required String title,
  required List<_GridEntry> entries,
}) {
  AppHaptics.light();
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (context, _, _) => _AboutGridDialog(
        heroTag: heroTag,
        cardRadius: cardRadius,
        title: title,
        entries: entries,
      ),
      // The dialog arrives by its hero flight; nothing else to animate.
      transitionsBuilder: (_, _, _, child) => child,
    ),
  );
}

class _AboutGridDialog extends StatelessWidget {
  final Object heroTag;
  final double cardRadius;
  final String title;
  final List<_GridEntry> entries;

  const _AboutGridDialog({
    required this.heroTag,
    required this.cardRadius,
    required this.title,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 40),
          child: Hero(
            tag: heroTag,
            flightShuttleBuilder: _dialogShuttle(cardRadius),
            child: Material(
              color: _dialogFill,
              borderRadius: BorderRadius.circular(_dialogRadius),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: _dmSans(16, FontWeight.w500, Colors.white),
                    ),
                    const SizedBox(height: 15),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: kSettingsDivider,
                    ),
                    Flexible(
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const LooperScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        crossAxisCount: 3,
                        childAspectRatio: 0.9,
                        children: [
                          for (final e in entries)
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _openUrl(e.url),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  e.icon,
                                  const SizedBox(height: 10),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Text(
                                      e.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: _dmSans(
                                        13,
                                        FontWeight.w500,
                                        Colors.white70,
                                      ),
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
    );
  }
}

/// Container transform: the card's rounded box grows into the dialog, whose
/// content (laid out at its final size) fades in over the second half.
HeroFlightShuttleBuilder _dialogShuttle(double cardRadius) =>
    (_, animation, direction, fromContext, toContext) {
      final dialogContext = direction == HeroFlightDirection.push
          ? toContext
          : fromContext;
      final size = dialogContext.size ?? Size.zero;
      return AnimatedBuilder(
        animation: animation,
        builder: (_, child) => ClipRRect(
          borderRadius: BorderRadius.circular(
            lerpDouble(cardRadius, _dialogRadius, animation.value)!,
          ),
          child: ColoredBox(
            color: _dialogFill,
            child: Opacity(
              opacity: const Interval(0.5, 1).transform(animation.value),
              child: child,
            ),
          ),
        ),
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minWidth: size.width,
          maxWidth: size.width,
          minHeight: size.height,
          maxHeight: size.height,
          child: (dialogContext.widget as Hero).child,
        ),
      );
    };

/// Live stargazer count of the public repo ([githubStarsProvider]).
class AboutStarsCard extends ConsumerWidget {
  const AboutStarsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stars = ref.watch(githubStarsProvider).value;
    return _AboutStatCard(
      title: 'Stars on Github',
      onTap: () => _openUrl(AppLinks.githubStatsRepo),
      body: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: SvgPicture.asset(
                AppAssets.aboutStar,
                width: 13,
                height: 12,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              stars?.toString() ?? '—',
              style: _dmSans(
                40,
                FontWeight.w700,
                Colors.white,
              ).copyWith(height: 1),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width row card: label with a chevron and a trailing icon box.
class AboutActionCard extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onTap;

  const AboutActionCard({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _aboutCardFill,
      borderRadius: BorderRadius.circular(15),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 66,
          child: Padding(
            padding: const EdgeInsets.only(left: 23, right: 15),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$label >',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _dmSans(16, FontWeight.w500, Colors.white),
                  ),
                ),
                icon,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Licenses & Privacy": app info/privacy notes, credits and OSS licenses,
/// which used to sit inline on the About screen.
class AboutLicensesPrivacyCard extends StatelessWidget {
  final List<Widget> content;

  const AboutLicensesPrivacyCard({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return AboutActionCard(
      label: 'Licenses & Privacy',
      icon: SvgPicture.asset(AppAssets.aboutInfo, width: 33, height: 32),
      onTap: () {
        AppHaptics.light();
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (context) => Theme(
              data: settingsTheme(Theme.of(context)),
              child: Scaffold(
                backgroundColor: Theme.of(context).colorScheme.surface,
                body: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
                        child: SettingsHeader(
                          title: 'Licenses & Privacy',
                          onBack: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          physics: const LooperScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(22, 4, 22, 120),
                          children: [
                            Material(
                              color: kSettingsCard,
                              borderRadius: BorderRadius.circular(15),
                              clipBehavior: Clip.antiAlias,
                              child: Column(children: content),
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
        );
      },
    );
  }
}
