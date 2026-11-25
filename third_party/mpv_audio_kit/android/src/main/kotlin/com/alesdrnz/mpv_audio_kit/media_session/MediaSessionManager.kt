/*
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.alesdrnz.mpv_audio_kit.media_session

import android.app.Activity
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
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
 * Media3 session. Only one [Player] per process owns the session, so a
 * singleton is the natural fit and lets [MpvMediaSessionService] — which
 * Media3 may create / destroy on its own schedule — always resolve the live
 * session and command target without a Binder handshake. Every Flutter
 * engine of the process reaches it through its own plugin, which passes
 * itself as the engine token. The first engine to enable owns the session
 * until it disables or detaches: another engine's enable fails with
 * `already_owned`, its updates are dropped, and the commands go to the
 * owner's sink (see [EngineOwnership]).
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
internal object MediaSessionManager {

    // ── Snapshots (the single source of truth lives in Dart) ────────────

    internal data class ConfigSnapshot(
        val actions: Set<String>,
        val interruptionPolicy: String,
        val fastForwardIntervalMs: Long,
        val rewindIntervalMs: Long,
        val isFavorite: Boolean,
    ) {
        companion object {
            val EMPTY =
                ConfigSnapshot(emptySet(), "pauseAndResume", 15_000, 15_000, false)
        }
    }

    internal class MetadataSnapshot(
        val title: String?,
        val artist: String?,
        val album: String?,
        val artworkBytes: ByteArray?,
        val durationMs: Long?,
        val trackNumber: Int?,
        val discNumber: Int?,
        val albumArtist: String?,
        val genre: String?,
    ) {
        companion object {
            val EMPTY =
                MetadataSnapshot(null, null, null, null, null, null, null, null, null)
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
        // The pauses and stops the app made (see AudioFocusController.onPlayback).
        val appPauses: Long = 0,
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

    private val scrub = ScrubFreeze()

    /** The scrub target the seek bar is pinned at, or `null` (see [ScrubFreeze]). */
    val scrubFreezeMs: Long? get() = scrub.targetMs

    @Volatile var enabled: Boolean = false
        private set

    /** A transient focus loss paused the player and the next gain resumes
     *  it: the session publishes it as suppressed (see [PublishedIntent]). */
    val resumeArmed: Boolean get() = audioFocus?.resumeArmed == true

    /** The foreground timeout the next [MpvMediaSessionService] gets, set
     *  in debug builds only by the emulator test of F172, which cannot wait
     *  the 10 minutes of Media3's default. `null` keeps the default. */
    @Volatile var debugForegroundServiceTimeoutMs: Long? = null
        private set

    // ── Wiring (set by the plugin) ──────────────────────────────────────

    private var appContext: Context? = null
    private var player: MpvControllerPlayer? = null
    private var session: MediaSession? = null
    private var audioFocus: AudioFocusController? = null
    // LOOPER PATCH: a disable keeps the focus this long before releasing it,
    // so a crossfade hand-over (disable on one player, enable on the other
    // ~600 ms later) never leaves a gap in which calls and other apps go
    // unanswered. An enable inside the window takes the controller over.
    private var focusReleasePending: Runnable? = null
    private const val FOCUS_HANDOVER_MS = 3_000L
    // LOOPER PATCH: the policy the focus follows during that window.
    private var handoverPolicy = "pauseAndResume"

    // The media controller of each activity in front points at the session,
    // so the window hands it the media keys on every Android version.
    private val activityKeys = ActivityMediaKeys<android.media.session.MediaSession.Token>()

    // Which engine owns the session, and the command sink of each engine:
    // every engine of the process reaches this object through its own plugin.
    private val engines = EngineOwnership<EventChannel.EventSink>()

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
            // The builder of media3 1.11 with no defaults, given those the
            // deprecated AcceptedResultBuilder(session) set: every controller
            // keeps the player's default commands, trusted or not.
            return MediaSession.ConnectionResult.AcceptedResultBuilder()
                .setAvailableSessionCommands(sessionCommands)
                .setAvailablePlayerCommands(MediaSession.ConnectionResult.DEFAULT_PLAYER_COMMANDS)
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

    /** [engine] detaches: its sink goes, and the session if it owns it.
     *  Dart calls `disable` on dispose, but an engine destroyed with the
     *  process still running (Back on the root route, a swipe from the
     *  recent apps) never disposes: its players stop on their own
     *  (`OwnerWatch` on the Dart side), and the session goes here. The
     *  session of another engine stays, and the application context serves
     *  them all. */
    fun detach(engine: Any) {
        if (engines.onDetach(engine) && enabled) disable()
    }

    // ── Method channel (Dart → native), per engine ──────────────────────

    fun onMethodCall(engine: Any, call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "enable" -> {
                    // The arguments first: a call that cannot be read must
                    // not take the session.
                    val a = call.arguments as Map<*, *>
                    val config = a["config"] as Map<*, *>
                    val metadata = a["metadata"] as Map<*, *>
                    val playback = a["playback"] as Map<*, *>
                    val ownedBefore = engines.mayUpdate(engine)
                    if (!engines.tryEnable(engine)) {
                        // Dart throws a MediaSessionException and leaves its state off.
                        result.error(
                            "already_owned",
                            "Another Flutter engine of this process owns the media session.",
                            null,
                        )
                        return
                    }
                    try {
                        enable(config, metadata, playback)
                    } catch (e: Exception) {
                        // Dart hears the error below and keeps its state
                        // off: an engine that took the session with this
                        // enable gives it back, or every other engine
                        // would be refused for a session nobody has.
                        if (engines.onEnableFailed(engine, ownedBefore)) {
                            runCatching { disable() }
                        }
                        throw e
                    }
                    result.success(null)
                }
                // Only the owner's: another engine's Player never had the session.
                "updateConfig" -> {
                    if (engines.mayUpdate(engine)) updateConfig(call.arguments as Map<*, *>)
                    result.success(null)
                }
                "updateMetadata" -> {
                    if (engines.mayUpdate(engine)) updateMetadata(call.arguments as Map<*, *>)
                    result.success(null)
                }
                "updatePlayback" -> {
                    if (engines.mayUpdate(engine)) updatePlayback(call.arguments as Map<*, *>)
                    result.success(null)
                }
                "disable" -> {
                    // Only the owner's: another engine's Player never had it.
                    if (engines.mayDisable(engine)) disable()
                    result.success(null)
                }
                "debugMediaSessionState" -> result.success(debugState())
                "debugForegroundServiceTimeoutMs" -> {
                    val debuggable = appContext?.applicationInfo?.flags?.let {
                        it and ApplicationInfo.FLAG_DEBUGGABLE != 0
                    } == true
                    if (debuggable) {
                        debugForegroundServiceTimeoutMs = (call.arguments as Number).toLong()
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("MEDIA_SESSION_ERROR", e.message, null)
        }
    }

    // ── Event channel (native → Dart), per engine ───────────────────────

    fun onListen(engine: Any, events: EventChannel.EventSink) {
        engines.onListen(engine, events)
    }

    fun onCancel(engine: Any) {
        engines.onCancel(engine)
    }

    /** A pause from a controller: disarm the resume of a call before the
     *  pause goes to Dart, which is already paused then. */
    fun disarmResume() = runOnMain {
        audioFocus?.disarm()
    }

    /** Forwards an OS remote command to the owner's Dart, on the platform
     *  thread. */
    fun forwardCommand(command: Map<String, Any?>) = runOnMain {
        engines.commandSink()?.success(command)
    }

    /** A scrub from the OS slider: pin the slider at the drop target
     *  (republish), then forward the absolute seek. The freeze clears in
     *  [updatePlayback] once the landed position confirms, on a new track
     *  in [updateMetadata], or at the backstop. */
    fun onScrub(positionMs: Long) = runOnMain {
        val generation = scrub.start(positionMs, trackOf(metadata))
        player?.republish()
        engines.commandSink()?.success(mapOf("type" to "seekTo", "positionMs" to positionMs))
        mainHandler.postDelayed({
            if (scrub.expire(generation) && enabled) publish()
        }, ScrubFreeze.BACKSTOP_MS)
    }

    /** What tells one track from the next for the scrub freeze: Dart pushes
     *  the metadata of a new track once it has loaded. */
    private fun trackOf(m: MetadataSnapshot): Any = Pair(m.title, m.durationMs)

    // ── Snapshot mutations ──────────────────────────────────────────────

    private fun enable(config: Map<*, *>, metadata: Map<*, *>, playback: Map<*, *>) = runOnMain {
        this.config = parseConfig(config)
        this.metadata = parseMetadata(metadata)
        this.playback = parsePlayback(playback)
        scrub.clear()
        enabled = true
        ensureSessionCreated()
        // A new session starts from a clean audio focus. An enable with no
        // disable before it (a Hot Restart whose disable never arrived)
        // would keep the old latch and play intent, and the next focus gain
        // would start the new player on its own.
        val handover = focusReleasePending
        if (handover != null) {
            mainHandler.removeCallbacks(handover)
            focusReleasePending = null
            audioFocus?.onNewSession()
        } else {
            audioFocus?.release()
            audioFocus = null
        }
        ensureAudioFocus()
        startService()
        publish()
        // Take audio focus + arm the headphone-unplug receiver if we're
        // already playing at enable time. The count of the app's pauses
        // starts here.
        audioFocus?.onPlayback(this.playback.playing, this.playback.appPauses)
    }

    private fun updateConfig(config: Map<*, *>) = runOnMain {
        val oldPolicy = this.config.interruptionPolicy
        this.config = parseConfig(config)
        publish()
        // LOOPER PATCH: e.g. "Manage Audio Focus" toggled mid-song.
        if (enabled && oldPolicy != this.config.interruptionPolicy) audioFocus?.onPolicyChanged()
    }

    private fun updateMetadata(metadata: Map<*, *>) = runOnMain {
        this.metadata = parseMetadata(metadata)
        // A scrub made on the previous track will never land on this one.
        scrub.onTrack(trackOf(this.metadata))
        publish()
    }

    private fun updatePlayback(playback: Map<*, *>) = runOnMain {
        val pb = parsePlayback(playback)
        this.playback = pb
        // The slider tracks playback again once Dart confirms the landed
        // position; a stale push mid-seek keeps it pinned.
        scrub.onPlayback(pb.positionMs)
        publish()
        // Acquire focus when playback starts (idempotent while held); focus is
        // held across a user pause and released only on disable. On pause, drop
        // the becoming-noisy receiver but keep focus. A pause or a stop of the
        // app disarms the resume of a call.
        audioFocus?.onPlayback(pb.playing, pb.appPauses)
    }

    private fun disable() = runOnMain {
        enabled = false
        engines.onDisabled()
        handoverPolicy = config.interruptionPolicy
        audioFocus?.let { focus ->
            focusReleasePending?.let { mainHandler.removeCallbacks(it) }
            val release = Runnable {
                focusReleasePending = null
                if (!enabled && audioFocus === focus) {
                    focus.release()
                    audioFocus = null
                }
            }
            focusReleasePending = release
            mainHandler.postDelayed(release, FOCUS_HANDOVER_MS)
        }
        config = ConfigSnapshot.EMPTY
        metadata = MetadataSnapshot.EMPTY
        playback = PlaybackSnapshot.EMPTY
        scrub.clear()
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
        activityKeys.onSession(null)
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
            session = builder.build().also { activityKeys.onSession(it.platformToken) }
        }
    }

    /** The activity of the engine [engine], in front: see [ActivityMediaKeys]. */
    fun attachActivity(engine: Any, activity: Activity) {
        activityKeys.attach(engine, object : ActivityMediaKeys.Window<android.media.session.MediaSession.Token> {
            override fun current() = activity.mediaController?.sessionToken
            override fun set(token: android.media.session.MediaSession.Token?) {
                activity.mediaController = token?.let { android.media.session.MediaController(activity, it) }
            }
        })
    }

    /** The activity of the engine [engine] went. */
    fun detachActivity(engine: Any) = activityKeys.detach(engine)

    /** Resolved by [MpvMediaSessionService.onGetSession]. */
    fun currentSession(): MediaSession? = session

    private fun ensureAudioFocus() {
        val ctx = appContext ?: return
        if (audioFocus == null) {
            val port = AndroidFocusPort(ctx, mainHandler)
            audioFocus = AudioFocusController(
                port = port,
                policy = { if (enabled) config.interruptionPolicy else handoverPolicy },
                emit = { cmd -> forwardCommand(cmd) },
                onResumeArmedChanged = { if (enabled) player?.republish() },
            ).also { port.target = it }
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
                "suppressed" to false,
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
        isFavorite = map["isFavorite"] as? Boolean ?: false,
    )

    private fun parseMetadata(map: Map<*, *>) = MetadataSnapshot(
        title = map["title"] as? String,
        artist = map["artist"] as? String,
        album = map["album"] as? String,
        artworkBytes = map["artworkBytes"] as? ByteArray,
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
        appPauses = (map["appPauses"] as? Number)?.toLong() ?: 0,
    )

    private fun runOnMain(block: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            block()
        } else {
            mainHandler.post(block)
        }
    }
}
