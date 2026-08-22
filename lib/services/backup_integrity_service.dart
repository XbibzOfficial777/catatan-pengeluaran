import 'dart:convert';
import 'dart:math' as math;

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:xml/xml.dart';

class BackupIntegrityService {
  static const _keyName = 'catatbibz_hmac_key_v1';
  static const _algorithm = 'HMAC-SHA256';
  static const _manifestName = 'manifest.xml';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<String> createSignature(String canonicalManifest) async {
    final key = await _deviceKey();
    return Hmac(sha256, key).convert(utf8.encode(canonicalManifest)).toString();
  }

  Future<bool> verifySignature(
    String canonicalManifest,
    String expected,
  ) async {
    if (expected.isEmpty) return false;
    final actual = await createSignature(canonicalManifest);
    return _constantTimeEquals(actual, expected);
  }

  Future<List<int>> _deviceKey() async {
    final stored = await _secureStorage.read(key: _keyName);
    if (stored != null && stored.isNotEmpty) {
      try {
        final decoded = base64Url.decode(stored);
        if (decoded.length == 32) return decoded;
      } on FormatException {
        // Regenerate a valid key when secure storage contains malformed data.
      }
      await _secureStorage.delete(key: _keyName);
    }
    final random = math.Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    await _secureStorage.write(key: _keyName, value: base64UrlEncode(bytes));
    return bytes;
  }

