# Catatan Pengeluaran

Catatan Pengeluaran adalah aplikasi Android modern untuk mencatat pengeluaran pribadi, hutang, piutang, dan lampiran foto. Aplikasi dibangun dengan Flutter 3.47.0 menggunakan package `com.catat.pengeluaran`.

## Arah desain

Visual aplikasi diperbarui berdasarkan `DESIGN-cursor.md` dengan pendekatan editorial yang tenang: warm-cream canvas `#F7F7F4`, near-black warm ink `#26251E`, Cursor Orange `#F54E00` sebagai aksen utama yang digunakan secara hemat, kartu putih dengan hairline border, radius compact 8–12px, display weight ringan, dan tanpa drop shadow berlebihan. Animasi tetap dipertahankan pada transisi tab, kartu, suggestion pencarian, dan feedback aksi agar aplikasi terasa hidup namun tidak norak.

## Uang Saku dan tujuan pengeluaran

Dashboard memiliki kartu **Uang Saku** yang dapat diatur dan diedit kapan saja. Aplikasi menghitung sisa Uang Saku berdasarkan total pengeluaran yang tercatat dan memberi indikator ketika pengeluaran melebihi batas dana. Pada form transaksi, field utama menggunakan label **Untuk apa pengeluaran ini?** sehingga setiap nominal memiliki konteks yang jelas.

Halaman hutang memiliki pencarian realtime berdasarkan nama, nomor telepon, dan catatan. Hasil langsung diperbarui saat pengguna mengetik, dengan suggestion nama dan nominal yang dapat dipilih.

Catatan hutang dipisahkan menjadi dua kelompok yang berdiri sendiri: **Dipinjam Orang** untuk uang yang perlu diterima dan **Saya Berhutang** untuk uang yang perlu dibayarkan. Setiap kelompok menampilkan jumlah catatan aktif dan state kosong yang terpisah agar pengelolaan lebih mudah.

## Fitur utama

Dashboard menampilkan total pengeluaran bulan berjalan, jumlah transaksi, hutang aktif, dan piutang aktif. Pengeluaran mendukung tambah, edit, hapus, kategori, nominal, tanggal, catatan, serta lampiran foto dari galeri atau kamera. Foto dapat diedit sebelum disimpan menggunakan editor internal yang mendukung crop, rotasi kanan/kiri, lingkaran/shape, coretan gambar, dan penyimpanan hasil edit.

Catatan hutang mendukung dua arah pencatatan: **Saya berhutang** dan **Dipinjam orang**. Nama orang dapat diketik manual atau dipilih secara opsional dari kontak Android. Setelah kontak dipilih, nama dan nomor telepon akan diisi serta disimpan bersama catatan. Pencarian hutang mendukung nama, nomor telepon, dan isi catatan, lengkap dengan suggestion interaktif yang dapat dipilih untuk memfilter hasil.

Pada kartu hutang tersedia tombol komunikasi. Pengguna dapat memilih WhatsApp atau SMS, mengedit template pesan, lalu membuka aplikasi komunikasi dengan nomor kontak yang tersimpan. Untuk piutang, template berisi pengingat pembayaran; untuk hutang pribadi, template berisi pemberitahuan tentang kewajiban pembayaran.

Setiap catatan dapat memiliki nominal, tanggal, jatuh tempo, catatan, foto, status lunas, edit, dan hapus. Penghapusan melalui swipe meminta konfirmasi modal terlebih dahulu dengan pilihan **Batal** atau **Hapus**. Setelah disetujui, snackbar **Urungkan** tetap tersedia untuk mengembalikan catatan.

Aplikasi menyediakan kalkulator cepat, tema **Ikuti sistem/Terang/Gelap**, transisi tab, animasi masuk kartu, animated search suggestions, progress card, feedback snackbar, dan layout responsif tanpa elemen dekoratif berlebihan.

## Backup, restore, dan Google Drive

Menu **Data dan laporan** menyediakan beberapa tujuan backup. **Backup ke perangkat** membuat file pada folder publik:

```text
/sdcard/Documents/CatatBibz/
```

File yang dihasilkan bernama seperti `CatatanPengeluaran_20260819_120000.bibzcup`. File tersebut adalah arsip ZIP valid dengan ekstensi khusus `.bibzcup`, berisi `manifest.json`, seluruh data pengeluaran/hutang, informasi kontak yang tersimpan, dan salinan foto di folder `photos/`. Kompresi menggunakan Deflate level 9 (**ultra**).

**Backup ke Google Drive** membuat arsip yang sama, lalu membukanya melalui Android share sheet. Pengguna memilih Google Drive pada share sheet untuk menyimpan arsip. Login Google dilakukan oleh Google Drive/browser/system; aplikasi tidak memiliki form login, tidak meminta password, dan tidak menyimpan kredensial Google.

