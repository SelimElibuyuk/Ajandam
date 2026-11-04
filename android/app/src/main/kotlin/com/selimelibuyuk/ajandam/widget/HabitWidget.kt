package com.selimelibuyuk.ajandam.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.LocalSize
import androidx.glance.action.ActionParameters
import androidx.glance.action.actionParametersOf
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.appWidgetBackground
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.appwidget.state.updateAppWidgetState
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontFamily
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.selimelibuyuk.ajandam.MainActivity
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.actionStartActivity
import java.time.LocalDate
import java.time.format.TextStyle as DayStyle
import java.util.Locale
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

private const val CHIP_WIDTH = 42
private const val MAX_CHIPS = 14
private const val HEADER_HEIGHT = 26

private val turkish = Locale.forLanguageTag("tr")
private val habitIdKey = ActionParameters.Key<String>("habitId")
private val dayKey = ActionParameters.Key<String>("day")

class HabitWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget = HabitWidget()

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val pending = goAsync()
        CoroutineScope(Dispatchers.Default).launch {
            try {
                refreshHabitWidgets(context)
            } finally {
                pending.finish()
            }
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        HabitSnapshot.forget(HomeWidgetPlugin.getData(context), appWidgetIds)
    }
}

/** Glance, aynı durum nesnesinde yeniden çizmez; önce durum tazelenir. */
suspend fun refreshHabitWidgets(context: Context) {
    val widget = HabitWidget()
    GlanceAppWidgetManager(context).getGlanceIds(HabitWidget::class.java).forEach { id ->
        updateAppWidgetState(context, widget.stateDefinition, id) { it }
        widget.update(context, id)
    }
}

/** Tek bir alışkanlığın zinciri: hafta bandı gibi son günler, en sağda bugün. */
class HabitWidget : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()
    override val sizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val appWidgetId = GlanceAppWidgetManager(context).getAppWidgetId(id)
        provideContent {
            val preferences = currentState<HomeWidgetGlanceState>().preferences
            val snapshot = HabitSnapshot.read(preferences)
            HabitContent(context, snapshot, snapshot.find(HabitSnapshot.habitFor(preferences, appWidgetId)))
        }
    }
}

@Composable
private fun HabitContent(context: Context, snapshot: HabitSnapshot, habit: HabitEntry?) {
    val colors = snapshot.appearance.palette(context)
    val today = LocalDate.now()
    val open =
        actionStartActivity<MainActivity>(
            context,
            Uri.parse(if (habit == null) "ajandam://habit" else "ajandam://habit/${habit.id}"),
        )
    Box(
        modifier =
            GlanceModifier.fillMaxSize()
                .appWidgetBackground()
                .background(snapshot.appearance.background(context))
                .cornerRadius(snapshot.appearance.radius.dp)
                .padding(12.dp),
    ) {
        if (habit == null) {
            Text(
                "Alışkanlık bulunamadı. Widget'ı uzun basıp yeniden ayarla.",
                modifier = GlanceModifier.fillMaxSize().clickable(open),
                style = TextStyle(color = ColorProvider(colors.muted), fontSize = 14.sp),
            )
        } else {
            Chain(context, habit, today, colors, open)
        }
    }
}

@Composable
private fun Chain(
    context: Context,
    habit: HabitEntry,
    today: LocalDate,
    colors: WidgetPalette,
    open: androidx.glance.action.Action,
) {
    val size = LocalSize.current
    val accent = Color(habit.color)
    val scale = context.resources.configuration.fontScale
    val chips = ((size.width.value - 24) / CHIP_WIDTH).toInt().coerceIn(3, MAX_CHIPS)
    val chipHeight = (size.height.value - 24 - HEADER_HEIGHT * scale - 6).coerceIn(30f, 72f)
    val streak = habit.streak(today)

    Column(modifier = GlanceModifier.fillMaxSize()) {
        Row(
            modifier = GlanceModifier.fillMaxWidth().clickable(open),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(modifier = GlanceModifier.size(10.dp).background(accent).cornerRadius(5.dp)) {}
            Spacer(GlanceModifier.width(8.dp))
            Text(
                habit.title,
                maxLines = 1,
                modifier = GlanceModifier.defaultWeight(),
                style =
                    TextStyle(
                        color = ColorProvider(colors.text),
                        fontSize = 17.sp,
                        fontFamily = FontFamily.Serif,
                    ),
            )
            Text(
                if (streak == 0) "seri yok" else "$streak gün",
                style =
                    TextStyle(
                        color = ColorProvider(if (streak == 0) colors.muted else accent),
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Medium,
                    ),
            )
        }
        Spacer(GlanceModifier.height(6.dp))
        Row(modifier = GlanceModifier.fillMaxWidth().height(chipHeight.dp)) {
            for (i in chips - 1 downTo 0) {
                val day = today.minusDays(i.toLong())
                Box(modifier = GlanceModifier.defaultWeight().fillMaxHeight().padding(horizontal = 2.dp)) {
                    DayChip(habit, day, day == today, chipHeight, accent, colors)
                }
            }
        }
    }
}

@Composable
private fun DayChip(
    habit: HabitEntry,
    day: LocalDate,
    isToday: Boolean,
    height: Float,
    accent: Color,
    colors: WidgetPalette,
) {
    val count = habit.count(day)
    val done = count >= habit.goal
    val planned = habit.planned(day)
    val background =
        when {
            done -> accent
            count > 0 -> accent.copy(alpha = 0.35f)
            isToday -> colors.accentSoft
            planned -> colors.container
            else -> Color.Transparent
        }
    val textColor =
        when {
            done -> Color.White
            isToday -> colors.accentText
            planned -> colors.text
            else -> colors.muted
        }
    val tap = actionRunCallback<HabitTapAction>(actionParametersOf(habitIdKey to habit.id, dayKey to day.toString()))
    val showLabel = height >= 44
    val bottom =
        if (habit.goal > 1 && isToday && !done) "$count/${habit.goal}" else "${day.dayOfMonth}"

    // Yalnızca bugün işaretlenir; geçmiş günler zinciri gösterir.
    val chip = GlanceModifier.fillMaxSize().background(background).cornerRadius(10.dp)
    Column(
        modifier = if (isToday) chip.clickable(tap) else chip,
        verticalAlignment = Alignment.CenterVertically,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        if (showLabel) {
            Text(
                day.dayOfWeek.getDisplayName(DayStyle.SHORT, turkish).take(3),
                maxLines = 1,
                style =
                    TextStyle(
                        color = ColorProvider(if (done) Color.White else colors.muted),
                        fontSize = 11.sp,
                        textAlign = TextAlign.Center,
                    ),
            )
        }
        Text(
            bottom,
            maxLines = 1,
            style =
                TextStyle(
                    color = ColorProvider(textColor),
                    fontSize = if (bottom.length > 3) 12.sp else 15.sp,
                    fontWeight = if (done || isToday) FontWeight.Bold else FontWeight.Normal,
                    textAlign = TextAlign.Center,
                ),
        )
    }
}

/** Güne dokununca zincir hemen değişir, kalıcı kaydı arka planda Dart yapar. */
class HabitTapAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters,
    ) {
        val id = parameters[habitIdKey] ?: return
        val day = LocalDate.parse(parameters[dayKey] ?: return)
        if (day != LocalDate.now()) return
        HabitSnapshot.tap(HomeWidgetPlugin.getData(context), id, day, System.currentTimeMillis())
        refreshHabitWidgets(context)
        HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("ajandam://habit-sync")).send()
    }
}
