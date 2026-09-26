import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_hsvcolor_picker/flutter_hsvcolor_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/sheets/app_bottom_sheet.dart';

void showCustomColorPicker(
  BuildContext context,
  WidgetRef ref,
  Color initialColor,
) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final l10n = AppLocalizations.of(context)!;
          final currentAccent = ref.watch(settingsProvider).accentColor;
          return AppBottomSheetContainer(
            height: 650,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.customAccentColor,
                      style: AppFonts.jostStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Color(currentAccent),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: ColorPicker(
                      color: Color(currentAccent),
                      onChanged: (color) {
                        ref
                            .read(settingsProvider.notifier)
                            .updateAccentColor(color.toARGB32());
                        setModalState(() {});
                      },
                      initialPicker: Picker.paletteHue,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                      },
                      child: Text(
                        l10n.done,
                        style: AppFonts.jostStyle(
                          color: Color(currentAccent),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

void showReorderBottomSheet(
  BuildContext context,
  WidgetRef ref,
  AppSettings settings,
) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      return StatefulBuilder(
        builder: (context, setModalState) {
          final currentSettings = ref.watch(settingsProvider);
          final currentOrder = List<String>.from(
            currentSettings.homeSectionOrder.isEmpty
                ? [
                    'quick_picks',
                    'songs',
                    'albums',
                    'artists',
                    'genres',
                    'recent',
                  ]
                : currentSettings.homeSectionOrder,
          );

          final itemMeta = {
            'quick_picks': {
              'title': l10n.quickPicks,
              'description': l10n.quickPicksRowDesc,
              'icon': LucideIcons.sparkles,
            },
            'songs': {
              'title': l10n.songs,
              'description': l10n.recentlyAddedSongsRowDesc,
              'icon': LucideIcons.music,
            },
            'albums': {
              'title': l10n.albums,
              'description': l10n.albumsRowDesc,
              'icon': LucideIcons.disc,
            },
            'artists': {
              'title': l10n.artists,
              'description': l10n.artistsRowDesc,
              'icon': LucideIcons.user,
            },
            'genres': {
              'title': l10n.genres,
              'description': l10n.genresRowDesc,
              'icon': LucideIcons.library,
            },
            'recent': {
              'title': l10n.recentPlayed,
              'description': l10n.recentRowDesc,
              'icon': LucideIcons.history,
            },
          };

          return AppBottomSheetContainer(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.reorderDashboardSections,
                  style: AppFonts.jostStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.reorderDashboardSectionsDesc,
                  style: AppFonts.jostStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: currentOrder.length,
                    onReorder: (oldIndex, newIndex) {
                      HapticFeedback.lightImpact();
                      setModalState(() {
                        if (oldIndex < newIndex) {
                          newIndex -= 1;
                        }
                        final String item = currentOrder.removeAt(oldIndex);
                        currentOrder.insert(newIndex, item);
                        ref
                            .read(settingsProvider.notifier)
                            .updateHomeSectionOrder(currentOrder);
                      });
                    },
                    itemBuilder: (context, index) {
                      final key = currentOrder[index];
                      final meta =
                          itemMeta[key] ??
                          {
                            'title': key,
                            'description': '',
                            'icon': LucideIcons.layers,
                          };

                      final title = meta['title'] as String;
                      final desc = meta['description'] as String;
                      final icon = meta['icon'] as IconData;

                      return Container(
                        key: ValueKey(key),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(
                                currentSettings.accentColor,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              icon,
                              color: Color(currentSettings.accentColor),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            title,
                            style: AppFonts.jostStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            desc,
                            style: AppFonts.jostStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                          trailing: ReorderableDragStartListener(
                            index: index,
                            child: const Icon(
                              LucideIcons.gripVertical,
                              color: Colors.white30,
                              size: 20,
                            ),
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
                      backgroundColor: Color(currentSettings.accentColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
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
          );
        },
      );
    },
  );
}

void showClearDialog(BuildContext context, AppLocalizations l10n) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        l10n.resetLibrary,
        style: AppFonts.jostStyle(color: Colors.white),
      ),
      content: Text(
        l10n.resetLibraryConfirmNew,
        style: AppFonts.jostStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            l10n.cancel,
            style: AppFonts.jostStyle(color: Colors.white38),
          ),
        ),
        TextButton(
          onPressed: () async {
            await DbService.isar.writeTxn(() async {
              await DbService.isar.songs.clear();
              await DbService.isar.albums.clear();
              await DbService.isar.artists.clear();
            });
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: Text(
            l10n.clear,
            style: AppFonts.jostStyle(color: Colors.redAccent),
          ),
        ),
      ],
    ),
  );
}
