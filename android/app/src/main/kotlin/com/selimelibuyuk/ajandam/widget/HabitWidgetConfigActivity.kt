package com.selimelibuyuk.ajandam.widget

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.content.res.ColorStateList
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.RippleDrawable
import android.net.Uri
import android.os.Bundle
import android.text.TextUtils
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup.LayoutParams.MATCH_PARENT
import android.view.ViewGroup.LayoutParams.WRAP_CONTENT
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import com.selimelibuyuk.ajandam.MainActivity
import es.antonborri.home_widget.HomeWidgetPlugin
import java.time.LocalDate
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

private val dayNames = listOf("Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz")

/**
 * Widget eklenirken veya yeniden ayarlanırken hangi alışkanlığı göstereceğini
 * seçtirir. Uygulamanın seçili temasıyla, ortada bir kart olarak açılır.
 */
class HabitWidgetConfigActivity : Activity() {
    private var widgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private lateinit var colors: WidgetPalette

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        widgetId =
            intent?.extras?.getInt(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
                ?: AppWidgetManager.INVALID_APPWIDGET_ID
        setResult(RESULT_CANCELED, result())
        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        val preferences = HomeWidgetPlugin.getData(this)
        val snapshot = HabitSnapshot.read(preferences)
        colors = snapshot.appearance.palette(this)
        val current = HabitSnapshot.habitFor(preferences, widgetId)

        val card =
            LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                setPadding(dp(20), dp(20), dp(20), dp(12))
                background = rounded(colors.surface, 20, stroke = colors.container)
                isClickable = true
            }
        card.addView(label("ALIŞKANLIK ZİNCİRİ"))
        if (snapshot.habits.isEmpty()) {
            card.addView(title("Henüz alışkanlık yok"))
            card.addView(
                body(
                    "Uygulamada Ay ekranının üstündeki + ile bir alışkanlık ekle, " +
                        "sonra widget'ı yeniden ekle.",
                ),
            )
            card.addView(
                actions(
                    textButton("Vazgeç") { finish() },
                    filledButton("Uygulamayı aç") { openApp() },
                ),
            )
        } else {
            card.addView(title("Hangi alışkanlık?"))
            card.addView(body("Widget seçtiğin alışkanlığın son günlerini gösterir."))
            val list = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
            val today = LocalDate.now()
            snapshot.habits.forEach { habit ->
                list.addView(habitRow(habit, today, habit.id == current) { choose(preferences, habit.id) })
            }
            val maxHeight = (resources.displayMetrics.heightPixels * 0.5f).toInt()
            val scroll =
                object : ScrollView(this) {
                    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
                        super.onMeasure(
                            widthMeasureSpec,
                            MeasureSpec.makeMeasureSpec(maxHeight, MeasureSpec.AT_MOST),
                        )
                    }
                }
            scroll.isVerticalScrollBarEnabled = false
            scroll.addView(list)
            card.addView(
                scroll,
                LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT).apply { topMargin = dp(12) },
            )
            card.addView(actions(textButton("Vazgeç") { finish() }))
        }

        val width = minOf(resources.displayMetrics.widthPixels - dp(48), dp(400))
        val root =
            FrameLayout(this).apply {
                setBackgroundColor(0x99000000.toInt())
                setOnClickListener { finish() }
                addView(card, FrameLayout.LayoutParams(width, WRAP_CONTENT, Gravity.CENTER))
            }
        setContentView(root)
    }

    private fun result() = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)

    private fun choose(preferences: android.content.SharedPreferences, habitId: String) {
        HabitSnapshot.assign(preferences, widgetId, habitId)
        setResult(RESULT_OK, result())
        val app = applicationContext
        CoroutineScope(Dispatchers.Default).launch { refreshHabitWidgets(app) }
        finish()
    }

    private fun habitRow(
        habit: HabitEntry,
        today: LocalDate,
        selected: Boolean,
        onClick: () -> Unit,
    ): View {
        val accent = Color(habit.color)
        val row =
            LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                minimumHeight = dp(60)
                setPadding(dp(14), dp(10), dp(14), dp(10))
                background =
                    RippleDrawable(
                        ColorStateList.valueOf(accent.copy(alpha = 0.25f).toArgb()),
                        rounded(colors.container, 12, stroke = if (selected) accent else null),
                        null,
                    )
                setOnClickListener { onClick() }
            }
        row.addView(
            View(this).apply { background = GradientDrawable().apply { shape = GradientDrawable.OVAL; setColor(accent.toArgb()) } },
            LinearLayout.LayoutParams(dp(12), dp(12)).apply { marginEnd = dp(14) },
        )
        val texts = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        texts.addView(
            text(habit.title, 16f, colors.text).apply {
                maxLines = 1
                ellipsize = TextUtils.TruncateAt.END
            },
        )
        val streak = habit.streak(today)
        val rule =
            buildString {
                append(daysLabel(habit.weekdays))
                if (habit.goal > 1) append(" · günde ${habit.goal}")
                if (streak > 0) append(" · $streak gün seri")
            }
        texts.addView(text(rule, 12f, colors.muted))
        row.addView(texts, LinearLayout.LayoutParams(0, WRAP_CONTENT, 1f))
        if (selected) {
            row.addView(text("Seçili", 12f, colors.accentText).apply { typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD) })
        }
        return LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            addView(row, LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT).apply { bottomMargin = dp(8) })
        }
    }

    private fun label(value: String) =
        text(value, 11f, colors.muted).apply {
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            letterSpacing = 0.08f
        }

    private fun title(value: String) =
        text(value, 22f, colors.text).apply {
            typeface = Typeface.SERIF
            setPadding(0, dp(6), 0, 0)
        }

    private fun body(value: String) =
        text(value, 14f, colors.muted).apply {
            setPadding(0, dp(4), 0, 0)
            setLineSpacing(0f, 1.2f)
        }

    private fun text(value: String, size: Float, color: Color) =
        TextView(this).apply {
            text = value
            setTextSize(TypedValue.COMPLEX_UNIT_SP, size)
            setTextColor(color.toArgb())
        }

    private fun textButton(value: String, onClick: () -> Unit) =
        text(value, 14f, colors.accentText).apply {
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            setPadding(dp(16), dp(12), dp(16), dp(12))
            background =
                RippleDrawable(ColorStateList.valueOf(colors.accentSoft.toArgb()), null, rounded(colors.surface, 8))
            setOnClickListener { onClick() }
        }

    private fun filledButton(value: String, onClick: () -> Unit) =
        text(value, 14f, colors.onAccent).apply {
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            setPadding(dp(18), dp(12), dp(18), dp(12))
            background =
                RippleDrawable(
                    ColorStateList.valueOf(colors.onAccent.copy(alpha = 0.2f).toArgb()),
                    rounded(colors.accent, 8),
                    null,
                )
            setOnClickListener { onClick() }
        }

    private fun actions(vararg buttons: View) =
        LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.END or Gravity.CENTER_VERTICAL
            setPadding(0, dp(8), 0, 0)
            buttons.forEach { addView(it, LinearLayout.LayoutParams(WRAP_CONTENT, WRAP_CONTENT).apply { marginStart = dp(8) }) }
        }

    private fun rounded(fill: Color, radius: Int, stroke: Color? = null) =
        GradientDrawable().apply {
            cornerRadius = dp(radius).toFloat()
            setColor(fill.toArgb())
            if (stroke != null) setStroke(dp(1), stroke.toArgb())
        }

    private fun dp(value: Int): Int =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value.toFloat(), resources.displayMetrics).toInt()

    private fun daysLabel(days: Set<Int>): String =
        when {
            days.isEmpty() || days.size == 7 -> "Her gün"
            days == setOf(1, 2, 3, 4, 5) -> "Hafta içi"
            days == setOf(6, 7) -> "Hafta sonu"
            else -> days.sorted().joinToString(", ") { dayNames[it - 1] }
        }

    private fun openApp() {
        startActivity(
            Intent(this, MainActivity::class.java)
                .setAction("es.antonborri.home_widget.action.LAUNCH")
                .setData(Uri.parse("ajandam://habit"))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        )
        finish()
    }
}
