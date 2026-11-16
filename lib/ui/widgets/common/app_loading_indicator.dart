import 'package:flutter/material.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:looper_player/ui/widgets/common/looper_loader.dart';

/// Page / inline loader. Keeps the old footprint ([size], default 120 or
/// 200 on desktop) so layouts don't shift, and draws the [LooperLoader]
/// inside it - full size when small (inline), a calm ~40-72dp mark when
/// used as a page loader.
class AppLoadingIndicator extends StatelessWidget {
  /// Null uses the page-loader default: 120, or 200 in a desktop window.
  final double? size;
  const AppLoadingIndicator({super.key, this.size});

  @override
  Widget build(BuildContext context) {
    final size = this.size ?? (UiUtils.isDesktop ? 200.0 : 120.0);
    final double mark = size <= 56 ? size : (size * 0.38).clamp(40.0, 72.0);
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Center(child: LooperLoader(size: mark)),
      ),
    );
  }
}
