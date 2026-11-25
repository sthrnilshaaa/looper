/*
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.alesdrnz.mpv_audio_kit.media_session

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.Handler

/**
 * Owns Android audio-focus and the "becoming noisy" route change for the
 * media session, translating both into transport commands forwarded to
 * Dart (which drives libmpv). This is the Android counterpart to the iOS
 * `AVAudioSession` interruption handling — libmpv's `audiotrack` output
 * does NOT request focus itself, so the plugin is the sole focus owner.
 *
 * The pure policy mapping lives in [InterruptionLogic], and the Android
 * calls in [FocusPort] ([AndroidFocusPort] in the app): this class keeps
 * the state between them and applies the reactions, so a JVM test drives
 * it with a fake port. Focus callbacks are delivered on the main looper
 * and the receiver's `onReceive` runs on the main thread, so [emit]
 * (which itself hops to the platform thread) is always called on main.
 */
internal class AudioFocusController(
    private val port: FocusPort,
    private val policy: () -> String,
    private val emit: (Map<String, Any?>) -> Unit,
    private val onResumeArmedChanged: () -> Unit = {},
) {
    private var hasFocus = false
    // The session publishes this latch (see [PublishedIntent]), so a change
    // calls [onResumeArmedChanged].
    private var resumeOnFocusGain = false
        set(value) {
            if (field == value) return
            field = value
            onResumeArmedChanged()
        }
    // The play intent, as the last onPlaybackActive or onPlaybackInactive
    // set it: a focus loss arms the resume only when it was true.
    private var playbackActive = false
    // A transient loss (a call) that paused the player, until the gain or
    // a permanent loss. The focus request stays in place through it, so
    // [hasFocus] is still true, but a play then asks for the focus again.
    private var transientLoss = false
    // The count of pauses and stops the app made, as the last playback
    // push gave it, or `null` before the first one (see [onPlayback]).
    private var appPauses: Long? = null
    // LOOPER PATCH: when the last becoming-noisy pause stopped a playing
    // player (System.nanoTime), so a call right after it still arms the
    // resume: a call on a Bluetooth headset moves the route first.
    private var noisyPauseAtNs: Long? = null

    /** A transient loss paused the player, and the next gain resumes it. */
    val resumeArmed: Boolean get() = resumeOnFocusGain

    /** A playback push from Dart: [playing] is the play intent, and
     *  [appPauses] counts the pauses and stops the app made, not those of
     *  the session. A new count disarms the resume: during a call Dart is
     *  already paused, so a pause of the app changes nothing else, and a
     *  stop only reads as an inactive player. The pause this controller
     *  emits for a focus loss leaves the count as it is. */
    fun onPlayback(playing: Boolean, appPauses: Long) {
        val seen = this.appPauses
        this.appPauses = appPauses
        if (seen != null && seen != appPauses) disarm()
        if (playing) onPlaybackActive() else onPlaybackInactive()
    }

    /** Playback became active: take focus and listen for headphone unplug.
     *  Gate on the request result — a FAILED/DELAYED grant pauses instead of
     *  barging over a non-duckable holder (active call / assistant). */
    private fun onPlaybackActive() {
        playbackActive = true
        // LOOPER PATCH: keepPlaying ("Manage Audio Focus" off) leaves the
        // focus alone, so other apps play on and Android 12+ never fades this
        // app out for keeping on after a loss it ignored.
        if (policy() == KEEP_PLAYING) {
            if (hasFocus) abandonFocus()
            transientLoss = false
            resumeOnFocusGain = false
            port.listenNoisy(true)
            return
        }
        val duringLoss = transientLoss
        val result = requestFocus()
        if (result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED) transientLoss = false
        port.listenNoisy(true)
        val r = InterruptionLogic.onFocusRequestResult(result, policy(), duringLoss)
        resumeOnFocusGain = r.resumeOnFocusGain
        r.command?.let { emit(mapOf("type" to it)) }
    }

    /** Playback paused (intent off): drop the headphone-unplug receiver — a
     *  paused stream can't be "becoming noisy" — but keep audio focus held so
     *  a quick resume doesn't re-duck other apps. */
    private fun onPlaybackInactive() {
        playbackActive = false
        port.listenNoisy(false)
    }

    /** A pause from a controller: the end of a call must not restart it
     *  (see [InterruptionLogic.onExternalPause]). */
    fun disarm() {
        noisyPauseAtNs = null
        resumeOnFocusGain = InterruptionLogic.onExternalPause().resumeOnFocusGain
    }

    /** Session disabled / engine detached: drop focus and the receiver. */
    /** LOOPER PATCH: the session was enabled again on another player (a
     *  crossfade hand-over) while this controller kept the focus. Dart's
     *  count of the app's pauses starts again from zero there. */
    fun onNewSession() {
        appPauses = null
    }

    /** LOOPER PATCH: the policy changed; apply it to the current playback. */
    fun onPolicyChanged() {
        val seen = appPauses ?: return
        onPlayback(playbackActive, seen)
    }

    fun release() {
        abandonFocus()
        port.listenNoisy(false)
        resumeOnFocusGain = false
        playbackActive = false
        transientLoss = false
    }

    /** An `OnAudioFocusChangeListener` callback, from [port]. */
    fun onFocusChange(focusChange: Int) {
        val noisyAt = noisyPauseAtNs
        val pausedByRouteJustNow = noisyAt != null &&
            System.nanoTime() - noisyAt < NOISY_THEN_CALL_NS
        if (focusChange != AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK) noisyPauseAtNs = null
        val r = InterruptionLogic.onFocusChange(
            focusChange, policy(), resumeOnFocusGain,
            wasPlaying = playbackActive ||
                (focusChange == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT && pausedByRouteJustNow),
        )
        transientLoss = InterruptionLogic.transientLossAfter(focusChange, policy(), transientLoss)
        resumeOnFocusGain = r.resumeOnFocusGain
        if (r.abandonFocus) abandonFocus()
        r.command?.let { emit(mapOf("type" to it)) }
    }

    /** `ACTION_AUDIO_BECOMING_NOISY`, from [port]. */
    fun onBecomingNoisy() {
        noisyPauseAtNs = if (playbackActive) System.nanoTime() else null
        val r = InterruptionLogic.onBecomingNoisy()
        resumeOnFocusGain = r.resumeOnFocusGain
        r.command?.let { emit(mapOf("type" to it)) }
    }

    /** Requests focus and returns the raw `AUDIOFOCUS_REQUEST_*` result so the
     *  caller can gate playback (GRANTED / FAILED / DELAYED). */
    private fun requestFocus(): Int {
        if (!InterruptionLogic.needsFocusRequest(hasFocus, transientLoss)) {
            return AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        }
        val result = port.requestFocus()
        hasFocus = result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        return result
    }

    private fun abandonFocus() {
        port.abandonFocus()
        hasFocus = false
    }

    private companion object {
        const val KEEP_PLAYING = "keepPlaying"
        const val NOISY_THEN_CALL_NS = 2_000_000_000L
    }
}

