part of 'audio_analysis_widget.dart';

class _AudioInfoCard extends StatelessWidget {
  final AudioAnalysisData data;
  final VoidCallback? onRescan;

  const _AudioInfoCard({required this.data, this.onRescan});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final nyquist = data.sampleRate / 2;

    return Card(
      color: Colors.white.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.audioStreamDetails,
                    style: AppFonts.jostStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (onRescan != null)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: l10n.rescan,
                    visualDensity: VisualDensity.compact,
                    color: Colors.white70,
                    onPressed: onRescan,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (data.codec.isNotEmpty)
                  _MetricChip(
                    icon: Icons.memory,
                    label: l10n.codec,
                    value: data.codec,
                    cs: cs,
                  ),
                if (data.container.isNotEmpty)
                  _MetricChip(
                    icon: Icons.inventory_2_outlined,
                    label: l10n.container,
                    value: data.container,
                    cs: cs,
                  ),
                _MetricChip(
                  icon: Icons.graphic_eq,
                  label: l10n.sampleRate,
                  value: '${(data.sampleRate / 1000).toStringAsFixed(1)} kHz',
                  cs: cs,
                ),
                _MetricChip(
                  icon: Icons.audio_file,
                  label: l10n.bitDepth,
                  value: data.bitDepth,
                  cs: cs,
                ),
                if (data.decodedSampleFormat.isNotEmpty)
                  _MetricChip(
                    icon: Icons.data_object,
                    label: l10n.decodedFormat,
                    value: data.decodedSampleFormat,
                    cs: cs,
                  ),
                if (data.bitrate > 0)
                  _MetricChip(
                    icon: Icons.speed,
                    label: l10n.bitrate,
                    value: _formatBitrate(data.bitrate),
                    cs: cs,
                  ),
                _MetricChip(
                  icon: Icons.surround_sound,
                  label: l10n.channels,
                  value: _formatChannels(l10n, data),
                  cs: cs,
                ),
                _MetricChip(
                  icon: Icons.timer_outlined,
                  label: l10n.duration,
                  value: _formatDuration(data.duration),
                  cs: cs,
                ),
                _MetricChip(
                  icon: Icons.multiline_chart,
                  label: l10n.nyquist,
                  value: '${(nyquist / 1000).toStringAsFixed(1)} kHz',
                  cs: cs,
                ),
                if (data.fileSize > 0)
                  _MetricChip(
                    icon: Icons.storage,
                    label: l10n.fileSize,
                    value: _formatFileSize(data.fileSize),
                    cs: cs,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.white.withValues(alpha: 0.08)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _MetricChip(
                  icon: Icons.trending_up,
                  label: l10n.dynamicRange,
                  value: '${data.dynamicRange.toStringAsFixed(2)} dB',
                  cs: cs,
                ),
                _MetricChip(
                  icon: Icons.show_chart,
                  label: l10n.peak,
                  value: '${data.peakAmplitude.toStringAsFixed(2)} dB',
                  cs: cs,
                ),
                _MetricChip(
                  icon: Icons.equalizer,
                  label: "RMS",
                  value: '${data.rmsLevel.toStringAsFixed(2)} dB',
                  cs: cs,
                ),
                if (data.integratedLufs != null)
                  _MetricChip(
                    icon: Icons.volume_up_outlined,
                    label: "LUFS",
                    value: '${data.integratedLufs!.toStringAsFixed(1)} LUFS',
                    cs: cs,
                  ),
                if (data.truePeakDb != null)
                  _MetricChip(
                    icon: Icons.warning_amber_outlined,
                    label: l10n.truePeak,
                    value: '${data.truePeakDb!.toStringAsFixed(2)} dBTP',
                    cs: cs,
                  ),
                _MetricChip(
                  icon: Icons.report_gmailerrorred_outlined,
                  label: l10n.clipping,
                  value: _formatClipping(l10n, data.clippingSamples),
                  cs: cs,
                ),
                if (data.spectralCutoffHz != null)
                  _MetricChip(
                    icon: Icons.filter_alt_outlined,
                    label: l10n.cutoff,
                    value: _formatFrequency(data.spectralCutoffHz!),
                    cs: cs,
                  ),
                _MetricChip(
                  icon: Icons.numbers,
                  label: l10n.samples,
                  value: _formatNumber(data.totalSamples),
                  cs: cs,
                ),
              ],
            ),
            if (data.channelStats.length > 1) ...[
              const SizedBox(height: 8),
              Divider(color: Colors.white.withValues(alpha: 0.08)),
              const SizedBox(height: 8),
              Text(
                l10n.perChannelMetrics,
                style: AppFonts.jostStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: data.channelStats.map((stats) {
                  return _MetricChip(
                    icon: Icons.surround_sound,
                    label: l10n.channelShort(stats.channel),
                    value: _formatChannelStats(stats),
                    cs: cs,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(double seconds) {
    final mins = seconds ~/ 60;
    final secs = (seconds % 60).floor();
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  String _formatChannels(AppLocalizations l10n, AudioAnalysisData data) {
    final layout = data.channelLayout.trim();
    if (layout.isNotEmpty && layout != 'unknown') {
      return data.channels > 0 ? '${data.channels} ($layout)' : layout;
    }
    if (data.channels == 2) return l10n.stereo;
    if (data.channels == 1) return l10n.mono;
    return data.channels > 0 ? '${data.channels}' : l10n.notAvailable;
  }

  String _formatFileSize(int bytes) {
    if (bytes == 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    final i = (math.log(bytes) / math.log(1024)).floor();
    final size = bytes / math.pow(1024, i);
    return '${size.toStringAsFixed(1)} ${units[i]}';
  }

  String _formatFrequency(double hz) {
    if (hz >= 1000) return '${(hz / 1000).toStringAsFixed(1)} kHz';
    return '${hz.round()} Hz';
  }

  String _formatBitrate(int bitsPerSecond) {
    if (bitsPerSecond >= 1000000) {
      return '${(bitsPerSecond / 1000000).toStringAsFixed(2)} Mbps';
    }
    return '${(bitsPerSecond / 1000).round()} kbps';
  }

  String _formatClipping(AppLocalizations l10n, int samples) {
    if (samples <= 0) return l10n.noneClean;
    return _formatNumber(samples);
  }

  String _formatChannelStats(ChannelAnalysisStats stats) {
    final parts = <String>[];
    if (stats.peakDb != null) {
      parts.add('P ${stats.peakDb!.toStringAsFixed(1)}');
    }
    if (stats.rmsDb != null) {
      parts.add('R ${stats.rmsDb!.toStringAsFixed(1)}');
    }
    if (stats.dynamicRangeDb != null) {
      parts.add('DR ${stats.dynamicRangeDb!.toStringAsFixed(1)}');
    }
    if (stats.peakCount > 0 && (stats.peakDb ?? -100) >= -0.1) {
      parts.add('Clip ${_formatNumber(stats.peakCount)}');
    }
    return parts.isEmpty ? 'N/A' : parts.join(' / ');
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white54),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: AppFonts.jostStyle(color: Colors.white54, fontSize: 12),
          ),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.jostStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
