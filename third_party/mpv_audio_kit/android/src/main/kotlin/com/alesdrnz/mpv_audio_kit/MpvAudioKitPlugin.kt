/*
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.alesdrnz.mpv_audio_kit

import android.content.Context
import android.net.Uri
import androidx.media3.common.util.UnstableApi
import com.alesdrnz.mpv_audio_kit.media_session.MediaSessionManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Android entry point. The package itself is direct FFI to libmpv; this plugin
 * only opens Content URIs as file descriptors ([FileDescriptorChannel]), reads
 * the images of content:// covers ([ArtworkChannel]), tells the passthrough
 * codecs of the output ([PassthroughChannel]), and
 * wires the OS media session (Media3) and its method/event channels.
 */
class MpvAudioKitPlugin : FlutterPlugin, ActivityAware {

    companion object {
        init {
            // Loading libmpv via System.loadLibrary() ensures that the JVM
            // invokes libmpv's JNI_OnLoad, registering the JavaVM pointer internally.
            // Without this, dart:ffi loads it via dlopen() which skips JNI_OnLoad,
            // causing the AudioTrack audio output driver to fail with
            // "No Java virtual machine has been registered". The build hook
            // bundles it as libmpv_audio_kit.so, the SONAME inside too, so the
            // later dlopen from Dart gets this same loaded copy.
            System.loadLibrary("mpv_audio_kit")
        }
    }

    private lateinit var fileDescriptors: FileDescriptorChannel
    private lateinit var artwork: ArtworkChannel
    private lateinit var passthrough: PassthroughChannel
    private lateinit var mediaSessionMethodChannel: MethodChannel
    private lateinit var mediaSessionEventChannel: EventChannel
    private lateinit var context: Context

    /**
     * Initializes the plugin when attached to the Flutter engine.
     */
    @UnstableApi
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        // Content URIs opened as file descriptors, off the main thread.
        fileDescriptors = FileDescriptorChannel { context.contentResolver }
        fileDescriptors.attach(flutterPluginBinding.binaryMessenger)
        // The images of content:// and android.resource:// covers, read for
        // the media session of the Dart side on a queue of their own.
        artwork = ArtworkChannel { uri ->
            val parsed = Uri.parse(uri)
            val resolver = context.contentResolver
            ArtworkChannel.Source(resolver.getType(parsed)) { resolver.openInputStream(parsed) }
        }
        artwork.attach(flutterPluginBinding.binaryMessenger)
        // The codecs of audio-spdif the output takes (HDMI on a TV box).
        passthrough = PassthroughChannel(PassthroughChannel.Device(context))
        passthrough.attach(flutterPluginBinding.binaryMessenger)

        // OS media session (Media3): lockscreen / notification controls,
        // hardware & Bluetooth media keys. The MediaSessionManager owns the
        // session + the SimpleBasePlayer adapter and bridges both channels.
        MediaSessionManager.attach(context)

        mediaSessionMethodChannel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "mpv_audio_kit/media_session"
        )
        // The manager is one per process: each engine reaches it with its own
        // plugin as the token, so the detach of another engine (a workmanager
        // task) leaves alone the session this one enabled.
        mediaSessionMethodChannel.setMethodCallHandler { call, result ->
            MediaSessionManager.onMethodCall(this, call, result)
        }

        mediaSessionEventChannel = EventChannel(
            flutterPluginBinding.binaryMessenger,
            "mpv_audio_kit/media_session/commands"
        )
        mediaSessionEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) =
                MediaSessionManager.onListen(this@MpvAudioKitPlugin, events)

            override fun onCancel(arguments: Any?) =
                MediaSessionManager.onCancel(this@MpvAudioKitPlugin)
        })
    }

    /**
     * Cleans up the plugin when detached from the engine.
     */
    // The activity of this engine, for the media keys of a remote: see
    // ActivityMediaKeys.
    @UnstableApi
    override fun onAttachedToActivity(binding: ActivityPluginBinding) =
        MediaSessionManager.attachActivity(this, binding.activity)

    @UnstableApi
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        MediaSessionManager.attachActivity(this, binding.activity)

    @UnstableApi
    override fun onDetachedFromActivityForConfigChanges() =
        MediaSessionManager.detachActivity(this)

    @UnstableApi
    override fun onDetachedFromActivity() = MediaSessionManager.detachActivity(this)

    @UnstableApi
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        fileDescriptors.detach()
        artwork.detach()
        passthrough.detach()
        mediaSessionMethodChannel.setMethodCallHandler(null)
        mediaSessionEventChannel.setStreamHandler(null)
        MediaSessionManager.detach(this)
    }
}
