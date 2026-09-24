import 'dart:io';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/ui/widgets/app_loading_indicator.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/playback/data/audio_analyzer.dart';
import 'package:looper_player/features/playback/data/lyrics_fetcher.dart';
import 'package:looper_player/features/settings/presentation/settings_notifier.dart';
import 'package:looper_player/core/app_fonts.dart';
import 'package:looper_player/core/responsive.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/ui/widgets/optimized_image.dart';
import 'package:intl/intl.dart';
import 'package:looper_player/ui/screens/android/widgets/audio_analysis_widget.dart';
import 'package:looper_player/ui/screens/android/widgets/premium_section.dart';

class SongInfoScreen extends ConsumerStatefulWidget {
  final Song song;

  const SongInfoScreen({super.key, required this.song});

  @override
  ConsumerState<SongInfoScreen> createState() => _SongInfoScreenState();
}

class _SongInfoScreenState extends ConsumerState<SongInfoScreen> {
  late Future<AudioAnalysis?> _analysisFuture;
  late Future<String?> _lyricsFuture;
  bool _lyricsExpanded = false;

  @override
  void initState() {
    super.initState();
    _analysisFuture = AudioAnalyzer.analyze(widget.song.path);
    _lyricsFuture = LyricsFetcher.fetchLyrics(widget.song);
  }

