/*
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.alesdrnz.mpv_audio_kit

import android.content.Context
import android.content.IntentFilter
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * The `mpv_audio_kit/passthrough` method channel: the codecs of
 * `audio-spdif` the output takes, as mpv names them. mpv's AudioTrack
 * output sends them as IEC61937 stereo, which carries AC3, E-AC3 and DTS;
 * TrueHD and DTS-HD need eight channels and stay out.
 *
 * On API 29 and later AudioTrack says whether the output plays an encoding
 * directly; before, the sticky HDMI plug broadcast lists the encodings of
 * the sink, as ExoPlayer reads them.
 */
internal class PassthroughChannel(
    private val probe: Probe,
) : MethodChannel.MethodCallHandler {

    /** What the platform says about the output. */
    interface Probe {
        /** The API level. */
        val sdk: Int

        /** API 29 and later: whether the output plays [encoding] directly. */
        fun direct(encoding: Int): Boolean

        /** The encodings of the HDMI sink, null when none is plugged. */
        fun plugged(): IntArray?
    }

    private var channel: MethodChannel? = null

    fun attach(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, NAME).also { it.setMethodCallHandler(this) }
    }

    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "codecs") {
            result.notImplemented()
            return
        }
        try {
            result.success(codecs(probe))
        } catch (e: Exception) {
            result.error("ERROR", e.message, null)
        }
    }

    companion object {
        const val NAME = "mpv_audio_kit/passthrough"

        // android.media.AudioFormat.ENCODING_*: E_AC3_JOC (Atmos in E-AC3)
        // is E-AC3 on the wire.
        private const val AC3 = 5
        private const val E_AC3 = 6
        private const val DTS = 7
        private const val E_AC3_JOC = 18

        /** Each mpv codec and the encodings that stand for it. */
        private val CODECS = listOf(
            "ac3" to listOf(AC3),
            "eac3" to listOf(E_AC3, E_AC3_JOC),
            "dts" to listOf(DTS),
        )

        /** The codecs [probe] reports, in the order of [CODECS]. */
        internal fun codecs(probe: Probe): List<String> {
            val taken: Set<Int> = if (probe.sdk >= Build.VERSION_CODES.Q) {
                CODECS.flatMap { it.second }.filter { probe.direct(it) }.toSet()
            } else {
                probe.plugged()?.toSet() ?: return emptyList()
            }
            return CODECS.filter { (_, encodings) -> encodings.any { it in taken } }.map { it.first }
        }
    }

    /** The [Probe] of the device, for media playback at 48 kHz stereo. */
    class Device(private val context: Context) : Probe {
        override val sdk: Int get() = Build.VERSION.SDK_INT

        // Deprecated from API 33 for AudioManager.getDirectPlaybackSupport,
        // whose answer counts offload playback too: switching would change
        // which codecs are reported, so the call stays.
        @Suppress("DEPRECATION")
        override fun direct(encoding: Int): Boolean {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false
            val format = AudioFormat.Builder()
                .setEncoding(encoding)
                .setSampleRate(48_000)
                .setChannelMask(AudioFormat.CHANNEL_OUT_STEREO)
                .build()
            val attributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build()
            return AudioTrack.isDirectPlaybackSupported(format, attributes)
        }

        override fun plugged(): IntArray? {
            // A sticky broadcast: a null receiver reads the last one.
            val intent = context.registerReceiver(
                null,
                IntentFilter(AudioManager.ACTION_HDMI_AUDIO_PLUG),
            ) ?: return null
            if (intent.getIntExtra(AudioManager.EXTRA_AUDIO_PLUG_STATE, 0) != 1) return null
            return intent.getIntArrayExtra(AudioManager.EXTRA_ENCODINGS) ?: IntArray(0)
        }
    }
}
