import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/finance_models.dart';

class BackupService {
  Future<File> createBackup({
    required List<ExpenseEntry> expenses,
    required List<DebtEntry> debts,
  }) async {
    await _requestStoragePermission();
    final root = Directory('/storage/emulated/0/Documents/CatatBibz');
    await root.create(recursive: true);

    final stamp = _stamp(DateTime.now());
    final temp = Directory('${root.path}/.tmp_$stamp');
    await temp.create(recursive: true);
    final photos = Directory('${temp.path}/photos');
    await photos.create(recursive: true);

    final expenseJson = <Map<String, dynamic>>[];
    for (final entry in expenses) {
      expenseJson.add(await _withBackupPhoto(entry.toJson(), entry.imagePath, photos, 'expense_${entry.id}'));
    }

    final debtJson = <Map<String, dynamic>>[];
    for (final entry in debts) {
      debtJson.add(await _withBackupPhoto(entry.toJson(), entry.imagePath, photos, 'debt_${entry.id}'));
    }

    final manifest = <String, dynamic>{
      'format': 'bibzcup',
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'compression': 'zip-deflate-level-9',
      'expenses': expenseJson,
      'debts': debtJson,
    };
    await File('${temp.path}/manifest.json').writeAsString(const JsonEncoder.withIndent('  ').convert(manifest));

    final output = File('${root.path}/CatatanPengeluaran_$stamp.bibzcup');
    final encoder = ZipFileEncoder();
    encoder.create(output.path, level: 9);
    await encoder.addDirectory(temp, includeDirName: false, level: 9);
    await encoder.close();

    await temp.delete(recursive: true);
    return output;
  }

  Future<void> _requestStoragePermission() async {
    if (!Platform.isAndroid) return;
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) status = await Permission.manageExternalStorage.request();
    if (!status.isGranted) {
      status = await Permission.storage.status;
      if (!status.isGranted) status = await Permission.storage.request();
    }
    if (!status.isGranted) {
      throw StateError('Izin penyimpanan diperlukan untuk membuat /sdcard/Documents/CatatBibz.');
    }
  }

  Future<Map<String, dynamic>> _withBackupPhoto(
    Map<String, dynamic> json,
    String? sourcePath,
    Directory photos,
    String baseName,
  ) async {
    final result = Map<String, dynamic>.from(json);
    if (sourcePath == null || sourcePath.isEmpty) return result;
    final source = File(sourcePath);
    if (!await source.exists()) return result;

    final extension = source.path.contains('.') ? source.path.split('.').last : 'jpg';
    final filename = '$baseName.$extension';
    await source.copy('${photos.path}/$filename');
    result['backupPhoto'] = 'photos/$filename';
    return result;
  }

  String _stamp(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}${two(date.month)}${two(date.day)}_${two(date.hour)}${two(date.minute)}${two(date.second)}';
  }
}
