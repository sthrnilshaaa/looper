/*
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.alesdrnz.mpv_audio_kit

import android.content.Context
import android.net.Uri
import android.os.ParcelFileDescriptor
import androidx.media3.common.util.UnstableApi
import com.alesdrnz.mpv_audio_kit.media_session.MediaSessionManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Android entry point. The package itself is direct FFI to libmpv; this plugin
 * only wires the OS media session (Media3) and its method/event channels.
 */
class MpvAudioKitPlugin :
    FlutterPlugin,
    MethodCallHandler {

    companion object {
        init {
            // Loading libmpv.so via System.loadLibrary() ensures that the JVM
            // invokes libmpv's JNI_OnLoad, registering the JavaVM pointer internally.
            // Without this, dart:ffi loads it via dlopen() which skips JNI_OnLoad,
            // causing the AudioTrack audio output driver to fail with
            // "No Java virtual machine has been registered".
            System.loadLibrary("mpv")
        }
    }

    private lateinit var channel: MethodChannel
    private lateinit var mediaSessionMethodChannel: MethodChannel
    private lateinit var mediaSessionEventChannel: EventChannel
    private lateinit var context: Context

    /**
     * Initializes the plugin when attached to the Flutter engine.
     */
    @UnstableApi
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "mpv_audio_kit")
        channel.setMethodCallHandler(this)

        // OS media session (Media3): lockscreen / notification controls,
        // hardware & Bluetooth media keys. The MediaSessionManager owns the
        // session + the SimpleBasePlayer adapter and bridges both channels.
        MediaSessionManager.attach(context)

        mediaSessionMethodChannel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "mpv_audio_kit/media_session"
        )
        mediaSessionMethodChannel.setMethodCallHandler(MediaSessionManager)

        mediaSessionEventChannel = EventChannel(
            flutterPluginBinding.binaryMessenger,
            "mpv_audio_kit/media_session/commands"
        )
        mediaSessionEventChannel.setStreamHandler(MediaSessionManager)
    }

    /**
     * Handles MethodChannel calls from Dart.
     *
     * Significant work on Android includes handling Content URIs (e.g., from the file picker)
     * by converting them to low-level File Descriptors that libmpv can consume.
     */
    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            "openFileDescriptor" -> {
                val uriStr = call.argument<String>("uri")
                if (uriStr != null) {
                    try {
                        val uri = Uri.parse(uriStr)
                        // Opens the Content URI and returns a ParcelFileDescriptor.
                        val pfd = context.contentResolver.openFileDescriptor(uri, "r")
                        if (pfd != null) {
                            // Detaches the raw integer FD. Ownership is transferred to libmpv,
                            // which will be responsible for closing it after use.
                            val fd = pfd.detachFd()
                            result.success(fd)
                        } else {
                            result.success(null)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                } else {
                    result.error("INVALID", "uri is null", null)
                }
            }
            "closeFileDescriptor" -> {
                // Closes a raw FD previously detached in `openFileDescriptor`
                // when libmpv never consumed it (e.g. the load was aborted on
                // the Dart side after `_disposed` flipped). Without this the
                // descriptor leaks for the process lifetime.
                val fd = call.argument<Int>("fd")
                if (fd != null) {
                    try {
                        ParcelFileDescriptor.adoptFd(fd).close()
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                } else {
                    result.error("INVALID", "fd is null", null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    /**
     * Cleans up the plugin when detached from the engine.
     */
    @UnstableApi
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        mediaSessionMethodChannel.setMethodCallHandler(null)
        mediaSessionEventChannel.setStreamHandler(null)
        MediaSessionManager.detach()
    }
}
