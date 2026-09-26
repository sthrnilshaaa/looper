import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DspCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  final List<Widget> children;
  final bool initialExpanded;

  const DspCard({
    required this.title,
    required this.icon,
    this.trailing,
    required this.children,
    this.initialExpanded = false,
    super.key,
  });

  @override
  State<DspCard> createState() => _DspCardState();
}

class _DspCardState extends State<DspCard> {
  late bool _expanded = widget.initialExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _expanded = !_expanded;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Icon(widget.icon, color: Colors.white70, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    widget.title,
                    style: AppFonts.jostStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  if (widget.trailing != null) widget.trailing!,
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _expanded ? 0.5 : 0,
                    child: const Icon(
                      LucideIcons.chevronDown,
                      color: Colors.white30,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: widget.children,
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
