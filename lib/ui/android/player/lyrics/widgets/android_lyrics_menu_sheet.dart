import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/playback/presentation/providers/lyrics/lyrics_notifier.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/sheets/app_bottom_sheet.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'lyrics_gestures_tutorial_sheet.dart';

void showLyricsMenuBottomSheet(BuildContext context, WidgetRef ref, Song song) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.black12,
    builder: (context) {
      return _LyricsMenuSheetContent(song: song);
    },
  );
}

class _LyricsMenuSheetContent extends ConsumerWidget {
  final Song song;

  const _LyricsMenuSheetContent({required this.song});

  String _formatSourceLabel(AppLocalizations l10n, String? source) {
    if (source == null || source.isEmpty) return l10n.noLyricsSource;
    final name = switch (source.toLowerCase()) {
      'embedded' => l10n.lyricsSourceEmbedded,
      'local' => l10n.lyricsSourceLocalSidecar,
      'custom_file' => l10n.lyricsSourceCustomFile,
      'lrclib' => 'LRCLIB',
      'genius' => 'Genius',
      'musixmatch' => 'Musixmatch',
      'azlyrics' => 'AZLyrics',
      'lyricsmint' => 'LyricsMINT',
      'lyricfind' => 'LyricFind',
      'not_found' => l10n.lyricsSourceNotFoundOnline,
      _ => source.toUpperCase(),
    };
    return l10n.lyricsSourceLabel(name);
  }

