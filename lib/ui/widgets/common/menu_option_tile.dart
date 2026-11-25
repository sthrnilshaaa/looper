import 'package:flutter/material.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MenuOptionTile extends StatelessWidget {
  final String label;
  final IconData? icon;
  // Drawn instead of [icon], for marks that are not font glyphs.
  final Widget? iconWidget;
  final Color iconColor;
  final VoidCallback onTap;

  const MenuOptionTile({
    super.key,
    required this.label,
    this.icon,
    this.iconWidget,
    required this.iconColor,
    required this.onTap,
  }) : assert(icon != null || iconWidget != null);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            iconWidget ?? Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: AppFonts.jostStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: Colors.white.withValues(alpha: 0.9),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
