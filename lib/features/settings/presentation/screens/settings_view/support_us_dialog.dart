part of 'settings_view.dart';

extension _SettingsSupportUsDialog on _SettingsViewState {
  void _showSupportUsDialog(
    BuildContext context,
    ColorScheme colorScheme,
    bool useBlur,
  ) {
    ref.read(supportUsSheetVisibleProvider.notifier).set(true);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black54,
      builder: (context) {
        const coffeeUrl = AppLinks.buyMeACoffee;
        final l10n = AppLocalizations.of(context)!;

        return AppBottomSheetContainer(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(context).padding.bottom + 24,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _PulsingHeart(),
                const SizedBox(height: 16),
                Text(
                  l10n.supportDevelopment,
                  style: AppFonts.jostStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.supportDevelopmentDesc,
                  textAlign: TextAlign.center,
                  style: AppFonts.jostStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFFFFDD00),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFDD00).withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        HapticFeedback.mediumImpact();
                        final upiUri = Uri.parse(AppLinks.upiPay);
                        final webUri = Uri.parse(AppLinks.buyMeACoffee);
                        try {
                          final launched = await launchUrl(
                            upiUri,
                            mode: LaunchMode.externalApplication,
                          );
                          if (!launched) {
                            await launchUrl(
                              webUri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        } catch (_) {
                          try {
                            await launchUrl(
                              webUri,
                              mode: LaunchMode.externalApplication,
                            );
                          } catch (_) {}
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.coffee,
                              size: 20,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              l10n.buyMeCoffee,
                              style: AppFonts.jostStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      ref.read(supportUsSheetVisibleProvider.notifier).set(false);
    });
  }
}