  String _formatDuration(int durationMs) {
    final duration = Duration(milliseconds: durationMs);
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final lyricsState = ref.watch(lyricsProvider);
    final currentAccent = settings.accentColor;

    final availableProviders = [
      'Local',
      'LRCLIB',
      'Genius',
      'Musixmatch',
      'AZLyrics',
      'LyricsMINT',
      'LyricFind',
    ];

    return AppBottomSheetContainer(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section: Song Info & Artwork
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: OptimizedImage(
                    imagePath: song.artPath,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.jostStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${song.artist ?? "Unknown Artist"} • ${_formatDuration(song.duration ?? 0)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.jostStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    LucideIcons.x,
                    color: Colors.white54,
                    size: 20,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Lyrics Source Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(currentAccent).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Color(currentAccent).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.disc, size: 13, color: Color(currentAccent)),
                  const SizedBox(width: 6),
                  Text(
                    _formatSourceLabel(l10n, lyricsState.source),
                    style: AppFonts.jostStyle(
                      color: Color(currentAccent),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section Divider
            Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),

            const SizedBox(height: 16),

            // Option 1: Change Lyrics Provider for this song
            Text(
              l10n.changeLyricsProvider,
              style: AppFonts.jostStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: availableProviders.map((provider) {
                  final isLocalSource =
                      lyricsState.source == 'embedded' ||
                      lyricsState.source == 'local';
                  final isSelected =
                      (provider.toLowerCase() == 'local' && isLocalSource) ||
                      (lyricsState.source?.toLowerCase() ==
                          provider.toLowerCase());
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        provider == 'Local'
                            ? l10n.lyricsProviderLocal
                            : provider,
                        style: AppFonts.jostStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: Color(currentAccent),
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected
                              ? Color(currentAccent)
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      onSelected: (selected) async {
                        if (selected) {
                          HapticFeedback.mediumImpact();
                          // Captured BEFORE popping: context belongs to this
                          // bottom sheet, which Navigator.pop starts tearing
                          // down immediately below. Calling
                          // ScaffoldMessenger.of(context) with that same
                          // context afterwards is unreliable (it's the
                          // "loading" snackbar showing nothing sometimes),
                          // and the later `if (context.mounted)` guard was
                          // always false after a real pop - it's the sheet's
                          // own context, permanently unmounted the instant
                          // it closes - so the result snackbar (the one that
                          // actually says what happened) could never fire.
                          // The messenger itself belongs to the screen
                          // behind the sheet, not the sheet, so it stays
                          // valid regardless.
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(context);
                          final loadingMsg = provider == 'Local'
                              ? l10n.checkingLocalLyrics
                              : l10n.fetchingLyricsFrom(provider);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(loadingMsg),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          final success = await ref
                              .read(lyricsProvider.notifier)
                              .fetchWithProvider(song, provider);
                          final resultMsg = provider == 'Local'
                              ? (success
                                    ? l10n.loadedLocalLyrics
                                    : l10n.noLocalLyricsFound)
                              : (success
                                    ? l10n.lyricsUpdatedFrom(provider)
                                    : l10n.noLyricsFoundOn(provider));
                          messenger.showSnackBar(
                            SnackBar(content: Text(resultMsg)),
                          );
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 18),
            Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
            const SizedBox(height: 12),

            // Option 2: Auto Lyrics Provider Fallback Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: Color(currentAccent),
              title: Text(
                l10n.autoFallbackProviders,
                style: AppFonts.jostStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                l10n.autoFallbackProvidersDesc,
                style: AppFonts.jostStyle(color: Colors.white54, fontSize: 12),
              ),
              value: settings.autoLyricsFallback,
              onChanged: (val) {
                HapticFeedback.lightImpact();
                ref
                    .read(settingsProvider.notifier)
                    .updateAutoLyricsFallback(val);
              },
            ),

            Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),

            // Option 2b: Ambient Color Background Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: Color(currentAccent),
              title: Text(
                l10n.ambientColorBackground,
                style: AppFonts.jostStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                l10n.ambientColorBackgroundDesc,
                style: AppFonts.jostStyle(color: Colors.white54, fontSize: 12),
              ),
              value: settings.ambientColorBackground,
              onChanged: (val) {
                HapticFeedback.lightImpact();
                ref
                    .read(settingsProvider.notifier)
                    .updateAmbientColorBackground(val);
              },
            ),

            Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),

            // Option 2c: Replay the lyrics-screen gestures tutorial
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.sparkles,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
              title: Text(
                l10n.gestureTips,
                style: AppFonts.jostStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                l10n.gestureTipsDesc,
                style: AppFonts.jostStyle(color: Colors.white54, fontSize: 12),
              ),
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
                showLyricsGesturesTutorial(context, ref);
              },
            ),

            Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
            const SizedBox(height: 8),

            // Option 3: Export Lyrics into LRC File
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.download,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
              title: Text(
                l10n.exportLyricsLrc,
                style: AppFonts.jostStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                l10n.saveLyricsToDevice,
                style: AppFonts.jostStyle(color: Colors.white54, fontSize: 12),
              ),
              onTap: () async {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);

                final rawLrc = lyricsState.rawLrc;
                if (rawLrc == null || rawLrc.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.noLyricsToExport)),
                  );
                  return;
                }

                try {
                  final safeArtist = (song.artist ?? 'Artist').replaceAll(
                    RegExp(r'[^a-zA-Z0-9_\-]'),
                    '_',
                  );
                  final safeTitle = song.title.replaceAll(
                    RegExp(r'[^a-zA-Z0-9_\-]'),
                    '_',
                  );
                  final defaultFileName = '$safeArtist - $safeTitle.lrc';

                  // Write to Downloads directory or custom path
                  String? exportPath;
                  if (Platform.isAndroid) {
                    final downloadsDir = Directory(
                      '/storage/emulated/0/Download',
                    );
                    if (await downloadsDir.exists()) {
                      exportPath = '${downloadsDir.path}/$defaultFileName';
                      final file = File(exportPath);
                      await file.writeAsString(rawLrc);
                    }
                  }

                  exportPath ??= (await FilePicker.saveFile(
                    dialogTitle: l10n.exportLyrics,
                    fileName: defaultFileName,
                    bytes: Uint8List.fromList(rawLrc.codeUnits),
                  ))?.path;

                  if (context.mounted && exportPath != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.lyricsExportedTo(exportPath)),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.failedToExportLyrics('$e'))),
                    );
                  }
                }
              },
            ),

            // Option 4: Use Custom Lyrics (LRC File)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.filePlus,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
              title: Text(
                l10n.useCustomLyricsLrc,
                style: AppFonts.jostStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                l10n.selectLocalLrcFile,
                style: AppFonts.jostStyle(color: Colors.white54, fontSize: 12),
              ),
              onTap: () async {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);

                final result = await FilePicker.pickFile(
                  type: FileType.custom,
                  allowedExtensions: ['lrc', 'txt'],
                );

                if (result != null && result.path != null) {
                  final file = File(result.path!);
                  final content = await file.readAsString();

                  if (content.trim().isNotEmpty) {
                    await ref
                        .read(lyricsProvider.notifier)
                        .applyCustomLyrics(song, content);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.customLyricsAppliedSuccess),
                        ),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
