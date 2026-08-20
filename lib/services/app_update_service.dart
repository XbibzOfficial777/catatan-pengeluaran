import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.version,
    required this.versionCode,
    required this.universalApkUrl,
    required this.arm64ApkUrl,
    this.releaseNotes = '',
  });

  final String version;
  final int versionCode;
  final String universalApkUrl;
  final String arm64ApkUrl;
  final String releaseNotes;

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) => AppUpdateInfo(
    version: json['version'] as String? ?? '0.0.0',
    versionCode: (json['versionCode'] as num?)?.toInt() ?? 0,
    universalApkUrl: json['universalApkUrl'] as String? ?? '',
    arm64ApkUrl: json['arm64ApkUrl'] as String? ?? '',
    releaseNotes: json['releaseNotes'] as String? ?? '',
  );
}

class AppUpdateService {
  AppUpdateService._();
  static final instance = AppUpdateService._();

  static const latestJsonUrl =
      'https://raw.githubusercontent.com/XbibzOfficial777/catatan-pengeluaran/main/version-latest.json';
  static const _channel = MethodChannel('catatan/app_update');

  bool get supportsApkInstall =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<AppUpdateInfo> checkLatest() async {
    final text = await _getText(latestJsonUrl);
    final decoded = jsonDecode(text);
    if (decoded is! Map) throw const FormatException('Format update tidak valid.');
    return AppUpdateInfo.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<String> download(
    AppUpdateInfo info, {
    required bool preferArm64,
    required void Function(int received, int total) onProgress,
  }) async {
    await cleanupDownloadedApks();
    final url = preferArm64 ? info.arm64ApkUrl : info.universalApkUrl;
    if (url.isEmpty) throw const FormatException('URL APK belum tersedia.');
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/catatan_pengeluaran_update_${info.version}.apk');
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
    try {
      final request = await client.getUrl(Uri.parse(url)).timeout(const Duration(seconds: 15));
      request.followRedirects = true;
      final response = await request.close().timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Download APK HTTP ${response.statusCode}');
      }
      final total = response.contentLength;
      var received = 0;
      final sink = file.openWrite();
      try {
        await for (final chunk in response) {
          sink.add(chunk);
          received += chunk.length;
          onProgress(received, total);
        }
      } finally {
        await sink.flush();
        await sink.close();
      }
      if (received == 0) throw const FileSystemException('APK kosong.');
      return file.path;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> installApk(String path) async {
    await _channel.invokeMethod<void>('install_apk', {'path': path});
  }

  Future<void> cleanupDownloadedApks() async {
    final directory = await getTemporaryDirectory();
    if (!await directory.exists()) return;
    await for (final entity in directory.list()) {
      if (entity is File &&
          entity.path.contains('catatan_pengeluaran_update_') &&
          entity.path.endsWith('.apk')) {
        try {
          await entity.delete();
        } catch (_) {
          // A file currently used by Android's installer can be removed later.
        }
      }
    }
  }

  Future<String> _getText(String url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(Uri.parse(url)).timeout(const Duration(seconds: 12));
      request.followRedirects = true;
      final response = await request.close().timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Update check HTTP ${response.statusCode}');
      }
      return await response.transform(utf8.decoder).join();
    } finally {
      client.close(force: true);
    }
  }
}
