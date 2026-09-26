import 'dart:io';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/core/providers/providers.dart';
import 'package:looper_player/core/services/storage/storage_access.dart';
import '../../features/library/presentation/providers/library/library_notifier.dart';
import '../../features/settings/presentation/providers/settings_notifier.dart';
import '../../features/playback/presentation/providers/playback/playback_notifier.dart';
import '../widgets/common/folder_picker_helper.dart';
import 'package:looper_player/core/utils/l10n.dart';

part 'welcome_screen.g.dart';
part 'glow_orb.dart';
part 'premium_button.dart';
part 'scanning_lottie_animation.dart';
part 'welcome_states.dart';

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
          title: context.l10n.addCustomFolder,
          description: context.l10n.addCustomFolderDesc,
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
            context.l10n.addFolder,
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
}
