import 'package:looper_player/core/services/memory_manager.dart';
import 'package:looper_player/core/motion/looper_scroll_physics.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show GestureBinding;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/features/settings/presentation/widgets/tiles/theme/theme_settings_tiles.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:looper_player/core/providers/providers.dart';
import 'core/services/storage/db_service.dart';
import 'core/theme/app_fonts.dart';
import 'core/services/appambit_reporter.dart';
import 'ui/home_screen/home_screen.dart';

import 'package:metadata_god/metadata_god.dart';
import 'package:looper_player/core/theme/theme_provider.dart';
import 'package:looper_player/ui/widgets/common/keyboard_handler.dart';
import 'package:looper_player/ui/widgets/common/desktop_ui_scale.dart';
import 'core/utils/logger_helper.dart';
import 'core/services/window/window_geometry.dart';
import 'core/services/window/window_geometry_listener.dart';
import 'core/utils/ui_utils.dart';
import 'package:looper_player/core/utils/l10n.dart';

final dbInitializerProvider = FutureProvider<void>((ref) async {
  LoggerHelper.write('dbInitializerProvider: Initializing db and settings...');
  await DbService.init();
  await ref.read(settingsProvider.notifier).initialization;
  LoggerHelper.write('dbInitializerProvider: Initialization finished.');
});

