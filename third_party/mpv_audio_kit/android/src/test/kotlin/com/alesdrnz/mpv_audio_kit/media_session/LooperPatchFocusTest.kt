package com.alesdrnz.mpv_audio_kit.media_session

import android.media.AudioManager
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/** The LOOPER PATCH changes of [AudioFocusController] (see LOOPER_PATCH.md). */
class LooperPatchFocusTest {
    private class FakePort : FocusPort {
        var requests = 0
        var abandons = 0
        var result = AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        override fun requestFocus(): Int { requests++; return result }
        override fun abandonFocus() { abandons++ }
        override fun listenNoisy(on: Boolean) {}
    }

    private val port = FakePort()
    private var policy = "pauseAndResume"
    private val commands = mutableListOf<Any?>()
    private val focus = AudioFocusController(port, { policy }, { commands.add(it["type"]) })

    @Test
    fun keepPlayingNeverRequestsFocus() {
        policy = "keepPlaying"
        focus.onPlayback(true, 0)
        assertEquals(0, port.requests)
        focus.onFocusChange(AudioManager.AUDIOFOCUS_LOSS)
        focus.onPlayback(false, 0)
        focus.onPlayback(true, 0)
        assertEquals(0, port.requests)
        assertTrue(commands.isEmpty())
    }

    @Test
    fun switchingToKeepPlayingDropsHeldFocusAndBack() {
        focus.onPlayback(true, 0)
        assertEquals(1, port.requests)
        policy = "keepPlaying"
        focus.onPolicyChanged()
        assertEquals(1, port.abandons)
        policy = "pauseAndResume"
        focus.onPolicyChanged()
        assertEquals(2, port.requests)
    }

    @Test
    fun callRightAfterNoisyPauseStillResumes() {
        focus.onPlayback(true, 0)
        focus.onBecomingNoisy() // Bluetooth route moves for the call
        focus.onPlayback(false, 0) // the plugin's own pause, not the app's
        focus.onFocusChange(AudioManager.AUDIOFOCUS_LOSS_TRANSIENT)
        assertTrue(focus.resumeArmed)
        focus.onFocusChange(AudioManager.AUDIOFOCUS_GAIN)
        assertEquals("play", commands.last())
    }

    @Test
    fun plainUnplugThenLaterCallDoesNotResume() {
        focus.onPlayback(true, 0)
        focus.onBecomingNoisy()
        focus.onPlayback(false, 0)
        focus.onFocusChange(AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK)
        focus.onPlayback(false, 1) // user pause in between
        focus.onFocusChange(AudioManager.AUDIOFOCUS_LOSS_TRANSIENT)
        assertFalse(focus.resumeArmed)
    }

    @Test
    fun appPauseCountRestartsOnNewSession() {
        focus.onPlayback(true, 5)
        focus.onFocusChange(AudioManager.AUDIOFOCUS_LOSS_TRANSIENT)
        focus.onPlayback(false, 5)
        assertTrue(focus.resumeArmed)
        focus.onNewSession() // crossfade hand-over: Dart's count is 0 again
        focus.onPlayback(false, 0)
        assertTrue(focus.resumeArmed)
    }
}
