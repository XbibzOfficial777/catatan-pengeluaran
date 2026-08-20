package com.catat.pengeluaran

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var quickActionChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        quickActionChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "catatan/quick_actions")
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.action == ACTION_ADD_EXPENSE) {
            quickActionChannel?.invokeMethod("open_expense_form", null)
        }
    }

    companion object {
        const val ACTION_ADD_EXPENSE = "com.catat.pengeluaran.ADD_EXPENSE"
    }
}
