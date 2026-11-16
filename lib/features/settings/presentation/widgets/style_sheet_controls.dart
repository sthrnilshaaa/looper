import 'package:flutter/material.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';

/// Small controls shared by the "style" sheets (progress bar, artwork
/// visualizer): a section label, a labelled slider with its value, a switch
/// row and a segmented choice, all in the settings screens' look.

class StyleSectionLabel extends StatelessWidget {
  final String text;
  final Color accent;

  const StyleSectionLabel(this.text, {super.key, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 6),
      child: Text(
        text.toUpperCase(),
        style: AppFonts.settingsStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: accent.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

class StyleSliderRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final Color accent;
  final bool enabled;
  final ValueChanged<double> onChanged;

  /// Called once the drag ends - where the value gets saved, so dragging
  /// doesn't write the database on every frame.
  final ValueChanged<double> onChangeEnd;

  const StyleSliderRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.accent,
    this.enabled = true,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.4,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppFonts.settingsStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: AppFonts.settingsStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  valueLabel,
                  style: AppFonts.settingsStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                activeTrackColor: accent,
                inactiveTrackColor: Colors.white10,
                thumbColor: accent,
                overlayColor: accent.withValues(alpha: 0.12),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: enabled ? onChanged : null,
                onChangeEnd: enabled ? onChangeEnd : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StyleSwitchRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final Color accent;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const StyleSwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.accent,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.4,
      // Its own Material: the sheet's tinted box would otherwise hide the
      // tile's ink (and trips ListTile's debug check).
      child: Material(
        type: MaterialType.transparency,
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          title: Text(
            title,
            style: AppFonts.settingsStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle!,
                  style: AppFonts.settingsStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
          activeThumbColor: accent,
          value: value,
          onChanged: enabled
              ? (v) {
                  AppHaptics.light();
                  onChanged(v);
                }
              : null,
        ),
      ),
    );
  }
}

/// A row of pill buttons, one selected - like the lyrics alignment picker.
class StyleSegmentedChoice<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final Color accent;
  final ValueChanged<T> onSelected;

  const StyleSegmentedChoice({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.accent,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10, width: 0.5),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          for (final v in values)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (v == selected) return;
                  AppHaptics.light();
                  onSelected(v);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: v == selected ? accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label(v),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.settingsStyle(
                      color: v == selected ? Colors.black : Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
