import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/app_fonts.dart';
import 'package:looper_player/features/library/presentation/library_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';

/// Small pill shown while LibraryScanner.enrichPendingSongs (the scanner's
/// background "Pass 2") is still filling in tags/art/lyrics for songs the
/// quick first pass already inserted - fades out on its own once the count
/// reaches 0. Meant to sit centered in the Home tab's app-bar row, between
/// the avatar and the search/settings buttons.
class EnrichmentIndicator extends ConsumerWidget {
  const EnrichmentIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(songsNeedingEnrichmentProvider);
    final l10n = AppLocalizations.of(context)!;

    // RepaintBoundary: the spinner repaints every frame for as long as the
    // pill is up. Without its own layer, that dirtied the whole Home scroll
    // view's layer (every section, image and blur in it) 60 times a second
    // for the entire enrichment run - on top of the enrichment work itself.
    return RepaintBoundary(
      child: IgnorePointer(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: pending <= 0
              ? const SizedBox.shrink(key: ValueKey('empty'))
              : Container(
                  key: const ValueKey('pill'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.enrichingSongs(pending),
                        style: AppFonts.jostStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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
