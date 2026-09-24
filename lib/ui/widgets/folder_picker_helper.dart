import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:looper_player/features/library/data/saf_folder_service.dart';
import 'package:looper_player/features/library/presentation/library_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';

class FolderPickerHelper {
  /// Reports what scanning a newly-added folder actually found - shared by
  /// the native picker and the manual-path dialog, since both call
  /// scanLibrary() the same way. The failure case (0 songs) already had a
  /// SnackBar; success silently had none at all, leaving the user to
  /// notice the new songs on their own by scrolling the library.
  static void _showScanResultSnackBar(BuildContext context, int count) {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    if (count == 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.noSupportedSongsFoundFolder),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Added $count song${count == 1 ? '' : 's'}'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green.shade800,
        ),
      );
    }
  }

  static void showManualPathDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController controller = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F1F1F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            l10n.enterFolderPathManually,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.folderPickerManualHint,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '/home/username/Music',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel, style: const TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final path = controller.text.trim();
                Navigator.of(context).pop();
                if (path.isNotEmpty) {
                  final count = await ref.read(libraryProvider.notifier).scanLibrary(path);
                  if (context.mounted) _showScanResultSnackBar(context, count);
                }
              },
              child: Text(l10n.add),
            ),
          ],
        );
      },
    );
  }

  /// Just resolves a folder path from the platform's native picker, without
  /// pickFolder()'s side effect of immediately scanning and adding it to the
  /// library - used by "Excluded folders" management, which wants the same
  /// picker UI but the opposite outcome.
  static Future<String?> pickFolderPathOnly(BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        return await SafFolderService.pickFolder();
      }
      return await FilePicker.getDirectoryPath();
    } catch (e) {
      debugPrint('Error using native directory picker: $e');
      return null;
    }
  }

  static Future<void> pickFolder(BuildContext context, WidgetRef ref) async {
    try {
      String? path;
      if (Platform.isAndroid) {
        try {
          path = await SafFolderService.pickFolder();
        } on PlatformException catch (e) {
          if (e.code == 'UNSUPPORTED_PROVIDER' && context.mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  e.message ??
                      "Please choose a folder on this device's internal storage or SD card.",
                ),
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }
      } else {
        path = await FilePicker.getDirectoryPath();
      }
      if (path != null) {
        final count = await ref.read(libraryProvider.notifier).scanLibrary(path);
        if (context.mounted) _showScanResultSnackBar(context, count);
      } else {
        if (context.mounted) {
          final l10n = AppLocalizations.of(context)!;
          // Clear any current snackbars to avoid queuing them
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF1E1E1E),
              duration: const Duration(seconds: 4), // Explicit auto-hide duration
              content: Text(l10n.folderPickerClosed, style: const TextStyle(color: Colors.white)),
              action: SnackBarAction(
                textColor: Colors.deepPurpleAccent,
                label: l10n.enterManually,
                onPressed: () => showManualPathDialog(context, ref),
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error using native directory picker: $e');
      if (context.mounted) {
        showManualPathDialog(context, ref);
      }
    }
  }
}
