part of 'theme_settings_tiles.dart';

/// On: the lyrics screen draws the Now Playing background and hides its own
/// background options.
class LyricsFollowPlayerBackgroundTile extends ConsumerWidget {
  const LyricsFollowPlayerBackgroundTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.layers),
      title: Text(l10n.lyricsFollowPlayerBackground, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.lyricsFollowPlayerBackgroundDesc,
        style: _tileSubtitleStyle(),
      ),
      value: !settings.lyricsOwnBackground,
      onChanged: (value) => ref
          .read(settingsProvider.notifier)
          .updateLyricsFollowPlayerBackground(value),
    );
  }
}

class EnableLyricsGradientTile extends ConsumerWidget {
  const EnableLyricsGradientTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.sparkles),
      title: Text(l10n.enableLyricsGradient, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.enableLyricsGradientDesc,
        style: _tileSubtitleStyle(),
      ),
      value: settings.enableLyricsGradient,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateEnableLyricsGradient(value);
      },
    );
  }
}

class AmbientLyricsBgTile extends ConsumerWidget {
  const AmbientLyricsBgTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.music),
      title: Text(l10n.ambientColorBackground, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.ambientColorBackgroundDesc,
        style: _tileSubtitleStyle(),
      ),
      value: settings.ambientColorBackground,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateAmbientColorBackground(value);
      },
    );
  }
}

class BlurredArtworkLyricsTile extends ConsumerWidget {
  const BlurredArtworkLyricsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    return SwitchListTile(
      secondary: const Icon(LucideIcons.image),
      title: Text(l10n.blurredArtworkForLyrics, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.blurredArtworkForLyricsDesc,
        style: _tileSubtitleStyle(),
      ),
      value: settings.blurredArtworkForLyrics,
      onChanged: (value) {
        ref
            .read(settingsProvider.notifier)
            .updateBlurredArtworkForLyrics(value);
      },
    );
  }
}

class DynamicColorActiveLyricsTile extends ConsumerWidget {
  const DynamicColorActiveLyricsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.palette),
      title: Text(l10n.dynamicColorActiveLyrics, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.dynamicColorActiveLyricsDesc,
        style: _tileSubtitleStyle(),
      ),
      value: settings.dynamicColorActiveLyrics,
      onChanged: (value) {
        ref
            .read(settingsProvider.notifier)
            .updateDynamicColorActiveLyrics(value);
      },
    );
  }
}

/// Whether two lyric lines sung in one breath are shown together.
class LyricsLineGroupingTile extends ConsumerWidget {
  const LyricsLineGroupingTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.listCollapse),
      title: Text(l10n.lyricsLineGrouping, style: _tileTitleStyle()),
      subtitle: Text(l10n.lyricsLineGroupingDesc, style: _tileSubtitleStyle()),
      value: !settings.lyricsNoLineGrouping,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateLyricsLineGrouping(value);
      },
    );
  }
}

class LyricsTranslationTile extends ConsumerWidget {
  const LyricsTranslationTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.languages),
      title: Text(l10n.showLyricsTranslation, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.showLyricsTranslationDesc,
        style: _tileSubtitleStyle(),
      ),
      value: settings.showLyricsTranslation,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateShowLyricsTranslation(value);
      },
    );
  }
}

class LyricsRomanizationTile extends ConsumerWidget {
  const LyricsRomanizationTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.type),
      title: Text(l10n.showLyricsRomanization, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.showLyricsRomanizationDesc,
        style: _tileSubtitleStyle(),
      ),
      value: settings.showLyricsRomanization,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateShowLyricsRomanization(value);
      },
    );
  }
}

