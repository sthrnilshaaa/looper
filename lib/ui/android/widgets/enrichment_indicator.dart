import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/motion.dart';
import 'package:looper_player/features/library/presentation/providers/library/library_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/common/looper_loader.dart';

/// Pill shown while LibraryScanner.enrichPendingSongs (the scanner's
/// background "Pass 2") is still filling in tags/art/lyrics for songs the
/// quick first pass already inserted. Meant to sit centered in the Home
/// tab's app-bar row (and above the Songs list).
///
/// Equalizer glyph + a count that rolls as it drops + a hairline that fills
/// with progress (done / the most pending seen this run). Enters with one
/// small scale-and-fade, leaves with a fade once the count reaches 0.
class EnrichmentIndicator extends ConsumerStatefulWidget {
  const EnrichmentIndicator({super.key});

  @override
  ConsumerState<EnrichmentIndicator> createState() =>
      _EnrichmentIndicatorState();
}

class _EnrichmentIndicatorState extends ConsumerState<EnrichmentIndicator> {
  // Largest pending count seen in this run; progress is measured against it.
  int _runTotal = 0;

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(songsNeedingEnrichmentProvider);
    if (pending <= 0) {
      _runTotal = 0;
    } else if (pending > _runTotal) {
      _runTotal = pending;
    }
    final double progress = _runTotal <= 0
        ? 0
        : (1 - pending / _runTotal).clamp(0.0, 1.0);
    final bool reduced = Motion.reducedOf(context);

    // RepaintBoundary: the glyph animates for as long as the pill is up;
    // without its own layer it would repaint the whole Home scroll view.
    return RepaintBoundary(
      child: IgnorePointer(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: reduced
                ? child
                : ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.92,
                      end: 1,
                    ).animate(animation),
                    child: child,
                  ),
          ),
          child: pending <= 0
              ? const SizedBox.shrink(key: ValueKey('empty'))
              : _Pill(
                  key: const ValueKey('pill'),
                  pending: pending,
                  progress: progress,
                ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({super.key, required this.pending, required this.progress});

  final int pending;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final Color accent = Theme.of(context).colorScheme.primary;
    final TextStyle style = AppFonts.jostStyle(
      color: Colors.white.withValues(alpha: 0.85),
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E10).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 14,
            spreadRadius: -4,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 7, 13, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                LooperLoader(size: 13, color: accent),
                const SizedBox(width: 8),
                // The count rolls up as it changes instead of snapping.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  transitionBuilder: (child, animation) => ClipRect(
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.6),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                  ),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [...previous, ?current],
                  ),
                  child: Text(
                    l10n.enrichingSongs(pending),
                    key: ValueKey(pending),
                    style: style,
                  ),
                ),
              ],
            ),
          ),
          // Progress hairline along the bottom edge.
          Positioned(
            left: 14,
            right: 14,
            bottom: 2,
            height: 1.5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(1),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: progress),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => FractionallySizedBox(
                      widthFactor: value,
                      alignment: Alignment.centerLeft,
                      child: ColoredBox(color: accent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
