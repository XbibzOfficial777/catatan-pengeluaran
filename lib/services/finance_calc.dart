import '../models/advanced_finance_models.dart';
import '../models/json_helpers.dart';
import '../models/finance_models.dart';
import '../models/reminder_models.dart';

/// Perhitungan keuangan murni (tanpa Flutter/UI) yang sebelumnya menempel
/// pada state halaman utama. Dipisah agar bisa diuji unit-test dan nantinya
/// mudah diangkat ke controller/state-management tersendiri.
class FinanceCalc {
  /// Total pengeluaran, sisa uang saku, hutang, dan piutang aktif.
  static FinanceTotals totals({
    required List<ExpenseEntry> expenses,
    required List<DebtEntry> debts,
    required double pocketMoney,
  }) {
    final totalExpense = roundMoney(
      expenses.fold<double>(0, (sum, item) => sum + item.amount),
    );
    final pocketMoneyExpense = roundMoney(
      expenses
          .where((item) => item.accountId == null)
          .fold<double>(0, (sum, item) => sum + item.amount),
    );
    final payable = roundMoney(
      debts
          .where((item) => item.kind == DebtKind.payable && !item.isSettled)
          .fold<double>(0, (sum, item) => sum + item.amount),
    );
    final receivable = roundMoney(
      debts
          .where((item) => item.kind == DebtKind.receivable && !item.isSettled)
          .fold<double>(0, (sum, item) => sum + item.amount),
    );
    return FinanceTotals(
      totalExpense: totalExpense,
      pocketMoneyExpense: pocketMoneyExpense,
      remainingPocketMoney: roundMoney(pocketMoney - pocketMoneyExpense),
      payable: payable,
      receivable: receivable,
    );
  }

  /// Gabungkan akun dengan nama yang sama (dinormalisasi) dan kembalikan
  /// peta pengganti ID supaya pengeluaran/pengeluaran berulang tetap menunjuk
  /// akun yang bertahan.
  static List<MoneyAccount> deduplicateAccounts(
    Iterable<MoneyAccount> accounts, {
    Map<String, String>? idMap,
  }) {
    final canonical = <String, MoneyAccount>{};
    for (final account in accounts) {
      final key = normalizeMoneyAccountName(account.name);
      final existing = canonical[key];
      if (existing == null) {
        canonical[key] = account;
        idMap?[account.id] = account.id;
      } else {
        idMap?[account.id] = existing.id;
      }
    }
    return canonical.values.toList();
  }

  static List<ExpenseEntry> remapExpenseAccounts(
    Iterable<ExpenseEntry> expenses,
    Map<String, String> idMap,
  ) => expenses
      .map(
        (entry) => entry.accountId != null && idMap[entry.accountId] != null
            ? entry.copyWith(accountId: idMap[entry.accountId])
            : entry,
      )
      .toList();

  static List<RecurringExpense> remapRecurringAccounts(
    Iterable<RecurringExpense> items,
    Map<String, String> idMap,
  ) => items
      .map(
        (item) => item.accountId != null && idMap[item.accountId] != null
            ? item.copyWith(accountId: idMap[item.accountId])
            : item,
      )
      .toList();

  /// Semua jadwal pengingat: pengingat manual + pengingat tujuan tabungan.
  static List<ReminderSchedule> allReminderSchedules(
    List<ReminderSchedule> reminders,
    List<SavingsGoal> savings,
  ) => [
    ...reminders,
    ...savings.where((goal) => goal.reminderEnabled).map(
      (goal) => ReminderSchedule(
        id: stableReminderId(goal.id),
        title: 'Waktu menabung: ${goal.name}',
        body: 'Sisihkan sedikit untuk mencapai target ${goal.name}.',
        hour: goal.reminderHour,
        minute: goal.reminderMinute,
        frequency: ReminderFrequency.daily,
        weekdays: const <int>[],
      ),
    ),
  ];

  /// ID notifikasi stabil dari ID tujuan tabungan (hindari tabrakan dengan
  /// ID pengingat manual).
  static int stableReminderId(String id) {
    var hash = 0;
    for (final code in id.codeUnits) {
      hash = (hash * 31 + code) & 0x1fffffff;
    }
    return 700000000 + hash;
  }
}

class FinanceTotals {
  const FinanceTotals({
    required this.totalExpense,
    required this.pocketMoneyExpense,
    required this.remainingPocketMoney,
    required this.payable,
    required this.receivable,
  });

  final double totalExpense;
  final double pocketMoneyExpense;
  final double remainingPocketMoney;
  final double payable;
  final double receivable;
}
