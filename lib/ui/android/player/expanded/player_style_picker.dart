import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/providers/player_expand_provider.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/motion.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';

import 'android_expanded_player.dart';
import 'styled_player_layout.dart';

/// Holding the artwork for ~3 s opens the style picker. A shorter hold
/// still runs [onLongPress] (on release, so the two never both fire).
class HoldForPlayerStyles extends StatefulWidget {
  final Widget child;
  final VoidCallback? onLongPress;
  const HoldForPlayerStyles({super.key, required this.child, this.onLongPress});

  @override
  State<HoldForPlayerStyles> createState() => _HoldForPlayerStylesState();
}

class _HoldForPlayerStylesState extends State<HoldForPlayerStyles> {
  Timer? _timer;

  void _start() {
    _timer?.cancel();
    AppHaptics.selection();
    // The long press itself starts after 500 ms (kLongPressTimeout), so 2.5 s
    // lands at ~3.0 s of hold.
    _timer = Timer(const Duration(milliseconds: 2500), () {
      _timer = null;
      if (!mounted) return;
      AppHaptics.success();
      Navigator.of(context, rootNavigator: true).push(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 240),
          pageBuilder: (_, _, _) => const PlayerStylePickerScreen(),
          transitionsBuilder: (_, a, _, child) =>
              FadeTransition(opacity: a, child: child),
        ),
      );
    });
  }

  void _end() {
    final t = _timer;
    if (t == null) return; // Already opened the picker.
    t.cancel();
    _timer = null;
    if (widget.onLongPress != null) {
      AppHaptics.medium();
      widget.onLongPress!();
    }
  }

  void _cancel() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onLongPressStart: (_) => _start(),
    onLongPressEnd: (_) => _end(),
    onLongPressCancel: _cancel,
    child: widget.child,
  );
}

/// Figma "Linear Style" (devvlooper 2162:1582): swipe between live previews
/// of each player style; the check saves, back discards.
class PlayerStylePickerScreen extends ConsumerStatefulWidget {
  const PlayerStylePickerScreen({super.key});

  @override
  ConsumerState<PlayerStylePickerScreen> createState() =>
      _PlayerStylePickerScreenState();
}

class _PlayerStylePickerScreenState
    extends ConsumerState<PlayerStylePickerScreen> {
  static const _styles = PlayerLayoutStyle.values;
  // Figma: 270-wide cards with 30 gaps on a 402 frame.
  static const double _cardFraction = 270 / 402;
  static const double _gapFraction = 30 / 402;

  late final PageController _pages;
  late int _index;
  late final int _initialStyleIndex;

  @override
  void initState() {
    super.initState();
    _initialStyleIndex = PlayerLayoutStyle.fromSetting(
      ref.read(settingsProvider).playerStyle,
    ).index;
    _index = _initialStyleIndex;
    _pages = PageController(
      initialPage: _index,
      viewportFraction: _cardFraction + _gapFraction,
    );
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  String _name(AppLocalizations l10n, PlayerLayoutStyle s) => switch (s) {
    PlayerLayoutStyle.classic => l10n.playerStyleClassic,
    PlayerLayoutStyle.arc => l10n.playerStyleArc,
    PlayerLayoutStyle.linear => l10n.playerStyleLinear,
    PlayerLayoutStyle.card => l10n.playerStyleCard,
  };

  void _save() {
    AppHaptics.success();
    ref.read(settingsProvider.notifier).updatePlayerStyle(_styles[_index].name);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mq = MediaQuery.of(context);
    final reduced = Motion.reducedOf(context);
    final duration = reduced
        ? Duration.zero
        : const Duration(milliseconds: 240);
    // Previews are always the portrait layout, at the phone's own shape.
    final Size frame = mq.size.width < mq.size.height
        ? mq.size
        : const Size(402, 874);

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  _CircleButton(
                    icon: Icons.arrow_back_rounded,
                    label: l10n.back,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      l10n.playerStyleTitle(_name(l10n, _styles[_index])),
                      textAlign: TextAlign.center,
                      style: AppFonts.jostStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _CircleButton(
                    icon: Icons.check_rounded,
                    label: l10n.save,
                    onTap: _save,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _styles.length,
                onPageChanged: (i) {
                  AppHaptics.selection();
                  setState(() => _index = i);
                },
                itemBuilder: (context, i) {
                  final isSelected = i == _index;
                  final isAlreadySet = i == _initialStyleIndex;
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: mq.size.width * _gapFraction / 2,
                    ),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: frame.width / frame.height,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (_index != i) {
                              AppHaptics.selection();
                              _pages.animateToPage(
                                i,
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeOutCubic,
                              );
                            }
                          },
                          child: AnimatedScale(
                            scale: isSelected || reduced ? 1.0 : 0.94,
                            duration: duration,
                            curve: Curves.easeOutCubic,
                            child: AnimatedOpacity(
                              opacity: isSelected || reduced ? 1.0 : 0.65,
                              duration: duration,
                              curve: Curves.easeOutCubic,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                foregroundDecoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isAlreadySet
                                        ? const Color(0xFF888888)
                                        : Colors.transparent,
                                    width: 2.0,
                                  ),
                                ),
                                child: _StylePreview(
                                  style: _styles[i],
                                  frame: frame,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < _styles.length; i++)
                  AnimatedContainer(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 16 : 8,
                    height: 4,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _CircleButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Material(
      color: Colors.white.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox.square(
          dimension: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    ),
  );
}

/// The real player, playing the current song, drawn at full phone size and
/// scaled into the card. Non-interactive and isolated from the live player:
/// no Heroes, and its art rect / expand progress go to a private scope.
class _StylePreview extends StatelessWidget {
  final PlayerLayoutStyle style;
  final Size frame;
  const _StylePreview({required this.style, required this.frame});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: FittedBox(
        child: SizedBox.fromSize(
          size: frame,
          child: MediaQuery(
            data: mq.copyWith(size: frame),
            child: ProviderScope(
              overrides: [
                playerArtworkRectProvider.overrideWith(PlayerArtworkRect.new),
                playerExpandProgressProvider.overrideWith((ref) {
                  final n = ValueNotifier<double>(1.0);
                  ref.onDispose(n.dispose);
                  return n;
                }),
              ],
              child: HeroMode(
                enabled: false,
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: AndroidExpandedPlayer(previewStyle: style),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
