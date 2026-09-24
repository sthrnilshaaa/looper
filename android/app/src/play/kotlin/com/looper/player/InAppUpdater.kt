package com.looper.player

import android.app.Activity
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.appupdate.AppUpdateOptions
import com.google.android.play.core.install.InstallStateUpdatedListener
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.InstallStatus
import com.google.android.play.core.install.model.UpdateAvailability
import io.flutter.plugin.common.MethodChannel

/**
 * Google Play In-App Updates (flexible flow), play flavor. The github flavor
 * has a no-op class of the same name in src/github, so MainActivity is
 * flavor-agnostic and the GitHub APK carries no Play code.
 *
 * Flexible rather than immediate: Play shows its own consent sheet, the update
 * downloads in the background and playback is never interrupted; the user
 * restarts into the new version when they choose to (see [completeUpdate]).
 *
 * Only works for builds actually installed from Play - anywhere else the
 * appUpdateInfo task fails and this reports "none".
 */
class InAppUpdater(
    private val activity: Activity,
    private val onDownloaded: () -> Unit,
) {
    private companion object {
        const val REQUEST_CODE = 9276
    }

    private val manager: AppUpdateManager = AppUpdateManagerFactory.create(activity.applicationContext)

    // The in-flight consent flow, bridged across the async gap to Play's
    // sheet the same way MainActivity bridges the SAF picker.
    private var pendingResult: MethodChannel.Result? = null
    private var pendingVersionCode = 0

    private val installListener = InstallStateUpdatedListener { state ->
        if (state.installStatus() == InstallStatus.DOWNLOADED) onDownloaded()
    }

    init {
        manager.registerListener(installListener)
    }

    /**
     * Asks Play whether a newer build exists and, if so, opens Play's consent
     * sheet. Completes with {"status": ..., "versionCode": ...} where status is:
     *  - "none"       no update, or Play couldn't be reached / didn't install us
     *  - "downloaded" an update finished downloading earlier and awaits a restart
     *  - "accepted"   the user accepted; the download proceeds in the background
     *  - "declined"   the user dismissed the sheet
     *  - "notAllowed" an update exists but Play won't allow the flexible flow
     *  - "failed"     the flow could not be started
     */
    fun checkAndStart(result: MethodChannel.Result) {
        manager.appUpdateInfo
            .addOnSuccessListener { info ->
                val code = info.availableVersionCode()
                when {
                    info.installStatus() == InstallStatus.DOWNLOADED ->
                        result.success(reply("downloaded", code))

                    info.updateAvailability() != UpdateAvailability.UPDATE_AVAILABLE ->
                        result.success(reply("none", code))

                    !info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE) ->
                        result.success(reply("notAllowed", code))

                    else -> {
                        pendingResult?.success(reply("none", code)) // superseded flow
                        pendingResult = result
                        pendingVersionCode = code
                        try {
                            manager.startUpdateFlowForResult(
                                info,
                                activity,
                                AppUpdateOptions.newBuilder(AppUpdateType.FLEXIBLE).build(),
                                REQUEST_CODE,
                            )
                        } catch (e: Exception) {
                            pendingResult = null
                            result.success(reply("failed", code))
                        }
                    }
                }
            }
            .addOnFailureListener { result.success(reply("none", 0)) }
    }

    /** Restarts the app into the downloaded update. */
    fun completeUpdate() {
        manager.completeUpdate()
    }

    /** Returns true when [requestCode] was the update consent flow. */
    fun onActivityResult(requestCode: Int, resultCode: Int): Boolean {
        if (requestCode != REQUEST_CODE) return false
        val result = pendingResult ?: return true
        pendingResult = null
        val status = when (resultCode) {
            Activity.RESULT_OK -> "accepted"
            Activity.RESULT_CANCELED -> "declined"
            else -> "failed" // ActivityResult.RESULT_IN_APP_UPDATE_FAILED
        }
        result.success(reply(status, pendingVersionCode))
        return true
    }

    /**
     * A flexible update can finish downloading while the app is in the
     * background, when the install-state listener has no UI to prompt on -
     * so re-check on every resume (Play's recommended pattern).
     */
    fun onResume() {
        manager.appUpdateInfo.addOnSuccessListener { info ->
            if (info.installStatus() == InstallStatus.DOWNLOADED) onDownloaded()
        }
    }

    fun onDestroy() {
        manager.unregisterListener(installListener)
        pendingResult = null
    }

    private fun reply(status: String, versionCode: Int) =
        mapOf("status" to status, "versionCode" to versionCode)
}