/// Slider for how see-through the lyric lines around the playing one are,
/// from solid to faint.
class InactiveLyricsOpacityTile extends ConsumerWidget {
  const InactiveLyricsOpacityTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SettingsSliderTile(
      icon: LucideIcons.contrast,
      title: l10n.inactiveLyricsOpacity,
      subtitle: l10n.inactiveLyricsOpacityDesc,
      value: inactiveLyricsOpacity(settings) * 100,
      min: AdvancedLyricLine.minInactiveOpacity * 100,
      max: AdvancedLyricLine.maxInactiveOpacity * 100,
      divisions: 90,
      suffix: '%',
      onChanged: (val) => ref
          .read(settingsProvider.notifier)
          .updateInactiveLyricsOpacity(val / 100.0),
    );
  }
}

/// Slider for how vibrant the active lyric line is drawn, with a preview of
/// the current song's active color next to an inactive line.
class ActiveLyricsIntensityTile extends ConsumerWidget {
  const ActiveLyricsIntensityTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    final intensity = settings.activeLyricsIntensity.isNaN
        ? 0.35
        : settings.activeLyricsIntensity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSliderTile(
          icon: LucideIcons.sunMedium,
          title: l10n.activeLyricsIntensity,
          subtitle: l10n.activeLyricsIntensityDesc,
          value: intensity * 100,
          min: 0.0,
          max: 100.0,
          divisions: 100,
          suffix: '%',
          onChanged: (val) {
            ref
                .read(settingsProvider.notifier)
                .updateActiveLyricsIntensity(val / 100.0);
          },
        ),
        const ActiveLyricsPreview(),
      ],
    );
  }
}

