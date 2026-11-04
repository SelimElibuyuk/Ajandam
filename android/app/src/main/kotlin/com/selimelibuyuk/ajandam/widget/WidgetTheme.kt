package com.selimelibuyuk.ajandam.widget

import android.content.Context
import android.content.res.Configuration
import androidx.compose.ui.graphics.Color
import org.json.JSONObject

/** Widget'ların kullandığı renkler; uygulamadaki seçili temadan gelir. */
class WidgetPalette(
    val surface: Color,
    val container: Color,
    val text: Color,
    val soft: Color,
    val muted: Color,
    val accent: Color,
    val accentSoft: Color,
    val accentText: Color,
    val onAccent: Color,
    val danger: Color,
)

/** Anlık görüntü gelmeden önce ve eksik renklerde kullanılan Nocturne. */
private val nocturneDark =
    WidgetPalette(
        surface = Color(0xFF121316),
        container = Color(0xFF1F1F23),
        text = Color(0xFFE3E2E6),
        soft = Color(0xFFC3C6D1),
        muted = Color(0xFF8D919A),
        accent = Color(0xFF4A6FA5),
        accentSoft = Color(0xFF243247),
        accentText = Color(0xFFA7C8FF),
        onAccent = Color(0xFFEDF1FF),
        danger = Color(0xFFFFB4AB),
    )

private val nocturneLight =
    WidgetPalette(
        surface = Color(0xFFF6F5F1),
        container = Color(0xFFEDECE7),
        text = Color(0xFF1B1C1F),
        soft = Color(0xFF43474F),
        muted = Color(0xFF6E727B),
        accent = Color(0xFF4A6FA5),
        accentSoft = Color(0xFFDCE4F2),
        accentText = Color(0xFF395F94),
        onAccent = Color(0xFFFFFFFF),
        danger = Color(0xFFB3261E),
    )

/**
 * Tema kipi (system | light | dark), seçili temanın açık ve koyu renkleri ve
 * widget ayarları. Yeni bir tema eklendiğinde widget kodu değişmez.
 */
class WidgetAppearance(
    private val mode: String,
    private val dark: WidgetPalette,
    private val light: WidgetPalette,
    /** Arka plan saydamlığı, 0..1 */
    val opacity: Float,
    /** Köşe yuvarlaklığı, dp */
    val radius: Int,
) {
    fun isDark(context: Context): Boolean =
        when (mode) {
            "light" -> false
            "dark" -> true
            else ->
                context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK ==
                    Configuration.UI_MODE_NIGHT_YES
        }

    fun palette(context: Context): WidgetPalette = if (isDark(context)) dark else light

    fun background(context: Context): Color = palette(context).surface.copy(alpha = opacity)

    companion object {
        val DEFAULT = WidgetAppearance("dark", nocturneDark, nocturneLight, 1f, 16)

        fun parse(json: JSONObject): WidgetAppearance {
            val colors = json.optJSONObject("colors")
            val style = json.optJSONObject("widgetStyle")
            return WidgetAppearance(
                mode = json.optString("theme", "dark"),
                dark = palette(colors?.optJSONObject("dark"), nocturneDark),
                light = palette(colors?.optJSONObject("light"), nocturneLight),
                opacity = (style?.optInt("opacity", 100) ?: 100).coerceIn(0, 100) / 100f,
                radius = (style?.optInt("radius", 16) ?: 16).coerceIn(0, 32),
            )
        }

        private fun palette(json: JSONObject?, fallback: WidgetPalette): WidgetPalette {
            fun color(key: String, default: Color): Color {
                val raw = json?.optString(key).orEmpty()
                if (raw.isEmpty()) return default
                return try {
                    Color(android.graphics.Color.parseColor(raw))
                } catch (_: IllegalArgumentException) {
                    default
                }
            }
            return WidgetPalette(
                surface = color("surface", fallback.surface),
                container = color("container", fallback.container),
                text = color("text", fallback.text),
                soft = color("soft", fallback.soft),
                muted = color("muted", fallback.muted),
                accent = color("accent", fallback.accent),
                accentSoft = color("accentSoft", fallback.accentSoft),
                accentText = color("accentText", fallback.accentText),
                onAccent = color("onAccent", fallback.onAccent),
                danger = color("danger", fallback.danger),
            )
        }
    }
}
