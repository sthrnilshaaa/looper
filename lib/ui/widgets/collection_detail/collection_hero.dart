import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// Hero layout, bottom-anchored: [title, 8, meta ~20, 24, actions 48, 16].
const double collectionHeroHeight = 440;
const double _heroActionsTop = collectionHeroHeight - 16 - 48;
const double _heroTitleBottom = _heroActionsTop - 24 - 20 - 8;

/// Full-bleed artwork fading into the page, with the title, the meta line
/// and the action row on top of it. Shared by the online and library
/// album / playlist / artist pages.
class CollectionHero extends ConsumerWidget {
  const CollectionHero({
    super.key,
    required this.title,
    required this.meta,
    required this.still,
    required this.actions,
    this.isArtist = false,
    this.albumArtist,
    this.album,
  });

  final String title;
  final String meta;

  /// Artwork shown when there is no motion art (or banner still).
  final Widget still;

  /// The 48-px action row.
  final Widget actions;

  /// Artist pages use the artist's wide banner.
  final bool isArtist;

  /// Album pages look up square motion art by these.
  final String? albumArtist;
  final String? album;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surface = Theme.of(context).colorScheme.surface;
    return SizedBox(
      height: collectionHeroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          still,
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.25),
                  Colors.transparent,
                  surface.withValues(alpha: 0.85),
                  surface,
                ],
                stops: const [0.0, 0.3, 0.8, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.jostStyle(
                      fontSize: 36,
                      height: 1.1,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: const [
                        Shadow(color: Colors.black38, blurRadius: 12),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (meta.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.jostStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(height: 48, child: actions),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Floats over a [CollectionHero]: only the back button (and [action]) at
/// first; a background, a small cover and the title fade in once the big
/// title scrolls under it, and [trailing] (Follow) slides in once the hero's
/// action row has.
class CollectionHeroBar extends StatelessWidget {
  const CollectionHeroBar({
    super.key,
    required this.controller,
    required this.title,
    required this.meta,
    required this.cover,
    required this.onBack,
    this.trailing,
    this.action,
  });

  final ScrollController controller;
  final String title;
  final String meta;

  /// 42-px cover beside the small title.
  final Widget cover;
  final VoidCallback onBack;
  final Widget? trailing;

  /// Always-visible button at the right end.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final barHeight = top + 8 + 48 + 8;
    double ramp(double offset, double start, double length) =>
        ((offset - start) / length).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final offset = controller.hasClients ? controller.offset : 0.0;
        final titleStart = _heroTitleBottom - barHeight - 20;
        final background = ramp(offset, titleStart - 80, 80);
        final reveal = Curves.easeOutCubic.transform(
          ramp(offset, titleStart, 40),
        );
        final follow = Curves.easeOutCubic.transform(
          ramp(offset, _heroActionsTop + 48 - barHeight - 24, 32),
        );
        return HeaderBackdrop(
          progress: background,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, top + 8, 20, 8),
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  HeroRoundButton(
                    icon: LucideIcons.arrowLeft,
                    size: 40,
                    onTap: onBack,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: reveal,
                        child: Transform.translate(
                          offset: Offset(0, 10 * (1 - reveal)),
                          child: Row(
                            children: [
                              cover,
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppFonts.jostStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (meta.isNotEmpty)
                                      Text(
                                        meta,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppFonts.jostStyle(
                                          fontSize: 13,
                                          color: Colors.white.withValues(
                                            alpha: 0.65,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (trailing != null)
                    // Grows from zero width so the title keeps the room until
                    // Follow actually arrives.
                    ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: follow,
                        child: IgnorePointer(
                          ignoring: follow < 1,
                          child: Opacity(
                            opacity: follow,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: trailing,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (action != null) ...[const SizedBox(width: 8), action!],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The fill behind a scrolled page header, faded in by [progress]: frosted
/// glass whenever sheets blur (Dynamic Theming's blur toggle, or "Always
/// blur" when Dynamic Theming is off), otherwise a black fade.
class HeaderBackdrop extends ConsumerWidget {
  const HeaderBackdrop({
    super.key,
    required this.progress,
    required this.child,
  });

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (progress <= 0) return child;
    final blur = ref.watch(settingsProvider.select((s) => s.statusBarBlur));
    final p = progress;
    // Faded through color and blur strength, not an Opacity: a
    // BackdropFilter under an Opacity costs an extra offscreen pass.
    final Widget fill = blur
        ? ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24 * p, sigmaY: 24 * p),
              child: ColoredBox(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.55 * p),
              ),
            ),
          )
        : DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.95 * p),
                  Colors.black.withValues(alpha: 0.8 * p),
                  Colors.black.withValues(alpha: 0),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // The black fade runs a little past the bar so it has no hard edge.
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          bottom: blur ? 0 : -28,
          child: fill,
        ),
        child,
      ],
    );
  }
}

const _buttonFill = Color(0x17FFFFFF);

class HeroRoundButton extends StatelessWidget {
  const HeroRoundButton({
    super.key,
    required this.icon,
    required this.size,
    required this.onTap,
    this.fill = _buttonFill,
    this.semanticLabel,
  });
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  final Color fill;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Material(
    color: fill,
    shape: const CircleBorder(),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: SizedBox.square(
        dimension: size,
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.45,
          semanticLabel: semanticLabel,
        ),
      ),
    ),
  );
}

class HeroPillButton extends StatelessWidget {
  const HeroPillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.height = 48,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) => Material(
    color: _buttonFill,
    shape: const StadiumBorder(),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: height / 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: height * 0.5),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.jostStyle(
                  fontSize: height * 0.36,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
