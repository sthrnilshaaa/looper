import 'package:flutter/material.dart';
import 'package:looper_player/ui/widgets/common/app_skeleton.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Shown on the Home tab while the saved library loads from the database
/// after a cold start. Mirrors the real tab's layout (header, Quick Picks
/// grid, then horizontal card rows) so the content drops into place instead
/// of replacing a spinner.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AppSkeleton(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            // Avatar + search/settings buttons.
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Bone.circle(size: 38),
                  Spacer(),
                  Bone(width: 48, height: 48, uniRadius: 24),
                  SizedBox(width: 5),
                  Bone(width: 48, height: 48, uniRadius: 24),
                ],
              ),
            ),
            // Quick Picks title + shuffle pill.
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Bone.text(fontSize: 24, width: 140),
                      SizedBox(height: 6),
                      Bone.text(fontSize: 14, width: 110),
                    ],
                  ),
                  Spacer(),
                  Bone.circle(size: 40),
                ],
              ),
            ),
            // 3 x 2 Quick Picks grid.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(6, (_) => const Bone(uniRadius: 8)),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Bone(width: 16, height: 6, uniRadius: 3),
                SizedBox(width: 6),
                Bone(width: 6, height: 6, uniRadius: 3),
                SizedBox(width: 6),
                Bone(width: 6, height: 6, uniRadius: 3),
              ],
            ),
            const _CardRow(circle: true),
            const _CardRow(circle: false),
          ],
        ),
      ),
    );
  }
}

/// A section header with a horizontal row of artist (circle) or album
/// (rounded square) cards, sized like home_sections.dart.
class _CardRow extends StatelessWidget {
  const _CardRow({required this.circle});

  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            children: [
              Bone.text(fontSize: 22, width: 120),
              Spacer(),
              Bone(width: 72, height: 36, uniRadius: 18),
            ],
          ),
        ),
        SizedBox(
          height: 170,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (var i = 0; i < 5; i++)
                Container(
                  width: circle ? 110 : 120,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      circle
                          ? const Bone.circle(size: 92)
                          : const Bone.square(size: 108, uniRadius: 16),
                      const SizedBox(height: 8),
                      Bone.text(fontSize: 13, width: circle ? 70 : 90),
                      if (!circle) ...[
                        const SizedBox(height: 4),
                        const Bone.text(fontSize: 11, width: 56),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shown on the Songs tab while the saved library loads after a cold start:
/// the tab's header and rows of song tiles (artwork, title, artist).
class SongsSkeleton extends StatelessWidget {
  const SongsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AppSkeleton(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Bone(width: 48, height: 48, uniRadius: 24),
                  Spacer(),
                  Bone.text(fontSize: 24, width: 120),
                  Spacer(),
                  Bone(width: 48, height: 48, uniRadius: 24),
                ],
              ),
            ),
            for (var i = 0; i < 14; i++) SongRowSkeleton(index: i),
          ],
        ),
      ),
    );
  }
}

/// One song row's bones (artwork, title, artist). Wrap in [AppSkeleton].
/// [index] varies the line widths so a column of them doesn't look stamped.
class SongRowSkeleton extends StatelessWidget {
  const SongRowSkeleton({super.key, this.index = 0});

  final int index;

  static const List<(double, double)> _widths = [
    (190, 120),
    (150, 95),
    (220, 140),
    (170, 80),
    (205, 125),
    (135, 105),
    (180, 90),
    (160, 130),
  ];

  @override
  Widget build(BuildContext context) {
    final (title, subtitle) = _widths[index % _widths.length];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Bone.square(size: 52, uniRadius: 4),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Bone.text(fontSize: 15, width: title),
              const SizedBox(height: 6),
              Bone.text(fontSize: 12, width: subtitle),
            ],
          ),
        ],
      ),
    );
  }
}

/// One Home card row (artists, albums, genres) whose data is still
/// loading: its header and a row of card bones, in its own [AppSkeleton].
class HomeCardRowSkeleton extends StatelessWidget {
  const HomeCardRowSkeleton({super.key, required this.circle});

  final bool circle;

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(child: _CardRow(circle: circle));
  }
}

/// Cross-fades a tab between its load states (skeleton, scanning, empty,
/// content). Return one from every branch of a tab's build with a fixed
/// [state] per branch: the switcher stays mounted across builds, so a state
/// change fades while updates within one state rebuild in place.
class LoadStateSwitcher extends StatelessWidget {
  const LoadStateSwitcher({
    super.key,
    required this.state,
    required this.child,
  });

  final String state;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) =>
          Stack(fit: StackFit.expand, children: [...previous, ?current]),
      child: KeyedSubtree(key: ValueKey(state), child: child),
    );
  }
}