/// An inactive and an active lyric line drawn as the lyrics screen draws
/// them (white active line while Dynamic Color Active Line is off).
class ActiveLyricsPreview extends ConsumerWidget {
  const ActiveLyricsPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    // Same color the lyrics screen uses.
    final previewColor = activeLyricsColor(
      settings,
      accent: Theme.of(context).colorScheme.primary,
    );
    final previewStyle = AppFonts.getLyricsStyle(
      useNewFontLyrics: settings.useNewFontLyrics,
      family: settings.customFontFamilyLyrics,
      weightDelta: settings.customFontWeightLyricsDelta,
      activeWeightDelta: settings.activeLyricsFontWeightDelta,
      isActive: true,
      fontSize: 18,
      height: 1.2,
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.activeLyricsIntensityPreviewInactive,
            style: previewStyle.copyWith(
              color: Colors.white.withValues(
                alpha: inactiveLyricsOpacity(settings),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.activeLyricsIntensityPreviewActive,
            style: previewStyle.copyWith(
              color: previewColor,
              shadows: [
                Shadow(
                  color: previewColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LyricsAlignmentTile extends ConsumerWidget {
  const LyricsAlignmentTile({super.key});

  Widget _buildAlignmentButton({
    required BuildContext context,
    required WidgetRef ref,
    required String alignment,
    required IconData icon,
    required String currentAlignment,
    required Color accentColor,
  }) {
    final isSelected = currentAlignment == alignment;
    return GestureDetector(
      onTap: () {
        AppHaptics.light();
        ref.read(settingsProvider.notifier).updateLyricsAlignment(alignment);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected ? Colors.black : Colors.white70,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    final tile = ListTile(
      leading: const Icon(LucideIcons.alignCenter),
      title: Text(l10n.lyricsAlignment, style: _tileTitleStyle()),
      subtitle: Text(l10n.lyricsAlignmentDesc, style: _tileSubtitleStyle()),
      trailing: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10, width: 0.5),
        ),
        padding: const EdgeInsets.all(2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAlignmentButton(
              context: context,
              ref: ref,
              alignment: 'left',
              icon: LucideIcons.alignLeft,
              currentAlignment: settings.lyricsAlignment,
              accentColor: settings.accent,
            ),
            _buildAlignmentButton(
              context: context,
              ref: ref,
              alignment: 'center',
              icon: LucideIcons.alignCenter,
              currentAlignment: settings.lyricsAlignment,
              accentColor: settings.accent,
            ),
            _buildAlignmentButton(
              context: context,
              ref: ref,
              alignment: 'right',
              icon: LucideIcons.alignRight,
              currentAlignment: settings.lyricsAlignment,
              accentColor: settings.accent,
            ),
          ],
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        tile,
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: LyricsAlignmentPreview(
            alignment: settings.lyricsAlignment,
            accent: settings.accent,
          ),
        ),
      ],
    );
  }
}

/// Lyrics screen style card in Settings -> Lyrics: shows a horizontal strip of
/// all 12 styles and opens the full-screen [LyricsStylePickerScreen] preview.
class LyricsStyleTile extends ConsumerWidget {
  const LyricsStyleTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final current = LyricsScreenStyle.fromSetting(
      ref.watch(settingsProvider.select((s) => s.lyricsStyle)),
    );
    final accent = Theme.of(context).colorScheme.primary;
    final currentLabel = lyricsStyleLabel(l10n, current);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.fromLTRB(21, 20, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => openLyricsStylePicker(context),
            child: SizedBox(
              height: 22,
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.sparkles,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '${l10n.lyricsStyle} › '),
                          TextSpan(
                            text: currentLabel,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.jostStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    LucideIcons.chevronRight,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0x05FFFFFF)),
          const SizedBox(height: 16),
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: LyricsScreenStyle.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final s = LyricsScreenStyle.values[i];
                final selected = s == current;
                final label = lyricsStyleLabel(l10n, s);
                return SizedBox(
                  width: 66,
                  child: GestureDetector(
                    onTap: () {
                      AppHaptics.selection();
                      ref
                          .read(settingsProvider.notifier)
                          .updateLyricsStyle(s.name);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 64,
                          height: 84,
                          decoration: BoxDecoration(
                            color: s == LyricsScreenStyle.oled
                                ? Colors.black
                                : const Color(0xFF14151B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.1),
                              width: selected ? 2 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: LyricsStyleSkeleton(
                            style: s,
                            accent: accent,
                            selected: selected,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppFonts.jostStyle(
                            color: selected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.48),
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Neutral-chrome "Lyrics text" customization panel (Font, Weight, Italic,
/// Size, Line spacing, Alignment, Case, and Reset to style defaults).
/// "Auto" values defer to the active style's [LyricsTextSpec].
class LyricsTextPanelTile extends ConsumerWidget {
  final bool compact;
  const LyricsTextPanelTile({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    final double fontScale = settings.lyricsFontScale.isNaN
        ? 1.0
        : settings.lyricsFontScale.clamp(0.8, 1.3);
    final double lineSpacing = settings.lyricsLineSpacing.isNaN
        ? 1.0
        : settings.lyricsLineSpacing.clamp(0.9, 1.5);

    Widget segButton({
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) => Expanded(
      child: GestureDetector(
        onTap: () {
          AppHaptics.selection();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.settingsStyle(
              color: selected ? Colors.black : Colors.white70,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );

    Widget sectionHeader(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppFonts.settingsStyle(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    final fontChoices = <(String?, String)>[
      (null, l10n.lyricsTextStyleDefault),
      for (final f in AppFonts.selectableFamilies) (f, f),
    ];

    return Container(
      margin: compact
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: compact ? Colors.white.withValues(alpha: 0.04) : const Color(0xFF101010),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.lyricsTextSection,
            style: AppFonts.settingsStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Font 3-column grid
          sectionHeader(l10n.lyricsTextFont),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: fontChoices.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.55,
            ),
            itemBuilder: (context, i) {
              final (family, label) = fontChoices[i];
              final selected = settings.customFontFamilyLyrics == family;
              return GestureDetector(
                onTap: () {
                  AppHaptics.selection();
                  notifier.updateCustomFontFamilyLyrics(family);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        family == null ? '✦' : 'Aa',
                        style: family == null
                            ? AppFonts.settingsStyle(
                                color: selected ? Colors.black : Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              )
                            : AppFonts.familyStyle(
                                family,
                                color: selected ? Colors.black : Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppFonts.settingsStyle(
                          color: selected ? Colors.black87 : Colors.white54,
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Weight 5-way segmented control
          sectionHeader(l10n.lyricsTextWeight),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                segButton(
                  label: l10n.lyricsTextAuto,
                  selected: settings.lyricsWeightOverride == 0,
                  onTap: () => notifier.updateLyricsWeightOverride(0),
                ),
                segButton(
                  label: l10n.lyricsTextWeightLight,
                  selected: settings.lyricsWeightOverride == 300,
                  onTap: () => notifier.updateLyricsWeightOverride(300),
                ),
                segButton(
                  label: l10n.lyricsTextWeightMed,
                  selected: settings.lyricsWeightOverride == 500,
                  onTap: () => notifier.updateLyricsWeightOverride(500),
                ),
                segButton(
                  label: l10n.lyricsTextWeightBold,
                  selected: settings.lyricsWeightOverride == 700,
                  onTap: () => notifier.updateLyricsWeightOverride(700),
                ),
                segButton(
                  label: l10n.lyricsTextWeightHeavy,
                  selected: settings.lyricsWeightOverride == 800,
                  onTap: () => notifier.updateLyricsWeightOverride(800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Italic switch
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.lyricsTextItalic, style: _tileTitleStyle()),
            value: settings.lyricsItalic,
            activeThumbColor: Colors.black,
            activeTrackColor: Colors.white,
            onChanged: (v) => notifier.updateLyricsItalic(v),
          ),
          const SizedBox(height: 6),

          // Size slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.lyricsTextSize, style: _tileTitleStyle()),
              Text(
                '${(fontScale * 100).round()}%',
                style: _tileSubtitleStyle(),
              ),
            ],
          ),
          Slider(
            value: fontScale,
            min: 0.8,
            max: 1.3,
            divisions: 10,
            activeColor: Colors.white,
            inactiveColor: Colors.white24,
            onChanged: (v) => notifier.updateLyricsFontScale(v),
          ),

          // Line spacing slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.lyricsTextLineSpacing, style: _tileTitleStyle()),
              Text(
                '${lineSpacing.toStringAsFixed(2)}×',
                style: _tileSubtitleStyle(),
              ),
            ],
          ),
          Slider(
            value: lineSpacing,
            min: 0.9,
            max: 1.5,
            divisions: 12,
            activeColor: Colors.white,
            inactiveColor: Colors.white24,
            onChanged: (v) => notifier.updateLyricsLineSpacing(v),
          ),
          const SizedBox(height: 8),

          // Alignment 4-way
          sectionHeader(l10n.lyricsTextAlignment),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                segButton(
                  label: l10n.lyricsTextAuto,
                  selected: settings.lyricsAlignment == 'auto',
                  onTap: () => notifier.updateLyricsAlignment('auto'),
                ),
                segButton(
                  label: l10n.lyricsTextAlignLeft,
                  selected: settings.lyricsAlignment == 'left',
                  onTap: () => notifier.updateLyricsAlignment('left'),
                ),
                segButton(
                  label: l10n.lyricsTextAlignCenter,
                  selected: settings.lyricsAlignment == 'center',
                  onTap: () => notifier.updateLyricsAlignment('center'),
                ),
                segButton(
                  label: l10n.lyricsTextAlignRight,
                  selected: settings.lyricsAlignment == 'right',
                  onTap: () => notifier.updateLyricsAlignment('right'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Case 3-way
          sectionHeader(l10n.lyricsTextCase),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                segButton(
                  label: 'Aa',
                  selected: settings.lyricsTextCase == 'auto',
                  onTap: () => notifier.updateLyricsTextCase('auto'),
                ),
                segButton(
                  label: 'AA',
                  selected: settings.lyricsTextCase == 'upper',
                  onTap: () => notifier.updateLyricsTextCase('upper'),
                ),
                segButton(
                  label: 'aa',
                  selected: settings.lyricsTextCase == 'lower',
                  onTap: () => notifier.updateLyricsTextCase('lower'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Reset to style defaults
          OutlinedButton(
            onPressed: () {
              AppHaptics.medium();
              notifier.resetLyricsTextToDefaults();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              l10n.lyricsTextReset,
              style: AppFonts.settingsStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
