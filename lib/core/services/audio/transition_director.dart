import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:looper_player/core/utils/logger_helper.dart';
import 'package:looper_player/features/playback/domain/crossmix_models.dart';

/// Manages dual-player audio crossfades and cue-aligned transitions
/// (docs/online/24).
///
/// [activePlayer] is always the song the app shows as "now playing": the
/// roles flip at the swap point, mid-fade, together with the OS media
/// session. The other player is [idlePlayer] (the incoming song before the
/// swap, the fading-out song after it).
class TransitionDirector {
  TransitionDirector({required Player playerA, required Player playerB})
    : _playerA = playerA,
      _playerB = playerB;

  final Player _playerA;
  final Player _playerB;

  bool _isPlayerAActive = true;

  Player get activePlayer => _isPlayerAActive ? _playerA : _playerB;
  Player get idlePlayer => _isPlayerAActive ? _playerB : _playerA;

  double _masterVolume = 1.0;
  bool _isMuted = false;

  // Fade gains, by role in the running transition (not by active/idle).
  double _gainOutgoing = 1.0;
  double _gainIncoming = 0.0;
  Player? _outgoing;
  Player? _incoming;

  // Outgoing-only fade of a user skip (doc 24 §2.1 rule 9).
  double _skipGain = 1.0;
  Timer? _skipTimer;
  Future<void> Function()? _pendingSkip;

  bool _isArmed = false;
  bool get isArmed => _isArmed;

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  /// True once the running transition has passed its swap point.
  bool get hasSwapped => _swappedThisTransition;

  TransitionPlan? _currentPlan;
  TransitionPlan? get currentPlan => _currentPlan;

  int _activeGeneration = 0;
  int get activeGeneration => _activeGeneration;

  Timer? _fadeTimer;
  Stopwatch? _fadeStopwatch;
  bool _swappedThisTransition = false;
  Timer? _rateTimer;
  Future<void>? _sessionMove;
  MediaSession? _movingSession;

  /// Completes once a media-session move started at a swap has landed.
  /// Media-session writes await it so they reach the new owner, after it.
  Future<void> get sessionReady => _sessionMove ?? Future.value();

  // The incoming player's rate before a beat-match speed-up.
  double _baseRate = 1.0;

  VoidCallback? onSwap;
  VoidCallback? onComplete;
  VoidCallback? onCancel;

  DateTime _lastSkipPress = DateTime.fromMillisecondsSinceEpoch(0);

  /// Synchronizes master volume across both players.
  void setMasterVolume(double volume, {bool? isMuted}) {
    _masterVolume = volume.clamp(0.0, 1.0);
    if (isMuted != null) _isMuted = isMuted;
    _applyGains();
  }

  void _applyGains() {
    final master = _isMuted ? 0.0 : _masterVolume * 100.0;
    try {
      if (_isRunning && _outgoing != null && _incoming != null) {
        _outgoing!.setVolume((master * _gainOutgoing).clamp(0.0, 150.0));
        _incoming!.setVolume((master * _gainIncoming).clamp(0.0, 150.0));
      } else {
        activePlayer.setVolume((master * _skipGain).clamp(0.0, 150.0));
        idlePlayer.setVolume(0.0);
      }
    } catch (e) {
      LoggerHelper.write('TransitionDirector: Error setting volume: $e');
    }
  }

  /// Applies DSP changes (EQ, filters) to both players.
  Future<void> applyToBoth(Future<void> Function(Player player) action) async {
    try {
      await Future.wait([action(_playerA), action(_playerB)]);
    } catch (e) {
      LoggerHelper.write('TransitionDirector: applyToBoth failed: $e');
    }
  }

  /// Arms the idle player with the incoming song ahead of the transition.
  Future<bool> arm({
    required TransitionPlan plan,
    required int generation,
    required Future<void> Function(Player player) loadMedia,
  }) async {
    cancelArming();
    _activeGeneration = generation;
    _currentPlan = plan;

    LoggerHelper.write(
      'TransitionDirector: Arming idle player for "${plan.incomingSong.title}" (Gen: $generation)',
    );

    try {
      idlePlayer.setVolume(0.0);
      _gainIncoming = 0.0;
      _baseRate = activePlayer.state.rate;
      await loadMedia(idlePlayer);
      // A cancel or a newer arm while loading wins.
      if (_currentPlan != plan || generation != _activeGeneration) return false;
      // DSP writes skip an empty idle player, so copy the chain over now;
      // the incoming song's own gain is applied at the swap.
      final a = activePlayer.state;
      await idlePlayer.setAudioEffects(a.audioEffects);
      await idlePlayer.setReplayGain(a.replayGain);
      await idlePlayer.setVolumeGain(a.volumeGain);
      await idlePlayer.setPitch(a.pitch);
      await idlePlayer.setRate(_baseRate * plan.speedAdjustment);
      _isArmed = true;
      return true;
    } catch (e) {
      LoggerHelper.write('TransitionDirector: Arming failed: $e');
      cancelArming();
      return false;
    }
  }

