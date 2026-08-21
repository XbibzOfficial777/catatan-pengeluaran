import 'dart:async';
import 'dart:io';


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'core/categories.dart';
import 'core/format.dart';
import 'core/palette.dart';
import 'forms/debt_form_sheet.dart';
import 'forms/expense_form_sheet.dart';
import 'models/finance_models.dart';
import 'widgets/calculator_sheet.dart';
import 'widgets/communication_sheet.dart';
import 'widgets/entry_actions.dart';
import 'widgets/finance_tiles.dart';
import 'widgets/form_scaffolding.dart';
import 'services/finance_calc.dart';
import 'services/finance_storage.dart';
import 'services/image_attachment_service.dart';
import 'services/contact_service.dart';
import 'services/backup_service.dart';
import 'services/communication_service.dart';
import 'services/data_transfer_service.dart';
import 'services/reminder_service.dart';
import 'services/image_feed_service.dart';
import 'services/advanced_finance_service.dart';
import 'services/report_service.dart';
import 'services/app_update_service.dart';
import 'models/reminder_models.dart';
import 'models/advanced_finance_models.dart';
import 'widgets/reminder_settings_sheet.dart';
import 'widgets/dashboard_image_rail.dart';
import 'widgets/data_tools_sheet.dart';
import 'widgets/advanced_finance_sheets.dart';
import 'widgets/analytics_sheet.dart';
import 'widgets/expense_filter_dialog.dart';
import 'widgets/savings_sheet.dart';
import 'widgets/app_settings_sheet.dart';

import 'package:share_plus/share_plus.dart';
import 'package:home_widget/home_widget.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CatatanPengeluaranApp());
}

class CatatanPengeluaranApp extends StatefulWidget {
  const CatatanPengeluaranApp({super.key});

  @override
  State<CatatanPengeluaranApp> createState() => _CatatanPengeluaranAppState();
}

