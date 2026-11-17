import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/l10n.dart';
import 'package:looper_player/features/playback/data/audio_analyzer.dart';
import 'package:looper_player/features/settings/domain/quality_badge_style.dart';

enum QualityTier {
  /// 1-bit DSD (DSF/DFF).
  dsd,

  /// Lossless beyond CD quality: 24-bit or more, or above 48 kHz.
  hiRes,
  lossless,
  high,
  standard,
}

const _losslessCodecs = [
  'FLAC', 'WAV', 'WAVE', 'ALAC', 'APE', 'AIFF', 'AIF', 'AIFC', 'WV', 'TTA', //
  'TAK', 'DSD', 'DSF', 'DFF',
];
const _lossyCodecs = [
  'MP3', 'M4A', 'MP4', 'AAC', 'OGG', 'OGA', 'OPUS', 'WMA', 'AC3', 'EAC3', //
  'MPC', 'WV-LOSSY',
];

/// What the Now Playing quality badge knows about the current file.
class QualityInfo {
  final QualityTier tier;

  /// Upper-case codec, or null when unknown (shown as "Audio"). For DSD
  /// it's the container (DSF/DFF), since the tier already says DSD.
  final String? codec;
  final int bitsPerSample;
  final int sampleRate;
  final int bitrate;
  final int channels;

  const QualityInfo({
    required this.tier,
    this.codec,
    this.bitsPerSample = 0,
    this.sampleRate = 0,
    this.bitrate = 0,
    this.channels = 0,
  });

  factory QualityInfo.fromAnalysis(AudioAnalysis a) {
    final codec = a.codec.toUpperCase();
    final QualityTier tier;
    if (codec == 'DSD' || codec == 'DSF' || codec == 'DFF') {
      tier = QualityTier.dsd;
    } else if (_losslessCodecs.contains(codec)) {
      tier = a.bitsPerSample >= 24 || a.sampleRate > 48000
          ? QualityTier.hiRes
          : QualityTier.lossless;
    } else if (_lossyCodecs.contains(codec)) {
      // Opus is transparent at a much lower bitrate than MP3/AAC.
      final int highFrom = codec == 'OPUS' ? 128000 : 192000;
      tier = a.bitrate > 0 && a.bitrate < highFrom
          ? QualityTier.standard
          : QualityTier.high;
    } else {
      tier = QualityTier.standard;
    }
    return QualityInfo(
      tier: tier,
      codec: tier == QualityTier.dsd ? a.container.toUpperCase() : codec,
      bitsPerSample: a.bitsPerSample,
      sampleRate: a.sampleRate,
      bitrate: a.bitrate,
      channels: a.channels,
    );
  }

  /// Guess from the file extension while the analysis is still running.
  factory QualityInfo.fromPath(String path) {
    final ext = path.split('.').last.toUpperCase();
    if (ext == 'DSF' || ext == 'DFF') {
      return QualityInfo(tier: QualityTier.dsd, codec: ext);
    }
    if (_losslessCodecs.contains(ext)) {
      return QualityInfo(tier: QualityTier.lossless, codec: ext);
    }
    if (_lossyCodecs.contains(ext)) {
      return QualityInfo(tier: QualityTier.high, codec: ext);
    }
    return const QualityInfo(tier: QualityTier.high);
  }

  /// Used by the style sheet's preview when nothing is playing.
  static const sample = QualityInfo(
    tier: QualityTier.hiRes,
    codec: 'FLAC',
    bitsPerSample: 24,
    sampleRate: 96000,
    channels: 2,
  );

  bool get isLossless =>
      tier == QualityTier.dsd ||
      tier == QualityTier.hiRes ||
      tier == QualityTier.lossless;
}

/// The audio quality badge under the Now Playing top bar, drawn per
/// [QualityBadgeStyle].
class QualityBadge extends StatelessWidget {
  final QualityInfo info;
  final QualityBadgeStyle style;

  /// Space above the badge. The Now Playing top bar passes zero and pads
  /// outside its Hero instead, so the hero's rect is the visible pill.
  final EdgeInsetsGeometry margin;

