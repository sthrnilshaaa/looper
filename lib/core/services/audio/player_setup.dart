part of 'audio_service.dart';

extension _AudioServiceSetup on AudioService {
  // Listen to media session command streams
  void _attachMediaSessionListeners() {
    player.stream.mediaSessionCommands.listen(
      (cmd) {
        try {
          LoggerHelper.write(
            'AudioService: MediaSession command received: $cmd',
          );
          if (cmd is MediaSessionCommandPlay) {
            onPlay?.call();
          } else if (cmd is MediaSessionCommandPause) {
            onPause?.call();
          } else if (cmd is MediaSessionCommandPlayPause) {
            onPlayPause?.call();
          } else if (cmd is MediaSessionCommandNext) {
            onNext?.call();
          } else if (cmd is MediaSessionCommandPrevious) {
            onPrevious?.call();
          } else if (cmd is MediaSessionCommandStop) {
            onStop?.call();
          } else if (cmd is MediaSessionCommandSeekTo) {
            onSeekApplied?.call(cmd.position);
          } else if (cmd is MediaSessionCommandSeekBy) {
            onSeekApplied?.call(player.state.position + cmd.offset);
          } else if (cmd is MediaSessionCommandSetShuffle) {
            onShuffleCommand?.call(cmd.shuffle);
          } else if (cmd is MediaSessionCommandSetRepeatMode) {
            onRepeatCommand?.call(cmd.loop);
          } else if (cmd is MediaSessionCommandLike) {
            onFavoriteToggle?.call();
          }
        } catch (e, stack) {
          LoggerHelper.write(
            'AudioService: Error executing MediaSession command $cmd',
            e,
            stack,
          );
        }
      },
      onError: (err) {
        LoggerHelper.write(
          'AudioService: MediaSession command stream error',
          err,
        );
      },
      cancelOnError: false,
    );
  }
}
