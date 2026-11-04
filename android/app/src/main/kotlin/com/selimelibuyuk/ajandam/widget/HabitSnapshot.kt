package com.selimelibuyuk.ajandam.widget

import android.content.SharedPreferences
import java.time.LocalDate
import java.time.format.DateTimeParseException
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

private const val HABITS_KEY = "habits"
private const val HABIT_PENDING_KEY = "habit_actions"
private const val WIDGET_HABIT_PREFIX = "habit_widget_"

/** Uygulamanın yazdığı alışkanlık; sayılar son 35 günü, daha eskisi tek seri sayısını taşır. */
class HabitEntry(
    val id: String,
    val title: String,
    val color: Long,
    val goal: Int,
    val weekdays: Set<Int>,
    private val olderStreak: Int,
    private val windowStart: LocalDate,
    private val counts: Map<String, Int>,
    private val frozenDays: Set<String> = emptySet(),
) {
    fun count(day: LocalDate): Int = counts[day.toString()] ?: 0

    fun done(day: LocalDate): Boolean = count(day) >= goal

    /** Dondurulan gün seriyi bozmaz ama sayılmaz; sonradan yapılırsa yapılmış sayılır. */
    fun frozen(day: LocalDate): Boolean = day.toString() in frozenDays && !done(day)

    fun planned(day: LocalDate): Boolean = weekdays.isEmpty() || day.dayOfWeek.value in weekdays

    /**
     * Uygulamadaki HabitHistory.streak ile aynı: bugün yapılmadıysa seri dünden sayılır,
     * dondurulan günler planlanmamış gün gibi atlanır.
     */
    fun streak(today: LocalDate): Int {
        var day = if (done(today)) today else today.minusDays(1)
        var count = 0
        while (true) {
            if (day < windowStart) return count + olderStreak
            if (planned(day) && !frozen(day)) {
                if (!done(day)) return count
                count++
            }
            day = day.minusDays(1)
        }
    }
}

class HabitSnapshot(val appearance: WidgetAppearance, val habits: List<HabitEntry>) {
    fun find(id: String?): HabitEntry? = habits.firstOrNull { it.id == id }

    companion object {
        fun read(preferences: SharedPreferences): HabitSnapshot {
            val raw = preferences.getString(HABITS_KEY, null) ?: return HabitSnapshot(WidgetAppearance.DEFAULT, emptyList())
            return try {
                parse(JSONObject(raw))
            } catch (_: JSONException) {
                HabitSnapshot(WidgetAppearance.DEFAULT, emptyList())
            } catch (_: DateTimeParseException) {
                // Bozuk tarih seçim penceresini veya widget'ı çökertmesin
                HabitSnapshot(WidgetAppearance.DEFAULT, emptyList())
            }
        }

        private fun parse(json: JSONObject): HabitSnapshot {
            val windowStart = LocalDate.parse(json.getString("windowStart"))
            val array = json.getJSONArray("habits")
            val habits =
                List(array.length()) { i ->
                    val habit = array.getJSONObject(i)
                    val days = habit.getJSONArray("weekdays")
                    val counts = habit.getJSONObject("counts")
                    // Eski anlık görüntülerde yok.
                    val frozen = habit.optJSONArray("frozen") ?: JSONArray()
                    HabitEntry(
                        id = habit.getString("id"),
                        title = habit.getString("title"),
                        color = habit.getLong("color"),
                        goal = habit.optInt("goal", 1).coerceAtLeast(1),
                        weekdays = List(days.length()) { days.getInt(it) }.toSet(),
                        olderStreak = habit.optInt("olderStreak"),
                        windowStart = windowStart,
                        counts = counts.keys().asSequence().associateWith { counts.getInt(it) },
                        frozenDays = List(frozen.length()) { frozen.getString(it) }.toSet(),
                    )
                }
            return HabitSnapshot(WidgetAppearance.parse(json), habits)
        }

        fun habitFor(preferences: SharedPreferences, appWidgetId: Int): String? =
            preferences.getString("$WIDGET_HABIT_PREFIX$appWidgetId", null)

        fun assign(preferences: SharedPreferences, appWidgetId: Int, habitId: String) {
            preferences.edit().putString("$WIDGET_HABIT_PREFIX$appWidgetId", habitId).commit()
        }

        fun forget(preferences: SharedPreferences, appWidgetIds: IntArray) {
            val edit = preferences.edit()
            appWidgetIds.forEach { edit.remove("$WIDGET_HABIT_PREFIX$it") }
            edit.commit()
        }

        /**
         * Dokunulan günün sayısını uygulamadaki gibi artırır, hedefteyse sıfırlar.
         * Mutlak sayı Dart'ın işleyeceği sıraya eklenir.
         */
        fun tap(preferences: SharedPreferences, habitId: String, day: LocalDate, now: Long) {
            val raw = preferences.getString(HABITS_KEY, null) ?: return
            val json = JSONObject(raw)
            val habits = json.getJSONArray("habits")
            var next: Int? = null
            for (i in 0 until habits.length()) {
                val habit = habits.getJSONObject(i)
                if (habit.getString("id") != habitId) continue
                val counts = habit.getJSONObject("counts")
                val goal = habit.optInt("goal", 1).coerceAtLeast(1)
                val current = counts.optInt(day.toString())
                val value = if (current >= goal) 0 else current + 1
                if (value == 0) counts.remove(day.toString()) else counts.put(day.toString(), value)
                next = value
            }
            val count = next ?: return
            val pending = JSONArray(preferences.getString(HABIT_PENDING_KEY, null) ?: "[]")
            pending.put(
                JSONObject().put("id", habitId).put("day", day.toString()).put("count", count).put("at", now),
            )
            preferences
                .edit()
                .putString(HABITS_KEY, json.toString())
                .putString(HABIT_PENDING_KEY, pending.toString())
                .commit()
        }
    }
}
