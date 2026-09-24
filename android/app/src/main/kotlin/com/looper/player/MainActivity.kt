package com.looper.player

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.Activity
import android.app.RecoverableSecurityException
import android.content.ContentValues
import android.content.Intent
import android.content.BroadcastReceiver
import android.content.IntentFilter
import android.os.Bundle
import android.os.Build
import android.media.AudioManager
import android.content.Context
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.util.Log
import android.graphics.Color
import android.media.MediaMetadataRetriever
import android.os.PowerManager


class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.looper.player/broadcast"
    private val WIDGET_CHANNEL = "com.looper.player/widget"
    private val WAKELOCK_CHANNEL = "com.looper.player/wakelock"
    private val UPDATE_CHANNEL = "com.looper.player/updates"
    private val AUDIO_FOCUS_CHANNEL = "com.looper.player/audio_focus"
    private val SAF_PICK_FOLDER_REQUEST_CODE = 9273
    private val MEDIA_WRITE_REQUEST_CODE = 9274
    private val MEDIA_BATCH_DELETE_REQUEST_CODE = 9275
    private var wakeLock: PowerManager.WakeLock? = null
    private var audioFocusManager: AudioFocusManager? = null
    // Real Play In-App Updates in the play flavor, a no-op in the github one.
    private var inAppUpdater: InAppUpdater? = null
    // Pending result for an in-flight pickSafFolder() call, bridged across
    // the async gap to the system folder-picker Activity in onActivityResult.
    private var pendingSafResult: MethodChannel.Result? = null
    // Pending result/retry for an in-flight single-file MediaStore write or
    // delete consent flow (RecoverableSecurityException's action intent -
    // see requestConsentThenRetry). declineValue is returned as-is if the
    // user dismisses the dialog, since callers expect different "not done"
    // shapes (false for delete/tag-write, null for rename).
    private var pendingMediaWriteResult: MethodChannel.Result? = null
    private var pendingMediaWriteRetry: (() -> Unit)? = null
    private var pendingMediaWriteDeclineValue: Any? = null
    // Pending result/paths for an in-flight batch delete via
    // MediaStore.createDeleteRequest (API 30+, one dialog for many files).
    private var pendingBatchDeleteResult: MethodChannel.Result? = null
    private var pendingBatchDeletePaths: List<String>? = null
    // Embedded-picture and embedded-lyrics reads for library enrichment. A
    // small fixed pool (not a thread per call) so a burst of requests queues
    // instead of spawning dozens of threads all doing file I/O at once, and
    // - the important part - never runs on the platform thread, which is
    // also what delivers touch input and vsync to Flutter: a read there
    // freezes the whole UI for as long as the file takes to open.
    private val metadataExecutor: java.util.concurrent.ExecutorService =
        java.util.concurrent.Executors.newFixedThreadPool(2)


    companion object {
        var activeEngine: FlutterEngine? = null
        var stopOnTaskRemoved: Boolean = false

        fun sendWidgetAction(context: Context, action: String) {
            val engine = activeEngine
            if (engine != null) {
                val channel = MethodChannel(engine.dartExecutor.binaryMessenger, "com.looper.player/widget")
                channel.invokeMethod("onWidgetAction", action)
            } else {
                // If app is not running, click launches the app
                val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                launchIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(launchIntent)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        activeEngine = flutterEngine
        io.flutter.embedding.engine.FlutterEngineCache.getInstance().put("looper_cached_engine", flutterEngine)
        
        try {
            startService(Intent(this, LooperTaskService::class.java))
        } catch (e: Exception) {
            Log.e("LooperTaskService", "Failed to start LooperTaskService", e)
        }



        val afm = AudioFocusManager(this, MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_FOCUS_CHANNEL))
        audioFocusManager = afm
        // Registered unconditionally (not tied to holding AudioManager focus):
        // mpv_audio_kit is the sole audio-focus owner, so this class must never
        // request focus itself (a second concurrent focus request would steal
        // focus from mpv's own listener and pause playback). These receivers
        // only need the ordinary broadcasts, not focus, to power "Resume on
        // Bluetooth Connect" (and a redundant but harmless noisy-pause).
        afm.registerReceivers()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_FOCUS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestAudioFocus" -> {
                    val granted = afm.requestAudioFocus()
                    result.success(granted)
                }
                "abandonAudioFocus" -> {
                    afm.abandonAudioFocus()
                    result.success(null)
                }
                "setPlaybackInterrupted" -> {
                    val interrupted = call.argument<Boolean>("interrupted") ?: false
                    afm.setPlaybackInterrupted(interrupted)
                    result.success(null)
                }
                "syncSettings" -> {
                    afm.isEnabled = call.argument<Boolean>("enabled") ?: true
                    afm.pauseOnDuck = call.argument<Boolean>("pauseOnDuck") ?: false
                    afm.resumeOnBluetoothConnect = call.argument<Boolean>("resumeOnBluetoothConnect") ?: false
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "broadcastMetadata") {
                val title = call.argument<String>("title")
                val artist = call.argument<String>("artist")
                val album = call.argument<String>("album")
                val duration = (call.argument<Any>("duration") as? Number)?.toLong() ?: 0L
                val isPlaying = call.argument<Boolean>("isPlaying") ?: false

                sendPlaybackBroadcast(title, artist, album, duration, isPlaying)
                result.success(null)
            } else if (call.method == "getAllFilesAccessInfo") {
                // Read-only. "declared" comes from the installed manifest, so
                // it is only ever true for the github flavor (see
                // src/github/AndroidManifest.xml) - the Play build never
                // declares MANAGE_EXTERNAL_STORAGE and so never offers it.
                val declared = try {
                    packageManager.getPackageInfo(packageName, android.content.pm.PackageManager.GET_PERMISSIONS)
                        .requestedPermissions
                        ?.contains("android.permission.MANAGE_EXTERNAL_STORAGE") == true
                } catch (e: Exception) {
                    false
                }
                val granted = declared &&
                    Build.VERSION.SDK_INT >= Build.VERSION_CODES.R &&
                    android.os.Environment.isExternalStorageManager()
                result.success(
                    mapOf(
                        "sdkInt" to Build.VERSION.SDK_INT,
                        "declared" to declared,
                        "granted" to granted
                    )
                )
            } else if (call.method == "setStopOnTaskRemoved") {
                val value = call.argument<Boolean>("value") ?: false
                stopOnTaskRemoved = value
                result.success(null)
            } else if (call.method == "isOnCall") {
                val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                val mode = audioManager.mode
                val isOnCall = (mode == AudioManager.MODE_IN_CALL || 
                                mode == AudioManager.MODE_IN_COMMUNICATION || 
                                mode == AudioManager.MODE_RINGTONE)
                result.success(isOnCall)
            } else if (call.method == "restartApp") {
                val intent = packageManager.getLaunchIntentForPackage(packageName)
                if (intent != null) {
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
                    startActivity(intent)
                    Runtime.getRuntime().exit(0)
                }
            } else if (call.method == "queryMediaStore") {
                val minDurationMs = (call.argument<Any>("minDurationMs") as? Number)?.toLong() ?: 0L
                val minSizeBytes = (call.argument<Any>("minSizeBytes") as? Number)?.toLong() ?: 0L
                val includeSystemAndMessagingAudio =
                    call.argument<Boolean>("includeSystemAndMessagingAudio") ?: false
                // Walks the device-wide audio index - hundreds of ms or more
                // on a big library - so it must not run on the platform
                // thread (see metadataExecutor's comment). Always replies,
                // even on failure: an unhandled exception in a background
                // thread would otherwise leave the Dart await hanging forever.
                Thread {
                    val songs = try {
                        queryMediaStoreAudio(
                            minDurationMs,
                            minSizeBytes,
                            includeSystemAndMessagingAudio
                        )
                    } catch (e: Exception) {
                        Log.e("MainActivity", "queryMediaStore failed", e)
                        null
                    }
                    runOnUiThread { result.success(songs) }
                }.start()
            } else if (call.method == "rescanMedia") {
                try {
                    val path = call.argument<String>("path") ?: "/storage/emulated/0"
                    android.media.MediaScannerConnection.scanFile(
                        applicationContext,
                        arrayOf(path),
                        null
                    ) { _, _ -> }
                    result.success(true)
                } catch (e: Exception) {
                    result.success(false)
                }
            } else if (call.method == "getEmbeddedPicture") {
                val path = call.argument<String>("path")
                if (path != null) {
                    metadataExecutor.execute {
                        var artBytes: ByteArray? = null
                        val mmr = MediaMetadataRetriever()
                        try {
                            mmr.setDataSource(path)
                            artBytes = mmr.embeddedPicture
                        } catch (e: Exception) {
                            artBytes = null
                        } finally {
                            // Released on failure too - setDataSource throws
                            // for files it can't open, and skipping release
                            // there leaked a native retriever per bad file.
                            try { mmr.release() } catch (e: Exception) {}
                        }
                        runOnUiThread { result.success(artBytes) }
                    }
                } else {
                    result.success(null)
                }
            } else if (call.method == "pickSafFolder") {
                // Storage Access Framework folder pick, used for "Add folder"
                // instead of MANAGE_EXTERNAL_STORAGE (Play Store disallows the
                // latter for a media-player app). The OS persists the grant
                // (takePersistableUriPermission) across restarts/reboots, so
                // nothing needs to be tracked on the Dart side.
                try {
                    pendingSafResult = result
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
                    intent.addFlags(
                        Intent.FLAG_GRANT_READ_URI_PERMISSION or
                        Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
                    )
                    startActivityForResult(intent, SAF_PICK_FOLDER_REQUEST_CODE)
                } catch (e: Exception) {
                    pendingSafResult = null
                    result.error("SAF_PICK_FAILED", e.message, null)
                }
            } else if (call.method == "listSafAudioFiles") {
                val extensions = call.argument<List<String>>("extensions") ?: emptyList()
                // Recursive DocumentsContract listing does binder round-trips
                // per directory level - keep it off the platform/UI thread.
                Thread {
                    val files = listSafAudioFiles(extensions)
                    runOnUiThread { result.success(files) }
                }.start()
            } else if (call.method == "releaseSafFolder") {
                val path = call.argument<String>("path")
                if (path != null) {
                    releaseSafFolder(path)
                }
                result.success(null)
            } else if (call.method == "getEmbeddedLyrics") {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.success(null)
                } else {
                    // Tag parsing does real file I/O - keep it off the
                    // platform/UI thread, same as the SAF folder listing above.
                    metadataExecutor.execute {
                        val lyrics = try {
                            readEmbeddedLyrics(path)
                        } catch (e: Exception) {
                            null
                        }
                        runOnUiThread { result.success(lyrics) }
                    }
                }
            } else if (call.method == "deleteMediaFile") {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.success(false)
                } else {
                    Thread { deleteMediaFile(path, result) }.start()
                }
            } else if (call.method == "deleteMediaFiles") {
                val paths = call.argument<List<String>>("paths") ?: emptyList()
                Thread { deleteMediaFilesBatch(paths, result) }.start()
            } else if (call.method == "renameMediaFile") {
                val path = call.argument<String>("path")
                val newDisplayName = call.argument<String>("newDisplayName")
                if (path == null || newDisplayName == null) {
                    result.success(null)
                } else {
                    Thread { renameMediaFile(path, newDisplayName, result) }.start()
                }
            } else if (call.method == "writeMediaTags") {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.success(false)
                } else {
                    val tags = mapOf(
                        "title" to call.argument<String>("title"),
                        "artist" to call.argument<String>("artist"),
                        "album" to call.argument<String>("album"),
                        "genre" to call.argument<String>("genre"),
                        "year" to (call.argument<Any>("year") as? Number)?.toInt(),
                        "lyrics" to call.argument<String>("lyrics")
                    )
                    Thread { writeMediaTags(path, tags, result) }.start()
                }
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "updateWidgetState") {
                val title = call.argument<String>("title") ?: "No song playing"
                val artist = call.argument<String>("artist") ?: ""
                val isPlaying = call.argument<Boolean>("isPlaying") ?: false
                val isShuffle = call.argument<Boolean>("isShuffle") ?: false
                val repeatMode = (call.argument<Any>("repeatMode") as? Number)?.toInt() ?: 0
                val lyrics = call.argument<String>("lyrics") ?: ""
                val nextLyrics = call.argument<String>("nextLyrics") ?: ""
                val artPath = call.argument<String>("artPath") ?: ""
                var accentColor = (call.argument<Any>("accentColor") as? Number)?.toInt() ?: 0
                val position = (call.argument<Any>("position") as? Number)?.toLong() ?: 0L
                val duration = (call.argument<Any>("duration") as? Number)?.toLong() ?: 0L

                Log.d("PlayerWidget", "MainActivity: updateWidgetState: title=$title, artist=$artist, isPlaying=$isPlaying, accentColor=$accentColor")

                // If accentColor is transparent or zero, fallback to premium green
                if (accentColor == 0) {
                    accentColor = Color.parseColor("#55DF69")
                }

                val prefs = es.antonborri.home_widget.HomeWidgetPlugin.getData(this)
                val oldTitle = prefs.getString("title", "")
                prefs.edit().apply {
                    if (title != oldTitle) {
                        putInt("currentLyricIndex", 0)
                        putString("lastSavedLyric", "")
                    }
                    putString("title", title)
                    putString("artist", artist)
                    putBoolean("isPlaying", isPlaying)
                    putBoolean("isShuffle", isShuffle)
                    putInt("repeatMode", repeatMode)
                    putString("lyrics", lyrics)
                    putString("nextLyrics", nextLyrics)
                    putString("artPath", artPath)
                    putInt("accentColor", accentColor)
                    putLong("position", position)
                    putLong("duration", duration)
                    apply()
                }

                // Trigger widget update for all 4 providers
                val appWidgetManager = AppWidgetManager.getInstance(this)
                val providers = listOf(
                    PlayerWidgetProvider::class.java,
                    PlayerWidgetProviderSquareArtwork::class.java,
                    PlayerWidgetProviderSquareProgress::class.java,
                    PlayerWidgetProviderLargeLyrics::class.java
                )
                for (provider in providers) {
                    val componentName = ComponentName(this, provider)
                    val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
                    Log.d("PlayerWidget", "MainActivity: updating widget IDs count for ${provider.simpleName} = ${appWidgetIds.size}")
                    for (appWidgetId in appWidgetIds) {
                        PlayerWidgetProvider.updateWidget(this, appWidgetManager, appWidgetId, provider)
                    }
                }

                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WAKELOCK_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "acquire" -> {
                    acquireWakeLock()
                    result.success(null)
                }
                "release" -> {
                    releaseWakeLock()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        val updateChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATE_CHANNEL)
        inAppUpdater?.onDestroy() // configureFlutterEngine can run again for the same activity
        val updater = InAppUpdater(this) { updateChannel.invokeMethod("onUpdateDownloaded", null) }
        inAppUpdater = updater
        updateChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPlayUpdate" -> updater.checkAndStart(result)
                "completePlayUpdate" -> {
                    updater.completeUpdate()
                    result.success(null)
                }
                "showUpdateNotification" -> {
                    val title = call.argument<String>("title")
                    val body = call.argument<String>("body")
                    val url = call.argument<String>("url")
                    if (title == null || body == null || url == null) {
                        result.error("bad_args", "title, body and url are required", null)
                    } else {
                        result.success(UpdateNotifier.show(this, title, body, url))
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun acquireWakeLock() {
        try {
            if (wakeLock == null) {
                val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "LooperPlayer:PlaybackWakeLock")
            }
            if (wakeLock?.isHeld == false) {
                wakeLock?.acquire()
                Log.d("LooperWakeLock", "Partial WakeLock acquired")
            }
        } catch (e: Exception) {
            Log.e("LooperWakeLock", "Error acquiring wakeLock", e)
        }
    }

    private fun releaseWakeLock() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
                Log.d("LooperWakeLock", "Partial WakeLock released")
            }
        } catch (e: Exception) {
            Log.e("LooperWakeLock", "Error releasing wakeLock", e)
        }
    }


    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (inAppUpdater?.onActivityResult(requestCode, resultCode) == true) return

        if (requestCode == MEDIA_WRITE_REQUEST_CODE) {
            val pending = pendingMediaWriteResult
            val retry = pendingMediaWriteRetry
            val declineValue = pendingMediaWriteDeclineValue
            pendingMediaWriteResult = null
            pendingMediaWriteRetry = null
            pendingMediaWriteDeclineValue = null
            if (resultCode == Activity.RESULT_OK) {
                if (retry != null) retry.invoke() else pending?.success(true)
            } else {
                pending?.success(declineValue) // user declined the consent dialog
            }
            return
        }

        if (requestCode == MEDIA_BATCH_DELETE_REQUEST_CODE) {
            val pending = pendingBatchDeleteResult
            val paths = pendingBatchDeletePaths
            pendingBatchDeleteResult = null
            pendingBatchDeletePaths = null
            if (resultCode == Activity.RESULT_OK) {
                pending?.success(emptyList<String>()) // platform deleted every requested row
            } else {
                pending?.success(paths ?: emptyList<String>())
            }
            return
        }

        if (requestCode != SAF_PICK_FOLDER_REQUEST_CODE) return

        val pending = pendingSafResult
        pendingSafResult = null
        val treeUri = data?.data
        if (resultCode != Activity.RESULT_OK || treeUri == null) {
            pending?.success(null) // user cancelled the picker
            return
        }

        try {
            contentResolver.takePersistableUriPermission(
                treeUri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION
            )
        } catch (e: Exception) {
            Log.e("SafFolderPicker", "Failed to persist URI permission", e)
        }

        val resolvedPath = resolveTreeUriToPath(treeUri)
        if (resolvedPath == null) {
            // Not backed by local/SD storage (e.g. a cloud document provider) -
            // the app can't do anything useful with it, so drop the grant.
            try {
                contentResolver.releasePersistableUriPermission(
                    treeUri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION
                )
            } catch (_: Exception) {}
            pending?.error(
                "UNSUPPORTED_PROVIDER",
                "Please choose a folder on this device's internal storage or SD card.",
                null
            )
            return
        }

        // Proactively index the folder: scoped storage grants raw filesystem
        // path reads to MediaStore-indexed audio files even without a broad
        // storage permission, so this makes common formats immediately
        // readable by the ordinary scan/metadata code path.
        try {
            android.media.MediaScannerConnection.scanFile(
                applicationContext,
                arrayOf(resolvedPath),
                null
            ) { _, _ -> }
        } catch (_: Exception) {}

        pending?.success(resolvedPath)
    }

    /// Resolves a tree Uri from the default local-storage document provider
    /// (internal storage or an SD card) to its real absolute filesystem path.
    /// Returns null for any other provider (e.g. a cloud-backed picker).
    private fun resolveTreeUriToPath(treeUri: android.net.Uri): String? {
        if (treeUri.authority != "com.android.externalstorage.documents") return null
        val docId = try {
            android.provider.DocumentsContract.getTreeDocumentId(treeUri)
        } catch (e: Exception) {
            null
        } ?: return null

        val split = docId.split(":", limit = 2)
        val volumeId = split.getOrNull(0) ?: return null
        val relativePath = split.getOrNull(1) ?: ""
        val root = if (volumeId.equals("primary", ignoreCase = true)) {
            "/storage/emulated/0"
        } else {
            "/storage/$volumeId"
        }
        return if (relativePath.isEmpty()) root else "$root/$relativePath"
    }

    /// Recursively lists every file matching [lowerExtensions] across all
    /// currently-persisted local-storage SAF folder grants.
    private fun listSafAudioFiles(extensions: List<String>): List<String> {
        val results = mutableListOf<String>()
        val lowerExtensions = extensions.map { it.lowercase() }.toSet()
        try {
            for (perm in contentResolver.persistedUriPermissions) {
                if (!perm.isReadPermission) continue
                val treeUri = perm.uri
                val rootPath = resolveTreeUriToPath(treeUri) ?: continue
                val rootDocId = try {
                    android.provider.DocumentsContract.getTreeDocumentId(treeUri)
                } catch (e: Exception) {
                    null
                } ?: continue
                walkSafTree(treeUri, rootDocId, rootPath, lowerExtensions, results)
            }
        } catch (e: Exception) {
            Log.e("SafFolderQuery", "Error listing SAF audio files", e)
        }
        return results
    }

    private fun walkSafTree(
        treeUri: android.net.Uri,
        parentDocId: String,
        parentPath: String,
        lowerExtensions: Set<String>,
        results: MutableList<String>
    ) {
        val childrenUri = android.provider.DocumentsContract
            .buildChildDocumentsUriUsingTree(treeUri, parentDocId)
        val projection = arrayOf(
            android.provider.DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            android.provider.DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            android.provider.DocumentsContract.Document.COLUMN_MIME_TYPE
        )
        try {
            contentResolver.query(childrenUri, projection, null, null, null)?.use { cursor ->
                val idCol = cursor.getColumnIndex(android.provider.DocumentsContract.Document.COLUMN_DOCUMENT_ID)
                val nameCol = cursor.getColumnIndex(android.provider.DocumentsContract.Document.COLUMN_DISPLAY_NAME)
                val mimeCol = cursor.getColumnIndex(android.provider.DocumentsContract.Document.COLUMN_MIME_TYPE)
                while (cursor.moveToNext()) {
                    val docId = if (idCol != -1) cursor.getString(idCol) else null
                    val name = if (nameCol != -1) cursor.getString(nameCol) else null
                    if (docId == null || name == null) continue
                    val mime = if (mimeCol != -1) cursor.getString(mimeCol) else null
                    val childPath = if (parentPath.endsWith("/")) "$parentPath$name" else "$parentPath/$name"

                    if (mime == android.provider.DocumentsContract.Document.MIME_TYPE_DIR) {
                        if (name.startsWith(".")) continue
                        walkSafTree(treeUri, docId, childPath, lowerExtensions, results)
                    } else {
                        val ext = name.substringAfterLast('.', "")
                        if (ext.isNotEmpty() && lowerExtensions.contains(".${ext.lowercase()}")) {
                            results.add(childPath)
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e("SafFolderQuery", "Error walking SAF tree at $parentPath", e)
        }
    }

    /// Releases a previously-persisted SAF grant whose resolved root matches
    /// (or contains/is contained by) [path], e.g. when the user removes a
    /// folder from Library Folders in Settings.
    private fun releaseSafFolder(path: String) {
        try {
            for (perm in contentResolver.persistedUriPermissions) {
                val treeUri = perm.uri
                val rootPath = resolveTreeUriToPath(treeUri) ?: continue
                if (rootPath == path ||
                    path.startsWith("$rootPath/") ||
                    rootPath.startsWith("$path/")
                ) {
                    contentResolver.releasePersistableUriPermission(
                        treeUri,
                        Intent.FLAG_GRANT_READ_URI_PERMISSION
                    )
                }
            }
        } catch (e: Exception) {
            Log.e("SafFolderRelease", "Error releasing SAF folder", e)
        }
    }

    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return io.flutter.embedding.engine.FlutterEngineCache.getInstance().get("looper_cached_engine")
    }

    override fun shouldDestroyEngineWithHost(): Boolean {
        return stopOnTaskRemoved
    }

    override fun onResume() {
        super.onResume()
        inAppUpdater?.onResume()
    }

    override fun onDestroy() {
        releaseWakeLock()
        audioFocusManager?.unregisterReceivers()
        inAppUpdater?.onDestroy()
        activeEngine = null
        if (stopOnTaskRemoved) {
            io.flutter.embedding.engine.FlutterEngineCache.getInstance().remove("looper_cached_engine")
        }
        super.onDestroy()
    }

    /// Reads the embedded lyrics tag (ID3 USLT for mp3/wav, Vorbis Comment
    /// LYRICS/UNSYNCEDLYRICS for flac/ogg, MP4 (c)lyr for m4a, ...) via
    /// jaudiotagger's unified FieldKey.LYRICS mapping. metadata_god (used for
    /// title/artist/album/art elsewhere in this app) has no lyrics field, and
    /// hand-rolling binary tag parsing for untrusted files isn't worth the
    /// risk when a mature library already does this correctly.
    private fun readEmbeddedLyrics(path: String): String? {
        return try {
            val audioFile = org.jaudiotagger.audio.AudioFileIO.read(java.io.File(path))
            val tag = audioFile.tag ?: return null
            if (!tag.hasField(org.jaudiotagger.tag.FieldKey.LYRICS)) return null
            val lyrics = tag.getFirst(org.jaudiotagger.tag.FieldKey.LYRICS)
            if (lyrics.isNullOrBlank()) null else lyrics
        } catch (e: Exception) {
            // Includes formats jaudiotagger can't read, corrupt/partial
            // files, and KeyNotFoundException for tag types that don't map
            // LYRICS at all - all just "no embedded lyrics", not a crash.
            null
        } catch (e: NoClassDefFoundError) {
            Log.e("EmbeddedLyrics", "jaudiotagger format module unavailable", e)
            null
        }
    }

    /// Resolves an audio file's absolute path to its MediaStore content Uri
    /// (matched on the DATA column, same as queryMediaStoreAudio), or null if
    /// it isn't MediaStore-indexed (e.g. an app-private file).
    private fun resolveAudioUri(path: String): android.net.Uri? {
        val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            android.provider.MediaStore.Audio.Media.getContentUri(android.provider.MediaStore.VOLUME_EXTERNAL)
        } else {
            android.provider.MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        }
        return try {
            contentResolver.query(
                collection,
                arrayOf(android.provider.MediaStore.Audio.Media._ID),
                "${android.provider.MediaStore.Audio.Media.DATA} = ?",
                arrayOf(path),
                null
            )?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val id = cursor.getLong(cursor.getColumnIndexOrThrow(android.provider.MediaStore.Audio.Media._ID))
                    android.content.ContentUris.withAppendedId(collection, id)
                } else {
                    null
                }
            }
        } catch (e: Exception) {
            Log.e("MediaWrite", "Failed to resolve MediaStore uri for $path", e)
            null
        }
    }

    /// Stores [result]/[onGranted]/[declineValue], then launches the system
    /// consent dialog carried by a RecoverableSecurityException - thrown by
    /// MediaProvider (API 29+) when this app tries to modify or delete a
    /// MediaStore row it doesn't own. [onGranted] re-attempts the operation
    /// from onActivityResult if the user approves; [declineValue] is handed
    /// back as-is if they dismiss it instead.
    private fun requestConsentThenRetry(
        e: RecoverableSecurityException,
        result: MethodChannel.Result,
        declineValue: Any?,
        onGranted: () -> Unit
    ) {
        pendingMediaWriteResult = result
        pendingMediaWriteRetry = onGranted
        pendingMediaWriteDeclineValue = declineValue
        runOnUiThread {
            try {
                startIntentSenderForResult(
                    e.userAction.actionIntent.intentSender,
                    MEDIA_WRITE_REQUEST_CODE, null, 0, 0, 0
                )
            } catch (e2: Exception) {
                pendingMediaWriteResult = null
                pendingMediaWriteRetry = null
                pendingMediaWriteDeclineValue = null
                result.error("CONSENT_REQUEST_FAILED", e2.message, null)
            }
        }
    }

    /// Deletes a single audio file under scoped storage. Tries a direct
    /// ContentResolver delete first (works if this app owns the row, or a
    /// grant from an earlier call is still active); falls back to the system
    /// consent dialog otherwise. Returns false if declined or if it failed.
    private fun deleteMediaFile(path: String, result: MethodChannel.Result) {
        val uri = resolveAudioUri(path)
        if (uri == null) {
            val deleted = try { java.io.File(path).delete() } catch (e: Exception) { false }
            runOnUiThread { result.success(deleted) }
            return
        }
        try {
            contentResolver.delete(uri, null, null)
            runOnUiThread { result.success(true) }
        } catch (e: RecoverableSecurityException) {
            requestConsentThenRetry(e, result, false) {
                Thread {
                    val ok = try {
                        contentResolver.delete(uri, null, null)
                        true
                    } catch (e2: Exception) {
                        false
                    }
                    runOnUiThread { result.success(ok) }
                }.start()
            }
        } catch (e: Exception) {
            Log.e("MediaWrite", "Failed to delete $path", e)
            runOnUiThread { result.success(false) }
        }
    }

    /// Attempts to delete every path in [paths]. On API 30+, this uses
    /// MediaStore.createDeleteRequest to show a single consent dialog
    /// covering every resolvable file at once. There is no batch consent API
    /// before Android 11, so on API 29 this only deletes files the app
    /// already owns outright and hands back the rest untouched - the caller
    /// falls back to deleteMediaFile() one at a time for those, each
    /// prompting its own dialog. Returns the subset of [paths] NOT deleted.
    private fun deleteMediaFilesBatch(paths: List<String>, result: MethodChannel.Result) {
        val uriByPath = paths.mapNotNull { path -> resolveAudioUri(path)?.let { path to it } }.toMap()
        if (uriByPath.isEmpty()) {
            runOnUiThread { result.success(paths) }
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                val pendingIntent = android.provider.MediaStore.createDeleteRequest(
                    contentResolver,
                    uriByPath.values.toList()
                )
                pendingBatchDeleteResult = result
                pendingBatchDeletePaths = paths
                runOnUiThread {
                    try {
                        startIntentSenderForResult(
                            pendingIntent.intentSender,
                            MEDIA_BATCH_DELETE_REQUEST_CODE, null, 0, 0, 0
                        )
                    } catch (e2: Exception) {
                        pendingBatchDeleteResult = null
                        pendingBatchDeletePaths = null
                        result.success(paths)
                    }
                }
            } catch (e: Exception) {
                Log.e("MediaWrite", "Batch delete request failed", e)
                runOnUiThread { result.success(paths) }
            }
        } else {
            val remaining = mutableListOf<String>()
            for ((filePath, uri) in uriByPath) {
                try {
                    contentResolver.delete(uri, null, null)
                } catch (e: Exception) {
                    remaining.add(filePath)
                }
            }
            remaining.addAll(paths.filter { it !in uriByPath.keys })
            runOnUiThread { result.success(remaining) }
        }
    }

    /// Renames a single audio file's underlying DISPLAY_NAME (MediaProvider
    /// performs the actual filesystem rename). Returns the new absolute path
    /// on success, or null if declined/failed.
    private fun renameMediaFile(path: String, newDisplayName: String, result: MethodChannel.Result) {
        val uri = resolveAudioUri(path)
        if (uri == null) {
            val newPath = try {
                val src = java.io.File(path)
                val dst = java.io.File(src.parentFile, newDisplayName)
                if (src.renameTo(dst)) dst.absolutePath else null
            } catch (e: Exception) {
                null
            }
            runOnUiThread { result.success(newPath) }
            return
        }

        fun doRename(): String? {
            val values = ContentValues().apply {
                put(android.provider.MediaStore.Audio.Media.DISPLAY_NAME, newDisplayName)
            }
            contentResolver.update(uri, values, null, null)
            return contentResolver.query(
                uri,
                arrayOf(android.provider.MediaStore.Audio.Media.DATA),
                null, null, null
            )?.use { cursor ->
                if (cursor.moveToFirst()) {
                    cursor.getString(cursor.getColumnIndexOrThrow(android.provider.MediaStore.Audio.Media.DATA))
                } else {
                    null
                }
            }
        }

        try {
            val newPath = doRename()
            runOnUiThread { result.success(newPath) }
        } catch (e: RecoverableSecurityException) {
            requestConsentThenRetry(e, result, null) {
                Thread {
                    val newPath = try { doRename() } catch (e2: Exception) { null }
                    runOnUiThread { result.success(newPath) }
                }.start()
            }
        } catch (e: Exception) {
            Log.e("MediaWrite", "Failed to rename $path", e)
            runOnUiThread { result.success(null) }
        }
    }

    /// Writes ID3/Vorbis Comment/MP4 tags directly into the audio file via
    /// jaudiotagger (already used read-only for embedded lyrics). Any [tags]
    /// entry that is null/blank is left untouched. If the app doesn't yet
    /// hold write access, a no-op ContentResolver update is used purely to
    /// surface RecoverableSecurityException and drive the same consent
    /// dialog as delete/rename - once approved, scoped storage also allows
    /// raw filesystem writes to that file for the rest of this app session,
    /// which is what jaudiotagger needs (it writes via java.io.File, not a
    /// content Uri). Returns false if declined, unsupported, or failed.
    private fun writeMediaTags(path: String, tags: Map<String, Any?>, result: MethodChannel.Result) {
        fun applyTags(): Boolean {
            val audioFile = org.jaudiotagger.audio.AudioFileIO.read(java.io.File(path))
            val tag = audioFile.tagOrCreateAndSetDefault
            (tags["title"] as? String)?.let { if (it.isNotBlank()) tag.setField(org.jaudiotagger.tag.FieldKey.TITLE, it) }
            (tags["artist"] as? String)?.let { if (it.isNotBlank()) tag.setField(org.jaudiotagger.tag.FieldKey.ARTIST, it) }
            (tags["album"] as? String)?.let { if (it.isNotBlank()) tag.setField(org.jaudiotagger.tag.FieldKey.ALBUM, it) }
            (tags["genre"] as? String)?.let { if (it.isNotBlank()) tag.setField(org.jaudiotagger.tag.FieldKey.GENRE, it) }
            (tags["year"] as? Int)?.let { if (it > 0) tag.setField(org.jaudiotagger.tag.FieldKey.YEAR, it.toString()) }
            (tags["lyrics"] as? String)?.let { if (it.isNotBlank()) tag.setField(org.jaudiotagger.tag.FieldKey.LYRICS, it) }
            audioFile.commit()
            return true
        }

        fun retryAfterGrant() {
            val ok = try { applyTags() } catch (e: Exception) { false }
            if (ok) rescanFile(path)
            runOnUiThread { result.success(ok) }
        }

        try {
            val ok = applyTags()
            if (ok) rescanFile(path)
            runOnUiThread { result.success(ok) }
        } catch (e: Exception) {
            if (!isPermissionError(e)) {
                Log.e("MediaWrite", "Failed to write tags for $path", e)
                runOnUiThread { result.success(false) }
                return
            }
            val uri = resolveAudioUri(path)
            if (uri == null) {
                runOnUiThread { result.success(false) }
                return
            }
            try {
                // Empty ContentValues: touches nothing, exists only to
                // trigger the same permission check contentResolver.update
                // would run for a real column change.
                contentResolver.update(uri, ContentValues(), null, null)
                retryAfterGrant()
            } catch (rse: RecoverableSecurityException) {
                requestConsentThenRetry(rse, result, false) { Thread { retryAfterGrant() }.start() }
            } catch (e3: Exception) {
                Log.e("MediaWrite", "Failed to write tags for $path", e3)
                runOnUiThread { result.success(false) }
            }
        }
    }

    private fun rescanFile(path: String) {
        try {
            android.media.MediaScannerConnection.scanFile(applicationContext, arrayOf(path), null) { _, _ -> }
        } catch (_: Exception) {}
    }

    /// Heuristic for "this failure means we need a write grant" - jaudiotagger
    /// wraps the underlying denial in its own exception types (e.g.
    /// CannotWriteException around an IOException), so this walks the cause
    /// chain for either a SecurityException or an EACCES/permission message
    /// rather than matching a single exception type.
    private fun isPermissionError(e: Throwable?): Boolean {
        var cur = e
        var depth = 0
        while (cur != null && depth < 6) {
            if (cur is SecurityException) return true
            val msg = cur.message
            if (msg != null && (msg.contains("EACCES", true) || msg.contains("Permission denied", true))) {
                return true
            }
            cur = cur.cause
            depth++
        }
        return false
    }

    private fun sendPlaybackBroadcast(title: String?, artist: String?, album: String?, duration: Long, isPlaying: Boolean) {
        val intent = Intent("com.android.music.metadatachanged")
        intent.putExtra("track", title)
        intent.putExtra("artist", artist)
        intent.putExtra("album", album)
        intent.putExtra("duration", duration)
        intent.putExtra("playing", isPlaying)
        
        // Some apps listen to these specific keys
        intent.putExtra("id", 1L)
        intent.putExtra("list_size", 1)
        
        sendBroadcast(intent)

        // Also send playstatechanged
        val stateIntent = Intent("com.android.music.playstatechanged")
        stateIntent.putExtra("playing", isPlaying)
        stateIntent.putExtra("track", title)
        sendBroadcast(stateIntent)
    }

    private fun queryMediaStoreAudio(
        minDurationMs: Long,
        minSizeBytes: Long,
        includeSystemAndMessagingAudio: Boolean
    ): List<Map<String, Any?>> {
        val audioList = mutableListOf<Map<String, Any?>>()
        try {
            val collection = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                android.provider.MediaStore.Audio.Media.getContentUri(android.provider.MediaStore.VOLUME_EXTERNAL)
            } else {
                android.provider.MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
            }

            val projection = arrayOf(
                android.provider.MediaStore.Audio.Media._ID,
                android.provider.MediaStore.Audio.Media.TITLE,
                android.provider.MediaStore.Audio.Media.ARTIST,
                android.provider.MediaStore.Audio.Media.ALBUM,
                android.provider.MediaStore.Audio.Media.DURATION,
                android.provider.MediaStore.Audio.Media.SIZE,
                android.provider.MediaStore.Audio.Media.DATA,
                android.provider.MediaStore.Audio.Media.YEAR,
                android.provider.MediaStore.Audio.Media.TRACK
            )

            val categorySelection = if (includeSystemAndMessagingAudio) {
                "1 = 1"
            } else {
                """(${android.provider.MediaStore.Audio.Media.IS_MUSIC} != 0 OR ${android.provider.MediaStore.Audio.Media.IS_MUSIC} IS NULL)
                    AND ${android.provider.MediaStore.Audio.Media.IS_RINGTONE} = 0
                    AND ${android.provider.MediaStore.Audio.Media.IS_NOTIFICATION} = 0
                    AND ${android.provider.MediaStore.Audio.Media.IS_ALARM} = 0""".trimIndent()
            }
            val selection = """
                ($categorySelection)
                AND (${android.provider.MediaStore.Audio.Media.DURATION} >= ? OR ${android.provider.MediaStore.Audio.Media.DURATION} IS NULL)
                AND (${android.provider.MediaStore.Audio.Media.SIZE} >= ? OR ${android.provider.MediaStore.Audio.Media.SIZE} IS NULL)
            """.trimIndent()

            val selectionArgs = arrayOf(
                minDurationMs.toString(),
                minSizeBytes.toString()
            )

            contentResolver.query(
                collection,
                projection,
                selection,
                selectionArgs,
                "${android.provider.MediaStore.Audio.Media.TITLE} ASC"
            )?.use { cursor ->
                val titleCol = cursor.getColumnIndex(android.provider.MediaStore.Audio.Media.TITLE)
                val artistCol = cursor.getColumnIndex(android.provider.MediaStore.Audio.Media.ARTIST)
                val albumCol = cursor.getColumnIndex(android.provider.MediaStore.Audio.Media.ALBUM)
                val durationCol = cursor.getColumnIndex(android.provider.MediaStore.Audio.Media.DURATION)
                val sizeCol = cursor.getColumnIndex(android.provider.MediaStore.Audio.Media.SIZE)
                val pathCol = cursor.getColumnIndex(android.provider.MediaStore.Audio.Media.DATA)
                val yearCol = cursor.getColumnIndex(android.provider.MediaStore.Audio.Media.YEAR)
                val trackCol = cursor.getColumnIndex(android.provider.MediaStore.Audio.Media.TRACK)

                while (cursor.moveToNext()) {
                    val path = if (pathCol != -1) cursor.getString(pathCol) else null
                    if (path.isNullOrEmpty()) continue

                    val lowerPath = path.lowercase()
                    val fileName = java.io.File(lowerPath).name
                    val pathSegments = lowerPath.split('/').filter { it.isNotEmpty() }.toSet()
                    val isAlwaysIgnored = lowerPath.contains("/android/data/") ||
                        lowerPath.contains("/android/obb/") ||
                        lowerPath.contains("/.cache/") ||
                        lowerPath.endsWith("/.nomedia")
                    val isOptionalAudio = pathSegments.any {
                        it == "ringtones" || it == "ringtone" ||
                            it == "notifications" || it == "notification" ||
                            it == "alarms" || it == "alarm" ||
                            it == "whatsapp" || it == "whatsapp business" ||
                            it == "whatsapp voice notes" || it == "whatsapp audio" ||
                            it == "telegram audio" || it == "telegram voice"
                    } ||
                        lowerPath.contains("/system/media/audio/") ||
                        fileName.startsWith("ptt-") ||
                        fileName.startsWith("aud-")
                    if (isAlwaysIgnored || (!includeSystemAndMessagingAudio && isOptionalAudio)) {
                        continue
                    }

                    val title = if (titleCol != -1) cursor.getString(titleCol) else null
                    val artist = if (artistCol != -1) cursor.getString(artistCol) else null
                    val album = if (albumCol != -1) cursor.getString(albumCol) else null
                    val duration = if (durationCol != -1) cursor.getLong(durationCol) else 0L
                    val size = if (sizeCol != -1) cursor.getLong(sizeCol) else 0L
                    val year = if (yearCol != -1) cursor.getInt(yearCol) else 0
                    val track = if (trackCol != -1) cursor.getInt(trackCol) else 0

                    audioList.add(mapOf(
                        "path" to path,
                        "title" to title,
                        "artist" to artist,
                        "album" to album,
                        "duration" to duration,
                        "size" to size,
                        "year" to year,
                        "track" to track
                    ))
                }
            }
        } catch (e: Exception) {
            Log.e("MediaStoreQuery", "Error querying MediaStore", e)
        }
        return audioList
    }
}
