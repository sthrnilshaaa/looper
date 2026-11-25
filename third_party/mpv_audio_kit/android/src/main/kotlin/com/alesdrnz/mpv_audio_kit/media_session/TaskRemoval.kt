/*
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.alesdrnz.mpv_audio_kit.media_session

/**
 * What a swipe of the app from the recent apps does to the media service,
 * kept free of Android types so it runs on the plain JVM (see
 * `TaskRemovalTest`).
 *
 * Whether playback outlives the task is the engine's call. An engine the
 * app keeps alive (cached, or run by a service) keeps its players, and the
 * service stays while they play. An engine that goes with the activity
 * stops its players itself (`OwnerWatch` on the Dart side), and its detach
 * turns the session off, which stops the service anyway.
 */
internal object TaskRemoval {

    /**
     * Runs [mediaDefault], Media3's own handling (pause every player, stop
     * the service), unless the session plays or is about to. Media3 checks
     * `isPlaying`, which is false while a file loads: alone, it would pause
     * a track change.
     */
    fun onTaskRemoved(playWhenReady: Boolean, mediaItemCount: Int, mediaDefault: () -> Unit) {
        if (playWhenReady && mediaItemCount > 0) return
        mediaDefault()
    }
}
