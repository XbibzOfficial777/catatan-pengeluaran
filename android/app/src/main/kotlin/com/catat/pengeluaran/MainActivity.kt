package com.catat.pengeluaran

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
                // Pertahanan terakhir sebelum memicu installer sistem: APK pembaruan
                // wajib ditandatangani kunci yang sama dengan aplikasi terpasang.
                // Tanpa ini, metadata yang disusupi bisa memasang APK apa pun.
                if (!signaturesMatch(apkFile)) {
                    result.error(
                        "SIGNATURE_MISMATCH",
                        "Tanda tangan APK pembaruan tidak cocok dengan aplikasi terpasang. Unduhan ditolak.",
                        null,
                    )
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
    }

    companion object {
        const val ACTION_ADD_EXPENSE = "com.catat.pengeluaran.ADD_EXPENSE"
    }
}
