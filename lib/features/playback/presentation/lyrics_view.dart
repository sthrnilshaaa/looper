import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/app_fonts.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/playback/presentation/lyrics_notifier.dart';
import 'package:looper_player/features/playback/presentation/playback_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/app_loading_indicator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'widgets/advanced_lyric_renderer.dart';

enum LyricsSyncMode { line, word, char }

class LyricsView extends ConsumerStatefulWidget {
  const LyricsView({super.key});

  @override
  ConsumerState<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends ConsumerState<LyricsView> {
  LyricsSyncMode _syncMode = LyricsSyncMode.line;

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

  Future<void> _enableWakelock() async {
    try {
      await WakelockPlus.enable();
    } catch (e) {}
  }

  Future<void> _disableWakelock() async {
    try {
      await WakelockPlus.disable();
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lyricsState = ref.watch(lyricsProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Stack(
      children: [
        Column(
          children: [
            if (_syncMode != LyricsSyncMode.line) _buildDisclaimer(l10n),
            Expanded(
              child: lyricsState.isLoading
                  ? const AppLoadingIndicator(size: 220.0)
                  : lyricsState.rawLrc == null
                  ? _buildNoLyricsState(context, l10n, primaryColor)
                  : AdvancedLyricRenderer(
                      lines: lyricsState.parsedLines,
                      mode: _syncMode,
                      onSeek: (pos) => ref.read(playbackProvider.notifier).seek(pos),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  /// Illustrated empty state shown when no lyrics could be found, with a
  /// button to import a local .lrc/.txt file for the currently playing song.
  Widget _buildNoLyricsState(BuildContext context, AppLocalizations l10n, Color primaryColor) {
    final song = ref.watch(playbackProvider.select((s) => s.currentSong));

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
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                        border: Border.all(color: Colors.black.withValues(alpha: 0.4), width: 2),
                      ),
                      child: const Icon(LucideIcons.searchX, size: 16, color: Colors.white54),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.lyricsNotAvailable,
              textAlign: TextAlign.center,
              style: AppFonts.spaceGroteskStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.lyricsNotAvailableHint,
              textAlign: TextAlign.center,
              style: AppFonts.jostStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
            ),
            const SizedBox(height: 28),
            if (song != null) _ImportLyricsButton(onTap: () => _importLyricsFile(context, song)),
          ],
        ),
      ),
    );
  }

  Future<void> _importLyricsFile(BuildContext context, Song song) async {
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.mediumImpact();
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.customLyricsAppliedSuccess)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to import lyrics: $e')));
      }
    }
  }

  Widget _buildDisclaimer(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, size: 12, color: Colors.orange),
          const SizedBox(width: 6),
          Text(
            l10n.approximatedSyncNoWordTimings,
            style: AppFonts.spaceGroteskStyle(
              fontSize: 10,
              color: Colors.orange,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
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
              setState(() => _syncMode = LyricsSyncMode.line);
            },
          ),
          _ModeButton(
            label: l10n.syncModeWord,
            isSelected: _syncMode == LyricsSyncMode.word,
            isShort: isShort,
            onTap: () {
              setState(() => _syncMode = LyricsSyncMode.word);
            },
          ),
          _ModeButton(
            label: l10n.syncModeChar,
            isSelected: _syncMode == LyricsSyncMode.char,
            isShort: isShort,
            onTap: () {
              setState(() => _syncMode = LyricsSyncMode.char);
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
        padding: EdgeInsets.symmetric(horizontal: isShort ? 12 : 20, vertical: isShort ? 6 : 10),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Text(
          label,
          style: AppFonts.jostStyle(
            fontSize: isShort ? 10 : 11,
            fontWeight: FontWeight.normal,
            color: isSelected ? Theme.of(context).colorScheme.onPrimary : Colors.grey[400],
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
