/*
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.alesdrnz.mpv_audio_kit.media_session

import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.media3.common.util.UnstableApi
import androidx.media3.session.CommandButton
import androidx.media3.session.MediaController
import androidx.media3.session.MediaSession
import androidx.media3.session.SessionCommand
import androidx.media3.session.SessionResult
import androidx.media3.session.SessionToken
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Process-static bridge between the Dart `MediaSessionController` and the
 * Media3 session. Only one [Player] per process owns the session
 * (enforced Dart-side), so a singleton is the natural fit and lets
 * [MpvMediaSessionService] — which Media3 may create / destroy on its own
 * schedule — always resolve the live session and command target without a
 * Binder handshake.
 *
 * It is a *stateless renderer*: each `enable` / `update*` replaces a
 * `@Volatile` snapshot and calls [MpvControllerPlayer.invalidateState];
 * [MpvControllerPlayer.getState] reads the snapshot. Inbound OS commands
 * arrive on the player's `handleX` callbacks and are forwarded to Dart
 * over the event channel.
 *
 * Everything runs on the main [Looper] — the Flutter platform thread —
 * which is also the player's application thread, so there are no
 * cross-thread hops. Snapshot fields are `@Volatile` anyway, to stay
 * correct if the player is ever moved to a dedicated looper.
 */
