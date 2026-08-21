import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../models/json_helpers.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.version,
    required this.versionCode,
    required this.universalApkUrl,
    required this.arm64ApkUrl,
    this.releaseNotes = '',
    this.sha256Universal = '',
    this.sha256Arm64 = '',
  });

  final String version;
  final int versionCode;
  final String universalApkUrl;
  final String arm64ApkUrl;
  final String releaseNotes;

  /// Checksum SHA256 opsional (hex). Bila metadata menyediakan nilai ini,
  /// APK hasil unduhan wajib cocok sebelum proses instalasi dilanjutkan.
  final String sha256Universal;
  final String sha256Arm64;

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    String readUrl(String primary, String fallback) =>
        readString(json[primary] ?? json[fallback]);
    return AppUpdateInfo(
      version: readString(json['version'], fallback: '0.0.0'),
      versionCode: readInt(json['versionCode']),
      universalApkUrl: readUrl('universalApkUrl', 'universalUrl'),
      arm64ApkUrl: readUrl('arm64ApkUrl', 'downloadUrl'),
      releaseNotes: readString(json['releaseNotes']),
      sha256Universal: readString(
        json['sha256Universal'] ?? json['universalSha256'],
      ),
      sha256Arm64: readString(json['sha256Arm64'] ?? json['arm64Sha256']),
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
  static const changelogUrl =
      'https://raw.githubusercontent.com/XbibzOfficial777/catatan-pengeluaran/main/CHANGELOG.MD';
  static const _channel = MethodChannel('catatan/app_update');

  /// Host yang diizinkan sebagai sumber unduhan APK. Metadata update diambil
  /// dari repo ini, jadi APK juga harus berasal dari domain GitHub resmi —
  /// menutup jalur injeksi URL arbitrer bila akun/berkas metadata disusupi.
  static const _allowedApkHosts = <String>{
    'github.com',
    'objects.githubusercontent.com',
    'release-assets.githubusercontent.com',
    'github-releases.githubusercontent.com',
  };

  bool get supportsApkInstall =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @visibleForTesting
  static bool isAllowedApkUrl(Uri url) {
    if (url.scheme != 'https') return false;
    final host = url.host.toLowerCase();
    if (_allowedApkHosts.contains(host)) return true;
    return host.endsWith('.githubusercontent.com') ||
        host.endsWith('.github.com');
  }

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
    if (decoded is! Map)
      throw const FormatException('Format update tidak valid.');
    return AppUpdateInfo.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<String> fetchChangelog() async {
    final url = Uri.parse(changelogUrl).replace(
      queryParameters: <String, String>{
        'cacheBust': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    return _getText(url.toString(), accept: 'text/markdown');
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
      throw const FormatException(
        'URL APK belum tersedia di version-latest.json.',
      );
    }
    final directory = await getTemporaryDirectory();
    // Sanitasi nama versi dari metadata agar tidak bisa menyuntik path.
    final safeVersion = info.version.replaceAll(
      RegExp(r'[^0-9A-Za-z._-]'),
      '_',
    );
    final file = File(
      '${directory.path}/catatan_pengeluaran_update_$safeVersion.apk',
    );
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 12);
    try {
      HttpException? lastHttpError;
      for (final url in urls) {
        final parsedUrl = Uri.tryParse(url);
        if (parsedUrl == null || !isAllowedApkUrl(parsedUrl)) {
          lastHttpError = HttpException(
            'URL APK tidak valid atau bukan https GitHub resmi: $url',
          );
          continue;
        }
        try {
          final request = await client
              .getUrl(parsedUrl)
              .timeout(const Duration(seconds: 15));
          request.followRedirects = true;
          request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
          final response = await request.close().timeout(
            const Duration(seconds: 30),
          );
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
          final checksumError = await _verifyChecksum(file, url, info);
          if (checksumError != null) {
            lastHttpError = HttpException(checksumError);
            try {
              await file.delete();
            } catch (_) {}
            continue;
          }
          return file.path;
        } on HttpException catch (error) {
          lastHttpError = error;
        }
      }
      throw lastHttpError ??
          const HttpException('Semua URL APK gagal diakses.');
    } finally {
      client.close(force: true);
    }
  }

  Future<void> installApk(String path) async {
    await _channel.invokeMethod<void>('install_apk', {'path': path});
  }

  /// Verifikasi checksum SHA256 APK unduhan bila metadata menyediakannya.
  ///
  /// Mengembalikan null bila checksum cocok atau tidak tersedia (kompatibilitas
  /// metadata lama), atau pesan error bila tidak cocok.
  @visibleForTesting
  static Future<String?> verifyApkChecksum(
    File file,
    String downloadedUrl,
    AppUpdateInfo info,
  ) {
    return _verifyChecksum(file, downloadedUrl, info);
  }

  static Future<String?> _verifyChecksum(
    File file,
    String downloadedUrl,
    AppUpdateInfo info,
  ) async {
    final expected = downloadedUrl == info.arm64ApkUrl
        ? info.sha256Arm64
        : info.sha256Universal;
    if (expected.isEmpty) return null;
    final digest = sha256.convert(await file.readAsBytes()).toString();
    if (digest != expected.toLowerCase()) {
      return 'Checksum APK tidak cocok (harapan ${expected.toLowerCase().substring(0, 12)}…, '
          'hasil ${digest.substring(0, 12)}…). Unduhan dibatalkan demi keamanan.';
    }
    return null;
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

  Future<String> _getText(
    String url, {
    String accept = 'application/json',
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client
          .getUrl(Uri.parse(url))
          .timeout(const Duration(seconds: 12));
      request.followRedirects = true;
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
      request.headers.set(HttpHeaders.acceptHeader, accept);
      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Update check HTTP ${response.statusCode}');
      }
      return await response.transform(utf8.decoder).join();
    } finally {
      client.close(force: true);
    }
  }
}