  const QualityBadge({
    super.key,
    required this.info,
    required this.style,
    this.margin = const EdgeInsets.only(top: 6),
  });

  static const Color _gold = Color(0xFFF5C451);
  static const Color _silver = Color(0xFFB9D7EA);

  /// The "By quality" color for [tier]; null means plain white.
  static Color? tierColor(QualityTier tier, Color primary) => switch (tier) {
    QualityTier.dsd || QualityTier.hiRes => _gold,
    QualityTier.lossless => _silver,
    QualityTier.high => primary,
    QualityTier.standard => null,
  };

  /// The tier's display name ("Hi-Res Lossless", "DSD", ...).
  static String tierLabel(BuildContext context, QualityTier tier) =>
      switch (tier) {
        QualityTier.dsd => 'DSD',
        QualityTier.hiRes => context.l10n.qualityHiRes,
        QualityTier.lossless => context.l10n.qualityLossless,
        QualityTier.high => context.l10n.qualityHigh,
        QualityTier.standard => context.l10n.qualityStandard,
      };

  /// The tier's compact badge name ("HI-RES", "LOSSLESS", "HQ", ...).
  static String tierShortLabel(QualityTier tier) => switch (tier) {
    QualityTier.dsd => 'DSD',
    QualityTier.hiRes => 'HI-RES',
    QualityTier.lossless => 'LOSSLESS',
    QualityTier.high => 'HQ',
    QualityTier.standard => 'SQ',
  };

  /// DSD rates read as multiples of 44.1 kHz (DSD64 = 2.8224 MHz).
  static String sampleRateLabel(QualityInfo info) =>
      info.tier == QualityTier.dsd
      ? 'DSD${(info.sampleRate / 44100).round()}'
      : '${(info.sampleRate / 1000).toStringAsFixed(1)} kHz';

  static String? channelsLabel(BuildContext context, int channels) =>
      switch (channels) {
        <= 0 => null,
        1 => context.l10n.qualityMono,
        2 => context.l10n.qualityStereo,
        6 => '5.1',
        8 => '7.1',
        final n => '$n ch',
      };

  static String textFor(
    BuildContext context,
    QualityInfo info,
    QualityBadgeStyle style, {
    bool shortTier = false,
  }) {
    final String tierName = shortTier
        ? tierShortLabel(info.tier)
        : tierLabel(context, info.tier);
    if (style.layout == QualityBadgeLayout.name) return tierName;
    final l10n = context.l10n;
    final String? channels = channelsLabel(context, info.channels);
    final parts = <String>[
      if (style.shows(QualityBadgeField.tier)) tierName,
      if (style.shows(QualityBadgeField.codec)) info.codec ?? l10n.qualityAudio,
      // DSD is always 1-bit; its rate label already says it.
      if (style.shows(QualityBadgeField.bitDepth) &&
          info.bitsPerSample > 0 &&
          info.tier != QualityTier.dsd)
        '${info.bitsPerSample}-bit',
      if (style.shows(QualityBadgeField.sampleRate) && info.sampleRate > 0)
        sampleRateLabel(info),
      if (style.shows(QualityBadgeField.channels) && channels != null) channels,
      // Bitrate says little about lossless files, so it's left off them.
      if (style.shows(QualityBadgeField.bitrate) &&
          info.bitrate > 0 &&
          !info.isLossless)
        '${(info.bitrate / 1000).round()} kbps',
    ];
    // Every enabled detail can be missing before analysis; fall back to the
    // codec so the badge is never blank.
    if (parts.isEmpty) parts.add(info.codec ?? l10n.qualityAudio);
    return parts.join(style.separatorGlyph).trim();
  }

  String _tierLabel(BuildContext context) => tierLabel(context, info.tier);

  String get _sampleRateLabel => sampleRateLabel(info);

  String? _channelsLabel(BuildContext context) =>
      channelsLabel(context, info.channels);

  String _text(BuildContext context) => textFor(context, info, style);

  /// The badge's leading icon, or null for [QualityBadgeIcon.none].
  static Widget? iconWidget(QualityBadgeIcon icon, double size, Color color) {
    if (icon == QualityBadgeIcon.ribbon) {
      return QualityRibbonIcon(size: size, color: color);
    }
    final IconData? data = _iconData(icon);
    return data == null ? null : Icon(data, size: size, color: color);
  }

