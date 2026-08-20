package com.catat.pengeluaran

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class FinanceWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { update(context, manager, it) }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, FinanceWidgetProvider::class.java)
            manager.getAppWidgetIds(component).forEach { update(context, manager, it) }
        }
    }

    private fun update(context: Context, manager: AppWidgetManager, widgetId: Int) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val monthExpense = prefs.getString("month_expense", "Rp 0") ?: "Rp 0"
        val pocketMoney = prefs.getString("pocket_money", "Rp 0") ?: "Rp 0"
        val totalBalance = prefs.getString("total_balance", "Rp 0") ?: "Rp 0"
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            widgetId,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val views = RemoteViews(context.packageName, R.layout.finance_widget).apply {
            setTextViewText(R.id.widget_month_expense, monthExpense)
            setTextViewText(R.id.widget_pocket_money, pocketMoney)
            setTextViewText(R.id.widget_total_balance, totalBalance)
            setOnClickPendingIntent(R.id.widget_root, pendingIntent)
        }
        manager.updateAppWidget(widgetId, views)
    }
}
