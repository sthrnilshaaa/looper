import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:looper_player/ui/android/player/lyrics/widgets/android_lyrics_menu_sheet.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/playback/presentation/providers/lyrics/lyrics_notifier.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/core/services/screen_awake.dart';

import '../widgets/lyrics/advanced_lyric_renderer.dart';
import '../widgets/lyrics/desktop_lyrics_toolbar.dart';
import '../widgets/lyrics/lyrics_scale.dart';
import '../widgets/lyrics/lyrics_skeleton.dart';
import 'package:looper_player/core/utils/l10n.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/services/haptics/haptic_snack_bar.dart';

enum LyricsSyncMode {
  line,
  word,
  char;

  /// From AppSettings.lyricsSyncStyle. Unknown/empty (installs from before
  /// the setting existed) means the default, the character wipe.
  static LyricsSyncMode fromSetting(String value) => switch (value) {
    'line' => LyricsSyncMode.line,
    'word' => LyricsSyncMode.word,
    _ => LyricsSyncMode.char,
  };

  String get settingValue => name;
}

class LyricsView extends ConsumerStatefulWidget {
  const LyricsView({super.key});

  @override
  ConsumerState<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends ConsumerState<LyricsView> {
  LyricsSyncMode get _syncMode => LyricsSyncMode.fromSetting(
    ref.watch(settingsProvider.select((s) => s.lyricsSyncStyle)),
  );

  void _setSyncMode(LyricsSyncMode mode) => ref
      .read(settingsProvider.notifier)
      .updateLyricsSyncStyle(mode.settingValue);

  @override
  void initState() {
    super.initState();
    _enableWakelock();
  }

  @override
  void dispose() {
    _disableWakelock();
    super.dispose();
  }

  void _enableWakelock() => ScreenAwake.set(this, true);

  void _disableWakelock() => ScreenAwake.set(this, false);

  @override
  Widget build(BuildContext context) {
    final syncMode = _syncMode;
    if (!UiUtils.isDesktop) return _buildLyrics(context, syncMode);

    // Read everything here, not inside the LayoutBuilder: its builder runs
    // during layout, where providers must not be watched.
    final lyricsState = ref.watch(lyricsProvider);
    final userScale = LyricsScale.normalize(
      ref.watch(settingsProvider.select((s) => s.lyricsFontScale)),
    );
    final song = ref.watch(playbackProvider.select((s) => s.currentSong));
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final isFullscreen = ref.watch(lyricsFullscreenProvider);
    // Offered once the user has scrolled the active line out of view.
    final showResync =
        ref.watch(lyricsManualScrollProvider) &&
        !ref.watch(lyricsActiveLineVisibleProvider);
    final fullscreenNotifier = ref.read(lyricsFullscreenProvider.notifier);
    final alignment = ref.watch(
      settingsProvider.select((s) => s.lyricsAlignment),
    );

    final lyricsPane = LayoutBuilder(
      builder: (context, constraints) {
        final paneWidth = constraints.maxWidth;
        final autoScale = LyricsScale.auto(paneWidth);
        return Stack(
          children: [
            Positioned.fill(
              child: _buildLyrics(
                context,
                syncMode,
                desktop: (lyricsState: lyricsState, song: song),
                fontScale: userScale * autoScale,
                onFontScaleChanged: (scale) =>
                    settingsNotifier.updateLyricsFontScale(scale / autoScale),
                // Centred lyrics keep a 900px column in the middle of the
                // pane. Left/right aligned lyrics use the full pane width.
                horizontalPadding: alignment == 'center'
                    ? math.max(24.0, (paneWidth - 900) / 2)
                    : 24.0,
                bottomPadding: constraints.maxHeight * 0.45,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: IgnorePointer(
                ignoring: !showResync,
                child: AnimatedOpacity(
                  opacity: showResync ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Center(
                    child: Material(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.9),
                      shape: const StadiumBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        key: const ValueKey('lyrics-resync'),
                        onTap: () => ref
                            .read(lyricsManualScrollProvider.notifier)
                            .set(false),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.refreshCw,
                                size: 14,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                context.l10n.resync,
                                style: AppFonts.jostStyle(
                                  color: Colors.black,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 16,
              child: DesktopLyricsToolbar(
                onMenu: song == null
                    ? null
                    : () => showLyricsMenuDialog(context, ref, song),
                isFullscreen: isFullscreen,
                onToggleFullscreen: () => fullscreenNotifier.set(!isFullscreen),
              ),
            ),
          ],
        );
      },
    );
    // Scrolling by hand (wheel, touchpad or drag) pauses auto-follow, as on
    // Android; the Re-sync button or the renderer's own timer resumes it.
    void markManualScroll() =>
        ref.read(lyricsManualScrollProvider.notifier).set(true);
    final pane = Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) markManualScroll();
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if ((notification is ScrollUpdateNotification &&
                  notification.dragDetails != null) ||
              (notification is ScrollStartNotification &&
                  notification.dragDetails != null)) {
            markManualScroll();
          }
          return false;
        },
        child: lyricsPane,
      ),
    );
    if (!isFullscreen) return pane;
    // Esc leaves lyrics-only full screen.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            fullscreenNotifier.set(false),
      },
      child: Focus(autofocus: true, child: pane),
    );
  }