  /// Go / no-go (doc 24 §4 stage 1): the incoming file must really be open
  /// (a known length) and not stuck buffering. An idle player that never
  /// loaded has no length, so it fails.
  bool checkGoNoGo() {
    if (!_isArmed) return false;
    final s = idlePlayer.state;
    return s.duration > Duration.zero && !s.buffering;
  }

  /// Starts the running dual-player transition.
  void startTransition({
    required int generation,
    Duration? customDuration,
    VoidCallback? onSwapCallback,
    VoidCallback? onCompleteCallback,
  }) {
    if (_isRunning || !_isArmed) return;
    if (generation != _activeGeneration) return;

    final plan = _currentPlan;
    final duration =
        customDuration ?? plan?.overlapDuration ?? const Duration(seconds: 6);

    _isRunning = true;
    _swappedThisTransition = false;
    _outgoing = activePlayer;
    _incoming = idlePlayer;
    onSwap = onSwapCallback;
    onComplete = onCompleteCallback;

    _incoming!.play();
    if (duration <= Duration.zero) {
      completeHandoverImmediately();
      return;
    }

    final totalUs = duration.inMicroseconds;
    _fadeStopwatch = Stopwatch()..start();
    _fadeTimer?.cancel();
    _fadeTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final elapsedUs = _fadeStopwatch?.elapsedMicroseconds ?? 0;
      final t = (elapsedUs / totalUs).clamp(0.0, 1.0);

      // Equal power: cos²(t·π/2) + sin²(t·π/2) = 1.
      _gainOutgoing = TransitionPlan.calculateOutgoingGain(t);
      _gainIncoming = TransitionPlan.calculateIncomingGain(t);
      _applyGains();

      if (t >= (plan?.swapProgress ?? 0.5) && !_swappedThisTransition) {
        _swappedThisTransition = true;
        _handleSwap();
      }

      if (t >= 1.0) {
        timer.cancel();
        _fadeTimer = null;
        _fadeStopwatch?.stop();
        _finalizeTransition();
      }
    });
  }

  /// Holds the fade clock while the user has paused playback.
  void pauseTransition() {
    if (!_isRunning) return;
    _fadeStopwatch?.stop();
    try {
      idlePlayer.pause();
    } catch (_) {}
  }

  void resumeTransition() {
    if (!_isRunning) return;
    try {
      idlePlayer.play();
    } catch (_) {}
    _fadeStopwatch?.start();
  }

  /// Ends a running transition at once: the incoming song takes over at
  /// full volume (a seek or a skip during the fade). No-op when idle.
  void completeHandoverImmediately() {
    if (!_isRunning) return;
    _fadeTimer?.cancel();
    _fadeTimer = null;
    _fadeStopwatch?.stop();

    if (!_swappedThisTransition) {
      _swappedThisTransition = true;
      _handleSwap();
    }
    _finalizeTransition();
  }

  void _handleSwap() {
    LoggerHelper.write(
      'TransitionDirector: Swap point reached. Handing over active role.',
    );
    final from = _outgoing!, to = _incoming!;
    _isPlayerAActive = identical(to, _playerA);
    _sessionMove = _moveMediaSession(from, to);
    unawaited(_sessionMove);
    onSwap?.call();
  }

  /// Only one Player may own the OS media session: release it on [from],
  /// then claim it on [to] with the same config.
  Future<void> _moveMediaSession(Player from, Player to) async {
    // A move still in flight already released [from]; reuse its config.
    final session = from.state.mediaSession ?? _movingSession;
    if (session == null) return;
    _movingSession = session;
    try {
      await from.setMediaSession(null);
      // Android: disable stops the media service and releases its
      // controller asynchronously; claiming at once lets that teardown kill
      // the new session (seen on device). Give it time to finish.
      if (Platform.isAndroid) {
        await Future<void>.delayed(const Duration(milliseconds: 600));
      }
      // Claim on whichever player is active now (a later swap may have
      // flipped again), unless a newer move took over.
      if (!identical(_movingSession, session)) return;
      if (activePlayer.state.mediaSession == null) {
        await activePlayer.setMediaSession(session);
      }
    } catch (e) {
      LoggerHelper.write('TransitionDirector: media session handover: $e');
    } finally {
      if (identical(_movingSession, session)) _movingSession = null;
    }
  }

  void _finalizeTransition() {
    final out = _outgoing;
    final plan = _currentPlan;
    _isRunning = false;
    _isArmed = false;
    _outgoing = null;
    _incoming = null;
    _gainOutgoing = 1.0;
    _gainIncoming = 0.0;
    _skipGain = 1.0;

    try {
      out?.stop();
    } catch (_) {}
    _applyGains();
    if (plan != null && plan.speedAdjustment != 1.0) {
      _easeRateBack(activePlayer, plan);
    }

    LoggerHelper.write('TransitionDirector: Transition completed.');
    onComplete?.call();
  }

  /// Eases a beat-matched speed-up back in 0.4% steps, one per beat, so
  /// the change can't be heard (doc 24 §2.1 rule 2).
  void _easeRateBack(Player p, TransitionPlan plan) {
    _rateTimer?.cancel();
    final bpm = (plan.incomingBpm ?? 120).clamp(60.0, 200.0);
    final target = _baseRate;
    var rate = target * plan.speedAdjustment;
    _rateTimer = Timer.periodic(Duration(milliseconds: (60000 / bpm).round()), (
      t,
    ) {
      rate = rate > target
          ? (rate - target * 0.004).clamp(target, double.infinity)
          : (rate + target * 0.004).clamp(0.0, target);
      try {
        p.setRate(rate);
      } catch (_) {}
      if ((rate - target).abs() < 1e-6) t.cancel();
    });
  }

  /// Cancels an armed or running transition and resets the idle player.
  void cancelArming() {
    final wasRunning = _isRunning;
    _fadeTimer?.cancel();
    _fadeTimer = null;
    _fadeStopwatch?.stop();
    _isRunning = false;
    _isArmed = false;
    _currentPlan = null;
    _outgoing = null;
    _incoming = null;
    _gainOutgoing = 1.0;
    _gainIncoming = 0.0;

    try {
      idlePlayer.stop();
    } catch (_) {}
    _applyGains();

    if (wasRunning) onCancel?.call();
  }

  /// A user skip: the outgoing song fades out over at most 1.5 s, then
  /// [executeSkip] runs once. A second press, or a press during a running
  /// transition, skips at once.
  void handleUserSkip({required Future<void> Function() executeSkip}) {
    final now = DateTime.now();
    final isDoubleSkip = now.difference(_lastSkipPress).inMilliseconds < 800;
    _lastSkipPress = now;

    if (_isRunning) {
      completeHandoverImmediately();
      unawaited(_runSkipNow(executeSkip));
      return;
    }
    if (isDoubleSkip || _pendingSkip != null) {
      unawaited(_runSkipNow(_pendingSkip ?? executeSkip));
      return;
    }

    _pendingSkip = executeSkip;
    final fader = Stopwatch()..start();
    const skipUs = 1500000;
    _skipTimer = Timer.periodic(const Duration(milliseconds: 16), (t) {
      final progress = (fader.elapsedMicroseconds / skipUs).clamp(0.0, 1.0);
      _skipGain = 1.0 - progress;
      _applyGains();
      if (progress >= 1.0 && _pendingSkip != null) {
        unawaited(_runSkipNow(_pendingSkip!));
      }
    });
  }

  Future<void> _runSkipNow(Future<void> Function() skip) async {
    _skipTimer?.cancel();
    _skipTimer = null;
    _pendingSkip = null;
    try {
      await skip();
    } finally {
      // Restored after the next song is loaded, so the old one can't blip.
      _skipGain = 1.0;
      _applyGains();
    }
  }

  void dispose() {
    _fadeTimer?.cancel();
    _skipTimer?.cancel();
    _rateTimer?.cancel();
    _fadeStopwatch?.stop();
  }
}
