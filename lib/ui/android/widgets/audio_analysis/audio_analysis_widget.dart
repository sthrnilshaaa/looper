import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:looper_player/ui/widgets/common/app_loading_indicator.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'audio_analysis_models.dart';
import 'package:looper_player/core/utils/l10n.dart';
part 'audio_analysis_engine.dart';
part 'audio_info_card.dart';
part 'spectrogram_view.dart';

class AudioAnalysisCard extends StatefulWidget {
  final String filePath;

  const AudioAnalysisCard({super.key, required this.filePath});

  @override
  State<AudioAnalysisCard> createState() => _AudioAnalysisCardState();
}

class _AudioAnalysisCardState extends State<AudioAnalysisCard> {
  AudioAnalysisData? _data;
  bool _analyzing = false;
  bool _checkingCache = true;
  String? _error;
  ui.Image? _spectrogramImage;

  static const _supportedExtensions = {
    '.flac',
    '.mp3',
    '.m4a',
    '.mp4',
    '.aac',
    '.ac3',
    '.eac3',
    '.opus',
    '.ogg',
    '.wav',
    '.wma',
    '.mka',
    '.wv',
    '.ape',
    '.tta',
    '.aif',
    '.aiff',
  };

  bool get _isSupported {
    final lower = widget.filePath.toLowerCase();
    return _supportedExtensions.any((ext) => lower.endsWith(ext));
  }

  @override
  void initState() {
    super.initState();
    if (_isSupported) {
      _tryLoadFromCache();
    }
  }

  @override
  void dispose() {
    _spectrogramImage?.dispose();
    super.dispose();
  }

