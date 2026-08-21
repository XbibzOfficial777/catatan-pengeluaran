import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/finance_models.dart';
import '../models/advanced_finance_models.dart';

/// Laporan korupsi data lokal hasil pembacaan storage.
///
/// [FinanceStorage] tidak pernah membuang data rusak secara diam-diam:
/// salinan mentah dipindahkan ke kunci karantina `<key>_corrupt` supaya tetap
/// bisa diperiksa atau dipulihkan manual, dan pemanggil dapat memeriksa
/// laporan ini sebelum menimpa data lewat penyimpanan baru.
class StorageCorruptionReport {
  StorageCorruptionReport._({
    required Set<String> unreadable,
    required Set<String> partial,
  }) : _unreadable = unreadable,
       _partial = partial;

  final Set<String> _unreadable;
  final Set<String> _partial;

  /// Kunci yang datanya benar-benar tidak bisa dibaca (JSON rusak total).
  /// Menyimpan data baru pada kunci ini akan mengganti isi lama, jadi UI
  /// harus memperingatkan pengguna dan menahan auto-save.
  bool get hasUnreadableData => _unreadable.isNotEmpty;

  /// Kunci yang sebagian entry-nya rusak tapi sebagian lain berhasil dibaca.
  bool get hasPartialDamage => _partial.isNotEmpty;

  bool get isEmpty => _unreadable.isEmpty && _partial.isEmpty;

  List<String> get quarantinedKeys =>
      List.unmodifiable({..._unreadable, ..._partial});
}

/// Pelacak korupsi storage yang dipakai bersama oleh beberapa storage service.
///
/// Diimplementasikan sebagai kelas (bukan mixin) karena field privat hanya
/// terlihat di library yang sama; lewat komposisi, semua akses status lewat
/// metode publik yang jelas.
class StorageCorruptionTracker {
  final Set<String> _unreadableKeys = <String>{};
  final Set<String> _partiallyCorruptKeys = <String>{};

  void markUnreadable(String key) => _unreadableKeys.add(key);

  void markPartial(String key) => _partiallyCorruptKeys.add(key);

  /// Mengambil laporan korupsi sejak panggilan terakhir dan mereset penandanya.
  StorageCorruptionReport consumeCorruptionReport() {
    final report = StorageCorruptionReport._(
      unreadable: Set.of(_unreadableKeys),
      partial: Set.of(_partiallyCorruptKeys),
    );
    _unreadableKeys.clear();
    _partiallyCorruptKeys.clear();
    return report;
  }

  /// Menyimpan salinan mentah data rusak ke kunci karantina.
  ///
  /// Karantina hanya ditulis bila isinya berubah supaya pemeriksaan berulang
  /// tidak menimpa bukti dengan salinan yang sama persis.
  Future<void> quarantineRaw(
    SharedPreferences preferences,
    String key,
    String raw,
  ) async {
    try {
      final quarantineKey = '${key}_corrupt';
      if (preferences.getString(quarantineKey) != raw) {
        await preferences.setString(quarantineKey, raw);
      }
    } catch (_) {
      // Karantina bersifat best-effort; kegagalan menulis tidak boleh
      // menghentikan proses pemuatan data.
    }
  }
}

class FinanceStorage {
  final StorageCorruptionTracker _corruption = StorageCorruptionTracker();
  Future<void> _writeQueue = Future<void>.value();

  /// Tulisan diserialisasi (queue) agar dua save bersamaan tidak saling
  /// menimpa — pengerasan dari branch main.
  Future<void> _enqueueWrite(Future<void> Function() action) {
    final next = _writeQueue.then((_) => action());
    _writeQueue = next.catchError((_) {});
    return next;
  }

  /// Laporan korupsi data sejak pembacaan terakhir.
  StorageCorruptionReport consumeCorruptionReport() =>
      _corruption.consumeCorruptionReport();

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
  static const _onboardingKey = 'onboarding_completed_v1';
  static const _lastSeenVersionKey = 'last_seen_app_version_v1';

