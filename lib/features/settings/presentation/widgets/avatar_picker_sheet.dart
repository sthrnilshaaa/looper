import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/sheets/app_bottom_sheet.dart';
import 'package:looper_player/ui/widgets/common/selected_avatar.dart';

void showAvatarPickerSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _AvatarPickerSheetContent(),
  );
}

class _AvatarPickerSheetContent extends ConsumerWidget {
  const _AvatarPickerSheetContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final avatars = ref.watch(avatarAssetsProvider);
    final (selected, dynamicColor) = ref.watch(
      settingsProvider.select(
        (s) => (s.selectedAvatarAsset, s.avatarDynamicColor),
      ),
    );
    final accentColor = Color(
      ref.watch(settingsProvider.select((s) => s.accentColor)),
    );

    return AppBottomSheetContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.selectAvatars,
            style: AppFonts.jostStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          avatars.when(
            data: (assets) => GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: assets
                  .map(
                    (asset) => _AvatarOption(
                      asset: asset,
                      isSelected: asset == selected,
                      accent: dynamicColor
                          ? Theme.of(context).colorScheme.primary
                          : null,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ref
                            .read(settingsProvider.notifier)
                            .updateSelectedAvatar(asset);
                      },
                    ),
                  )
                  .toList(),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l10n.dynamicAvatarColor,
              style: AppFonts.jostStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              l10n.dynamicAvatarColorDesc,
              style: AppFonts.jostStyle(color: Colors.white54, fontSize: 12),
            ),
            activeThumbColor: accentColor,
            value: dynamicColor,
            onChanged: (value) {
              ref
                  .read(settingsProvider.notifier)
                  .updateAvatarDynamicColor(value);
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _AvatarOption extends StatelessWidget {
  const _AvatarOption({
    required this.asset,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  final String asset;
  final bool isSelected;
  final Color? accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.white12,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: AvatarIcon(assetFileName: asset, accent: accent),
      ),
    );
  }
}
