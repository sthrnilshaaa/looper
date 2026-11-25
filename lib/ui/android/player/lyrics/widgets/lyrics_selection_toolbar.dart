import 'package:flutter/material.dart';
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
import 'package:looper_player/core/services/haptics/app_haptics.dart';

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
            height: 56,
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Material(
                  color: Colors.black.withValues(alpha: 0.06),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      AppHaptics.light();
                      ref.read(lyricsSelectionProvider.notifier).clear();
                    },
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        LucideIcons.x,
                        color: Colors.black,
                        size: 18,
                        semanticLabel: MaterialLocalizations.of(
                          context,
                        ).cancelButtonLabel,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.linesSelected(selection.count),
                    style: AppFonts.jostStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (!selection.isActive) return;
                    AppHaptics.medium();
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
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(22),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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
