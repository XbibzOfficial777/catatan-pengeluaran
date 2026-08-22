import 'dart:math' as math;

import '../models/finance_models.dart';

class RecurringCandidate {
  const RecurringCandidate({
    required this.title,
    required this.category,
    required this.amount,
    required this.occurrences,
    required this.lastDate,
    this.merchant = '',
  });

  final String title;
  final ExpenseCategory category;
  final double amount;
  final int occurrences;
  final DateTime lastDate;
  final String merchant;

  int get averageIntervalDays => 30;
}

class FinanceFeatureService {
  static List<RecurringCandidate> detectRecurring(
    List<ExpenseEntry> expenses, {
    DateTime? now,
  }) {
    final groups = <String, List<ExpenseEntry>>{};
    for (final expense in expenses) {
      final key = _key(expense.title, expense.merchantName, expense.amount);
      groups.putIfAbsent(key, () => <ExpenseEntry>[]).add(expense);
    }
    final candidates = <RecurringCandidate>[];
    for (final group in groups.values) {
      if (group.length < 2) continue;
      final sorted = [...group]..sort((a, b) => a.date.compareTo(b.date));
      final intervals = <int>[];
      for (var index = 1; index < sorted.length; index++) {
        intervals.add(
          sorted[index].date.difference(sorted[index - 1].date).inDays,
        );
      }
      final monthlyLike = intervals
          .where((days) => days >= 20 && days <= 45)
          .length;
      if (monthlyLike == 0 && sorted.length < 3) continue;
      final sample = sorted.last;
      candidates.add(
        RecurringCandidate(
          title: sample.title,
          category: sample.category,
          amount: sample.amount,
          occurrences: sorted.length,
          lastDate: sample.date,
          merchant: sample.merchantName,
        ),
      );
    }
    candidates.sort((a, b) => b.occurrences.compareTo(a.occurrences));
    return candidates;
  }

  static double safeDailyBudget({
    required double monthlyLimit,
    required double monthToDateSpend,
    DateTime? now,
  }) {
    final date = now ?? DateTime.now();
    final daysInMonth = DateTime(date.year, date.month + 1, 0).day;
    final remainingDays = math.max(1, daysInMonth - date.day + 1);
    return ((monthlyLimit - monthToDateSpend) / remainingDays)
        .clamp(0, double.infinity)
        .toDouble();
  }

  static double businessSpend(List<ExpenseEntry> expenses) => expenses
      .where((item) => item.isBusiness)
      .fold<double>(0, (sum, item) => sum + item.amount);

  static double deductibleTax(List<ExpenseEntry> expenses) => expenses
      .where((item) => item.taxDeductible)
      .fold<double>(0, (sum, item) => sum + item.taxAmount);

  static String _key(String title, String merchant, double amount) =>
      '${title.trim().toLowerCase()}|${merchant.trim().toLowerCase()}|${amount.toStringAsFixed(2)}';
}
