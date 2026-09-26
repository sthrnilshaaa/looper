import 'package:flutter/material.dart';

class EqualizerSliderTrack extends StatelessWidget {
  final double gain;
  final ValueChanged<double> onChanged;
  final VoidCallback? onDragEnd;
  final bool enabled;

  const EqualizerSliderTrack({
    required this.gain,
    required this.onChanged,
    this.onDragEnd,
    required this.enabled,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final percent = ((gain + 20) / 40).clamp(0.0, 1.0);
    final accentColor = Theme.of(context).colorScheme.primary;

    return Opacity(
      opacity: enabled ? 1.0 : 0.35,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackHeight = constraints.maxHeight - 16;
          final centerProgressY = trackHeight * 0.5;
          final thumbY = (1.0 - percent) * trackHeight;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: enabled
                ? (details) {
                    final RenderBox renderBox =
                        context.findRenderObject() as RenderBox;
                    final localPos = renderBox.globalToLocal(
                      details.globalPosition,
                    );
                    final dragY = (localPos.dy - 8).clamp(0.0, trackHeight);
                    final newPercent = (1.0 - (dragY / trackHeight)).clamp(
                      0.0,
                      1.0,
                    );
                    onChanged((newPercent * 40.0) - 20.0);
                  }
                : null,
            onVerticalDragEnd: enabled ? (_) => onDragEnd?.call() : null,
            onVerticalDragCancel: enabled ? () => onDragEnd?.call() : null,
            onTapDown: enabled
                ? (details) {
                    final RenderBox renderBox =
                        context.findRenderObject() as RenderBox;
                    final localPos = renderBox.globalToLocal(
                      details.globalPosition,
                    );
                    final dragY = (localPos.dy - 8).clamp(0.0, trackHeight);
                    final newPercent = (1.0 - (dragY / trackHeight)).clamp(
                      0.0,
                      1.0,
                    );
                    onChanged((newPercent * 40.0) - 20.0);
                  }
                : null,
            onTapUp: enabled ? (_) => onDragEnd?.call() : null,
            child: SizedBox(
              width: 32,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Full background pill
                  Container(
                    width: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  // Center zero line
                  Positioned(
                    top: centerProgressY + 8,
                    child: Container(
                      width: 14,
                      height: 1.5,
                      color: Colors.white30,
                    ),
                  ),
                  // Active fill from center
                  Positioned(
                    top: percent >= 0.5 ? thumbY + 8 : centerProgressY + 8,
                    bottom: percent >= 0.5
                        ? trackHeight - centerProgressY + 8
                        : trackHeight - thumbY + 8,
                    child: Container(
                      width: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accentColor,
                            accentColor.withValues(alpha: 0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  // Thumb Handle
                  Positioned(
                    top: thumbY,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (enabled)
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                        ],
                        border: Border.all(color: accentColor, width: 3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