void main(List<String> args) async {
  // Startup timing: how long each boot stage takes, and the time to the
  // first frame, written to the log once it is ready (Settings > Export
  // logs). Measurement only - it changes no ordering.
  final startup = Stopwatch()..start();
  final stageMs = <String, int>{};
  Future<void> timed(String stage, Future<void> work) async {
    final began = startup.elapsedMilliseconds;
    try {
      await work;
    } finally {
      stageMs[stage] = startup.elapsedMilliseconds - began;
    }
  }

  WidgetsFlutterBinding.ensureInitialized();
  // Touch events arrive on the input clock, not on vsync; on a 90/120Hz panel
  // that makes drag deltas land unevenly across frames, so dragged surfaces
  // (the Fluid Player, sheets) step instead of glide. Resampling aligns them
  // to the frame clock.
  if (Platform.isAndroid) {
    MemoryManager.install();
    GestureBinding.instance.resamplingEnabled = true;
  }
  AppHaptics.init();

  // Capture unhandled Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    LoggerHelper.writeLocal(
      'Flutter Framework Exception: ${details.exceptionAsString()}',
      details.exception,
      details.stack,
    );
  };

  // Capture unhandled asynchronous errors
  PlatformDispatcher.instance.onError = (error, stack) {
    LoggerHelper.writeLocal('Unhandled Async Exception: $error', error, stack);
    return true;
  };

  // Crash reporting starts alongside the other boot stages instead of ahead
  // of them: on device it took ~150 ms of a ~180 ms launch on its own.
  // Nothing below needs it, so the first frame no longer waits for it.
  final Future<void> reporterInit = timed(
    'reporter',
    AppAmbitReporter.start().catchError((Object e, StackTrace stack) {
      LoggerHelper.writeLocal('AppAmbitSdk start error: $e', e, stack);
    }),
  );

  // Initialize rolling file logging helper in parallel
  final Future<void> logsInit = LoggerHelper.init()
      .then((_) {
        LoggerHelper.write('=======================================');
        LoggerHelper.write('Application starting...');
        LoggerHelper.write('Arguments: $args');
      })
      .catchError((e, s) {});

  final String? initialFile = args.isNotEmpty ? args.first : null;

  // Initialize desktop/window setups in parallel
  final Future<void> desktopInit = () async {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      try {
        await windowManager.ensureInitialized();
        final geometry = WindowGeometry.sanitize(
          await WindowGeometryStore.load(),
          WindowGeometry.desktopSize(),
        );
        final position = (geometry?.x != null && geometry?.y != null)
            ? Offset(geometry!.x!, geometry.y!)
            : null;
        WindowOptions windowOptions = WindowOptions(
          size: geometry?.size ?? WindowGeometry.defaultSize,
          minimumSize: WindowGeometry.minimumSize,
          center: position == null,
          skipTaskbar: false,
          titleBarStyle: TitleBarStyle.hidden,
          title: 'Looper Player',
          backgroundColor: const Color(0xFF121214),
        );
        await windowManager.waitUntilReadyToShow(windowOptions, () async {
          if (position != null) {
            await windowManager.setPosition(position);
          }
          await windowManager.show();
          if (geometry?.maximized ?? false) {
            await windowManager.maximize();
          }
          await windowManager.focus();
        });
      } catch (e, s) {
        LoggerHelper.write('Failed to initialize Window Manager', e, s);
        // The Windows runner leaves the window hidden for window_manager to
        // show; make sure a failed setup can't leave it invisible.
        if (Platform.isWindows) {
          try {
            await windowManager.show();
          } catch (_) {}
        }
      }
    }
  }();

  // Initialize database in parallel
  final Future<void> dbInit = () async {
    try {
      await DbService.init();
    } catch (e, s) {
      LoggerHelper.write('Main startup: Failed to load DB', e, s);
    }
  }();

  // Initialize native plugins in parallel
  final Future<void> nativePluginsInit = () async {
    try {
      await MetadataGod.initialize();
    } catch (e, s) {
      LoggerHelper.write('Failed to initialize MetadataGod', e, s);
    }
    try {
      MpvAudioKit.ensureInitialized();
    } catch (e, s) {
      LoggerHelper.write('Failed to initialize MpvAudioKit', e, s);
    }
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (_) {}
  }();

  // Check permissions in parallel (status check only - no automatic permission prompt dialogs on startup)
  bool permissionsGranted = true;
  final Future<void> permissionCheck = () async {
    if (Platform.isAndroid) {
      try {
        final results = await Future.wait([
          Permission.audio.isGranted,
          Permission.storage.isGranted,
          Permission.notification.isGranted,
        ]);
        permissionsGranted = results.any((granted) => granted);
      } catch (e, s) {
        LoggerHelper.write('Failed to check permissions on startup', e, s);
        permissionsGranted = false;
      }
    }
  }();

  // Wait for all boot-up stages concurrently
  await Future.wait([
    timed('logs', logsInit),
    timed('window', desktopInit),
    timed('db', dbInit),
    timed('plugins', nativePluginsInit),
    timed('permissions', permissionCheck),
    if (AppAmbitReporter.mustStartBeforeUi) reporterInit,
  ]);
  final beforeRunApp = startup.elapsedMilliseconds;

  runApp(
    ProviderScope(
      overrides: [
        startupFileProvider.overrideWithValue(initialFile),
        startupPermissionsGrantedProvider.overrideWithValue(permissionsGranted),
      ],
      child: const MyApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final firstFrame = startup.elapsedMilliseconds;
    // Wait for the reporter so its own time is in the line too.
    await reporterInit;
    LoggerHelper.write(
      'Startup timing (ms): '
      '${stageMs.entries.map((e) => '${e.key}=${e.value}').join(', ')}, '
      'runApp at $beforeRunApp, '
      'first frame at $firstFrame',
    );
  });
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbInit = ref.watch(dbInitializerProvider);
    final isInitialized = dbInit.asData != null;

    final themeState = isInitialized ? ref.watch(themeProvider) : null;
    final settings = isInitialized ? ref.watch(settingsProvider) : null;

    Widget buildHome() {
      return dbInit.when(
        data: (_) => KeyboardHandler(
          child: UiUtils.isDesktop
              ? const WindowGeometryListener(child: HomeScreen())
              : const HomeScreen(),
        ),
        loading: () => const PreAppLoadingScreenContent(),
        error: (err, stack) {
          LoggerHelper.write(
            'Error during dbInitializerProvider execution: $err',
            err,
            stack,
          );
          return CrashRecoveryScreen(error: err.toString(), stack: stack);
        },
      );
    }

    // Build the MaterialApp using either dynamic/loaded settings or fallback values.
    final ColorScheme colorScheme = (themeState != null)
        ? themeState.colorScheme
        : ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          );

    final bool useNewFont = settings?.useNewFont ?? false;
    final String customFontFamily = settings?.customFontFamily ?? '';
    final int customFontWeightDelta = settings?.customFontWeightDelta ?? 0;
    final String language = settings?.language ?? '';

    final String fontFamily = useNewFont
        ? (customFontFamily.isEmpty ? 'Stack Sans Text' : customFontFamily)
        : 'Stack Sans Text';

    final fontFallback = AppFonts.scriptFallbackFor(fontFamily);
    final textTheme = AppFonts.adjustTextTheme(
      ThemeData.dark().textTheme.apply(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFallback,
        displayColor: Colors.white,
        bodyColor: Colors.white70,
      ),
      useNewFont ? customFontWeightDelta : 0,
    );

    Widget buildMaterialApp(ColorScheme colorScheme) {
      return MaterialApp(
        navigatorObservers: AppAmbitReporter.navigatorObservers,
        scaffoldMessengerKey: scaffoldMessengerKey,
        debugShowCheckedModeBanner: false,
        title: 'Looper Player',
        color: Colors.transparent,
        scrollBehavior: const LooperScrollBehavior(),
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: colorScheme,
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallback,
          textTheme: textTheme,
          // Material 3 defaults snackbars to inverseSurface, a near-white
          // block on this dark theme. Use a plain near-black instead. Their
          // bottom inset clears the navbar / music bar (AndroidMainScreen).
          snackBarTheme: SnackBarThemeData(
            backgroundColor: Colors.black.withValues(alpha: 0.9),
            contentTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: fontFamily,
              fontFamilyFallback: fontFallback,
            ),
            actionTextColor: colorScheme.primary,
            closeIconColor: Colors.white70,
            behavior: SnackBarBehavior.floating,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
        ),
        // No app-wide theme animation: with the accent following the
        // artwork, every song change re-themed the app, and a 1 s theme lerp
        // rebuilt the entire tree on every frame of it (~25 ms frames, ~40
        // fps for a second on a 120 Hz phone). The new accent now lands in a
        // single rebuild, after the song-change motion (ThemeNotifier).
        themeAnimationDuration: Duration.zero,
        locale: language.isEmpty || language == 'system'
            ? null
            : Locale(language),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => DesktopUiScale(
          scale: settings?.desktopUiScale ?? 1.0,
          child: child!,
        ),
        home: buildHome(),
      );
    }

    return buildMaterialApp(colorScheme);
  }
}

