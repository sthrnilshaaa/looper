import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/theme/app_icons.dart';
import 'package:looper_player/core/utils/responsive.dart';
import 'package:looper_player/l10n/app_localizations.dart';

/// 04 · Minimal Line navbar: 1dp hairline across top, icons only with an
/// animated 16×3 white indicator bar under the active tab.
class MinimalNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MinimalNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static double heightFor({required bool compact}) => compact ? 60.0 : 82.0;

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

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        compact ? 6 : 14,
        24,
        (compact ? 6 : 20) + bottomPadding,
      ),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: currentIndex == i,
                  label: items[i].$2,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      AppHaptics.tick();
                      onTap(i);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          items[i].$1,
                          width: 23,
                          height: 23,
                          colorFilter: ColorFilter.mode(
                            currentIndex == i
                                ? Colors.white
                                : const Color(0xFF5C5C5C),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          width: currentIndex == i ? 16 : 0,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
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
