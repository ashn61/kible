package com.kible.kible

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * Widget'ları ve kalıcı "sıradaki vakit" bildirimini günceller; bir sonraki
 * vakit girdiğinde tekrar çalışmak için alarm kurar. Uygulama kapalıyken de
 * [KibleUpdateReceiver] üzerinden çalışır.
 */
object KibleUpdater {
    private const val CHANNEL_ID = "kible_ongoing"
    private const val NOTIFICATION_ID = 7001
    private const val ALARM_REQUEST = 7002

    fun refresh(context: Context) {
        KibleWidgetProvider.updateAll(context)
        updateOngoingNotification(context)
        scheduleNext(context)
    }

    /** Sıradaki vakit anında (+1 sn) [KibleUpdateReceiver]'ı tetikler. */
    fun scheduleNext(context: Context) {
        val next = KibleData.load(context)?.stateAt(System.currentTimeMillis())?.nextTime ?: return
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = PendingIntent.getBroadcast(
            context,
            ALARM_REQUEST,
            Intent(context, KibleUpdateReceiver::class.java).setAction(KibleUpdateReceiver.ACTION_TICK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val at = next + 1_000
        val canExact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarm.canScheduleExactAlarms()
        try {
            if (canExact) {
                alarm.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, intent)
            } else {
                alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, intent)
            }
        } catch (e: SecurityException) {
            alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, intent)
        }
    }

    private fun updateOngoingNotification(context: Context) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val data = KibleData.load(context)
        if (!KibleData.ongoingEnabled(context) || data == null) {
            manager.cancel(NOTIFICATION_ID)
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            !manager.areNotificationsEnabled()
        ) {
            return
        }

        val state = data.stateAt(System.currentTimeMillis())
        val next = state.nextTime
        if (next == null) {
            manager.cancel(NOTIFICATION_ID)
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, "Sıradaki vakit", NotificationManager.IMPORTANCE_LOW)
                    .apply {
                        description = "Bildirim panelinde sıradaki vakte geri sayım"
                        setShowBadge(false)
                    },
            )
        }

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context).setPriority(Notification.PRIORITY_LOW)
        }

        val current = state.currentIndex.takeIf { it >= 0 }?.let { data.names.getOrNull(it) }
        builder
            .setSmallIcon(R.drawable.ic_stat_kible)
            .setColor(0xFF0E5A5F.toInt())
            .setContentTitle("${state.nextName} vakti · ${state.nextLabel}")
            .setContentText(
                listOfNotNull(data.location, current?.let { "Şu an: $it" }).joinToString("  •  "),
            )
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(true)
            .setWhen(next)
            .setUsesChronometer(true)
            .setContentIntent(KibleWidgetProvider.openAppIntent(context))
            .setCategory(Notification.CATEGORY_STATUS)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            builder.setChronometerCountDown(true)
        }

        manager.notify(NOTIFICATION_ID, builder.build())
    }
}