class PreAppLoadingScreenContent extends StatelessWidget {
  const PreAppLoadingScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F0F0C),
      body: SizedBox.shrink(),
    );
  }
}

class CrashRecoveryScreen extends StatefulWidget {
  final String error;
  final StackTrace? stack;

  const CrashRecoveryScreen({super.key, required this.error, this.stack});

  @override
  State<CrashRecoveryScreen> createState() => _CrashRecoveryScreenState();
}

class _CrashRecoveryScreenState extends State<CrashRecoveryScreen> {
  String _savedPath = '';
  bool _isSaving = true;

  @override
  void initState() {
    super.initState();
    _dumpCrashLog();
  }

  Future<void> _dumpCrashLog() async {
    final path = await LoggerHelper.saveCrashLog(widget.error, widget.stack);
    if (mounted) {
      setState(() {
        _savedPath = path;
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFF0F0F1A),
          body: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFFF5252),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.appCrashedTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.appCrashedDesc,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        context.l10n.appCrashedDetails,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isSaving)
                    const CircularProgressIndicator()
                  else ...[
                    if (_savedPath.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          context.l10n.crashReportSaved,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFB4BEFE),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (_savedPath.isNotEmpty)
                          ElevatedButton.icon(
                            onPressed: () =>
                                LoggerHelper.shareCrashLog(_savedPath),
                            icon: const Icon(Icons.share, size: 16),
                            label: Text(context.l10n.shareLog),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C7086),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ElevatedButton.icon(
                          onPressed: () {
                            exit(0);
                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: Text(context.l10n.restartApp),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5252),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
