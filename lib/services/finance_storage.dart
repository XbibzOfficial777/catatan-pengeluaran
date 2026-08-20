import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/finance_models.dart';

class FinanceStorage {
  static const _expenseKey = 'expense_entries_v1';
  static const _debtKey = 'debt_entries_v1';
  static const _themeKey = 'theme_mode_v1';
  static const _pocketMoneyKey = 'pocket_money_v1';

  Future<List<ExpenseEntry>> loadExpenses() async {
    final preferences = await SharedPreferences.getInstance();
    return _decodeList(preferences.getString(_expenseKey), ExpenseEntry.fromJson);
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

  Future<void> saveThemeMode(String mode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeKey, mode);
  }

  List<T> _decodeList<T>(String? raw, T Function(Map<String, dynamic>) factory) {
    if (raw == null || raw.isEmpty) return <T>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(factory)
          .toList();
    } catch (_) {
      return <T>[];
    }
  }
}
