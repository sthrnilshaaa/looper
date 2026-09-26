import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/playback/presentation/providers/lyrics/lyrics_notifier.dart';
import 'package:looper_player/features/playback/presentation/providers/lyrics/lyrics_selection_notifier.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'lyrics_share_sheet.dart';
import 'package:looper_player/core/utils/l10n.dart';

/// Floating pill bar shown above the lyrics list while the user has an
/// active multi-line selection (started via long-press in `AdvancedLyricLine`).
/// Lets them cancel the selection or open the share preview.
class LyricsSelectionToolbar extends ConsumerWidget {
  final Song song;

  const LyricsSelectionToolbar({super.key, required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(lyricsSelectionProvider);
    // final accentColor = Color(ref.watch(settingsProvider.select((s) => s.accentColor)));

    return IgnorePointer(
      ignoring: !selection.isActive,
      child: AnimatedSlide(
        offset: selection.isActive ? Offset.zero : const Offset(0, -0.3),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: selection.isActive ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.s),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(lyricsSelectionProvider.notifier).clear();
                  },
                  icon: const Icon(
                    LucideIcons.x,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                Expanded(
                  child: Text(
                    context.l10n.linesSelected(selection.count),
                    textAlign: TextAlign.center,
                    style: AppFonts.jostStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (!selection.isActive) return;
                    HapticFeedback.mediumImpact();
                    final allLines = ref.read(lyricsProvider).parsedLines;
                    final selected = allLines.sublist(
                      selection.startIndex!,
                      selection.endIndex! + 1,
                    );
                    showLyricsShareSheet(
                      context,
                      ref,
                      song: song,
                      lines: selected,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSecondary,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.share2,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          context.l10n.share,
                          style: AppFonts.jostStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
