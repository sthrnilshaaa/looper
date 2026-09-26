import 'dart:ui';

import 'package:flutter_svg/flutter_svg.dart';

class AccentColorMapper extends ColorMapper {
  final Color accentColor;
  const AccentColorMapper(this.accentColor);

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    // Only replace colors where green is significantly dominant
    if (color.green > color.red * 1.2 && color.green > color.blue * 1.2) {
      return accentColor.withValues(alpha: color.a);
    }

    return color;
  }
}
