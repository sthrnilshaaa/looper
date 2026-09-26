part of 'theme_settings_tiles.dart';

class SelectAvatarsTile extends ConsumerWidget {
  const SelectAvatarsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(LucideIcons.userCircle, color: Colors.white70),
      title: Text(l10n.selectAvatars, style: _tileTitleStyle()),
      subtitle: Text(l10n.selectAvatarsDesc, style: _tileSubtitleStyle()),
      trailing: const Icon(
        LucideIcons.chevronRight,
        color: Colors.white30,
        size: 18,
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        showAvatarPickerSheet(context);
      },
    );
  }
}

class DynamicThemingTile extends ConsumerWidget {
  const DynamicThemingTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.palette, color: Colors.white70),
      title: Text(l10n.dynamicTheming, style: _tileTitleStyle()),
      subtitle: Text(l10n.adaptColorsArtwork, style: _tileSubtitleStyle()),
      activeThumbColor: Color(settings.accentColor),
      value: settings.enableDynamicTheming,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateDynamicTheming(value);
      },
    );
  }
}

class DisableBlurTile extends ConsumerWidget {
  const DisableBlurTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.eyeOff, color: Colors.white70),
      title: Text(l10n.disableBlurEffects, style: _tileTitleStyle()),
      subtitle: Text(l10n.turnOffBlursOptimize, style: _tileSubtitleStyle()),
      activeThumbColor: Color(settings.accentColor),
      value: settings.disableBlur,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateDisableBlur(value);
      },
    );
  }
}

/// Lets sheets built on AppBottomSheetContainer (the lyrics popup menu,
/// lyrics share sheet, queue sheet, etc.) show their background blur even
/// with Dynamic Theming off -- that toggle also changes accent colors and
/// gradients app-wide, so this gives just the sheet blur without the rest.
/// Only shown while Dynamic Theming is off; once it's on, blur already
/// applies everywhere DisableBlurTile controls it directly.
class AlwaysBlurSheetsTile extends ConsumerWidget {
  const AlwaysBlurSheetsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.droplets, color: Colors.white70),
      title: Text(l10n.alwaysBlurSheets, style: _tileTitleStyle()),
      subtitle: Text(l10n.alwaysBlurSheetsDesc, style: _tileSubtitleStyle()),
      activeThumbColor: Color(settings.accentColor),
      value: settings.alwaysBlurSheets,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateAlwaysBlurSheets(value);
      },
    );
  }
}

class DynamicAccentColorTile extends ConsumerWidget {
  const DynamicAccentColorTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    return SwitchListTile(
      secondary: const Icon(LucideIcons.paintBucket, color: Colors.white70),
      title: Text(l10n.dynamicAccentColor, style: _tileTitleStyle()),
      subtitle: Text(l10n.dynamicAccentColorDesc, style: _tileSubtitleStyle()),
      activeThumbColor: Color(settings.accentColor),
      value: settings.dynamicAccentColor,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateDynamicAccentColor(value);
      },
    );
  }
}

class PureBlackOledTile extends ConsumerWidget {
  const PureBlackOledTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.moon, color: Colors.white70),
      title: Text(l10n.pureBlackOled, style: _tileTitleStyle()),
      subtitle: Text(l10n.useAbsoluteBlackBg, style: _tileSubtitleStyle()),
      activeThumbColor: Color(settings.accentColor),
      value: settings.darkTheme,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateDarkTheme(value);
      },
    );
  }
}

class AccentColorTile extends ConsumerWidget {
  const AccentColorTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(LucideIcons.droplet, color: Colors.white70),
      title: Text(l10n.accentColor, style: _tileTitleStyle()),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ColorCircle(
            color: const Color(0xFF41C25E),
            isSelected: settings.accentColor == 0xFF41C25E,
            onTap: () => ref
                .read(settingsProvider.notifier)
                .updateAccentColor(0xFF41C25E),
          ),
          const SizedBox(width: 8),
          ColorCircle(
            color: const Color(0xFFF7EAA6),
            isSelected: settings.accentColor == 0xFFF7EAA6,
            onTap: () => ref
                .read(settingsProvider.notifier)
                .updateAccentColor(0xFFF7EAA6),
          ),
          const SizedBox(width: 8),
          ColorCircle(
            color: Colors.blueAccent,
            isSelected: settings.accentColor == Colors.blueAccent.value,
            onTap: () => ref
                .read(settingsProvider.notifier)
                .updateAccentColor(Colors.blueAccent.value),
          ),
        ],
      ),
    );
  }
}

class CustomAccentColorTile extends ConsumerWidget {
  const CustomAccentColorTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(LucideIcons.palette, color: Colors.white70),
      title: Text(l10n.customAccentColor, style: _tileTitleStyle()),
      subtitle: Text(l10n.selectCustomColor, style: _tileSubtitleStyle()),
      trailing: ColorCircle(
        color: Color(settings.accentColor),
        isSelected:
            settings.accentColor != 0xFF41C25E &&
            settings.accentColor != 0xFFF7EAA6 &&
            settings.accentColor != Colors.blueAccent.value,
        onTap: () =>
            showCustomColorPicker(context, ref, Color(settings.accentColor)),
      ),
      onTap: () =>
          showCustomColorPicker(context, ref, Color(settings.accentColor)),
    );
  }
}
