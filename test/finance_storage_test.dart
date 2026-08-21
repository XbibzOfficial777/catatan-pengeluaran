import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:catatan_pengeluaran/models/finance_models.dart';
import 'package:catatan_pengeluaran/services/finance_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FinanceStorage karantina data rusak', () {
    test('JSON rusak total → list kosong + karantina + laporan unreadable', () async {
      SharedPreferences.setMockInitialValues({
        'expense_entries_v1': '{bukan-json-valid',
      });
      final storage = FinanceStorage();
      final expenses = await storage.loadExpenses();
      expect(expenses, isEmpty);

      final report = storage.consumeCorruptionReport();
      expect(report.hasUnreadableData, isTrue,
          reason: 'UI harus tahu data rusak total agar menahan auto-save');
      expect(report.quarantinedKeys, contains('expense_entries_v1'));

      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString('expense_entries_v1_corrupt'),
        '{bukan-json-valid',
        reason: 'Salinan mentah wajib tersimpan supaya bisa dipulihkan manual',
      );
    });

    test('Sebagian entry rusak → entry sehat tetap dimuat + laporan partial', () async {
      final raw = jsonEncode([
        {
          'id': 'ok1',
          'title': 'Valid',
          'amount': 1000,
          'category': 'food',
          'date': '2026-08-01T00:00:00.000',
          'createdAt': '2026-08-01T00:00:00.000',
        },
        'bukan-map',
      ]);
      SharedPreferences.setMockInitialValues({
        'expense_entries_v1': raw,
      });
      final storage = FinanceStorage();
      final expenses = await storage.loadExpenses();
      expect(expenses.length, 1);
      expect(expenses.first.id, 'ok1');

      final report = storage.consumeCorruptionReport();
      expect(report.hasUnreadableData, isFalse);
      expect(report.hasPartialDamage, isTrue);
    });

    test('Laporan dikonsumsi sekali lalu reset', () async {
      SharedPreferences.setMockInitialValues({
        'debt_entries_v1': 'rusak-total',
      });
      final storage = FinanceStorage();
      await storage.loadDebts();
      expect(storage.consumeCorruptionReport().hasUnreadableData, isTrue);
      expect(storage.consumeCorruptionReport().isEmpty, isTrue,
          reason: 'Konsumsi kedua tidak boleh melaporkan ulang');
    });

    test('Save & load normal tetap berfungsi tanpa laporan', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = FinanceStorage();
      final entry = ExpenseEntry(
        id: 'x1',
        title: 'Bensin',
        amount: 20000,
        category: ExpenseCategory.transport,
        date: DateTime(2026, 8, 10),
        createdAt: DateTime(2026, 8, 10),
      );
      await storage.saveExpenses([entry]);
      final loaded = await storage.loadExpenses();
      expect(loaded.length, 1);
      expect(loaded.first.title, 'Bensin');
      expect(storage.consumeCorruptionReport().isEmpty, isTrue);
    });
  });
}
