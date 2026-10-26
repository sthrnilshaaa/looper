import 'package:looper_player/core/motion/looper_scroll_physics.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/ui/android/widgets/premium_section.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';

void showSleepTimerBottomSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    isScrollControlled: true,
    builder: (modalContext) => const SleepTimerSheetContent(),
  );
}

class SleepTimerSheetContent extends ConsumerStatefulWidget {
  const SleepTimerSheetContent({super.key});

  @override
  ConsumerState<SleepTimerSheetContent> createState() =>
      _SleepTimerSheetContentState();
}

class _SleepTimerSheetContentState
    extends ConsumerState<SleepTimerSheetContent> {
  int _customMinutes = 15;
  int _customSongs = 5;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final (
      isSleepTimerActive,
      sleepTimerDurationRemaining,
      sleepTimerSongsRemaining,
    ) = ref.watch(
      playbackProvider.select(
        (s) => (
          s.isSleepTimerActive,
          s.sleepTimerDurationRemaining,
          s.sleepTimerSongsRemaining,
        ),
      ),
    );
    final accentColor = Color(settings.accentColor);
    final useBlur =
        settings.alwaysBlurSheets ||
        (!settings.disableBlur && settings.enableDynamicTheming);
    final isPureBlack = settings.darkTheme;

    final sheetBg = isPureBlack
        ? Colors.black
        : (useBlur
              ? Colors.black.withValues(alpha: 0.6)
              : const Color(0xFF1E1E1E));

    Widget sheetContent = Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isPureBlack
              ? Colors.white10
              : Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(LucideIcons.timer, color: accentColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  l10n.sleepTimer,
                  style: AppFonts.jostStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isSleepTimerActive
                  ? (sleepTimerDurationRemaining != null
                        ? l10n.sleepTimerStoppingIn(
                            formatSleepTimerRemaining(
                              l10n,
                              durationRemaining: sleepTimerDurationRemaining,
                            ),
                          )
                        : l10n.sleepTimerStoppingAfter(
                            formatSleepTimerRemaining(
                              l10n,
                              songsRemaining: sleepTimerSongsRemaining,
                            ),
                          ))
                  : l10n.selectWhenToPause,
              style: AppFonts.jostStyle(
                fontSize: 14,
                color: isSleepTimerActive ? accentColor : Colors.white54,
              ),
            ),
            const SizedBox(height: 24),
            ..._buildSection(
              title: l10n.stopByTime,
              valueLabel: l10n.minutesShort(_customMinutes),
              accentColor: accentColor,
              onMinus: () {
                if (_customMinutes > 1) setState(() => _customMinutes--);
              },
              onPlus: () => setState(() => _customMinutes++),
              startArgs: () => (Duration(minutes: _customMinutes), null),
              chips: [
                for (final minutes in const [1, 5, 10, 30, 45])
                  _buildCustomChip(
                    label: l10n.minuteChip(minutes),
                    onTap: () => _startTimer(Duration(minutes: minutes)),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            ..._buildSection(
              title: l10n.stopBySongCount,
              valueLabel: l10n.songsCountTitle(_customSongs),
              accentColor: accentColor,
              onMinus: () {
                if (_customSongs > 1) setState(() => _customSongs--);
              },
              onPlus: () => setState(() => _customSongs++),
              startArgs: () => (null, _customSongs),
              chips: [
                for (final count in const [1, 2, 3, 5, 10])
                  _buildCustomChip(
                    label: l10n.songsCountTitle(count),
                    onTap: () => _startSongs(count),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            if (isSleepTimerActive)
              ElevatedButton.icon(
                onPressed: () {
                  AppHaptics.medium();
                  ref.read(playbackProvider.notifier).stopSleepTimer();
                  Navigator.pop(context);
                },
                icon: const Icon(LucideIcons.xCircle, size: 20),
                label: Text(
                  l10n.cancelSleepTimer,
                  style: AppFonts.jostStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
                  foregroundColor: Colors.redAccent,
                  elevation: 0,
                  side: const BorderSide(color: Colors.redAccent, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
          ],
        ),
      ),
    );

    if (useBlur && !isPureBlack) {
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: sheetContent,
          ),
        ),
      );
    }

    return sheetContent;
  }

  /// One "stop by ..." block: its caption, a stepper card with a Start
  /// button for the stepped value, and a row of preset [chips].
  /// [startArgs] gives the (duration, song count) Start should begin with.
  List<Widget> _buildSection({
    required String title,
    required String valueLabel,
    required Color accentColor,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
    required (Duration?, int?) Function() startArgs,
    required List<Widget> chips,
  }) {
    final l10n = AppLocalizations.of(context)!;

    Widget stepButton(IconData icon, VoidCallback onStep) => IconButton(
      onPressed: () {
        AppHaptics.light();
        onStep();
      },
      icon: Icon(icon, color: Colors.white70),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    return [
      Text(
        title,
        style: AppFonts.jostStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white38,
          letterSpacing: 1.5,
        ),
      ),
      const SizedBox(height: 12),
      PremiumSection(
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        useExpanded: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                stepButton(LucideIcons.minus, onMinus),
                const SizedBox(width: 16),
                Text(
                  valueLabel,
                  style: AppFonts.jostStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                stepButton(LucideIcons.plus, onPlus),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                AppHaptics.medium();
                final (duration, songCount) = startArgs();
                ref
                    .read(playbackProvider.notifier)
                    .startSleepTimer(duration: duration, songCount: songCount);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text(
                l10n.start,
                style: AppFonts.jostStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const LooperScrollPhysics(),
        child: Row(children: chips),
      ),
    ];
  }

  void _startTimer(Duration duration) {
    ref.read(playbackProvider.notifier).startSleepTimer(duration: duration);
    Navigator.pop(context);
  }

  void _startSongs(int count) {
    ref.read(playbackProvider.notifier).startSleepTimer(songCount: count);
    Navigator.pop(context);
  }

  Widget _buildCustomChip({
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.white.withValues(alpha: 0.06),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                label,
                style: AppFonts.jostStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String formatSleepTimerRemaining(
  AppLocalizations l10n, {
  Duration? durationRemaining,
  int? songsRemaining,
}) {
  if (durationRemaining != null) {
    final minutes = durationRemaining.inMinutes;
    final seconds = durationRemaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds';
  } else if (songsRemaining != null) {
    return l10n.songsLeft(songsRemaining);
  }
  return '';
}
