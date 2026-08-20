import 'dart:math' as math;

import '../models/advanced_finance_models.dart';
import '../models/finance_models.dart';

class BudgetStatus {
  const BudgetStatus({
    required this.limit,
    required this.spent,
    required this.percent,
  });

  final BudgetLimit limit;
  final double spent;
  final double percent;

  bool get isExceeded => spent > limit.monthlyLimit;
  bool get isAlert => !isExceeded && percent >= limit.alertPercent;
  double get remaining => limit.monthlyLimit - spent;
}

class ExpenseInsight {
  const ExpenseInsight({
    required this.entry,
    required this.average,
    required this.ratio,
  });

  final ExpenseEntry entry;
  final double average;
  final double ratio;
}

class AdvancedFinanceService {
  List<BudgetStatus> budgetStatuses({
    required List<BudgetLimit> budgets,
    required List<ExpenseEntry> expenses,
    DateTime? month,
  }) {
    final target = month ?? DateTime.now();
    return budgets.where((budget) => budget.enabled).map((budget) {
      final spent = expenses
          .where(
            (entry) =>
                entry.category == budget.category &&
                entry.date.year == target.year &&
                entry.date.month == target.month,
          )
          .fold(0.0, (sum, entry) => sum + entry.amount);
      final percent = budget.monthlyLimit <= 0
          ? 0.0
          : (spent / budget.monthlyLimit) * 100;
      return BudgetStatus(limit: budget, spent: spent, percent: percent);
    }).toList();
  }

  List<ExpenseInsight> unusualExpenses(List<ExpenseEntry> expenses) {
    if (expenses.length < 4) return const [];
    final byCategory = <ExpenseCategory, List<double>>{};
    for (final entry in expenses) {
      byCategory.putIfAbsent(entry.category, () => []).add(entry.amount);
    }
    final results = <ExpenseInsight>[];
    for (final entry in expenses) {
      final values = byCategory[entry.category] ?? const <double>[];
      if (values.length < 3) continue;
      final average = values.reduce((a, b) => a + b) / values.length;
      final variance =
          values
              .map((value) => math.pow(value - average, 2))
              .reduce((a, b) => a + b) /
          values.length;
      final deviation = math.sqrt(variance);
      final threshold = math.max(average * 2, average + deviation * 2);
      if (entry.amount >= threshold && entry.amount > 50000) {
        results.add(
          ExpenseInsight(
            entry: entry,
            average: average,
            ratio: average == 0 ? 0 : entry.amount / average,
          ),
        );
      }
    }
    results.sort((a, b) => b.ratio.compareTo(a.ratio));
    return results;
  }

  List<ExpenseEntry> materializeDueRecurring({
    required List<RecurringExpense> recurring,
    required DateTime now,
    required List<ExpenseEntry> existing,
  }) {
    final generated = <ExpenseEntry>[];
    for (final item in recurring) {
      var due = item.nextDue;
      while (item.enabled && !due.isAfter(now)) {
        final id =
            '${item.id}_${due.year}${due.month.toString().padLeft(2, '0')}';
        if (!existing.any(
          (entry) =>
              entry.recurringId == item.id &&
              entry.date.year == due.year &&
              entry.date.month == due.month,
        )) {
          generated.add(
            ExpenseEntry(
              id: id,
              title: item.title,
              amount: item.amount,
              category: item.category,
              date: due,
              note: item.note,
              accountId: item.accountId,
              recurringId: item.id,
              createdAt: now,
            ),
          );
        }
        due = _nextMonth(due, item.dayOfMonth);
      }
    }
    return generated;
  }

  DateTime nextDueAfter(DateTime current, int dayOfMonth) =>
      _nextMonth(current, dayOfMonth);

  DateTime _nextMonth(DateTime date, int day) {
    final nextMonth = DateTime(date.year, date.month + 1, 1);
    final lastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
    return DateTime(
      nextMonth.year,
      nextMonth.month,
      math.min(day.clamp(1, 31), lastDay),
    );
  }
}