  String _cleanLyrics(String rawLrc) {
    final lines = rawLrc.split('\n');
    final cleanedLines = <String>[];
    final metadataPattern = RegExp(r'^\[[a-zA-Z]+:.*\]$');
    final timestampPattern = RegExp(r'^\[\d{2}:\d{2}\.\d{2,3}\]');
    
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      // Skip source marker tags we add
      if (line.startsWith('[source:')) continue;
      if (metadataPattern.hasMatch(line)) continue;
      
      final match = timestampPattern.firstMatch(line);
      if (match != null) {
        line = line.substring(match.end).trim();
      }
      
      line = line.replaceAll(RegExp(r'<\d{2}:\d{2}\.\d{2,3}>'), '');
      
      cleanedLines.add(line);
    }
    return cleanedLines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final l10n = AppLocalizations.of(context)!;
    final isLandscape = Responsive.isLandscape(MediaQuery.sizeOf(context));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Blurred Background
          if (settings.enableDynamicTheming && widget.song.artPath != null)
            Positioned.fill(
              child: RepaintBoundary(
                child: Stack(
                  children: [
                    ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Image.file(
                        File(widget.song.artPath!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        cacheWidth: 100,
                        cacheHeight: 100,
                        gaplessPlayback: true,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                    Container(
                      color: Colors.black.withValues(alpha: 0.85),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(color: theme.colorScheme.surface),

          SafeArea(
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(context),

                Expanded(
                  // In landscape, cap the reading width and center it instead
                  // of stretching every info row edge-to-edge across the
                  // whole window.
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isLandscape ? 700 : double.infinity,
                      ),
                      child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroSection(primaryColor),
                        const SizedBox(height: 32),

                        // FutureBuilder for FFprobe Metadata
                        FutureBuilder<AudioAnalysis?>(
                          future: _analysisFuture,
                          builder: (context, snapshot) {
                            final analysis = snapshot.data;
                            final isLoading = snapshot.connectionState == ConnectionState.waiting;

                            // Dynamic Format
                            final format = widget.song.path.split('.').last.toUpperCase();

                            return Column(
                              children: [
                                // Complete Metadata details card
                                _buildInfoSection(
                                  title: l10n.metadataDetails,
                                  icon: LucideIcons.tags,
                                  isLoading: isLoading,
                                  items: [
                                    _InfoItem('Track Title', widget.song.title),
                                    _InfoItem('Artist', widget.song.artist ?? 'Unknown Artist'),
                                    _InfoItem('Album', widget.song.album ?? 'Unknown Album'),
                                    if (analysis?.composer != null && analysis!.composer!.isNotEmpty)
                                      _InfoItem('Composer', analysis.composer!),
                                    _InfoItem('Genre', widget.song.genre ?? 'Unknown Genre'),
                                    if (widget.song.year != null && widget.song.year! > 0)
                                      _InfoItem('Release Year', widget.song.year.toString()),
                                    _InfoItem('ISRC', (analysis?.isrc == null || analysis!.isrc!.isEmpty) ? 'N/A' : analysis.isrc!),
                                    _InfoItem('Label', (analysis?.label == null || analysis!.label!.isEmpty) ? 'N/A' : analysis.label!),
                                    _InfoItem('Copyright', (analysis?.copyright == null || analysis!.copyright!.isEmpty) ? 'N/A' : analysis.copyright!, isLong: true),
                                    _InfoItem('Encoder', (analysis?.encoder == null || analysis!.encoder!.isEmpty) ? 'N/A' : analysis.encoder!),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // File info card
                                _buildInfoSection(
                                  title: l10n.fileInformation,
                                  icon: LucideIcons.fileText,
                                  isLoading: false,
                                  items: [
                                    _InfoItem('File Name', widget.song.path.split(Platform.pathSeparator).last),
                                    _InfoItem('File Format', format),
                                    _InfoItem('File Size', _formatFileSize(widget.song.path)),
                                    _InfoItem('Date Added', DateFormat('MMM dd, yyyy, hh:mm a').format(widget.song.dateAdded)),
                                    _InfoItem('Absolute Path', widget.song.path, isLong: true),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Lyrics card
                        _buildLyricsSection(),
                        const SizedBox(height: 24),

                        // Live audio quality analysis card
                        Text(
                          l10n.acousticSpectralAnalysis,
                          style: AppFonts.jostStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AudioAnalysisCard(filePath: widget.song.path),
                      ],
                    ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          PremiumSection(
            useExpanded: false,
             borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          bottomLeft: Radius.circular(32),
                          topRight: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
            width: 44,
            height: 44,
            onTap: () => Navigator.pop(context),
            child: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            l10n.songDetails,
            style: AppFonts.jostStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildHeroSection(Color primaryColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: OptimizedImage(
              imagePath: widget.song.artPath,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.song.title,
                style: AppFonts.jostStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                widget.song.artist ?? 'Unknown Artist',
                style: AppFonts.jostStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.song.album ?? 'Unknown Album',
                style: AppFonts.jostStyle(
                  color: primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLyricsSection() {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<String?>(
      future: _lyricsFuture,
      builder: (context, snapshot) {
        final rawLyrics = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        if (isLoading) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: Colors.white.withValues(alpha: 0.04),
              child: const AppLoadingIndicator(),
            ),
          );
        }

        if (rawLyrics == null || rawLyrics.trim().isEmpty) {
          return const SizedBox.shrink();
        }

        final cleanedLyrics = _cleanLyrics(rawLyrics);
        final lines = cleanedLyrics.split('\n');
        final hasManyLines = lines.length > 5;
        final displayedLines = _lyricsExpanded || !hasManyLines
            ? lines
            : lines.take(5).toList();

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.04),
                  Colors.white.withValues(alpha: 0.01),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.fileKey, color: Colors.white.withValues(alpha: 0.5), size: 20),
                      const SizedBox(width: 12),
                      Text(
                        l10n.lyrics,
                        style: AppFonts.jostStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    displayedLines.join('\n'),
                    style: AppFonts.plusJakartaSansStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  if (hasManyLines) ...[
                    const SizedBox(height: 16),
                    Divider(color: Colors.white.withValues(alpha: 0.08)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _lyricsExpanded = !_lyricsExpanded;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _lyricsExpanded ? l10n.showLess : l10n.showMore,
                              style: AppFonts.jostStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _lyricsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: Theme.of(context).colorScheme.primary,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<_InfoItem> items,
    bool isLoading = false,
  }) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.04),
                Colors.white.withValues(alpha: 0.01),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 20),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: AppFonts.jostStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isLoading) ...[
                      const SizedBox(width: 12),
                      const AppLoadingIndicator(size: 24),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label.toUpperCase(),
                            style: AppFonts.jostStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.value,
                            style: AppFonts.jostStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            maxLines: item.isLong ? 5 : 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }

  String _formatFileSize(String path) {
    try {
      final file = File(path);
      final bytes = file.lengthSync();
      if (bytes <= 0) return "0 B";
      const suffixes = ["B", "KB", "MB", "GB", "TB"];
      var i = (math.log(bytes) / math.log(1024)).floor();
      return '${(bytes / math.pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
    } catch (_) {
      return "N/A";
    }
  }
}

class _InfoItem {
  final String label;
  final String value;
  final bool isLong;

  _InfoItem(this.label, this.value, {this.isLong = false});
}
