package com.looper.player

import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioDeviceInfo
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioMixerAttributes
import android.os.Build
import android.util.Log

/**
 * Device-side audio facts for the Now Playing quality sheet: the phone, the
 * mixer's native rate/buffer, and the output device music most likely goes
 * to. mpv plays through its own AudioTrack, which we can't query for its
 * routed device, so the device is picked by Android's usual media routing
 * priority (USB > wired > dock > Bluetooth > hearing aid > HDMI > speaker).
 */
object AudioOutputInfo {
    fun collect(context: Context): Map<String, Any?> {
        val am = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val pm = context.packageManager
        val info = mutableMapOf<String, Any?>(
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
            "androidVersion" to Build.VERSION.RELEASE,
            "sdkInt" to Build.VERSION.SDK_INT,
            "nativeSampleRate" to
                am.getProperty(AudioManager.PROPERTY_OUTPUT_SAMPLE_RATE)?.toIntOrNull(),
            "framesPerBuffer" to
                am.getProperty(AudioManager.PROPERTY_OUTPUT_FRAMES_PER_BUFFER)?.toIntOrNull(),
            "lowLatency" to pm.hasSystemFeature(PackageManager.FEATURE_AUDIO_LOW_LATENCY),
            "proAudio" to pm.hasSystemFeature(PackageManager.FEATURE_AUDIO_PRO),
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S_V2) {
            val spatializer = am.spatializer
            info["spatialAvailable"] = spatializer.isAvailable
            info["spatialEnabled"] = spatializer.isEnabled
        }
        val active = am.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            .mapNotNull { device -> kindOf(device)?.let { device to it } }
            .minByOrNull { priority(it.second) }
        if (active != null) info["device"] = describe(am, active.first, active.second)
        return info
    }

    private fun describe(am: AudioManager, d: AudioDeviceInfo, kind: String): Map<String, Any?> {
        val encodings = d.encodings
        return mapOf(
            "name" to d.productName?.toString(),
            "kind" to kind,
            // Empty means the device takes any rate / channel count.
            "sampleRates" to d.sampleRates.toList(),
            "maxChannels" to (d.channelCounts.maxOrNull() ?: 0),
            "maxBits" to (encodings.maxOfOrNull { bitsOf(it) } ?: 0),
            "float" to encodings.contains(AudioFormat.ENCODING_PCM_FLOAT),
            "bitPerfect" to supportsBitPerfect(am, d),
            "bluetoothCodec" to if (kind == "bluetooth") bluetoothCodecOf(d) else null,
        )
    }

    private fun bluetoothCodecOf(d: AudioDeviceInfo): String? {
        val enc = d.encodings
        return when {
            Build.VERSION.SDK_INT >= 33 && enc.contains(23) -> "LDAC"
            enc.contains(AudioFormat.ENCODING_AAC_LC) -> "AAC"
            Build.VERSION.SDK_INT >= 30 && enc.contains(20) -> "Opus"
            else -> "SBC"
        }
    }

    private fun supportsBitPerfect(am: AudioManager, d: AudioDeviceInfo): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return false
        return try {
            am.getSupportedMixerAttributes(d).any {
                it.mixerBehavior == AudioMixerAttributes.MIXER_BEHAVIOR_BIT_PERFECT
            }
        } catch (e: Exception) {
            Log.w("AudioOutputInfo", "getSupportedMixerAttributes failed", e)
            false
        }
    }

    private fun bitsOf(encoding: Int): Int = when (encoding) {
        AudioFormat.ENCODING_PCM_8BIT -> 8
        AudioFormat.ENCODING_PCM_16BIT -> 16
        AudioFormat.ENCODING_PCM_24BIT_PACKED -> 24
        AudioFormat.ENCODING_PCM_32BIT, AudioFormat.ENCODING_PCM_FLOAT -> 32
        else -> 0
    }

    private fun kindOf(d: AudioDeviceInfo): String? = when (d.type) {
        AudioDeviceInfo.TYPE_BUILTIN_SPEAKER,
        AudioDeviceInfo.TYPE_BUILTIN_SPEAKER_SAFE -> "speaker"
        AudioDeviceInfo.TYPE_WIRED_HEADSET,
        AudioDeviceInfo.TYPE_WIRED_HEADPHONES,
        AudioDeviceInfo.TYPE_LINE_ANALOG,
        AudioDeviceInfo.TYPE_AUX_LINE -> "wired"
        AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
        AudioDeviceInfo.TYPE_BLE_HEADSET,
        AudioDeviceInfo.TYPE_BLE_SPEAKER,
        AudioDeviceInfo.TYPE_BLE_BROADCAST -> "bluetooth"
        AudioDeviceInfo.TYPE_USB_DEVICE,
        AudioDeviceInfo.TYPE_USB_HEADSET,
        AudioDeviceInfo.TYPE_USB_ACCESSORY -> "usb"
        AudioDeviceInfo.TYPE_HDMI,
        AudioDeviceInfo.TYPE_HDMI_ARC,
        AudioDeviceInfo.TYPE_HDMI_EARC -> "hdmi"
        AudioDeviceInfo.TYPE_HEARING_AID -> "hearingAid"
        AudioDeviceInfo.TYPE_DOCK,
        AudioDeviceInfo.TYPE_DOCK_ANALOG -> "dock"
        else -> null
    }

    private fun priority(kind: String): Int = when (kind) {
        "usb" -> 0
        "wired" -> 1
        "dock" -> 2
        "bluetooth" -> 3
        "hearingAid" -> 4
        "hdmi" -> 5
        else -> 6
    }
}
