import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/core/providers/providers.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';

class KeyboardHandler extends ConsumerStatefulWidget {
  final Widget child;
  const KeyboardHandler({super.key, required this.child});

  @override
  ConsumerState<KeyboardHandler> createState() => _KeyboardHandlerState();
}

class _KeyboardHandlerState extends ConsumerState<KeyboardHandler> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _isEditing() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null) return false;

    // Direct check against our search focus node
    if (focus == ref.read(searchFocusNodeProvider)) return true;

    // Robust check for whether the current focus is within an editable text field
    final label = focus.debugLabel?.toLowerCase() ?? '';
    return label.contains('editabletext') ||
        label.contains('textfield') ||
        label.contains('searchfocusnode') ||
        focus.context?.widget is EditableText;
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    // If we're typing, ignore all playback shortcuts so they can reach the text field
    if (_isEditing()) {
      // Exception: Escape key should still work to unfocus
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (FocusManager.instance.primaryFocus ==
            ref.read(searchFocusNodeProvider)) {
          FocusManager.instance.primaryFocus?.unfocus();
          return true;
        }
      }
      return false; // Let it bubble to TextField
    }

    final playback = ref.read(playbackProvider.notifier);
    final nav = ref.read(appNavigationProvider.notifier);
    final key = event.logicalKey;

    // Global Playback Shortcuts
    if (key == LogicalKeyboardKey.space) {
      playback.togglePlay();
      return true;
    }
    if (key == LogicalKeyboardKey.mediaPlayPause) {
      playback.togglePlay();
      return true;
    }
    if (key == LogicalKeyboardKey.mediaTrackNext) {
      playback.skipNext();
      return true;
    }
    if (key == LogicalKeyboardKey.mediaTrackPrevious) {
      playback.skipPrevious();
      return true;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      playback.seekRelative(5);
      return true;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      playback.seekRelative(-5);
      return true;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      playback.adjustVolume(0.05);
      return true;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      playback.adjustVolume(-0.05);
      return true;
    }

    // Functional Shortcuts
    if (key == LogicalKeyboardKey.slash) {
      ref.read(searchFocusNodeProvider).requestFocus();
      return true;
    }
    if (key == LogicalKeyboardKey.keyF &&
        HardwareKeyboard.instance.isControlPressed) {
      ref.read(searchFocusNodeProvider).requestFocus();
      return true;
    }
    if (key == LogicalKeyboardKey.keyM) {
      playback.toggleMute();
      return true;
    }
    if (key == LogicalKeyboardKey.keyS) {
      playback.toggleShuffle();
      return true;
    }
    if (key == LogicalKeyboardKey.keyR) {
      playback.nextRepeatMode();
      return true;
    }
    if (key == LogicalKeyboardKey.keyL) {
      nav.toggleItem(NavItem.lyrics);
      return true;
    }
    if (key == LogicalKeyboardKey.keyQ) {
      nav.toggleItem(NavItem.queue);
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
