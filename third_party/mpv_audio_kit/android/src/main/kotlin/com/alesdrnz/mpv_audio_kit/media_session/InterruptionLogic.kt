/*
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.alesdrnz.mpv_audio_kit.media_session

import android.media.AudioManager

/**
 * Pure decision logic for OS audio interruptions, mapping an Android audio
 * focus change (or a "becoming noisy" route change) + the consumer's
 * [interruptionPolicy] into a transport reaction. Kept free of any Android
 * instance APIs (it reads only compile-time `AUDIOFOCUS_*` int constants)
 * so it is unit-testable on the plain JVM — see `InterruptionLogicTest`.
 *
 * Mirrors the Apple `AVAudioSession` behaviour in `MediaSessionPlugin.swift`:
 * - `pauseAndResume`: pause on loss; resume only after a *transient* loss
 *   that interrupted playback.
 * - `pauseOnly`: pause on loss; never auto-resume.
 * - `keepPlaying`: never auto-pause on focus loss (the system still auto-ducks).
 * A headphone unplug ("becoming noisy") always pauses, even under
 * `keepPlaying` (Apple HIG: don't blast the speaker), and never arms
 * auto-resume — re-plugging must not restart.
 */
internal object InterruptionLogic {

    const val PLAY = "play"
    const val PAUSE = "pause"
    const val STOP = "stop"

    private const val KEEP_PLAYING = "keepPlaying"
    private const val PAUSE_AND_RESUME = "pauseAndResume"

    /**
     * @param command the transport command to forward to Dart, or `null` for none.
     * @param resumeOnFocusGain the new "re-arm auto-resume" latch value.
     * @param abandonFocus whether to drop the OS focus request (permanent loss).
     */
    data class Reaction(
        val command: String?,
        val resumeOnFocusGain: Boolean,
        val abandonFocus: Boolean,
    )

    /** Reaction to an `OnAudioFocusChangeListener` callback. [resumeArmed]
     *  is the current latch (set when we auto-paused for a transient loss).
     *  [wasPlaying] is the play intent when the focus changed: a paused
     *  player keeps its focus, and the end of a call must not start what
     *  the user had paused (Apple checks `wasPlayingBeforeInterruption`). */
    fun onFocusChange(
        focusChange: Int,
        policy: String,
        resumeArmed: Boolean,
        wasPlaying: Boolean,
    ): Reaction =
        when (focusChange) {
            AudioManager.AUDIOFOCUS_LOSS ->
                if (policy == KEEP_PLAYING) {
                    Reaction(command = null, resumeOnFocusGain = false, abandonFocus = false)
                } else {
                    // Permanent: another media app took over. Pause, drop focus,
                    // do not auto-resume.
                    Reaction(command = PAUSE, resumeOnFocusGain = false, abandonFocus = true)
                }

            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT ->
                if (policy == KEEP_PLAYING) {
                    Reaction(command = null, resumeOnFocusGain = false, abandonFocus = false)
                } else {
                    // Transient (call, alarm). Pause (harmless when already
                    // paused); arm auto-resume only for pauseAndResume and only
                    // if something was playing. A latch already armed stays:
                    // the pause we caused makes the player inactive before a
                    // second transient loss arrives.
                    Reaction(
                        command = PAUSE,
                        resumeOnFocusGain =
                            policy == PAUSE_AND_RESUME && (wasPlaying || resumeArmed),
                        abandonFocus = false,
                    )
                }

            AudioManager.AUDIOFOCUS_GAIN ->
                if (resumeArmed) {
                    Reaction(command = PLAY, resumeOnFocusGain = false, abandonFocus = false)
                } else {
                    Reaction(command = null, resumeOnFocusGain = false, abandonFocus = false)
                }

            // AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK and any unknown code: keep
            // playing (the system auto-ducks when willPauseWhenDucked=false),
            // preserve the existing latch.
            else -> Reaction(command = null, resumeOnFocusGain = resumeArmed, abandonFocus = false)
        }

    /**
     * Reaction to the result of an audio-focus *request* made when playback
     * starts. Without this the engine barges over a non-duckable holder (active call / assistant).
     *
     * - GRANTED: proceed (already playing).
     * - FAILED: pause — another app holds focus we can't duck under.
     * - DELAYED (only when `setAcceptsDelayedFocusGain(true)`): pause now and
     *   arm auto-resume so the eventual `AUDIOFOCUS_GAIN` resumes, for
     *   pauseAndResume only (parity with transient-loss handling).
     *
     * `keepPlaying` never pauses — the policy opts out of focus gating.
     *
     * [duringTransientLoss]: the request was made during a call (see
     * [transientLossAfter]). Anything short of a grant then waits for the
     * gain that ends the call, as a deferred grant does; before API 26 the
     * request fails instead of being deferred.
     */
    fun onFocusRequestResult(
        result: Int,
        policy: String,
        duringTransientLoss: Boolean = false,
    ): Reaction {
        if (policy == KEEP_PLAYING) {
            return Reaction(command = null, resumeOnFocusGain = false, abandonFocus = false)
        }
        val waits = duringTransientLoss && result != AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        return when (if (waits) AudioManager.AUDIOFOCUS_REQUEST_DELAYED else result) {
            AudioManager.AUDIOFOCUS_REQUEST_GRANTED ->
                Reaction(command = null, resumeOnFocusGain = false, abandonFocus = false)

            AudioManager.AUDIOFOCUS_REQUEST_DELAYED ->
                Reaction(
                    command = PAUSE,
                    resumeOnFocusGain = policy == PAUSE_AND_RESUME,
                    abandonFocus = false,
                )

            else ->  // AUDIOFOCUS_REQUEST_FAILED
                Reaction(command = PAUSE, resumeOnFocusGain = false, abandonFocus = false)
        }
    }

    /** Reaction to `ACTION_AUDIO_BECOMING_NOISY` (headphones unplugged / BT
     *  disconnect). Always pauses, even under keepPlaying (Apple HIG: don't
     *  blast the speaker); never arms auto-resume — re-plugging must not restart. */
    fun onBecomingNoisy(): Reaction =
        Reaction(command = PAUSE, resumeOnFocusGain = false, abandonFocus = false)

    /** Reaction to a pause from a controller (the car, a headset, a Media3
     *  controller), which the session forwards to Dart. During a call the
     *  player is already paused, so the latch is the only place the user's
     *  choice can go: the end of the call must not restart it. ExoPlayer
     *  does the same by clearing `playWhenReady`. */
    fun onExternalPause(): Reaction =
        Reaction(command = null, resumeOnFocusGain = false, abandonFocus = false)

    /** Whether a command from a controller is the user's own end of
     *  playback, which disarms the resume of a call (see
     *  [onExternalPause]): a pause or a stop. */
    fun disarmsResume(command: String): Boolean = command == PAUSE || command == STOP

    /** Whether a call (a transient loss that paused the player) is in
     *  progress after [focusChange], from the [current] state. A transient
     *  loss keeps the focus request, so the player still holds the focus
     *  then, but a play must ask again instead of trusting it. */
    fun transientLossAfter(focusChange: Int, policy: String, current: Boolean): Boolean =
        when (focusChange) {
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> policy != KEEP_PLAYING
            AudioManager.AUDIOFOCUS_GAIN, AudioManager.AUDIOFOCUS_LOSS -> false
            else -> current
        }

    /** Whether a play must request the focus: always without it, and
     *  during a call even with it (see [transientLossAfter]). */
    fun needsFocusRequest(hasFocus: Boolean, transientLoss: Boolean): Boolean =
        !hasFocus || transientLoss
}