  static IconData? _iconData(QualityBadgeIcon icon) => switch (icon) {
    QualityBadgeIcon.none || QualityBadgeIcon.ribbon => null,
    QualityBadgeIcon.audioLines => LucideIcons.audioLines,
    QualityBadgeIcon.waveform => LucideIcons.audioWaveform,
    QualityBadgeIcon.disc => LucideIcons.disc3,
    QualityBadgeIcon.headphones => LucideIcons.headphones,
    QualityBadgeIcon.sparkles => LucideIcons.sparkles,
    QualityBadgeIcon.gem => LucideIcons.gem,
  };

  /// The badge's tint for [style]; null is the original neutral white.
  static Color? tintFor(
    QualityBadgeStyle style,
    QualityInfo info,
    Color primary,
  ) => switch (style.colors) {
    QualityBadgeColors.white => null,
    QualityBadgeColors.theme => primary,
    QualityBadgeColors.byQuality => tierColor(info.tier, primary),
  };

  /// The badge's box. Shared with the details dialog's hero morph, which
  /// starts from exactly this so the pill doesn't jump when it takes off.
  static BoxDecoration decorationFor(QualityBadgeStyle style, Color? tint) {
    final bool bare = style.look == QualityBadgeLook.text;
    final bool big = style.layout == QualityBadgeLayout.name;
    final double radius = switch (style.shape) {
      QualityBadgeShape.pill => 100,
      QualityBadgeShape.rounded => big ? 8 : 6,
      QualityBadgeShape.square => 3,
    };
    return BoxDecoration(
      color: style.look == QualityBadgeLook.pill
          ? (tint ?? Colors.white).withValues(alpha: tint == null ? 0.08 : 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: bare
            ? Colors.transparent
            : (tint ?? Colors.white).withValues(
                alpha: style.look == QualityBadgeLook.outlined
                    ? (tint == null ? 0.3 : 0.6)
                    : (tint == null ? 0.12 : 0.3),
              ),
        width: style.look == QualityBadgeLook.outlined ? 0.8 : 0.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color? tint = tintFor(
      style,
      info,
      Theme.of(context).colorScheme.primary,
    );
    final Color fg = tint ?? Colors.white70;
    final bool bare = style.look == QualityBadgeLook.text;
    final bool big = style.layout == QualityBadgeLayout.name;
    final Widget? icon = iconWidget(
      style.icon,
      big ? 16 : (bare ? 12 : 11),
      fg,
    );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[icon, SizedBox(width: big ? 6 : 4)],
        Flexible(
          child: Text(
            _text(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.jostStyle(
              color: fg,
              fontSize: big ? 13 : (bare ? 11 : 10),
              fontWeight: FontWeight.w600,
              letterSpacing: big ? 0.2 : 0.5,
            ),
          ),
        ),
      ],
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: margin,
      padding: EdgeInsets.symmetric(
        horizontal: bare ? 0 : (big ? 12 : 10),
        vertical: big ? 5 : 3,
      ),
      decoration: decorationFor(style, tint),
      child: content,
    );
  }
}

/// Three flowing, slanted wave strokes: a "lossless ribbon" mark drawn
/// in code so it takes the badge color like the Lucide icons do.
class QualityRibbonIcon extends StatelessWidget {
  final double size;
  final Color color;

  const QualityRibbonIcon({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _RibbonPainter(color));
}

class _RibbonPainter extends CustomPainter {
  final Color color;

  _RibbonPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.06
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    const int steps = 24;
    for (int line = 0; line < 3; line++) {
      final double shift = line * 0.17;
      final path = Path();
      for (int i = 0; i <= steps; i++) {
        final double t = i / steps;
        // One sine period, slanted up to the right.
        final double x = 0.06 + shift + 0.5 * t;
        final double y = 0.84 - 0.68 * t + 0.14 * math.sin(2 * math.pi * t);
        if (i == 0) {
          path.moveTo(x * w, y * h);
        } else {
          path.lineTo(x * w, y * h);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_RibbonPainter old) => old.color != color;
}
