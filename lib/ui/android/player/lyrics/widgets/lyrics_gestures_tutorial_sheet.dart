import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/ui/widgets/sheets/app_bottom_sheet.dart';
import 'package:looper_player/core/utils/l10n.dart';

class _GestureTip {
  final IconData icon;
  final String title;
  final String description;

  const _GestureTip({
    required this.icon,
    required this.title,
    required this.description,
  });
}

List<_GestureTip> _lyricsGestureTips(BuildContext context) {
  final l10n = context.l10n;
  return [
    _GestureTip(
      icon: LucideIcons.pointer,
      title: l10n.gestureTapLine,
      description: l10n.gestureTapLineDesc,
    ),
    _GestureTip(
      icon: LucideIcons.hand,
      title: l10n.gestureLongPressLine,
      description: l10n.gestureLongPressLineDesc,
    ),
    _GestureTip(
      icon: LucideIcons.zoomIn,
      title: l10n.gesturePinch,
      description: l10n.gesturePinchDesc,
    ),
    _GestureTip(
      icon: LucideIcons.chevronsDown,
      title: l10n.gestureSwipeDown,
      description: l10n.gestureSwipeDownDesc,
    ),
  ];
}

/// Shows the one-time "hidden gestures" tutorial for the Lyrics screen.
/// Marks it as seen immediately (before the sheet even opens) so it's never
/// re-prompted — regardless of how the sheet ends up being dismissed
/// (the "Got it" button, the scrim, or the system back gesture).
Future<void> showLyricsGesturesTutorial(BuildContext context, WidgetRef ref) {
  ref.read(settingsProvider.notifier).updateLyricsGestureTutorialSeen(true);

  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    // Without this, showModalBottomSheet caps the sheet to ~9/16 of screen
    // height regardless of content - this tutorial's header + 4 tips +
    // button is just tall enough to exceed that on some devices, causing a
    // small "RenderFlex overflowed... on the bottom" (visible as the
    // debug-mode overflow banner). Matches the isScrollControlled: true +
    // SingleChildScrollView pattern the other sheets here already use.
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (context) => const _LyricsGesturesTutorialSheet(),
  );
}

class _LyricsGesturesTutorialSheet extends StatelessWidget {
  const _LyricsGesturesTutorialSheet();

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;

    return AppBottomSheetContainer(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(LucideIcons.sparkles, color: accentColor, size: 22),
                const SizedBox(width: 12),
                Text(
                  context.l10n.lyricsGestures,
                  style: AppFonts.jostStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.lyricsGesturesIntro,
              style: AppFonts.jostStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 20),
            for (final tip in _lyricsGestureTips(context)) ...[
              _TipRow(tip: tip, accentColor: accentColor),
              const SizedBox(height: 14),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  context.l10n.gotIt,
                  style: AppFonts.jostStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final _GestureTip tip;
  final Color accentColor;

  const _TipRow({required this.tip, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(tip.icon, color: accentColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tip.title,
                style: AppFonts.jostStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                tip.description,
                style: AppFonts.jostStyle(
                  fontSize: 13,
                  color: Colors.white60,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
