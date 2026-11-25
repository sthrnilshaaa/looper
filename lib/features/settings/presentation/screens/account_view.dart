import 'package:looper_player/ui/widgets/common/setup_kit.dart';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/core/motion/looper_scroll_physics.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';
import 'package:looper_player/core/providers/providers.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:looper_player/features/analyze/presentation/providers/analyze_notifier.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/common/scrolling_text.dart';

/// Card fill used by the Account and Settings screens (Figma devvlooper).
// Opaque: 5% white over #0A0A0A, so the animated backdrop stays behind it.
const kAccountCard = Color(0xFF161616);
const _lime = Color(0xFFC0E200);

/// Name greeted on the Account screen: the user's own, else a neutral default.
String accountDisplayName(AppSettings s, AppLocalizations l10n) =>
    s.userName.isNotEmpty ? s.userName : l10n.accountDefaultName;

/// Lets the user pick any image as their profile photo. The file is copied
/// into app support storage so it survives the source being moved/deleted.
Future<void> pickProfilePhoto(WidgetRef ref) async {
  try {
    final picked = (await FilePicker.pickFile(type: FileType.image))?.path;
    if (picked == null) return;
    final dir = Directory(
      p.join((await getApplicationSupportDirectory()).path, 'profile'),
    );
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    // New name per pick so Image.file doesn't serve the old cached photo.
    final dest = p.join(
      dir.path,
      'photo_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked)}',
    );
    await File(picked).copy(dest);
    await ref.read(settingsProvider.notifier).updateUserPhotoPath(dest);
  } catch (_) {}
}

Future<void> removeProfilePhoto(WidgetRef ref) async {
  final path = ref.read(settingsProvider).userPhotoPath;
  await ref.read(settingsProvider.notifier).updateUserPhotoPath('');
  try {
    if (path.isNotEmpty) await File(path).delete();
  } catch (_) {}
}

/// The user's photo, or a neutral person glyph until one is picked.
class ProfilePhoto extends ConsumerWidget {
  const ProfilePhoto({super.key, this.size = 62, this.radius = 5});

  final double size;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = ref.watch(settingsProvider.select((s) => s.userPhotoPath));
    final placeholder = Icon(
      LucideIcons.user,
      color: Colors.white.withValues(alpha: 0.3),
      size: size * 0.45,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        color: const Color(0xFF111111),
        child: path.isEmpty
            ? placeholder
            : Image.file(
                File(path),
                fit: BoxFit.cover,
                cacheWidth: (size * 3).round(),
                errorBuilder: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}

/// Settings > Account > "Profile photo" row: tap to pick, x to remove.
class ProfilePhotoTile extends ConsumerWidget {
  const ProfilePhotoTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final hasPhoto = ref.watch(
      settingsProvider.select((s) => s.userPhotoPath.isNotEmpty),
    );
    return ListTile(
      leading: const ProfilePhoto(size: 28, radius: 14),
      title: Text(l10n.accountPhoto),
      subtitle: Text(l10n.accountPhotoDesc),
      trailing: hasPhoto
          ? IconButton(
              tooltip: l10n.accountPhotoRemove,
              icon: const Icon(LucideIcons.x, size: 18),
              onPressed: () {
                AppHaptics.light();
                removeProfilePhoto(ref);
              },
            )
          : const Icon(LucideIcons.chevronRight, size: 18),
      onTap: () {
        AppHaptics.light();
        pickProfilePhoto(ref);
      },
    );
  }
}

Future<void> showEditNameDialog(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController(
    text: ref.read(settingsProvider).userName,
  );
  void submit(BuildContext dialogContext) {
    ref.read(settingsProvider.notifier).updateUserName(controller.text);
    Navigator.pop(dialogContext);
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Theme.of(dialogContext).colorScheme.surfaceContainer,
      title: Text(l10n.accountEditName),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 24,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => submit(dialogContext),
        decoration: InputDecoration(hintText: l10n.accountNameHint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => submit(dialogContext),
          child: Text(l10n.save),
        ),
      ],
    ),
  );
  controller.dispose();
}

