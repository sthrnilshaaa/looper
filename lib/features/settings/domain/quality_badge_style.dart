import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/settings/domain/app_defaults.dart';

/// How the Now Playing quality badge is drawn. The stored index is the enum
/// index, so only append.
enum QualityBadgeLook {
  /// Filled pill with a hairline border (the original look).
  pill,

  /// Border only, no fill.
  outlined,

  /// Bare text, no container.
  text,
}

/// Optional leading icon. Only append.
enum QualityBadgeIcon {
  none,
  audioLines,
  waveform,
  disc,
  headphones,
  sparkles,
  gem,

  /// Custom-drawn flowing ribbon (see QualityRibbonIcon).
  ribbon,
}

/// Where the badge's text/icon/border color comes from. Only append.
enum QualityBadgeColors {
  white,
  theme,

  /// Hi-Res/DSD gold, lossless silver, high quality in the theme color,
  /// standard white.
  byQuality,
}

/// Corner shape of the badge. Only append.
enum QualityBadgeShape { pill, rounded, square }

/// What the badge says. Only append.
enum QualityBadgeLayout {
  /// Quality level, codec, bit depth, ... per [QualityBadgeStyle.fields].
  details,

  /// Just the quality level ("Lossless"), bigger, next to the icon.
  name,
}

/// Glyph between the badge's details. Only append.
enum QualityBadgeSeparator { dot, middot, bar, slash }

/// The details the badge can show, as bits of [QualityBadgeStyle.fields].
enum QualityBadgeField { tier, codec, bitDepth, sampleRate, bitrate, channels }

class QualityBadgeStyle {
  final QualityBadgeLook look;
  final QualityBadgeIcon icon;
  final QualityBadgeColors colors;
  final QualityBadgeSeparator separator;
  final QualityBadgeShape shape;
  final QualityBadgeLayout layout;

  /// Bitmask of [QualityBadgeField] indices.
  final int fields;

  static final int allFields = (1 << QualityBadgeField.values.length) - 1;

  /// The original badge's details (everything before channels was added),
  /// so an untouched badge reads the same as it always has.
  static const int defaultFields = AppDefaults.qualityBadgeFields;

  const QualityBadgeStyle({
    this.look = QualityBadgeLook.pill,
    this.icon = QualityBadgeIcon.headphones,
    this.colors = QualityBadgeColors.white,
    this.separator = QualityBadgeSeparator.bar,
    this.shape = QualityBadgeShape.rounded,
    this.layout = QualityBadgeLayout.details,
    required this.fields,
  });

  factory QualityBadgeStyle.fromSettings(AppSettings s) => QualityBadgeStyle(
    look: _at(QualityBadgeLook.values, s.qualityBadgeLook),
    icon: _at(
      QualityBadgeIcon.values,
      s.qualityBadgeIcon,
      QualityBadgeIcon.headphones,
    ),
    colors: _at(QualityBadgeColors.values, s.qualityBadgeColors),
    separator: _at(
      QualityBadgeSeparator.values,
      s.qualityBadgeSeparator,
      QualityBadgeSeparator.bar,
    ),
    shape: _at(
      QualityBadgeShape.values,
      s.qualityBadgeShape,
      QualityBadgeShape.rounded,
    ),
    layout: _at(QualityBadgeLayout.values, s.qualityBadgeLayout),
    // An empty mask would leave an empty badge; treat it as unset.
    fields: (s.qualityBadgeFields ?? 0) & allFields == 0
        ? defaultFields
        : s.qualityBadgeFields! & allFields,
  );

  static T _at<T>(List<T> values, int? i, [T? fallback]) =>
      i != null && i >= 0 && i < values.length
      ? values[i]
      : fallback ?? values.first;

  bool shows(QualityBadgeField field) => fields & (1 << field.index) != 0;

  String get separatorGlyph => switch (separator) {
    QualityBadgeSeparator.dot => ' • ',
    QualityBadgeSeparator.middot => ' · ',
    QualityBadgeSeparator.bar => ' | ',
    QualityBadgeSeparator.slash => ' / ',
  };

  @override
  bool operator ==(Object other) =>
      other is QualityBadgeStyle &&
      other.look == look &&
      other.icon == icon &&
      other.colors == colors &&
      other.separator == separator &&
      other.shape == shape &&
      other.layout == layout &&
      other.fields == fields;

  @override
  int get hashCode =>
      Object.hash(look, icon, colors, separator, shape, layout, fields);
}