**Restore backup** membuka file picker sistem untuk memilih `.bibzcup` atau `.zip`. Aplikasi memvalidasi `manifest.json`, memulihkan data transaksi, memulihkan foto ke penyimpanan aplikasi, lalu menawarkan dua mode: **Gabungkan** dengan data saat ini atau **Ganti semua**. ID transaksi dipakai untuk mencegah duplikasi saat mode gabungkan digunakan.

## Export spreadsheet Excel profesional

Menu **Share spreadsheet Excel** menghasilkan workbook `.xlsx` profesional yang siap dibuka di Microsoft Excel, Google Sheets, LibreOffice, atau aplikasi perkantoran lain. Workbook menggunakan tiga sheet dengan struktur kerja yang jelas:

| Sheet | Isi |
|---|---|
| `Overview` | Judul laporan, KPI total pengeluaran, hutang aktif, piutang aktif, catatan lunas, isi workbook, dan waktu pembuatan |
| `Transactions` | Seluruh pengeluaran serta hutang/piutang dalam tabel detail terpadu |
| `Hutang & Piutang` | Detail nama, tipe, status, nominal, tanggal, jatuh tempo, nomor kontak, catatan, dan lampiran |

Workbook memakai tema corporate blue yang tenang, hierarki tipografi, header kontras, warna status lunas yang lembut, format angka Rupiah, format tanggal, lebar kolom yang disesuaikan, wrapping untuk catatan panjang, garis pemisah horizontal, dan layout overview yang dapat langsung dipresentasikan. File dibagikan melalui Android share sheet sehingga dapat dikirim ke email, WhatsApp, Google Drive, Microsoft Excel, Google Sheets, dan aplikasi kantor lainnya.

## Model data

`ExpenseEntry` memiliki `id`, `title`, `amount`, `category`, `date`, `note`, `imagePath`, dan `createdAt`. `DebtEntry` memiliki `id`, `person`, `amount`, `kind`, `date`, `dueDate`, `note`, `imagePath`, `contactId`, `contactPhone`, `isSettled`, dan `createdAt`. Data diserialisasi sebagai JSON dan disimpan secara lokal melalui `shared_preferences`.

## Struktur proyek

```text
lib/
  main.dart                              # UI, navigation, dashboard, search, forms, animations
  models/finance_models.dart             # Model ExpenseEntry dan DebtEntry
  services/finance_storage.dart          # Persistence SharedPreferences
  services/image_attachment_service.dart # Pick, edit result, copy, replace, delete foto
  services/contact_service.dart          # Permission dan picker kontak Android
  services/communication_service.dart    # WhatsApp/SMS URL launcher
  services/backup_service.dart           # JSON + foto ke ZIP level 9 .bibzcup
  services/data_transfer_service.dart    # Restore ZIP dan export spreadsheet XLSX profesional
assets/
  catatan_pengeluaran_icon.png           # Icon sumber aplikasi
vendor/font_awesome_flutter/              # Shim IconData Flutter terbaru untuk editor
android/app/proguard-rules.pro            # Aturan R8 release
android/app/build.gradle.kts              # Package, SDK, minify, dan resource shrinking
```

## Kompatibilitas

Aplikasi menggunakan minimum SDK Android 24 untuk Android 7 dan target/compile SDK 36 untuk Android 16. Icon aplikasi tersedia pada seluruh density Android dari mdpi sampai xxxhdpi. Permission kontak, storage, file picker, dan share bersifat opsional serta hanya digunakan ketika fitur terkait dipilih.

## GitHub Actions dan Releases

Workflow `.github/workflows/android-release.yml` menjalankan `flutter analyze` dan `flutter test`, kemudian membangun APK release split-ABI dengan obfuscation Dart, split debug symbols, R8, resource shrinking, dan optimasi icon. Workflow berjalan saat tag versi dengan pola `v*.*.*` dibuat dan mengunggah tiga APK serta `SHA256SUMS.txt` ke GitHub Releases. Workflow juga dapat dijalankan manual melalui tab **Actions**.

Untuk membuat release baru:

```bash
git tag v1.1.0
git push origin v1.1.0
```

GitHub Actions akan membuat release otomatis dan mengunggah APK `arm64-v8a`, `armeabi-v7a`, serta `x86_64`.

## Build normal

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Build kompresi mendalam

Release final dibangun dengan R8 minification, resource shrinking, tree-shaking Material Icons, Dart obfuscation, split debug symbols, split ABI, dan zipalign:

```bash
flutter build apk --release \
  --obfuscate \
  --split-debug-info=dist/symbols \
  --split-per-abi
```

Artefak hasil build tersedia di folder `dist/`. Symbol files disimpan terpisah di `dist/symbols/` dan diperlukan untuk membaca stack trace dari build yang sudah di-obfuscate.
