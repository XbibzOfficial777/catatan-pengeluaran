import 'package:flutter_test/flutter_test.dart';

import 'package:catatan_pengeluaran/models/advanced_finance_models.dart';
import 'package:catatan_pengeluaran/models/finance_models.dart';
import 'package:catatan_pengeluaran/models/reminder_models.dart';
import 'package:catatan_pengeluaran/models/task_item.dart';
import 'package:catatan_pengeluaran/models/json_helpers.dart';

void main() {
  test('expense parsing accepts legacy numeric and invalid fields safely', () {
    final expense = ExpenseEntry.fromJson({
      'id': 42,
      'title': 123,
      'amount': '50000.125',
      'category': 'FOOD',
      'date': 'not-a-date',
      'createdAt': null,
      'isSettled': 'true',
    });

    expect(expense.id, '42');
    expect(expense.title, '123');
    expect(expense.amount, 50000.13);
    expect(expense.category, ExpenseCategory.food);
    expect(expense.date, isA<DateTime>());
    expect(expense.isSettled, isTrue);
  });

  test('unknown debt and account enums fall back without throwing', () {
    final debt = DebtEntry.fromJson({
      'id': 'debt-1',
      'person': 'A',
      'amount': 1000,
      'kind': 'new-kind',
      'date': '2026-01-01',
      'createdAt': '2026-01-01',
    });
    final account = MoneyAccount.fromJson({
      'id': 'account-1',
      'name': 'Cash',
      'type': 'new-account-type',
      'balance': '2500',
      'createdAt': '2026-01-01',
    });

    expect(debt.kind, DebtKind.payable);
    expect(account.type, MoneyAccountType.cash);
    expect(account.balance, 2500);
  });

  test('budget and savings progress stay finite and bounded', () {
    final goal = SavingsGoal(
      id: 'goal',
      name: 'Target',
      targetAmount: 0,
      savedAmount: 100,
      createdAt: DateTime(2026),
    );
    final budget = BudgetLimit.fromJson({
      'id': 'budget',
      'category': 'food',
      'monthlyLimit': '100000',
      'alertPercent': 1000,
      'createdAt': '2026-01-01',
    });

    expect(goal.progress, 0);
    expect(budget.alertPercent, 100);
    expect(clampProgress(double.infinity), 0);
    expect(roundMoney(0.1 + 0.2), 0.3);
  });

  test('reminders and tasks tolerate legacy string values', () {
    final reminder = ReminderSchedule.fromJson({
      'id': '7',
      'title': 99,
      'hour': '25',
      'minute': 'x',
      'frequency': 'unknown',
      'weekdays': ['1', 8, 2],
    });
    final task = TaskItem.fromJson({
      'id': 9,
      'title': null,
      'dueDate': 'invalid',
      'priority': 'unknown',
      'createdAt': 'invalid',
    });

    expect(reminder.id, 7);
    expect(reminder.title, '99');
    expect(reminder.hour, 23);
    expect(reminder.minute, 0);
    expect(reminder.frequency, ReminderFrequency.daily);
    expect(reminder.weekdays, [1, 2]);
    expect(task.id, '9');
    expect(task.priority, TaskPriority.medium);
    expect(task.dueDate, isNull);
  });
}
