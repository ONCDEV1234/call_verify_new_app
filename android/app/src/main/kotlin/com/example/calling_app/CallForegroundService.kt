package com.example.calling_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log

/**
 * Shows a foreground notification while Verify Call tracks a cellular call.
 *
 * IMPORTANT:
 * This version uses DATA_SYNC to match the current manifest and native call.
 * DATA_SYNC is appropriate only for genuine data-sync work. Select a valid
 * foreground-service type for the real production use case before release.
 *
 * MainActivity must explicitly start and stop this service.
 */
class CallForegroundService : Service() {

    companion object {
        private const val TAG = "CallForegroundService"

        const val ACTION_START =
            "com.example.calling_app.action.START_CALL_TRACKING"

        const val ACTION_STOP =
            "com.example.calling_app.action.STOP_CALL_TRACKING"

        private const val CHANNEL_ID = "verify_call_tracking"
        private const val CHANNEL_NAME = "Call tracking"
        private const val NOTIFICATION_ID = 8402

        fun start(context: Context) {
            val intent = Intent(context, CallForegroundService::class.java)
                .setAction(ACTION_START)

            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Unable to start foreground service", e)
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, CallForegroundService::class.java)
                .setAction(ACTION_STOP)

            try {
                context.startService(intent)
            } catch (e: Exception) {
                Log.e(TAG, "Unable to request service stop", e)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int
    ): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopForegroundCompat()
                stopSelf()
                return START_NOT_STICKY
            }

            ACTION_START, null -> {
                if (!startTrackingForeground()) {
                    // Do not leave a started foreground service running if
                    // Android rejected its foreground-service configuration.
                    stopSelf(startId)
                    return START_NOT_STICKY
                }
            }

            else -> {
                Log.w(TAG, "Unknown service action: ${intent.action}")
                stopSelf(startId)
                return START_NOT_STICKY
            }
        }

        // Persisted call state must be restored by MainActivity independently.
        return START_STICKY
    }

    private fun startTrackingForeground(): Boolean {
        val notification = buildNotification()

        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "Could not enter foreground; stopping service", e)
            false
        }
    }

    private fun buildNotification(): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)

        val pendingIntent = launchIntent?.let {
            PendingIntent.getActivity(
                this,
                0,
                it,
                PendingIntent.FLAG_UPDATE_CURRENT or
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            PendingIntent.FLAG_IMMUTABLE
                        } else {
                            0
                        }
            )
        }

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
                .setContentTitle("Verify Call")
                .setContentText("Call tracking is active")
                .setSmallIcon(applicationInfo.icon)
                .setOngoing(true)
                .setContentIntent(pendingIntent)
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setContentTitle("Verify Call")
                .setContentText("Call tracking is active")
                .setSmallIcon(applicationInfo.icon)
                .setOngoing(true)
                .setContentIntent(pendingIntent)
                .build()
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Shows when Verify Call is tracking a call"
        }

        val manager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        manager.createNotificationChannel(channel)
    }

    private fun stopForegroundCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
