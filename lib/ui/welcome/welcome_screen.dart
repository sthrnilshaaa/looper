import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:looper_player/core/providers/providers.dart';
import 'package:looper_player/core/services/storage/storage_access.dart';
import 'package:looper_player/core/utils/app_links.dart';
import 'package:looper_player/core/utils/desktop_paths.dart';
import 'package:looper_player/core/utils/motion.dart';
import 'package:looper_player/features/settings/presentation/widgets/tiles/about_settings_tiles.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/common/setup_kit.dart';
import '../../features/library/presentation/providers/library/library_notifier.dart';
import '../../features/playback/presentation/providers/playback/playback_notifier.dart';
import '../../features/settings/presentation/providers/settings_notifier.dart';

part 'welcome_screen.g.dart';

@Riverpod(keepAlive: true)
class WelcomeBypassed extends _$WelcomeBypassed {
  @override
  bool build() {
    final forceWelcome = ref.watch(forceWelcomeProvider);
    if (forceWelcome) return false;

    // Desktop (Linux, Windows, macOS) shows its own setup screen only while
    // there is no library yet. Until the library has loaded, assume set up,
    // so returning users never see the setup screen flash.
    if (!Platform.isAndroid && !Platform.isIOS) {
      if (!ref.watch(libraryProvider.select((s) => s.isInitialized))) {
        return true;
      }
      return ref.read(libraryProvider).songs.isNotEmpty ||
          ref.read(settingsProvider).libraryFolders.isNotEmpty;
    }

    // Re-derive when forceWelcome changes, and once more when the library
    // finishes its initial load (isInitialized flips false->true exactly
    // once and never again) - not on every subsequent library write.
    // Watching the full libraryProvider/songs list here previously made this
    // whole StateProvider - including the synchronous File.existsSync() calls
    // below - re-run on every library write, which happens routinely during
    // normal playback (see PlaybackNotifier's ~20s listen-time checkpoint),
    // stalling the UI thread with blocking filesystem I/O every time.
    ref.watch(libraryProvider.select((s) => s.isInitialized));
    final songs = ref.read(libraryProvider).songs;
    final settings = ref.read(settingsProvider);

    if (songs.isEmpty) {
      return settings.libraryFolders.isNotEmpty;
    }

    try {
      final checkCount = songs.length < 5 ? songs.length : 5;
      for (int i = 0; i < checkCount; i++) {
        if (File(songs[i].path).existsSync()) {
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void set(bool value) => state = value;
}

/// First-run setup: welcome, permissions, community, done. The library scan runs quietly in the background from
/// the moment permissions are granted, so there is no loading screen.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

enum _Page { welcome, permissions, community, done }

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  // "Start listening": the page eases toward you and fades into the dark.
  late final _exit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final _exitCurve = CurvedAnimation(
    parent: _exit,
    curve: Curves.easeInCubic,
  );
  late final _exitFade = Tween(begin: 1.0, end: 0.0).animate(_exitCurve);
  late final _exitZoom = Tween(begin: 1.0, end: 1.04).animate(_exitCurve);
  bool _leaving = false;
  _Page _page = _Page.welcome;
  bool _reverse = false;

  bool _notificationGranted = false;
  bool _audioGranted = false;
  bool _allFilesGranted = false; // github flavor only, optional
  bool _canOfferAllFiles = false; // github flavor on Android 11+
  bool _scanStarted = false;

  // True if standard audio/storage is granted, or (github flavor only) All
  // Files Access - either is enough to scan.
  bool get _permissionGranted => _audioGranted || _allFilesGranted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _exitCurve.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermissionStatus();
  }

  void _go(_Page p) => setState(() {
    _reverse = p.index < _page.index;
    _page = p;
  });

  Future<void> _checkPermissionStatus() async {
    bool notif = true;
    bool aud = true;
    final allFiles = await StorageAccess.allFilesStatus();
    if (Platform.isAndroid) {
      try {
        notif = await Permission.notification.isGranted;
        aud =
            (await Permission.audio.isGranted) ||
            (await Permission.storage.isGranted);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _notificationGranted = notif;
      _audioGranted = aud;
      _allFilesGranted = allFiles.granted;
      _canOfferAllFiles = allFiles.canOffer;
    });
  }

  Future<void> _requestNotificationPermission() async {
    if (!Platform.isAndroid) return;
    try {
      final status = await Permission.notification.request();
      // No dialog shows once permanently denied; send them to system settings.
      if (status.isPermanentlyDenied) await openAppSettings();
    } catch (_) {}
    await _checkPermissionStatus();
    ref.read(playbackProvider.notifier).updateNotification();
  }

  Future<void> _requestAudioPermission() async {
    if (!Platform.isAndroid) return;
    try {
      await Permission.audio.request();
      await Permission.storage.request();
    } catch (_) {}
    await _checkPermissionStatus();
  }

  Future<void> _requestAllFilesPermission() async {
    await StorageAccess.requestAllFilesAccess();
    await _checkPermissionStatus();
  }

  Future<void> _continueFromPermissions() async {
    if (Platform.isAndroid && !_permissionGranted) {
      await _requestAudioPermission();
      if (!mounted) return;
      if (!_permissionGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.storagePermissionRequired,
            ),
          ),
        );
        return;
      }
    }
    if (Platform.isAndroid && !_notificationGranted) {
      await _requestNotificationPermission();
      if (!mounted) return;
      if (!_notificationGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.notificationPermissionRequired,
            ),
          ),
        );
        return;
      }
    }
    if (!_scanStarted) {
      _scanStarted = true;
      unawaited(_scanLibrary());
    }
    if (mounted) _go(_Page.community);
  }

  /// Scans every standard music location. Runs detached from the UI: the
  /// notifier is captured up front so it finishes even after setup closes.
  Future<void> _scanLibrary() async {
    final library = ref.read(libraryProvider.notifier);
    final List<String> scanRoots = [];
    // Broad/coarse roots (e.g. the whole storage root) that must NOT be
    // recorded as-is in libraryFolders.
    final Set<String> coarseRoots = {};
    if (Platform.isLinux) {
      String defaultPath = '${Platform.environment['HOME']}/Music';
      try {
        final result = await Process.run('xdg-user-dir', ['MUSIC']);
        if (result.exitCode == 0 &&
            result.stdout.toString().trim().isNotEmpty) {
          defaultPath = result.stdout.toString().trim();
        }
      } catch (_) {}
      scanRoots.add(defaultPath);
    } else if (Platform.isWindows) {
      scanRoots.add(windowsMusicFolder(Platform.environment));
    } else if (Platform.isAndroid && await StorageAccess.hasAllFilesAccess()) {
      // github flavor with All Files Access: walk the whole internal storage
      // root and every SD card; the real per-song folders are recorded after.
      final roots = await StorageAccess.wholeStorageRoots();
      scanRoots.addAll(roots);
      coarseRoots.addAll(roots);
    } else if (Platform.isAndroid) {
      // Without All Files Access raw traversal only reaches these public
      // directories; LibraryScanner's MediaStore + SAF merges cover the rest.
      scanRoots.addAll(const [
        '/storage/emulated/0/Music',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Documents',
        '/storage/emulated/0/Audiobooks',
        '/storage/emulated/0/Podcasts',
        '/storage/emulated/0/Recordings',
        '/storage/emulated/0/Ringtones',
        '/storage/emulated/0/Alarms',
        '/storage/emulated/0/Notifications',
        '/storage/emulated/0/DCIM',
        '/storage/emulated/0/Pictures',
        '/storage/emulated/0/Movies',
      ]);
    }

    final existingRoots = scanRoots
        .where((path) => Directory(path).existsSync())
        .toList();
    if (existingRoots.isEmpty) return;
    // One batch so the library's live watches pause/resume once, not per
    // folder (see scanMultipleFolders).
    await library.scanMultipleFolders(
      existingRoots,
      recordFolder: coarseRoots.isEmpty,
    );
    if (coarseRoots.isNotEmpty) await library.recordActualLibraryFolders();
  }

  Future<void> _finish() async {
    if (_leaving) return; // already on the way out
    _leaving = true;
    if (!Motion.reducedOf(context)) await _exit.forward();
    if (!mounted) return;
    ref.read(forceWelcomeProvider.notifier).set(false);
    ref.read(welcomeBypassedProvider.notifier).set(true);
  }

  Future<void> _open(String url) async {
    if (url.isEmpty) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: _page == _Page.welcome,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _go(_Page.values[_page.index - 1]);
      },
      child: ColoredBox(
        color: kSetupBg,
        child: FadeTransition(
          opacity: _exitFade,
          child: ScaleTransition(
            scale: _exitZoom,
            child: Scaffold(
              backgroundColor: kSetupBg,
              body: SetupBackground(
                child: SetupSwitcher(
                  reverse: _reverse,
                  child: KeyedSubtree(
                    key: ValueKey(_page),
                    child: switch (_page) {
                      _Page.welcome => _welcome(l10n),
                      _Page.permissions => _permissions(l10n),
                      _Page.community => _community(l10n),
                      _Page.done => _done(l10n),
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _welcome(AppLocalizations l10n) => SetupPage(
    step: l10n.setupStep(1),
    body: const AboutHeroCard(),
    bottom: SetupBottomBar(
      label: l10n.setupBegin,
      leadingIcon: Icons.translate_rounded,
      onBack: () => _showLanguageSheet(context),
      onNext: Platform.isAndroid
          ? () => _go(_Page.permissions)
          : _continueFromPermissions,
    ),
  );

  Widget _permissions(AppLocalizations l10n) {
    Widget row(
      String title,
      String desc,
      IconData icon,
      bool on,
      Future<void> Function() request,
    ) => SetupRow(
      title: title,
      description: desc,
      icon: Icon(icon, size: 16, color: Colors.white),
      trailing: SetupCheck(on: on),
      filled: on,
      onTap: on ? null : request,
    );
    return SetupPage(
      step: l10n.setupStep(2),
      title: l10n.setupPermissionsTitle,
      description: l10n.setupPermissionsDesc,
      body: SetupCard(
        children: [
          row(
            l10n.setupNotifications,
            l10n.welcomeNotificationDesc,
            Icons.notifications_active_rounded,
            _notificationGranted,
            _requestNotificationPermission,
          ),
          // Media access is always asked; All Files Access (github, Android
          // 11+) is offered on top so the scan can walk the whole storage.
          row(
            l10n.setupMusicAudio,
            l10n.welcomeMusicAudioDesc,
            Icons.music_note_rounded,
            _audioGranted,
            _requestAudioPermission,
          ),
          if (_canOfferAllFiles)
            row(
              l10n.setupAllFiles,
              l10n.welcomeAllFilesDesc,
              Icons.description_rounded,
              _allFilesGranted,
              _requestAllFilesPermission,
            ),
        ],
      ),
      bottom: SetupBottomBar(
        label: l10n.setupContinue,
        onBack: () => _go(_Page.welcome),
        onNext: _continueFromPermissions,
      ),
    );
  }

  Widget _community(AppLocalizations l10n) {
    Widget link(String title, String desc, Widget icon, String url) => SetupRow(
      title: title,
      description: desc,
      trailing: SizedBox(width: 24, child: Center(child: icon)),
      onTap: () => _open(url),
    );
    return SetupPage(
      step: l10n.setupStep(3),
      title: l10n.setupCommunityTitle,
      description: l10n.setupCommunityDesc,
      body: SetupCard(
        children: [
          link(
            l10n.setupStarGithub,
            l10n.setupStarGithubDesc,
            const Icon(Icons.star_rounded, color: Colors.white, size: 24),
            AppLinks.githubStatsRepo,
          ),
          link(
            l10n.setupTelegram,
            l10n.setupTelegramDesc,
            const Icon(LucideIcons.send, color: Colors.white, size: 20),
            AppLinks.socialTelegram,
          ),
          if (AppLinks.upi.isNotEmpty)
            link(
              l10n.setupUpi,
              l10n.setupUpiDesc,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Text(
                  'UPI',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
              AppLinks.upi,
            ),
          link(
            l10n.setupKofi,
            l10n.setupKofiDesc,
            const Icon(LucideIcons.cupSoda, color: Colors.white, size: 20),
            AppLinks.koFi,
          ),
        ],
      ),
      bottom: SetupBottomBar(
        label: l10n.setupContinue,
        onBack: () => _go(_Page.permissions),
        onNext: () => _go(_Page.done),
      ),
    );
  }

  Widget _done(AppLocalizations l10n) => SetupPage(
    step: l10n.setupStep(4),
    expand: true,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(flex: 3),
        const Center(child: SetupDoneBadge()),
        const Spacer(flex: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(l10n.setupDoneTitle, style: setupTitleStyle()),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(l10n.setupDoneDesc, style: setupBody()),
        ),
      ],
    ),
    bottom: SetupBottomBar(label: l10n.setupStartListening, onNext: _finish),
  );
}

const _languages = [
  ('', null),
  ('en', 'English'),
  ('es', 'Español'),
  ('fr', 'Français'),
  ('de', 'Deutsch'),
  ('pt', 'Português'),
  ('ru', 'Русский'),
  ('it', 'Italiano'),
  ('zh', '中文'),
  ('ja', '日本語'),
  ('ko', '한국어'),
  ('ar', 'العربية'),
  ('tr', 'Türkçe'),
  ('nl', 'Nederlands'),
  ('hi', 'हिन्दी'),
];

void _showLanguageSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: kSetupCard,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        final current = ref.watch(settingsProvider.select((s) => s.language));
        final l10n = AppLocalizations.of(context)!;
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Text(
                  l10n.language,
                  style: setupBody(size: 20, color: Colors.white),
                ),
              ),
              for (final (code, name) in _languages)
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Text(
                    name ?? l10n.systemDefault,
                    style: setupBody(size: 16, color: Colors.white),
                  ),
                  trailing: SetupCheck(on: code == current),
                  onTap: () {
                    ref.read(settingsProvider.notifier).updateLanguage(code);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    ),
  );
}
