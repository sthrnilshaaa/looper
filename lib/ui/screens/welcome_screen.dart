import 'dart:io';
import 'package:looper_player/core/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/core/providers.dart';
import 'package:looper_player/core/storage_access.dart';
import '../../features/library/presentation/library_notifier.dart';
import '../../features/settings/presentation/settings_notifier.dart';
import '../../features/playback/presentation/playback_notifier.dart';
import '../widgets/folder_picker_helper.dart';

part 'welcome_screen.g.dart';

enum WelcomeState { initial, scanning, indexing, noSongs }

@Riverpod(keepAlive: true)
class WelcomeBypassed extends _$WelcomeBypassed {
  @override
  bool build() {
    final forceWelcome = ref.watch(forceWelcomeProvider);
    if (forceWelcome) return false;

    // On desktop platforms (Linux, Windows, macOS), bypass mobile permission screen
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true;
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

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with WidgetsBindingObserver {
  WelcomeState _currentState = WelcomeState.initial;
  String _scanStatusMessage = "Initializing scanner...";

  // True if standard audio/storage is granted, or (github flavor only) All
  // Files Access - either is enough to scan.
  bool _permissionGranted = false;
  bool _notificationGranted = false;
  bool _audioGranted = false;
  bool _allFilesGranted = false; // github flavor only, optional
  bool _canOfferAllFiles = false; // github flavor on Android 11+
  bool _autoScanTriggered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionStatus();
    }
  }

  Future<void> _checkPermissionStatus() async {
    bool notif = false;
    bool aud = false;
    final allFiles = await StorageAccess.allFilesStatus();

    if (Platform.isAndroid) {
      try {
        notif = await Permission.notification.isGranted;
        aud =
            (await Permission.audio.isGranted) ||
            (await Permission.storage.isGranted);
      } catch (_) {
        aud = true;
        notif = true;
      }
    } else {
      notif = true;
      aud = true;
    }

    if (mounted) {
      setState(() {
        _notificationGranted = notif;
        _audioGranted = aud;
        _allFilesGranted = allFiles.granted;
        _canOfferAllFiles = allFiles.canOffer;
        _permissionGranted = aud || allFiles.granted;
      });
    }
  }

  Future<void> _requestNotificationPermission() async {
    HapticFeedback.lightImpact();
    if (!Platform.isAndroid) return;
    try {
      await Permission.notification.request();
    } catch (_) {}
    await _checkPermissionStatus();
    ref.read(playbackProvider.notifier).updateNotification();
  }

  Future<void> _requestAudioPermission() async {
    HapticFeedback.lightImpact();
    if (!Platform.isAndroid) return;
    try {
      await Permission.audio.request();
      await Permission.storage.request();
    } catch (_) {}
    await _checkPermissionStatus();
  }

  Future<void> _requestAllFilesPermission() async {
    HapticFeedback.lightImpact();
    await StorageAccess.requestAllFilesAccess();
    await _checkPermissionStatus();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // Elegant animated-like glowing backgrounds
          Positioned(
            top: -100,
            right: -100,
            child: _GlowOrb(color: colorScheme.primary.withValues(alpha: 0.12)),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: _GlowOrb(color: colorScheme.primary.withValues(alpha: 0.08)),
          ),

          // Subtle vignette overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    Colors.white.withValues(alpha: 0.001),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Layout Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28.0,
                    vertical: 24.0,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    switchInCurve: Curves.easeInOutCubic,
                    switchOutCurve: Curves.easeInOutCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.05),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _buildStateContent(colorScheme, l10n),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateContent(ColorScheme colorScheme, AppLocalizations l10n) {
    switch (_currentState) {
      case WelcomeState.scanning:
        return _buildScanningState(colorScheme, l10n);
      case WelcomeState.indexing:
        return _buildIndexingState(colorScheme, l10n);
      case WelcomeState.noSongs:
        return _buildNoSongsState(colorScheme, l10n);
      case WelcomeState.initial:
      default:
        return _buildInitialState(colorScheme, l10n);
    }
  }

