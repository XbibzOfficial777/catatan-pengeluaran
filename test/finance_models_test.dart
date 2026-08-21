import 'package:flutter_test/flutter_test.dart';

import 'package:catatan_pengeluaran/models/finance_models.dart';

void main() {
  group('ExpenseEntry', () {
    test('toJson → fromJson roundtrip mempertahankan data', () {
      final entry = ExpenseEntry(
        id: 'e1',
        title: 'Makan siang',
        amount: 25000,
        category: ExpenseCategory.food,
        date: DateTime(2026, 8, 19, 10, 30),
        note: 'warung depan',
        imagePath: '/tmp/a.jpg',
        accountId: 'acc1',
        recurringId: 'rec1',
        isSettled: false,
        createdAt: DateTime(2026, 8, 19, 10, 31),
      );
      final restored = ExpenseEntry.fromJson(entry.toJson());
      expect(restored.id, entry.id);
      expect(restored.title, entry.title);
      expect(restored.amount, entry.amount);
      expect(restored.category, entry.category);
      expect(restored.date, entry.date);
      expect(restored.note, entry.note);
      expect(restored.imagePath, entry.imagePath);
      expect(restored.accountId, entry.accountId);
      expect(restored.recurringId, entry.recurringId);
      expect(restored.isSettled, entry.isSettled);
      expect(restored.createdAt, entry.createdAt);
    });

    test('fromJson tanpa id menghasilkan fallback id deterministik', () {
      final json = {
        'title': 'Kopi',
        'amount': 18000,
        'category': 'food',
        'date': '2026-08-01T08:00:00.000',
        'note': '',
        'createdAt': '2026-08-01T08:05:00.000',
      };
      final first = ExpenseEntry.fromJson(json);
      final second = ExpenseEntry.fromJson(json);
      expect(first.id, isNotEmpty);
      expect(first.id, second.id,
          reason: 'ID fallback harus stabil agar merge restore tidak menduplikasi entry');
      final other = ExpenseEntry.fromJson({...json, 'title': 'Teh'});
      expect(other.id, isNot(first.id));
    });

    test('fromJson dengan id terisi tetap memakai id tersebut', () {
      final entry = ExpenseEntry.fromJson({
        'id': 'asli',
        'title': 'X',
        'amount': 1,
        'date': '2026-08-01T00:00:00.000',
        'createdAt': '2026-08-01T00:00:00.000',
      });
      expect(entry.id, 'asli');
    });

    test('categoryLabel konsisten untuk semua kategori', () {
      final expected = {
        ExpenseCategory.food: 'Makanan',
        ExpenseCategory.transport: 'Transportasi',
        ExpenseCategory.shopping: 'Belanja',
        ExpenseCategory.bills: 'Tagihan',
        ExpenseCategory.health: 'Kesehatan',
        ExpenseCategory.entertainment: 'Hiburan',
        ExpenseCategory.other: 'Lainnya',
      };
      expected.forEach((category, label) {
        expect(categoryLabel(category), label);
      });
    });
  });

  group('DebtEntry', () {
    test('toJson → fromJson roundtrip mempertahankan data', () {
      final entry = DebtEntry(
        id: 'd1',
        person: 'Budi',
        amount: 150000,
        kind: DebtKind.receivable,
        date: DateTime(2026, 8, 2),
        dueDate: DateTime(2026, 9, 2),
        note: 'buat bayar kos',
        imagePath: null,
        contactId: 'c1',
        contactPhone: '+6281234567890',
        isSettled: true,
        createdAt: DateTime(2026, 8, 2, 9),
      );
      final restored = DebtEntry.fromJson(entry.toJson());
      expect(restored.id, entry.id);
      expect(restored.person, entry.person);
      expect(restored.amount, entry.amount);
      expect(restored.kind, entry.kind);
      expect(restored.dueDate, entry.dueDate);
      expect(restored.note, entry.note);
      expect(restored.contactId, entry.contactId);
      expect(restored.contactPhone, entry.contactPhone);
      expect(restored.isSettled, entry.isSettled);
    });

    test('fromJson tanpa id tidak crash dan fallback id stabil', () {
      final json = {
        'person': 'Sari',
        'amount': 50000,
        'kind': 'payable',
        'date': '2026-08-05T00:00:00.000',
        'createdAt': '2026-08-05T00:00:00.000',
      };
      final first = DebtEntry.fromJson(json);
      final second = DebtEntry.fromJson(json);
      expect(first.id, second.id);
      expect(first.id, startsWith('debt_recovered_'));
    });
  });
}
