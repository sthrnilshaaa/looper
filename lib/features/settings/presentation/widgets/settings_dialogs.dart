import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:looper_player/core/motion/app_routes.dart';
import 'package:looper_player/core/motion/looper_scroll_physics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_hsvcolor_picker/flutter_hsvcolor_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/features/settings/domain/home_order.dart';
import 'package:looper_player/ui/widgets/sheets/app_bottom_sheet.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';

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
                      style: AppFonts.settingsStyle(
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
                        AppHaptics.medium();
                        Navigator.pop(context);
                      },
                      child: Text(
                        l10n.done,
                        style: AppFonts.settingsStyle(
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
    builder: (context) => const ReorderDashboardSectionsSheet(),
  );
}

class ReorderDashboardSectionsSheet extends ConsumerStatefulWidget {
  const ReorderDashboardSectionsSheet({super.key});

  @override
  ConsumerState<ReorderDashboardSectionsSheet> createState() =>
      _ReorderDashboardSectionsSheetState();
}

class _ReorderDashboardSectionsSheetState
    extends ConsumerState<ReorderDashboardSectionsSheet> {
  late List<String> _currentOrder;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    final savedOrder = settings.homeSectionOrder.isEmpty
        ? AppSettings.defaultHomeSectionOrder
        : settings.homeSectionOrder;
    _currentOrder = [...savedOrder];
  }

  void _onReorder(int oldIndex, int newIndex) {
    AppHaptics.light();
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final String item = _currentOrder.removeAt(oldIndex);
      _currentOrder.insert(newIndex, item);
    });

    final currentSettings = ref.read(settingsProvider);
    final savedOrder = currentSettings.homeSectionOrder.isEmpty
        ? AppSettings.defaultHomeSectionOrder
        : currentSettings.homeSectionOrder;
    ref
        .read(settingsProvider.notifier)
        .updateHomeSectionOrder(mergeHomeOrder(savedOrder, _currentOrder));
  }

  void _resetToDefault() {
    AppHaptics.medium();
    final defaultOrder = [...AppSettings.defaultHomeSectionOrder];
    setState(() => _currentOrder = [...defaultOrder]);
    ref.read(settingsProvider.notifier).updateHomeSectionOrder(defaultOrder);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final accent = settings.accent;
    final mq = MediaQuery.of(context);
    final sheetHeight = math.min(mq.size.height * 0.85, 750.0);

    return AppBottomSheetContainer(
      height: sheetHeight,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              l10n.reorderDashboardSections,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.jostStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_currentOrder.length}',
                              style: AppFonts.jostStyle(
                                color: accent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.reorderDashboardSectionsDesc,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.jostStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _resetToDefault,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.rotateCcw,
                            color: Colors.white70,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            l10n.reset,
                            style: AppFonts.jostStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Hairline divider
          Divider(
            height: 1,
            thickness: 0.6,
            color: Colors.white.withValues(alpha: 0.06),
          ),

          // Scrollable list
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              physics: const LooperScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _currentOrder.length,
              onReorderStart: (_) => AppHaptics.selection(),
              onReorderEnd: (_) => AppHaptics.light(),
              onReorder: _onReorder,
              proxyDecorator: (child, index, animation) => AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  final t = Curves.easeInOut.transform(animation.value);
                  final double scale = lerpDouble(1.0, 1.025, t)!;
                  final double elevation = lerpDouble(0, 14, t)!;
                  return Transform.scale(
                    scale: scale,
                    child: Material(
                      color: Colors.transparent,
                      elevation: elevation,
                      shadowColor: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        children: [
                          child,
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.7 * t),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              itemBuilder: (context, index) {
                final key = _currentOrder[index];
                final (:title, description: desc, :icon) = homeRowInfo(
                  key,
                  l10n,
                );
                return _SectionReorderTile(
                  key: ValueKey(key),
                  index: index,
                  title: title,
                  description: desc,
                  icon: icon,
                  accent: accent,
                );
              },
            ),
          ),

          // Hairline divider above footer
          Divider(
            height: 1,
            thickness: 0.6,
            color: Colors.white.withValues(alpha: 0.06),
          ),

          // Pinned Footer (Done button)
          Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + mq.padding.bottom),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
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
          ),
        ],
      ),
    );
  }
}

class _SectionReorderTile extends StatelessWidget {
  final int index;
  final String title;
  final String description;
  final IconData icon;
  final Color accent;

  const _SectionReorderTile({
    super.key,
    required this.index,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
          width: 0.8,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${index + 1}',
                style: AppFonts.jostStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: accent, size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.jostStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.jostStyle(
                        color: Colors.white38,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: const Icon(
                  LucideIcons.gripVertical,
                  color: Colors.white38,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showClearDialog(BuildContext context, AppLocalizations l10n) {
  showTaskDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        l10n.resetLibrary,
        style: AppFonts.settingsStyle(color: Colors.white),
      ),
      content: Text(
        l10n.resetLibraryConfirmNew,
        style: AppFonts.settingsStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            l10n.cancel,
            style: AppFonts.settingsStyle(color: Colors.white38),
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
            style: AppFonts.settingsStyle(color: Colors.redAccent),
          ),
        ),
      ],
    ),
  );
}