  /// The lyrics body. [desktop] carries the state the desktop branch has
  /// already watched (its caller runs inside a LayoutBuilder); without it
  /// the providers are watched here, as on mobile.
  Widget _buildLyrics(
    BuildContext context,
    LyricsSyncMode syncMode, {
    ({LyricsState lyricsState, Song? song})? desktop,
    double? fontScale,
    ValueChanged<double>? onFontScaleChanged,
    double? horizontalPadding,
    double? bottomPadding,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final LyricsState lyricsState =
        desktop?.lyricsState ?? ref.watch(lyricsProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              // Cross-fades between the three states. The keys are fixed per
              // state, so new lines for the same state (an offset change,
              // a word-sync upgrade) update the renderer in place instead
              // of fading it out and back in.
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (current, previous) => Stack(
                  fit: StackFit.expand,
                  children: [...previous, ?current],
                ),
                child: lyricsState.isLoading
                    ? const LyricsSkeleton(key: ValueKey('loading'))
                    : lyricsState.rawLrc == null
                    ? KeyedSubtree(
                        key: const ValueKey('empty'),
                        child: _buildNoLyricsState(
                          context,
                          l10n,
                          primaryColor,
                          desktop: desktop,
                        ),
                      )
                    : AdvancedLyricRenderer(
                        key: const ValueKey('lyrics'),
                        lines: lyricsState.parsedLines,
                        synced: lyricsState.isSynced,
                        mode: syncMode,
                        onSeek: (pos) =>
                            ref.read(playbackProvider.notifier).seek(pos),
                        fontScale: fontScale,
                        onFontScaleChanged: onFontScaleChanged,
                        horizontalPadding: horizontalPadding,
                        bottomPadding: bottomPadding,
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Illustrated empty state shown when no lyrics could be found, with a
  /// button to import a local .lrc/.txt file for the currently playing song.
  Widget _buildNoLyricsState(
    BuildContext context,
    AppLocalizations l10n,
    Color primaryColor, {
    ({LyricsState lyricsState, Song? song})? desktop,
  }) {
    final song = desktop != null
        ? desktop.song
        : ref.watch(playbackProvider.select((s) => s.currentSong));

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Soft glow behind the illustration
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          primaryColor.withValues(alpha: 0.16),
                          primaryColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  // Main disc with a music file glyph
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Icon(
                      LucideIcons.fileMusic,
                      size: 40,
                      color: primaryColor.withValues(alpha: 0.7),
                    ),
                  ),
                  // "not found" badge overlapping the disc
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1E1E1E),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.searchX,
                        size: 16,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.lyricsNotAvailable,
              textAlign: TextAlign.center,
              style: AppFonts.familyStyle(
                AppFonts.spaceGrotesk,
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.lyricsNotAvailableHint,
              textAlign: TextAlign.center,
              style: AppFonts.jostStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 28),
            if (song != null)
              _ImportLyricsButton(
                onTap: () => _importLyricsFile(context, song),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _importLyricsFile(BuildContext context, Song song) async {
    final l10n = AppLocalizations.of(context)!;
    AppHaptics.medium();
    try {
      final result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['lrc', 'txt'],
      );
      if (result == null || result.path == null) return;

      final file = File(result.path!);
      final content = await file.readAsString();
      if (content.trim().isEmpty) return;

      await ref.read(lyricsProvider.notifier).applyCustomLyrics(song, content);

      if (mounted) {
        ScaffoldMessenger.of(context).showHapticSnackBar(
          AppHaptics.success,
          SnackBar(content: Text(l10n.customLyricsAppliedSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showHapticSnackBar(
          AppHaptics.error,
          SnackBar(content: Text(context.l10n.failedToImportLyrics('$e'))),
        );
      }
    }
  }

  Widget _buildModeSelector([bool isShort = false]) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeButton(
            label: l10n.syncModeLine,
            isSelected: _syncMode == LyricsSyncMode.line,
            isShort: isShort,
            onTap: () {
              _setSyncMode(LyricsSyncMode.line);
            },
          ),
          _ModeButton(
            label: l10n.syncModeWord,
            isSelected: _syncMode == LyricsSyncMode.word,
            isShort: isShort,
            onTap: () {
              _setSyncMode(LyricsSyncMode.word);
            },
          ),
          _ModeButton(
            label: l10n.syncModeChar,
            isSelected: _syncMode == LyricsSyncMode.char,
            isShort: isShort,
            onTap: () {
              _setSyncMode(LyricsSyncMode.char);
            },
          ),
        ],
      ),
    );
  }
}

class _ImportLyricsButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ImportLyricsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: primary.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.filePlus, size: 18, color: primary),
              const SizedBox(width: 8),
              Text(
                l10n.importLyricsFile,
                style: AppFonts.jostStyle(
                  color: primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isShort;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isShort = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isShort ? 12 : 20,
          vertical: isShort ? 6 : 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Text(
          label,
          style: AppFonts.jostStyle(
            fontSize: isShort ? 10 : 11,
            fontWeight: FontWeight.normal,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Colors.grey[400],
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
