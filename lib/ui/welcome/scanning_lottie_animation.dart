part of 'welcome_screen.dart';

class _ScanningLottieAnimation extends StatelessWidget {
  const _ScanningLottieAnimation();

  @override
  Widget build(BuildContext context) {
    // Sized to the screen and shown on a tilted 3D stage.
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: FirstScanStage(maxWidth: 380),
    );
  }
}
