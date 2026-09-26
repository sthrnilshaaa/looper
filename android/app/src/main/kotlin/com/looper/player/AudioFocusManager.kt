package com.looper.player

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioManager
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.MethodChannel

/**
 * Forwards audio-route events to Dart: headphones unplugged ("becoming
 * noisy") and a Bluetooth audio output connecting (for "Resume on Bluetooth
 * Connect").
 *
 * Despite the name, this class must never request audio focus: mpv_audio_kit
 * is the sole focus owner (its AudioFocusController), and a second focus
 * request from this app would steal focus from the plugin's listener and
 * pause playback.
 */
class AudioFocusManager(
    private val context: Context,
    private val channel: MethodChannel
) {
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val handler = Handler(Looper.getMainLooper())

    // Synced from Dart
    var resumeOnBluetoothConnect = false

    private val knownAudioDeviceIds = mutableSetOf<Int>()

    private val audioDeviceCallback = object : AudioDeviceCallback() {
        override fun onAudioDevicesAdded(addedDevices: Array<out AudioDeviceInfo>) {
            val newlyConnectedBluetoothAudio = addedDevices.any { device ->
                val isNew = knownAudioDeviceIds.add(device.id)
                isNew && isBluetoothAudioOutput(device)
            }
            if (newlyConnectedBluetoothAudio && resumeOnBluetoothConnect) {
                Log.d("AudioFocusManager", "Bluetooth audio output connected")
                try {
                    channel.invokeMethod("onBluetoothConnected", null)
                } catch (e: Exception) {
                    Log.e("AudioFocusManager", "Error invoking onBluetoothConnected", e)
                }
            }
        }

        override fun onAudioDevicesRemoved(removedDevices: Array<out AudioDeviceInfo>) {
            removedDevices.forEach { knownAudioDeviceIds.remove(it.id) }
        }
    }

    private val audioReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent == null) return
            when (intent.action) {
                AudioManager.ACTION_AUDIO_BECOMING_NOISY -> {
                    Log.d("AudioFocusManager", "Audio becoming noisy (headset unplugged)")
                    try {
                        channel.invokeMethod("onBecomingNoisy", null)
                    } catch (e: Exception) {
                        Log.e("AudioFocusManager", "Error invoking onBecomingNoisy", e)
                    }
                }
            }
        }
    }

    private var receiversRegistered = false

    fun registerReceivers() {
        if (receiversRegistered) return
        val filter = IntentFilter().apply {
            addAction(AudioManager.ACTION_AUDIO_BECOMING_NOISY)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // A protected system broadcast only the OS can send, so there's
            // no need to accept it from other apps too.
            context.registerReceiver(audioReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(audioReceiver, filter)
        }
        knownAudioDeviceIds.clear()
        audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            .forEach { knownAudioDeviceIds.add(it.id) }
        audioManager.registerAudioDeviceCallback(audioDeviceCallback, handler)
        receiversRegistered = true
    }

    fun unregisterReceivers() {
        if (!receiversRegistered) return
        try {
            context.unregisterReceiver(audioReceiver)
        } catch (e: Exception) {
            Log.e("AudioFocusManager", "Error unregistering receiver", e)
        }
        audioManager.unregisterAudioDeviceCallback(audioDeviceCallback)
        knownAudioDeviceIds.clear()
        receiversRegistered = false
    }

    private fun isBluetoothAudioOutput(device: AudioDeviceInfo): Boolean {
        if (!device.isSink) return false
        if (device.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP ||
            device.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
            device.type == AudioDeviceInfo.TYPE_HEARING_AID
        ) return true
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            (device.type == AudioDeviceInfo.TYPE_BLE_HEADSET ||
                device.type == AudioDeviceInfo.TYPE_BLE_SPEAKER)
        ) return true
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            device.type == AudioDeviceInfo.TYPE_BLE_BROADCAST
    }
}
