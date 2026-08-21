# Changelog Catatan Pengeluaran

Semua perubahan penting pada **Catatan Pengeluaran** dicatat di dokumen ini.

## [1.3.7] - 2026-08-21

### Fixed

- Updater memakai raw GitHub sebagai sumber metadata utama sehingga tidak bergantung pada rate limit Contents API yang dapat mengembalikan HTTP 403.
- Contents API tetap tersedia sebagai fallback, dengan User-Agent resmi dan validasi metadata yang lebih ketat.
- Pesan ketika tidak ada update sekarang menampilkan versi/build lokal serta versi/build server untuk membantu diagnosis.

## [1.3.6] - 2026-08-21

### Added

- Changelog resmi dari GitHub yang ditampilkan satu kali setelah aplikasi selesai diperbarui.
- Tutorial onboarding untuk instalasi pertama dengan panduan pencatatan pengeluaran, hutang/piutang, tabungan, backup, dan restore.
- Menu tekan lama pada riwayat pengeluaran dan hutang dengan pilihan edit, hapus, serta tandai lunas.
- Pratinjau lampiran gambar langsung dari riwayat pengeluaran dan hutang.
- Metadata updater dan release asset universal serta arm64-v8a untuk versi 1.3.6.

### Fixed

- Penghapusan tujuan Tabungan sekarang langsung dikembalikan ke halaman utama dan disimpan secara persisten.
- Hapus tujuan Tabungan tidak lagi meninggalkan item lama setelah sheet ditutup.
- Lampiran yang hilang atau rusak menampilkan placeholder yang aman, bukan menyebabkan halaman gagal dirender.

### Improved

- Alur update memakai `CHANGELOG.MD` GitHub dengan cache-busting dan fallback error yang aman.
- Status onboarding dan versi changelog terakhir disimpan secara lokal agar dialog tidak muncul berulang.
- APK release tetap dibuild dalam dua varian: universal dan arm64-v8a.

## [1.3.3] - 2026-08-21

- Audit keamanan dan keandalan data.
- Restore lintas perangkat dengan integritas backup yang lebih ketat.
- Hardening gambar, updater terverifikasi, dan perbaikan build Flutter 3.32/FlutLab.

## [1.3.2] - 2026-08-21

- Perbaikan updater aplikasi, restore `.bibzcup`, cache-busting metadata, dan fallback download GitHub Release.
