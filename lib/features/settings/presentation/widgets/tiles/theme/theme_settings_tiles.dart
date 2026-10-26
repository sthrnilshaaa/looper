import 'package:looper_player/core/motion/looper_scroll_physics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/playback/presentation/widgets/lyrics/advanced_lyric_line/advanced_lyric_line.dart'
    show activeLyricsColor;
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import '../../settings_widgets.dart';
import '../../settings_dialogs.dart';
import '../../avatar_picker_sheet.dart';
import '../../artwork_visualizer_sheet.dart';
import '../../progress_bar_style_sheet.dart';
import '../../quality_badge_sheet.dart';
import 'package:looper_player/features/settings/domain/artwork_visualizer_style.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
export 'darkness_sliders.dart';
export 'package:looper_player/features/playback/presentation/widgets/lyrics/advanced_lyric_line/advanced_lyric_line.dart'
    show activeLyricsIsWhite;
part 'appearance_tiles.dart';
part 'lyrics_appearance_tiles.dart';
part 'player_appearance_tiles.dart';
part 'font_tiles.dart';

TextStyle _tileTitleStyle() =>
    AppFonts.jostStyle(color: Colors.white, fontWeight: FontWeight.w500);

TextStyle _tileSubtitleStyle() =>
    AppFonts.jostStyle(color: Colors.white54, fontSize: 12);
