/*
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.alesdrnz.mpv_audio_kit.media_session

import java.util.IdentityHashMap

/**
 * Which Flutter engine owns the process-wide media session, and the command
 * sink of each engine, kept free of Android types so it runs on the plain
 * JVM (see `EngineOwnershipTest`). An engine is any token unique to it (the
 * plugin instance attached to it), [S] the type of its sink.
 *
 * An app can run more engines than the one that plays: a workmanager task
 * builds one per task and destroys it at the end, add-to-app keeps several.
 * The first engine to enable owns the session until it disables or
 * detaches. Another engine's enable is refused, and its updates, disable
 * and detach change nothing. OS commands go to the owner's sink, whichever
 * engine listened last. A Hot Restart keeps the engine, so its new VM's
 * calls are the owner's. Apple, Windows and Linux follow the same rule.
 */
internal class EngineOwnership<S : Any> {

    private val sinks = IdentityHashMap<Any, S>()
    private var owner: Any? = null

    /** [engine] listened for commands on [sink]. */
    fun onListen(engine: Any, sink: S) {
        sinks[engine] = sink
    }

    /** [engine] cancelled: its sink goes. */
    fun onCancel(engine: Any) {
        sinks.remove(engine)
    }

    /** [engine] asks to enable the session. Refused, with nothing changed,
     *  while another engine owns it. */
    fun tryEnable(engine: Any): Boolean {
        if (owner != null && owner !== engine) return false
        owner = engine
        return true
    }

    /** The enable [tryEnable] accepted for [engine] failed. [ownedBefore] is
     *  whether [engine] owned the session before that enable ([mayUpdate],
     *  read before [tryEnable]). An engine that took the session with this
     *  enable gives it back, and the caller turns off what it built: true.
     *  An owner whose new enable failed keeps the session it had: false. */
    fun onEnableFailed(engine: Any, ownedBefore: Boolean): Boolean {
        if (ownedBefore || owner !== engine) return false
        owner = null
        return true
    }

    /** Whether an update from [engine] reaches the session: only the owner's. */
    fun mayUpdate(engine: Any): Boolean = owner === engine

    /** Whether a disable from [engine] turns the session off: the owner's
     *  does, and any does while nobody owns it (a no-op then). */
    fun mayDisable(engine: Any): Boolean = owner == null || owner === engine

    /** The session went off. */
    fun onDisabled() {
        owner = null
    }

    /** [engine] detached: its sink goes. Returns whether it owned the
     *  session, which the caller then turns off. */
    fun onDetach(engine: Any): Boolean {
        sinks.remove(engine)
        if (owner !== engine) return false
        owner = null
        return true
    }

    /** Where an OS command goes: the owner's sink, or nowhere. */
    fun commandSink(): S? = owner?.let { sinks[it] }
}
