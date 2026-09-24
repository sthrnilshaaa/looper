package com.looper.player

import android.app.Activity
import io.flutter.plugin.common.MethodChannel

/**
 * github flavor: intentionally does nothing. In-App Updates is a Google Play
 * feature, so this build neither includes the Play library nor uses it; Dart
 * sees "unsupported" and falls back to checking GitHub releases instead.
 * The play flavor's src/play counterpart has the real implementation.
 */
@Suppress("UNUSED_PARAMETER")
class InAppUpdater(activity: Activity, onDownloaded: () -> Unit) {
    fun checkAndStart(result: MethodChannel.Result) {
        result.success(mapOf("status" to "unsupported", "versionCode" to 0))
    }

    fun completeUpdate() {}

    fun onActivityResult(requestCode: Int, resultCode: Int): Boolean = false

    fun onResume() {}

    fun onDestroy() {}
}