  bool _constantTimeEquals(String left, String right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var index = 0; index < left.length; index++) {
      difference |= left.codeUnitAt(index) ^ right.codeUnitAt(index);
    }
    return difference == 0;
  }

  XmlElement createRoot({
    required DateTime createdAt,
    required double pocketMoney,
    required List<XmlElement> expenses,
    required List<XmlElement> debts,
    required List<XmlElement> reminders,
    required List<XmlElement> accounts,
    required List<XmlElement> budgets,
    required List<XmlElement> recurring,
    required List<XmlElement> savingsGoals,
    required List<XmlElement> splitBills,
    required List<XmlElement> reconciliationSnapshots,
    required List<XmlElement> merchantCategoryRules,
    required bool privacyMode,
    required List<XmlElement> files,
  }) {
    return XmlElement.tag(
      'bibzcup',
      attributes: [
        XmlAttribute(XmlName('format'), 'bibzcup'),
        XmlAttribute(XmlName('version'), '2'),
        XmlAttribute(XmlName('manifest'), 'xml'),
        XmlAttribute(XmlName('compression'), 'zip-deflate-level-9'),
      ],
      children: [
        _textElement('createdAt', createdAt.toIso8601String()),
        _textElement('pocketMoney', pocketMoney.toString()),
        XmlElement.tag('expenses', children: expenses),
        XmlElement.tag('debts', children: debts),
        XmlElement.tag('reminders', children: reminders),
        XmlElement.tag('accounts', children: accounts),
        XmlElement.tag('budgets', children: budgets),
        XmlElement.tag('recurringExpenses', children: recurring),
        XmlElement.tag('savingsGoals', children: savingsGoals),
        XmlElement.tag('splitBills', children: splitBills),
        XmlElement.tag(
          'reconciliationSnapshots',
          children: reconciliationSnapshots,
        ),
        XmlElement.tag(
          'merchantCategoryRules',
          children: merchantCategoryRules,
        ),
        _textElement('privacyMode', privacyMode.toString()),
        XmlElement.tag('files', children: files),
      ],
    );
  }

  XmlElement createEntry(String name, Map<String, dynamic> values) {
    return XmlElement.tag(
      name,
      children: values.entries.where((entry) => entry.value != null).map((
        entry,
      ) {
        final value = entry.value;
        final isNestedJson =
            value is Map ||
            (value is List && value.any((item) => item is Map || item is List));
        final type = isNestedJson
            ? 'json'
            : value is bool
            ? 'bool'
            : value is num
            ? 'number'
            : value is List
            ? 'list'
            : 'string';
        final text = isNestedJson
            ? jsonEncode(value)
            : value is List
            ? value.join(',')
            : value.toString();
        return XmlElement.tag(
          'field',
          attributes: [
            XmlAttribute(XmlName('name'), entry.key),
            XmlAttribute(XmlName('type'), type),
          ],
          children: [XmlText(text)],
        );
      }),
    );
  }

  XmlElement createFileEntry(String path, String digest) {
    return XmlElement.tag(
      'file',
      attributes: [
        XmlAttribute(XmlName('path'), path),
        XmlAttribute(XmlName('sha256'), digest),
      ],
    );
  }

  XmlElement createIntegrity(String signature) {
    return XmlElement.tag(
      'integrity',
      attributes: [
        XmlAttribute(XmlName('algorithm'), _algorithm),
        XmlAttribute(XmlName('scope'), 'device-keystore'),
        XmlAttribute(XmlName('value'), signature),
      ],
    );
  }

  String canonicalize(XmlElement root) {
    final copy = root.copy();
    copy.children.removeWhere(
      (node) => node is XmlElement && node.name.local == 'integrity',
    );
    _stripFormattingWhitespace(copy);
    return XmlDocument([copy]).toXmlString(pretty: false);
  }

  void _stripFormattingWhitespace(XmlElement element) {
    final hasElementChildren = element.children.any(
      (node) => node is XmlElement,
    );
    if (hasElementChildren) {
      element.children.removeWhere(
        (node) => node is XmlText && node.text.trim().isEmpty,
      );
    }
    for (final child in element.children.whereType<XmlElement>()) {
      _stripFormattingWhitespace(child);
    }
  }

  Map<String, dynamic> parseEntry(XmlElement element) {
    final result = <String, dynamic>{};
    for (final field in element.findElements('field')) {
      final name = field.getAttribute('name');
      if (name == null) continue;
      final type = field.getAttribute('type');
      final value = field.innerText;
      result[name] = switch (type) {
        'bool' => value.toLowerCase() == 'true',
        'number' => double.tryParse(value) ?? 0,
        'list' =>
          value.trim().isEmpty
              ? <int>[]
              : value
                    .split(',')
                    .map((item) => int.tryParse(item.trim()) ?? 0)
                    .toList(),
        'json' => _decodeJsonValue(value),
        _ => value,
      };
    }
    return result;
  }

  dynamic _decodeJsonValue(String value) {
    try {
      return jsonDecode(value);
    } catch (_) {
      return null;
    }
  }

  Map<String, String> parseFileHashes(XmlElement root) {
    final files = <String, String>{};
    final filesElement = root.findElements('files').firstOrNull;
    if (filesElement == null) return files;
    for (final file in filesElement.findElements('file')) {
      final path = file.getAttribute('path');
      final hash = file.getAttribute('sha256');
      if (path != null && hash != null) files[path] = hash;
    }
    return files;
  }

  String? integrityValue(XmlElement root) =>
      root.findElements('integrity').firstOrNull?.getAttribute('value');

  bool isSafeRelativePath(String path) =>
      path.isNotEmpty &&
      !path.startsWith('/') &&
      !path.contains('..') &&
      !path.contains('\\');

  Future<String> sha256Bytes(List<int> bytes) async =>
      sha256.convert(bytes).toString();

  Future<bool> verifyArchiveFiles(
    Archive archive,
    Map<String, String> expectedHashes,
  ) async {
    final files = <String, ArchiveFile>{};
    for (final file in archive.files) {
      if (!file.isFile) continue;
      if (!isSafeRelativePath(file.name)) return false;
      if (files.containsKey(file.name)) return false;
      files[file.name] = file;
    }
    final expectedPaths = expectedHashes.keys.toSet();
    if (!files.keys.toSet().containsAll(expectedPaths)) return false;
    if (files.keys.any(
      (path) => path != _manifestName && !expectedPaths.contains(path),
    ))
      return false;
    for (final entry in expectedHashes.entries) {
      final content = files[entry.key]?.content;
      if (content is! List<int>) return false;
      if (await sha256Bytes(content) != entry.value) return false;
    }
    return true;
  }

  List<int> bytes(ArchiveFile file) {
    final content = file.content;
    return content is List<int> ? List<int>.from(content) : <int>[];
  }

  XmlElement _textElement(String name, String value) =>
      XmlElement.tag(name, children: [XmlText(value)]);
}
