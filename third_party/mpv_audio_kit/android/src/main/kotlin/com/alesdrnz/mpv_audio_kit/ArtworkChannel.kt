/*
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.alesdrnz.mpv_audio_kit

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import java.io.ByteArrayOutputStream
import java.io.InputStream

/**
 * The `mpv_audio_kit/artwork` method channel: reads the image of a
 * `content://` or `android.resource://` cover for the media session of the
 * Dart side, which hands the OS bytes only.
 *
 * It has a background task queue of its own, apart from the one of
 * [FileDescriptorChannel]: a provider that is slow to give a cover (a cloud
 * one downloads it first) must not hold up the open of a song.
 */
internal class ArtworkChannel(
    private val source: (String) -> Source,
) : MethodChannel.MethodCallHandler {

    /** What the ContentResolver has for a URI: its type and its content. */
    class Source(val type: String?, val open: () -> InputStream?)

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
        if (call.method != "readArtwork") {
            result.notImplemented()
            return
        }
        val uri = call.argument<String>("uri")
        val maxBytes = call.argument<Int>("maxBytes")
        if (uri == null || maxBytes == null) {
            result.error("INVALID", "uri or maxBytes is null", null)
            return
        }
        try {
            val found = source(uri)
            // The URI of a song or a video is no cover: not read at all.
            val bytes = if (refusesType(found.type)) {
                null
            } else {
                found.open()?.use { readArtwork(it, maxBytes) }
            }
            result.success(bytes?.let { mapOf("bytes" to it, "mimeType" to found.type) })
        } catch (e: Exception) {
            result.error("ERROR", e.message, null)
        } catch (e: OutOfMemoryError) {
            result.error("ERROR", "out of memory reading the cover", null)
        }
    }

    companion object {
        const val NAME = "mpv_audio_kit/artwork"

        /** The bytes read before the image signature is checked. */
        private const val HEAD = 12

        /** Whether [type] names content that is no image. */
        internal fun refusesType(type: String?): Boolean =
            type != null && (type.startsWith("audio/") || type.startsWith("video/") ||
                type.startsWith("text/"))

        /**
         * Reads [input] to its end when it starts like an image Android
         * decodes (PNG, JPEG, GIF, WebP, BMP, HEIF or AVIF), or gives up:
         * null for anything else (a compiled XML drawable, an adaptive icon),
         * for an empty stream and for one longer than [maxBytes], without
         * reading on.
         */
        internal fun readArtwork(input: InputStream, maxBytes: Int): ByteArray? {
            val out = ByteArrayOutputStream()
            val buffer = ByteArray(64 * 1024)
            var checked = false
            while (true) {
                val n = input.read(buffer)
                if (n < 0) break
                out.write(buffer, 0, n)
                if (out.size() > maxBytes) return null
                if (!checked && out.size() >= HEAD) {
                    if (!isImage(out.toByteArray())) return null
                    checked = true
                }
            }
            if (out.size() == 0) return null
            val bytes = out.toByteArray()
            return if (checked || isImage(bytes)) bytes else null
        }

        /** Whether [head] starts with the signature of an image format. */
        internal fun isImage(head: ByteArray): Boolean {
            fun at(i: Int, vararg b: Int) =
                head.size >= i + b.size && b.indices.all { head[i + it] == b[it].toByte() }
            fun ascii(i: Int, s: String) = at(i, *s.map { it.code }.toIntArray())
            return at(0, 0x89, 0x50, 0x4E, 0x47) || // PNG
                at(0, 0xFF, 0xD8, 0xFF) || // JPEG
                ascii(0, "GIF8") ||
                (ascii(0, "RIFF") && ascii(8, "WEBP")) ||
                ascii(0, "BM") ||
                (ascii(4, "ftyp") && listOf("heic", "heix", "mif1", "msf1", "avif")
                    .any { ascii(8, it) })
        }
    }
}
