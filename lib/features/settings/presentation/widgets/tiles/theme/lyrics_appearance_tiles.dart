part of 'theme_settings_tiles.dart';

class AmbientLyricsBgTile extends ConsumerWidget {
  const AmbientLyricsBgTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.music, color: Colors.white70),
      title: Text(l10n.ambientColorBackground, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.ambientColorBackgroundDesc,
        style: _tileSubtitleStyle(),
      ),
      activeThumbColor: Color(settings.accentColor),
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
      secondary: const Icon(LucideIcons.image, color: Colors.white70),
      title: Text(l10n.blurredArtworkForLyrics, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.blurredArtworkForLyricsDesc,
        style: _tileSubtitleStyle(),
      ),
      activeThumbColor: Color(settings.accentColor),
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
      secondary: const Icon(LucideIcons.palette, color: Colors.white70),
      title: Text(l10n.dynamicColorActiveLyrics, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.dynamicColorActiveLyricsDesc,
        style: _tileSubtitleStyle(),
      ),
      activeThumbColor: Color(settings.accentColor),
      value: settings.dynamicColorActiveLyrics,
      onChanged: (value) {
        ref
            .read(settingsProvider.notifier)
            .updateDynamicColorActiveLyrics(value);
      },
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
        HapticFeedback.lightImpact();
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
    return ListTile(
      leading: const Icon(LucideIcons.alignCenter, color: Colors.white70),
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
              accentColor: Color(settings.accentColor),
            ),
            _buildAlignmentButton(
              context: context,
              ref: ref,
              alignment: 'center',
              icon: LucideIcons.alignCenter,
              currentAlignment: settings.lyricsAlignment,
              accentColor: Color(settings.accentColor),
            ),
            _buildAlignmentButton(
              context: context,
              ref: ref,
              alignment: 'right',
              icon: LucideIcons.alignRight,
              currentAlignment: settings.lyricsAlignment,
              accentColor: Color(settings.accentColor),
            ),
          ],
        ),
      ),
    );
  }
}
