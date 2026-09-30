package com.kible.kible

import android.content.Context
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/** Flutter tarafının yazdığı vakit verisi (bkz. lib/services/widget_service.dart). */
class KibleData(
    val location: String,
    val names: List<String>,
    private val days: List<Day>,
) {
    class Day(val date: String, val hijri: String, val times: LongArray, val labels: List<String>)

    /** O anki ve sıradaki vakit. */
    class State(
        val today: Day?,
        /** Bugünün listesinde vurgulanacak vakit (0–5), yoksa -1. */
        val currentIndex: Int,
        val nextName: String?,
        val nextLabel: String?,
        val nextTime: Long?,
    )

    fun stateAt(now: Long): State {
        val todayKey = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date(now))
        val today = days.firstOrNull { it.date == todayKey }

        var nextName: String? = null
        var nextLabel: String? = null
        var nextTime: Long? = null
        loop@ for (day in days) {
            for (i in day.times.indices) {
                if (day.times[i] > now) {
                    nextName = names.getOrNull(i)
                    nextLabel = day.labels.getOrNull(i)
                    nextTime = day.times[i]
                    break@loop
                }
            }
        }

        val currentIndex = today?.times?.indexOfLast { it <= now } ?: -1
        return State(today, currentIndex, nextName, nextLabel, nextTime)
    }

    companion object {
        const val DATA_KEY = "kible_data"
        const val ONGOING_KEY = "kible_ongoing"

        fun load(context: Context): KibleData? {
            val raw = HomeWidgetPlugin.getData(context).getString(DATA_KEY, null) ?: return null
            return try {
                val json = JSONObject(raw)
                val names = json.getJSONArray("names").let { a -> List(a.length()) { a.getString(it) } }
                val daysJson = json.getJSONArray("days")
                val days = List(daysJson.length()) { i ->
                    val d = daysJson.getJSONObject(i)
                    val t = d.getJSONArray("t")
                    val l = d.getJSONArray("l")
                    Day(
                        date = d.getString("d"),
                        hijri = d.optString("h"),
                        times = LongArray(t.length()) { t.getLong(it) },
                        labels = List(l.length()) { l.getString(it) },
                    )
                }
                KibleData(json.optString("location", "Trabzon"), names, days)
            } catch (e: Exception) {
                null
            }
        }

        fun ongoingEnabled(context: Context): Boolean =
            HomeWidgetPlugin.getData(context).getBoolean(ONGOING_KEY, false)
    }
}
