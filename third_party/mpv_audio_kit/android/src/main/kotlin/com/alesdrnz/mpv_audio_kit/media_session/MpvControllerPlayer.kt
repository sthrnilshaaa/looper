/*
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.alesdrnz.mpv_audio_kit.media_session

import android.os.Looper
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.PlaybackParameters
import androidx.media3.common.Player
import androidx.media3.common.SimpleBasePlayer
import androidx.media3.common.util.UnstableApi
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture

/**
 * A controller-only [SimpleBasePlayer]: it owns no audio engine. libmpv
 * decodes in-process; this adapter only mirrors the Dart-side state into
 * a Media3 [SimpleBasePlayer.State] (so the OS draws the now-playing
 * entry) and forwards transport commands back to Dart via
 * [MediaSessionManager.forwardCommand].
 *
 * Constructed on the main [Looper] — the same thread as Flutter's
 * platform channel — so the Dart `update*` calls mutate the manager's
 * snapshot and call [republish] with no thread hop, and the `handleX`
 * callbacks fire on that thread too (forwarding to the event sink is
 * therefore already on the platform thread).
 *
 * [getState] is a pure read of [MediaSessionManager]'s `@Volatile`
 * snapshot — the native side is a stateless renderer, all truth lives in
 * Dart. Note `getState` / `invalidateState` / `MediaItemData` are
 * protected in the superclass, so everything that touches them lives here
 * and is exposed to the manager via [republish] / [debugProbe].
 */
@UnstableApi
internal class MpvControllerPlayer(looper: Looper) : SimpleBasePlayer(looper) {

    private val mgr get() = MediaSessionManager

    // Cache the built MediaMetadata keyed by the snapshot identity, so a
    // playback-only tick (position/rate/seek) doesn't re-wrap title/artwork
    // into a fresh MediaMetadata on every getState. The manager replaces the
    // snapshot object only on updateMetadata, so reference identity is a sound
    // key.
    private var cachedMetaKey: MediaSessionManager.MetadataSnapshot? = null
    private var cachedMediaMetadata: MediaMetadata? = null

    /** Re-poll [getState] and notify listeners. Public wrapper around the
     *  protected `invalidateState`, called by the manager on each push. */
    fun republish() = invalidateState()

    override fun getState(): State {
        if (!mgr.enabled) return idleState(playWhenReady = false)

        val cfg = mgr.config
        val meta = mgr.metadata
        val pb = mgr.playback

        val title = meta.title?.takeIf { it.isNotEmpty() }
        // No content yet → stay idle so the foreground service / notification
        // doesn't surface a blank entry (parity with the Apple "no
        // content-less publish" guard). Audio that is playing or loading is
        // content even without a title: going idle then would drop the
        // notification and with it the foreground service keeping playback
        // alive in the background.
        if (title == null && !pb.playing && !pb.buffering) {
            return idleState(playWhenReady = false)
        }

        val mediaMetadata = if (meta === cachedMetaKey && cachedMediaMetadata != null) {
            cachedMediaMetadata!!
        } else {
            MediaSessionMappers.toMediaMetadata(meta).also {
                cachedMetaKey = meta
                cachedMediaMetadata = it
            }
        }
        val wantsNextPrev =
            cfg.actions.contains("next") || cfg.actions.contains("previous")
        // Include a prev/next placeholder only when navigation is actually
        // available, so Media3 greys the skip buttons out at playlist bounds.
        // A single item / external queue keeps both (hasNext/Prev=true).
        val showPrev = wantsNextPrev && cfg.actions.contains("previous") && pb.hasPrevious
        val showNext = wantsNextPrev && cfg.actions.contains("next") && pb.hasNext
        val items = buildPlaylist(meta, mediaMetadata, pb.seekable, showPrev, showNext)
        val currentIndex = if (showPrev) 1 else 0
        // While a scrub is in flight the slider pins at the drop target
        // until Dart confirms the landed position (see MediaSessionManager).
        val positionMs = mgr.scrubFreezeMs ?: pb.positionMs

        return State.Builder()
            .setAvailableCommands(
                MediaSessionMappers.buildCommands(cfg.actions, pb.seekable),
            )
            // STATE_ENDED at true end-of-content (Dart's eof-reached) so the OS
            // parks the scrubber at duration and renders a finished track;
            // STATE_BUFFERING while loading so the OS shows a spinner. Falling
            // edges are re-published Dart-side as READY.
            .setPlaybackState(
                when {
                    pb.completed -> Player.STATE_ENDED
                    pb.buffering -> Player.STATE_BUFFERING
                    else -> Player.STATE_READY
                },
            )
            // The INTENT axis: playWhenReady binds to `playing`
            // (playWhenReady Dart-side), which is stable across seeks.
            // Never re-derive it from anything else.
            .setPlayWhenReady(
                pb.playing,
                Player.PLAY_WHEN_READY_CHANGE_REASON_USER_REQUEST,
            )
            // Speed drives the OS position extrapolation while playing;
            // clamp away from zero (mpv reports the configured speed even
            // when paused, but a 0 speed is invalid here).
            .setPlaybackParameters(
                PlaybackParameters(pb.rate.toFloat().coerceAtLeast(0.01f)),
            )
            .setRepeatMode(MediaSessionMappers.loopToRepeatMode(pb.loop))
            .setShuffleModeEnabled(pb.shuffle)
            .setPlaylist(items)
            .setCurrentMediaItemIndex(currentIndex)
            // Extrapolate the scrub position from this anchor while audio is
            // genuinely advancing (not paused / buffering / scrub-frozen), so
            // the OS notification seek bar moves smoothly between pushes instead
            // of freezing on a constant value. A constant supplier holds it
            // pinned otherwise.
            .setContentPositionMs(
                if (pb.actualPlaying && mgr.scrubFreezeMs == null) {
                    SimpleBasePlayer.PositionSupplier.getExtrapolating(
                        positionMs,
                        pb.rate.toFloat().coerceAtLeast(0.01f),
                    )
                } else {
                    SimpleBasePlayer.PositionSupplier.getConstant(positionMs)
                },
            )
            .setSeekBackIncrementMs(cfg.rewindIntervalMs)
            .setSeekForwardIncrementMs(cfg.fastForwardIntervalMs)
            .build()
    }

