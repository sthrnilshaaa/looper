import 'dart:async';
import 'package:flutter/material.dart';

/// Pull-to-refresh wrapper used across the library screens. [onRefresh] is
/// typically a full library rescan, which can run long enough (walking
/// folders, reading tags, refreshing several DB collections) that awaiting
/// it directly keeps the pull gesture pinned in its "refreshing" state for
/// the whole duration - any stutter that work causes lands squarely on the
/// release animation the user's finger is on, which is exactly where it's
/// most noticeable and reads as the UI "hanging".
///
/// Instead we let [onRefresh] run in the background and release the pull
/// gesture almost immediately. The screens that depend on the refreshed
/// data already react to it through Isar watch streams/state updates once
/// the scan actually completes, so nothing is lost - the affordance just
/// stops fighting the long task for frames.
class AppRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const AppRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: const Color(0xFF1E1E1E),
      onRefresh: () {
        unawaited(onRefresh().catchError((_) {}));
        return Future.delayed(const Duration(milliseconds: 350));
      },
      child: child,
    );
  }
}
