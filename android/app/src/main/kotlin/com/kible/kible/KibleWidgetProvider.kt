package com.kible.kible

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/** Ana ekran widget'ı: konum, sıradaki vakit + geri sayım ve günün altı vakti. */
class KibleWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        render(context, appWidgetManager, appWidgetIds)
        KibleUpdater.scheduleNext(context)
    }

    companion object {
        private val NAME_IDS = intArrayOf(
            R.id.name_0, R.id.name_1, R.id.name_2, R.id.name_3, R.id.name_4, R.id.name_5,
        )
        private val TIME_IDS = intArrayOf(
            R.id.time_0, R.id.time_1, R.id.time_2, R.id.time_3, R.id.time_4, R.id.time_5,
        )
        private val CELL_IDS = intArrayOf(
            R.id.cell_0, R.id.cell_1, R.id.cell_2, R.id.cell_3, R.id.cell_4, R.id.cell_5,
        )

        private const val GOLD = 0xFFD4AF37.toInt()
        private const val NAVY = 0xFF0B2D3B.toInt()
        private const val BEIGE = 0xFFF7F5EF.toInt()
        private const val BEIGE_MUTED = 0xA6F7F5EF.toInt()

        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, KibleWidgetProvider::class.java))
            if (ids.isNotEmpty()) render(context, manager, ids)
        }

        private fun render(context: Context, manager: AppWidgetManager, ids: IntArray) {
            val views = RemoteViews(context.packageName, R.layout.kible_widget)
            views.setOnClickPendingIntent(R.id.widget_root, openAppIntent(context))

            val data = KibleData.load(context)
            if (data == null) {
                views.setTextViewText(R.id.location, "Kıble")
                views.setTextViewText(R.id.next_name, "Vakitler için uygulamayı açın")
                views.setViewVisibility(R.id.countdown, View.GONE)
                manager.updateAppWidget(ids, views)
                return
            }

            val now = System.currentTimeMillis()
            val state = data.stateAt(now)
            views.setTextViewText(R.id.location, data.location)
            views.setTextViewText(R.id.hijri, state.today?.hijri ?: "")

            val nextTime = state.nextTime
            if (nextTime != null) {
                views.setTextViewText(R.id.next_name, "${state.nextName} · ${state.nextLabel}")
                views.setViewVisibility(R.id.countdown, View.VISIBLE)
                views.setChronometer(
                    R.id.countdown,
                    SystemClock.elapsedRealtime() + (nextTime - now),
                    null,
                    true,
                )
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    views.setChronometerCountDown(R.id.countdown, true)
                }
            } else {
                views.setTextViewText(R.id.next_name, "Vakitleri yenilemek için uygulamayı açın")
                views.setViewVisibility(R.id.countdown, View.GONE)
            }

            for (i in 0 until 6) {
                val active = i == state.currentIndex
                views.setTextViewText(NAME_IDS[i], data.names.getOrElse(i) { "" })
                views.setTextViewText(TIME_IDS[i], state.today?.labels?.getOrNull(i) ?: "--:--")
                views.setTextColor(NAME_IDS[i], if (active) NAVY else BEIGE_MUTED)
                views.setTextColor(TIME_IDS[i], if (active) NAVY else BEIGE)
                views.setInt(
                    CELL_IDS[i],
                    "setBackgroundResource",
                    if (active) R.drawable.widget_cell_active else android.R.color.transparent,
                )
            }
            views.setTextColor(R.id.countdown, GOLD)
            manager.updateAppWidget(ids, views)
        }

        fun openAppIntent(context: Context): PendingIntent =
            PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
    }
}