    private fun idleState(playWhenReady: Boolean): State =
        State.Builder()
            // COMMAND_RELEASE even while idle, so release() actually tears
            // down listeners instead of early-returning.
            .setAvailableCommands(
                Player.Commands.Builder().add(Player.COMMAND_RELEASE).build(),
            )
            .setPlaybackState(Player.STATE_IDLE)
            .setPlayWhenReady(
                playWhenReady,
                Player.PLAY_WHEN_READY_CHANGE_REASON_USER_REQUEST,
            )
            .build()

    /**
     * Builds the State playlist. When the consumer advertises next /
     * previous, the timeline must carry adjacent items or Media3 greys the
     * buttons out — so we synthesise a 3-item window `[prev, current,
     * next]` with the real metadata on the current (index 1). The
     * placeholders are never shown (the OS renders the current item); the
     * real track change is driven by Dart, which re-publishes fresh
     * metadata. Without next/prev, a single item.
     */
    private fun buildPlaylist(
        meta: MediaSessionManager.MetadataSnapshot,
        mediaMetadata: MediaMetadata,
        seekable: Boolean,
        showPrev: Boolean,
        showNext: Boolean,
    ): List<MediaItemData> {
        val durationUs =
            meta.durationMs?.takeIf { it > 0 }?.let { it * 1000L } ?: C.TIME_UNSET

        val current = MediaItemData.Builder("mpv-current")
            .setMediaItem(MediaItem.Builder().setMediaId("mpv-current").build())
            .setMediaMetadata(mediaMetadata)
            .setDurationUs(durationUs)
            .setIsSeekable(seekable)
            .build()

        val items = mutableListOf<MediaItemData>()
        if (showPrev) items.add(placeholder("mpv-prev"))
        items.add(current)
        if (showNext) items.add(placeholder("mpv-next"))
        return items
    }

    private fun placeholder(uid: String): MediaItemData =
        MediaItemData.Builder(uid)
            .setMediaItem(MediaItem.Builder().setMediaId(uid).build())
            .setIsSeekable(false)
            .build()