/** The Android calls of [AudioFocusController]. */
internal interface FocusPort {
    /** Requests the focus, and returns the `AUDIOFOCUS_REQUEST_*` result. */
    fun requestFocus(): Int

    fun abandonFocus()

    /** Registers the becoming noisy receiver, or unregisters it. */
    fun listenNoisy(on: Boolean)
}

/** [FocusPort] on the [AudioManager] of [context]. Its callbacks go to
 *  [target], set once the controller exists, on [mainHandler]'s looper. */
internal class AndroidFocusPort(
    private val context: Context,
    private val mainHandler: Handler,
) : FocusPort {
    lateinit var target: AudioFocusController

    private val audioManager =
        context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    private var focusRequest: AudioFocusRequest? = null
    private var noisyRegistered = false

    private val focusListener =
        AudioManager.OnAudioFocusChangeListener { change -> target.onFocusChange(change) }

    private val noisyReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != AudioManager.ACTION_AUDIO_BECOMING_NOISY) return
            target.onBecomingNoisy()
        }
    }

    override fun requestFocus(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val attrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build()
            val req = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(attrs)
                .setOnAudioFocusChangeListener(focusListener, mainHandler)
                // Let the system auto-duck for transient duck requests (nav
                // prompts) instead of pausing — matches iOS, which doesn't
                // pause for duck-type events. No CAN_DUCK callback arrives.
                .setWillPauseWhenDucked(false)
                // Accept a deferred grant: if focus is busy now (a call), the
                // system grants it later via AUDIOFOCUS_GAIN → resume then.
                .setAcceptsDelayedFocusGain(true)
                .build()
            focusRequest = req
            audioManager.requestAudioFocus(req)
        } else {
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(
                focusListener,
                AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN,
            )
        }

    override fun abandonFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
            focusRequest = null
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(focusListener)
        }
    }

    override fun listenNoisy(on: Boolean) {
        if (on == noisyRegistered) return
        if (on) {
            val filter = IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY)
            // ACTION_AUDIO_BECOMING_NOISY is a protected system broadcast →
            // RECEIVER_NOT_EXPORTED on API 33+ (required there; harmless intent).
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.registerReceiver(noisyReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                context.registerReceiver(noisyReceiver, filter)
            }
        } else {
            try {
                context.unregisterReceiver(noisyReceiver)
            } catch (_: IllegalArgumentException) {
                // Not registered (defensive) — ignore.
            }
        }
        noisyRegistered = on
    }
}
