/*
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.alesdrnz.mpv_audio_kit.media_session

import android.content.Intent
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

    override fun onGetSession(controllerInfo: MediaSession.ControllerInfo): MediaSession? =
        MediaSessionManager.currentSession()

    override fun onTaskRemoved(rootIntent: Intent?) {
        // Playback is in-process and dies with the app, so swiping the app
        // away should clear the notification rather than linger.
        val session = MediaSessionManager.currentSession()
        val stillPlaying = session?.player?.playWhenReady == true &&
            session.player.mediaItemCount > 0
        if (!stillPlaying) {
            stopSelf()
        }
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        // The manager owns the session — it releases it in `disable`. The
        // service only drops its reference by being destroyed; it must not
        // double-release.
        super.onDestroy()
    }
}
