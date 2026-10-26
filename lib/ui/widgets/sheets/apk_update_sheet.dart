import 'package:looper_player/core/motion/looper_scroll_physics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/services/update/apk_update_notifier.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/l10n.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/sheets/app_bottom_sheet.dart';

/// The github build's in-app update sheet. It only mirrors
/// [apkUpdateProvider], so closing it mid-download loses nothing: the
/// download carries on and reopening the sheet shows where it is.
void showApkUpdateSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    isScrollControlled: true,
    builder: (context) => const ApkUpdateSheet(),
  );
}

/// `12.3 MB`
String formatUpdateSize(int bytes) =>
    '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

class ApkUpdateSheet extends ConsumerWidget {
  const ApkUpdateSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final update = ref.watch(apkUpdateProvider);
    final accentColor = Color(
      ref.watch(settingsProvider.select((s) => s.accentColor)),
    );
    final release = update.release;
    final asset = update.asset;

    return AppBottomSheetContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(LucideIcons.download, color: accentColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.updateAvailable,
                      style: AppFonts.jostStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (release != null && asset != null)
                      Text(
                        '${l10n.versionLabel(release.tag).trim()} · '
                        '${formatUpdateSize(asset.size)}',
                        style: AppFonts.jostStyle(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (release != null && release.notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              l10n.updateWhatsNew.toUpperCase(),
              style: AppFonts.jostStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: accentColor.withValues(alpha: 0.8),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.3,
              ),
              child: SingleChildScrollView(
                physics: const LooperScrollPhysics(),
                child: Text(
                  release.notes,
                  style: AppFonts.jostStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          _UpdateStatus(update: update, accentColor: accentColor),
          const SizedBox(height: 16),
          _UpdateActions(update: update, accentColor: accentColor),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Progress or error text for the current phase; empty while there is
/// nothing to report.
class _UpdateStatus extends StatelessWidget {
  final ApkUpdateState update;
  final Color accentColor;

  const _UpdateStatus({required this.update, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    switch (update.phase) {
      case ApkUpdatePhase.idle || ApkUpdatePhase.available:
        return const SizedBox.shrink();
      case ApkUpdatePhase.ready:
        return _label(l10n.updateReadyToInstall, Colors.white70);
      case ApkUpdatePhase.downloading:
        final progress = update.progress;
        final amount =
            '${formatUpdateSize(update.received)} / '
            '${formatUpdateSize(update.total)}';
        return _progress(
          value: progress,
          left: l10n.updateDownloading,
          right: progress == null
              ? amount
              : '$amount · ${(progress * 100).round()}%',
        );
      case ApkUpdatePhase.verifying:
        return _progress(value: null, left: l10n.updateVerifying);
      case ApkUpdatePhase.installing:
        return _progress(value: null, left: l10n.updateWaitingForInstaller);
      case ApkUpdatePhase.failed:
        final detail = update.errorDetail;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label(_errorText(l10n, update.error), Colors.redAccent),
            if (detail != null && detail.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                detail,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.jostStyle(fontSize: 11, color: Colors.white38),
              ),
            ],
          ],
        );
    }
  }

  static String _errorText(AppLocalizations l10n, ApkUpdateError? error) =>
      switch (error) {
        ApkUpdateError.checksum => l10n.updateErrorChecksum,
        ApkUpdateError.storage => l10n.updateErrorStorage,
        ApkUpdateError.install => l10n.updateErrorInstall,
        ApkUpdateError.network || null => l10n.updateErrorNetwork,
      };

  Widget _label(String text, Color color) =>
      Text(text, style: AppFonts.jostStyle(fontSize: 13, color: color));

  Widget _progress({
    required double? value,
    required String left,
    String? right,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation(accentColor),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _label(left, Colors.white70)),
            if (right != null)
              Text(
                right,
                style: AppFonts.jostStyle(
                  fontSize: 12,
                  color: Colors.white54,
                ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
          ],
        ),
      ],
    );
  }
}

class _UpdateActions extends ConsumerWidget {
  final ApkUpdateState update;
  final Color accentColor;

  const _UpdateActions({required this.update, required this.accentColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notifier = ref.read(apkUpdateProvider.notifier);

    Widget later() => _secondary(l10n.updateLater, () {
      AppHaptics.light();
      notifier.dismiss();
      Navigator.pop(context);
    });

    final List<Widget> buttons = switch (update.phase) {
      ApkUpdatePhase.idle => [
        _secondary(l10n.close, () => Navigator.pop(context)),
      ],
      ApkUpdatePhase.available => [
        later(),
        _primary(l10n.updateNow, () {
          AppHaptics.medium();
          notifier.download();
        }),
      ],
      ApkUpdatePhase.downloading => [
        _secondary(l10n.cancel, () {
          AppHaptics.light();
          notifier.cancel();
        }),
      ],
      ApkUpdatePhase.verifying ||
      ApkUpdatePhase.installing => [_primary(l10n.updateInstall, null)],
      ApkUpdatePhase.ready => [
        later(),
        _primary(l10n.updateInstall, () {
          AppHaptics.medium();
          notifier.install();
        }),
      ],
      ApkUpdatePhase.failed => [
        later(),
        _primary(l10n.retry, () {
          AppHaptics.medium();
          notifier.retry();
        }),
      ],
    };

    return Row(
      children: [
        for (final (i, button) in buttons.indexed) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: button),
        ],
      ],
    );
  }

  static const _padding = EdgeInsets.symmetric(horizontal: 20, vertical: 14);
  static final _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );

  Widget _primary(String label, VoidCallback? onPressed) => ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: accentColor,
      foregroundColor: Colors.black,
      disabledBackgroundColor: Colors.white10,
      disabledForegroundColor: Colors.white38,
      shape: _shape,
      padding: _padding,
    ),
    child: Text(label, style: AppFonts.jostStyle(fontWeight: FontWeight.bold)),
  );

  Widget _secondary(String label, VoidCallback onPressed) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      backgroundColor: Colors.white10,
      foregroundColor: Colors.white,
      shape: _shape,
      padding: _padding,
    ),
    child: Text(label, style: AppFonts.jostStyle(fontWeight: FontWeight.w600)),
  );
}
