import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../providers/lyrics/lyrics_notifier.dart';
import '../../providers/playback/playback_notifier.dart';
import '../../services/overlay_service.dart';

class OverlayLyricsWidget extends ConsumerStatefulWidget {
  const OverlayLyricsWidget({super.key});

  @override
  ConsumerState<OverlayLyricsWidget> createState() =>
      _OverlayLyricsWidgetState();
}

class _OverlayLyricsWidgetState extends ConsumerState<OverlayLyricsWidget> {
  Size? _initialSize;

  @override
  Widget build(BuildContext context) {
    // Only rebuild when the parsed lines change
    final lines = ref.watch(
      lyricsProvider.select((state) => state.parsedLines),
    );

    return GestureDetector(
      onPanStart: (details) {
        windowManager.startDragging();
      },
      onDoubleTap: () {
        ref.read(overlayServiceProvider).toggleOverlay();
      },
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Stack(
          children: [
            Center(
              child: Consumer(
                builder: (context, ref, child) {
                  // Optimization: only rebuild when the current line index changes
                  final lineIndex = ref.watch(
                    playbackProvider.select((s) {
                      if (lines.isEmpty) return -1;
                      int idx = lines.indexWhere(
                        (line) =>
                            s.position >= line.startTime &&
                            s.position < line.endTime,
                      );
                      if (idx == -1) {
                        if (s.position < lines.first.startTime) {
                          idx = 0;
                        } else if (s.position >= lines.last.endTime) {
                          idx = lines.length - 1;
                        }
                      }
                      return idx;
                    }),
                  );

                  String currentLine = "Looper Player";
                  String nextLine = "";

                  if (lineIndex != -1) {
                    currentLine = lines[lineIndex].text;
                    if (lineIndex + 1 < lines.length) {
                      nextLine = lines[lineIndex + 1].text;
                    }
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentLine,
                        textAlign: TextAlign.center,
                        style: AppFonts.spaceGroteskStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (nextLine.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          nextLine,
                          textAlign: TextAlign.center,
                          style: AppFonts.spaceGroteskStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      LucideIcons.x,
                      color: Colors.white54,
                      size: 20,
                    ),
                    onPressed: () {
                      ref.read(overlayServiceProvider).toggleOverlay();
                    },
                    hoverColor: Colors.white10,
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            // Resize handle on the bottom right
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onPanStart: (details) async {
                  _initialSize = await windowManager.getSize();
                },
                onPanUpdate: (details) async {
                  if (_initialSize != null) {
                    final newWidth =
                        _initialSize!.width + details.localPosition.dx;
                    final newHeight =
                        _initialSize!.height + details.localPosition.dy;

                    // Enforce a minimum size
                    final width = newWidth < 100 ? 100.0 : newWidth;
                    final height = newHeight < 50 ? 50.0 : newHeight;

                    await windowManager.setSize(Size(width, height));
                  }
                },
                onPanEnd: (details) {
                  _initialSize = null;
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeDownRight,
                  child: Container(
                    width: 20,
                    height: 20,
                    color: Colors.transparent,
                    child: const Icon(
                      Icons.keyboard_arrow_right,
                      size: 14,
                      color: Colors.white24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
