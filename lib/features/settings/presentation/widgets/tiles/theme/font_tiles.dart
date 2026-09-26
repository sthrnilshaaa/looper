part of 'theme_settings_tiles.dart';

class UseNewFontTile extends ConsumerWidget {
  const UseNewFontTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.type, color: Colors.white70),
      title: Text(l10n.useCustomFont, style: _tileTitleStyle()),
      subtitle: Text(l10n.useCustomFontDesc, style: _tileSubtitleStyle()),
      activeThumbColor: Color(settings.accentColor),
      value: settings.useNewFont,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateUseNewFont(value);
      },
    );
  }
}

class FontFamilySelectionTile extends ConsumerWidget {
  const FontFamilySelectionTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    final availableFonts = [
      'Jost',
      'DM Sans',
      'Poppins',
      'Space Grotesk',
      'Plus Jakarta Sans',
      'Sora',
      'Google Sans',
    ];

    return ListTile(
      leading: const Icon(LucideIcons.type, color: Colors.white70),
      title: Text(l10n.selectFontFamily, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.activeFont(settings.customFontFamily ?? 'Jost'),
        style: _tileSubtitleStyle(),
      ),
      trailing: DropdownButton<String>(
        value: availableFonts.contains(settings.customFontFamily)
            ? settings.customFontFamily
            : 'Jost',
        dropdownColor: const Color(0xFF1A1A1A),
        underline: const SizedBox(),
        items: availableFonts.map((font) {
          return DropdownMenuItem<String>(
            value: font,
            child: Text(font, style: AppFonts.jostStyle(color: Colors.white)),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            ref.read(settingsProvider.notifier).updateCustomFontFamily(value);
          }
        },
      ),
    );
  }
}

class FontWeightSelectionTile extends ConsumerWidget {
  const FontWeightSelectionTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    final delta = settings.customFontWeightDelta;
    final selectedWeight = 400 + (delta * 100);

    final weights = [100, 200, 300, 400, 500, 600, 700, 800, 900];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(LucideIcons.bold, color: Colors.white70),
          title: Text(l10n.fontWeightAdjustment, style: _tileTitleStyle()),
          subtitle: Text(
            '${l10n.currentWeight}: $selectedWeight',
            style: _tileSubtitleStyle(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: weights.length,
              itemBuilder: (context, index) {
                final w = weights[index];
                final isSelected = w == selectedWeight;
                final accentColor = Color(settings.accentColor);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    final newDelta = (w - 400) ~/ 100;
                    ref
                        .read(settingsProvider.notifier)
                        .updateCustomFontWeightDelta(newDelta);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8.0),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : Colors.white.withValues(alpha: 0.08),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '$w',
                      style: AppFonts.jostStyle(
                        color: isSelected
                            ? (ThemeData.estimateBrightnessForColor(
                                        accentColor,
                                      ) ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black)
                            : Colors.white70,
                        fontWeight: FontWeight.values[index],
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class UseNewFontLyricsTile extends ConsumerWidget {
  const UseNewFontLyricsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.type, color: Colors.white70),
      title: Text(l10n.useCustomFontLyrics, style: _tileTitleStyle()),
      subtitle: Text(l10n.useCustomFontLyricsDesc, style: _tileSubtitleStyle()),
      activeThumbColor: Color(settings.accentColor),
      value: settings.useNewFontLyrics,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateUseNewFontLyrics(value);
      },
    );
  }
}

class LyricsFontFamilySelectionTile extends ConsumerWidget {
  const LyricsFontFamilySelectionTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    final availableFonts = [
      'Sora',
      'Jost',
      'Space Grotesk',
      'Plus Jakarta Sans',
      'Google Sans',
    ];

    return ListTile(
      leading: const Icon(LucideIcons.type, color: Colors.white70),
      title: Text(l10n.lyricsFontFamily, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.activeLyricsFont(settings.customFontFamilyLyrics ?? 'Sora'),
        style: _tileSubtitleStyle(),
      ),
      trailing: DropdownButton<String>(
        value: availableFonts.contains(settings.customFontFamilyLyrics)
            ? settings.customFontFamilyLyrics
            : 'Sora',
        dropdownColor: const Color(0xFF1A1A1A),
        underline: const SizedBox(),
        items: availableFonts.map((font) {
          return DropdownMenuItem<String>(
            value: font,
            child: Text(font, style: AppFonts.jostStyle(color: Colors.white)),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            ref
                .read(settingsProvider.notifier)
                .updateCustomFontFamilyLyrics(value);
          }
        },
      ),
    );
  }
}

class LyricsFontWeightSelectionTile extends ConsumerWidget {
  const LyricsFontWeightSelectionTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final delta = settings.activeLyricsFontWeightDelta;
    final selectedWeight = 700 + (delta * 100);

    final weights = [400, 500, 600, 700, 800, 900];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(LucideIcons.bold, color: Colors.white70),
          title: Text(l10n.lyricsFontWeight, style: _tileTitleStyle()),
          subtitle: Text(
            '${l10n.currentWeight}: $selectedWeight',
            style: _tileSubtitleStyle(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: weights.length,
              itemBuilder: (context, index) {
                final w = weights[index];
                final isSelected = w == selectedWeight;
                final accentColor = Color(settings.accentColor);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    final newDelta = (w - 700) ~/ 100;
                    ref
                        .read(settingsProvider.notifier)
                        .updateActiveLyricsFontWeightDelta(newDelta);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8.0),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : Colors.white.withValues(alpha: 0.08),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '$w',
                      style: AppFonts.jostStyle(
                        color: isSelected
                            ? (ThemeData.estimateBrightnessForColor(
                                        accentColor,
                                      ) ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black)
                            : Colors.white70,
                        fontWeight: FontWeight
                            .values[index + 3], // 400 is w400 (index 3)
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
