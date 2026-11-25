part of 'android_equalizer_screen.dart';

/// Card colour of the redesigned screens (Settings, Account, EQ).
const Color _kEqCard = Color(0xFF101010);

/// A rounded dark group, the redesign's card.
class _EqCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _EqCard({required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _kEqCard,
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }
}

/// The grey label above a card.
class _EqLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const _EqLabel(this.text, {this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 2, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: AppFonts.jostStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A small rounded value tag, as on the Settings slider rows.
class _EqPill extends StatelessWidget {
  final String text;

  const _EqPill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        text,
        style: AppFonts.jostStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// A row with a title, a value pill and a slider under it.
class _EqSliderRow extends StatelessWidget {
  final String title;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final bool dense;

  const _EqSliderRow({
    required this.title,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.onChangeEnd,
    this.divisions,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? 4 : 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppFonts.jostStyle(
                    fontSize: dense ? 14 : 16,
                    fontWeight: dense ? FontWeight.w400 : FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              _EqPill(valueText),
            ],
          ),
          SizedBox(
            height: 36,
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ],
      ),
    );
  }
}

/// Segmented control: the selected segment is white with black text.
class _EqSegmented<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final double height;

  const _EqSegmented({
    required this.options,
    required this.selected,
    required this.onSelected,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (final (value, label) in options)
            Expanded(
              child: Semantics(
                button: true,
                selected: value == selected,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (value == selected) return;
                    AppHaptics.selection();
                    onSelected(value);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: height,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: value == selected
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      label,
                      style: AppFonts.jostStyle(
                        fontSize: 14,
                        fontWeight: value == selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: value == selected
                            ? Colors.black
                            : Colors.white.withValues(alpha: 0.7),
                      ),
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

/// One effect in the Effects card: a short tag, its name and current
/// setting, and a switch. Its settings open under it while it is on.
class _EffectRow extends StatelessWidget {
  final String tag;
  final String title;
  final String summary;
  final bool value;
  final ValueChanged<bool> onChanged;
  final List<Widget> children;
  final bool showDivider;

  const _EffectRow({
    required this.tag,
    required this.title,
    required this.summary,
    required this.value,
    required this.onChanged,
    this.children = const [],
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showDivider)
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.white.withValues(alpha: 0.06),
          ),
        InkWell(
          onTap: () {
            AppHaptics.medium();
            onChanged(!value);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    tag,
                    style: AppFonts.jostStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: value ? Colors.black : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppFonts.jostStyle(
                          fontSize: 15,
                          fontWeight: value ? FontWeight.w600 : FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        summary,
                        style: AppFonts.jostStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.56),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: (v) {
                    AppHaptics.medium();
                    onChanged(v);
                  },
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: value && children.isNotEmpty
              ? Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// A plain row inside a card: icon, title and subtitle, chevron.
class _EqLinkRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _EqLinkRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        AppHaptics.light();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.jostStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppFonts.jostStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.56),
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
          ],
        ),
      ),
    );
  }
}

String _signedDb(double v) {
  final r = v.round();
  return '${r > 0 ? '+' : ''}$r dB';
}
