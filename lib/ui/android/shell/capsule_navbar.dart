import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/theme/app_icons.dart';
import 'package:looper_player/core/utils/responsive.dart';
import 'package:looper_player/l10n/app_localizations.dart';

/// 03 · Floating Capsule navbar: dark `#0A0A0A` pill with `#1F1F1F` active
/// tab pill that expands its flex (2.2 vs 1) to reveal the label.
class CapsuleNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CapsuleNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static double heightFor({required bool compact}) => compact ? 76.0 : 92.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final bool compact = Responsive.isShort(MediaQuery.sizeOf(context));
    final items = [
      (AppIcons.home, l10n.home),
      (AppIcons.search, l10n.search),
      (AppIcons.songs, l10n.songs),
      (AppIcons.library, l10n.library),
    ];

    final double capsuleH = compact ? 52.0 : 60.0;
    final double tabH = compact ? 40.0 : 48.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        28,
        compact ? 8 : 14,
        28,
        (compact ? 10 : 18) + bottomPadding,
      ),
      child: Container(
        height: capsuleH,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.07),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.80),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              _CapsuleTab(
                iconPath: items[i].$1,
                label: items[i].$2,
                selected: currentIndex == i,
                height: tabH,
                onTap: () {
                  AppHaptics.tick();
                  onTap(i);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CapsuleTab extends StatelessWidget {
  final String iconPath;
  final String label;
  final bool selected;
  final double height;
  final VoidCallback onTap;

  const _CapsuleTab({
    required this.iconPath,
    required this.label,
    required this.selected,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg = selected ? Colors.white : const Color(0xFF6B6B6B);
    return Expanded(
      flex: selected ? 22 : 10,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            height: height,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF1F1F1F) : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  iconPath,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.jostStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
