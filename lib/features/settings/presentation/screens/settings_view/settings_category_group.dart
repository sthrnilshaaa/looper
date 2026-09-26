part of 'settings_view.dart';

extension _SettingsCategoryGroup on _SettingsViewState {
  Widget _buildCategoryGroup({
    required BuildContext context,
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required ColorScheme colorScheme,
    required bool useBlur,
    required AppSettings settings,
  }) {
    return Column(
      children: [
        PremiumSection(
          useBlur: useBlur,
          forceNoBlur: true,
          borderRadius: BorderRadius.circular(20),
          useExpanded: false,
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              if (id == 'support_us') {
                _showSupportUsDialog(context, colorScheme, useBlur);
                return;
              }
              // Routed through appNavigationProvider (not a raw Navigator
              // push) so the sub-page is tracked in nav history -- otherwise
              // the system back button's PopScope handler (which always
              // resolves through appNavigationProvider.goBack()) has no
              // record of this level and collapses straight past both this
              // screen and Settings back to the main tab in one shot.
              ref
                  .read(appNavigationProvider.notifier)
                  .showSettingsCategory(id: id, title: title);
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(
                        settings.accentColor,
                      ).withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: Color(settings.accentColor),
                      size: 20.s,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppFonts.jostStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: AppFonts.jostStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    color: Colors.white.withValues(alpha: 0.4),
                    size: 18.s,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
