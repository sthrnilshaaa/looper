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
      icon: LucideIcons.mousePointer2,
      title: l10n.gestureScroll,
      description: l10n.gestureScrollDesc,
    ),
    _GestureTip(
      icon: LucideIcons.chevronsDown,
      title: l10n.gestureSwipeDown,
      description: l10n.gestureSwipeDownDesc,
    ),
  ];
}

/// Options that live in the lyrics ⋮ menu sheet.
List<_GestureTip> _lyricsMenuTips(BuildContext context) {
  final l10n = context.l10n;
  return [
    _GestureTip(
      icon: LucideIcons.sparkles,
      title: l10n.findWordSyncedLyrics,
      description: l10n.tipFindWordSyncDesc,
    ),
    _GestureTip(
      icon: LucideIcons.searchCheck,
      title: l10n.findSyncedLyrics,
      description: l10n.tipFindSyncedDesc,
    ),
    _GestureTip(
      icon: LucideIcons.highlighter,
      title: l10n.lyricsHighlightStyle,
      description: l10n.tipHighlightStyleDesc,
    ),
    _GestureTip(
      icon: LucideIcons.timer,
      title: l10n.lyricsTiming,
      description: l10n.tipLyricsTimingDesc,
    ),
    _GestureTip(
      icon: LucideIcons.globe,
      title: l10n.changeLyricsProvider,
      description: l10n.tipChangeProviderDesc,
    ),
    _GestureTip(
      icon: LucideIcons.fileText,
      title: l10n.tipOwnLyrics,
      description: l10n.tipOwnLyricsDesc,
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
    // height regardless of content - this tutorial's header + tips +
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

class _LyricsGesturesTutorialSheet extends StatefulWidget {
  const _LyricsGesturesTutorialSheet();

  @override
  State<_LyricsGesturesTutorialSheet> createState() =>
      _LyricsGesturesTutorialSheetState();
}

class _LyricsGesturesTutorialSheetState
    extends State<_LyricsGesturesTutorialSheet> {
  bool _menuTab = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gestures = _lyricsGestureTips(context);
    // Scroll freely gets the full-width card under the four quick gestures.
    final scroll = gestures[3];
    final quick = [gestures[0], gestures[1], gestures[2], gestures[4]];

    Widget tab(String label, bool menu) {
      final selected = _menuTab == menu;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _menuTab = menu),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                style: AppFonts.jostStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? Colors.black
                      : Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return AppBottomSheetContainer(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                l10n.lyricsGestures,
                style: AppFonts.jostStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  tab(l10n.lyricsTipsGestures, false),
                  const SizedBox(width: 4),
                  tab(l10n.lyricsTipsMenu, true),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _menuTab
                      ? _TipList(
                          key: const ValueKey('menu'),
                          tips: _lyricsMenuTips(context),
                        )
                      : Column(
                          key: const ValueKey('gestures'),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var row = 0; row < 2; row++) ...[
                              if (row > 0) const SizedBox(height: 10),
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: _TipCard(tip: quick[row * 2]),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _TipCard(tip: quick[row * 2 + 1]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            _TipCard(tip: scroll, wide: true),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  l10n.gotIt,
                  style: AppFonts.jostStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
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

/// One gesture as a card: its icon on a soft tile, then title and line.
class _TipCard extends StatelessWidget {
  final _GestureTip tip;
  final bool wide;

  const _TipCard({required this.tip, this.wide = false});

  @override
  Widget build(BuildContext context) {
    final iconTile = Container(
      height: wide ? 56 : 64,
      width: wide ? 56 : null,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(tip.icon, color: Colors.white, size: 26),
    );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          tip.title,
          style: AppFonts.jostStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          tip.description,
          style: AppFonts.jostStyle(
            fontSize: 12,
            height: 1.35,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(22),
      ),
      child: wide
          ? Row(
              children: [
                iconTile,
                const SizedBox(width: 14),
                Expanded(child: text),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [iconTile, const SizedBox(height: 14), text],
            ),
    );
  }
}

/// The menu tips as rows in one card.
class _TipList extends StatelessWidget {
  final List<_GestureTip> tips;

  const _TipList({super.key, required this.tips});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          for (var i = 0; i < tips.length; i++) ...[
            if (i > 0)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.white.withValues(alpha: 0.06),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(tips[i].icon, color: Colors.white, size: 20),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tips[i].title,
                          style: AppFonts.jostStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tips[i].description,
                          style: AppFonts.jostStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
