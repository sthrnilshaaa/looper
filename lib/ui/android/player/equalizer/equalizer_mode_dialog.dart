part of 'android_equalizer_screen.dart';

void _showEqualizerModeDialog(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      final settings = ref.watch(settingsProvider);
      final accentColor = Color(settings.accentColor);
      final isGlobal = settings.equalizerGlobalMode;

      return AppBottomSheetContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(LucideIcons.sliders, color: accentColor, size: 22),
                const SizedBox(width: 12),
                Text(
                  l10n.equalizerTargetMode,
                  style: AppFonts.jostStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.equalizerTargetModeDesc,
              style: AppFonts.jostStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 20),

            // Global Mode Card
            Container(
              decoration: BoxDecoration(
                color: isGlobal
                    ? accentColor.withValues(alpha: 0.08)
                    : settings.darkTheme
                    ? Colors.white.withValues(alpha: 0.03)
                    : const Color(0xFF1E1E1B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isGlobal
                      ? accentColor.withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.08),
                  width: isGlobal ? 1.5 : 1.0,
                ),
              ),
              child: PremiumSection(
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(16),
                useExpanded: false,
                useCenter: false,
                forceTransparent: true,
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  await ref
                      .read(settingsProvider.notifier)
                      .updateEqualizerGlobalMode(true);
                  final currentSong = ref.read(playbackProvider).currentSong;
                  ref
                      .read(equalizerProvider.notifier)
                      .onSongChanged(currentSong);
                  ref.read(equalizerProvider.notifier).applyEqualizerInstant();
                  Navigator.of(context).pop();
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isGlobal
                            ? accentColor.withValues(alpha: 0.15)
                            : Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.globe,
                        color: isGlobal ? accentColor : Colors.white60,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                l10n.globalMode,
                                style: AppFonts.jostStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (isGlobal) ...[
                                const Spacer(),
                                Icon(
                                  LucideIcons.check,
                                  color: accentColor,
                                  size: 18,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.globalModeDesc,
                            style: AppFonts.jostStyle(
                              fontSize: 13,
                              color: Colors.white60,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Song-Specific Mode Card
            Container(
              decoration: BoxDecoration(
                color: !isGlobal
                    ? accentColor.withValues(alpha: 0.08)
                    : settings.darkTheme
                    ? Colors.white.withValues(alpha: 0.03)
                    : const Color(0xFF1E1E1B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: !isGlobal
                      ? accentColor.withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.08),
                  width: !isGlobal ? 1.5 : 1.0,
                ),
              ),
              child: PremiumSection(
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(16),
                useExpanded: false,
                useCenter: false,
                forceTransparent: true,
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  await ref
                      .read(settingsProvider.notifier)
                      .updateEqualizerGlobalMode(false);
                  final currentSong = ref.read(playbackProvider).currentSong;
                  ref
                      .read(equalizerProvider.notifier)
                      .onSongChanged(currentSong);
                  ref.read(equalizerProvider.notifier).applyEqualizerInstant();
                  Navigator.of(context).pop();
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: !isGlobal
                            ? accentColor.withValues(alpha: 0.15)
                            : Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.music,
                        color: !isGlobal ? accentColor : Colors.white60,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                l10n.songSpecificMode,
                                style: AppFonts.jostStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (!isGlobal) ...[
                                const Spacer(),
                                Icon(
                                  LucideIcons.check,
                                  color: accentColor,
                                  size: 18,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.songSpecificModeDesc,
                            style: AppFonts.jostStyle(
                              fontSize: 13,
                              color: Colors.white60,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Button to view Audio capabilities
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _showAudioCapabilitiesSheet(context, ref);
              },
              icon: Icon(
                LucideIcons.activity,
                color: accentColor.withValues(alpha: 0.7),
                size: 16,
              ),
              label: Text(
                l10n.viewDeviceAudioCapabilities,
                style: AppFonts.jostStyle(
                  fontSize: 13,
                  color: accentColor.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
