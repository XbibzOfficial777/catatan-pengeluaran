# Audit arsitektur updater dan scheduler Android

Tanggal audit: 2026-08-21.

## Temuan resmi Android

Dokumentasi Android WorkManager menyatakan bahwa `PeriodicWorkRequest` memiliki minimum repeat interval 15 menit. Waktu eksekusi tetap dapat ditunda oleh constraint, optimisasi sistem, Doze, Battery Saver, dan kondisi perangkat. WorkManager cocok untuk pengecekan update berkala di background dengan interval minimal 15 menit.

Dokumentasi Android AlarmManager menyatakan bahwa repeating alarm pada Android modern bersifat inexact dan dapat ditunda. `setInexactRepeating` adalah pilihan yang disarankan untuk kebanyakan aplikasi. Alarm exact memerlukan permission khusus pada Android 12+ dan tidak cocok untuk polling update yang sering karena konsumsi baterai. Interval per menit tidak dapat dijamin ketika aplikasi berada di background; interval per menit hanya dapat dijalankan sebagai timer selama aplikasi sedang terbuka.

## Keputusan desain

Aplikasi akan menyediakan pilihan `Saat aplikasi dibuka`, `15 menit`, `30 menit`, `1 jam`, `6 jam`, `12 jam`, `1 hari`, dan custom. Nilai custom kurang dari 15 menit akan dinormalisasi menjadi 15 menit untuk background scheduler dan UI akan menjelaskan batas Android. Jika aplikasi sedang foreground, timer dapat menjalankan pengecekan sesuai custom interval, termasuk per menit, tetapi timer berhenti ketika proses aplikasi dihentikan.

Metadata update akan mengambil raw GitHub sebagai sumber utama, Gist raw sebagai fallback kedua, lalu GitHub Contents API sebagai fallback terakhir. Semua sumber harus mengembalikan schema yang sama: `version`, `versionCode`, `universalApkUrl`, `arm64ApkUrl`, dan optional `releaseNotes`. APK dipilih berdasarkan ABI perangkat Android, dengan fallback universal bila asset ABI spesifik tidak tersedia.

## Referensi

1. https://developer.android.com/develop/background-work/background-tasks/persistent/getting-started/define-work — Android Developers, Define work requests.
2. https://developer.android.com/develop/background-work/services/alarms — Android Developers, Schedule alarms.
3. https://developer.android.com/ndk/guides/abis — Android Developers, Android ABIs.

## Evaluasi plugin scheduler Flutter

`android_alarm_manager_plus` dapat menjalankan callback Dart pada isolate background dan dokumentasinya mencantumkan kompatibilitas Dart >=3.1.0. Namun versi terbaru membutuhkan Kotlin 2.2.0, AGP >=8.12.1, dan Gradle >=8.13, yang berisiko bertabrakan dengan konfigurasi FlutLab proyek yang dipin ke Kotlin 2.1.21/AGP 8.11.1. Plugin juga tidak menyediakan mekanisme permission exact alarm dan callback background tidak berbagi isolate dengan aplikasi utama.

Karena pengecekan update adalah pekerjaan network ringan dan tidak memerlukan exact timing, implementasi yang paling aman untuk target FlutLab adalah timer foreground di Flutter untuk interval custom, ditambah scheduler native/inexact hanya bila dependency dan toolchain Android tetap kompatibel. Background interval kurang dari 15 menit tidak dapat dijamin Android; UI harus menjelaskan bahwa pilihan per menit aktif saat aplikasi terbuka, sedangkan background dinormalisasi minimal 15 menit atau memakai alarm inexact.

Referensi tambahan:

4. https://pub.dev/packages/android_alarm_manager_plus — package documentation and requirements.
5. https://github.com/fluttercommunity/plus_plugins/blob/main/packages/android_alarm_manager_plus/README.md — official plugin README.
