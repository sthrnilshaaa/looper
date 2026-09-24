import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/core/app_fonts.dart';
import 'package:looper_player/features/library/presentation/library_notifier.dart';
import 'package:looper_player/features/settings/presentation/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/folder_picker_helper.dart';
import 'settings_dialogs.dart';

class AddFolderTile extends ConsumerWidget {
  const AddFolderTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(LucideIcons.plus, color: Colors.white70),
      title: Text(l10n.addFolder, style: _tileTitleStyle()),
      trailing: const Icon(
        LucideIcons.chevronRight,
        color: Colors.white30,
        size: 18,
      ),
      onTap: () async {
        HapticFeedback.lightImpact();
        await FolderPickerHelper.pickFolder(context, ref);
      },
    );
  }
}

class ExcludedFoldersTile extends ConsumerWidget {
  const ExcludedFoldersTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final excluded = ref.watch(excludedFoldersProvider);
    return ListTile(
      leading: const Icon(LucideIcons.folderMinus, color: Colors.white70),
      // Not localized: a small addition to an already-large l10n surface -
      // see the equivalent note in songs_list.dart's multi-select bar.
      title: Text('Excluded Folders', style: _tileTitleStyle()),
      subtitle: Text(
        excluded.isEmpty ? 'None' : '${excluded.length} folder(s) skipped when scanning',
        style: _tileSubtitleStyle(),
      ),
      trailing: const Icon(
        LucideIcons.chevronRight,
        color: Colors.white30,
        size: 18,
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        _showExcludedFoldersSheet(context, ref, l10n);
      },
    );
  }

  void _showExcludedFoldersSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Consumer(
        builder: (sheetContext, ref, _) {
          final excluded = ref.watch(excludedFoldersProvider);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Excluded Folders', style: AppFonts.jostStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    'Songs in these folders are skipped during a scan, even if they sit inside a folder you added.',
                    style: _tileSubtitleStyle(),
                  ),
                  const SizedBox(height: 12),
                  if (excluded.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text('No excluded folders yet.', style: _tileSubtitleStyle()),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: excluded.length,
                        itemBuilder: (context, index) {
                          final folder = excluded[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(LucideIcons.folder, size: 18, color: Colors.white54),
                            title: Text(
                              folder,
                              style: _tileTitleStyle(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon: const Icon(LucideIcons.x, size: 18, color: Colors.redAccent),
                              onPressed: () => ref.read(excludedFoldersProvider.notifier).remove(folder),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () async {
                      final path = await FolderPickerHelper.pickFolderPathOnly(sheetContext);
                      if (path != null) {
                        await ref.read(excludedFoldersProvider.notifier).add(path);
                      }
                    },
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('Exclude a Folder'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class SyncLyricsOfflineTile extends ConsumerWidget {
  const SyncLyricsOfflineTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(LucideIcons.downloadCloud, color: Colors.white70),
      title: Text(l10n.syncLyricsOffline, style: _tileTitleStyle()),
      trailing: const Icon(
        LucideIcons.chevronRight,
        color: Colors.white30,
        size: 18,
      ),
      onTap: () {
        HapticFeedback.mediumImpact();
        ref.read(libraryProvider.notifier).prefetchLibraryLyrics();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.downloadingLyricsOffline)));
      },
    );
  }
}

class RescanLibraryTile extends ConsumerWidget {
  const RescanLibraryTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(LucideIcons.refreshCcw, color: Colors.white70),
      title: Text(l10n.rescanLibrary, style: _tileTitleStyle()),
      trailing: const Icon(
        LucideIcons.chevronRight,
        color: Colors.white30,
        size: 18,
      ),
      onTap: () {
        HapticFeedback.mediumImpact();
        ref
            .read(libraryProvider.notifier)
            .scanSavedFolders(fullStorageDiscovery: true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.scanningLibrary)));
      },
    );
  }
}

class IncludeSystemAndMessagingAudioTile extends ConsumerWidget {
  const IncludeSystemAndMessagingAudioTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final enabled = ref.watch(
      settingsProvider.select((s) => s.includeSystemAndMessagingAudio),
    );
    return SwitchListTile(
      secondary: const Icon(LucideIcons.audioLines, color: Colors.white70),
      title: Text(l10n.includeOtherDeviceAudioTitle, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.includeOtherDeviceAudioDesc,
        style: _tileSubtitleStyle(),
      ),
      value: enabled,
      onChanged: (value) async {
        HapticFeedback.lightImpact();
        await ref
            .read(settingsProvider.notifier)
            .updateIncludeSystemAndMessagingAudio(value);
        await ref
            .read(libraryProvider.notifier)
            .scanSavedFolders(fullStorageDiscovery: true);
      },
    );
  }
}

class ResetLibraryTile extends ConsumerWidget {
  const ResetLibraryTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(LucideIcons.trash2, color: Colors.redAccent),
      title: Text(
        l10n.resetLibrary,
        style: AppFonts.jostStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(
        LucideIcons.alertTriangle,
        color: Colors.redAccent,
        size: 16,
      ),
      onTap: () {
        HapticFeedback.heavyImpact();
        showClearDialog(context, l10n);
      },
    );
  }
}

TextStyle _tileTitleStyle() =>
    AppFonts.jostStyle(color: Colors.white, fontWeight: FontWeight.w500);

TextStyle _tileSubtitleStyle() =>
    AppFonts.jostStyle(color: Colors.white54, fontSize: 12);
