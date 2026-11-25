/*
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.alesdrnz.mpv_audio_kit.media_session

/**
 * Points the media controller of each activity in front at the session,
 * kept free of Android types so it runs on the plain JVM (see
 * `ActivityMediaKeysTest`).
 *
 * A media key of a remote or a headset goes to the window in front first.
 * Flutter hands back the keys the app does not use, and the window passes
 * them to the media controller of its activity. Without one, Android 9 and
 * later send them to the media sessions themselves, but Android 7 and 8
 * (Fire OS 6 and 7 among them) drop them: play, pause, next and previous
 * from the remote never reached the player there. The activity's
 * controller makes every version hand the keys to the session, once.
 *
 * Each engine attaches the activity it runs in, and every one gets the
 * session: the engine that plays may not be the one in front. A
 * controller the app set itself stays as it is.
 */
internal class ActivityMediaKeys<T : Any> {

    /** The media controller of an activity, by the token it points at. */
    interface Window<T> {
        /** The token the activity's controller points at, `null` without one. */
        fun current(): T?

        /** Points the activity's controller at [token], or drops it. */
        fun set(token: T?)
    }

    private val windows = LinkedHashMap<Any, Window<T>>()
    private var token: T? = null

    /** The activity of the engine [key], in front. */
    fun attach(key: Any, window: Window<T>) {
        windows[key] = window
        val t = token ?: return
        if (window.current() == null) window.set(t)
    }

    /** The activity of the engine [key] went: it drops the controller it got. */
    fun detach(key: Any) {
        val window = windows.remove(key) ?: return
        val t = token ?: return
        if (window.current() == t) window.set(null)
    }

    /** The session's token, `null` once it is released. */
    fun onSession(next: T?) {
        val previous = token
        token = next
        for (window in windows.values) {
            val current = window.current()
            if (current == null || current == previous) window.set(next)
        }
    }
}
