package com.selimelibuyuk.ajandam.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.res.Configuration
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.ColorFilter
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalSize
import androidx.glance.action.Action
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
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.lazy.items
import androidx.glance.appwidget.provideContent
import androidx.glance.appwidget.state.updateAppWidgetState
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontFamily
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextDecoration
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.selimelibuyuk.ajandam.MainActivity
import com.selimelibuyuk.ajandam.R
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.actionStartActivity
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

private val SMALL = DpSize(110.dp, 110.dp)
private val MEDIUM = DpSize(250.dp, 110.dp)
private val LARGE = DpSize(250.dp, 250.dp)

private const val ROW_HEIGHT = 34
private const val COMPACT_ROW_HEIGHT = 28
private const val HEADER_HEIGHT = 44
private const val PLUS_CLEARANCE = 40
private const val FOOTER_ID = -1L

private val turkish = Locale.forLanguageTag("tr")
private val dayFormat = DateTimeFormatter.ofPattern("d MMMM", turkish)
private val fullDayFormat = DateTimeFormatter.ofPattern("EEEE, d MMMM", turkish)
private val weekdayFormat = DateTimeFormatter.ofPattern("EEEE", turkish)

private val itemIdKey = ActionParameters.Key<String>("itemId")

private class Palette(
    val surface: Color,
    val text: Color,
    val soft: Color,
    val muted: Color,
    val accent: Color,
    val accentText: Color,
    val onAccent: Color,
    val danger: Color,
)

private val darkPalette =
    Palette(
        surface = Color(0xFF121316),
        text = Color(0xFFE3E2E6),
        soft = Color(0xFFC3C6D1),
        muted = Color(0xFF8D919A),
        accent = Color(0xFF4A6FA5),
        accentText = Color(0xFFA7C8FF),
        onAccent = Color(0xFFEDF1FF),
        danger = Color(0xFFFFB4AB),
    )

private val lightPalette =
    Palette(
        surface = Color(0xFFF6F5F1),
        text = Color(0xFF1B1C1F),
        soft = Color(0xFF43474F),
        muted = Color(0xFF6E727B),
        accent = Color(0xFF4A6FA5),
        accentText = Color(0xFF395F94),
        onAccent = Color(0xFFFFFFFF),
        danger = Color(0xFFB3261E),
    )

/** Eklentinin alıcısı runBlocking ile ana iş parçacığını kilitlediği için kullanılmaz. */
class AjandamWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget = AjandamWidget()

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val pending = goAsync()
        CoroutineScope(Dispatchers.Default).launch {
            try {
                refreshAll(context)
            } finally {
                pending.finish()
            }
        }
    }
}

/** Glance, aynı durum nesnesinde yeniden çizmez; önce durum tazelenir. */
private suspend fun refreshAll(context: Context) {
    val widget = AjandamWidget()
    GlanceAppWidgetManager(context).getGlanceIds(AjandamWidget::class.java).forEach { id ->
        updateAppWidgetState(context, widget.stateDefinition, id) { it }
        widget.update(context, id)
    }
}

class AjandamWidget : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()
    override val sizeMode = SizeMode.Responsive(setOf(SMALL, MEDIUM, LARGE))

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val state = currentState<HomeWidgetGlanceState>()
            Content(context, Snapshot.read(state.preferences))
        }
    }
}

