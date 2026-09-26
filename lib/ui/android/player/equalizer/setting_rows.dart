part of 'android_equalizer_screen.dart';

extension _EqualizerSettingRows on AndroidEqualizerScreen {
  Widget _buildSwitchRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color accentColor,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: AppFonts.jostStyle(
            fontSize: 13,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Switch.adaptive(
          value: value,
          activeThumbColor: accentColor,
          activeTrackColor: accentColor.withValues(alpha: 0.35),
          onChanged: (val) {
            HapticFeedback.mediumImpact();
            onChanged(val);
          },
        ),
      ],
    );
  }

  Widget _buildSliderRow({
    required String title,
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                title,
                style: AppFonts.jostStyle(fontSize: 12, color: Colors.white54),
              ),
              const Spacer(),
              Text(
                '${value.toStringAsFixed(1)} $unit',
                style: AppFonts.jostStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Colors.white24,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.05),
              thumbColor: Colors.white,
              trackHeight: 2.0,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
