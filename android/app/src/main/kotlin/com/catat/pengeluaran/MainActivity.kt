package com.catat.pengeluaran

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
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
            when (call.method) {
                "install_apk" -> installApk(call.argument<String>("path"), result)
                "get_supported_abis" -> result.success(Build.SUPPORTED_ABIS.toList())
                "schedule_update_check" -> {
                    val minutes = call.argument<Int>("minutes") ?: 0
                    scheduleUpdateCheck(this, minutes)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        dispatchScheduledCheckIfNeeded()
    }

    private fun installApk(path: String?, result: MethodChannel.Result) {
        if (path.isNullOrBlank()) {
            result.error("INVALID_PATH", "APK path kosong", null)
            return
        }
        try {
            val apkFile = File(path)
            if (!apkFile.exists()) {
                result.error("FILE_NOT_FOUND", "APK tidak ditemukan", null)
                return
            }
            // Pertahanan terakhir sebelum memicu installer sistem: APK pembaruan
            // wajib ditandatangani kunci yang sama dengan aplikasi terpasang.
            if (!signaturesMatch(apkFile)) {
                result.error(
                    "SIGNATURE_MISMATCH",
                    "Tanda tangan APK pembaruan tidak cocok dengan aplikasi terpasang. Unduhan ditolak.",
                    null,
                )
                return
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

    private fun dispatchScheduledCheckIfNeeded() {
        if (intent?.action == ACTION_SCHEDULED_UPDATE_CHECK) {
            updateChannel?.invokeMethod("scheduled_update_check", null)
            intent?.action = null
        }
    }

    /**
     * Membandingkan sertifikat signing APK unduhan dengan aplikasi terpasang.
     * Mengembalikan false pada kegagalan apa pun agar hanya APK terverifikasi
     * yang boleh masuk ke alur instalasi.
     */
    private fun signaturesMatch(apkFile: File): Boolean {
        return try {
            val archiveInfo = packageArchiveInfo(apkFile.path) ?: return false
            val archiveSignatures = signaturesOf(archiveInfo) ?: return false
            val installedInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
            }
            val installedSignatures = signaturesOf(installedInfo) ?: return false
            archiveSignatures == installedSignatures
        } catch (_: Exception) {
            false
        }
    }

    private fun packageArchiveInfo(path: String): PackageInfo? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            packageManager.getPackageArchiveInfo(path, PackageManager.GET_SIGNING_CERTIFICATES)
        } else {
            @Suppress("DEPRECATION")
            packageManager.getPackageArchiveInfo(path, PackageManager.GET_SIGNATURES)
        }
    }

    private fun signaturesOf(info: PackageInfo): Set<String>? {
        val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            info.signingInfo?.apkContentsSigners
        } else {
            @Suppress("DEPRECATION")
            info.signatures
        }
        if (signatures == null || signatures.isEmpty()) return null
        return signatures.map { it.toCharsString() }.toSet()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.action == ACTION_ADD_EXPENSE) {
            quickActionChannel?.invokeMethod("open_expense_form", null)
        }
        dispatchScheduledCheckIfNeeded()
    }

    companion object {
        const val ACTION_ADD_EXPENSE = "com.catat.pengeluaran.ADD_EXPENSE"
        const val ACTION_SCHEDULED_UPDATE_CHECK = "com.catat.pengeluaran.SCHEDULED_UPDATE_CHECK"
        private const val UPDATE_ALARM_REQUEST_CODE = 77139
        private const val FLUTTER_UPDATE_INTERVAL_KEY = "flutter.update_check_interval_minutes_v1"

        fun scheduleUpdateCheck(context: Context, requestedMinutes: Int) {
            val minutes = requestedMinutes.coerceIn(0, 10080)
            context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                .edit()
                .putInt(FLUTTER_UPDATE_INTERVAL_KEY, minutes)
                .apply()

            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val pendingIntent = updatePendingIntent(context)
            alarmManager.cancel(pendingIntent)
            if (minutes < 15) return

            val intervalMillis = minutes.toLong() * 60_000L
            val firstTrigger = System.currentTimeMillis() + intervalMillis
            alarmManager.setInexactRepeating(
                AlarmManager.RTC_WAKEUP,
                firstTrigger,
                intervalMillis,
                pendingIntent,
            )
        }

        fun rescheduleFromStoredValue(context: Context) {
            val minutes = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                .getInt(FLUTTER_UPDATE_INTERVAL_KEY, 0)
            scheduleUpdateCheck(context, minutes)
        }

        private fun updatePendingIntent(context: Context): PendingIntent {
            val intent = Intent(context, UpdateCheckReceiver::class.java).apply {
                action = ACTION_SCHEDULED_UPDATE_CHECK
            }
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
            return PendingIntent.getBroadcast(context, UPDATE_ALARM_REQUEST_CODE, intent, flags)
        }
    }
}

class UpdateCheckReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED ||
            intent?.action == Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            MainActivity.rescheduleFromStoredValue(context)
            return
        }
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            action = MainActivity.ACTION_SCHEDULED_UPDATE_CHECK
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        context.startActivity(launchIntent)
    }
}