  Future<String> loadLanguage() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_languageKey) ?? 'id';
  }

  Future<void> saveLanguage(String languageCode) => _enqueueWrite(() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_languageKey, languageCode);
  });

  Future<bool> loadOnboardingCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_onboardingKey) ?? false;
  }

  Future<void> saveOnboardingCompleted() => _enqueueWrite(() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_onboardingKey, true);
  });

  Future<String?> loadLastSeenAppVersion() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_lastSeenVersionKey);
  }

  Future<void> saveLastSeenAppVersion(String version) =>
      _enqueueWrite(() async {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setString(_lastSeenVersionKey, version);
      });

  Future<List<ExpenseEntry>> loadExpenses() async {
    final preferences = await SharedPreferences.getInstance();
    return _decodeList(preferences, _expenseKey, ExpenseEntry.fromJson);
  }

  Future<List<DebtEntry>> loadDebts() async {
    final preferences = await SharedPreferences.getInstance();
    return _decodeList(preferences, _debtKey, DebtEntry.fromJson);
  }

  Future<void> saveExpenses(List<ExpenseEntry> entries) =>
      _enqueueWrite(() async {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setString(
          _expenseKey,
          jsonEncode(entries.map((entry) => entry.toJson()).toList()),
        );
      });

  Future<void> saveDebts(List<DebtEntry> entries) => _enqueueWrite(() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _debtKey,
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  });

  Future<double> loadPocketMoney() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getDouble(_pocketMoneyKey) ?? 0;
  }

  Future<void> savePocketMoney(double amount) => _enqueueWrite(() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(_pocketMoneyKey, amount);
  });

  Future<String?> loadThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_themeKey);
  }

  Future<List<MoneyAccount>> loadAccounts() async {
    final preferences = await SharedPreferences.getInstance();
    return _decodeList(preferences, _accountsKey, MoneyAccount.fromJson);
  }

  Future<void> saveAccounts(List<MoneyAccount> entries) =>
      _enqueueWrite(() async {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setString(
          _accountsKey,
          jsonEncode(entries.map((entry) => entry.toJson()).toList()),
        );
      });

  Future<List<BudgetLimit>> loadBudgets() async {
    final preferences = await SharedPreferences.getInstance();
    return _decodeList(preferences, _budgetsKey, BudgetLimit.fromJson);
  }

  Future<void> saveBudgets(List<BudgetLimit> entries) =>
      _enqueueWrite(() async {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setString(
          _budgetsKey,
          jsonEncode(entries.map((entry) => entry.toJson()).toList()),
        );
      });

  Future<List<RecurringExpense>> loadRecurringExpenses() async {
    final preferences = await SharedPreferences.getInstance();
    return _decodeList(preferences, _recurringKey, RecurringExpense.fromJson);
  }

  Future<void> saveRecurringExpenses(List<RecurringExpense> entries) =>
      _enqueueWrite(() async {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setString(
          _recurringKey,
          jsonEncode(entries.map((entry) => entry.toJson()).toList()),
        );
      });

  Future<List<SavingsGoal>> loadSavingsGoals() async {
    final preferences = await SharedPreferences.getInstance();
    return _decodeList(preferences, _savingsKey, SavingsGoal.fromJson);
  }

  Future<void> saveSavingsGoals(List<SavingsGoal> entries) =>
      _enqueueWrite(() async {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setString(
          _savingsKey,
          jsonEncode(entries.map((entry) => entry.toJson()).toList()),
        );
      });

  Future<bool> loadPrivacyMode() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_privacyKey) ?? false;
  }

  Future<void> savePrivacyMode(bool enabled) => _enqueueWrite(() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_privacyKey, enabled);
  });

  Future<void> saveThemeMode(String mode) => _enqueueWrite(() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeKey, mode);
  });

  /// Membaca list JSON dari [key].
  ///
  /// - JSON rusak total → salinan mentah dikarantina, dilaporkan sebagai
  ///   unreadable, dan dikembalikan sebagai list kosong. Pemanggil bertanggung
  ///   jawab menahan auto-save agar tidak menimpa karantina.
  /// - Entry individual yang rusak → dilewati, salinan mentah tetap
  ///   dikarantina, dan dilaporkan sebagai partial supaya UI bisa memberi tahu.
  Future<List<T>> _decodeList<T>(
    SharedPreferences preferences,
    String key,
    T Function(Map<String, dynamic>) factory,
  ) async {
    final raw = preferences.getString(key);
    if (raw == null || raw.isEmpty) return <T>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const FormatException('Nilai storage bukan list JSON.');
      }
      var damagedEntries = 0;
      final results = <T>[];
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) {
          damagedEntries++;
          continue;
        }
        try {
          results.add(factory(item));
        } catch (_) {
          damagedEntries++;
        }
      }
      if (damagedEntries > 0) {
        _corruption.markPartial(key);
        await _corruption.quarantineRaw(preferences, key, raw);
      }
      return results;
    } catch (_) {
      _corruption.markUnreadable(key);
      await _corruption.quarantineRaw(preferences, key, raw);
      return <T>[];
    }
  }
}
