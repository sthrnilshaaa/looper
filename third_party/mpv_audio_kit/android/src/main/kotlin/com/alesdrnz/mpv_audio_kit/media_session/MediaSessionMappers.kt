/*
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.alesdrnz.mpv_audio_kit.media_session

import android.net.Uri
import android.os.Bundle
import androidx.media3.common.MediaMetadata
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.session.CommandButton
import androidx.media3.session.SessionCommand

/**
 * Pure, stateless translation between the Dart wire contract and the
 * *public* Media3 types. Anything touching `SimpleBasePlayer`'s protected
 * surface (`MediaItemData`, `getState`, `invalidateState`) must live
 * inside [MpvControllerPlayer] instead — that's why playlist construction
 * is there, not here.
 */
@UnstableApi
internal object MediaSessionMappers {

    /**
     * Custom session-command action for the favourite (heart) button. `like`
     * has no Media3 player command, so it ships as a [SessionCommand] the
     * session advertises in `onConnect` and handles in `onCustomCommand`,
     * forwarding the same `{type: "like"}` wire event the Dart side decodes.
     */
    const val LIKE_ACTION = "com.alesdrnz.mpv_audio_kit.LIKE"

    /** Wire loop string → Media3 repeat-mode constant. */
    fun loopToRepeatMode(loop: String): Int = when (loop) {
        "file" -> Player.REPEAT_MODE_ONE
        "playlist" -> Player.REPEAT_MODE_ALL
        else -> Player.REPEAT_MODE_OFF
    }

    /** Media3 repeat-mode constant → wire loop string. */
    fun repeatModeToLoop(repeatMode: Int): String = when (repeatMode) {
        Player.REPEAT_MODE_ONE -> "file"
        Player.REPEAT_MODE_ALL -> "playlist"
        else -> "off"
    }

    /**
     * Builds the command set advertised to the OS from the Dart [actions]
     * set, gated on [seekable] for the scrubber. The OS shows only the
     * buttons it has UI space for, but offers the wider set to Auto /
     * Assistant. The `GET_*` reads let controllers (System UI, Auto) read
     * timeline + metadata.
     */
    fun buildCommands(actions: Set<String>, seekable: Boolean): Player.Commands {
        val b = Player.Commands.Builder()
        b.add(Player.COMMAND_GET_CURRENT_MEDIA_ITEM)
        b.add(Player.COMMAND_GET_TIMELINE)
        b.add(Player.COMMAND_GET_METADATA)
        // Must be advertised or SimpleBasePlayer.release() early-returns
        // without tearing down listeners (leaks across enable/disable cycles).
        b.add(Player.COMMAND_RELEASE)
        if ("play" in actions || "pause" in actions || "playPause" in actions) {
            b.add(Player.COMMAND_PLAY_PAUSE)
        }
        if ("stop" in actions) b.add(Player.COMMAND_STOP)
        if ("seek" in actions && seekable) {
            b.add(Player.COMMAND_SEEK_IN_CURRENT_MEDIA_ITEM)
            b.add(Player.COMMAND_SEEK_TO_DEFAULT_POSITION)
        }
        // Both forms: media keys and the notification buttons call
        // seekToNext() / seekToPrevious(), which SimpleBasePlayer drops
        // unless COMMAND_SEEK_TO_NEXT / COMMAND_SEEK_TO_PREVIOUS is
        // available, while controllers may use the MEDIA_ITEM forms.
        if ("next" in actions) {
            b.add(Player.COMMAND_SEEK_TO_NEXT_MEDIA_ITEM)
            b.add(Player.COMMAND_SEEK_TO_NEXT)
        }
        if ("previous" in actions) {
            b.add(Player.COMMAND_SEEK_TO_PREVIOUS_MEDIA_ITEM)
            b.add(Player.COMMAND_SEEK_TO_PREVIOUS)
        }
        if ("fastForward" in actions) b.add(Player.COMMAND_SEEK_FORWARD)
        if ("rewind" in actions) b.add(Player.COMMAND_SEEK_BACK)
        if ("setRepeatMode" in actions) b.add(Player.COMMAND_SET_REPEAT_MODE)
        if ("setShuffle" in actions) b.add(Player.COMMAND_SET_SHUFFLE_MODE)
        if ("setPlaybackRate" in actions) b.add(Player.COMMAND_SET_SPEED_AND_PITCH)
        return b.build()
    }

