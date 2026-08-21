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

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    String readUrl(String primary, String fallback) =>
        (json[primary] ?? json[fallback]) as String? ?? '';
    return AppUpdateInfo(
      version: json['version'] as String? ?? '0.0.0',
      versionCode: (json['versionCode'] as num?)?.toInt() ?? 0,
      universalApkUrl: readUrl('universalApkUrl', 'universalUrl'),
      arm64ApkUrl: readUrl('arm64ApkUrl', 'downloadUrl'),
      releaseNotes: json['releaseNotes'] as String? ?? '',
    );
  }
}

class AppUpdateService {
  AppUpdateService._();
  static final instance = AppUpdateService._();

  static const latestJsonApiUrl =
      'https://api.github.com/repos/XbibzOfficial777/catatan-pengeluaran/contents/version-latest.json?ref=main';
  static const latestJsonUrl =
      'https://raw.githubusercontent.com/XbibzOfficial777/catatan-pengeluaran/main/version-latest.json';
  static const _channel = MethodChannel('catatan/app_update');

  bool get supportsApkInstall =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<AppUpdateInfo> checkLatest() async {
    try {
      final apiText = await _getText(latestJsonApiUrl);
      final apiDecoded = jsonDecode(apiText);
      if (apiDecoded is Map && apiDecoded['content'] is String) {
        final encoded = (apiDecoded['content'] as String).replaceAll('\n', '');
        final metadataText = utf8.decode(base64.decode(encoded));
        return _parseMetadata(metadataText);
      }
      if (apiDecoded is Map) {
        return AppUpdateInfo.fromJson(Map<String, dynamic>.from(apiDecoded));
      }
    } catch (_) {
      // Fall back to raw GitHub when the Contents API is unavailable.
    }

    final cacheBustedUrl = Uri.parse(latestJsonUrl).replace(
      queryParameters: <String, String>{
        'cacheBust': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    return _parseMetadata(await _getText(cacheBustedUrl.toString()));
  }

  AppUpdateInfo _parseMetadata(String text) {
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
    final urls = <String>{
      if (preferArm64) info.arm64ApkUrl else info.universalApkUrl,
      if (preferArm64) info.universalApkUrl else info.arm64ApkUrl,
    }..removeWhere((url) => url.isEmpty);
    if (urls.isEmpty) {
      throw const FormatException('URL APK belum tersedia di version-latest.json.');
    }
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/catatan_pengeluaran_update_${info.version}.apk');
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
    try {
      HttpException? lastHttpError;
      for (final url in urls) {
        final parsedUrl = Uri.tryParse(url);
        if (parsedUrl == null || !parsedUrl.hasScheme) {
          lastHttpError = HttpException('URL APK tidak valid: $url');
          continue;
        }
        try {
          final request = await client.getUrl(parsedUrl).timeout(const Duration(seconds: 15));
          request.followRedirects = true;
          request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
          final response = await request.close().timeout(const Duration(seconds: 30));
          if (response.statusCode < 200 || response.statusCode >= 300) {
            lastHttpError = HttpException(
              'Download APK HTTP ${response.statusCode} dari $url. Pastikan GitHub Release memiliki asset APK tersebut.',
            );
            await response.drain<void>();
            continue;
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
        } on HttpException catch (error) {
          lastHttpError = error;
        }
      }
      throw lastHttpError ?? const HttpException('Semua URL APK gagal diakses.');
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
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
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
