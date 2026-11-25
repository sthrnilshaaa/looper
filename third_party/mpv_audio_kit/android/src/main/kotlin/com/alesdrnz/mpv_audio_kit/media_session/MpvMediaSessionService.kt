/*
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.alesdrnz.mpv_audio_kit.media_session

import android.content.Intent
import android.util.Log
import androidx.media3.common.util.UnstableApi
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService

/**
 * Hosts the Media3 session so the now-playing notification and
 * lock-screen / Android-11+ media controls appear and the service can
 * auto-promote to the foreground (type `mediaPlayback`) while playing.
 *
 * The service owns no state and creates no player: the single session is
 * owned by [MediaSessionManager] (created on `enable`). The service just
 * vends it to connecting controllers (System UI, Bluetooth, Auto). This
 * keeps the session lifecycle tied to Dart's `setMediaSession`, not to
 * Media3's service-creation schedule.
 */
@UnstableApi
internal class MpvMediaSessionService : MediaSessionService() {

    override fun onCreate() {
        super.onCreate()
        // A play started from the background, the end of a long call on
        // Android 12 and later, may not bring the service back to the
        // foreground. Pause then, instead of playing in a process Android
        // may freeze or kill.
        setListener(object : Listener {
            override fun onForegroundServiceStartNotAllowedException() {
                Log.w(TAG, "The media session cannot enter the foreground: pausing.")
                MediaSessionManager.forwardCommand(mapOf("type" to "pause"))
            }
        })
        MediaSessionManager.debugForegroundServiceTimeoutMs?.let {
            setForegroundServiceTimeoutMs(it)
        }
    }

    override fun onGetSession(controllerInfo: MediaSession.ControllerInfo): MediaSession? =
        MediaSessionManager.currentSession()

    override fun onTaskRemoved(rootIntent: Intent?) {
        // An engine that goes with the task turns the session off on its
        // detach. One that outlives it keeps playing: the service stays
        // while the session plays, also through a load (see [TaskRemoval]).
        val player = MediaSessionManager.currentSession()?.player
        TaskRemoval.onTaskRemoved(
            playWhenReady = player?.playWhenReady == true,
            mediaItemCount = player?.mediaItemCount ?: 0,
        ) { super.onTaskRemoved(rootIntent) }
    }

    override fun onDestroy() {
        // The manager owns the session — it releases it in `disable`. The
        // service only drops its reference by being destroyed; it must not
        // double-release.
        clearListener()
        super.onDestroy()
    }

    private companion object {
        const val TAG = "mpv_audio_kit"
    }
}
