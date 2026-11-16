import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/ui/android/widgets/premium_section.dart';

/// Mochy text colours (docs/morchy-music/01 → Colour).
/// Design adapted from Mochy Music, GPL-3.0, github.com/realidkroo/Mochy-Music.
abstract final class MochyColors {
  static const secondary = Color(0xFF9A9AA0);
}

/// A Mochy settings-style bubble: icon circle, title (+ optional line under
/// it), optional trailing. Tapping squishes it (PremiumSection), no ripple.
/// The card takes the theme surface (follows Pure Black) and the icon the
/// accent colour, like the cards it replaced.
class MochyCardRow extends ConsumerWidget {
  const MochyCardRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.margin = EdgeInsets.zero,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;

  static const radius = BorderRadius.all(Radius.circular(20));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(settingsProvider.select((s) => s.accent));
    return Padding(
      padding: margin,
      child: PremiumSection(
        borderRadius: radius,
        forceNoBlur: true,
        useExpanded: false,
        useCenter: false,
        padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 19, color: accent),
            ),
            const SizedBox(width: 14),
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
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.48, // −0.03 em
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.jostStyle(
                        color: MochyColors.secondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.25, // −0.02 em
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          ],
        ),
      ),
    );
  }
}
