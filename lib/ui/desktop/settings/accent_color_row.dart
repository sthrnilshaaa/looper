part of 'settings_view.dart';

class _PremiumAccentColorRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int selectedColor;
  final ValueChanged<int> onColorChanged;
  final bool isLast;

  const _PremiumAccentColorRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selectedColor,
    required this.onColorChanged,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PremiumColorCircle(
                    color: const Color(0xFF41C25E),
                    isSelected: selectedColor == 0xFF41C25E,
                    onTap: () => onColorChanged(0xFF41C25E),
                  ),
                  const SizedBox(width: 8),
                  _PremiumColorCircle(
                    color: const Color(0xFFF7EAA6),
                    isSelected: selectedColor == 0xFFF7EAA6,
                    onTap: () => onColorChanged(0xFFF7EAA6),
                  ),
                  const SizedBox(width: 8),
                  _PremiumColorCircle(
                    color: Colors.blueAccent,
                    isSelected: selectedColor == Colors.blueAccent.value,
                    onTap: () => onColorChanged(Colors.blueAccent.value),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 0.8,
            color: Colors.white.withValues(alpha: 0.04),
            indent: 20,
            endIndent: 20,
          ),
      ],
    );
  }
}

class _PremiumColorCircle extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PremiumColorCircle({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.white, width: 2)
              : Border.all(color: Colors.white24, width: 1),
        ),
      ),
    );
  }
}
