import 'package:flutter/material.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/theme/app_fonts.dart';

/// Rounded filter chip used above library lists (All / On Device / ...).
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(40),
      onTap: () {
        AppHaptics.selection();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.92)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Text(
          label,
          style: AppFonts.jostStyle(
            color: isSelected
                ? Colors.black
                : Colors.white.withValues(alpha: 0.4),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