/// Settings > Account > "Your name" row.
/// Settings > Account: the profile photo in place of the person icon in
/// the Home, Songs and Library top bars.
class HeaderProfilePhotoTile extends ConsumerWidget {
  const HeaderProfilePhotoTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final show = ref.watch(
      settingsProvider.select((s) => s.showHeaderProfilePhoto),
    );
    return SwitchListTile(
      secondary: const Icon(LucideIcons.circleUser),
      title: Text(l10n.headerProfilePhoto),
      subtitle: Text(l10n.headerProfilePhotoDesc),
      value: show,
      onChanged: (value) {
        AppHaptics.light();
        ref.read(settingsProvider.notifier).updateHeaderProfilePhoto(value);
      },
    );
  }
}

/// The round profile photo for a [size] top-bar button, or null when there
/// is none or the user turned it off (the button keeps its person icon).
Widget? headerProfilePhoto(WidgetRef ref, double size) {
  final show = ref.watch(
    settingsProvider.select(
      (s) => s.showHeaderProfilePhoto && s.userPhotoPath.isNotEmpty,
    ),
  );
  return show ? ProfilePhoto(size: size, radius: size / 2) : null;
}

class AccountNameTile extends ConsumerWidget {
  const AccountNameTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final name = ref.watch(settingsProvider.select((s) => s.userName));
    return ListTile(
      leading: const Icon(LucideIcons.userPen),
      title: Text(l10n.accountEditName),
      subtitle: Text(name.isEmpty ? l10n.accountEditNameDesc : name),
      trailing: const Icon(LucideIcons.chevronRight, size: 18),
      onTap: () {
        AppHaptics.light();
        showEditNameDialog(context, ref);
      },
    );
  }
}

/// Minutes listened today, summed from the play-event log.
final _todayListenedProvider = Provider.autoDispose<Duration>((ref) {
  final events = ref.watch(playEventsProvider).value ?? const [];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  var ms = 0;
  for (final e in events) {
    if (!e.playedAt.isBefore(today)) ms += e.listenedMs;
  }
  return Duration(milliseconds: ms);
});

