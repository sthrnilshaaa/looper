part of 'android_equalizer_screen.dart';

void _showAudioCapabilitiesSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (context) {
      final settings = ref.read(settingsProvider);
      final accentColor = Color(settings.accentColor);

      return FutureBuilder<Map<String, String>>(
        future: ref.read(audioServiceProvider).getAudioOutputCapabilities(),
        builder: (context, snapshot) {
          final l10n = AppLocalizations.of(context)!;
          final capabilities = snapshot.data ?? {};
          return AppBottomSheetContainer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.activity, color: accentColor, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      l10n.deviceAudioCapabilities,
                      style: AppFonts.jostStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white10),
                const SizedBox(height: 12),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (capabilities.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Text(
                      l10n.noPlaybackActiveCapabilities,
                      style: AppFonts.jostStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: capabilities.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Text(
                                  entry.key,
                                  style: AppFonts.jostStyle(
                                    color: Colors.white54,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  entry.value,
                                  style: AppFonts.jostStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      );
    },
  );
}