@Composable
private fun Content(context: Context, snapshot: Snapshot) {
    val today = LocalDate.now()
    val now = System.currentTimeMillis()
    val items = snapshot.itemsFor(today, now)
    val remaining = items.count { !it.isFinished(now) }
    val colors = paletteFor(context, snapshot.theme)
    val quickAdd = "ajandam://quick-add?date=$today"
    val bodyLink = if (snapshot.tapMode == "quick_add") quickAdd else "ajandam://week?focus=$today"
    val body = actionStartActivity<MainActivity>(context, Uri.parse(bodyLink))
    val size = LocalSize.current

    Box(
        modifier =
            GlanceModifier.fillMaxSize()
                .appWidgetBackground()
                .background(colors.surface)
                .cornerRadius(16.dp)
                .clickable(body),
    ) {
        if (size.width < MEDIUM.width) {
            SmallContent(context, items, today, now, remaining, colors, body)
        } else {
            WideContent(context, items, today, now, remaining, colors, body)
        }
        Box(
            modifier = GlanceModifier.fillMaxSize().padding(10.dp),
            contentAlignment = Alignment.BottomEnd,
        ) {
            Box(
                modifier =
                    GlanceModifier.size(34.dp)
                        .background(colors.accent)
                        .cornerRadius(10.dp)
                        .clickable(actionStartActivity<MainActivity>(context, Uri.parse(quickAdd))),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    "+",
                    style = TextStyle(color = ColorProvider(colors.onAccent), fontSize = 20.sp),
                )
            }
        }
    }
}

@Composable
private fun SmallContent(
    context: Context,
    items: List<WidgetItem>,
    today: LocalDate,
    now: Long,
    remaining: Int,
    colors: Palette,
    body: Action,
) {
    Column(modifier = GlanceModifier.fillMaxSize().padding(12.dp, 10.dp, 10.dp, 0.dp)) {
        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                today.format(dayFormat),
                maxLines = 1,
                modifier = GlanceModifier.defaultWeight(),
                style =
                    TextStyle(
                        color = ColorProvider(colors.text),
                        fontSize = 16.sp,
                        fontFamily = FontFamily.Serif,
                    ),
            )
            if (remaining > 0) {
                Text(
                    "$remaining",
                    style = TextStyle(color = ColorProvider(colors.accentText), fontSize = 12.sp),
                )
            }
        }
        Spacer(GlanceModifier.height(2.dp))
        ItemList(context, items, now, colors, body, compact = true)
    }
}

@Composable
private fun WideContent(
    context: Context,
    items: List<WidgetItem>,
    today: LocalDate,
    now: Long,
    remaining: Int,
    colors: Palette,
    body: Action,
) {
    Column(modifier = GlanceModifier.fillMaxSize().padding(14.dp, 12.dp, 14.dp, 0.dp)) {
        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                today.format(fullDayFormat),
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
                remainingLabel(remaining, items.isEmpty()),
                style = TextStyle(color = ColorProvider(colors.muted), fontSize = 11.sp),
            )
        }
        Spacer(GlanceModifier.height(4.dp))
        ItemList(context, items, now, colors, body, compact = false)
    }
}

/** Satırlar sığıyorsa boş alan dokunulabilir kalır, sığmıyorsa liste kayar. */
@Composable
private fun ItemList(
    context: Context,
    items: List<WidgetItem>,
    now: Long,
    colors: Palette,
    body: Action,
    compact: Boolean,
) {
    val rowHeight = if (compact) COMPACT_ROW_HEIGHT else ROW_HEIGHT
    val available = LocalSize.current.height.value - HEADER_HEIGHT
    when {
        items.isEmpty() ->
            Text(
                "Bugün boş.",
                style = TextStyle(color = ColorProvider(colors.muted), fontSize = 13.sp),
            )
        items.size * rowHeight <= available - PLUS_CLEARANCE ->
            items.forEach { item -> ItemRow(context, item, now, colors, compact) }
        else ->
            LazyColumn(modifier = GlanceModifier.fillMaxSize()) {
                items(items, itemId = { it.id.hashCode().toLong() }) { item ->
                    ItemRow(context, item, now, colors, compact)
                }
                // Son satır + düğmesinin altında kalmasın.
                item(itemId = FOOTER_ID) {
                    Box(
                        modifier = GlanceModifier.fillMaxWidth().height(PLUS_CLEARANCE.dp).clickable(body),
                    ) {}
                }
            }
    }
}