    /**
     * Builds the notification button row from the advertised actions. The
     * `DefaultMediaNotificationProvider` only auto-draws play/pause + prev/next
     * + the seek bar; everything else needs an explicit [CommandButton] in the
     * session's media button preferences.
     *
     * Rewind / fast-forward / repeat / shuffle ride on a *player* command, so
     * Media3 executes them with no custom handling — they route straight to the
     * matching `handleX` on [MpvControllerPlayer], which forwards to Dart.
     * `setRepeatMode` carries the *next* mode as the button parameter (the
     * command is a no-op without one); `setShuffle` carries the target boolean.
     * Each toggle's icon reflects the *current* state, so the caller must
     * rebuild and re-publish whenever the loop / shuffle / favourite state
     * changes (see [MediaSessionManager.publish]).
     *
     * `like` has no player command — it's a custom [SessionCommand]; the heart
     * fills/empties from [ConfigSnapshot.isFavorite].
     */
    fun buildMediaButtonPreferences(
        config: MediaSessionManager.ConfigSnapshot,
        playback: MediaSessionManager.PlaybackSnapshot,
    ): List<CommandButton> {
        val buttons = mutableListOf<CommandButton>()

        // Build in the consumer's advertised order (preserved end-to-end as a
        // LinkedHashSet from the Dart `actions`). Android renders only a few
        // media-button slots, so the order IS the priority: whichever buttons
        // come first win the visible slots and the rest overflow. Non-custom
        // actions (play/pause/next/previous/seek/stop/rate) aren't buttons here.
        for (action in config.actions) {
            val button = when (action) {
                "rewind" ->
                    CommandButton.Builder(CommandButton.ICON_REWIND)
                        .setDisplayName("Rewind")
                        .setPlayerCommand(Player.COMMAND_SEEK_BACK)
                        .build()
                "fastForward" ->
                    CommandButton.Builder(CommandButton.ICON_FAST_FORWARD)
                        .setDisplayName("Fast forward")
                        .setPlayerCommand(Player.COMMAND_SEEK_FORWARD)
                        .build()
                "setRepeatMode" -> {
                    // Icon = current mode; parameter = next in the off → all → one cycle.
                    val (icon, next) = when (playback.loop) {
                        "playlist" -> CommandButton.ICON_REPEAT_ALL to Player.REPEAT_MODE_ONE
                        "file" -> CommandButton.ICON_REPEAT_ONE to Player.REPEAT_MODE_OFF
                        else -> CommandButton.ICON_REPEAT_OFF to Player.REPEAT_MODE_ALL
                    }
                    CommandButton.Builder(icon)
                        .setDisplayName("Repeat")
                        .setPlayerCommand(Player.COMMAND_SET_REPEAT_MODE, next)
                        .build()
                }
                "setShuffle" -> {
                    val icon =
                        if (playback.shuffle) CommandButton.ICON_SHUFFLE_ON else CommandButton.ICON_SHUFFLE_OFF
                    CommandButton.Builder(icon)
                        .setDisplayName("Shuffle")
                        .setPlayerCommand(Player.COMMAND_SET_SHUFFLE_MODE, !playback.shuffle)
                        .build()
                }
                "like" -> {
                    val icon =
                        if (config.isFavorite) CommandButton.ICON_HEART_FILLED
                        else CommandButton.ICON_HEART_UNFILLED
                    CommandButton.Builder(icon)
                        .setDisplayName("Favorite")
                        .setSessionCommand(SessionCommand(LIKE_ACTION, Bundle.EMPTY))
                        .build()
                }
                else -> null
            }
            if (button != null) buttons.add(button)
        }
        return buttons
    }

    /** Resolved metadata snapshot → Media3 [MediaMetadata]. */
    fun toMediaMetadata(meta: MediaSessionManager.MetadataSnapshot): MediaMetadata {
        val b = MediaMetadata.Builder()
        meta.title?.let { b.setTitle(it) }
        meta.artist?.let { b.setArtist(it) }
        meta.album?.let { b.setAlbumTitle(it) }
        meta.albumArtist?.let { b.setAlbumArtist(it) }
        meta.genre?.let { b.setGenre(it) }
        meta.trackNumber?.let { b.setTrackNumber(it) }
        meta.discNumber?.let { b.setDiscNumber(it) }
        // Media3 takes raw encoded image bytes (JPEG/PNG) directly and
        // decodes them for the notification — no Bitmap conversion needed.
        // For a tag-less stream we instead hand it the artwork URL and let
        // Media3 load + cache it (a transcoded server track has no embedded
        // cover). Bytes win when both are present; they're mutually exclusive
        // off the wire anyway.
        when {
            meta.artworkBytes != null ->
                b.setArtworkData(meta.artworkBytes, MediaMetadata.PICTURE_TYPE_FRONT_COVER)
            meta.artworkUri != null -> b.setArtworkUri(Uri.parse(meta.artworkUri))
        }
        return b.build()
    }
}
