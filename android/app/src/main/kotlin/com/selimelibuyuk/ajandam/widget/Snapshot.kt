package com.selimelibuyuk.ajandam.widget

import android.content.SharedPreferences
import java.time.LocalDate
import org.json.JSONArray
import org.json.JSONObject

private const val SNAPSHOT_KEY = "snapshot"
private const val PENDING_KEY = "pending_actions"

data class WidgetItem(
    val id: String,
    val title: String,
    val time: String?,
    val isTask: Boolean,
    val done: Boolean,
    val startMs: Long?,
    val endMs: Long?,
    val day: String,
) {
    fun isFinished(now: Long): Boolean = done || (!isTask && endMs != null && endMs < now)

    fun isOverdue(now: Long): Boolean =
        isTask && !done && (if (startMs != null) startMs < now else day < LocalDate.now().toString())
}

/** Uygulamanın yazdığı anlık görüntü. Widget ağa çıkmaz, yalnızca bunu okur. */
class Snapshot(
    val tapMode: String,
    val theme: String,
    private val days: Map<String, List<WidgetItem>>,
) {
    /** Sıra: süresi geçenler, saatliler, saatsizler. Dünden kalanlar da eklenir. */
    fun itemsFor(today: LocalDate, now: Long): List<WidgetItem> {
        val carried =
            days[today.minusDays(1).toString()].orEmpty().filter { it.isTask && !it.done }
        val all = (carried + days[today.toString()].orEmpty()).distinctBy { it.id }
        val (overdue, rest) = all.partition { it.isOverdue(now) }
        val (timed, untimed) = rest.partition { it.startMs != null }
        return overdue + timed.sortedBy { it.startMs } + untimed
    }

    companion object {
        fun read(preferences: SharedPreferences): Snapshot {
            val raw = preferences.getString(SNAPSHOT_KEY, null)
                ?: return Snapshot("week_view", "dark", emptyMap())
            return try {
                parse(JSONObject(raw))
            } catch (_: org.json.JSONException) {
                Snapshot("week_view", "dark", emptyMap())
            }
        }

        private fun parse(json: JSONObject): Snapshot {
            val days = mutableMapOf<String, List<WidgetItem>>()
            val array = json.getJSONArray("days")
            for (i in 0 until array.length()) {
                val day = array.getJSONObject(i)
                val date = day.getString("date")
                val items = day.getJSONArray("items")
                days[date] = List(items.length()) { parseItem(items.getJSONObject(it), date) }
            }
            return Snapshot(json.optString("tapMode", "week_view"), json.optString("theme", "dark"), days)
        }

        private fun parseItem(json: JSONObject, day: String) =
            WidgetItem(
                id = json.getString("id"),
                title = json.getString("title"),
                time = json.optString("time").ifEmpty { null },
                isTask = json.getString("kind") == "task",
                done = json.optBoolean("done"),
                startMs = json.optLong("startMs").takeIf { json.has("startMs") },
                endMs = json.optLong("endMs").takeIf { json.has("endMs") },
                day = json.optString("day", day),
            )

        /** Durumu anlık görüntüde çevirir ve Dart'ın işleyeceği sıraya ekler. */
        fun toggle(preferences: SharedPreferences, id: String, now: Long) {
            val raw = preferences.getString(SNAPSHOT_KEY, null) ?: return
            val json = JSONObject(raw)
            var done: Boolean? = null
            val days = json.getJSONArray("days")
            for (i in 0 until days.length()) {
                val items = days.getJSONObject(i).getJSONArray("items")
                for (j in 0 until items.length()) {
                    val item = items.getJSONObject(j)
                    if (item.getString("id") == id) {
                        done = !item.optBoolean("done")
                        item.put("done", done)
                    }
                }
            }
            val next = done ?: return
            val pending = JSONArray(preferences.getString(PENDING_KEY, null) ?: "[]")
            pending.put(JSONObject().put("id", id).put("done", next).put("at", now))
            preferences
                .edit()
                .putString(SNAPSHOT_KEY, json.toString())
                .putString(PENDING_KEY, pending.toString())
                .commit()
        }
    }
}
