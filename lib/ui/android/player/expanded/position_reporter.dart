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
    if (next > 0.99 && _lastProgress <= 0.99) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reportPosition());
    }
    _lastProgress = next;
  }

  void _reportPosition() {
    if (!mounted) return;
    final double progress = _expandProgress.value;
    final enableSlide = ref.read(settingsProvider).enableSlideGesture;
    // Never report mid-motion. Fully collapsed is fine: the Fluid Player
    // keeps the expanded player mounted (Offstage, still laid out at its
    // final screen-sized layout), so measuring at launch gives the very
    // first expand the real target instead of an approximation.
    if (enableSlide && progress > 0.01 && progress < 0.99) return;

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
