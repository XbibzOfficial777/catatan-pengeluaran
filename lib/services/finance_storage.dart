import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/finance_models.dart';
import '../models/advanced_finance_models.dart';

class FinanceStorage {
  static const _expenseKey = 'expense_entries_v1';
  static const _debtKey = 'debt_entries_v1';
  static const _themeKey = 'theme_mode_v1';
  static const _languageKey = 'app_language_v1';
  static const _pocketMoneyKey = 'pocket_money_v1';
  static const _accountsKey = 'money_accounts_v1';
  static const _budgetsKey = 'budget_limits_v1';
  static const _recurringKey = 'recurring_expenses_v1';
  static const _privacyKey = 'privacy_mode_v1';
  static const _savingsKey = 'savings_goals_v1';

  Future<String> loadLanguage() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_languageKey) ?? 'id';
  }

  Future<void> saveLanguage(String languageCode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_languageKey, languageCode);
  }

  Future<List<ExpenseEntry>> loadExpenses() async {
    final preferences = await SharedPreferences.getInstance();
    return _decodeList(
      preferences.getString(_expenseKey),
      ExpenseEntry.fromJson,
    );
  }

  Future<List<DebtEntry>> loadDebts() async {
    final preferences = await SharedPreferences.getInstance();
    return _decodeList(preferences.getString(_debtKey), DebtEntry.fromJson);
  }

  Future<void> saveExpenses(List<ExpenseEntry> entries) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _expenseKey,
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<void> saveDebts(List<DebtEntry> entries) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _debtKey,
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<double> loadPocketMoney() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getDouble(_pocketMoneyKey) ?? 0;
  }

  Future<void> savePocketMoney(double amount) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(_pocketMoneyKey, amount);
  }

  Future<String?> loadThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_themeKey);
  }

  Future<List<MoneyAccount>> loadAccounts() async {
    final preferences = await SharedPreferences.getInstance();
    return _decodeList(
      preferences.getString(_accountsKey),
      MoneyAccount.fromJson,
    );
  }

  Future<void> saveAccounts(List<MoneyAccount> entries) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _accountsKey,
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<List<BudgetLimit>> loadBudgets() async {
    final preferences = await SharedPreferences.getInstance();
    return _decodeList(
      preferences.getString(_budgetsKey),
      BudgetLimit.fromJson,
    );
  }

  Future<void> saveBudgets(List<BudgetLimit> entries) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _budgetsKey,
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<List<RecurringExpense>> loadRecurringExpenses() async {
    final preferences = await SharedPreferences.getInstance();
    return _decodeList(
      preferences.getString(_recurringKey),
      RecurringExpense.fromJson,
    );
  }

  Future<void> saveRecurringExpenses(List<RecurringExpense> entries) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _recurringKey,
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<List<SavingsGoal>> loadSavingsGoals() async {
    final preferences = await SharedPreferences.getInstance();
    return _decodeList(
      preferences.getString(_savingsKey),
      SavingsGoal.fromJson,
    );
  }

  Future<void> saveSavingsGoals(List<SavingsGoal> entries) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _savingsKey,
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<bool> loadPrivacyMode() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_privacyKey) ?? false;
  }

  Future<void> savePrivacyMode(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_privacyKey, enabled);
  }

  Future<void> saveThemeMode(String mode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeKey, mode);
  }

  List<T> _decodeList<T>(
    String? raw,
    T Function(Map<String, dynamic>) factory,
  ) {
    if (raw == null || raw.isEmpty) return <T>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.whereType<Map<String, dynamic>>().map(factory).toList();
    } catch (_) {
      return <T>[];
    }
  }
}
