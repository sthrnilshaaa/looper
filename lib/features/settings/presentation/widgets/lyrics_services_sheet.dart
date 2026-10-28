import 'package:looper_player/core/motion/looper_scroll_physics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/playback/data/lyrics_fetcher.dart';
import 'package:looper_player/features/playback/data/lyrics_providers/lyrics_provider_info.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/sheets/app_bottom_sheet.dart';

/// The switched-on lyrics services in lookup order, as `A > B > C`.
String lyricsServiceChain(AppSettings settings) =>
    LyricsFetcher.enabledProviders(
      settings,
    ).map((id) => LyricsProviderInfo.of(id)?.label ?? id).join(' > ');

/// Lyrics services: drag to set the order lookups ask them in, switch one
/// off to have lookups skip it. Changes are saved as they're made.
void showLyricsServicesSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _LyricsServicesSheet(),
  );
}

class _LyricsServicesSheet extends ConsumerWidget {
  const _LyricsServicesSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final accent = Color(settings.accentColor);
    final order = LyricsFetcher.providerOrder(settings);
    final enabled = LyricsFetcher.enabledProviders(settings).toSet();

    return AppBottomSheetContainer(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: ConstrainedBox(
        // AppBottomSheetContainer lays its child out with unbounded height.
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.lyricsServices,
              style: AppFonts.jostStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.lyricsServicesDesc,
              style: AppFonts.jostStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              lyricsServiceChain(settings),
              style: AppFonts.jostStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                physics: const LooperScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: order.length,
                onReorder: (oldIndex, newIndex) {
                  AppHaptics.light();
                  if (oldIndex < newIndex) newIndex -= 1;
                  final next = [...order];
                  next.insert(newIndex, next.removeAt(oldIndex));
                  notifier.updateLyricsProviderOrder(next);
                },
                itemBuilder: (context, index) {
                  final id = order[index];
                  final isOn = enabled.contains(id);
                  return Container(
                    key: ValueKey(id),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.only(left: 8, right: 8),
                      leading: ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            LucideIcons.gripVertical,
                            color: Colors.white30,
                            size: 20,
                          ),
                        ),
                      ),
                      title: Text(
                        LyricsProviderInfo.of(id)?.label ?? id,
                        style: AppFonts.jostStyle(
                          color: isOn ? Colors.white : Colors.white38,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      trailing: Switch(
                        value: isOn,
                        activeThumbColor: accent,
                        onChanged: (value) {
                          AppHaptics.selection();
                          notifier.setLyricsProviderEnabled(id, value);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  AppHaptics.medium();
                  Navigator.pop(context);
                },
                child: Text(
                  l10n.done,
                  style: AppFonts.jostStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
