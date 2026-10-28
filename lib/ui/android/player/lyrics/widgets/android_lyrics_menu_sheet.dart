import 'package:looper_player/core/motion/app_routes.dart';
import 'dart:io';

import 'package:looper_player/core/utils/song_metadata.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/playback/data/lyrics_fetcher.dart';
import 'package:looper_player/features/playback/data/lyrics_providers/lyrics_provider_info.dart';
import 'package:looper_player/features/playback/presentation/providers/lyrics/lyrics_notifier.dart';
import 'package:looper_player/features/playback/presentation/widgets/lyrics/desktop_lyrics_toolbar.dart';
import 'package:looper_player/features/playback/presentation/widgets/lyrics/lyrics_scale.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/sheets/app_bottom_sheet.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'lyrics_gestures_tutorial_sheet.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/services/haptics/haptic_snack_bar.dart';

part 'lyrics_menu_widgets.dart';

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

/// The same menu for mouse-and-window platforms: a centred dialog instead
/// of a bottom sheet, without the touch-only entries.
void showLyricsMenuDialog(BuildContext context, WidgetRef ref, Song song) {
  showTaskDialog<void>(
    context: context,
    useRootNavigator: true,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: _LyricsMenuSheetContent(song: song, desktop: true),
        ),
      ),
    ),
  );
}

class _LyricsMenuSheetContent extends ConsumerWidget {
  final Song song;

  /// Shown in a dialog on desktop: no drag handle, no touch-gesture tips.
  final bool desktop;

  const _LyricsMenuSheetContent({required this.song, this.desktop = false});