  Future<void> _tryLoadFromCache() async {
    try {
      final cached = await _loadFromCache(widget.filePath);
      if (cached != null && mounted) {
        setState(() {
          _data = cached;
          _checkingCache = false;
        });
        final image = await _loadSpectrogramFromCache(widget.filePath);
        if (image != null && mounted) {
          setState(() {
            _spectrogramImage?.dispose();
            _spectrogramImage = image;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _checkingCache = false);
    }
  }

  Future<void> _analyze({bool forceRefresh = false}) async {
    if (_analyzing) return;
    setState(() {
      _analyzing = true;
      _error = null;
      if (forceRefresh) {
        _spectrogramImage?.dispose();
        _spectrogramImage = null;
        _data = null;
      }
    });

    try {
      if (forceRefresh) {
        await _clearCache(widget.filePath);
      }

      final cached = forceRefresh
          ? null
          : await _loadFromCache(widget.filePath);
      AudioAnalysisData data;
      bool fromCache = false;

      if (cached != null) {
        data = cached;
        fromCache = true;
      } else {
        data = await _runAnalysis(widget.filePath);
        _saveToCache(widget.filePath, data);
      }

      ui.Image? image;
      if (fromCache) {
        image = await _loadSpectrogramFromCache(widget.filePath);
      }
      if (image == null &&
          data.spectrum != null &&
          data.spectrum!.sliceCount > 0) {
        image = await _renderSpectrogramToImage(data.spectrum!);
        _saveSpectrogramToCache(widget.filePath, image);
      }

      if (mounted) {
        setState(() {
          _data = data;
          _spectrogramImage?.dispose();
          _spectrogramImage = image;
          _analyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _analyzing = false;
        });
      }
    }
  }

  static Future<void> _clearCache(String filePath) async {
    try {
      final dir = await _cacheDir();
      final key = _cacheKey(filePath);
      final jsonFile = File('${dir.path}/$key.json');
      final imageFile = File('${dir.path}/$key.png');
      if (await jsonFile.exists()) {
        await jsonFile.delete();
      }
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
    } catch (_) {}
  }

  static String _cacheKey(String filePath) {
    var hash = 0xcbf29ce484222325;
    for (final byte in utf8.encode(filePath)) {
      hash ^= byte;
      hash = (hash * 0x100000001b3) & 0x7FFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16);
  }

  static Future<Directory> _cacheDir() async {
    final appSupport = await getApplicationSupportDirectory();
    final dir = Directory('${appSupport.path}/audio_analysis_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<AudioAnalysisData?> _loadFromCache(String filePath) async {
    try {
      final dir = await _cacheDir();
      final key = _cacheKey(filePath);
      final file = File('${dir.path}/$key.json');
      if (!await file.exists()) return null;

      final json = Map<String, dynamic>.from(
        jsonDecode(await file.readAsString()) as Map,
      );
      if (json['cacheVersion'] != AudioAnalysisData.cacheVersion) {
        return null;
      }
      final cachedSize = json['fileSize'] as int;

      final currentSize = await File(filePath).length();
      if (currentSize != cachedSize) return null;

      return AudioAnalysisData.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _saveToCache(
    String filePath,
    AudioAnalysisData data,
  ) async {
    try {
      final dir = await _cacheDir();
      final key = _cacheKey(filePath);
      final file = File('${dir.path}/$key.json');
      await file.writeAsString(jsonEncode(data.toJson()));
    } catch (_) {}
  }

  static Future<void> _saveSpectrogramToCache(
    String filePath,
    ui.Image image,
  ) async {
    try {
      final dir = await _cacheDir();
      final key = _cacheKey(filePath);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final file = File('${dir.path}/$key.png');
        await file.writeAsBytes(byteData.buffer.asUint8List());
      }
    } catch (_) {}
  }

  static Future<ui.Image?> _loadSpectrogramFromCache(String filePath) async {
    try {
      final dir = await _cacheDir();
      final key = _cacheKey(filePath);
      final file = File('${dir.path}/$key.png');
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, completer.complete);
      return await completer.future;
    } catch (_) {
      return null;
    }
  }

  Future<AudioAnalysisData> _runAnalysis(String filePath) async {
    final info = await _getMediaInfo(filePath);
    return AudioAnalysisData(
      filePath: filePath,
      fileSize: info.fileSize,
      codec: info.codec,
      container: info.container,
      decodedSampleFormat: info.decodedSampleFormat,
      sampleRate: info.sampleRate,
      channels: info.channels,
      channelLayout: info.channelLayout,
      bitsPerSample: info.bitsPerSample,
      duration: info.duration,
      bitrate: info.bitrate,
      bitDepth: info.bitsPerSample > 0 ? '${info.bitsPerSample}-bit' : 'N/A',
      dynamicRange: 0.0,
      peakAmplitude: 0.0,
      rmsLevel: 0.0,
      totalSamples: info.totalSamples,
    );
  }

  Future<_MediaInfo> _getMediaInfo(String filePath) async {
    int fileSize = 0;
    try {
      fileSize = await File(filePath).length();
    } catch (_) {}

    final ext = filePath.split('.').last.toUpperCase();
    return _MediaInfo(
      fileSize: fileSize,
      codec: ext,
      container: ext,
      decodedSampleFormat: 's16',
      sampleRate: 44100,
      channels: 2,
      channelLayout: 'stereo',
      bitsPerSample: 16,
      duration: 180.0,
      bitrate: 320000,
      totalSamples: 180 * 44100,
    );
  }

  Future<ui.Image> _renderSpectrogramToImage(SpectrogramData spectrum) async {
    const imgWidth = 800;
    const imgHeight = 400;

    final pixels = await compute(
      _renderSpectrogramPixels,
      _SpectrogramRenderParams(
        spectrum: spectrum,
        width: imgWidth,
        height: imgHeight,
      ),
    );

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      imgWidth,
      imgHeight,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSupported) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    if (_checkingCache) return const SizedBox.shrink();

    if (_analyzing) {
      final isRescan = _data != null || _spectrogramImage != null;
      return Card(
        color: Colors.white.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLoadingIndicator(size: 48),
                const SizedBox(height: 12),
                Text(
                  isRescan
                      ? context.l10n.reanalyzingAudio
                      : context.l10n.analyzingAudio,
                  style: AppFonts.jostStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Card(
        color: cs.errorContainer.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: cs.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _error!,
                  style: AppFonts.jostStyle(color: cs.error, fontSize: 13),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: context.l10n.rescan,
                visualDensity: VisualDensity.compact,
                color: cs.error,
                onPressed: () => _analyze(forceRefresh: true),
              ),
            ],
          ),
        ),
      );
    }

    if (_data == null) {
      return Card(
        color: Colors.white.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: _analyze,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.analytics_outlined, color: cs.primary, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.audioQualityAnalysis,
                        style: AppFonts.jostStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.audioQualityAnalysisDesc,
                        style: AppFonts.jostStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white54),
              ],
            ),
          ),
        ),
      );
    }

    final data = _data!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AudioInfoCard(
          data: data,
          onRescan: () => _analyze(forceRefresh: true),
        ),
        if (_spectrogramImage != null) ...[
          const SizedBox(height: 12),
          _SpectrogramView(
            image: _spectrogramImage!,
            sampleRate: data.sampleRate,
            maxFreq: data.spectrum?.maxFreq ?? data.sampleRate / 2,
          ),
        ],
      ],
    );
  }
}
