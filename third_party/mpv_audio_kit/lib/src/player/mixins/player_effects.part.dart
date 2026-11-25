// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// What the player logs on [PlayerStream.internalLog] when mpv refuses a
/// live `af-command` update and the chain is rewritten instead. Tests
/// count refusals by it.
@visibleForTesting
const afCommandRefusedLog =
    'A live effects update was refused; rebuilding the chain.';

/// The public setters of the effects chain, the [AudioEffect] list
/// written to mpv's `af`. Its writes, live updates through `af-command`
/// and the chain written again at a load are those of [_EffectsChain].
mixin _EffectsModule on _PlayerBase {
  // ── DSP pipeline ────────────────────────────────────────────────────
  // The DSP pipeline is an ordered list of [AudioEffect] stages, applied
  // atomically with [setAudioEffects] (replace) or [updateAudioEffects]
  // (mapper). Each stage owns an `enabled` flag: disabling one drops it
  // from the chain while keeping it, and its settings, in the list.

  /// Replaces the effects chain in one atomic write: [effects] run in
  /// list order, and the same filter may appear more than once.
  ///
  /// Use for a whole chain (initial setup, presets). To change one stage,
  /// typical of UI sliders, prefer [updateAudioEffects].
  ///
  /// Throws [MpvCommandException], with the state back on the last list
  /// mpv accepted, when mpv rejects the chain: a syntax error, an unknown
  /// filter, or an option value the filter refuses when it is created. A
  /// filter that fails later, while it configures on its first frame, is
  /// disabled by mpv instead, with a message on [PlayerStream.log]. With
  /// no file loaded there is no graph to build yet, so a refused value
  /// surfaces at the next load instead, on [PlayerStream.error].
  ///
  /// Throws [ArgumentError], before anything reaches mpv and with the
  /// state unchanged, when a stage holds a value its filter would take and
  /// then read or write out of its buffers with, or turn the audio to NaN
  /// with:
  /// - chorus lists with different numbers of voices, a negative or NaN
  ///   delay or depth, or a speed that is not above 0 and at most 100 Hz;
  /// - aecho delays that are not above 0 and at most 90000 ms, or decays
  ///   that are not above 0 and at most 1;
  /// - an anequalizer band value that is NaN or infinite;
  /// - a pan input channel named UNK, UNSD or AMBI, which pan has no slot
  ///   for;
  /// - an mcompand band with an empty attack or decay among an even number
  ///   of them, or a NaN crossover frequency;
  /// - compand attacks and decays that both start with no number.
  ///
  /// It throws the same way for a `params` key that is no option name,
  /// such as one with a `:` or a `,`, which would add options or filters
  /// to the chain.
  ///
  /// A [RawAudioEffect] is not checked here. The filters themselves refuse
  /// such values, so a raw stage that carries one fails as described above
  /// for a value a filter refuses, instead of reading or writing out of its
  /// buffers.
  ///
  /// A [RawAudioEffect] carries a lavfi entry written by hand, for
  /// expression-based filters or anything without a typed effect. The
  /// chain is the only writer of mpv's `af` property: raw writes via
  /// `setRawProperty('af', ...)` are rejected. An `af` value already
  /// there, such as the chain a resume point saved by 0.5.1 or earlier
  /// brings back with its file, is replaced by the first call here, and
  /// after that call at every load.
  ///
  /// ```dart
  /// await player.setAudioEffects([
  ///   EqualizerEffect(frequency: 100, width: 50, gain: 3),
  ///   EqualizerEffect(frequency: 8000, width: 1000, gain: -2),
  ///   AcompressorEffect(ratio: 4),
  ///   AlimiterEffect(limit: 0.9),
  /// ]);
  /// ```
  Future<void> setAudioEffects(List<AudioEffect> effects) async {
    await _gate();
    await _effects.apply(effects);
  }

  /// Changes the effects chain through [mapper], which receives the
  /// current list and returns the new one.
  ///
  /// Throws [MpvCommandException] like [setAudioEffects] when mpv refuses
  /// the result, and [ArgumentError] like it for a stage that is not safe
  /// to run, so a call that is not awaited, typical of a slider, ends in
  /// an unhandled error then.
  ///
  /// ```dart
  /// // A slider on the second stage (an EqualizerEffect):
  /// await player.updateAudioEffects((fx) => [
  ///   for (final (i, e) in fx.indexed)
  ///     i == 1 ? (e as EqualizerEffect).copyWith(gain: gain) : e,
  /// ]);
  ///
  /// // Bypass every compressor without losing its settings:
  /// await player.updateAudioEffects((fx) => [
  ///   for (final e in fx)
  ///     e is AcompressorEffect ? e.copyWith(enabled: false) : e,
  /// ]);
  /// ```
  Future<void> updateAudioEffects(
    List<AudioEffect> Function(List<AudioEffect>) mapper,
  ) async {
    _checkNotDisposed();
    // Run the mapper only AFTER the ready gate, and commit in the same
    // microtask: two un-awaited calls in one synchronous turn would
    // otherwise both run their mapper on the same pre-commit list, and
    // the second commit would silently drop the first mutation. The
    // single suspension point serializes each read-modify-write in call
    // order on the microtask queue.
    await _gate();
    await _effects.apply(mapper(_state.settings.audioEffects));
  }
}