  String _formatSourceLabel(AppLocalizations l10n, String? source) {
    if (source == null || source.isEmpty) return l10n.noLyricsSource;
    final name = switch (source.toLowerCase()) {
      'embedded' => l10n.lyricsSourceEmbedded,
      'local' => l10n.lyricsSourceLocalSidecar,
      'custom_file' => l10n.lyricsSourceCustomFile,
      'lrc.red' => 'lrc.red',
      'lyricsplus' => 'LyricsPlus',
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
    final showAlbum = watchShowAlbum(ref);
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final lyricsState = ref.watch(lyricsProvider);
    final currentAccent = settings.accentColor;
    final isWordSynced = lyricsState.parsedLines.any((l) => l.hasWordTiming);
    final isSynced = lyricsState.isSynced;
    final syncStyle = switch (settings.lyricsSyncStyle) {
      'line' || 'word' => settings.lyricsSyncStyle,
      _ => 'char',
    };

    // The services in the user's order; one that is switched off for
    // automatic lookups can still be picked here for this song.
    final availableProviders = [
      'Local',
      for (final id in LyricsFetcher.providerOrder(settings))
        LyricsProviderInfo.of(id)?.label ?? id,
    ];

    final accent = Color(currentAccent);
    final hasLyrics = lyricsState.parsedLines.isNotEmpty;
    final lyricsScale = LyricsScale.normalize(settings.lyricsFontScale);

    return AppBottomSheetContainer(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      showDragHandle: !desktop,
      // The sheet shell lays its child out with unbounded height, so the
      // scroll view needs an explicit cap to actually scroll.
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: artwork, song info, close
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: OptimizedImage(
                      imagePath: song.artPath,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                          '${artistAlbumLabel(song, l10n, showAlbum: showAlbum)} • ${_formatDuration(song.duration ?? 0)}',
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

              const SizedBox(height: 8),

              // Lyrics source badge + whether the lyrics carry word timing
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.disc, size: 13, color: accent),
                        const SizedBox(width: 6),
                        Text(
                          _formatSourceLabel(l10n, lyricsState.source),
                          style: AppFonts.jostStyle(
                            color: accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasLyrics)
                    _SyncBadge(
                      wordSynced: isWordSynced,
                      synced: isSynced,
                      accent: accent,
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Section 1: how the lyrics are synced - highlight style (or a
              // way to get word timing) and the timing offset.
              _MenuSection(
                children: [
                  if (isWordSynced)
                    // Only offered when the lyrics have word timing -
                    // otherwise it's line by line.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel(l10n.lyricsHighlightStyle),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final (value, label) in [
                                ('line', l10n.lyricsStyleLine),
                                ('word', l10n.lyricsStyleWord),
                                ('char', l10n.lyricsStyleCharacter),
                              ])
                                _MenuChip(
                                  label: label,
                                  selected: syncStyle == value,
                                  accent: accent,
                                  onSelected: () {
                                    AppHaptics.selection();
                                    ref
                                        .read(settingsProvider.notifier)
                                        .updateLyricsSyncStyle(value);
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else if (hasLyrics && !isSynced)
                    // No timestamps at all: any synced lyrics would do.
                    _MenuActionTile(
                      icon: LucideIcons.searchCheck,
                      iconColor: accent,
                      title: l10n.findSyncedLyrics,
                      onTap: () async {
                        AppHaptics.medium();
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(context);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(l10n.searchingSyncedLyrics),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        final found = await ref
                            .read(lyricsProvider.notifier)
                            .findSynced(song);
                        messenger.showHapticSnackBar(
                          found ? AppHaptics.success : AppHaptics.error,
                          SnackBar(
                            content: Text(
                              found
                                  ? l10n.syncedLyricsLoaded
                                  : l10n.noSyncedLyricsFound,
                            ),
                          ),
                        );
                      },
                    )
                  else
                    _MenuActionTile(
                      icon: LucideIcons.sparkles,
                      iconColor: accent,
                      title: l10n.findWordSyncedLyrics,
                      onTap: () async {
                        AppHaptics.medium();
                        // See the provider chips below for why the messenger
                        // is captured before popping.
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(context);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(l10n.searchingWordSyncedLyrics),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        final found = await ref
                            .read(lyricsProvider.notifier)
                            .findWordSynced(song);
                        messenger.showHapticSnackBar(
                          found ? AppHaptics.success : AppHaptics.error,
                          SnackBar(
                            content: Text(
                              found
                                  ? l10n.wordSyncedLyricsLoaded
                                  : l10n.noWordSyncedLyricsFound,
                            ),
                          ),
                        );
                      },
                    ),
                  // Nothing to shift without timestamps.
                  if (hasLyrics && isSynced)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 8, 2),
                      child: _LyricsOffsetControl(
                        offsetMs: lyricsState.songId == song.id
                            ? lyricsState.songOffsetMs
                            : lyricsShiftMs(song.lyricsOffsetMs),
                        accent: accent,
                        onChanged: (ms) => ref
                            .read(lyricsProvider.notifier)
                            .updateSongOffsetMs(song, ms),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Section 2: where the lyrics come from - provider for this
              // song, and whether to fall back through the others.
              _MenuSection(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _SectionLabel(l10n.changeLyricsProvider),
                        ),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: availableProviders.map((provider) {
                              final isLocalSource =
                                  lyricsState.source == 'embedded' ||
                                  lyricsState.source == 'local';
                              final isSelected =
                                  (provider.toLowerCase() == 'local' &&
                                      isLocalSource) ||
                                  (lyricsState.source?.toLowerCase() ==
                                      provider.toLowerCase());
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _MenuChip(
                                  label: provider == 'Local'
                                      ? l10n.lyricsProviderLocal
                                      : provider,
                                  selected: isSelected,
                                  accent: accent,
                                  onSelected: () async {
                                    if (isSelected) return;
                                    AppHaptics.medium();
                                    // Captured BEFORE popping: context belongs
                                    // to this bottom sheet, which Navigator.pop
                                    // starts tearing down immediately below.
                                    // Calling ScaffoldMessenger.of(context)
                                    // with that same context afterwards is
                                    // unreliable (it's the "loading" snackbar
                                    // showing nothing sometimes), and a later
                                    // `if (context.mounted)` guard is always
                                    // false after a real pop - it's the sheet's
                                    // own context, permanently unmounted the
                                    // instant it closes - so the result
                                    // snackbar could never fire. The messenger
                                    // itself belongs to the screen behind the
                                    // sheet, so it stays valid regardless.
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    Navigator.pop(context);
                                    // "Fetching..." only when it's really
                                    // a download: the song's own files and
                                    // saved provider copies load instantly.
                                    if (provider != 'Local' &&
                                        !await LyricsFetcher.hasAnswer(
                                          song,
                                          provider,
                                        )) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            l10n.fetchingLyricsFrom(provider),
                                          ),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                    // With auto-fallback the lyrics may
                                    // come from a later source than the
                                    // one picked - name the real one.
                                    final source = await ref
                                        .read(lyricsProvider.notifier)
                                        .fetchWithProvider(song, provider);
                                    final String resultMsg;
                                    if (source == null) {
                                      resultMsg = provider == 'Local'
                                          ? l10n.noLocalLyricsFound
                                          : l10n.noLyricsFoundOn(provider);
                                    } else if (source == 'embedded' ||
                                        source == 'local') {
                                      resultMsg = l10n.loadedLocalLyrics;
                                    } else {
                                      resultMsg = l10n.lyricsUpdatedFrom(
                                        availableProviders.firstWhere(
                                          (p) => p.toLowerCase() == source,
                                          orElse: () => source,
                                        ),
                                      );
                                    }
                                    messenger.showHapticSnackBar(
                                      source == null
                                          ? AppHaptics.error
                                          : AppHaptics.success,
                                      SnackBar(content: Text(resultMsg)),
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _MenuSwitchTile(
                    icon: LucideIcons.layers,
                    title: l10n.autoFallbackProviders,
                    subtitle: l10n.autoFallbackProvidersDesc,
                    value: settings.autoLyricsFallback,
                    accent: accent,
                    onChanged: (val) => ref
                        .read(settingsProvider.notifier)
                        .updateAutoLyricsFallback(val),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Section 3: look & feel of the lyrics screen
              _MenuSection(
                children: [
                  // Only the Android lyrics screen has an ambient background.
                  if (!desktop)
                    _MenuSwitchTile(
                      icon: LucideIcons.palette,
                      title: l10n.ambientColorBackground,
                      subtitle: l10n.ambientColorBackgroundDesc,
                      value: settings.ambientColorBackground,
                      accent: accent,
                      onChanged: (val) => ref
                          .read(settingsProvider.notifier)
                          .updateAmbientColorBackground(val),
                    ),
                  if (desktop)
                    ListTile(
                      contentPadding: const EdgeInsets.only(
                        left: 16,
                        right: 10,
                      ),
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      leading: const _MenuIcon(LucideIcons.type),
                      title: Text(
                        l10n.lyricsSize,
                        style: AppFonts.jostStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      trailing: LyricsSizeControl(
                        scale: lyricsScale,
                        onSmaller: () => ref
                            .read(settingsProvider.notifier)
                            .updateLyricsFontScale(
                              LyricsScale.stepBy(lyricsScale, -1),
                            ),
                        onLarger: () => ref
                            .read(settingsProvider.notifier)
                            .updateLyricsFontScale(
                              LyricsScale.stepBy(lyricsScale, 1),
                            ),
                        onReset: () => ref
                            .read(settingsProvider.notifier)
                            .updateLyricsFontScale(1.0),
                      ),
                    ),
                  if (!desktop)
                    _MenuActionTile(
                      icon: LucideIcons.hand,
                      title: l10n.gestureTips,
                      subtitle: l10n.gestureTipsDesc,
                      onTap: () {
                        AppHaptics.medium();
                        Navigator.pop(context);
                        showLyricsGesturesTutorial(context, ref);
                      },
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Section 4: LRC files in and out
              _MenuSection(
                children: [
                  _MenuActionTile(
                    icon: LucideIcons.download,
                    title: l10n.exportLyricsLrc,
                    subtitle: l10n.saveLyricsToDevice,
                    onTap: () async {
                      AppHaptics.medium();
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
                            exportPath =
                                '${downloadsDir.path}/$defaultFileName';
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
                          ScaffoldMessenger.of(context).showHapticSnackBar(
                            AppHaptics.success,
                            SnackBar(
                              content: Text(l10n.lyricsExportedTo(exportPath)),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showHapticSnackBar(
                            AppHaptics.error,
                            SnackBar(
                              content: Text(l10n.failedToExportLyrics('$e')),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  _MenuActionTile(
                    icon: LucideIcons.filePlus,
                    title: l10n.useCustomLyricsLrc,
                    subtitle: l10n.selectLocalLrcFile,
                    onTap: () async {
                      AppHaptics.medium();
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
            ],
          ),
        ),
      ),
    );
  }
}