    /**
     * Reads back the real published State as a primitive map for the
     * integration-test probe. Lives here because it reads the protected
     * [getState]; position / duration / artwork come from the manager's
     * snapshot (not surfaced on State in a readable form).
     */
    fun debugProbe(publishCount: Int): Map<String, Any?> {
        val st = getState()
        val item = st.playlist.getOrNull(st.currentMediaItemIndex)
        val mm = item?.mediaMetadata
        val playbackState = when {
            st.playbackState == Player.STATE_IDLE -> "stopped"
            st.playbackState == Player.STATE_ENDED -> "completed"
            st.playbackState == Player.STATE_BUFFERING -> "buffering"
            st.playWhenReady -> "playing"
            else -> "paused"
        }
        return mapOf(
            "publishCount" to publishCount,
            "playbackState" to playbackState,
            "title" to mm?.title?.toString(),
            "artist" to mm?.artist?.toString(),
            "album" to mm?.albumTitle?.toString(),
            "durationMs" to mgr.metadata.durationMs,
            "positionMs" to (mgr.scrubFreezeMs ?: mgr.playback.positionMs),
            "rate" to st.playbackParameters.speed.toDouble(),
            "hasArtwork" to
                (mgr.metadata.artworkBytes != null || mgr.metadata.artworkUri != null),
            "seekable" to st.availableCommands
                .contains(Player.COMMAND_SEEK_IN_CURRENT_MEDIA_ITEM),
            "loop" to MediaSessionMappers.repeatModeToLoop(st.repeatMode),
            "shuffle" to st.shuffleModeEnabled,
            "frozen" to (mgr.scrubFreezeMs != null),
        )
    }

    // ── Transport handlers — each forwards to Dart, applies nothing
    //    locally (Dart is the source of truth; the resulting update*
    //    re-publishes). The lone exception is the scrub freeze. ──────────

    override fun handleSetPlayWhenReady(playWhenReady: Boolean): ListenableFuture<*> {
        mgr.forwardCommand(mapOf("type" to if (playWhenReady) "play" else "pause"))
        return Futures.immediateVoidFuture()
    }

    override fun handleStop(): ListenableFuture<*> {
        mgr.forwardCommand(mapOf("type" to "stop"))
        return Futures.immediateVoidFuture()
    }

    override fun handleSeek(
        mediaItemIndex: Int,
        positionMs: Long,
        seekCommand: Int,
    ): ListenableFuture<*> {
        when (seekCommand) {
            Player.COMMAND_SEEK_TO_NEXT_MEDIA_ITEM,
            Player.COMMAND_SEEK_TO_NEXT,
            ->
                mgr.forwardCommand(mapOf("type" to "next"))

            Player.COMMAND_SEEK_TO_PREVIOUS_MEDIA_ITEM,
            Player.COMMAND_SEEK_TO_PREVIOUS,
            ->
                mgr.forwardCommand(mapOf("type" to "previous"))

            Player.COMMAND_SEEK_FORWARD ->
                mgr.forwardCommand(
                    mapOf("type" to "seekBy", "offsetMs" to mgr.config.fastForwardIntervalMs),
                )

            Player.COMMAND_SEEK_BACK ->
                mgr.forwardCommand(
                    mapOf("type" to "seekBy", "offsetMs" to -mgr.config.rewindIntervalMs),
                )

            else ->
                // SEEK_IN_CURRENT_MEDIA_ITEM / SEEK_TO_MEDIA_ITEM / default:
                // absolute scrub. Pin the slider, then forward.
                mgr.onScrub(positionMs)
        }
        return Futures.immediateVoidFuture()
    }

    override fun handleSetRepeatMode(repeatMode: Int): ListenableFuture<*> {
        mgr.forwardCommand(
            mapOf(
                "type" to "setRepeatMode",
                "loop" to MediaSessionMappers.repeatModeToLoop(repeatMode),
            ),
        )
        return Futures.immediateVoidFuture()
    }

    override fun handleSetShuffleModeEnabled(shuffleModeEnabled: Boolean): ListenableFuture<*> {
        mgr.forwardCommand(mapOf("type" to "setShuffle", "shuffle" to shuffleModeEnabled))
        return Futures.immediateVoidFuture()
    }

    override fun handleSetPlaybackParameters(
        playbackParameters: PlaybackParameters,
    ): ListenableFuture<*> {
        mgr.forwardCommand(
            mapOf("type" to "setPlaybackRate", "rate" to playbackParameters.speed.toDouble()),
        )
        return Futures.immediateVoidFuture()
    }

    override fun handleRelease(): ListenableFuture<*> = Futures.immediateVoidFuture()
}
