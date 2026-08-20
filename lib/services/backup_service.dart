import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:xml/xml.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/finance_models.dart';
import '../models/reminder_models.dart';
import '../models/advanced_finance_models.dart';
import 'backup_integrity_service.dart';

class BackupService {
  BackupService({BackupIntegrityService? integrity})
    : _integrity = integrity ?? BackupIntegrityService();

  final BackupIntegrityService _integrity;

  Future<File> createBackup({
    required List<ExpenseEntry> expenses,
    required List<DebtEntry> debts,
    double pocketMoney = 0,
    List<ReminderSchedule> reminders = const <ReminderSchedule>[],
    List<MoneyAccount> accounts = const <MoneyAccount>[],
    List<BudgetLimit> budgets = const <BudgetLimit>[],
    List<RecurringExpense> recurring = const <RecurringExpense>[],
    bool privacyMode = false,
  }) async {
    await _requestStoragePermission();
    final root = Directory('/storage/emulated/0/Documents/CatatBibz');
    await root.create(recursive: true);

    final stamp = _stamp(DateTime.now());
    final temp = Directory('${root.path}/.tmp_$stamp');
    await temp.create(recursive: true);
    final photos = Directory('${temp.path}/photos');
    await photos.create(recursive: true);

    try {
      final expenseXml = <XmlElement>[];
      for (final entry in expenses) {
        final data = await _withBackupPhoto(
          entry.toJson(),
          entry.imagePath,
          photos,
          'expense_${entry.id}',
        );
        expenseXml.add(_integrity.createEntry('expense', data));
      }

      final debtXml = <XmlElement>[];
      for (final entry in debts) {
        final data = await _withBackupPhoto(
          entry.toJson(),
          entry.imagePath,
          photos,
          'debt_${entry.id}',
        );
        debtXml.add(_integrity.createEntry('debt', data));
      }

      final reminderXml = reminders
          .map((item) => _integrity.createEntry('reminder', item.toJson()))
          .toList();
      final accountXml = accounts
          .map((item) => _integrity.createEntry('account', item.toJson()))
          .toList();
      final budgetXml = budgets
          .map((item) => _integrity.createEntry('budget', item.toJson()))
          .toList();
      final recurringXml = recurring
          .map(
            (item) => _integrity.createEntry('recurringExpense', item.toJson()),
          )
          .toList();
      final fileXml = <XmlElement>[];
      await for (final entity in photos.list()) {
        if (entity is! File) continue;
        final relativePath = 'photos/${entity.path.split('/').last}';
        final digest = await _integrity.sha256Bytes(await entity.readAsBytes());
        fileXml.add(_integrity.createFileEntry(relativePath, digest));
      }

      final manifestRoot = _integrity.createRoot(
        createdAt: DateTime.now(),
        pocketMoney: pocketMoney,
        expenses: expenseXml,
        debts: debtXml,
        reminders: reminderXml,
        accounts: accountXml,
        budgets: budgetXml,
        recurring: recurringXml,
        privacyMode: privacyMode,
        files: fileXml,
      );
      final signature = await _integrity.createSignature(
        _integrity.canonicalize(manifestRoot),
      );
      manifestRoot.children.add(_integrity.createIntegrity(signature));
      await File('${temp.path}/manifest.xml').writeAsString(
        XmlDocument([manifestRoot]).toXmlString(pretty: true, indent: '  '),
        flush: true,
      );

      final output = File('${root.path}/CatatanPengeluaran_$stamp.bibzcup');
      final encoder = ZipFileEncoder();
      encoder.create(output.path, level: 9);
      await encoder.addDirectory(temp, includeDirName: false, level: 9);
      await encoder.close();
      return output;
    } finally {
      if (await temp.exists()) await temp.delete(recursive: true);
    }
  }

  Future<void> _requestStoragePermission() async {
    if (!Platform.isAndroid) return;
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted)
      status = await Permission.manageExternalStorage.request();
    if (!status.isGranted) {
      status = await Permission.storage.status;
      if (!status.isGranted) status = await Permission.storage.request();
    }
    if (!status.isGranted) {
      throw StateError(
        'Izin penyimpanan diperlukan untuk membuat /sdcard/Documents/CatatBibz.',
      );
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

    final extension = source.path.contains('.')
        ? source.path.split('.').last.toLowerCase()
        : 'jpg';
    final safeExtension = RegExp(r'^[a-z0-9]{1,8}$').hasMatch(extension)
        ? extension
        : 'jpg';
    final filename = '$baseName.$safeExtension';
    await source.copy('${photos.path}/$filename');
    result['backupPhoto'] = 'photos/$filename';
    return result;
  }

  String _stamp(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}${two(date.month)}${two(date.day)}_${two(date.hour)}${two(date.minute)}${two(date.second)}';
  }
}
