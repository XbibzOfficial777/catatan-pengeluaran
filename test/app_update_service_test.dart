import 'package:flutter_test/flutter_test.dart';

import 'package:catatan_pengeluaran/services/app_update_service.dart';

void main() {
  test('parses canonical APK URL keys', () {
    final info = AppUpdateInfo.fromJson({
      'version': '1.3.2',
      'versionCode': 11,
      'universalApkUrl': 'https://example.com/universal.apk',
      'arm64ApkUrl': 'https://example.com/arm64.apk',
    });

    expect(info.version, '1.3.2');
    expect(info.versionCode, 11);
    expect(info.universalApkUrl, 'https://example.com/universal.apk');
    expect(info.arm64ApkUrl, 'https://example.com/arm64.apk');
  });

  test('accepts legacy URL aliases from version-latest.json', () {
    final info = AppUpdateInfo.fromJson({
      'version': '2.0.0',
      'versionCode': 20,
      'universalUrl': 'https://example.com/universal.apk',
      'downloadUrl': 'https://example.com/arm64.apk',
    });

    expect(info.universalApkUrl, 'https://example.com/universal.apk');
    expect(info.arm64ApkUrl, 'https://example.com/arm64.apk');
  });
}
