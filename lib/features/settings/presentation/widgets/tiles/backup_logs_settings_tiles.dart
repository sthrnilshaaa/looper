import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/services/storage/import_export_service.dart';
import 'package:looper_player/core/utils/logger_helper.dart';
import 'package:looper_player/l10n/app_localizations.dart';

class ExportBackupTile extends ConsumerWidget {
  const ExportBackupTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(LucideIcons.upload, color: Colors.white70),
      title: Text(l10n.exportBackupJson, style: _tileTitleStyle()),
      subtitle: Text(l10n.exportBackupJsonDesc, style: _tileSubtitleStyle()),
      trailing: const Icon(
        LucideIcons.chevronRight,
        color: Colors.white30,
        size: 18,
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        ImportExportService.exportLibraryData(context);
      },
    );
  }
}

class ImportBackupTile extends ConsumerWidget {
  const ImportBackupTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(LucideIcons.download, color: Colors.white70),
      title: Text(l10n.importBackupJson, style: _tileTitleStyle()),
      subtitle: Text(l10n.importBackupJsonDesc, style: _tileSubtitleStyle()),
      trailing: const Icon(
        LucideIcons.chevronRight,
        color: Colors.white30,
        size: 18,
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        ImportExportService.importLibraryData(context, ref);
      },
    );
  }
}

class ExportLogsTile extends ConsumerWidget {
  const ExportLogsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(LucideIcons.fileText, color: Colors.white70),
      title: Text(l10n.exportDiagnosticsLogs, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.exportDiagnosticsLogsDesc,
        style: _tileSubtitleStyle(),
      ),
      trailing: const Icon(
        LucideIcons.chevronRight,
        color: Colors.white30,
        size: 18,
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        LoggerHelper.exportLogs();
      },
    );
  }
}

class ClearLogsTile extends ConsumerWidget {
  const ClearLogsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(LucideIcons.trash2, color: Colors.redAccent),
      title: Text(
        l10n.clearDiagnosticsLogs,
        style: AppFonts.jostStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        l10n.clearDiagnosticsLogsDesc,
        style: _tileSubtitleStyle(),
      ),
      trailing: const Icon(
        LucideIcons.alertTriangle,
        color: Colors.redAccent,
        size: 16,
      ),
      onTap: () async {
        HapticFeedback.mediumImpact();
        await LoggerHelper.clearLogs();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.logsClearedSuccess),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }
}

TextStyle _tileTitleStyle() =>
    AppFonts.jostStyle(color: Colors.white, fontWeight: FontWeight.w500);

TextStyle _tileSubtitleStyle() =>
    AppFonts.jostStyle(color: Colors.white54, fontSize: 12);