@Composable
private fun ItemRow(
    context: Context,
    item: WidgetItem,
    now: Long,
    colors: Palette,
    compact: Boolean,
) {
    val finished = item.isFinished(now)
    val overdue = item.isOverdue(now)
    val titleColor =
        when {
            overdue -> colors.danger
            finished -> colors.muted
            else -> colors.text
        }
    val open = actionStartActivity<MainActivity>(context, Uri.parse("ajandam://item/${item.id}"))

    Row(
        modifier = GlanceModifier.fillMaxWidth().height((if (compact) COMPACT_ROW_HEIGHT else ROW_HEIGHT).dp).clickable(open),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Mark(item, finished, overdue, colors, if (compact) 26.dp else 32.dp)
        if (item.time != null && !compact) {
            Text(
                item.time,
                modifier = GlanceModifier.width(46.dp),
                style =
                    TextStyle(
                        color = ColorProvider(if (overdue) colors.danger else colors.accentText),
                        fontSize = 11.sp,
                        fontFamily = FontFamily.Monospace,
                    ),
            )
        }
        Text(
            if (compact && item.time != null) "${item.time} ${item.title}" else item.title,
            maxLines = 1,
            style =
                TextStyle(
                    color = ColorProvider(titleColor),
                    fontSize = if (compact) 12.sp else 14.sp,
                    fontWeight = FontWeight.Normal,
                    textDecoration = if (finished) TextDecoration.LineThrough else null,
                ),
        )
    }
}

@Composable
private fun Mark(
    item: WidgetItem,
    finished: Boolean,
    overdue: Boolean,
    colors: Palette,
    width: androidx.compose.ui.unit.Dp,
) {
    val tint = if (overdue) colors.danger else if (finished) colors.accent else colors.muted
    val base = GlanceModifier.width(width).height(30.dp)
    if (item.isTask) {
        Box(
            modifier =
                base.clickable(
                    actionRunCallback<ToggleDoneAction>(actionParametersOf(itemIdKey to item.id)),
                ),
            contentAlignment = Alignment.CenterStart,
        ) {
            Image(
                provider = ImageProvider(if (item.done) R.drawable.widget_box_done else R.drawable.widget_box),
                contentDescription = if (item.done) "Tamamlandı" else "Tamamla",
                colorFilter = ColorFilter.tint(ColorProvider(tint)),
                modifier = GlanceModifier.size(17.dp),
            )
        }
    } else {
        Box(modifier = base, contentAlignment = Alignment.CenterStart) {
            if (finished) {
                Image(
                    provider = ImageProvider(R.drawable.widget_box_done),
                    contentDescription = "Bitti",
                    colorFilter = ColorFilter.tint(ColorProvider(colors.accent)),
                    modifier = GlanceModifier.size(17.dp),
                )
            } else {
                Box(
                    modifier =
                        GlanceModifier.padding(start = 6.dp).width(3.dp).height(16.dp).background(colors.accent),
                ) {}
            }
        }
    }
}

private fun remainingLabel(remaining: Int, empty: Boolean): String =
    when {
        empty -> "Bugün boş"
        remaining == 0 -> "Hepsi bitti"
        else -> "$remaining iş kaldı"
    }

private fun paletteFor(context: Context, theme: String): Palette {
    val nightMask = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
    val dark =
        when (theme) {
            "light" -> false
            "dark" -> true
            else -> nightMask == Configuration.UI_MODE_NIGHT_YES
        }
    return if (dark) darkPalette else lightPalette
}

/** Kutuya dokununca ekran hemen değişir, kalıcı kaydı arka planda Dart yapar. */
class ToggleDoneAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters,
    ) {
        val id = parameters[itemIdKey] ?: return
        Snapshot.toggle(HomeWidgetPlugin.getData(context), id, System.currentTimeMillis())
        refreshAll(context)
        HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("ajandam://sync")).send()
    }
}
