import 'package:flutter/material.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/ui/android/widgets/premium_section.dart';

/// A small glass stat card: an icon chip, a value that counts up from 0 on
/// first build, and a label underneath. Used for the "report card" grid at
/// the top of Looper Analyze (total plays, listening time, streaks, ...).
class StatTile extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color accent;
  final String Function(int value)? formatter;

  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
    this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumSection(
      borderRadius: BorderRadius.circular(20),
      useExpanded: false,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      useCenter: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, _) => Text(
              formatter?.call(animatedValue) ?? '$animatedValue',
              style: AppFonts.jostStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppFonts.jostStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
