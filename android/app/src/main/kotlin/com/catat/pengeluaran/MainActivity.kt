package com.catat.pengeluaran

import android.content.Intent
import androidx.core.content.FileProvider
import java.io.File
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var quickActionChannel: MethodChannel? = null
    private var updateChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        quickActionChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "catatan/quick_actions")
        updateChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "catatan/app_update")
        updateChannel?.setMethodCallHandler { call, result ->
            if (call.method != "install_apk") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val path = call.argument<String>("path")
            if (path.isNullOrBlank()) {
                result.error("INVALID_PATH", "APK path kosong", null)
                return@setMethodCallHandler
            }
            try {
                val apkFile = File(path)
                if (!apkFile.exists()) {
                    result.error("FILE_NOT_FOUND", "APK tidak ditemukan", null)
                    return@setMethodCallHandler
                }
                val uri = FileProvider.getUriForFile(
                    this,
                    "${applicationContext.packageName}.fileprovider",
                    apkFile,
                )
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(uri, "application/vnd.android.package-archive")
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(intent)
                result.success(null)
            } catch (error: Exception) {
                result.error("INSTALL_FAILED", error.message, null)
            }
        }
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
