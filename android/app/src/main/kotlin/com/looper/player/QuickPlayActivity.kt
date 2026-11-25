package com.looper.player

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaMetadataRetriever
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.OpenableColumns
import android.util.Log
import android.view.View
import android.widget.ImageView
import android.widget.ProgressBar
import android.widget.TextView

/**
 * "Open with Looper" for an audio file from a file manager or any other app.
 * Plays it in a small floating card that looks like the Dial home-screen
 * widget, with Android's own MediaPlayer: the full app (mpv, queue, stats)
 * is never started. Closing the card stops playback.
 */
class QuickPlayActivity : Activity() {

    private var player: MediaPlayer? = null
    private var prepared = false
    private var focusRequest: AudioFocusRequest? = null
    private val handler = Handler(Looper.getMainLooper())

    private lateinit var artwork: ImageView
    private lateinit var title: TextView
    private lateinit var artist: TextView
    private lateinit var playPause: ImageView
    private lateinit var progress: ProgressBar

    private val tick = object : Runnable {
        override fun run() {
            updateProgress()
            handler.postDelayed(this, 500)
        }
    }

    private val audioManager by lazy { getSystemService(AUDIO_SERVICE) as AudioManager }

    // A call paused the preview: play on once it ends.
    private var resumeOnFocusGain = false

    // No CAN_DUCK case: since Android 8 the system ducks a request that
    // doesn't set willPauseWhenDucked, and never delivers that loss.
    private val focusListener = AudioManager.OnAudioFocusChangeListener { change ->
        when (change) {
            AudioManager.AUDIOFOCUS_LOSS -> {
                resumeOnFocusGain = false
                pause()
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                if (player?.isPlaying == true) resumeOnFocusGain = true
                pause()
            }
            AudioManager.AUDIOFOCUS_GAIN -> if (resumeOnFocusGain) {
                resumeOnFocusGain = false
                play()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Newer Android finishes activities with the activity transition,
        // not the window animation, so register the slide for both ways.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            overrideActivityTransition(OVERRIDE_TRANSITION_OPEN, R.anim.quick_play_enter, 0)
            overrideActivityTransition(OVERRIDE_TRANSITION_CLOSE, 0, R.anim.quick_play_exit)
        }
        setContentView(R.layout.activity_quick_play)
        artwork = findViewById(R.id.widget_artwork)
        title = findViewById(R.id.widget_title)
        artist = findViewById(R.id.widget_artist)
        playPause = findViewById(R.id.widget_play_pause)
        progress = findViewById(R.id.widget_progress)
        progress.max = 1000

        findViewById<View>(R.id.widget_play_pause_container).setOnClickListener { togglePlayPause() }
        // One file, no queue: prev / next skip back / ahead 10 s.
        findViewById<View>(R.id.widget_prev).setOnClickListener { seekBy(-10_000) }
        findViewById<View>(R.id.widget_next).setOnClickListener { seekBy(10_000) }

        open(intent)
    }

    override fun finish() {
        super.finish()
        // Slide down on close (back, tap outside, leaving); older Android.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            @Suppress("DEPRECATION")
            overridePendingTransition(0, R.anim.quick_play_exit)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        open(intent)
    }

    override fun onStop() {
        super.onStop()
        // Leaving the card (home, another app) ends it; the screen turning
        // off doesn't, so a song keeps playing on the lock screen.
        val power = getSystemService(POWER_SERVICE) as PowerManager
        if (power.isInteractive && !isChangingConfigurations) finish()
    }

    override fun onDestroy() {
        handler.removeCallbacks(tick)
        release()
        super.onDestroy()
    }

    private fun open(intent: Intent?) {
        val uri = intent?.data
        if (uri == null) {
            finish()
            return
        }
        release()
        showMetadata(uri)
        try {
            val mp = MediaPlayer()
            mp.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )
            mp.setDataSource(this, uri)
            mp.setOnPreparedListener {
                prepared = true
                play()
            }
            mp.setOnCompletionListener {
                updatePlayIcon()
                progress.progress = progress.max
                abandonFocus()
            }
            mp.setOnErrorListener { _, what, extra ->
                Log.e(TAG, "Playback error $what/$extra for $uri")
                finish()
                true
            }
            player = mp
            mp.prepareAsync()
        } catch (e: Exception) {
            Log.e(TAG, "Can't open $uri", e)
            finish()
        }
    }

    private fun showMetadata(uri: Uri) {
        var songTitle: String? = null
        var songArtist: String? = null
        var picture: Bitmap? = null
        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(this, uri)
            songTitle = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_TITLE)
            songArtist = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ARTIST)
            retriever.embeddedPicture?.let { bytes ->
                picture = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
            }
        } catch (e: Exception) {
            Log.w(TAG, "No metadata for $uri", e)
        } finally {
            try {
                retriever.release()
            } catch (_: Exception) {
            }
        }
        title.text = songTitle?.takeIf { it.isNotBlank() } ?: displayName(uri)
        artist.text = songArtist ?: ""
        artist.visibility = if (songArtist.isNullOrBlank()) View.GONE else View.VISIBLE
        artwork.setImageBitmap(
            PlayerWidgetProvider.renderArtwork(
                this,
                picture,
                PlayerWidgetProvider.ArtBox(156, 152, bottomScrim = true)
            )
        )
        progress.progress = 0
    }

    private fun displayName(uri: Uri): String {
        try {
            contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                ?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val name = cursor.getString(0)
                        if (!name.isNullOrBlank()) return name.substringBeforeLast('.')
                    }
                }
        } catch (_: Exception) {
        }
        return uri.lastPathSegment?.substringAfterLast('/')?.substringBeforeLast('.') ?: ""
    }

    private fun togglePlayPause() {
        val mp = player ?: return
        if (!prepared) return
        resumeOnFocusGain = false
        if (mp.isPlaying) pause() else play()
    }

    private fun play() {
        val mp = player ?: return
        if (!prepared || !requestFocus()) return
        mp.start()
        updatePlayIcon()
        handler.removeCallbacks(tick)
        handler.post(tick)
    }

    private fun pause() {
        val mp = player ?: return
        if (prepared && mp.isPlaying) mp.pause()
        updatePlayIcon()
        handler.removeCallbacks(tick)
        updateProgress()
    }

    private fun seekBy(deltaMs: Int) {
        val mp = player ?: return
        if (!prepared) return
        val target = (mp.currentPosition + deltaMs).coerceIn(0, mp.duration.coerceAtLeast(0))
        mp.seekTo(target)
        updateProgress()
    }

    private fun updatePlayIcon() {
        val playing = prepared && player?.isPlaying == true
        playPause.setImageResource(if (playing) R.drawable.ic_widget_pause else R.drawable.ic_widget_play)
    }

    private fun updateProgress() {
        val mp = player ?: return
        if (!prepared) return
        val duration = mp.duration
        progress.progress =
            if (duration > 0) (mp.currentPosition.toLong() * progress.max / duration).toInt() else 0
    }

    private fun requestFocus(): Boolean {
        val request = focusRequest ?: AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )
            .setOnAudioFocusChangeListener(focusListener, handler)
            .build()
            .also { focusRequest = it }
        return audioManager.requestAudioFocus(request) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
    }

    private fun abandonFocus() {
        focusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
    }

    private fun release() {
        handler.removeCallbacks(tick)
        prepared = false
        player?.let {
            try {
                it.stop()
            } catch (_: Exception) {
            }
            it.release()
        }
        player = null
        abandonFocus()
    }

    companion object {
        private const val TAG = "QuickPlay"
    }
}
