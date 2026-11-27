import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/motion.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';

import 'android_lyrics_screen.dart';
import 'lyrics_screen_style.dart';

/// Opens the full-screen Lyrics Style preview and selection screen.
void openLyricsStylePicker(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, _, _) => const LyricsStylePickerScreen(),
      transitionsBuilder: (_, a, _, child) =>
          FadeTransition(opacity: a, child: child),
    ),
  );
}

String lyricsStyleLabel(AppLocalizations l10n, LyricsScreenStyle s) =>
    switch (s) {
      LyricsScreenStyle.classic => l10n.lyricsStyleClassic,
      LyricsScreenStyle.arc => l10n.lyricsStyleArc,
      LyricsScreenStyle.spatial => l10n.lyricsStyleSpatial,
      LyricsScreenStyle.vinyl => l10n.lyricsStyleVinyl,
      LyricsScreenStyle.editorial => l10n.lyricsStyleEditorial,
      LyricsScreenStyle.karaoke => l10n.lyricsStyleKaraoke,
      LyricsScreenStyle.poster => l10n.lyricsStylePoster,
      LyricsScreenStyle.oled => l10n.lyricsStyleOled,
      LyricsScreenStyle.m3 => l10n.lyricsStyleM3,
      LyricsScreenStyle.timeline => l10n.lyricsStyleTimeline,
      LyricsScreenStyle.zen => l10n.lyricsStyleZen,
      LyricsScreenStyle.bigtype => l10n.lyricsStyleBigType,
    };

/// Swipe between live previews of each of the 12 lyrics screen styles;
/// the check saves, back discards.
class LyricsStylePickerScreen extends ConsumerStatefulWidget {
  const LyricsStylePickerScreen({super.key});

  @override
  ConsumerState<LyricsStylePickerScreen> createState() =>
      _LyricsStylePickerScreenState();
}

class _LyricsStylePickerScreenState
    extends ConsumerState<LyricsStylePickerScreen> {
  static const _styles = LyricsScreenStyle.values;
  static const double _cardFraction = 270 / 402;
  static const double _gapFraction = 30 / 402;

  PageController? _pages;
  bool? _wasLandscape;
  late int _index;
  late final int _initialStyleIndex;

  @override
  void initState() {
    super.initState();
    _initialStyleIndex = LyricsScreenStyle.fromSetting(
      ref.read(settingsProvider).lyricsStyle,
    ).index;
    _index = _initialStyleIndex;
  }

  PageController _controllerFor(bool isLandscape) {
    if (_pages == null || _wasLandscape != isLandscape) {
      final old = _pages;
      if (old != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
      }
      _wasLandscape = isLandscape;
      _pages = PageController(
        initialPage: _index,
        viewportFraction: isLandscape ? 0.62 : (_cardFraction + _gapFraction),
      );
    }
    return _pages!;
  }

  @override
  void dispose() {
    _pages?.dispose();
    super.dispose();
  }

  void _save() {
    AppHaptics.success();
    ref.read(settingsProvider.notifier).updateLyricsStyle(_styles[_index].name);
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
    final bool isLandscape = mq.size.width > mq.size.height;
    final PageController pages = _controllerFor(isLandscape);
    final Size frame = mq.size;

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, isLandscape ? 10 : 16, 16, 0),
              child: Row(
                children: [
                  _CircleButton(
                    icon: Icons.arrow_back_rounded,
                    label: l10n.back,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      l10n.lyricsStyleTitle(
                        lyricsStyleLabel(l10n, _styles[_index]),
                      ),
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
            SizedBox(height: isLandscape ? 12 : 28),
            Expanded(
              child: PageView.builder(
                key: ValueKey(isLandscape),
                controller: pages,
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
                      horizontal:
                          mq.size.width *
                          (isLandscape ? 0.025 : _gapFraction / 2),
                    ),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: frame.width / frame.height,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (_index != i) {
                              AppHaptics.selection();
                              pages.animateToPage(
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
                                child: TickerMode(
                                  enabled: isSelected,
                                  child: _LyricsStylePreview(
                                    style: _styles[i],
                                    frame: frame,
                                  ),
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
            SizedBox(height: isLandscape ? 10 : 18),
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
            SizedBox(height: isLandscape ? 8 : 16),
            _LyricsPickerQuickToggles(l10n: l10n),
            SizedBox(height: isLandscape ? 8 : 20),
          ],
        ),
      ),
    );
  }
}

class _LyricsPickerQuickToggles extends ConsumerWidget {
  final AppLocalizations l10n;
  const _LyricsPickerQuickToggles({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dynamicColor = ref.watch(
      settingsProvider.select((s) => s.dynamicColorActiveLyrics),
    );
    final transOn = ref.watch(
      settingsProvider.select((s) => s.showLyricsTranslation),
    );
    final ownBg = ref.watch(
      settingsProvider.select((s) => s.lyricsOwnBackground),
    );
    final notifier = ref.read(settingsProvider.notifier);

    Widget pill({
      required IconData icon,
      required String label,
      required bool active,
      required VoidCallback onTap,
    }) => Material(
      color: active
          ? Colors.white.withValues(alpha: 0.18)
          : Colors.white.withValues(alpha: 0.06),
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          AppHaptics.selection();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? Colors.white : Colors.white54,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: AppFonts.jostStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: active ? Colors.white : Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          pill(
            icon: Icons.palette_outlined,
            label: l10n.dynamicColorActiveLyrics,
            active: dynamicColor,
            onTap: () => notifier.updateDynamicColorActiveLyrics(!dynamicColor),
          ),
          const SizedBox(width: 8),
          pill(
            icon: Icons.translate_rounded,
            label: l10n.showLyricsTranslation,
            active: transOn,
            onTap: () => notifier.updateShowLyricsTranslation(!transOn),
          ),
          const SizedBox(width: 8),
          pill(
            icon: Icons.layers_outlined,
            label: l10n.lyricsFollowPlayerBackground,
            active: !ownBg,
            onTap: () => notifier.updateLyricsFollowPlayerBackground(ownBg),
          ),
        ],
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

class _LyricsStylePreview extends StatelessWidget {
  final LyricsScreenStyle style;
  final Size frame;
  const _LyricsStylePreview({required this.style, required this.frame});

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
            child: HeroMode(
              enabled: false,
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: AndroidLyricsScreen(previewStyle: style),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
