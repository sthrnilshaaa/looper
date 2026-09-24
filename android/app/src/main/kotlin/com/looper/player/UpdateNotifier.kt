package com.looper.player

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri

/**
 * Backs the "update available" notification.
 *
 * Deliberately built on platform APIs only (minSdk 29 always has notification
 * channels), so it adds no dependency. Tapping the notification fires a plain
 * ACTION_VIEW PendingIntent, which works even when the app process is gone -
 * no Dart callback is needed to route the tap.
 */
object UpdateNotifier {
    private const val CHANNEL_ID = "app_updates"
    private const val NOTIFICATION_ID = 4201

    /**
     * Posts the notification. Returns false without posting when the user has
     * notifications disabled (including the Android 13+ POST_NOTIFICATIONS
     * runtime permission being denied), so the caller can fall back to
     * in-app UI instead of silently telling nobody.
     */
    fun show(context: Context, title: String, body: String, url: String): Boolean {
        val manager = context.getSystemService(NotificationManager::class.java)
        if (!manager.areNotificationsEnabled()) return false

        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, "App updates", NotificationManager.IMPORTANCE_DEFAULT).apply {
                description = "Tells you when a new version of Looper Player is available"
            }
        )

        val viewIntent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        val contentIntent = PendingIntent.getActivity(
            context,
            0,
            viewIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification_session)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setContentIntent(contentIntent)
            .setAutoCancel(true)
            .build()

        // Fixed id: a newer release replaces an older, still-showing notification.
        manager.notify(NOTIFICATION_ID, notification)
        return true
    }
}