  // State 1: Initial Premium Welcome State
  Widget _buildInitialState(ColorScheme colorScheme, AppLocalizations l10n) {
    final librarySongs = ref.watch(libraryProvider).songs;
    final settings = ref.watch(settingsProvider);

    return Column(
      key: const ValueKey('initial_state'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Brand logo container with glowing borders
        Container(
          padding: const EdgeInsets.all(28.0),
          child: SizedBox(
            height: 100.s,
            width: 200.s,
            child: SvgPicture.asset(
              'assets/main_logo_transparent.svg',
              fit: BoxFit.contain,
              placeholderBuilder: (context) => Icon(
                LucideIcons.music,
                size: 50.s,
                color: colorScheme.primary.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Clean & Modern Title Typography
        Text(
          l10n.appTitle.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28.ts,
            fontWeight: FontWeight.w200,
            letterSpacing: 10,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "LOOPER PLAYER",
          style: TextStyle(
            fontSize: 11.ts,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary.withValues(alpha: 0.6),
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 32),

        // Premium About Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.info,
                    size: 16.s,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.aboutLooperPlayer.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12.ts,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n.welcomeAboutDesc,
                style: TextStyle(
                  fontSize: 13.ts,
                  height: 1.6,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Interactive Permission Checklist (Sequential Setup)
        if (Platform.isAndroid) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.shieldCheck,
                      size: 16.s,
                      color: Color(settings.accentColor),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.systemPermissionChecklist.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12.ts,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 1. Notification Permission Row
                _buildPermissionRow(
                  title: l10n.notificationAccess.toUpperCase(),
                  description: l10n.welcomeNotificationDesc,
                  isGranted: _notificationGranted,
                  onGrant: _requestNotificationPermission,
                  colorScheme: colorScheme,
                  accentColor: Color(settings.accentColor),
                  l10n: l10n,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Divider(height: 1, color: Colors.white10),
                ),

                // 2. Music & Audio Permission Row
                _buildPermissionRow(
                  title: l10n.musicAudioAccess.toUpperCase(),
                  description: l10n.welcomeMusicAudioDesc,
                  isGranted: _audioGranted,
                  onGrant: _requestAudioPermission,
                  colorScheme: colorScheme,
                  accentColor: Color(settings.accentColor),
                  l10n: l10n,
                ),

                // 3. All Files Access Row (github flavor, optional)
                // Its availability is only known after an async native
                // check, so grow it in rather than letting the card jump.
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _canOfferAllFiles
                      ? Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: Divider(height: 1, color: Colors.white10),
                            ),
                            _buildPermissionRow(
                              title: l10n.allFilesAccess.toUpperCase(),
                              description: l10n.welcomeAllFilesDesc,
                              isGranted: _allFilesGranted,
                              onGrant: _requestAllFilesPermission,
                              colorScheme: colorScheme,
                              accentColor: Color(settings.accentColor),
                              l10n: l10n,
                            ),
                          ],
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],

        // Modern Action Button area
        Column(
          children: [
            // GO START Button (Colored when standard permission is granted, otherwise greyed)
            _PremiumButton(
              onPressed: _permissionGranted
                  ? () async {
                      await _startStorageScanFlow();
                    }
                  : null,
              label: l10n.goStart,
              icon: LucideIcons.playCircle,
              gradientColors: _permissionGranted
                  ? [
                      Color(settings.accentColor),
                      Color(settings.accentColor).withValues(alpha: 0.75),
                    ]
                  : [
                      Colors.grey.withValues(alpha: 0.3),
                      Colors.grey.withValues(alpha: 0.2),
                    ],
            ),
            const SizedBox(height: 24),

            // Scan Completion Status feedback
            if (_permissionGranted && librarySongs.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Color(settings.accentColor).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Color(settings.accentColor).withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.checkCircle2,
                      color: Color(settings.accentColor),
                      size: 18.s,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.scanCompleteSongsDetected(librarySongs.length),
                      style: TextStyle(
                        fontSize: 12.ts,
                        fontWeight: FontWeight.bold,
                        color: Color(settings.accentColor),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPermissionRow({
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onGrant,
    required ColorScheme colorScheme,
    required Color accentColor,
    required AppLocalizations l10n,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2.0),
          padding: const EdgeInsets.all(6.0),
          decoration: BoxDecoration(
            color: isGranted
                ? accentColor.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.03),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isGranted ? LucideIcons.check : LucideIcons.shieldAlert,
            size: 16.s,
            color: isGranted ? accentColor : Colors.white60,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11.ts,
                  height: 1.4,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (!isGranted)
          SizedBox(
            height: 30.s,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: accentColor.withValues(alpha: 0.15),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 0.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: onGrant,
              child: Text(
                l10n.grant,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.ts,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 4.0,
            ),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              l10n.granted,
              style: TextStyle(
                color: accentColor,
                fontSize: 11.ts,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  // State 2: Deep Scanning State
  Widget _buildScanningState(ColorScheme colorScheme, AppLocalizations l10n) {
    return Column(
      key: const ValueKey('scanning_state'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _ScanningLottieAnimation(),
        const SizedBox(height: 24),
        Text(
          l10n.deepStorageScanProgress,
          style: TextStyle(
            fontSize: 16.ts,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            l10n.welcomeScanningFoldersDesc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.ts,
              color: Colors.white.withValues(alpha: 0.4),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // State 2b: Brief final "Indexing..." beat shown after the scan itself
  // finds songs but before handing off to Home - covers the moment Pass 2
  // enrichment (tags/art/lyrics) is just getting started in the background,
  // so the app doesn't cut straight from "scanning" to a Home screen full
  // of half-populated song rows.
  Widget _buildIndexingState(ColorScheme colorScheme, AppLocalizations l10n) {
    return Column(
      key: const ValueKey('indexing_state'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _ScanningLottieAnimation(),
        const SizedBox(height: 24),
        Text(
          "INDEXING YOUR LIBRARY...",
          style: TextStyle(
            fontSize: 16.ts,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            "Filling in titles, artwork and lyrics for your songs.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.ts,
              color: Colors.white.withValues(alpha: 0.4),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // State 3: User Information / Instructions State when No Songs are Found
  Widget _buildNoSongsState(ColorScheme colorScheme, AppLocalizations l10n) {
    final settings = ref.watch(settingsProvider);
    return Column(
      key: const ValueKey('no_songs_state'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Informational Alert Icon
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.amber.withValues(alpha: 0.05),
            border: Border.all(
              color: Colors.amber.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Icon(LucideIcons.searchCode, size: 48.s, color: Colors.amber),
        ),
        const SizedBox(height: 24),

        Text(
          l10n.noMusicDetected,
          style: TextStyle(
            fontSize: 18.ts,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.welcomeNoSongsDesc,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.ts,
            color: Colors.white.withValues(alpha: 0.4),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 36),

        // Custom Step-by-Step Instruction Cards
        _buildInstructionStep(
          stepNumber: "1",
          title: l10n.connectDevice,
          description: l10n.welcomeInstructionConnectDesc,
          icon: LucideIcons.usb,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 16),
        _buildInstructionStep(
          stepNumber: "2",
          title: l10n.transferMusicFiles,
          description: l10n.welcomeInstructionTransferDesc,
          icon: LucideIcons.arrowDownToLine,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 16),
        _buildInstructionStep(
          stepNumber: "3",
          title: l10n.downloadAudioDirectly,
          description: l10n.welcomeInstructionDownloadDesc,
          icon: LucideIcons.globe,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 16),
        // The automatic scan above only checks a fixed list of standard
        // folder names (Music, Download, Podcasts, ...) plus anything
        // manually added - without All Files Access (removed for Play
        // Store compliance) it can't blanket-discover an arbitrarily-named
        // folder or every SD card on its own, so this is the direct path
        // to fixing that instead of leaving the user to find "Add Folder"
        // buried in Settings after they've already given up here.
        _buildInstructionStep(
          stepNumber: "4",
          title: "Add a Custom Folder",
          description:
              "If your music lives in a folder with a different name, or on an SD card, add it directly.",
          icon: LucideIcons.folderPlus,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => FolderPickerHelper.pickFolder(context, ref),
          icon: Icon(
            LucideIcons.folderPlus,
            size: 16,
            color: colorScheme.primary,
          ),
          label: Text(
            "Add Folder",
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 36),

        // Quick Retry/Actions
        _PremiumButton(
          onPressed: _startStorageScanFlow,
          label: l10n.rescanStorage,
          icon: LucideIcons.refreshCw,
          gradientColors: [
            Color(settings.accentColor),
            Color(settings.accentColor).withValues(alpha: 0.75),
          ],
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _currentState = WelcomeState.initial;
            });
          },
          child: Text(
            l10n.backToMainView,
            style: TextStyle(
              fontSize: 12.ts,
              color: Colors.white60,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionStep({
    required String stepNumber,
    required String title,
    required String description,
    required IconData icon,
    required ColorScheme colorScheme,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.015),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.03),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36.s,
            width: 36.s,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, size: 16.s, color: colorScheme.primary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "STEP $stepNumber: $title",
                  style: TextStyle(
                    fontSize: 11.ts,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.ts,
                    color: Colors.white.withValues(alpha: 0.45),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Scan & Permission Flow Functions
  Future<void> _startStorageScanFlow() async {
    _autoScanTriggered = true;
    if (!mounted) return;
    setState(() {
      _currentState = WelcomeState.scanning;
      _scanStatusMessage = "Preparing music scan...";
    });

    if (!mounted) return;
    setState(() {
      _scanStatusMessage = "Checking system permissions...";
    });

    // Check again
    await _checkPermissionStatus();

    if (!mounted) return;
    if (Platform.isAndroid && !_permissionGranted) {
      final localizations = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.storagePermissionRequired)),
      );
      setState(() {
        _currentState = WelcomeState.initial;
      });
      return;
    }

    setState(() {
      _scanStatusMessage =
          "Traversing standard device directories recursively...";
    });

    // Determine scan roots including all popular directories for maximum coverage
    final List<String> scanRoots = [];
    // Broad/coarse roots (e.g. the whole storage root) that must NOT be
    // recorded as-is in libraryFolders - see recordFolder below.
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
    } else if (Platform.isAndroid && await StorageAccess.hasAllFilesAccess()) {
      // github flavor with All Files Access: walk the whole internal storage
      // root and every SD card. These are coarse roots - the real per-song
      // folders are recorded after the scan instead (see below).
      final roots = await StorageAccess.wholeStorageRoots();
      scanRoots.addAll(roots);
      coarseRoots.addAll(roots);
    } else if (Platform.isAndroid) {
      // Without All Files Access (always the case on the Play build) raw
      // traversal can't reach an arbitrary/whole-storage root or SD cards
      // - see AndroidManifest.xml. These specific top-level
      // public directories are still listable with just
      // READ_MEDIA_AUDIO/READ_EXTERNAL_STORAGE; everything else (custom
      // folders, SD cards, formats MediaStore doesn't index) is covered by
      // the MediaStore + SAF merges inside LibraryScanner.scanDirectory().
      final List<String> commonPaths = [
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
      ];
      for (final cp in commonPaths) {
        if (!scanRoots.contains(cp)) scanRoots.add(cp);
      }
    }

    if (!mounted) return;
    setState(() {
      _scanStatusMessage = "Scanning ${scanRoots.length} folders...";
    });

    final existingRoots = scanRoots
        .where((path) => Directory(path).existsSync())
        .toList();

    // Scanned as one batch (not a per-path loop calling scanLibrary) so the
    // library's live watches are only paused/resumed once for the whole
    // set, not once per folder - see scanMultipleFolders' doc comment for
    // why looping the single-folder call here used to mean up to ~24 full
    // library requery+rebuild cycles stacked into the first few seconds on
    // Home right after this screen hands off.
    //
    // coarseRoots is only populated with All Files Access (github flavor),
    // and then every root is coarse - so either all roots are recorded as
    // their own libraryFolders entries, or none are.
    final totalSongsDiscovered = existingRoots.isEmpty
        ? 0
        : await ref
              .read(libraryProvider.notifier)
              .scanMultipleFolders(
                existingRoots,
                recordFolder: coarseRoots.isEmpty,
              );

    if (!mounted) return;

    if (coarseRoots.isNotEmpty) {
      // Coarse roots were scanned without recording themselves in
      // libraryFolders - record the real per-song folders instead, so
      // Settings > Library Folders shows e.g. "Music" / "Songs" rather
      // than the whole storage root.
      await ref.read(libraryProvider.notifier).recordActualLibraryFolders();
    }

    if (!mounted) return;

    if (totalSongsDiscovered == 0) {
      if (mounted) {
        setState(() {
          _currentState = WelcomeState.noSongs;
        });
      }
      return;
    }

    // A brief fixed pause here (not tied to actual enrichment progress,
    // which can take much longer for a large library - that's the whole
    // point of the quick first pass) just smooths the handoff to Home
    // instead of cutting straight from "scanning" to a screen full of
    // still-enriching placeholder rows.
    setState(() {
      _currentState = WelcomeState.indexing;
    });
    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;

    ref.read(forceWelcomeProvider.notifier).set(false);
    ref.read(welcomeBypassedProvider.notifier).set(true);
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  const _GlowOrb({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320.s,
      height: 320.s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

class _PremiumButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;
  final List<Color> gradientColors;

  const _PremiumButton({
    required this.onPressed,
    required this.label,
    required this.icon,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;
    return Container(
      width: double.infinity,
      height: 56.s,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: isEnabled
              ? gradientColors
              : [
                  Colors.white.withValues(alpha: 0.05),
                  Colors.white.withValues(alpha: 0.02),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isEnabled ? Colors.white : Colors.white30,
                size: 20.s,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15.ts,
                  fontWeight: FontWeight.bold,
                  color: isEnabled ? Colors.white : Colors.white30,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanningLottieAnimation extends StatelessWidget {
  const _ScanningLottieAnimation();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: 400.s,
        height: 300.s,
        child: Lottie.asset(
          'assets/loading.json',
          fit: BoxFit.contain,
          repeat: true,
        ),
      ),
    );
  }
}