class _CatatanPengeluaranAppState extends State<CatatanPengeluaranApp> {
  final _storage = FinanceStorage();
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final saved = await _storage.loadThemeMode();
    if (!mounted || saved == null) return;
    setState(() {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == saved,
        orElse: () => ThemeMode.system,
      );
    });
  }

  Future<void> _changeThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    await _storage.saveThemeMode(mode.name);
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: cursorOrange,
          brightness: brightness,
        ).copyWith(
          primary: isDark ? const Color(0xFFFF7A3D) : cursorOrange,
          onPrimary: Colors.white,
          secondary: isDark ? const Color(0xFFFFA47A) : semanticMint,
          onSecondary: Colors.white,
          surface: isDark ? surfaceDark : const Color(0xFFFFFFFF),
          onSurface: isDark ? const Color(0xFFF7F7F4) : warmInk,
          surfaceContainerHighest: isDark
              ? const Color(0xFF48453C)
              : const Color(0xFFE6E5E0),
          outline: isDark ? const Color(0xFF625F55) : const Color(0xFFE6E5E0),
          error: semanticError,
        );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? canvasDark : canvasLight,
      fontFamily: 'CursorGothic',
    );
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        labelStyle: TextStyle(color: isDark ? const Color(0xFFA8B5C9) : warmSlate),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catatan Pengeluaran',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: SplashScreen(
        themeMode: _themeMode,
        onThemeModeChanged: _changeThemeMode,
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 1050),
          )
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && mounted) setState(() {});
          })
          ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 360),
      child: _controller.isCompleted
          ? FinanceHomePage(
              themeMode: widget.themeMode,
              onThemeModeChanged: widget.onThemeModeChanged,
            )
          : Scaffold(
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.primary,
                      colors.primary.withValues(alpha: 0.78),
                      colors.surface,
                    ],
                  ),
                ),
                child: Center(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) => Opacity(
                      opacity: Curves.easeOut.transform(_controller.value),
                      child: Transform.scale(
                        scale: 0.82 + (_controller.value * 0.18),
                        child: child,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.14),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            color: colors.primary,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Catatan Pengeluaran',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'Lebih sadar, lebih tertata.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: 110,
                          child: LinearProgressIndicator(
                            minHeight: 3,
                            borderRadius: BorderRadius.circular(99),
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

enum FinanceTab { overview, expenses, debts, savings }

class FinanceHomePage extends StatefulWidget {
  const FinanceHomePage({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<FinanceHomePage> createState() => _FinanceHomePageState();
}

class _FinanceHomePageState extends State<FinanceHomePage> {
  final _storage = FinanceStorage();
  final _imageService = ImageAttachmentService();
  final _contactService = ContactService();
  final _backupService = BackupService();
  final _communicationService = CommunicationService();
  final _transferService = DataTransferService();
  final _reminderStorage = ReminderStorage();
  final _imageFeedService = ImageFeedService();
  final _advancedService = AdvancedFinanceService();
  final _reportService = ReportService();
  List<ExpenseEntry> _expenses = <ExpenseEntry>[];
  List<DebtEntry> _debts = <DebtEntry>[];
  List<ReminderSchedule> _reminders = <ReminderSchedule>[];
  List<MoneyAccount> _accounts = <MoneyAccount>[];
  List<BudgetLimit> _budgets = <BudgetLimit>[];
  List<RecurringExpense> _recurring = <RecurringExpense>[];
  List<SavingsGoal> _savings = <SavingsGoal>[];
  ExpenseFilter _expenseFilter = const ExpenseFilter();
  List<String> _dashboardImageUrls = const <String>[];
  bool _imageFeedLoading = false;
  bool _imageFeedFromCache = false;
  bool _privacyEnabled = false;
  double _pocketMoney = 0;
  FinanceTab _tab = FinanceTab.overview;
  bool _isLoading = true;
  String _languageCode = 'id';
  String _cacheInfoLabel = 'menghitung...';
  final _debtSearchController = TextEditingController();
  final _expenseSearchController = TextEditingController();
  String _debtQuery = '';
  String _expenseQuery = '';
  final Set<String> _selectedExpenseIds = <String>{};
  bool _isSelectingExpenses = false;

  static const _quickActionChannel = MethodChannel('catatan/quick_actions');

  @override
  void initState() {
    super.initState();
    _quickActionChannel.setMethodCallHandler((call) async {
      if (call.method == 'open_expense_form' && mounted) {
        _showExpenseForm();
      }
    });
    _loadData();
    _loadImageFeed();
    _refreshCacheInfo();
  }

  @override
  void dispose() {
    _debtSearchController.dispose();
    _expenseSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final expenses = await _storage.loadExpenses();
    final debts = await _storage.loadDebts();
    final pocketMoney = await _storage.loadPocketMoney();
    final reminders = await _reminderStorage.load();
    final accounts = await _storage.loadAccounts();
    final budgets = await _storage.loadBudgets();
    final recurring = await _storage.loadRecurringExpenses();
    final savings = await _storage.loadSavingsGoals();
    final privacy = await _storage.loadPrivacyMode();
    final languageCode = await _storage.loadLanguage();
    final storageReport = _storage.consumeCorruptionReport();
    final reminderReport = _reminderStorage.consumeCorruptionReport();
    // Data yang rusak total sudah dikarantina. Jangan pernah menulis ulang
    // koleksi kosong hasil kegagalan baca: materialisasi pengeluaran berulang
    // akan menganggap semua sudah hilang dan menimpa karantina dengan data baru.
    final hasUnreadableData =
        storageReport.hasUnreadableData || reminderReport.hasUnreadableData;
    if (!hasUnreadableData) {
      final generated = _advancedService.materializeDueRecurring(
        recurring: recurring,
        now: DateTime.now(),
        existing: expenses,
      );
      if (generated.isNotEmpty) {
        expenses.addAll(generated);
        await _storage.saveExpenses(expenses);
      }
    }
    try {
      await ReminderService.instance.syncAll(_allReminderSchedules(reminders, savings));
    } catch (_) {
      // A missing notification permission must not block the finance dashboard.
    }
    if (!mounted) return;
    setState(() {
      _expenses = expenses..sort((a, b) => b.date.compareTo(a.date));
      _debts = debts..sort((a, b) => b.date.compareTo(a.date));
      _pocketMoney = pocketMoney;
      _reminders = reminders;
      _accounts = accounts;
      _budgets = budgets;
      _recurring = recurring;
      _savings = savings;
      _privacyEnabled = privacy;
      PrivacyMask.enabled = privacy;
      _languageCode = languageCode == 'en' ? 'en' : 'id';
      _isLoading = false;
    });
    await _syncHomeWidget();
    if (hasUnreadableData && mounted) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Data lokal terdeteksi rusak'),
          content: const Text(
            'Sebagian data tidak dapat dibaca dan salinan mentahnya telah disimpan otomatis dalam karantina internal. '
            'Pengeluaran berulang sementara tidak diaktifkan otomatis agar data rusak tidak tertimpa.\n\n'
            'Disarankan segera memulihkan data dari file backup terakhir (.bibzcup) melalui menu Pengaturan → Restore backup.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
    } else if ((storageReport.hasPartialDamage ||
            reminderReport.hasPartialDamage) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Beberapa catatan rusak dilewati saat memuat data. Salinan mentah disimpan untuk pemeriksaan.',
          ),
        ),
      );
    }
  }

  Future<void> _syncHomeWidget() async {
    final now = DateTime.now();
    final monthExpense = _expenses
        .where(
          (entry) =>
              entry.date.year == now.year && entry.date.month == now.month,
        )
        .fold(0.0, (sum, entry) => sum + entry.amount);
    final totalBalance = _accounts
        .where((item) => !item.isArchived)
        .fold(0.0, (sum, item) => sum + item.balance);
    try {
      await HomeWidget.saveWidgetData<String>(
        'month_expense',
        formatCurrency(monthExpense),
      );
      await HomeWidget.saveWidgetData<String>(
        'pocket_money',
        formatCurrency(_remainingPocketMoney),
      );
      await HomeWidget.saveWidgetData<String>(
        'total_balance',
        formatCurrency(totalBalance),
      );
      await HomeWidget.updateWidget(name: 'FinanceWidgetProvider');
    } catch (_) {
      // Widgets are optional; storage and dashboard must remain functional without them.
    }
  }

  List<ExpenseEntry> get _filteredExpenses {
    final filter = _expenseFilter;
    final query = filter.query.trim().toLowerCase();
    return _expenses.where((entry) {
      final haystack =
          '${entry.title} ${entry.note} ${categoryLabel(entry.category)}'
              .toLowerCase();
      if (query.isNotEmpty && !haystack.contains(query)) return false;
      if (filter.category != null && entry.category != filter.category)
        return false;
      if (filter.accountId != null && entry.accountId != filter.accountId)
        return false;
      if (filter.from != null && entry.date.isBefore(filter.from!))
        return false;
      if (filter.to != null &&
          entry.date.isAfter(
            DateTime(
              filter.to!.year,
              filter.to!.month,
              filter.to!.day,
              23,
              59,
              59,
            ),
          ))
        return false;
      if (filter.minimum != null && entry.amount < filter.minimum!)
        return false;
      if (filter.maximum != null && entry.amount > filter.maximum!)
        return false;
      return true;
    }).toList();
  }

  bool get _expenseFilterIsActive => _expenseFilter.isActive;

  Future<void> _openExpenseFilters() async {
    final result = await showDialog<ExpenseFilter>(
      context: context,
      builder: (_) =>
          ExpenseFilterDialog(filter: _expenseFilter, accounts: _accounts),
    );
    if (result == null || !mounted) return;
    setState(() => _expenseFilter = result.copyWith(query: _expenseQuery));
  }

  List<MoneyAccount> _deduplicateAccounts(
    Iterable<MoneyAccount> accounts, {
    Map<String, String>? idMap,
  }) => FinanceCalc.deduplicateAccounts(accounts, idMap: idMap);

  List<ExpenseEntry> _remapExpenseAccounts(
    Iterable<ExpenseEntry> expenses,
    Map<String, String> idMap,
  ) => FinanceCalc.remapExpenseAccounts(expenses, idMap);

  List<RecurringExpense> _remapRecurringAccounts(
    Iterable<RecurringExpense> items,
    Map<String, String> idMap,
  ) => FinanceCalc.remapRecurringAccounts(items, idMap);

  FinanceTotals get _totals => FinanceCalc.totals(
        expenses: _expenses,
        debts: _debts,
        pocketMoney: _pocketMoney,
      );
  double get _totalExpense => _totals.totalExpense;
  double get _pocketMoneyExpense => _totals.pocketMoneyExpense;
  double get _remainingPocketMoney => _totals.remainingPocketMoney;
  double get _payable => _totals.payable;
  double get _receivable => _totals.receivable;

  Future<void> _loadImageFeed({bool forceRefresh = false}) async {
    if (mounted) setState(() => _imageFeedLoading = true);
    final snapshot = await _imageFeedService.load(forceRefresh: forceRefresh);
    if (!mounted) return;
    setState(() {
      _dashboardImageUrls = snapshot.urls;
      _imageFeedFromCache = snapshot.fromCache;
      _imageFeedLoading = false;
    });
  }

  Future<void> _saveExpenses() => _storage.saveExpenses(_expenses);
  Future<void> _saveDebts() => _storage.saveDebts(_debts);
  Future<void> _savePocketMoney() => _storage.savePocketMoney(_pocketMoney);
  Future<void> _saveReminders() => _reminderStorage.save(_reminders);
  Future<void> _saveAccounts() => _storage.saveAccounts(_accounts);
  Future<void> _saveBudgets() => _storage.saveBudgets(_budgets);
  Future<void> _saveRecurring() => _storage.saveRecurringExpenses(_recurring);
  Future<void> _saveSavings() => _storage.saveSavingsGoals(_savings);

  void _toggleExpenseSelection(String id) {
    setState(() {
      if (!_selectedExpenseIds.remove(id)) _selectedExpenseIds.add(id);
    });
  }

  void _selectAllExpenses(List<ExpenseEntry> entries) {
    setState(() {
      _selectedExpenseIds
        ..clear()
        ..addAll(entries.map((entry) => entry.id));
    });
  }

  void _exitExpenseSelection() {
    setState(() {
      _isSelectingExpenses = false;
      _selectedExpenseIds.clear();
    });
  }

  Future<void> _markSelectedExpensesSettled() async {
    if (_selectedExpenseIds.isEmpty) return;
    setState(() {
      _expenses = _expenses
          .map(
            (entry) => _selectedExpenseIds.contains(entry.id)
                ? entry.copyWith(isSettled: true)
                : entry,
          )
          .toList();
    });
    await _saveExpenses();
    if (mounted) _exitExpenseSelection();
  }

  Future<void> _deleteSelectedExpenses() async {
    if (_selectedExpenseIds.isEmpty) return;
    final selected = _expenses
        .where((entry) => _selectedExpenseIds.contains(entry.id))
        .toList();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Hapus ${selected.length} pengeluaran?'),
        content: const Text('Transaksi terpilih dan foto lampirannya akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    for (final entry in selected) {
      await _imageService.delete(entry.imagePath);
    }
    setState(() {
      _expenses.removeWhere((entry) => _selectedExpenseIds.contains(entry.id));
      _selectedExpenseIds.clear();
      _isSelectingExpenses = false;
    });
    await _saveExpenses();
    await _syncHomeWidget();
  }

  Future<void> _openBudgets() async {
    final updated = await showModalBottomSheet<List<BudgetLimit>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BudgetSettingsSheet(initialBudgets: _budgets),
    );
    if (updated == null || !mounted) return;
    setState(() => _budgets = updated);
    await _saveBudgets();
    _notifyBudgetStatus(updated);
  }

  Future<void> _openAccountDetail(MoneyAccount account) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AccountTransitionSplash(account: account),
    );
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AccountDetailSheet(
        account: account,
        expenses: _expenses,
        onEdit: _openAccounts,
        onDelete: _openAccounts,
      ),
    );
  }

  Future<void> _openAccounts() async {
    final updated = await showModalBottomSheet<List<MoneyAccount>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AccountSettingsSheet(
        initialAccounts: _accounts,
        expenses: _expenses,
        recurring: _recurring,
      ),
    );
    if (updated == null || !mounted) return;
    final previousIds = _accounts.map((item) => item.id).toSet();
    final updatedIds = updated.map((item) => item.id).toSet();
    final removedIds = previousIds.difference(updatedIds);
    setState(() {
      _accounts = updated;
      if (removedIds.isNotEmpty) {
        _expenses = _expenses
            .map(
              (entry) => removedIds.contains(entry.accountId)
                  ? entry.copyWith(clearAccount: true)
                  : entry,
            )
            .toList();
        _recurring = _recurring
            .map(
              (item) => removedIds.contains(item.accountId)
                  ? item.copyWith(clearAccount: true)
                  : item,
            )
            .toList();
      }
    });
    await _saveAccounts();
    if (removedIds.isNotEmpty) {
      await _saveExpenses();
      await _saveRecurring();
    }
    await _syncHomeWidget();
  }

  Future<void> _openRecurring() async {
    final updated = await showModalBottomSheet<List<RecurringExpense>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          RecurringSettingsSheet(initialItems: _recurring, accounts: _accounts),
    );
    if (updated == null || !mounted) return;
    setState(() => _recurring = updated);
    await _saveRecurring();
    await ReminderService.instance.syncAll(_reminders);
  }

  Future<void> _openAnalytics() async {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AnalyticsSheet(
        expenses: _expenses,
        budgets: _advancedService.budgetStatuses(
          budgets: _budgets,
          expenses: _expenses,
        ),
        insights: _advancedService.unusualExpenses(_expenses),
      ),
    );
  }

  Future<void> _sharePdf() async {
    try {
      await _reportService.sharePdf(
        expenses: _expenses,
        debts: _debts,
        accounts: _accounts,
        budgets: _budgets,
        insights: _advancedService.unusualExpenses(_expenses),
        pocketMoney: _pocketMoney,
      );
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('PDF gagal dibuat: $error')));
    }
  }

  Future<void> _togglePrivacy() async {
    setState(() {
      _privacyEnabled = !_privacyEnabled;
      PrivacyMask.enabled = _privacyEnabled;
    });
    await _storage.savePrivacyMode(_privacyEnabled);
  }

  void _notifyBudgetStatus(List<BudgetLimit> budgets) {
    final statuses = _advancedService.budgetStatuses(
      budgets: budgets,
      expenses: _expenses,
    );
    final alert = statuses.firstWhere(
      (item) => item.isExceeded || item.isAlert,
      orElse: () => BudgetStatus(
        limit: BudgetLimit(
          id: '',
          category: ExpenseCategory.other,
          monthlyLimit: 0,
          createdAt: DateTime(2000),
        ),
        spent: 0,
        percent: 0,
      ),
    );
    if (alert.limit.id.isNotEmpty && mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            alert.isExceeded
                ? 'Anggaran ${categoryLabel(alert.limit.category)} sudah terlampaui.'
                : 'Anggaran ${categoryLabel(alert.limit.category)} mendekati batas ${alert.limit.alertPercent}%.',
          ),
        ),
      );
  }

  List<ReminderSchedule> _allReminderSchedules(
    List<ReminderSchedule> reminders,
    List<SavingsGoal> savings,
  ) => FinanceCalc.allReminderSchedules(reminders, savings);

  Future<void> _openSavings() async {
    final updated = await showModalBottomSheet<List<SavingsGoal>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SavingsSettingsSheet(
        initialGoals: _savings,
        imageService: _imageService,
      ),
    );
    if (updated == null || !mounted) return;
    final granted = updated.any((goal) => goal.reminderEnabled)
        ? await ReminderService.instance.requestPermission()
        : true;
    setState(() => _savings = updated);
    await _saveSavings();
    try {
      await ReminderService.instance.syncAll(
        _allReminderSchedules(_reminders, updated),
      );
    } catch (_) {
      // Goals remain saved even if notification permission is unavailable.
    }
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tabungan tersimpan, tetapi izin notifikasi belum diberikan.',
          ),
        ),
      );
    }
  }

  Future<void> _openReminders() async {
    final updated = await showModalBottomSheet<List<ReminderSchedule>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReminderSettingsSheet(initialReminders: _reminders),
    );
    if (updated == null || !mounted) return;
    final granted = await ReminderService.instance.requestPermission();
    setState(() => _reminders = updated);
    await _saveReminders();
    try {
      await ReminderService.instance.syncAll(
        _allReminderSchedules(updated, _savings),
      );
    } catch (_) {
      // The schedules remain saved and can be synced again after permission is granted.
    }
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Izin notifikasi belum diberikan. Jadwal tersimpan, tetapi notifikasi belum aktif.',
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${updated.where((item) => item.enabled).length} pengingat aktif.',
          ),
        ),
      );
    }
  }

  Future<void> _editPocketMoney() async {
    final controller = TextEditingController(
      text: _pocketMoney == 0 ? '' : _pocketMoney.toStringAsFixed(0),
    );
    final value = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Atur Uang Saku'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Jumlah Uang Saku',
            prefixText: 'Rp  ',
            hintText: 'Contoh: 500000',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, parseAmount(controller.text)),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value < 0 || !mounted) return;
    setState(() => _pocketMoney = value);
    await _savePocketMoney();
    await _syncHomeWidget();
  }

  void _showExpenseForm({ExpenseEntry? entry}) async {
    final result = await showModalBottomSheet<ExpenseEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExpenseFormSheet(
        entry: entry,
        imageService: _imageService,
        accounts: _accounts,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      final index = _expenses.indexWhere((item) => item.id == result.id);
      if (index == -1) {
        _expenses = [result, ..._expenses];
      } else {
        _expenses[index] = result;
        _expenses.sort((a, b) => b.date.compareTo(a.date));
      }
    });
    await _saveExpenses();
    await _syncHomeWidget();
  }

  void _showDebtForm({DebtEntry? entry}) async {
    final result = await showModalBottomSheet<DebtEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DebtFormSheet(
        entry: entry,
        imageService: _imageService,
        contactService: _contactService,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      final index = _debts.indexWhere((item) => item.id == result.id);
      if (index == -1) {
        _debts = [result, ..._debts];
      } else {
        _debts[index] = result;
        _debts.sort((a, b) => b.date.compareTo(a.date));
      }
    });
    _saveDebts();
  }

  Future<void> _deleteExpense(ExpenseEntry entry) async {
    setState(() => _expenses.removeWhere((item) => item.id == entry.id));
    await _saveExpenses();
    if (!mounted) {
      // Halaman sudah tidak aktif sehingga undo tidak lagi mungkin.
      await _imageService.delete(entry.imagePath);
      return;
    }
    // File lampiran dihapus setelah jendela undo berlalu, bukan segera,
    // supaya tombol URUNGKAN tidak mengembalikan entry dengan path foto yang
    // sudah tidak ada (lampiran menggantung).
    var undone = false;
    final pendingDelete = Timer(const Duration(seconds: 6), () {
      if (!undone) _imageService.delete(entry.imagePath);
    });
    _showUndoSnackBar('Pengeluaran dihapus', () {
      undone = true;
      pendingDelete.cancel();
      if (!mounted) return;
      setState(() => _expenses = [entry, ..._expenses]);
      _saveExpenses();
    });
  }

  Future<void> _deleteDebt(DebtEntry entry) async {
    setState(() => _debts.removeWhere((item) => item.id == entry.id));
    await _saveDebts();
    if (!mounted) {
      await _imageService.delete(entry.imagePath);
      return;
    }
    var undone = false;
    final pendingDelete = Timer(const Duration(seconds: 6), () {
      if (!undone) _imageService.delete(entry.imagePath);
    });
    _showUndoSnackBar('Catatan hutang dihapus', () {
      undone = true;
      pendingDelete.cancel();
      if (!mounted) return;
      setState(() => _debts = [entry, ..._debts]);
      _saveDebts();
    });
  }

  void _showUndoSnackBar(String message, VoidCallback onUndo) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(label: 'URUNGKAN', onPressed: onUndo),
      ),
    );
  }

  Future<void> _toggleDebt(DebtEntry entry) async {
    final index = _debts.indexWhere((item) => item.id == entry.id);
    if (index == -1) return;
    setState(() => _debts[index] = entry.copyWith(isSettled: !entry.isSettled));
    await _saveDebts();
  }

  Future<void> _createBackup() async {
    try {
      final file = await _backupService.createBackup(
        expenses: _expenses,
        debts: _debts,
        pocketMoney: _pocketMoney,
        reminders: _reminders,
        accounts: _accounts,
        budgets: _budgets,
        recurring: _recurring,
        savingsGoals: _savings,
        privacyMode: _privacyEnabled,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Backup tersimpan di CatatBibz: ${file.path.split('/').last}',
          ),
        ),
      );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup belum berhasil dibuat. Coba lagi.'),
          ),
        );
    }
  }

  Future<void> _backupToGoogleDrive() async {
    try {
      final file = await _backupService.createBackup(
        expenses: _expenses,
        debts: _debts,
        pocketMoney: _pocketMoney,
        reminders: _reminders,
        accounts: _accounts,
        budgets: _budgets,
        recurring: _recurring,
        savingsGoals: _savings,
        privacyMode: _privacyEnabled,
      );
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Backup ke Google Drive'),
          content: const Text(
            'Login akan dilakukan melalui aplikasi Google Drive atau browser/system. Catatan Pengeluaran tidak meminta atau menyimpan password Google.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Lanjutkan'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await SharePlus.instance.share(
        ShareParams(
          title: 'Backup Catatan Pengeluaran',
          subject: 'Backup Catatan Pengeluaran',
          text: 'Pilih Google Drive pada menu berbagi untuk menyimpan backup ini.',
          files: [XFile(file.path, mimeType: 'application/zip')],
          fileNameOverrides: [file.path.split('/').last],
        ),
      );
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup Google Drive gagal: $error')),
        );
    }
  }

  Future<void> _restoreBackup() async {
    try {
      RestorePayload? payload;
      try {
        payload = await _transferService.pickAndRestore();
      } on CrossDeviceBackupException catch (error) {
        if (!mounted) return;
        final proceed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Backup dari perangkat lain'),
            content: const Text(
              'Backup ini dibuat di perangkat berbeda sehingga tanda tangan perangkat tidak bisa diverifikasi di sini.\n\n'
              'Isi file tetap akan diperiksa dengan checksum SHA256. Lanjutkan restore?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Lanjutkan'),
              ),
            ],
          ),
        );
        if (proceed != true || !mounted) return;
        payload = await _transferService.restoreFromFile(
          error.sourcePath,
          allowCrossDevice: true,
        );
      }
      if (payload == null || !mounted) return;
      final mode = await showDialog<RestoreMode>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Pulihkan backup'),
          content: Text('${payload.sourceName}\n\nPilih cara pemulihan data.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, RestoreMode.merge),
              child: const Text('Gabungkan'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, RestoreMode.replace),
              child: const Text('Ganti semua'),
            ),
          ],
        ),
      );
      if (mode == null) return;
      setState(() {
        if (mode == RestoreMode.replace) {
          final accountIdMap = <String, String>{};
          _accounts = _deduplicateAccounts(
            payload.accounts,
            idMap: accountIdMap,
          );
          _expenses = _remapExpenseAccounts(payload.expenses, accountIdMap);
          _debts = [...payload.debts];
          _pocketMoney = payload.pocketMoney;
          _reminders = [...payload.reminders];
          _budgets = [...payload.budgets];
          _recurring = _remapRecurringAccounts(payload.recurring, accountIdMap);
          _savings = [...payload.savingsGoals];
          _privacyEnabled = payload.privacyMode;
          PrivacyMask.enabled = _privacyEnabled;
        } else {
          final accountIdMap = <String, String>{};
          _accounts = _deduplicateAccounts([
            ..._accounts,
            ...payload.accounts,
          ], idMap: accountIdMap);
          final expenses = {for (final item in _expenses) item.id: item};
          final debts = {for (final item in _debts) item.id: item};
          for (final item in payload.expenses) {
            expenses[item.id] = item;
          }
          for (final item in payload.debts) {
            debts[item.id] = item;
          }
          _expenses = _remapExpenseAccounts(expenses.values, accountIdMap);
          _debts = debts.values.toList();
          if (payload.pocketMoney > 0) _pocketMoney = payload.pocketMoney;
          if (payload.reminders.isNotEmpty)
            _reminders = [..._reminders, ...payload.reminders];
          if (payload.budgets.isNotEmpty)
            _budgets = [..._budgets, ...payload.budgets];
          if (payload.recurring.isNotEmpty)
            _recurring = _remapRecurringAccounts([
              ..._recurring,
              ...payload.recurring,
            ], accountIdMap);
          if (payload.savingsGoals.isNotEmpty) {
            final savings = {for (final item in _savings) item.id: item};
            for (final item in payload.savingsGoals) {
              savings[item.id] = item;
            }
            _savings = savings.values.toList();
          }
          if (payload.privacyMode) {
            _privacyEnabled = true;
            PrivacyMask.enabled = true;
          }
        }
        _expenses.sort((a, b) => b.date.compareTo(a.date));
        _debts.sort((a, b) => b.date.compareTo(a.date));
      });
      await _saveExpenses();
      await _saveDebts();
      await _savePocketMoney();
      await _saveReminders();
      await _saveAccounts();
      await _saveBudgets();
      await _saveRecurring();
      await _saveSavings();
      await _storage.savePrivacyMode(_privacyEnabled);
      try {
        await ReminderService.instance.syncAll(_allReminderSchedules(_reminders, _savings));
      } catch (_) {
        // Restore data must remain successful even when notification permission is denied.
      }
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${payload.expenses.length + payload.debts.length} catatan dan ${payload.reminders.length} pengingat berhasil dipulihkan.',
            ),
          ),
        );
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Restore gagal: ${error.toString().replaceFirst('FormatException: ', '')}',
            ),
          ),
        );
    }
  }

  Future<void> _shareSpreadsheet() async {
    try {
      final file = await _transferService.createSpreadsheet(
        expenses: _expenses,
        debts: _debts,
        pocketMoney: _pocketMoney,
      );
      await SharePlus.instance.share(
        ShareParams(
          title: 'Spreadsheet Catatan Pengeluaran',
          subject: 'Laporan Catatan Pengeluaran',
          text: 'Spreadsheet profesional Catatan Pengeluaran dengan ringkasan, transaksi, dan hutang/piutang.',
          files: [
            XFile(
              file.path,
              mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ),
          ],
          fileNameOverrides: [file.path.split('/').last],
        ),
      );
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export spreadsheet gagal: $error')),
        );
    }
  }

  Future<void> _openCommunication(DebtEntry entry) async {
    final phone = entry.contactPhone;
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pilih kontak yang memiliki nomor telepon terlebih dahulu.',
          ),
        ),
      );
      return;
    }
    final request = await showModalBottomSheet<CommunicationRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommunicationSheet(entry: entry),
    );
    if (request == null) return;
    final opened = request.channel == CommunicationChannel.whatsapp
        ? await _communicationService.openWhatsApp(
            phone: phone,
            message: request.message,
          )
        : await _communicationService.openSms(
            phone: phone,
            message: request.message,
          );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            request.channel == CommunicationChannel.whatsapp
                ? 'WhatsApp tidak tersedia di perangkat ini.'
                : 'Aplikasi SMS tidak tersedia di perangkat ini.',
          ),
        ),
      );
    }
  }

  void _openCalculator() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CalculatorSheet(),
    );
  }

  Future<void> _openSettings() async {
    await _refreshCacheInfo();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AppSettingsSheet(
        languageCode: _languageCode,
        cacheInfo: _cacheInfoLabel,
        selectedTheme: widget.themeMode,
        onThemeSelected: widget.onThemeModeChanged,
        onLanguageChanged: (value) {
          setState(() => _languageCode = value);
          _storage.saveLanguage(value);
        },
        onBackup: _createBackup,
        onRestore: _restoreBackup,
        onCheckUpdate: _checkForUpdates,
        onClearCache: _clearAppCache,
      ),
    );
  }

  Future<void> _refreshCacheInfo() async {
    final temporary = await getTemporaryDirectory();
    final documents = await getApplicationDocumentsDirectory();
    final attachments = Directory('${documents.path}/attachments');
    var updateBytes = 0;
    var attachmentBytes = 0;
    if (await temporary.exists()) {
      await for (final entity in temporary.list()) {
        if (entity is File && entity.path.endsWith('.apk')) {
          updateBytes += await entity.length();
        }
      }
    }
    if (await attachments.exists()) {
      await for (final entity in attachments.list(recursive: true)) {
        if (entity is File) attachmentBytes += await entity.length();
      }
    }
    if (mounted) {
      setState(() {
        _cacheInfoLabel =
            'Gambar dashboard tersimpan • APK ${_formatBytes(updateBytes)} • Lampiran ${_formatBytes(attachmentBytes)}';
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _clearAppCache() async {
    await _imageFeedService.clearCache();
    await AppUpdateService.instance.cleanupDownloadedApks();
    await _refreshCacheInfo();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache sementara berhasil dibersihkan. Foto lampiran tetap aman.')),
      );
    }
  }

  Future<void> _checkForUpdates() async {
    try {
      final current = await PackageInfo.fromPlatform();
      final latest = await AppUpdateService.instance.checkLatest();
      final currentCode = int.tryParse(current.buildNumber) ?? 0;
      // Android uses versionCode as the authoritative install/update order.
      // A changed display version with the same code is not installable as an update.
      final hasUpdate = latest.versionCode > currentCode ||
          (currentCode == 0 && latest.version != current.version);
      if (!mounted) return;
      if (!hasUpdate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aplikasi sudah versi terbaru (${current.version}).')),
        );
        return;
      }
      if (!AppUpdateService.instance.supportsApkInstall) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _languageCode == 'en'
                  ? 'A new version is available. iOS/Web updates are delivered through their platform deployment channel.'
                  : 'Versi baru tersedia. Update iOS/Web dilakukan melalui kanal deployment platform masing-masing.',
            ),
          ),
        );
        return;
      }
      await _showUpdateDialog(current.version, latest);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cek update gagal: $error')),
        );
      }
    }
  }

  Future<void> _showUpdateDialog(String currentVersion, AppUpdateInfo latest) async {
    var downloading = false;
    var progress = 0.0;
    String? errorMessage;
    await showDialog<void>(
      context: context,
      barrierDismissible: !downloading,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final percent = (progress * 100).round();
          return AlertDialog(
            title: const Text('Pembaruan tersedia'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Versi saat ini: $currentVersion\nVersi terbaru: ${latest.version}'),
                if (latest.releaseNotes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(latest.releaseNotes),
                ],
                if (downloading) ...[
                  const SizedBox(height: 18),
                  LinearProgressIndicator(value: progress == 0 ? null : progress),
                  const SizedBox(height: 8),
                  Text(progress == 0 ? 'Menyiapkan unduhan...' : 'Mengunduh $percent%'),
                ],
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: downloading ? null : () => Navigator.pop(dialogContext),
                child: const Text('Nanti'),
              ),
              FilledButton.icon(
                onPressed: downloading
                    ? null
                    : () async {
                        setDialogState(() {
                          downloading = true;
                          errorMessage = null;
                        });
                        try {
                          final path = await AppUpdateService.instance.download(
                            latest,
                            preferArm64: true,
                            onProgress: (received, total) {
                              if (!dialogContext.mounted) return;
                              setDialogState(() {
                                progress = total > 0 ? received / total : 0;
                              });
                            },
                          );
                          if (dialogContext.mounted) Navigator.pop(dialogContext);
                          await AppUpdateService.instance.installApk(path);
                          Future<void>.delayed(const Duration(seconds: 45), () {
                            return AppUpdateService.instance.cleanupDownloadedApks();
                          });
                        } catch (error) {
                          if (dialogContext.mounted) {
                            setDialogState(() {
                              downloading = false;
                              errorMessage = 'Download atau instalasi gagal: $error';
                            });
                          }
                        }
                      },
                icon: const Icon(Icons.download_rounded),
                label: const Text('Perbarui'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            Flexible(
              child: Text(
                'Catatan Pengeluaran',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  color: colors.onSurface,
                  fontSize: 19,
                  letterSpacing: -0.35,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Pengingat jadwal',
            onPressed: _openReminders,
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            tooltip: 'Kalkulator',
            onPressed: _openCalculator,
            icon: const Icon(Icons.calculate_outlined),
          ),
          IconButton(
            tooltip: 'Data dan laporan',
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              useSafeArea: true,
              backgroundColor: colors.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              isScrollControlled: true,
              builder: (_) => DataToolsSheet(
                onSpreadsheet: _shareSpreadsheet,
                onPdf: _sharePdf,
                onBudgets: _openBudgets,
                onAccounts: _openAccounts,
                onRecurring: _openRecurring,
                onAnalytics: _openAnalytics,
                onPrivacy: _togglePrivacy,
                privacyEnabled: _privacyEnabled,
              ),
            ),
            icon: const Icon(Icons.more_horiz_rounded),
          ),
          IconButton(
            tooltip: 'Pengaturan',
            onPressed: _openSettings,
            icon: const Icon(Icons.menu_rounded),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.03, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _buildCurrentTab(),
              ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab.index,
        onDestinationSelected: (index) =>
            setState(() => _tab = FinanceTab.values[index]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Ringkasan',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Pengeluaran',
          ),
          NavigationDestination(
            icon: Icon(Icons.handshake_outlined),
            selectedIcon: Icon(Icons.handshake_rounded),
            label: 'Hutang',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings_rounded),
            label: 'Tabungan',
          ),
        ],
      ),
      floatingActionButton: _buildFab(colors),
    );
  }

  Widget? _buildFab(ColorScheme colors) {
    final isDebt = _tab == FinanceTab.debts;
    final isSavings = _tab == FinanceTab.savings;
    return FloatingActionButton.extended(
      heroTag: 'finance-fab',
      onPressed: isDebt
          ? _showDebtForm
          : isSavings
          ? _openSavings
          : _showExpenseForm,
      backgroundColor: isDebt ? semanticMint : colors.primary,
      foregroundColor: Colors.white,
      icon: Icon(
        isDebt
            ? Icons.add_card_rounded
            : isSavings
            ? Icons.savings_rounded
            : Icons.add_rounded,
      ),
      label: Text(
        isDebt
            ? 'Tambah hutang'
            : isSavings
            ? 'Tambah tabungan'
            : 'Catat pengeluaran',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_tab) {
      case FinanceTab.overview:
        return _buildOverview(key: const ValueKey('overview'));
      case FinanceTab.expenses:
        return _buildExpenseList(key: const ValueKey('expenses'));
      case FinanceTab.debts:
        return _buildDebtList(key: const ValueKey('debts'));
      case FinanceTab.savings:
        return _buildSavingsPage(key: const ValueKey('savings'));
    }
  }

  Widget _buildSavingsPage({required Key key}) {
    final colors = Theme.of(context).colorScheme;
    final target = _savings.fold<double>(
      0,
      (sum, goal) => sum + goal.targetAmount,
    );
    final saved = _savings.fold<double>(
      0,
      (sum, goal) => sum + goal.savedAmount,
    );
    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 108),
      children: [
        PageHeading(
          title: 'Tabungan',
          subtitle: 'Tujuan yang ingin kamu wujudkan',
        ),
        const SizedBox(height: 16),
        Card(
          color: colors.primary,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total terkumpul',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  formatCurrency(saved),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'dari ${formatCurrency(target)} total target',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (_savings.isEmpty)
          _buildEmptyCard(
            'Belum ada tabungan',
            'Tekan tombol Tambah tabungan untuk membuat tujuan baru.',
            Icons.savings_outlined,
          )
        else
          ..._savings.map(
            (goal) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SavingsOverviewCard(
                goal: goal,
                onTap: _openSavings,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOverview({required Key key}) {
    final colors = Theme.of(context).colorScheme;
    final recent = _expenses.take(4).toList();
    return RefreshIndicator(
      key: key,
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 108),
        children: [
          Text(
            'Halo, yuk lebih sadar finansial.',
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.66),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          _buildPocketMoneyCard(colors),
          const SizedBox(height: 14),
          DashboardImageRail(
            urls: _dashboardImageUrls,
            isLoading: _imageFeedLoading,
            fromCache: _imageFeedFromCache,
            onRefresh: () => _loadImageFeed(forceRefresh: true),
          ),
          const SizedBox(height: 14),
          _buildBalanceCard(colors),
          const SizedBox(height: 14),
          _buildAccountStrip(colors),
          const SizedBox(height: 14),
          _buildBudgetStrip(colors),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  label: 'Hutang kita',
                  value: formatCurrency(_payable),
                  icon: Icons.arrow_upward_rounded,
                  color: semanticError,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricCard(
                  label: 'Piutang kita',
                  value: formatCurrency(_receivable),
                  icon: Icons.arrow_downward_rounded,
                  color: semanticMint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          SectionHeader(
            title: 'Pengeluaran terbaru',
            actionLabel: 'Lihat semua',
            onAction: () => setState(() => _tab = FinanceTab.expenses),
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            _buildEmptyCard(
              'Belum ada pengeluaran',
              'Catat transaksi pertamamu agar ringkasan mulai terisi.',
              Icons.receipt_long_outlined,
            )
          else
            ...recent.asMap().entries.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ExpenseTile(
                  entry: item.value,
                  onTap: () => _showExpenseForm(entry: item.value),
                  onDelete: () => _deleteExpense(item.value),
                ),
              ),
            ),
          const SizedBox(height: 10),
          SectionHeader(
            title: 'Hutang & piutang',
            actionLabel: 'Kelola',
            onAction: () => setState(() => _tab = FinanceTab.debts),
          ),
          const SizedBox(height: 12),
          _buildDebtSummary(colors),
        ],
      ),
    );
  }

  Widget _buildPocketMoneyCard(ColorScheme colors) {
    final hasAllowance = _pocketMoney > 0;
    final remaining = _remainingPocketMoney;
    final isOver = remaining < 0;
    return InkWell(
      onTap: _editPocketMoney,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(17, 15, 13, 15),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outline.withValues(alpha: 0.78)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                color: colors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saldo Uang Saku',
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.62),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasAllowance
                        ? formatCurrency(_pocketMoney)
                        : 'Belum diatur',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (hasAllowance)
                    Text(
                      isOver
                          ? 'Melebihi ${formatCurrency(remaining.abs())}'
                          : 'Sisa Uang Saku ${formatCurrency(remaining)}',
                      style: TextStyle(
                        color: isOver ? colors.error : semanticMint,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Edit Uang Saku',
              onPressed: _editPocketMoney,
              icon: Icon(
                Icons.edit_outlined,
                color: colors.onSurface.withValues(alpha: 0.55),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountStrip(ColorScheme colors) {
    final active = _accounts.where((item) => !item.isArchived).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Saldo akun/dompet (di luar Uang Saku)',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton.icon(
              onPressed: _openAccounts,
              icon: const Icon(Icons.tune_rounded, size: 17),
              label: const Text('Kelola'),
            ),
          ],
        ),
        if (active.isEmpty)
          InkWell(
            onTap: _openAccounts,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_card_rounded, color: colors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tambahkan bank atau e-wallet untuk melihat saldo terpisah.',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 126,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: active.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final account = active[index];
                return SizedBox(
                  width: 214,
                  child: Card(
                    child: InkWell(
                      onTap: () => _openAccountDetail(account),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                AccountBrandIcon(
                                  brandKey: account.brandKey,
                                  size: 28,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    account.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              account.type.name,
                              style: TextStyle(
                                color: colors.onSurface.withValues(alpha: 0.58),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _privacyEnabled
                                  ? '••••••'
                                  : formatCurrency(account.balance),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBudgetStrip(ColorScheme colors) {
    final statuses = _advancedService.budgetStatuses(
      budgets: _budgets,
      expenses: _expenses,
    );
    if (statuses.isEmpty) {
      return InkWell(
        onTap: _openBudgets,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.primary.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Icon(Icons.add_chart_rounded, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Atur anggaran bulanan agar pengeluaran lebih terarah.',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      );
    }
    final status = statuses.first;
    final progressColor = status.isExceeded
        ? colors.error
        : status.isAlert
        ? Colors.orange
        : colors.primary;
    return Card(
      child: InkWell(
        onTap: _openBudgets,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Anggaran ${categoryLabel(status.limit.category)}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    '${status.percent.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: progressColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (status.percent / 100).clamp(0, 1),
                minHeight: 8,
                borderRadius: BorderRadius.circular(99),
                color: progressColor,
              ),
              const SizedBox(height: 6),
              Text(
                status.isExceeded
                    ? 'Melebihi ${formatCurrency(status.remaining.abs())}'
                    : 'Sisa ${formatCurrency(status.remaining)}',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.onSurface.withValues(alpha: 0.62),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(ColorScheme colors) {
    final today = DateTime.now();
    final thisMonth = _expenses
        .where(
          (entry) =>
              entry.date.year == today.year && entry.date.month == today.month,
        )
        .fold(0.0, (sum, entry) => sum + entry.amount);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        alignment: Alignment.center,
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cursorOrangeDark.withValues(alpha: 0.45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total pengeluaran bulan ini (semua sumber dana)',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${_expenses.length} transaksi',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              formatCurrency(thisMonth),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 18),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.18)),
            const SizedBox(height: 13),
            Row(
              children: [
                const Icon(
                  Icons.insights_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Catat kecil, dampaknya besar.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  formatCurrency(_totalExpense),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseList({required Key key}) {
    final filtered = _filteredExpenses;
    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 108),
      children: [
        PageHeading(
          title: 'Riwayat pengeluaran',
          subtitle:
              '${filtered.length} dari ${_expenses.length} transaksi tercatat',
        ),
        const SizedBox(height: 14),
        if (_isSelectingExpenses) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Selesai memilih',
                    onPressed: _exitExpenseSelection,
                    icon: const Icon(Icons.close_rounded),
                  ),
                  Expanded(
                    child: Text(
                      '${_selectedExpenseIds.length} dipilih',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  TextButton(
                    onPressed: filtered.isEmpty
                        ? null
                        : () => _selectAllExpenses(filtered),
                    child: const Text('Pilih semua'),
                  ),
                  IconButton(
                    tooltip: 'Tandai lunas',
                    onPressed: _selectedExpenseIds.isEmpty
                        ? null
                        : _markSelectedExpensesSettled,
                    icon: const Icon(Icons.done_all_rounded),
                  ),
                  IconButton(
                    tooltip: 'Hapus terpilih',
                    onPressed: _selectedExpenseIds.isEmpty
                        ? null
                        : _deleteSelectedExpenses,
                    icon: const Icon(Icons.delete_sweep_outlined),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ] else
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() => _isSelectingExpenses = true),
              icon: const Icon(Icons.checklist_rounded),
              label: const Text('Pilih transaksi'),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _expenseSearchController,
                onChanged: (value) => setState(() => _expenseQuery = value),
                decoration: InputDecoration(
                  labelText: 'Cari pengeluaran',
                  hintText: 'Judul, catatan, atau kategori',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _expenseQuery.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _expenseSearchController.clear();
                            setState(() => _expenseQuery = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: _openExpenseFilters,
              tooltip: 'Filter lanjutan',
              icon: Badge(
                isLabelVisible: _expenseFilterIsActive,
                child: const Icon(Icons.tune_rounded),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_expenses.isEmpty)
          _buildEmptyCard(
            'Belum ada transaksi',
            'Tekan tombol di bawah untuk mencatat pengeluaran.',
            Icons.receipt_long_outlined,
          )
        else if (filtered.isEmpty)
          _buildEmptyCard(
            'Tidak ada hasil',
            'Coba kata kunci atau filter yang berbeda.',
            Icons.search_off_rounded,
          )
        else
          ...filtered.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ExpenseTile(
                entry: entry,
                onTap: () => _isSelectingExpenses
                    ? _toggleExpenseSelection(entry.id)
                    : _showExpenseForm(entry: entry),
                onDelete: () => _deleteExpense(entry),
                selectable: _isSelectingExpenses,
                selected: _selectedExpenseIds.contains(entry.id),
                onSelect: () => _toggleExpenseSelection(entry.id),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDebtList({required Key key}) {
    final query = _debtQuery.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _debts
        : _debts.where((item) {
            final haystack =
                '${item.person} ${item.contactPhone ?? ''} ${item.note}'
                    .toLowerCase();
            return haystack.contains(query);
          }).toList();
    final suggestions = query.isEmpty
        ? <DebtEntry>[]
        : filtered.take(6).toList();
    final colors = Theme.of(context).colorScheme;
    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 108),
      children: [
        PageHeading(
          title: 'Hutang & piutang',
          subtitle: 'Jaga semua janji tetap tercatat',
        ),
        const SizedBox(height: 18),
        _buildDebtSummary(colors),
        const SizedBox(height: 18),
        TextField(
          controller: _debtSearchController,
          onChanged: (value) => setState(() => _debtQuery = value),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: 'Cari catatan hutang',
            hintText: 'Nama, nomor kontak, atau catatan',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _debtQuery.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Bersihkan pencarian',
                    onPressed: () {
                      _debtSearchController.clear();
                      setState(() => _debtQuery = '');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: suggestions.isEmpty
              ? const SizedBox.shrink(key: ValueKey('no-suggestions'))
              : Container(
                  key: const ValueKey('suggestions'),
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: colors.outline.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Column(
                    children: suggestions
                        .map(
                          (entry) => ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: colors.primary.withValues(
                                alpha: 0.1,
                              ),
                              child: Icon(
                                Icons.person_outline_rounded,
                                size: 18,
                                color: colors.primary,
                              ),
                            ),
                            title: Text(
                              entry.person,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              entry.contactPhone?.isNotEmpty == true
                                  ? entry.contactPhone!
                                  : 'Nomor tidak tersimpan',
                            ),
                            trailing: Text(
                              formatCurrency(entry.amount),
                              style: TextStyle(
                                color: entry.kind == DebtKind.payable
                                    ? semanticError
                                    : semanticMint,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            onTap: () {
                              _debtSearchController.text = entry.person;
                              setState(() => _debtQuery = entry.person);
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
        ),
        const SizedBox(height: 18),
        if (_debts.isEmpty)
          _buildEmptyCard(
            'Belum ada catatan hutang',
            'Tambahkan siapa, jumlahnya, dan kapan harus selesai.',
            Icons.handshake_outlined,
          )
        else if (filtered.isEmpty)
          _buildEmptyCard(
            'Tidak ditemukan',
            'Coba cari dengan nama, nomor telepon, atau kata di catatan.',
            Icons.search_off_rounded,
          )
        else ...[
          _buildDebtSection(
            title: 'Dipinjam Orang',
            subtitle: 'Uang yang perlu kamu terima',
            entries: filtered
                .where((item) => item.kind == DebtKind.receivable)
                .toList(),
            color: semanticMint,
          ),
          const SizedBox(height: 22),
          _buildDebtSection(
            title: 'Saya Berhutang',
            subtitle: 'Uang yang perlu kamu bayarkan',
            entries: filtered
                .where((item) => item.kind == DebtKind.payable)
                .toList(),
            color: semanticError,
          ),
        ],
      ],
    );
  }

  Widget _buildDebtSection({
    required String title,
    required String subtitle,
    required List<DebtEntry> entries,
    required Color color,
  }) {
    final activeCount = entries.where((item) => !item.isSettled).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: 0.58),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$activeCount aktif',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (entries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline
                    .withValues(alpha: 0.65),
              ),
            ),
            child: Text(
              'Belum ada catatan di bagian ini.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.58),
                fontSize: 13,
              ),
            ),
          )
        else
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DebtTile(
                entry: entry,
                onToggle: () => _toggleDebt(entry),
                onTap: () => _showDebtForm(entry: entry),
                onDelete: () => _deleteDebt(entry),
                onCommunicate: () => _openCommunication(entry),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDebtSummary(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline.withValues(alpha: 0.65)),
      ),
      child: Row(
        children: [
          Expanded(
            child: DebtAmount(
              label: 'Hutang',
              amount: _payable,
              color: semanticError,
              icon: Icons.arrow_upward_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 42,
            color: colors.outline.withValues(alpha: 0.7),
          ),
          Expanded(
            child: DebtAmount(
              label: 'Piutang',
              amount: _receivable,
              color: semanticMint,
              icon: Icons.arrow_downward_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String title, String subtitle, IconData icon) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline.withValues(alpha: 0.65)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 38, color: colors.primary.withValues(alpha: 0.7)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.6),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}





enum RestoreMode { merge, replace }





