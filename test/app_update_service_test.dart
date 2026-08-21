import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';

import 'package:catatan_pengeluaran/services/app_update_service.dart';

void main() {
  group('AppUpdateService.isAllowedApkUrl', () {
    test('https GitHub resmi diizinkan', () {
      expect(
        AppUpdateService.isAllowedApkUrl(
          Uri.parse('https://github.com/XbibzOfficial777/catatan-pengeluaran/releases/latest/download/app.apk'),
        ),
        isTrue,
      );
      expect(
        AppUpdateService.isAllowedApkUrl(
          Uri.parse('https://objects.githubusercontent.com/xyz/app.apk'),
        ),
        isTrue,
      );
      expect(
        AppUpdateService.isAllowedApkUrl(
          Uri.parse('https://release-assets.githubusercontent.com/xyz/app.apk'),
        ),
        isTrue,
      );
    });

    test('http, host asing, dan host menyerupai GitHub palsu ditolak', () {
      expect(
        AppUpdateService.isAllowedApkUrl(
          Uri.parse('http://github.com/XbibzOfficial777/catatan-pengeluaran/releases/download/x/app.apk'),
        ),
        isFalse,
        reason: 'http harus ditolak agar jalur unduhan tidak bisa di-downgrade',
      );
      expect(
        AppUpdateService.isAllowedApkUrl(Uri.parse('https://evil.example.com/app.apk')),
        isFalse,
      );
      expect(
        AppUpdateService.isAllowedApkUrl(Uri.parse('https://github.com.evil.com/app.apk')),
        isFalse,
      );
      expect(
        AppUpdateService.isAllowedApkUrl(Uri.parse('https://notgithubusercontent.com/app.apk')),
        isFalse,
      );
    });
  });

  group('AppUpdateInfo metadata', () {
    test('sha256 opsional terbaca dengan nama field utama maupun fallback', () {
      final primary = AppUpdateInfo.fromJson({
        'version': '1.4.0',
        'versionCode': 12,
        'universalApkUrl': 'https://github.com/x/y/releases/download/v1/app.apk',
        'arm64ApkUrl': 'https://github.com/x/y/releases/download/v1/app64.apk',
        'sha256Universal': 'aa',
        'sha256Arm64': 'bb',
      });
      expect(primary.sha256Universal, 'aa');
      expect(primary.sha256Arm64, 'bb');

      final fallback = AppUpdateInfo.fromJson({
        'version': '1.4.0',
        'versionCode': 12,
        'universalApkUrl': 'u',
        'arm64ApkUrl': 'a',
        'universalSha256': 'cc',
        'arm64Sha256': 'dd',
      });
      expect(fallback.sha256Universal, 'cc');
      expect(fallback.sha256Arm64, 'dd');
    });

    test('metadata lama tanpa sha256 tetap valid (string kosong)', () {
      final info = AppUpdateInfo.fromJson({
        'version': '1.3.2',
        'versionCode': 11,
        'universalApkUrl': 'https://github.com/x/y/app.apk',
        'arm64ApkUrl': 'https://github.com/x/y/app64.apk',
      });
      expect(info.sha256Universal, '');
      expect(info.sha256Arm64, '');
    });
  });

  group('verifyApkChecksum', () {
    late Directory temp;

    setUp(() async {
      temp = await Directory.systemTemp.createTemp('apk_checksum_test');
    });

    tearDown(() async {
      await temp.delete(recursive: true);
    });

    AppUpdateInfo infoWithChecksum(String universal, String arm64) =>
        AppUpdateInfo(
          version: '9.9.9',
          versionCode: 99,
          universalApkUrl: 'https://github.com/x/y/universal.apk',
          arm64ApkUrl: 'https://github.com/x/y/arm64.apk',
          sha256Universal: universal,
          sha256Arm64: arm64,
        );

    test('checksum cocok → null (lolos)', () async {
      final bytes = 'isi-apk-anda'.codeUnits;
      final file = File('${temp.path}/a.apk');
      await file.writeAsBytes(bytes);
      final result = await AppUpdateService.verifyApkChecksum(
        file,
        'https://github.com/x/y/universal.apk',
        infoWithChecksum(crypto.sha256.convert(bytes).toString(), 'zz'),
      );
      expect(result, isNull);
    });

    test('checksum tidak cocok → pesan error', () async {
      final file = File('${temp.path}/b.apk');
      await file.writeAsBytes('berisi-lain'.codeUnits);
      final result = await AppUpdateService.verifyApkChecksum(
        file,
        'https://github.com/x/y/universal.apk',
        infoWithChecksum(
            crypto.sha256.convert('beda'.codeUnits).toString(), 'zz'),
      );
      expect(result, isNotNull);
      expect(result, contains('tidak cocok'));
    });

    test('checksum arm64 dipakai untuk URL arm64', () async {
      final bytes = 'apk-arm64'.codeUnits;
      final file = File('${temp.path}/c.apk');
      await file.writeAsBytes(bytes);
      final result = await AppUpdateService.verifyApkChecksum(
        file,
        'https://github.com/x/y/arm64.apk',
        infoWithChecksum('salah', crypto.sha256.convert(bytes).toString()),
      );
      expect(result, isNull);
    });

    test('tanpa checksum yang relevan → null (kompatibilitas metadata lama)',
        () async {
      final file = File('${temp.path}/d.apk');
      await file.writeAsBytes('apapun'.codeUnits);
      final result = await AppUpdateService.verifyApkChecksum(
        file,
        'https://github.com/x/y/universal.apk',
        infoWithChecksum('', ''),
      );
      expect(result, isNull);
    });
  });
}
