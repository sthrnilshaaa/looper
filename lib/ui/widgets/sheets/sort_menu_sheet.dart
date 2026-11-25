import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/motion/looper_scroll_physics.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/ui/android/widgets/premium_section.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// One row of a [SortMenuSheet].
class SortMenuItem {
  const SortMenuItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
}

/// Sort / filter menu drawn like the song options sheet: drag handle,
/// header, divider, then a rounded group of icon rows; the picked row gets
/// an accent check. Tapping a row closes the sheet.
class SortMenuSheet extends ConsumerWidget {
  const SortMenuSheet({
    super.key,
    required this.title,
    required this.items,
    this.trailing,
  });

  final String title;
  final List<SortMenuItem> items;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final useBlur = settings.sheetShouldBlur;
    final isPureBlack = settings.darkTheme;
    final accent = settings.accent;
    // Blur wins over Pure Black, as in AppBottomSheetContainer.
    final sheetBg = useBlur
        ? Colors.black.withValues(alpha: 0.6)
        : (isPureBlack ? Colors.black : const Color(0xFF1E1E1E));

    final rows = [
      for (final item in items)
        _SortMenuRow(
          item: item,
          accent: accent,
          onTap: () {
            AppHaptics.light();
            item.onTap();
            Navigator.pop(context);
          },
        ),
    ];

    final Widget sheet = Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppFonts.jostStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            Flexible(
              child: SingleChildScrollView(
                physics: const LooperScrollPhysics(),
                padding: const EdgeInsets.all(8),
                child: PremiumSection(
                  borderRadius: BorderRadius.circular(20),
                  padding: EdgeInsets.zero,
                  useExpanded: false,
                  backgroundColor: sheetBg,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < rows.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            thickness: 0.8,
                            color: Colors.white.withValues(alpha: 0.04),
                            indent: 20,
                            endIndent: 20,
                          ),
                        rows[i],
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (useBlur) {
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: sheet,
          ),
        ),
      );
    }
    return sheet;
  }
}

class _SortMenuRow extends StatelessWidget {
  const _SortMenuRow({
    required this.item,
    required this.accent,
    required this.onTap,
  });

  final SortMenuItem item;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 22,
              color: item.selected
                  ? accent
                  : Colors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.label,
                style: AppFonts.jostStyle(
                  color: Colors.white,
                  fontWeight: item.selected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
            if (item.selected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.check,
                  color: Colors.white,
                  size: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
