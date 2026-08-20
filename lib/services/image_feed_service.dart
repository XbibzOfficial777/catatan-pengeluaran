import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class ImageFeedSnapshot {
  const ImageFeedSnapshot({
    required this.urls,
    required this.fromCache,
    required this.errorMessage,
  });

  final List<String> urls;
  final bool fromCache;
  final String? errorMessage;
}

class ImageFeedService {
  static const sourceUrl = 'https://pastebin.com/raw/ytnu2NLD';
  static const _cachedUrlsKey = 'dashboard_image_urls_v1';
  static const _cachedAtKey = 'dashboard_image_urls_cached_at_v1';
  static const fallbackUrls = <String>[];

  Future<ImageFeedSnapshot> load({bool forceRefresh = false}) async {
    final preferences = await SharedPreferences.getInstance();
    final cached = preferences.getStringList(_cachedUrlsKey) ?? fallbackUrls;
    if (!forceRefresh && cached.isNotEmpty) {
      return ImageFeedSnapshot(
        urls: cached,
        fromCache: true,
        errorMessage: null,
      );
    }

    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final urls = await _fetchFromNetwork();
        if (urls.isNotEmpty) {
          await preferences.setStringList(_cachedUrlsKey, urls);
          await preferences.setString(
            _cachedAtKey,
            DateTime.now().toIso8601String(),
          );
          return ImageFeedSnapshot(
            urls: urls,
            fromCache: false,
            errorMessage: null,
          );
        }
      } catch (error) {
        lastError = error;
        await Future<void>.delayed(Duration(milliseconds: 350 * (attempt + 1)));
      }
    }

    return ImageFeedSnapshot(
      urls: cached,
      fromCache: cached.isNotEmpty,
      errorMessage: lastError == null
          ? 'Belum ada gambar dari sumber.'
          : 'Koneksi sedang bermasalah.',
    );
  }

  Future<void> clearCache() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_cachedUrlsKey);
    await preferences.remove(_cachedAtKey);
  }

  Future<List<String>> _fetchFromNetwork() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      final request = await client
          .getUrl(Uri.parse(sourceUrl))
          .timeout(const Duration(seconds: 8));
      request.followRedirects = true;
      request.headers.set(HttpHeaders.acceptHeader, 'text/plain');
      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Pastebin HTTP ${response.statusCode}');
      }
      final text = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 8));
      return text
          .split(RegExp(r'[\s,;]+'))
          .map((item) => item.trim())
          .where(_isImageUrl)
          .toSet()
          .take(8)
          .toList(growable: false);
    } finally {
      client.close(force: true);
    }
  }

  bool _isImageUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return false;
    final path = uri.path.toLowerCase();
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.webp') ||
        path.endsWith('.gif');
  }
}