@UnstableApi
internal object MediaSessionManager :
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    // ── Snapshots (the single source of truth lives in Dart) ────────────

    internal data class ConfigSnapshot(
        val actions: Set<String>,
        val interruptionPolicy: String,
        val fastForwardIntervalMs: Long,
        val rewindIntervalMs: Long,
        val supportedPlaybackRates: List<Double>,
        val isFavorite: Boolean,
    ) {
        companion object {
            val EMPTY =
                ConfigSnapshot(emptySet(), "pauseAndResume", 15_000, 15_000, emptyList(), false)
        }
    }

    internal class MetadataSnapshot(
        val title: String?,
        val artist: String?,
        val album: String?,
        val artworkBytes: ByteArray?,
        val artworkUri: String?,
        val durationMs: Long?,
        val trackNumber: Int?,
        val discNumber: Int?,
        val albumArtist: String?,
        val genre: String?,
    ) {
        companion object {
            val EMPTY =
                MetadataSnapshot(null, null, null, null, null, null, null, null, null, null)
        }
    }

    internal data class PlaybackSnapshot(
        val playing: Boolean,
        val positionMs: Long,
        val rate: Double,
        val seekable: Boolean,
        val loop: String,
        val shuffle: Boolean,
        val completed: Boolean,
        val actualPlaying: Boolean,
        val buffering: Boolean,
        val hasNext: Boolean,
        val hasPrevious: Boolean,
    ) {
        companion object {
            val EMPTY = PlaybackSnapshot(
                false, 0, 1.0, false, "off", false, false, false, false, true, true,
            )
        }
    }

    @Volatile var config: ConfigSnapshot = ConfigSnapshot.EMPTY
        private set

    @Volatile var metadata: MetadataSnapshot = MetadataSnapshot.EMPTY
        private set

    @Volatile var playback: PlaybackSnapshot = PlaybackSnapshot.EMPTY
        private set

    @Volatile var scrubFreezeMs: Long? = null
        private set

    @Volatile var enabled: Boolean = false
        private set

    // ── Wiring (set by the plugin) ──────────────────────────────────────

    private var appContext: Context? = null
    private var eventSink: EventChannel.EventSink? = null
    private var player: MpvControllerPlayer? = null
    private var session: MediaSession? = null
    private var audioFocus: AudioFocusController? = null

    // A self-connected controller binds [MpvMediaSessionService] so Media3
    // promotes it to the foreground and posts (and keeps updating) the media
    // notification. `startService` alone runs the service but never engages its
    // MediaNotificationManager, so without this binding the notification — and
    // the lock-screen / shade media controls it drives — never appear.
    private var controllerFuture: ListenableFuture<MediaController>? = null
    private var publishCount: Int = 0

    /** The last media button preferences pushed to the session — so a
     *  position-only tick doesn't re-broadcast an identical button row.
     *  [CommandButton] has value equality (ignoring extras). */
    private var lastButtons: List<CommandButton> = emptyList()

    private val mainHandler = Handler(Looper.getMainLooper())

    /**
     * The session callback. Advertises the custom favourite (`like`) command so
     * controllers — including Media3's own media-notification controller — may
     * send it, and forwards the press to Dart as the `{type: "like"}` wire event
     * (matching the Apple contract). Transport commands ride on player commands
     * and never reach here.
     */
    private val sessionCallback = object : MediaSession.Callback {
        override fun onConnect(
            session: MediaSession,
            controller: MediaSession.ControllerInfo,
        ): MediaSession.ConnectionResult {
            val sessionCommands =
                MediaSession.ConnectionResult.DEFAULT_SESSION_COMMANDS.buildUpon()
                    .add(SessionCommand(MediaSessionMappers.LIKE_ACTION, Bundle.EMPTY))
                    .build()
            return MediaSession.ConnectionResult.AcceptedResultBuilder(session)
                .setAvailableSessionCommands(sessionCommands)
                .build()
        }

        override fun onCustomCommand(
            session: MediaSession,
            controller: MediaSession.ControllerInfo,
            customCommand: SessionCommand,
            args: Bundle,
        ): ListenableFuture<SessionResult> {
            if (customCommand.customAction == MediaSessionMappers.LIKE_ACTION) {
                forwardCommand(mapOf("type" to "like"))
                return Futures.immediateFuture(SessionResult(SessionResult.RESULT_SUCCESS))
            }
            return Futures.immediateFuture(
                SessionResult(SessionResult.RESULT_ERROR_NOT_SUPPORTED),
            )
        }
    }

    fun attach(context: Context) {
        appContext = context.applicationContext
    }

    /** Tear everything down when the engine detaches (defensive — Dart
     *  normally calls `disable` on dispose first). */
    fun detach() {
        eventSink = null
        if (enabled) disable()
        appContext = null
    }

    // ── Method channel (Dart → native) ──────────────────────────────────

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "enable" -> {
                    val a = call.arguments as Map<*, *>
                    enable(
                        a["config"] as Map<*, *>,
                        a["metadata"] as Map<*, *>,
                        a["playback"] as Map<*, *>,
                    )
                    result.success(null)
                }
                "updateConfig" -> {
                    updateConfig(call.arguments as Map<*, *>); result.success(null)
                }
                "updateMetadata" -> {
                    updateMetadata(call.arguments as Map<*, *>); result.success(null)
                }
                "updatePlayback" -> {
                    updatePlayback(call.arguments as Map<*, *>); result.success(null)
                }
                "disable" -> {
                    disable(); result.success(null)
                }
                "debugMediaSessionState" -> result.success(debugState())
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("MEDIA_SESSION_ERROR", e.message, null)
        }
    }

    // ── Event channel (native → Dart) ───────────────────────────────────

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    /** Forwards an OS remote command to Dart, on the platform thread. */
    fun forwardCommand(command: Map<String, Any?>) = runOnMain {
        eventSink?.success(command)
    }

    /** A scrub from the OS slider: pin the slider at the drop target
     *  (republish), then forward the absolute seek. The freeze clears in
     *  [updatePlayback] once the landed position confirms. */
    fun onScrub(positionMs: Long) = runOnMain {
        scrubFreezeMs = positionMs
        player?.republish()
        eventSink?.success(mapOf("type" to "seekTo", "positionMs" to positionMs))
    }

    // ── Snapshot mutations ──────────────────────────────────────────────

    private fun enable(config: Map<*, *>, metadata: Map<*, *>, playback: Map<*, *>) = runOnMain {
        this.config = parseConfig(config)
        this.metadata = parseMetadata(metadata)
        this.playback = parsePlayback(playback)
        scrubFreezeMs = null
        enabled = true
        ensureSessionCreated()
        ensureAudioFocus()
        startService()
        publish()
        // Take audio focus + arm the headphone-unplug receiver if we're
        // already playing at enable time.
        if (this.playback.playing) audioFocus?.onPlaybackActive()
    }

    private fun updateConfig(config: Map<*, *>) = runOnMain {
        this.config = parseConfig(config)
        publish()
    }

    private fun updateMetadata(metadata: Map<*, *>) = runOnMain {
        this.metadata = parseMetadata(metadata)
        publish()
    }

    private fun updatePlayback(playback: Map<*, *>) = runOnMain {
        val pb = parsePlayback(playback)
        this.playback = pb
        val frozen = scrubFreezeMs
        // Clear the scrub freeze once Dart confirms the landed position is
        // within ~1s of the drop target — the slider then tracks playback
        // again. A stale push mid-seek keeps the slider pinned.
        if (frozen != null && kotlin.math.abs(pb.positionMs - frozen) <= 1000) {
            scrubFreezeMs = null
        }
        publish()
        // Acquire focus when playback starts (idempotent while held); focus is
        // held across a user pause and released only on disable. On pause, drop
        // the becoming-noisy receiver but keep focus.
        if (pb.playing) {
            audioFocus?.onPlaybackActive()
        } else {
            audioFocus?.onPlaybackInactive()
        }
    }

    private fun disable() = runOnMain {
        enabled = false
        audioFocus?.release()
        audioFocus = null
        config = ConfigSnapshot.EMPTY
        metadata = MetadataSnapshot.EMPTY
        playback = PlaybackSnapshot.EMPTY
        scrubFreezeMs = null
        lastButtons = emptyList()
        // Publish the idle/empty state first so Media3 removes the
        // notification and demotes the foreground service, THEN release.
        player?.republish()
        publishCount++
        // Release the foreground-holding controller before stopping the
        // service so Media3 drops the notification and demotes the FGS.
        controllerFuture?.let { MediaController.releaseFuture(it) }
        controllerFuture = null
        stopService()
        // Media3's documented onDestroy order: release the Player BEFORE the
        // MediaSession it wraps, or the player's release-time notifications hit
        // a dead session and log "already released" spam.
        player?.release()
        player = null
        session?.release()
        session = null
    }

    // ── Session / service lifecycle ─────────────────────────────────────

    private fun ensureSessionCreated() {
        val ctx = appContext ?: return
        if (player == null) player = MpvControllerPlayer(Looper.getMainLooper())
        if (session == null) {
            val launch = ctx.packageManager.getLaunchIntentForPackage(ctx.packageName)
            val pending = launch?.let {
                PendingIntent.getActivity(
                    ctx,
                    0,
                    it,
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                )
            }
            val builder = MediaSession.Builder(ctx, player!!)
                .setCallback(sessionCallback)
            if (pending != null) builder.setSessionActivity(pending)
            session = builder.build()
        }
    }

    /** Resolved by [MpvMediaSessionService.onGetSession]. */
    fun currentSession(): MediaSession? = session

    private fun ensureAudioFocus() {
        val ctx = appContext ?: return
        if (audioFocus == null) {
            audioFocus = AudioFocusController(
                context = ctx,
                mainHandler = mainHandler,
                policy = { config.interruptionPolicy },
                emit = { cmd -> forwardCommand(cmd) },
            )
        }
    }

    private fun startService() {
        val ctx = appContext ?: return
        try {
            ctx.startService(Intent(ctx, MpvMediaSessionService::class.java))
        } catch (_: Exception) {
            // Background-start restriction (Android 8+) — enable() is
            // user-initiated in the foreground, so this rarely fires; if it
            // does, the session still exists, only the notification is absent.
        }
        // Bind a controller to the service. This is what makes Media3 promote
        // the service to the foreground and post the media notification — a
        // bare startService never engages its notification manager. The
        // controller drives nothing (playback is owned by Dart); it exists
        // only to hold the service foreground for the session's lifetime.
        if (controllerFuture == null) {
            val token =
                SessionToken(ctx, ComponentName(ctx, MpvMediaSessionService::class.java))
            controllerFuture = MediaController.Builder(ctx, token).buildAsync()
        }
    }

    private fun stopService() {
        val ctx = appContext ?: return
        try {
            ctx.stopService(Intent(ctx, MpvMediaSessionService::class.java))
        } catch (_: Exception) {
        }
    }

    private fun publish() = runOnMain {
        player?.republish()
        applyButtons()
        publishCount++
    }

    /** Rebuild the notification button row and push it only when it differs
     *  from the last one — toggle icons (repeat / shuffle / heart) track state,
     *  so this re-broadcasts on a loop / shuffle / favourite change but not on a
     *  plain position tick. Best-effort: a failure never interrupts playback. */
    private fun applyButtons() {
        val s = session ?: return
        val buttons =
            if (enabled) MediaSessionMappers.buildMediaButtonPreferences(config, playback)
            else emptyList()
        if (buttons == lastButtons) return
        lastButtons = buttons
        try {
            s.setMediaButtonPreferences(buttons)
        } catch (_: Exception) {
        }
    }

    // ── Debug probe (real published State) ──────────────────────────────

    /** Reads back what the player actually publishes — used by the
     *  integration test to assert the real OS-facing state. The State-derived
     *  fields are read inside the player (where `getState` is accessible). */
    fun debugState(): Map<String, Any?> {
        val p = player
        if (!enabled || p == null) {
            return mapOf(
                "publishCount" to publishCount,
                "playbackState" to "stopped",
                "title" to null,
                "artist" to null,
                "album" to null,
                "durationMs" to null,
                "positionMs" to 0,
                "rate" to 1.0,
                "hasArtwork" to false,
                "seekable" to false,
                "loop" to "off",
                "shuffle" to false,
                "frozen" to false,
            )
        }
        return p.debugProbe(publishCount)
    }

    // ── Parsing ─────────────────────────────────────────────────────────

    private fun parseConfig(map: Map<*, *>) = ConfigSnapshot(
        actions = (map["actions"] as? List<*>)?.mapNotNull { it as? String }?.toSet()
            ?: emptySet(),
        interruptionPolicy = map["interruptionPolicy"] as? String ?: "pauseAndResume",
        fastForwardIntervalMs = (map["fastForwardIntervalMs"] as? Number)?.toLong() ?: 15_000,
        rewindIntervalMs = (map["rewindIntervalMs"] as? Number)?.toLong() ?: 15_000,
        supportedPlaybackRates = (map["supportedPlaybackRates"] as? List<*>)
            ?.mapNotNull { (it as? Number)?.toDouble() } ?: emptyList(),
        isFavorite = map["isFavorite"] as? Boolean ?: false,
    )

    private fun parseMetadata(map: Map<*, *>) = MetadataSnapshot(
        title = map["title"] as? String,
        artist = map["artist"] as? String,
        album = map["album"] as? String,
        artworkBytes = map["artworkBytes"] as? ByteArray,
        artworkUri = map["artworkUri"] as? String,
        durationMs = (map["durationMs"] as? Number)?.toLong(),
        trackNumber = (map["trackNumber"] as? Number)?.toInt(),
        discNumber = (map["discNumber"] as? Number)?.toInt(),
        albumArtist = map["albumArtist"] as? String,
        genre = map["genre"] as? String,
    )

    private fun parsePlayback(map: Map<*, *>) = PlaybackSnapshot(
        playing = map["playing"] as? Boolean ?: false,
        positionMs = (map["positionMs"] as? Number)?.toLong() ?: 0,
        rate = (map["rate"] as? Number)?.toDouble() ?: 1.0,
        seekable = map["seekable"] as? Boolean ?: false,
        loop = map["loop"] as? String ?: "off",
        shuffle = map["shuffle"] as? Boolean ?: false,
        completed = map["completed"] as? Boolean ?: false,
        actualPlaying = map["actualPlaying"] as? Boolean ?: false,
        buffering = map["buffering"] as? Boolean ?: false,
        hasNext = map["hasNext"] as? Boolean ?: true,
        hasPrevious = map["hasPrevious"] as? Boolean ?: true,
    )

    private fun runOnMain(block: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            block()
        } else {
            mainHandler.post(block)
        }
    }
}
