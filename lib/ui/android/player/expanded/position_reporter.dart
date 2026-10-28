import 'package:looper_player/ui/android/shell/music_bar/fluid_player_motion.dart'
    show kFluidHandoff;
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/core/providers/player_expand_provider.dart';

class PositionReporter extends ConsumerStatefulWidget {
  final Widget child;
  final ValueChanged<Rect> onPositionChanged;
  final GlobalKey ancestorKey;

  const PositionReporter({
    required this.child,
    required this.onPositionChanged,
    required this.ancestorKey,
    super.key,
  });

  @override
  ConsumerState<PositionReporter> createState() => _PositionReporterState();
}

class _PositionReporterState extends ConsumerState<PositionReporter> {
  late final ValueNotifier<double> _expandProgress;
  double _lastProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _expandProgress = ref.read(playerExpandProgressProvider);
    _lastProgress = _expandProgress.value;
    _expandProgress.addListener(_onExpandProgress);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportPosition());
  }

  @override
  void dispose() {
    _expandProgress.removeListener(_onExpandProgress);
    super.dispose();
  }

  void _onExpandProgress() {
    final double next = _expandProgress.value;
    if (next >= kFluidHandoff && _lastProgress < kFluidHandoff) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reportPosition());
    }
    // Expand starting: the player has just woken up (its state was paused
    // while collapsed), so its layout can differ from the last measurement.
    // Re-measure two frames in - once the woken state has laid out - so the
    // morphing art lands exactly on the real one instead of snapping to it.
    if (next > 0.01 && _lastProgress <= 0.01) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _reportPosition(force: true),
        );
        WidgetsBinding.instance.scheduleFrame();
      });
    }
    _lastProgress = next;
  }

  void _reportPosition({bool force = false}) {
    if (!mounted) return;
    final double progress = _expandProgress.value;
    final enableSlide = ref.read(settingsProvider).enableSlideGesture;
    // Normally not mid-motion. Fully collapsed is fine: the Fluid Player
    // keeps the expanded player mounted (Offstage, still laid out at its
    // final screen-sized layout), so measuring at launch gives the very
    // first expand the real target instead of an approximation. [force]
    // (expand start) is safe too: the player's layout doesn't change with
    // the progress, only paint transforms on other sections do.
    if (!force && enableSlide && progress > 0.01 && progress < kFluidHandoff) {
      return;
    }

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    final RenderBox? ancestorBox =
        widget.ancestorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && ancestorBox != null) {
      final position = ancestorBox.globalToLocal(
        renderBox.localToGlobal(Offset.zero),
      );
      widget.onPositionChanged(
        Rect.fromLTWH(
          position.dx,
          position.dy,
          renderBox.size.width,
          renderBox.size.height,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
