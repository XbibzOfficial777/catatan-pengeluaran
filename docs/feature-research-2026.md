# Riset fitur Catatan Pengeluaran

## Offline-first

Flutter Architecture menjelaskan bahwa aplikasi offline-first sebaiknya menjadikan repository sebagai single source of truth; repository menggabungkan local data source dan remote data source, sementara UI membaca repository tanpa bergantung langsung pada status koneksi. Dokumentasi juga membedakan strategi fallback local, local-only, stream, offline-first writing, dan sinkronisasi. Referensi: https://docs.flutter.dev/app-architecture/design-patterns/offline-first

Implikasi untuk proyek ini: pencatatan finansial harus tetap local-first karena data utama saat ini tersimpan lokal melalui FinanceStorage. Fitur online seperti import mutasi bank/berkas harus bersifat opsional dan tidak boleh memblokir pembuatan atau pembacaan transaksi offline.

## OCR struk

`google_mlkit_text_recognition` versi yang tampil di pub.dev saat riset adalah 0.17.1. Package mendukung karakter Latin, berjalan on-device melalui API native Android/iOS, Android minimum SDK 21, dan tidak mendukung Web. Dokumentasi menyebut iOS minimum deployment target 15.5 serta hanya arsitektur 64-bit. Referensi: https://pub.dev/packages/google_mlkit_text_recognition

Implikasi untuk target Android 7–16: Android minSdk 24 proyek memenuhi syarat. Namun karena target juga Web/iOS FlutLab, OCR harus diberi adapter platform: implementasi ML Kit hanya Android/iOS, sedangkan Web menyediakan fallback manual atau impor foto tanpa OCR. Dependency terbaru perlu dipin ke versi yang benar-benar masih menerima Dart 3.8.1 dan toolchain FlutLab sebelum ditambahkan.

## Quick transaction dari notification

Dokumentasi `flutter_local_notifications` menjelaskan bahwa action notification Android dapat memanggil callback utama jika UI ditampilkan, atau background isolate melalui callback background ketika aplikasi tidur/terminated. Payload dipakai untuk membawa konteks transaksi. Package juga memperingatkan bahwa konfigurasi action berbeda antara platform, sehingga adapter Android/iOS/Web diperlukan. Referensi: https://pub.dev/packages/flutter_local_notifications

Dokumentasi Android resmi menyatakan notification dapat menyediakan hingga tiga action button. Action sebaiknya memakai PendingIntent menuju BroadcastReceiver untuk pekerjaan background yang tidak perlu membuka activity. Direct reply tersedia mulai Android 7.0/API 24, sesuai minSdk proyek. Android 8/API 26 membutuhkan notification channel dan Android 13/API 33 membutuhkan POST_NOTIFICATIONS runtime permission. Referensi: https://developer.android.com/develop/ui/compose/notifications/create-notification#Actions

Implikasi: fitur transaksi cepat akan memakai action `Catat cepat` yang membuka form dengan payload aman atau receiver yang hanya menandai intent; nominal, kategori, dan akun tetap dikonfirmasi di form agar tidak membuat transaksi salah hanya karena satu tap notification.

## Package compatibility audit

Pub.dev API pada 2026-08-22 menunjukkan `google_mlkit_text_recognition` terbaru 0.17.1 membutuhkan Dart `^3.12.0` dan Flutter `>=3.44.0`, sehingga tidak kompatibel dengan target FlutLab Dart 3.8.1/Flutter 3.32.1. Versi 0.15.1 dan 0.16.0 membutuhkan Dart `>=3.8.0 <4.0.0` serta Flutter `>=3.32.0`, sehingga 0.16.0 adalah kandidat OCR paling baru yang kompatibel dengan target proyek. `drift` terbaru 2.34.3 dan `drift_flutter` 0.3.1 membutuhkan Dart `>=3.10.0`, sehingga keduanya tidak dapat dipakai pada Dart 3.8.1 tanpa memilih versi lama dan menambah generator/migrasi. `connectivity_plus` 7.3.1 membutuhkan Dart `>=3.2.0 <4.0.0` dan Flutter `>=3.7.0`, tetapi konektivitas hanya indikator, bukan sumber kebenaran network.

Keputusan sementara: jangan menambahkan Drift sekarang karena FinanceStorage sudah local-first dan migrasi database besar akan memperbesar risiko regresi backup/restore. Fitur offline-first akan diperkuat di lapisan service dengan operasi lokal yang tidak menunggu network, status pending/import, dan fallback aman. Jika OCR ditambahkan, pin `google_mlkit_text_recognition: 0.16.0`, uji iOS deployment target, dan sediakan fallback manual/Web karena ML Kit hanya Android/iOS.
