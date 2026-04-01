package com.managarr.managarr

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray
import org.json.JSONException

class UpcomingWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        UpcomingRemoteViewsFactory(applicationContext)
}

private class UpcomingRemoteViewsFactory(
    private val context: Context
) : RemoteViewsService.RemoteViewsFactory {

    private data class Item(
        val title: String,
        val subtitle: String,
        val date: String,
        val type: String,
        val route: String
    )

    private val items = mutableListOf<Item>()

    override fun onCreate() {}

    override fun onDataSetChanged() {
        items.clear()
        val prefs = context.getSharedPreferences(
            "HomeWidgetPreferences", Context.MODE_PRIVATE
        )
        val json = prefs.getString("widget_upcoming_releases", null) ?: return
        try {
            val array = JSONArray(json)
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                items += Item(
                    title    = obj.optString("title", ""),
                    subtitle = obj.optString("subtitle", ""),
                    date     = obj.optString("date", ""),
                    type     = obj.optString("type", "movie"),
                    route    = obj.optString("route", "")
                )
            }
        } catch (_: JSONException) {}
    }

    override fun onDestroy() = items.clear()

    override fun getCount(): Int = items.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.upcoming_widget_item)
        val item = items.getOrNull(position) ?: return views

        views.setTextViewText(R.id.item_title, item.title)
        views.setTextViewText(R.id.item_subtitle, item.subtitle)
        views.setTextViewText(R.id.item_date, item.date)
        views.setImageViewResource(
            R.id.item_type_icon,
            if (item.type == "tv") R.drawable.ic_widget_tv else R.drawable.ic_widget_movie
        )

        // Fill-in intent carries the per-item deep-link URI; merged with the
        // PendingIntent template set on the ListView in UpcomingWidgetProvider.
        if (item.route.isNotEmpty()) {
            val fillIn = Intent().apply {
                data = Uri.parse("managarr://${item.route}")
            }
            views.setOnClickFillInIntent(R.id.item_root, fillIn)
        }

        return views
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = false
}
