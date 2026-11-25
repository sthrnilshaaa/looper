part of 'android_equalizer_screen.dart';

extension _EqualizerPresetChips on AndroidEqualizerScreen {
  bool _isMatchingPreset(List<double> current, List<double> preset) {
    for (int i = 0; i < 18; i++) {
      final curGain = i < current.length ? current[i] : 0.0;
      final preGain = i < preset.length ? preset[i] : 0.0;
      if ((curGain - preGain).abs() > 0.5) return false;
    }
    return true;
  }

  // Shared visual for every preset pill (built-in, custom, and the "save"
  // action) so the three don't drift out of sync with each other.
  Widget _buildPresetChip({
    required String label,
    required bool isCurrent,
    required Color accentColor,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    IconData? icon,
  }) {
    final fg = isCurrent ? Colors.black : Colors.white;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Material(
        color: isCurrent ? Colors.white : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: fg),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: AppFonts.jostStyle(
                    fontSize: 14,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavePresetChip(
    BuildContext context,
    WidgetRef ref,
    EqualizerState eqState,
    Color accentColor,
  ) {
    return _buildPresetChip(
      label: context.l10n.save,
      icon: LucideIcons.plus,
      isCurrent: false,
      accentColor: accentColor,
      onTap: () => _promptSaveCustomPreset(context, ref, eqState),
    );
  }

  Future<void> _promptSaveCustomPreset(
    BuildContext context,
    WidgetRef ref,
    EqualizerState eqState,
  ) async {
    final controller = TextEditingController();
    final name = await showTaskDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.savePreset),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: context.l10n.presetName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    // Saves the whole current gains array (all bands plus every effect
    // toggle), not just the 18 visible sliders, so recalling it later
    // restores exactly what was heard when it was saved.
    await ref
        .read(customEqPresetsProvider.notifier)
        .save(name, eqState.currentSongGains);
  }

  Future<void> _confirmDeleteCustomPreset(
    BuildContext context,
    WidgetRef ref,
    String name,
  ) async {
    final confirmed = await showTaskDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deletePreset),
        content: Text(context.l10n.deletePresetConfirm(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              context.l10n.delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(customEqPresetsProvider.notifier).delete(name);
    }
  }
}
