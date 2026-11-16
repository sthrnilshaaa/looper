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
 * The pure policy mapping lives in [InterruptionLogic]; this class only
 * does the Android plumbing (request/abandon focus across the API 26
 * split, register/unregister the noisy receiver) and applies the
 * reactions. Focus callbacks are delivered on [mainHandler]'s looper and
 * the receiver's `onReceive` runs on the main thread, so [emit] (which
 * itself hops to the platform thread) is always called on main.
 */
internal class AudioFocusController(
    private val context: Context,
    private val mainHandler: Handler,
    private val policy: () -> String,
    private val emit: (Map<String, Any?>) -> Unit,
) {
    private val audioManager =
        context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    private var focusRequest: AudioFocusRequest? = null
    private var hasFocus = false
    private var resumeOnFocusGain = false
    private var noisyRegistered = false

    private val focusListener =
        AudioManager.OnAudioFocusChangeListener { change -> onFocusChange(change) }

    private val noisyReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != AudioManager.ACTION_AUDIO_BECOMING_NOISY) return
            val r = InterruptionLogic.onBecomingNoisy()
            resumeOnFocusGain = r.resumeOnFocusGain
            r.command?.let { emit(mapOf("type" to it)) }
        }
    }

    /** Playback became active: take focus and listen for headphone unplug.
     *  Gate on the request result — a FAILED/DELAYED grant pauses instead of
     *  barging over a non-duckable holder (active call / assistant). */
    fun onPlaybackActive() {
        val result = requestFocus()
        registerNoisy()
        val r = InterruptionLogic.onFocusRequestResult(result, policy())
        resumeOnFocusGain = r.resumeOnFocusGain
        r.command?.let { emit(mapOf("type" to it)) }
    }

    /** Playback paused (intent off): drop the headphone-unplug receiver — a
     *  paused stream can't be "becoming noisy" — but keep audio focus held so
     *  a quick resume doesn't re-duck other apps. */
    fun onPlaybackInactive() {
        unregisterNoisy()
    }

    /** Session disabled / engine detached: drop focus and the receiver. */
    fun release() {
        abandonFocus()
        unregisterNoisy()
        resumeOnFocusGain = false
    }

    private fun onFocusChange(focusChange: Int) {
        val r = InterruptionLogic.onFocusChange(focusChange, policy(), resumeOnFocusGain)
        resumeOnFocusGain = r.resumeOnFocusGain
        if (r.abandonFocus) abandonFocus()
        r.command?.let { emit(mapOf("type" to it)) }
    }

    /** Requests focus and returns the raw `AUDIOFOCUS_REQUEST_*` result so the
     *  caller can gate playback (GRANTED / FAILED / DELAYED). */
    private fun requestFocus(): Int {
        if (hasFocus) return AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        val result = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
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
        hasFocus = result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        return result
    }

    private fun abandonFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
            focusRequest = null
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(focusListener)
        }
        hasFocus = false
    }

    private fun registerNoisy() {
        if (noisyRegistered) return
        val filter = IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY)
        // ACTION_AUDIO_BECOMING_NOISY is a protected system broadcast →
        // RECEIVER_NOT_EXPORTED on API 33+ (required there; harmless intent).
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(noisyReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(noisyReceiver, filter)
        }
        noisyRegistered = true
    }

    private fun unregisterNoisy() {
        if (!noisyRegistered) return
        try {
            context.unregisterReceiver(noisyReceiver)
        } catch (_: IllegalArgumentException) {
            // Not registered (defensive) — ignore.
        }
        noisyRegistered = false
    }
}
