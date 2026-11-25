/*
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.alesdrnz.mpv_audio_kit.media_session

import androidx.media3.common.Player

/**
 * The play intent the session publishes, kept free of Android types so it
 * runs on the plain JVM (see `PublishedIntentTest`).
 *
 * A transient focus loss (a call, an alarm) pauses the player and arms the
 * resume for the next gain. The session then publishes `playWhenReady`
 * with the suppression reason of a transient focus loss instead of a
 * pause. Media3 keeps a session with `playWhenReady`
 * "user engaged", so the service stays in the foreground through the
 * whole call. Published as paused, it left the foreground after Media3's
 * timeout (10 minutes), and on Android 12 and later the play at the end
 * of the call could not bring it back (F172). Controllers still show the
 * play button: Media3 draws a suppressed session as paused.
 */
internal data class PublishedIntent(val playWhenReady: Boolean, val suppressionReason: Int) {
    companion object {
        /** From Dart's play intent ([playing]) and the focus latch. */
        fun of(playing: Boolean, resumeArmed: Boolean): PublishedIntent = when {
            playing -> PublishedIntent(true, Player.PLAYBACK_SUPPRESSION_REASON_NONE)
            resumeArmed -> PublishedIntent(
                true,
                Player.PLAYBACK_SUPPRESSION_REASON_TRANSIENT_AUDIO_FOCUS_LOSS,
            )
            else -> PublishedIntent(false, Player.PLAYBACK_SUPPRESSION_REASON_NONE)
        }
    }
}
