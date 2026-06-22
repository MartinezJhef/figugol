package com.example.figugol

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class WorldCupWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.world_cup_widget).apply {
                val missingText = widgetData.getString("missing_text", "¡Calculando faltantes! 🚀")
                val duplicatesText = widgetData.getString("duplicates_text", "Revisando repetidas... 🔄")
                
                setTextViewText(R.id.widget_missing, missingText)
                setTextViewText(R.id.widget_duplicates, duplicatesText)
                
                // Add click intent to launch the app
                val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                if (intent != null) {
                    val pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                    setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                }
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
