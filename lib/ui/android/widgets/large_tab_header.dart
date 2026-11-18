import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/theme/app_fonts.dart';

/// Two-line tab title ("All / Songs", "Your / Library") with round search
/// and account buttons on the right.
class LargeTabHeader extends ConsumerWidget {
  final String eyebrow;
  final String title;

  const LargeTabHeader({super.key, required this.eyebrow, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void go(NavItem item) {
      AppHaptics.light();
      ref.read(appNavigationProvider.notifier).setItem(item);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: AppFonts.jostStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.jostStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
          RoundIconButton(
            icon: Icons.search_rounded,
            tooltip: MaterialLocalizations.of(context).searchFieldLabel,
            onTap: () => go(NavItem.search),
          ),
          const SizedBox(width: 6),
          RoundIconButton(
            icon: Icons.person_rounded,
            onTap: () => go(NavItem.account),
          ),
        ],
      ),
    );
  }
}

/// The filled 42px circle button from the tab headers.
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.white.withValues(alpha: 0.11),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox.square(
          dimension: 42,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}

/// The app bar's fade over a list below a [LargeTabHeader]: it shows only
/// once the list has scrolled, so rows at rest are never dimmed, and then
/// softens the edge the rows scroll under.
class TabHeaderFade extends StatefulWidget {
  final Widget child;

  const TabHeaderFade({super.key, required this.child});

  @override
  State<TabHeaderFade> createState() => _TabHeaderFadeState();
}

class _TabHeaderFadeState extends State<TabHeaderFade> {
  final _scrolled = ValueNotifier(false);

  @override
  void dispose() {
    _scrolled.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth == 0 && n.metrics.axis == Axis.vertical) {
      _scrolled.value = n.metrics.pixels > n.metrics.minScrollExtent;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: widget.child,
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 40,
          child: IgnorePointer(
            child: ValueListenableBuilder<bool>(
              valueListenable: _scrolled,
              builder: (context, scrolled, child) => AnimatedOpacity(
                opacity: scrolled ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: child,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    // Solid at the top so the rows' clipped edge hides in
                    // black, then an eased fade: a plain linear ramp left a
                    // visible line where it met the header.
                    colors: [
                      surface,
                      surface,
                      surface.withValues(alpha: 0.7),
                      surface.withValues(alpha: 0.3),
                      surface.withValues(alpha: 0.08),
                      surface.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.3, 0.5, 0.7, 0.88, 1],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