class AccountView extends ConsumerWidget {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final nav = ref.read(appNavigationProvider.notifier);
    void back() {
      AppHaptics.light();
      nav.goBack();
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop &&
            ref.read(appNavigationProvider).activeItem == NavItem.account) {
          nav.goBack();
        }
      },
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: SetupBackground(
          child: SafeArea(
            child: ListView(
              physics: const LooperScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 140),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: back,
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      // Figma ships this arrow pointing up-right, rotated -135°.
                      icon: Transform.rotate(
                        angle: -2.356,
                        child: SvgPicture.asset(
                          SettingsIcons.arrow,
                          width: 12.6,
                          height: 12.6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.account,
                      style: AppFonts.jostStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.32,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const AccountSummary(),
                const SizedBox(height: 26),
                Padding(
                  padding: const EdgeInsets.only(left: 1, bottom: 12),
                  child: Text(
                    l10n.settingsGroupTitle,
                    style: AppFonts.jostStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.32,
                    ),
                  ),
                ),
                _NavRow(
                  svg: SettingsIcons.gear,
                  title: l10n.accountOpenSettings,
                  onTap: () => nav.setItem(NavItem.settings),
                ),
                const SizedBox(height: 12),
                _NavRow(
                  svg: SettingsIcons.userCircle,
                  title: l10n.accountSettings,
                  onTap: () => nav.showSettingsCategory(
                    id: 'account',
                    title: l10n.account,
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

/// Greeting card plus today's listening and version cards.
class AccountSummary extends ConsumerWidget {
  const AccountSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final nav = ref.read(appNavigationProvider.notifier);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _HeroCard(),
        const SizedBox(height: 17),
        SizedBox(
          height: 128,
          child: Row(
            children: [
              Expanded(
                flex: 144,
                child: _StatCard(
                  label: '${l10n.accountViewStats} >',
                  onTap: () => nav.setItem(NavItem.analyze),
                  child: const _TodayListening(),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                flex: 198,
                child: _StatCard(
                  label: '${l10n.accountVersionAbout} >',
                  onTap: () => nav.showSettingsCategory(
                    id: 'about',
                    title: l10n.catAbout,
                    replace: UiUtils.isDesktop,
                  ),
                  child: Row(
                    children: [
                      Flexible(
                        child: FittedBox(
                          child: Text(
                            ref.watch(appVersionProvider).value ?? '',
                            style: _big,
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      SvgPicture.asset(
                        SettingsIcons.forward,
                        width: 38,
                        height: 27,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final _big = AppFonts.jostStyle(
  color: Colors.white,
  fontSize: 40,
  fontWeight: FontWeight.bold,
  height: 1,
);
final _unit = AppFonts.jostStyle(
  color: Colors.white,
  fontSize: 20,
  fontWeight: FontWeight.bold,
  height: 1,
);
final _muted = AppFonts.jostStyle(
  color: Colors.white.withValues(alpha: 0.3),
  fontSize: 14,
  fontWeight: FontWeight.w500,
);

class _HeroCard extends ConsumerWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final name = accountDisplayName(ref.watch(settingsProvider), l10n);
    final tag = '${l10n.accountLooperTag(name)} • ';
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 128,
        color: SettingsCardTint.of(context, kAccountCard),
        child: Stack(
          children: [
            // Faint "Looper Player" watermark tiled behind the greeting.
            Positioned.fill(
              child: OverflowBox(
                maxWidth: 600,
                maxHeight: 400,
                child: Transform.rotate(
                  angle: -0.52,
                  child: Wrap(
                    spacing: 24,
                    runSpacing: 12,
                    children: [
                      for (var i = 0; i < 40; i++)
                        Text(
                          'Looper Player',
                          style: AppFonts.jostStyle(
                            color: Colors.white.withValues(alpha: 0.02),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 24,
              child: Container(
                color: _lime,
                alignment: Alignment.centerLeft,
                // Always wider than the card, so it scrolls like a long
                // player title (and holds still with reduced motion).
                child: ScrollingText(
                  text: tag * 8,
                  style: GoogleFonts.pixelifySans(
                    color: Colors.black.withValues(alpha: 0.15),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.28,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 22,
              top: 22,
              right: 12,
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: l10n.accountPhoto,
                    child: GestureDetector(
                      onTap: () {
                        AppHaptics.light();
                        pickProfilePhoto(ref);
                      },
                      child: const ProfilePhoto(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.accountHello,
                          style: AppFonts.jostStyle(
                            color: Colors.white.withValues(alpha: 0.2),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.6,
                          ),
                        ),
                        Text(
                          '$name!',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.jostStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.6,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.accountEditName,
                    onPressed: () {
                      AppHaptics.light();
                      showEditNameDialog(context, ref);
                    },
                    icon: SvgPicture.asset(
                      SettingsIcons.edit,
                      width: 16,
                      height: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayListening extends ConsumerWidget {
  const _TodayListening();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final d = ref.watch(_todayListenedProvider);
    return Semantics(
      label: l10n.accountTodayListening,
      child: FittedBox(
        alignment: Alignment.centerLeft,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '${d.inHours}', style: _big),
              TextSpan(text: 'h ', style: _unit),
              TextSpan(text: '${d.inMinutes % 60}', style: _big),
              TextSpan(text: 'm', style: _unit),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SettingsCardTint.of(context, kAccountCard),
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          AppHaptics.light();
          onTap();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 14),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _muted,
              ),
            ),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Align(alignment: Alignment.centerLeft, child: child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.svg, required this.title, required this.onTap});

  final String svg;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SettingsCardTint.of(context, kAccountCard),
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          AppHaptics.light();
          onTap();
        },
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 18),
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.jostStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SvgPicture.asset(
                      SettingsIcons.chevron,
                      width: 5,
                      height: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: SvgPicture.asset(svg, width: 17, height: 17),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}
