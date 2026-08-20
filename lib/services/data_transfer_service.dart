import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:excel_plus/excel_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:xml/xml.dart';
import 'package:path_provider/path_provider.dart';

import '../models/finance_models.dart';
import '../models/reminder_models.dart';
import '../models/advanced_finance_models.dart';
import 'backup_integrity_service.dart';

class RestorePayload {
  const RestorePayload({
    required this.expenses,
    required this.debts,
    required this.sourceName,
    this.pocketMoney = 0,
    this.reminders = const <ReminderSchedule>[],
    this.accounts = const <MoneyAccount>[],
    this.budgets = const <BudgetLimit>[],
    this.recurring = const <RecurringExpense>[],
    this.privacyMode = false,
  });

  final List<ExpenseEntry> expenses;
  final List<DebtEntry> debts;
  final String sourceName;
  final double pocketMoney;
  final List<ReminderSchedule> reminders;
  final List<MoneyAccount> accounts;
  final List<BudgetLimit> budgets;
  final List<RecurringExpense> recurring;
  final bool privacyMode;
}

class DataTransferService {
  DataTransferService({BackupIntegrityService? integrity})
    : _integrity = integrity ?? BackupIntegrityService();

  final BackupIntegrityService _integrity;

  Future<RestorePayload?> pickAndRestore() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['bibzcup'],
      withData: false,
    );
    if (picked.isEmpty || picked.first.path == null) return null;

    final source = File(picked.first.path!);
    if (!source.path.toLowerCase().endsWith('.bibzcup')) {
      throw const FormatException(
        'Restore ditolak: file harus berformat .bibzcup.',
      );
    }

    final archive = ZipDecoder().decodeBytes(await source.readAsBytes());
    final manifestFile = archive.files
        .where((file) => file.name == 'manifest.xml')
        .firstOrNull;
    if (manifestFile == null)
      throw const FormatException(
        'Restore ditolak: manifest.xml tidak ditemukan.',
      );

    final document = XmlDocument.parse(
      utf8.decode(_integrity.bytes(manifestFile)),
    );
    final root = document.rootElement;
    if (root.name.local != 'bibzcup' ||
        root.getAttribute('format') != 'bibzcup' ||
        root.getAttribute('manifest') != 'xml') {
      throw const FormatException(
        'Restore ditolak: format manifest XML tidak dikenali.',
      );
    }
    if (root.getAttribute('version') != '2') {
      throw const FormatException(
        'Restore ditolak: versi backup tidak didukung.',
      );
    }

    final expectedSignature = _integrity.integrityValue(root);
    if (expectedSignature == null ||
        !await _integrity.verifySignature(
          _integrity.canonicalize(root),
          expectedSignature,
        )) {
      throw const FormatException(
        'Restore ditolak: backup telah berubah atau bukan dibuat oleh perangkat ini.',
      );
    }
    final expectedFiles = _integrity.parseFileHashes(root);
    if (!await _integrity.verifyArchiveFiles(archive, expectedFiles)) {
      throw const FormatException(
        'Restore ditolak: isi file backup tidak cocok dengan checksum manifest.',
      );
    }

    final pocketMoney =
        double.tryParse(
          root.findElements('pocketMoney').firstOrNull?.innerText ?? '',
        ) ??
        0;
    final documents = await getApplicationDocumentsDirectory();
    final restoredPhotos = Directory('${documents.path}/attachments');
    await restoredPhotos.create(recursive: true);

    final expenses = <ExpenseEntry>[];
    final expenseContainer = root.findElements('expenses').firstOrNull;
    for (final item
        in expenseContainer?.findElements('expense') ?? const <XmlElement>[]) {
      final json = await _restorePhoto(
        _integrity.parseEntry(item),
        archive,
        restoredPhotos,
      );
      expenses.add(ExpenseEntry.fromJson(json));
    }

    final debts = <DebtEntry>[];
    final debtContainer = root.findElements('debts').firstOrNull;
    for (final item
        in debtContainer?.findElements('debt') ?? const <XmlElement>[]) {
      final json = await _restorePhoto(
        _integrity.parseEntry(item),
        archive,
        restoredPhotos,
      );
      debts.add(DebtEntry.fromJson(json));
    }

    final reminders = <ReminderSchedule>[];
    final reminderContainer = root.findElements('reminders').firstOrNull;
    for (final item
        in reminderContainer?.findElements('reminder') ??
            const <XmlElement>[]) {
      reminders.add(ReminderSchedule.fromJson(_integrity.parseEntry(item)));
    }

    final accounts = <MoneyAccount>[];
    for (final item
        in root.findElements('accounts').firstOrNull?.findElements('account') ??
            const <XmlElement>[]) {
      accounts.add(MoneyAccount.fromJson(_integrity.parseEntry(item)));
    }
    final budgets = <BudgetLimit>[];
    for (final item
        in root.findElements('budgets').firstOrNull?.findElements('budget') ??
            const <XmlElement>[]) {
      budgets.add(BudgetLimit.fromJson(_integrity.parseEntry(item)));
    }
    final recurring = <RecurringExpense>[];
    for (final item
        in root
                .findElements('recurringExpenses')
                .firstOrNull
                ?.findElements('recurringExpense') ??
            const <XmlElement>[]) {
      recurring.add(RecurringExpense.fromJson(_integrity.parseEntry(item)));
    }
    final privacyMode =
        (root.findElements('privacyMode').firstOrNull?.innerText ?? 'false')
            .toLowerCase() ==
        'true';

    return RestorePayload(
      expenses: expenses,
      debts: debts,
      sourceName: source.path.split('/').last,
      pocketMoney: pocketMoney,
      reminders: reminders,
      accounts: accounts,
      budgets: budgets,
      recurring: recurring,
      privacyMode: privacyMode,
    );
  }

  Future<File> createSpreadsheet({
    required List<ExpenseEntry> expenses,
    required List<DebtEntry> debts,
    double pocketMoney = 0,
  }) async {
    final workbook = Excel.createExcel();
    workbook.rename('Sheet1', 'Overview');
    final overview = workbook['Overview'];
    final transactions = workbook['Transactions'];
    final debtsSheet = workbook['Hutang & Piutang'];
    workbook.setDefaultSheet('Overview');

    _configureOverview(overview, expenses, debts, pocketMoney);
    _configureTransactions(transactions, expenses, debts);
    _configureDebts(debtsSheet, debts);

    final directory = await getTemporaryDirectory();
    final stamp = _stamp(DateTime.now());
    final file = File(
      '${directory.path}/Laporan_CatatanPengeluaran_$stamp.xlsx',
    );
    final bytes = workbook.save();
    if (bytes == null || bytes.isEmpty)
      throw StateError('Workbook tidak dapat dibuat.');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  void _configureOverview(
    Sheet sheet,
    List<ExpenseEntry> expenses,
    List<DebtEntry> debts,
    double pocketMoney,
  ) {
    _hideGrid(sheet);
    _setWidths(sheet, {
      0: 3,
      1: 23,
      2: 18,
      3: 18,
      4: 18,
      5: 18,
      6: 4,
      7: 22,
      8: 18,
    });
    sheet.merge(
      CellIndex.indexByString('B2'),
      CellIndex.indexByString('I2'),
      customValue: TextCellValue('CATATAN PENGELUARAN'),
    );
    _put(sheet, 1, 1, TextCellValue('CATATAN PENGELUARAN'), _titleStyle());
    _put(
      sheet,
      1,
      2,
      TextCellValue('Ringkasan keuangan pribadi dan laporan transaksi'),
      _subtitleStyle(),
    );
    _put(sheet, 1, 4, TextCellValue('RINGKASAN UTAMA'), _sectionStyle());

    final totalExpense = expenses.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final remainingPocketMoney = pocketMoney - totalExpense;
    final payable = debts
        .where((item) => item.kind == DebtKind.payable && !item.isSettled)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final receivable = debts
        .where((item) => item.kind == DebtKind.receivable && !item.isSettled)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final settled = debts.where((item) => item.isSettled).length;

    final metrics = <List<Object>>[
      ['Uang Saku', pocketMoney, 'Batas dana yang ditetapkan'],
      [
        'Sisa Uang Saku',
        remainingPocketMoney,
        'Uang saku dikurangi pengeluaran',
      ],
      ['Total Pengeluaran', totalExpense, 'Semua transaksi tercatat'],
      ['Hutang Aktif', payable, 'Kewajiban yang belum lunas'],
      ['Piutang Aktif', receivable, 'Tagihan yang belum diterima'],
      ['Catatan Lunas', settled, 'Hutang/piutang selesai'],
    ];
    for (var index = 0; index < metrics.length; index++) {
      final col = 1 + index * 2;
      final value = metrics[index][1];
      _put(
        sheet,
        col,
        5,
        TextCellValue(metrics[index][0] as String),
        _metricLabelStyle(),
      );
      _put(
        sheet,
        col,
        6,
        value is double ? DoubleCellValue(value) : IntCellValue(value as int),
        _metricValueStyle(value is double),
      );
      _put(
        sheet,
        col,
        7,
        TextCellValue(metrics[index][2] as String),
        _noteStyle(),
      );
    }

    _put(sheet, 1, 9, TextCellValue('KONTEN WORKBOOK'), _sectionStyle());
    final contents = [
      ['Overview', 'Ringkasan KPI dan petunjuk penggunaan'],
      [
        'Transactions',
        'Seluruh pengeluaran dan hutang/piutang dalam satu tabel',
      ],
      [
        'Hutang & Piutang',
        'Detail kewajiban, tagihan, kontak, dan status pelunasan',
      ],
    ];
    for (var index = 0; index < contents.length; index++) {
      final row = 10 + index;
      _put(sheet, 1, row, TextCellValue(contents[index][0]), _linkStyle());
      _put(sheet, 2, row, TextCellValue(contents[index][1]), _bodyStyle());
    }

    _put(sheet, 1, 15, TextCellValue('CATATAN LAPORAN'), _sectionStyle());
    sheet.merge(
      CellIndex.indexByString('B16'),
      CellIndex.indexByString('I17'),
      customValue: TextCellValue(
        'Workbook dibuat dari data lokal Catatan Pengeluaran. Nominal ditampilkan dalam Rupiah. Gunakan filter pada sheet detail untuk meninjau data berdasarkan tanggal, status, kategori, atau arah transaksi.',
      ),
    );
    _put(sheet, 1, 15, TextCellValue('CATATAN LAPORAN'), _sectionStyle());
    _put(sheet, 1, 19, TextCellValue('Dibuat pada'), _bodyStyle());
    _put(
      sheet,
      2,
      19,
      DateTimeCellValue.fromDateTime(DateTime.now()),
      _dateTimeStyle(),
    );
    sheet.setRowHeight(1, 34);
    sheet.setRowHeight(2, 22);
    sheet.setRowHeight(16, 24);
    sheet.setRowHeight(17, 24);
  }

  void _configureTransactions(
    Sheet sheet,
    List<ExpenseEntry> expenses,
    List<DebtEntry> debts,
  ) {
    _hideGrid(sheet);
    final headers = [
      'No',
      'Jenis',
      'Status',
      'Arah',
      'Untuk Apa / Nama',
      'Kategori',
      'Nominal (Rp)',
      'Tanggal',
      'Jatuh Tempo',
      'Nomor Kontak',
      'Catatan',
      'Lampiran',
      'Dibuat Pada',
    ];
    final widths = <int, double>{
      0: 7,
      1: 16,
      2: 13,
      3: 18,
      4: 26,
      5: 16,
      6: 18,
      7: 14,
      8: 15,
      9: 18,
      10: 30,
      11: 12,
      12: 20,
    };
    _setWidths(sheet, widths);
    _put(sheet, 0, 0, TextCellValue('LAPORAN DETAIL TRANSAKSI'), _titleStyle());
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: headers.length - 1, rowIndex: 0),
    );
    _put(
      sheet,
      0,
      1,
      TextCellValue(
        'Gunakan filter pada header untuk meninjau transaksi secara profesional.',
      ),
      _subtitleStyle(),
    );
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      CellIndex.indexByColumnRow(columnIndex: headers.length - 1, rowIndex: 1),
    );
    for (var col = 0; col < headers.length; col++) {
      _put(sheet, col, 3, TextCellValue(headers[col]), _headerStyle());
    }

    var row = 4;
    var number = 1;
    for (final entry in expenses) {
      _writeTransactionRow(
        sheet,
        row++,
        number++,
        'Pengeluaran',
        'Tercatat',
        'Keluar',
        entry.title,
        _categoryLabel(entry.category),
        entry.amount,
        entry.date,
        null,
        '',
        '',
        entry.note,
        entry.imagePath != null,
        entry.createdAt,
      );
    }
    for (final entry in debts) {
      _writeTransactionRow(
        sheet,
        row++,
        number++,
        entry.kind == DebtKind.payable ? 'Hutang' : 'Piutang',
        entry.isSettled ? 'Lunas' : 'Aktif',
        entry.kind == DebtKind.payable ? 'Saya berhutang' : 'Dipinjam orang',
        entry.person,
        '',
        entry.amount,
        entry.date,
        entry.dueDate,
        entry.contactPhone ?? '',
        '',
        entry.note,
        entry.imagePath != null,
        entry.createdAt,
      );
    }
    if (row == 4)
      _put(
        sheet,
        0,
        4,
        TextCellValue('Belum ada data transaksi.'),
        _bodyStyle(),
      );
  }

  void _configureDebts(Sheet sheet, List<DebtEntry> debts) {
    _hideGrid(sheet);
    final headers = [
      'No',
      'Nama',
      'Tipe',
      'Status',
      'Nominal (Rp)',
      'Tanggal',
      'Jatuh Tempo',
      'Nomor Kontak',
      'Catatan',
      'Lampiran',
      'Dibuat Pada',
    ];
    _setWidths(sheet, {
      0: 7,
      1: 24,
      2: 18,
      3: 14,
      4: 18,
      5: 14,
      6: 15,
      7: 19,
      8: 32,
      9: 12,
      10: 20,
    });
    _put(sheet, 0, 0, TextCellValue('HUTANG & PIUTANG'), _titleStyle());
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: headers.length - 1, rowIndex: 0),
    );
    _put(
      sheet,
      0,
      1,
      TextCellValue('Ringkasan kewajiban dan tagihan dengan informasi kontak.'),
      _subtitleStyle(),
    );
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      CellIndex.indexByColumnRow(columnIndex: headers.length - 1, rowIndex: 1),
    );
    for (var col = 0; col < headers.length; col++) {
      _put(sheet, col, 3, TextCellValue(headers[col]), _headerStyle());
    }
    var row = 4;
    for (var index = 0; index < debts.length; index++) {
      final entry = debts[index];
      final style = entry.isSettled ? _settledBodyStyle() : _bodyStyle();
      final values = <CellValue>[
        IntCellValue(index + 1),
        TextCellValue(entry.person),
        TextCellValue(
          entry.kind == DebtKind.payable ? 'Saya berhutang' : 'Dipinjam orang',
        ),
        TextCellValue(entry.isSettled ? 'Lunas' : 'Aktif'),
        DoubleCellValue(entry.amount),
        DateCellValue.fromDateTime(entry.date),
        entry.dueDate == null
            ? TextCellValue('')
            : DateCellValue.fromDateTime(entry.dueDate!),
        TextCellValue(entry.contactPhone ?? ''),
        TextCellValue(entry.note),
        TextCellValue(entry.imagePath == null ? 'Tidak' : 'Ya'),
        DateTimeCellValue.fromDateTime(entry.createdAt),
      ];
      for (var col = 0; col < values.length; col++) {
        _put(
          sheet,
          col,
          row,
          values[col],
          col == 4
              ? _currencyStyle(entry.isSettled)
              : (col == 5 || col == 6 ? _dateStyle(entry.isSettled) : style),
        );
      }
      row++;
    }
    if (row == 4)
      _put(
        sheet,
        0,
        4,
        TextCellValue('Belum ada catatan hutang atau piutang.'),
        _bodyStyle(),
      );
  }

  void _writeTransactionRow(
    Sheet sheet,
    int row,
    int number,
    String type,
    String status,
    String direction,
    String name,
    String category,
    double amount,
    DateTime date,
    DateTime? dueDate,
    String phone,
    String contactId,
    String note,
    bool hasPhoto,
    DateTime createdAt,
  ) {
    final values = <CellValue>[
      IntCellValue(number),
      TextCellValue(type),
      TextCellValue(status),
      TextCellValue(direction),
      TextCellValue(name),
      TextCellValue(category),
      DoubleCellValue(amount),
      DateCellValue.fromDateTime(date),
      dueDate == null ? TextCellValue('') : DateCellValue.fromDateTime(dueDate),
      TextCellValue(phone),
      TextCellValue(note),
      TextCellValue(hasPhoto ? 'Ya' : 'Tidak'),
      DateTimeCellValue.fromDateTime(createdAt),
    ];
    for (var col = 0; col < values.length; col++) {
      final style = col == 6
          ? _currencyStyle(false)
          : (col == 7 || col == 8 ? _dateStyle(false) : _bodyStyle());
      _put(sheet, col, row, values[col], style);
    }
  }

  void _put(
    Sheet sheet,
    int column,
    int row,
    CellValue value,
    CellStyle style,
  ) {
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row),
      value,
      cellStyle: style,
    );
  }

  void _setWidths(Sheet sheet, Map<int, double> widths) {
    for (final entry in widths.entries) {
      sheet.setColumnWidth(entry.key, entry.value);
    }
  }

  void _hideGrid(Sheet sheet) {
    // excel_plus 0.0.3 does not expose a gridline toggle; the workbook remains clean through styling and spacing.
  }

  CellStyle _titleStyle() => CellStyle(
    fontFamily: 'Aptos Display',
    fontSize: 20,
    bold: true,
    fontColorHex: ExcelColor.fromHexString('#1F3A5F'),
    verticalAlign: VerticalAlign.Center,
  );
  CellStyle _subtitleStyle() => CellStyle(
    fontFamily: 'Aptos',
    fontSize: 11,
    italic: true,
    fontColorHex: ExcelColor.fromHexString('#637083'),
    verticalAlign: VerticalAlign.Center,
  );
  CellStyle _sectionStyle() => CellStyle(
    fontFamily: 'Aptos Display',
    fontSize: 13,
    bold: true,
    fontColorHex: ExcelColor.fromHexString('#1F3A5F'),
    backgroundColorHex: ExcelColor.fromHexString('#E7EEF6'),
    verticalAlign: VerticalAlign.Center,
    bottomBorder: Border(
      borderStyle: BorderStyle.Medium,
      borderColorHex: ExcelColor.fromHexString('#1F3A5F'),
    ),
  );
  CellStyle _headerStyle() => CellStyle(
    fontFamily: 'Aptos',
    fontSize: 10,
    bold: true,
    fontColorHex: ExcelColor.white,
    backgroundColorHex: ExcelColor.fromHexString('#1F3A5F'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
    bottomBorder: Border(
      borderStyle: BorderStyle.Medium,
      borderColorHex: ExcelColor.fromHexString('#14283F'),
    ),
  );
  CellStyle _metricLabelStyle() => CellStyle(
    fontFamily: 'Aptos',
    fontSize: 10,
    bold: true,
    fontColorHex: ExcelColor.fromHexString('#526173'),
    backgroundColorHex: ExcelColor.fromHexString('#F4F7FA'),
    verticalAlign: VerticalAlign.Center,
  );
  CellStyle _metricValueStyle(bool currency) => CellStyle(
    fontFamily: 'Aptos Display',
    fontSize: 16,
    bold: true,
    fontColorHex: ExcelColor.fromHexString('#1F3A5F'),
    backgroundColorHex: ExcelColor.fromHexString('#F4F7FA'),
    verticalAlign: VerticalAlign.Center,
    numberFormat: currency
        ? NumFormat.custom(formatCode: '#,##0')
        : NumFormat.standard_3,
  );
  CellStyle _bodyStyle() => CellStyle(
    fontFamily: 'Aptos',
    fontSize: 10,
    fontColorHex: ExcelColor.fromHexString('#253246'),
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
    bottomBorder: Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString('#D8E0E8'),
    ),
  );
  CellStyle _settledBodyStyle() => CellStyle(
    fontFamily: 'Aptos',
    fontSize: 10,
    italic: true,
    fontColorHex: ExcelColor.fromHexString('#7B8794'),
    backgroundColorHex: ExcelColor.fromHexString('#F1F6F2'),
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
    bottomBorder: Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString('#D8E0E8'),
    ),
  );
  CellStyle _currencyStyle(bool settled) => CellStyle(
    fontFamily: 'Aptos',
    fontSize: 10,
    bold: true,
    fontColorHex: ExcelColor.fromHexString(settled ? '#7B8794' : '#1F3A5F'),
    backgroundColorHex: settled
        ? ExcelColor.fromHexString('#F1F6F2')
        : ExcelColor.none,
    horizontalAlign: HorizontalAlign.Right,
    verticalAlign: VerticalAlign.Center,
    numberFormat: NumFormat.custom(formatCode: '#,##0'),
    bottomBorder: Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString('#D8E0E8'),
    ),
  );
  CellStyle _dateStyle(bool settled) => CellStyle(
    fontFamily: 'Aptos',
    fontSize: 10,
    fontColorHex: ExcelColor.fromHexString(settled ? '#7B8794' : '#253246'),
    backgroundColorHex: settled
        ? ExcelColor.fromHexString('#F1F6F2')
        : ExcelColor.none,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    numberFormat: NumFormat.custom(formatCode: 'dd-mmm-yyyy'),
    bottomBorder: Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString('#D8E0E8'),
    ),
  );
  CellStyle _dateTimeStyle() => CellStyle(
    fontFamily: 'Aptos',
    fontSize: 10,
    fontColorHex: ExcelColor.fromHexString('#253246'),
    horizontalAlign: HorizontalAlign.Left,
    verticalAlign: VerticalAlign.Center,
    numberFormat: NumFormat.custom(formatCode: 'dd-mmm-yyyy hh:mm'),
  );
  CellStyle _noteStyle() => CellStyle(
    fontFamily: 'Aptos',
    fontSize: 9,
    italic: true,
    fontColorHex: ExcelColor.fromHexString('#637083'),
    backgroundColorHex: ExcelColor.fromHexString('#F8FAFC'),
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
  );
  CellStyle _linkStyle() => CellStyle(
    fontFamily: 'Aptos',
    fontSize: 10,
    bold: true,
    fontColorHex: ExcelColor.fromHexString('#2F6FAD'),
    verticalAlign: VerticalAlign.Center,
  );

  Future<Map<String, dynamic>> _restorePhoto(
    Map<String, dynamic> original,
    Archive archive,
    Directory target,
  ) async {
    final json = Map<String, dynamic>.from(original);
    final backupPhoto = json['backupPhoto'] as String?;
    if (backupPhoto == null || backupPhoto.isEmpty) {
      json['imagePath'] = null;
      return json;
    }
    if (!_integrity.isSafeRelativePath(backupPhoto)) {
      throw const FormatException('Restore ditolak: path lampiran tidak aman.');
    }
    final archiveFile = archive.files
        .where((file) => file.name == backupPhoto && file.isFile)
        .firstOrNull;
    if (archiveFile == null) {
      throw const FormatException(
        'Restore ditolak: lampiran tidak ditemukan atau telah dihapus.',
      );
    }
    final extension = backupPhoto.contains('.')
        ? backupPhoto.split('.').last.toLowerCase()
        : 'jpg';
    final safeExtension = RegExp(r'^[a-z0-9]{1,8}$').hasMatch(extension)
        ? extension
        : 'jpg';
    final targetFile = File(
      '${target.path}/restored_${DateTime.now().microsecondsSinceEpoch}.$safeExtension',
    );
    await targetFile.writeAsBytes(_integrity.bytes(archiveFile), flush: true);
    json['imagePath'] = targetFile.path;
    return json;
  }

  String _categoryLabel(ExpenseCategory category) => switch (category) {
    ExpenseCategory.food => 'Makanan',
    ExpenseCategory.transport => 'Transportasi',
    ExpenseCategory.bills => 'Tagihan',
    ExpenseCategory.shopping => 'Belanja',
    ExpenseCategory.health => 'Kesehatan',
    ExpenseCategory.entertainment => 'Hiburan',
    ExpenseCategory.other => 'Lainnya',
  };
  String _stamp(DateTime date) =>
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}_${date.hour.toString().padLeft(2, '0')}${date.minute.toString().padLeft(2, '0')}';
}
