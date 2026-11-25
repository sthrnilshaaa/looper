/*
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.alesdrnz.mpv_audio_kit

import android.content.ContentResolver
import android.net.Uri
import android.os.ParcelFileDescriptor
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec

/**
 * The `mpv_audio_kit` method channel: opens Content URIs (e.g. from the
 * file picker) as raw file descriptors libmpv can read, and closes them.
 *
 * It runs on a background task queue of the messenger, not on the main
 * thread: `openFileDescriptor` blocks until the provider has the file, and
 * a cloud provider (Drive, OneDrive, Nextcloud) downloads it first, which
 * on the main thread is an ANR after 5 s. The queue is serial, so opens and
 * closes keep their order, and a reply may be sent from its thread.
 */
internal class FileDescriptorChannel(
    private val resolver: () -> ContentResolver,
) : MethodChannel.MethodCallHandler {

    private var channel: MethodChannel? = null

    fun attach(messenger: BinaryMessenger) {
        val queue = messenger.makeBackgroundTaskQueue()
        channel = MethodChannel(messenger, NAME, StandardMethodCodec.INSTANCE, queue)
            .also { it.setMethodCallHandler(this) }
    }

    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "openFileDescriptor" -> {
                val uriStr = call.argument<String>("uri")
                if (uriStr != null) {
                    try {
                        val uri = Uri.parse(uriStr)
                        // Opens the Content URI and returns a ParcelFileDescriptor.
                        val pfd = resolver().openFileDescriptor(uri, "r")
                        if (pfd != null) {
                            // Detaches the raw integer FD. The Dart side owns it: mpv
                            // never closes an fd:// descriptor, so the player closes it
                            // through closeFileDescriptor once the entry has left the
                            // playlist, or at dispose.
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
                // Closes a raw FD previously detached in `openFileDescriptor`:
                // when its entry has left the playlist, at dispose, or when the
                // load was aborted before mpv got it. Without this the
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

    companion object {
        const val NAME = "mpv_audio_kit"
    }
}
