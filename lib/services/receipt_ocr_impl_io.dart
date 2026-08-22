import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'receipt_ocr_models.dart';

Future<ReceiptOcrResult> scanReceiptFile(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    throw const FileSystemException('Foto struk tidak ditemukan.');
  }
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final input = InputImage.fromFilePath(path);
    final recognized = await recognizer.processImage(input);
    return _parse(recognized.text);
  } finally {
    await recognizer.close();
  }
}

ReceiptOcrResult _parse(String text) {
  final lines = text
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
  String? merchant;
  for (final line in lines.take(4)) {
    if (!_looksLikeHeaderNoise(line) && line.length >= 2) {
      merchant = line;
      break;
    }
  }
  merchant ??= lines.isEmpty ? null : lines.first;
  return ReceiptOcrResult(
    text: text.trim(),
    merchant: merchant,
    amount: _findAmount(lines),
    date: _findDate(text),
  );
}

bool _looksLikeHeaderNoise(String value) => RegExp(
  r'^(?:tel|phone|kasir|struk|invoice|receipt|no\.?\s*[:#])',
  caseSensitive: false,
).hasMatch(value);

double? _findAmount(List<String> lines) {
  final totalCandidates = <double>[];
  final otherCandidates = <double>[];
  for (final line in lines) {
    final target =
        RegExp(
          r'\b(total|grand\s*total|jumlah|bayar|amount|tagihan)\b',
          caseSensitive: false,
        ).hasMatch(line)
        ? totalCandidates
        : otherCandidates;
    for (final match in RegExp(
      r'(?:rp\.?\s*)?([0-9][0-9.,]{2,})',
      caseSensitive: false,
    ).allMatches(line)) {
      final raw = match.group(1)!.replaceAll(RegExp(r'[^0-9]'), '');
      final parsed = double.tryParse(raw);
      if (parsed != null && parsed > 0 && parsed <= 100000000000) {
        target.add(parsed);
      }
    }
  }
  final candidates = totalCandidates.isNotEmpty
      ? totalCandidates
      : otherCandidates;
  if (candidates.isEmpty) return null;
  candidates.sort();
  return candidates.last;
}

DateTime? _findDate(String text) {
  final match = RegExp(
    r'\b(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})\b',
  ).firstMatch(text);
  if (match == null) return null;
  final day = int.tryParse(match.group(1)!);
  final month = int.tryParse(match.group(2)!);
  var year = int.tryParse(match.group(3)!);
  if (day == null || month == null || year == null) return null;
  if (year < 100) year += 2000;
  return DateTime.tryParse(
    '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
  );
}
