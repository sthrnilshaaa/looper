import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/theme/app_icons.dart';
import 'package:looper_player/core/utils/responsive.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:looper_player/l10n/app_localizations.dart';

/// Looper Music's root tab bar: four icon-over-label tabs (Home, Search,
/// Songs, Library) with no surface of their own - they sit on the black fade
/// the main screen draws behind them. Settings > New Navbar.
class NewNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const NewNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  /// Height above the system inset. The main screen lays the mini player and
  /// snackbars out against this, so it is the one place the size lives.
  static double heightFor({required bool compact}) => compact ? 52.0 : 76.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    // Landscape phones are short: tighter padding and smaller icon/label.
    final bool compact = Responsive.isShort(MediaQuery.sizeOf(context));
    final items = [
      (AppIcons.home, l10n.home),
      (AppIcons.search, l10n.search),
      (AppIcons.songs, l10n.songs),
      (AppIcons.library, l10n.library),
    ];

    return Padding(
      // top + row + bottom == heightFor(compact).
      padding: EdgeInsets.fromLTRB(
        20,
        compact ? 6 : 22,
        20,
        (compact ? 4 : 10) + bottomPadding,
      ),
      child: SizedBox(
        height: compact ? 42 : 44,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _NavItem(
                  iconPath: items[i].$1,
                  label: items[i].$2,
                  isSelected: currentIndex == i,
                  compact: compact,
                  onTap: () {
                    AppHaptics.tick();
                    onTap(i);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String iconPath;
  final String label;
  final bool isSelected;
  final bool compact;
  final VoidCallback onTap;

  const _NavItem({
    required this.iconPath,
    required this.label,
    required this.isSelected,
    required this.compact,
    required this.onTap,
  });

  static const _inactive = Color(0xFF666666);
  static const _duration = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Colors.white : _inactive;
    final iconSize = (compact ? 17.0 : 20.0).s;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: color),
              duration: _duration,
              curve: Curves.easeOutCubic,
              builder: (context, c, _) => SvgPicture.asset(
                iconPath,
                width: iconSize,
                height: iconSize,
                colorFilter: ColorFilter.mode(c ?? color, BlendMode.srcIn),
              ),
            ),
            SizedBox(height: compact ? 3 : 6),
            AnimatedDefaultTextStyle(
              duration: _duration,
              curve: Curves.easeOutCubic,
              style: AppFonts.jostStyle(
                textStyle: const TextStyle(inherit: false),
                color: color,
                fontSize: (compact ? 12.0 : 14.0).ts,
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
