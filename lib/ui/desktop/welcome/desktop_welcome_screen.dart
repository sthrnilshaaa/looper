import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/core/providers/providers.dart';
import 'package:looper_player/core/theme/app_assets.dart';
import 'package:looper_player/core/utils/desktop_paths.dart';
import 'package:looper_player/core/utils/l10n.dart';
import 'package:looper_player/features/library/presentation/providers/library/library_notifier.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/welcome/welcome_screen.dart';
import 'package:looper_player/ui/widgets/common/folder_picker_helper.dart';

part 'desktop_welcome_widgets.dart';

enum _Stage { setup, scanning, noSongs }

/// First-run setup for Linux and Windows: find the Music folder (or let the
/// user pick one), scan it, then hand over to the normal desktop shell.
///
/// From [_wideBreakpoint] the logo sits centred on top with the features and
/// the setup card side by side below it; narrower windows stack everything
/// in one column.
class DesktopWelcomeScreen extends ConsumerStatefulWidget {
  const DesktopWelcomeScreen({super.key});

  @override
  ConsumerState<DesktopWelcomeScreen> createState() =>
      _DesktopWelcomeScreenState();
}

const double _wideBreakpoint = 1200;

class _DesktopWelcomeScreenState extends ConsumerState<DesktopWelcomeScreen> {
  _Stage _stage = _Stage.setup;
  String? _musicFolder;
  bool _musicFolderExists = false;

  /// The folder being scanned, or the last one that turned up no songs.
  String? _scanPath;

  @override
  void initState() {
    super.initState();
    _findMusicFolder();
  }

  Future<void> _findMusicFolder() async {
    final path = await desktopMusicFolder();
    final exists = await Directory(path).exists();
    if (!mounted) return;
    setState(() {
      _musicFolder = path;
      _musicFolderExists = exists;
    });
  }

  Future<void> _scan(String path) async {
    setState(() {
      _stage = _Stage.scanning;
      _scanPath = path;
    });
    final count = await ref.read(libraryProvider.notifier).scanLibrary(path);
    if (!mounted) return;
    if (count == 0) {
      setState(() => _stage = _Stage.noSongs);
      return;
    }
    ref.read(forceWelcomeProvider.notifier).set(false);
    ref.read(welcomeBypassedProvider.notifier).set(true);
  }

  Future<void> _chooseFolder() async {
    final path = await FolderPickerHelper.pickFolderPathOnly(context);
    if (!mounted) return;
    if (path != null) return _scan(path);

    // No picker on this system (e.g. zenity missing) or it was closed:
    // offer typing the path instead.
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: Text(context.l10n.folderPickerClosed),
        action: SnackBarAction(
          label: context.l10n.enterManually,
          onPressed: _enterPathManually,
        ),
      ),
    );
  }

  Future<void> _enterPathManually() async {
    final path = await showDialog<String>(
      context: context,
      builder: (_) => _ManualPathDialog(hint: _musicFolder ?? ''),
    );
    if (path != null && path.isNotEmpty && mounted) await _scan(path);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Color(
      ref.watch(settingsProvider.select((s) => s.accentColor)),
    );
    final l10n = context.l10n;

    return Stack(
      children: [
        Positioned.fill(child: _WelcomeBackdrop(accent: accent)),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= _wideBreakpoint;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 48 : 24,
                vertical: 32,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 64).clamp(
                    0.0,
                    double.infinity,
                  ),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.03),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: switch (_stage) {
                      _Stage.setup => _buildSetup(l10n, accent, wide),
                      _Stage.scanning => _buildScanning(l10n, accent),
                      _Stage.noSongs => _buildNoSongs(l10n, accent),
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSetup(AppLocalizations l10n, Color accent, bool wide) {
    final setup = _SetupPanel(
      accent: accent,
      musicFolder: _musicFolder,
      musicFolderExists: _musicFolderExists,
      onScanMusicFolder: _musicFolderExists && _musicFolder != null
          ? () => _scan(_musicFolder!)
          : null,
      onChooseFolder: _chooseFolder,
      fillHeight: wide,
    );
    final features = _FeaturesPanel(accent: accent, twoColumns: true);

    if (wide) {
      return ConstrainedBox(
        key: const ValueKey('setup-wide'),
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BrandHeader(accent: accent, large: true),
            const SizedBox(height: 44),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 11, child: features),
                  const SizedBox(width: 24),
                  Expanded(flex: 9, child: setup),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ConstrainedBox(
      key: const ValueKey('setup-narrow'),
      constraints: const BoxConstraints(maxWidth: 620),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BrandHeader(accent: accent, large: false),
          const SizedBox(height: 32),
          setup,
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, c) =>
                _FeaturesPanel(accent: accent, twoColumns: c.maxWidth >= 540),
          ),
        ],
      ),
    );
  }

  Widget _buildScanning(AppLocalizations l10n, Color accent) {
    return ConstrainedBox(
      key: const ValueKey('scanning'),
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            child: SizedBox(
              width: 320,
              height: 220,
              child: Lottie.asset(AppAssets.loadingAnimation, repeat: true),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.scanningStorage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.desktopWelcomeScanningFolder(_scanPath ?? ''),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: 280,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                minHeight: 4,
                color: accent,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSongs(AppLocalizations l10n, Color accent) {
    final folder = _scanPath ?? '';
    return ConstrainedBox(
      key: const ValueKey('no-songs'),
      constraints: const BoxConstraints(maxWidth: 560),
      child: _Panel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber.withValues(alpha: 0.06),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
              ),
              child: const Icon(
                LucideIcons.searchX,
                size: 40,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              l10n.noMusicDetected,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.desktopWelcomeNoSongsDesc(folder),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.desktopWelcomeNoSongsTip,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 28),
            _WelcomeButton(
              label: l10n.desktopWelcomeChooseFolder,
              icon: LucideIcons.folderOpen,
              accent: accent,
              primary: true,
              autofocus: true,
              onPressed: _chooseFolder,
            ),
            const SizedBox(height: 12),
            _WelcomeButton(
              label: l10n.desktopWelcomeScanAgain,
              icon: LucideIcons.refreshCw,
              accent: accent,
              primary: false,
              onPressed: folder.isEmpty ? null : () => _scan(folder),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _stage = _Stage.setup),
              child: Text(
                l10n.backToMainView,
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
