import 'package:flutter_test/flutter_test.dart';

import '../lib/models/advanced_finance_models.dart';
import '../lib/models/finance_models.dart';
import '../lib/services/category_rules_service.dart';
import '../lib/services/finance_feature_service.dart';

void main() {
  final baseDate = DateTime(2026, 1, 10);

  ExpenseEntry expense({
    required String id,
    required String title,
    required double amount,
    required DateTime date,
    String merchant = '',
    ExpenseCategory category = ExpenseCategory.other,
    bool isBusiness = false,
    bool taxDeductible = false,
    double taxAmount = 0,
  }) => ExpenseEntry(
    id: id,
    title: title,
    amount: amount,
    category: category,
    date: date,
    merchantName: merchant,
    isBusiness: isBusiness,
    taxDeductible: taxDeductible,
    taxAmount: taxAmount,
    createdAt: date,
  );

  test('category rules prefer custom merchant rule', () {
    final rule = MerchantCategoryRule(
      id: 'r1',
      pattern: 'kantin kantor',
      category: ExpenseCategory.shopping,
      createdAt: baseDate,
    );
    expect(
      CategoryRulesService.suggest(
        title: 'Makan siang',
        merchant: 'Kantin Kantor',
        rules: [rule],
      ),
      ExpenseCategory.shopping,
    );
    expect(
      CategoryRulesService.suggest(title: 'Bayar PLN'),
      ExpenseCategory.bills,
    );
  });

  test('recurring detection finds monthly-like patterns', () {
    final entries = [
      expense(
        id: 'a',
        title: 'Internet',
        amount: 250000,
        date: DateTime(2025, 11, 10),
        merchant: 'ISP',
      ),
      expense(
        id: 'b',
        title: 'Internet',
        amount: 250000,
        date: DateTime(2025, 12, 10),
        merchant: 'ISP',
      ),
      expense(
        id: 'c',
        title: 'Internet',
        amount: 250000,
        date: DateTime(2026, 1, 10),
        merchant: 'ISP',
      ),
    ];
    final candidates = FinanceFeatureService.detectRecurring(
      entries,
      now: baseDate,
    );
    expect(candidates, hasLength(1));
    expect(candidates.single.occurrences, 3);
  });

  test('safe daily budget never returns negative', () {
    expect(
      FinanceFeatureService.safeDailyBudget(
        monthlyLimit: 100000,
        monthToDateSpend: 120000,
        now: DateTime(2026, 1, 10),
      ),
      0,
    );
    expect(
      FinanceFeatureService.safeDailyBudget(
        monthlyLimit: 310000,
        monthToDateSpend: 0,
        now: DateTime(2026, 1, 1),
      ),
      10000,
    );
  });

  test('business and deductible summaries use explicit flags', () {
    final entries = [
      expense(
        id: 'a',
        title: 'Office',
        amount: 100000,
        date: baseDate,
        isBusiness: true,
        taxDeductible: true,
        taxAmount: 11000,
      ),
      expense(id: 'b', title: 'Lunch', amount: 50000, date: baseDate),
    ];
    expect(FinanceFeatureService.businessSpend(entries), 100000);
    expect(FinanceFeatureService.deductibleTax(entries), 11000);
  });

  test('split bill balances after equal allocation', () {
    final bill = SplitBill(
      id: 'b1',
      title: 'Makan bersama',
      totalAmount: 100000,
      date: baseDate,
      participants: [
        const SplitParticipant(id: '1', name: 'A', amount: 50000),
        const SplitParticipant(id: '2', name: 'B', amount: 50000),
      ],
      createdAt: baseDate,
    );
    expect(bill.isBalanced, isTrue);
    expect(bill.remainingAmount, 0);
  });

  test('old ExpenseEntry JSON remains readable with new fields absent', () {
    final entry = ExpenseEntry.fromJson({
      'id': 'legacy',
      'title': 'Makan',
      'amount': 15000,
      'category': 'food',
      'date': baseDate.toIso8601String(),
      'createdAt': baseDate.toIso8601String(),
    });
    expect(entry.merchantName, isEmpty);
    expect(entry.isBusiness, isFalse);
    expect(entry.taxAmount, 0);
  });
}
