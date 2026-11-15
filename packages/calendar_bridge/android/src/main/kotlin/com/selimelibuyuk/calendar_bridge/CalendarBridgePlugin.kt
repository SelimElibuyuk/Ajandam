package com.selimelibuyuk.calendar_bridge

import android.Manifest
import android.accounts.Account
import android.app.Activity
import android.content.ContentResolver
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.database.ContentObserver
import android.database.Cursor
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.CalendarContract.Calendars
import android.provider.CalendarContract.Events
import android.provider.CalendarContract.Instances
import android.provider.CalendarContract
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.util.TimeZone
import java.util.concurrent.Executors

/**
 * Telefonun takvim sağlayıcısına (CalendarContract) erişim. Google hesabının
 * takvimi bu sağlayıcıyla senkronlanır; buraya yazılan etkinlikleri Android
 * Google'a gönderir. Eşleme kuralları Dart tarafındadır, burada yalnızca okuma
 * ve yazma yapılır.
 */
class CalendarBridgePlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler,
    ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {

    private lateinit var context: Context
    private lateinit var methods: MethodChannel
    private lateinit var changes: EventChannel
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    private var activity: ActivityPluginBinding? = null
    private var pendingPermission: MethodChannel.Result? = null
    private var observer: ContentObserver? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methods = MethodChannel(binding.binaryMessenger, "ajandam/calendar")
        methods.setMethodCallHandler(this)
        changes = EventChannel(binding.binaryMessenger, "ajandam/calendar/changes")
        changes.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methods.setMethodCallHandler(null)
        changes.setStreamHandler(null)
        stopObserving()
        io.shutdown()
    }

    // region İzin

    private fun granted(): Boolean =
        context.checkSelfPermission(Manifest.permission.READ_CALENDAR) == PackageManager.PERMISSION_GRANTED &&
            context.checkSelfPermission(Manifest.permission.WRITE_CALENDAR) == PackageManager.PERMISSION_GRANTED

    private fun requestPermission(result: MethodChannel.Result) {
        if (granted()) return result.success(true)
        val current: Activity? = activity?.activity
        if (current == null || pendingPermission != null) return result.success(false)
        pendingPermission = result
        current.requestPermissions(
            arrayOf(Manifest.permission.READ_CALENDAR, Manifest.permission.WRITE_CALENDAR),
            PERMISSION_REQUEST,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST) return false
        pendingPermission?.success(granted())
        pendingPermission = null
        return true
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        onAttachedToActivity(binding)

    override fun onDetachedFromActivity() {
        activity?.removeRequestPermissionsResultListener(this)
        activity = null
    }

    // endregion

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasPermission" -> return result.success(granted())
            "requestPermission" -> return requestPermission(result)
            "timeZone" -> return result.success(TimeZone.getDefault().id)
        }
        if (!granted()) return result.error("permission", "Takvim izni yok", null)
        io.execute {
            try {
                val value: Any? =
                    when (call.method) {
                        "calendars" -> calendars()
                        "events" -> events(call)
                        "instances" -> instances(call)
                        "insert" -> insert(call)
                        "update" -> update(call)
                        "delete" -> delete(call)
                        "insertException" -> insertException(call)
                        "requestSync" -> requestSync(call)
                        else -> {
                            main.post { result.notImplemented() }
                            return@execute
                        }
                    }
                main.post { result.success(value) }
            } catch (e: Exception) {
                main.post { result.error("calendar", e.message ?: e.javaClass.simpleName, null) }
            }
        }
    }

    // region Okuma

    private val resolver: ContentResolver get() = context.contentResolver

    private fun calendars(): List<Map<String, Any?>> {
        val columns =
            arrayOf(
                Calendars._ID,
                Calendars.CALENDAR_DISPLAY_NAME,
                Calendars.ACCOUNT_NAME,
                Calendars.ACCOUNT_TYPE,
                Calendars.CALENDAR_COLOR,
                Calendars.CALENDAR_ACCESS_LEVEL,
                Calendars.VISIBLE,
                Calendars.IS_PRIMARY,
                Calendars.OWNER_ACCOUNT,
            )
        val out = mutableListOf<Map<String, Any?>>()
        resolver.query(Calendars.CONTENT_URI, columns, "${Calendars.SYNC_EVENTS}=1", null, null)?.use { c ->
            while (c.moveToNext()) {
                val account = c.str(2)
                val owner = c.str(8)
                val primary = if (c.isNull(7)) owner != null && owner == account else c.getInt(7) == 1
                out +=
                    mapOf(
                        "id" to c.getLong(0),
                        "name" to (c.str(1) ?: ""),
                        "account" to (account ?: ""),
                        "accountType" to (c.str(3) ?: ""),
                        "color" to (if (c.isNull(4)) null else c.getInt(4)),
                        "accessLevel" to (if (c.isNull(5)) 0 else c.getInt(5)),
                        "visible" to (!c.isNull(6) && c.getInt(6) == 1),
                        "primary" to primary,
                    )
            }
        }
        return out
    }

    private fun ids(call: MethodCall, key: String): List<Long> =
        (call.argument<List<Number>>(key) ?: emptyList()).map { it.toLong() }

    /** Aralıkla kesişen satırlar: tekli etkinlikler, seriler ve seri istisnaları. */
    private fun events(call: MethodCall): List<Map<String, Any?>> {
        val calendars = ids(call, "calendarIds")
        if (calendars.isEmpty()) return emptyList()
        val from = call.argument<Number>("from")!!.toLong()
        val to = call.argument<Number>("to")!!.toLong()
        val columns =
            arrayOf(
                Events._ID,
                Events.CALENDAR_ID,
                Events.TITLE,
                Events.DESCRIPTION,
                Events.DTSTART,
                Events.DTEND,
                Events.DURATION,
                Events.ALL_DAY,
                Events.RRULE,
                Events.EXDATE,
                Events.ORIGINAL_ID,
                Events.ORIGINAL_INSTANCE_TIME,
                Events.STATUS,
                Events.EVENT_TIMEZONE,
                Events.RDATE,
            )
        val selection =
            "${Events.CALENDAR_ID} IN (${calendars.joinToString(",")}) AND ${Events.DELETED}=0 AND " +
                "${Events.DTSTART} IS NOT NULL AND ${Events.DTSTART} < ? AND " +
                "(${Events.LAST_DATE} IS NULL OR ${Events.LAST_DATE} >= ?)"
        val out = mutableListOf<Map<String, Any?>>()
        resolver.query(Events.CONTENT_URI, columns, selection, arrayOf("$to", "$from"), null)?.use { c ->
            while (c.moveToNext()) {
                val start = c.getLong(4)
                val allDay = !c.isNull(7) && c.getInt(7) == 1
                val end =
                    if (!c.isNull(5) && c.getLong(5) > 0) {
                        c.getLong(5)
                    } else {
                        start + (parseDuration(c.str(6)) ?: if (allDay) DAY else HOUR)
                    }
                out +=
                    mapOf(
                        "id" to c.getLong(0),
                        "calendarId" to c.getLong(1),
                        "title" to c.str(2),
                        "description" to c.str(3),
                        "start" to start,
                        "end" to end,
                        "allDay" to allDay,
                        "rrule" to c.str(8),
                        "exdate" to c.str(9),
                        "originalId" to (if (c.isNull(10)) null else c.getLong(10)),
                        "originalInstanceTime" to (if (c.isNull(11)) null else c.getLong(11)),
                        "canceled" to (!c.isNull(12) && c.getInt(12) == Events.STATUS_CANCELED),
                        "timeZone" to c.str(13),
                        "rdate" to c.str(14),
                    )
            }
        }
        return out
    }

    /** Uygulamanın çözemediği tekrar kuralları için açılmış tekrarlar. */
    private fun instances(call: MethodCall): List<Map<String, Any?>> {
        val events = ids(call, "eventIds")
        if (events.isEmpty()) return emptyList()
        val from = call.argument<Number>("from")!!.toLong()
        val to = call.argument<Number>("to")!!.toLong()
        val uri =
            Instances.CONTENT_URI.buildUpon().also {
                ContentUris.appendId(it, from)
                ContentUris.appendId(it, to)
            }.build()
        val columns =
            arrayOf(
                Instances.EVENT_ID,
                Instances.BEGIN,
                Instances.END,
                Instances.ALL_DAY,
                Instances.TITLE,
                Instances.DESCRIPTION,
                Instances.CALENDAR_ID,
                Instances.STATUS,
            )
        val out = mutableListOf<Map<String, Any?>>()
        resolver.query(uri, columns, "${Instances.EVENT_ID} IN (${events.joinToString(",")})", null, null)?.use { c ->
            while (c.moveToNext()) {
                out +=
                    mapOf(
                        "eventId" to c.getLong(0),
                        "begin" to c.getLong(1),
                        "end" to c.getLong(2),
                        "allDay" to (!c.isNull(3) && c.getInt(3) == 1),
                        "title" to c.str(4),
                        "description" to c.str(5),
                        "calendarId" to c.getLong(6),
                        "canceled" to (!c.isNull(7) && c.getInt(7) == Events.STATUS_CANCELED),
                    )
            }
        }
        return out
    }

    // endregion

    // region Yazma

    /**
     * Tekrarlayan etkinlikte sağlayıcı DTEND değil DURATION ister. Tüm gün
     * etkinlik UTC gece yarısında başlar ve UTC saat diliminde tutulur.
     */
    private fun eventValues(call: MethodCall): ContentValues {
        val start = call.argument<Number>("start")!!.toLong()
        val end = call.argument<Number>("end")!!.toLong()
        val allDay = call.argument<Boolean>("allDay") ?: false
        val rrule = call.argument<String>("rrule")
        return ContentValues().apply {
            put(Events.TITLE, call.argument<String>("title"))
            put(Events.DESCRIPTION, call.argument<String>("description"))
            put(Events.DTSTART, start)
            put(Events.ALL_DAY, if (allDay) 1 else 0)
            put(
                Events.EVENT_TIMEZONE,
                if (allDay) "UTC" else call.argument<String>("timeZone") ?: TimeZone.getDefault().id,
            )
            if (rrule != null) {
                put(Events.RRULE, rrule)
                val length = (end - start).coerceAtLeast(0)
                put(Events.DURATION, if (allDay) "P${maxOf(1, length / DAY)}D" else "P${length / 1000}S")
                putNull(Events.DTEND)
            } else {
                putNull(Events.RRULE)
                putNull(Events.DURATION)
                put(Events.DTEND, end)
            }
        }
    }

    private fun insert(call: MethodCall): Long {
        val values = eventValues(call)
        values.put(Events.CALENDAR_ID, call.argument<Number>("calendarId")!!.toLong())
        val uri = resolver.insert(Events.CONTENT_URI, values) ?: error("Etkinlik eklenemedi")
        return ContentUris.parseId(uri)
    }

    private fun update(call: MethodCall): Boolean {
        val id = call.argument<Number>("id")!!.toLong()
        val values = eventValues(call)
        call.argument<Number>("calendarId")?.let { values.put(Events.CALENDAR_ID, it.toLong()) }
        return resolver.update(ContentUris.withAppendedId(Events.CONTENT_URI, id), values, null, null) > 0
    }

    private fun delete(call: MethodCall): Boolean {
        val id = call.argument<Number>("id")!!.toLong()
        return resolver.delete(ContentUris.withAppendedId(Events.CONTENT_URI, id), null, null) > 0
    }

    /** Serinin tek tekrarını değiştirir ya da iptal eder; yeni satırın kimliği döner. */
    private fun insertException(call: MethodCall): Long {
        val parent = call.argument<Number>("parentId")!!.toLong()
        val values =
            if (call.argument<Boolean>("canceled") == true) {
                ContentValues().apply { put(Events.STATUS, Events.STATUS_CANCELED) }
            } else {
                eventValues(call)
            }
        values.put(Events.ORIGINAL_INSTANCE_TIME, call.argument<Number>("originalInstanceTime")!!.toLong())
        val uri =
            resolver.insert(Uri.withAppendedPath(Events.CONTENT_EXCEPTION_URI, parent.toString()), values)
                ?: error("Tekrar değiştirilemedi")
        return ContentUris.parseId(uri)
    }

    /** Değişikliklerin Google'a hemen gitmesi için hesapların senkronunu ister. */
    private fun requestSync(call: MethodCall): Boolean {
        val calendars = ids(call, "calendarIds")
        if (calendars.isEmpty()) return false
        val accounts = mutableSetOf<Account>()
        resolver.query(
            Calendars.CONTENT_URI,
            arrayOf(Calendars.ACCOUNT_NAME, Calendars.ACCOUNT_TYPE),
            "${Calendars._ID} IN (${calendars.joinToString(",")})",
            null,
            null,
        )?.use { c ->
            while (c.moveToNext()) {
                val name = c.str(0)
                val type = c.str(1)
                if (name != null && type != null && type != CalendarContract.ACCOUNT_TYPE_LOCAL) {
                    accounts += Account(name, type)
                }
            }
        }
        val extras =
            Bundle().apply {
                putBoolean(ContentResolver.SYNC_EXTRAS_MANUAL, true)
                putBoolean(ContentResolver.SYNC_EXTRAS_EXPEDITED, true)
            }
        accounts.forEach { ContentResolver.requestSync(it, CalendarContract.AUTHORITY, extras) }
        return accounts.isNotEmpty()
    }

    // endregion

    // region Değişiklik bildirimi

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        stopObserving()
        if (!granted()) return
        val notify = Runnable { events.success(null) }
        observer =
            object : ContentObserver(main) {
                override fun onChange(selfChange: Boolean) {
                    // Senkron bir değişikliği art arda birçok bildirimle yazar.
                    main.removeCallbacks(notify)
                    main.postDelayed(notify, 1500)
                }
            }.also { resolver.registerContentObserver(Events.CONTENT_URI, true, it) }
    }

    override fun onCancel(arguments: Any?) = stopObserving()

    private fun stopObserving() {
        observer?.let { resolver.unregisterContentObserver(it) }
        observer = null
    }

    // endregion

    private fun Cursor.str(index: Int): String? = if (isNull(index)) null else getString(index)

    companion object {
        private const val PERMISSION_REQUEST = 7341
        private const val HOUR = 3_600_000L
        private const val DAY = 86_400_000L

        private val durationPattern =
            Regex("""^[+-]?P(?:(\d+)W)?(?:(\d+)D)?T?(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?$""")

        /** RFC 5545 süresi: "P3600S", "PT1H30M", "P1D". */
        fun parseDuration(text: String?): Long? {
            val m = durationPattern.matchEntire(text?.trim() ?: return null) ?: return null
            fun part(i: Int) = m.groupValues[i].toLongOrNull() ?: 0L
            return part(1) * 7 * DAY + part(2) * DAY + part(3) * HOUR + part(4) * 60_000L + part(5) * 1000L
        }
    }
}
