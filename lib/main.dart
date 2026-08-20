import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image_editor_plus/image_editor_plus.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'models/finance_models.dart';
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
import 'models/reminder_models.dart';
import 'models/advanced_finance_models.dart';
import 'widgets/reminder_settings_sheet.dart';
import 'widgets/dashboard_image_rail.dart';
import 'widgets/data_tools_sheet.dart';
import 'widgets/advanced_finance_sheets.dart';
import 'widgets/analytics_sheet.dart';
import 'widgets/expense_filter_dialog.dart';

import 'package:share_plus/share_plus.dart';
import 'package:home_widget/home_widget.dart';

const _indigo = Color(0xFFF54E00); // Cursor Orange
const _indigoDark = Color(0xFFD04200); // Cursor Orange active
const _coral = Color(0xFFCF2D56); // semantic error
const _mint = Color(0xFF1F8A65); // semantic success
const _ink = Color(0xFF26251E);
const _slate = Color(0xFF5A5852);
const _lightBackground = Color(0xFFF7F7F4); // warm cream canvas
const _darkBackground = Color(0xFF26251E);
const _darkSurface = Color(0xFF333129);

bool _privacyMode = false;

String formatCurrency(double value) => _formatCurrency(value);

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
          seedColor: _indigo,
          brightness: brightness,
        ).copyWith(
          primary: isDark ? const Color(0xFFFF7A3D) : _indigo,
          onPrimary: Colors.white,
          secondary: isDark ? const Color(0xFFFFA47A) : _mint,
          onSecondary: Colors.white,
          surface: isDark ? _darkSurface : const Color(0xFFFFFFFF),
          onSurface: isDark ? const Color(0xFFF7F7F4) : _ink,
          surfaceContainerHighest: isDark
              ? const Color(0xFF48453C)
              : const Color(0xFFE6E5E0),
          outline: isDark ? const Color(0xFF625F55) : const Color(0xFFE6E5E0),
          error: _coral,
        );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? _darkBackground : _lightBackground,
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
        labelStyle: TextStyle(color: isDark ? const Color(0xFFA8B5C9) : _slate),
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

enum FinanceTab { overview, expenses, debts }

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
  ExpenseFilter _expenseFilter = const ExpenseFilter();
  List<String> _dashboardImageUrls = const <String>[];
  bool _imageFeedLoading = false;
  bool _imageFeedFromCache = false;
  bool _privacyEnabled = false;
  double _pocketMoney = 0;
  FinanceTab _tab = FinanceTab.overview;
  bool _isLoading = true;
  final _debtSearchController = TextEditingController();
  final _expenseSearchController = TextEditingController();
  String _debtQuery = '';
  String _expenseQuery = '';

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
    final privacy = await _storage.loadPrivacyMode();
    final generated = _advancedService.materializeDueRecurring(
      recurring: recurring,
      now: DateTime.now(),
      existing: expenses,
    );
    if (generated.isNotEmpty) {
      expenses.addAll(generated);
      await _storage.saveExpenses(expenses);
    }
    try {
      await ReminderService.instance.syncAll(reminders);
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
      _privacyEnabled = privacy;
      _privacyMode = privacy;
      _isLoading = false;
    });
    await _syncHomeWidget();
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
        _formatCurrency(monthExpense),
      );
      await HomeWidget.saveWidgetData<String>(
        'pocket_money',
        _formatCurrency(_remainingPocketMoney),
      );
      await HomeWidget.saveWidgetData<String>(
        'total_balance',
        _formatCurrency(totalBalance),
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

  List<ExpenseEntry> _remapExpenseAccounts(
    Iterable<ExpenseEntry> expenses,
    Map<String, String> idMap,
  ) => expenses
      .map(
        (entry) => entry.accountId != null && idMap[entry.accountId] != null
            ? entry.copyWith(accountId: idMap[entry.accountId])
            : entry,
      )
      .toList();

  List<RecurringExpense> _remapRecurringAccounts(
    Iterable<RecurringExpense> items,
    Map<String, String> idMap,
  ) => items
      .map(
        (item) => item.accountId != null && idMap[item.accountId] != null
            ? item.copyWith(accountId: idMap[item.accountId])
            : item,
      )
      .toList();

  double get _totalExpense =>
      _expenses.fold(0, (sum, item) => sum + item.amount);
  double get _pocketMoneyExpense => _expenses
      .where((item) => item.accountId == null)
      .fold(0, (sum, item) => sum + item.amount);
  double get _remainingPocketMoney => _pocketMoney - _pocketMoneyExpense;
  double get _payable => _debts
      .where((item) => item.kind == DebtKind.payable && !item.isSettled)
      .fold(0, (sum, item) => sum + item.amount);
  double get _receivable => _debts
      .where((item) => item.kind == DebtKind.receivable && !item.isSettled)
      .fold(0, (sum, item) => sum + item.amount);

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
      _privacyMode = _privacyEnabled;
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
      await ReminderService.instance.syncAll(updated);
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
                Navigator.pop(dialogContext, _parseAmount(controller.text)),
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
    if (result == null) return;
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
    if (result == null) return;
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
    await _imageService.delete(entry.imagePath);
    if (!mounted) return;
    _showUndoSnackBar('Pengeluaran dihapus', () {
      setState(() => _expenses = [entry, ..._expenses]);
      _saveExpenses();
    });
  }

  Future<void> _deleteDebt(DebtEntry entry) async {
    setState(() => _debts.removeWhere((item) => item.id == entry.id));
    await _saveDebts();
    await _imageService.delete(entry.imagePath);
    if (!mounted) return;
    _showUndoSnackBar('Catatan hutang dihapus', () {
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
      final payload = await _transferService.pickAndRestore();
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
          _privacyEnabled = payload.privacyMode;
          _privacyMode = _privacyEnabled;
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
          if (payload.privacyMode) {
            _privacyEnabled = true;
            _privacyMode = true;
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
      await _storage.savePrivacyMode(_privacyEnabled);
      try {
        await ReminderService.instance.syncAll(_reminders);
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

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ThemeSettingsSheet(
        selected: widget.themeMode,
        onSelected: widget.onThemeModeChanged,
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
                onBackup: _createBackup,
                onDrive: _backupToGoogleDrive,
                onRestore: _restoreBackup,
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
            tooltip: 'Tema',
            onPressed: _openSettings,
            icon: const Icon(Icons.tune_rounded),
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
        ],
      ),
      floatingActionButton: _buildFab(colors),
    );
  }

  Widget? _buildFab(ColorScheme colors) {
    final isDebt = _tab == FinanceTab.debts;
    return FloatingActionButton.extended(
      heroTag: 'finance-fab',
      onPressed: isDebt ? _showDebtForm : _showExpenseForm,
      backgroundColor: isDebt ? _mint : colors.primary,
      foregroundColor: Colors.white,
      icon: Icon(isDebt ? Icons.add_card_rounded : Icons.add_rounded),
      label: Text(
        isDebt ? 'Tambah hutang' : 'Catat pengeluaran',
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
    }
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
                child: _MetricCard(
                  label: 'Hutang kita',
                  value: _formatCurrency(_payable),
                  icon: Icons.arrow_upward_rounded,
                  color: _coral,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'Piutang kita',
                  value: _formatCurrency(_receivable),
                  icon: Icons.arrow_downward_rounded,
                  color: _mint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          _SectionHeader(
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
                child: _ExpenseTile(
                  entry: item.value,
                  onTap: () => _showExpenseForm(entry: item.value),
                  onDelete: () => _deleteExpense(item.value),
                ),
              ),
            ),
          const SizedBox(height: 10),
          _SectionHeader(
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
                        ? _formatCurrency(_pocketMoney)
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
                          ? 'Melebihi ${_formatCurrency(remaining.abs())}'
                          : 'Sisa Uang Saku ${_formatCurrency(remaining)}',
                      style: TextStyle(
                        color: isOver ? colors.error : _mint,
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
                                  : _formatCurrency(account.balance),
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
                    ? 'Melebihi ${_formatCurrency(status.remaining.abs())}'
                    : 'Sisa ${_formatCurrency(status.remaining)}',
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
          border: Border.all(color: _indigoDark.withValues(alpha: 0.45)),
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
              _formatCurrency(thisMonth),
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
                  _formatCurrency(_totalExpense),
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
        _PageHeading(
          title: 'Riwayat pengeluaran',
          subtitle:
              '${filtered.length} dari ${_expenses.length} transaksi tercatat',
        ),
        const SizedBox(height: 14),
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
              child: _ExpenseTile(
                entry: entry,
                onTap: () => _showExpenseForm(entry: entry),
                onDelete: () => _deleteExpense(entry),
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
        _PageHeading(
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
                              _formatCurrency(entry.amount),
                              style: TextStyle(
                                color: entry.kind == DebtKind.payable
                                    ? _coral
                                    : _mint,
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
            color: _mint,
          ),
          const SizedBox(height: 22),
          _buildDebtSection(
            title: 'Saya Berhutang',
            subtitle: 'Uang yang perlu kamu bayarkan',
            entries: filtered
                .where((item) => item.kind == DebtKind.payable)
                .toList(),
            color: _coral,
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
              child: _DebtTile(
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
            child: _DebtAmount(
              label: 'Hutang',
              amount: _payable,
              color: _coral,
              icon: Icons.arrow_upward_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 42,
            color: colors.outline.withValues(alpha: 0.7),
          ),
          Expanded(
            child: _DebtAmount(
              label: 'Piutang',
              amount: _receivable,
              color: _mint,
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

class _PageHeading extends StatelessWidget {
  const _PageHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: colors.onSurface.withValues(alpha: 0.62),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline.withValues(alpha: 0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 13),
          Text(
            label,
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.62),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtAmount extends StatelessWidget {
  const _DebtAmount({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatCurrency(amount),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedCardEntry extends StatelessWidget {
  const _AnimatedCardEntry({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 10),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });
  final ExpenseEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _AnimatedCardEntry(
      child: Dismissible(
        key: ValueKey(entry.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => _confirmDeleteEntry(context, entry),
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 22),
          decoration: BoxDecoration(
            color: colors.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.delete_outline_rounded, color: colors.error),
        ),
        child: Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  _CategoryIcon(category: entry.category),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${_categoryLabel(entry.category)} • ${_formatDate(entry.date)}',
                          style: TextStyle(
                            color: colors.onSurface.withValues(alpha: 0.58),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatCurrency(entry.amount),
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (entry.imagePath != null) ...[
                        const SizedBox(height: 5),
                        Icon(
                          Icons.image_outlined,
                          size: 14,
                          color: colors.primary,
                        ),
                      ],
                    ],
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

class _DebtTile extends StatelessWidget {
  const _DebtTile({
    required this.entry,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
    required this.onCommunicate,
  });
  final DebtEntry entry;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onCommunicate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = entry.kind == DebtKind.payable ? _coral : _mint;
    return _AnimatedCardEntry(
      child: Dismissible(
        key: ValueKey(entry.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => _confirmDeleteEntry(context, entry),
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 22),
          decoration: BoxDecoration(
            color: colors.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.delete_outline_rounded, color: colors.error),
        ),
        child: Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 12, 12),
              child: Row(
                children: [
                  Checkbox(
                    value: entry.isSettled,
                    onChanged: (_) => onToggle(),
                    activeColor: _mint,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.13),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      entry.kind == DebtKind.payable
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: color,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.person,
                          style: TextStyle(
                            color: entry.isSettled
                                ? colors.onSurface.withValues(alpha: 0.45)
                                : colors.onSurface,
                            fontWeight: FontWeight.w800,
                            decoration: entry.isSettled
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (entry.contactPhone?.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            entry.contactPhone!,
                            style: TextStyle(
                              color: colors.onSurface.withValues(alpha: 0.5),
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          '${entry.kind == DebtKind.payable ? 'Hutang' : 'Piutang'} • ${entry.dueDate == null ? 'Tanpa tenggat' : 'Jatuh tempo ${_formatDate(entry.dueDate!)}'}',
                          style: TextStyle(
                            color: colors.onSurface.withValues(alpha: 0.58),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: entry.contactPhone?.isNotEmpty == true
                        ? 'Kirim pesan'
                        : 'Pilih kontak terlebih dahulu',
                    onPressed: onCommunicate,
                    icon: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 19,
                      color: entry.contactPhone?.isNotEmpty == true
                          ? colors.primary
                          : colors.onSurface.withValues(alpha: 0.28),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    _formatCurrency(entry.amount),
                    style: TextStyle(
                      color: entry.isSettled
                          ? colors.onSurface.withValues(alpha: 0.45)
                          : color,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
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

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.category});
  final ExpenseCategory category;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = _categoryColor(category, colors);
    return Container(
      width: 43,
      height: 43,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(_categoryIcon(category), color: color, size: 21),
    );
  }
}

class ExpenseFormSheet extends StatefulWidget {
  const ExpenseFormSheet({
    super.key,
    this.entry,
    required this.imageService,
    required this.accounts,
  });
  final ExpenseEntry? entry;
  final ImageAttachmentService imageService;
  final List<MoneyAccount> accounts;

  @override
  State<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<ExpenseFormSheet> {
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late ExpenseCategory _category;
  late DateTime _date;
  String? _imagePath;
  String? _accountId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.entry?.title ?? '');
    _amount = TextEditingController(
      text: widget.entry == null ? '' : widget.entry!.amount.toStringAsFixed(0),
    );
    _note = TextEditingController(text: widget.entry?.note ?? '');
    _category = widget.entry?.category ?? ExpenseCategory.food;
    _date = widget.entry?.date ?? DateTime.now();
    _imagePath = widget.entry?.imagePath;
    _accountId = widget.entry?.accountId;
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _chooseImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => _ImageSourceSheet(
        onSelected: (value) => Navigator.pop(sheetContext, value),
      ),
    );
    if (source == null || !mounted) return;
    final newPath = await _pickEditStoreImage(
      context,
      widget.imageService,
      source,
    );
    if (newPath == null) return;
    if (_imagePath != null && _imagePath != newPath)
      await widget.imageService.delete(_imagePath);
    if (mounted) setState(() => _imagePath = newPath);
  }

  Future<void> _removeImage() async {
    await widget.imageService.delete(_imagePath);
    if (mounted) setState(() => _imagePath = null);
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Pilih tanggal transaksi',
    );
    if (selected != null && mounted) setState(() => _date = selected);
  }

  void _save() {
    final title = _title.text.trim();
    final amount = _parseAmount(_amount.text);
    if (title.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi nama transaksi dan nominal yang valid.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    Navigator.pop(
      context,
      ExpenseEntry(
        id: widget.entry?.id ?? _newId(),
        title: title,
        amount: amount,
        category: _category,
        date: _date,
        note: _note.text.trim(),
        imagePath: _imagePath,
        accountId: _accountId,
        recurringId: widget.entry?.recurringId,
        createdAt: widget.entry?.createdAt ?? DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _SheetShell(
      title: widget.entry == null ? 'Catat pengeluaran' : 'Edit pengeluaran',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Untuk apa pengeluaran ini?',
              hintText: 'Contoh: Makan siang, ongkos, pulsa',
            ),
          ),
          const SizedBox(height: 13),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Nominal',
              prefixText: 'Rp  ',
              hintText: '0',
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<ExpenseCategory>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: ExpenseCategory.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(_categoryLabel(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(15),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(_formatDate(_date)),
                  ),
                ),
              ),
            ],
          ),
          if (widget.accounts.isNotEmpty) ...[
            const SizedBox(height: 13),
            DropdownButtonFormField<String>(
              initialValue: _accountId,
              decoration: const InputDecoration(labelText: 'Sumber dana'),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Uang Saku'),
                ),
                ...widget.accounts
                    .where((item) => !item.isArchived)
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.name),
                      ),
                    ),
              ],
              onChanged: (value) => setState(() => _accountId = value),
            ),
          ],
          const SizedBox(height: 13),
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Catatan (opsional)',
              hintText: 'Tambahkan detail transaksi',
            ),
          ),
          const SizedBox(height: 15),
          _PhotoAttachment(
            path: _imagePath,
            onAdd: _chooseImage,
            onRemove: _removeImage,
            colors: colors,
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 53,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(
                widget.entry == null
                    ? 'Simpan pengeluaran'
                    : 'Simpan perubahan',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DebtFormSheet extends StatefulWidget {
  const DebtFormSheet({
    super.key,
    this.entry,
    required this.imageService,
    required this.contactService,
  });
  final DebtEntry? entry;
  final ImageAttachmentService imageService;
  final ContactService contactService;

  @override
  State<DebtFormSheet> createState() => _DebtFormSheetState();
}

class _DebtFormSheetState extends State<DebtFormSheet> {
  late final TextEditingController _person;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late DebtKind _kind;
  late DateTime _date;
  DateTime? _dueDate;
  String? _imagePath;
  String? _contactId;
  String? _contactPhone;
  bool _contactBusy = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _person = TextEditingController(text: widget.entry?.person ?? '');
    _amount = TextEditingController(
      text: widget.entry == null ? '' : widget.entry!.amount.toStringAsFixed(0),
    );
    _note = TextEditingController(text: widget.entry?.note ?? '');
    _kind = widget.entry?.kind ?? DebtKind.payable;
    _date = widget.entry?.date ?? DateTime.now();
    _dueDate = widget.entry?.dueDate;
    _imagePath = widget.entry?.imagePath;
    _contactId = widget.entry?.contactId;
    _contactPhone = widget.entry?.contactPhone;
  }

  @override
  void dispose() {
    _person.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _chooseImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => _ImageSourceSheet(
        onSelected: (value) => Navigator.pop(sheetContext, value),
      ),
    );
    if (source == null || !mounted) return;
    final newPath = await _pickEditStoreImage(
      context,
      widget.imageService,
      source,
    );
    if (newPath == null) return;
    if (_imagePath != null && _imagePath != newPath)
      await widget.imageService.delete(_imagePath);
    if (mounted) setState(() => _imagePath = newPath);
  }

  Future<void> _removeImage() async {
    await widget.imageService.delete(_imagePath);
    if (mounted) setState(() => _imagePath = null);
  }

  Future<void> _pickContact() async {
    setState(() => _contactBusy = true);
    try {
      final selected = await widget.contactService.pickContact();
      if (!mounted) return;
      if (selected == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Kontak tidak dipilih atau izin kontak belum diberikan.',
            ),
          ),
        );
        return;
      }
      setState(() {
        _contactId = selected.id;
        _contactPhone = selected.phone;
        _person.text = selected.name;
      });
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kontak belum bisa diakses. Coba lagi.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _contactBusy = false);
    }
  }

  void _clearContact() {
    setState(() {
      _contactId = null;
      _contactPhone = null;
    });
  }

  Future<void> _pickDate({required bool due}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: due ? (_dueDate ?? _date) : _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: due ? 'Pilih jatuh tempo' : 'Pilih tanggal hutang',
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (due) {
        _dueDate = selected;
      } else {
        _date = selected;
      }
    });
  }

  void _save() {
    final person = _person.text.trim();
    final amount = _parseAmount(_amount.text);
    if (person.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi nama orang dan nominal yang valid.')),
      );
      return;
    }
    setState(() => _saving = true);
    Navigator.pop(
      context,
      DebtEntry(
        id: widget.entry?.id ?? _newId(),
        person: person,
        amount: amount,
        kind: _kind,
        date: _date,
        dueDate: _dueDate,
        note: _note.text.trim(),
        imagePath: _imagePath,
        contactId: _contactId,
        contactPhone: _contactPhone,
        isSettled: widget.entry?.isSettled ?? false,
        createdAt: widget.entry?.createdAt ?? DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _SheetShell(
      title: widget.entry == null ? 'Tambah hutang' : 'Edit catatan hutang',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<DebtKind>(
            segments: const [
              ButtonSegment(
                value: DebtKind.payable,
                label: Text('Saya berhutang'),
                icon: Icon(Icons.arrow_upward_rounded),
              ),
              ButtonSegment(
                value: DebtKind.receivable,
                label: Text('Dipinjam orang'),
                icon: Icon(Icons.arrow_downward_rounded),
              ),
            ],
            selected: {_kind},
            onSelectionChanged: (value) => setState(() => _kind = value.first),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _person,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Nama orang',
              hintText: 'Ketik manual atau pilih kontak',
              suffixIcon: _contactBusy
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      tooltip: 'Pilih dari kontak',
                      onPressed: _pickContact,
                      icon: const Icon(Icons.contacts_outlined),
                    ),
            ),
          ),
          if (_contactId != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 18,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _contactPhone?.isNotEmpty == true
                          ? _contactPhone!
                          : 'Nomor tidak tersedia',
                      style: TextStyle(
                        color: colors.onSurface.withValues(alpha: 0.68),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _clearContact,
                    child: const Text(
                      'Lepas',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 13),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Nominal',
              prefixText: 'Rp  ',
              hintText: '0',
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(due: false),
                  borderRadius: BorderRadius.circular(15),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal',
                      suffixIcon: Icon(Icons.event_outlined),
                    ),
                    child: Text(_formatDate(_date)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(due: true),
                  borderRadius: BorderRadius.circular(15),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Jatuh tempo',
                      suffixIcon: _dueDate == null
                          ? const Icon(Icons.event_available_outlined)
                          : IconButton(
                              onPressed: () => setState(() => _dueDate = null),
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                    child: Text(
                      _dueDate == null ? 'Opsional' : _formatDate(_dueDate!),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Catatan (opsional)',
              hintText: 'Tambahkan konteks atau janji pembayaran',
            ),
          ),
          const SizedBox(height: 15),
          _PhotoAttachment(
            path: _imagePath,
            onAdd: _chooseImage,
            onRemove: _removeImage,
            colors: colors,
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 53,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: _kind == DebtKind.payable ? _coral : _mint,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(
                widget.entry == null ? 'Simpan catatan' : 'Simpan perubahan',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Material(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 13, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outline,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 19),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoAttachment extends StatelessWidget {
  const _PhotoAttachment({
    required this.path,
    required this.onAdd,
    required this.onRemove,
    required this.colors,
  });
  final String? path;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final hasImage = path != null && path!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lampiran foto',
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (hasImage)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: Image.file(
                    File(path!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: colors.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
                Positioned(
                  top: 9,
                  right: 9,
                  child: Row(
                    children: [
                      IconButton.filled(
                        tooltip: 'Ganti foto',
                        onPressed: onAdd,
                        icon: const Icon(Icons.edit_rounded, size: 18),
                      ),
                      const SizedBox(width: 5),
                      IconButton.filled(
                        tooltip: 'Hapus foto',
                        onPressed: onRemove,
                        style: IconButton.styleFrom(
                          backgroundColor: colors.error,
                        ),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              height: 82,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.26),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: colors.primary),
                  const SizedBox(height: 5),
                  Text(
                    'Tambah foto dari galeri atau kamera',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ImageSourceSheet extends StatelessWidget {
  const _ImageSourceSheet({required this.onSelected});
  final ValueChanged<ImageSource> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outline,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 17),
            Text(
              'Pilih sumber foto',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SourceButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Galeri',
                    onTap: () => onSelected(ImageSource.gallery),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SourceButton(
                    icon: Icons.photo_camera_outlined,
                    label: 'Kamera',
                    onTap: () => onSelected(ImageSource.camera),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 19),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: colors.primary, size: 28),
            const SizedBox(height: 7),
            Text(
              label,
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum RestoreMode { merge, replace }

enum CommunicationChannel { whatsapp, sms }

class CommunicationRequest {
  const CommunicationRequest({required this.channel, required this.message});

  final CommunicationChannel channel;
  final String message;
}

class CommunicationSheet extends StatefulWidget {
  const CommunicationSheet({super.key, required this.entry});
  final DebtEntry entry;

  @override
  State<CommunicationSheet> createState() => _CommunicationSheetState();
}

class _CommunicationSheetState extends State<CommunicationSheet> {
  late final TextEditingController _message;
  CommunicationChannel _channel = CommunicationChannel.whatsapp;

  @override
  void initState() {
    super.initState();
    _message = TextEditingController(text: _defaultDebtMessage(widget.entry));
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  void _submit() {
    final message = _message.text.trim();
    if (message.isEmpty) return;
    Navigator.pop(
      context,
      CommunicationRequest(channel: _channel, message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isWhatsApp = _channel == CommunicationChannel.whatsapp;
    return _SheetShell(
      title: 'Kirim pengingat',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  color: colors.primary,
                  size: 20,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.entry.person,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.entry.contactPhone ?? '',
                        style: TextStyle(
                          color: colors.onSurface.withValues(alpha: 0.58),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          SegmentedButton<CommunicationChannel>(
            segments: const [
              ButtonSegment(
                value: CommunicationChannel.whatsapp,
                label: Text('WhatsApp'),
                icon: Icon(Icons.chat_rounded),
              ),
              ButtonSegment(
                value: CommunicationChannel.sms,
                label: Text('SMS'),
                icon: Icon(Icons.sms_outlined),
              ),
            ],
            selected: {_channel},
            onSelectionChanged: (value) =>
                setState(() => _channel = value.first),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _message,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Pesan',
              alignLabelWithHint: true,
              hintText: 'Tulis pesan pengingat...',
            ),
          ),
          const SizedBox(height: 19),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: isWhatsApp
                    ? const Color(0xFF16A085)
                    : colors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(isWhatsApp ? Icons.chat_rounded : Icons.sms_rounded),
              label: Text(
                isWhatsApp ? 'Buka WhatsApp' : 'Buka aplikasi SMS',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _defaultDebtMessage(DebtEntry entry) {
  final due = entry.dueDate == null
      ? ''
      : ' Jatuh tempo yang tercatat adalah ${_formatDate(entry.dueDate!)}.';
  if (entry.kind == DebtKind.payable) {
    return 'Halo ${entry.person}, saya ingin mengabari tentang hutang saya sebesar ${_formatCurrency(entry.amount)}.$due Terima kasih.';
  }
  return 'Halo ${entry.person}, izin mengingatkan tentang hutang sebesar ${_formatCurrency(entry.amount)}.$due Mohon kabari jika sudah ada waktu pembayarannya. Terima kasih.';
}

class ThemeSettingsSheet extends StatelessWidget {
  const ThemeSettingsSheet({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  final ThemeMode selected;
  final ValueChanged<ThemeMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final options = [
      (ThemeMode.system, 'Ikuti sistem', Icons.brightness_auto_rounded),
      (ThemeMode.light, 'Terang', Icons.light_mode_rounded),
      (ThemeMode.dark, 'Gelap', Icons.dark_mode_rounded),
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outline,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Tampilan aplikasi',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Pilih tema yang paling nyaman untukmu.',
              style: TextStyle(
                color: colors.onSurface.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 13),
            RadioGroup<ThemeMode>(
              groupValue: selected,
              onChanged: (value) {
                if (value != null) {
                  onSelected(value);
                  Navigator.pop(context);
                }
              },
              child: Column(
                children: options
                    .map(
                      (option) => RadioListTile<ThemeMode>(
                        value: option.$1,
                        title: Text(
                          option.$2,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        secondary: Icon(option.$3, color: colors.primary),
                        activeColor: colors.primary,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CalculatorSheet extends StatefulWidget {
  const CalculatorSheet({super.key});

  @override
  State<CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends State<CalculatorSheet> {
  String _expression = '';
  String _result = '0';

  void _tap(String value) {
    setState(() {
      if (value == 'C') {
        _expression = '';
        _result = '0';
      } else if (value == '⌫') {
        if (_expression.isNotEmpty)
          _expression = _expression.substring(0, _expression.length - 1);
      } else if (value == '=') {
        final calculated = _calculateExpression(_expression);
        if (calculated != null) _result = _formatNumber(calculated);
      } else {
        _expression += value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const keys = [
      'C',
      '⌫',
      '÷',
      '×',
      '7',
      '8',
      '9',
      '−',
      '4',
      '5',
      '6',
      '+',
      '1',
      '2',
      '3',
      '=',
      '00',
      '0',
      '.',
      '',
    ];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Material(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 13, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.outline,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 19),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Kalkulator cepat',
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 15, 18, 18),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _expression.isEmpty ? 'Masukkan angka' : _expression,
                        style: TextStyle(
                          color: colors.onSurface.withValues(alpha: 0.55),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        _result,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 31,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 13),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: keys.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 9,
                    mainAxisSpacing: 9,
                    childAspectRatio: 1.55,
                  ),
                  itemBuilder: (context, index) {
                    final label = keys[index];
                    if (label.isEmpty) return const SizedBox.shrink();
                    final isAction = [
                      'C',
                      '⌫',
                      '÷',
                      '×',
                      '−',
                      '+',
                      '=',
                    ].contains(label);
                    return FilledButton(
                      onPressed: () => _tap(label),
                      style: FilledButton.styleFrom(
                        backgroundColor: label == '='
                            ? colors.primary
                            : isAction
                            ? colors.primary.withValues(alpha: 0.13)
                            : colors.surfaceContainerHighest,
                        foregroundColor: label == '='
                            ? Colors.white
                            : colors.onSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: label == '⌫' ? 18 : 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

double? _calculateExpression(String expression) {
  if (expression.isEmpty) return null;
  final tokens = RegExp(r'\d+(?:\.\d+)?|[+\-×÷]')
      .allMatches(expression)
      .map((match) => match.group(0)!)
      .toList();
  if (tokens.isEmpty ||
      tokens.first.length == 1 && '+−×÷'.contains(tokens.first))
    return null;
  try {
    final values = <double>[double.parse(tokens.first)];
    final lowOperators = <String>[];
    for (var index = 1; index < tokens.length - 1; index += 2) {
      final operator = tokens[index];
      final number = double.parse(tokens[index + 1]);
      if (operator == '×' || operator == '÷') {
        if (operator == '÷' && number == 0) return null;
        values[values.length - 1] = operator == '×'
            ? values.last * number
            : values.last / number;
      } else {
        values.add(number);
        lowOperators.add(operator);
      }
    }
    var result = values.first;
    for (var index = 0; index < lowOperators.length; index++) {
      result = lowOperators[index] == '+'
          ? result + values[index + 1]
          : result - values[index + 1];
    }
    return result.isFinite ? result : null;
  } catch (_) {
    return null;
  }
}

Future<bool> _confirmDeleteEntry(BuildContext context, Object entry) async {
  final label = entry is ExpenseEntry
      ? entry.title
      : entry is DebtEntry
      ? entry.person
      : 'catatan ini';
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Hapus catatan?'),
      content: Text(
        'Catatan "$label" akan dihapus. Tindakan ini tidak bisa dibatalkan dari daftar utama.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<String?> _pickEditStoreImage(
  BuildContext context,
  ImageAttachmentService service,
  ImageSource source,
) async {
  final pickedPath = await service.pickAndStore(source: source);
  if (pickedPath == null) return null;
  final bytes = await File(pickedPath).readAsBytes();
  if (!context.mounted) return pickedPath;
  final edited = await Navigator.push<Uint8List>(
    context,
    MaterialPageRoute(builder: (_) => ImageEditor(image: bytes)),
  );
  if (edited == null) return pickedPath;
  final editedPath = await service.storeBytes(edited);
  await service.delete(pickedPath);
  return editedPath;
}

String _formatCurrency(double value) =>
    _privacyMode ? '••••••' : 'Rp ${_formatNumber(value)}';
String _formatNumber(double value) {
  final fixed = value.round().toString();
  return fixed.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => '.',
  );
}

double _parseAmount(String raw) {
  final normalized = raw
      .trim()
      .replaceAll(' ', '')
      .replaceAll('.', '')
      .replaceAll(',', '.');
  return double.tryParse(normalized) ?? 0;
}

String _newId() =>
    '${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(9999)}';

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _categoryLabel(ExpenseCategory category) {
  const labels = {
    ExpenseCategory.food: 'Makanan',
    ExpenseCategory.transport: 'Transportasi',
    ExpenseCategory.shopping: 'Belanja',
    ExpenseCategory.bills: 'Tagihan',
    ExpenseCategory.health: 'Kesehatan',
    ExpenseCategory.entertainment: 'Hiburan',
    ExpenseCategory.other: 'Lainnya',
  };
  return labels[category]!;
}

IconData _categoryIcon(ExpenseCategory category) {
  const icons = {
    ExpenseCategory.food: Icons.restaurant_rounded,
    ExpenseCategory.transport: Icons.directions_car_filled_rounded,
    ExpenseCategory.shopping: Icons.shopping_bag_rounded,
    ExpenseCategory.bills: Icons.receipt_rounded,
    ExpenseCategory.health: Icons.medical_services_rounded,
    ExpenseCategory.entertainment: Icons.movie_rounded,
    ExpenseCategory.other: Icons.more_horiz_rounded,
  };
  return icons[category]!;
}

Color _categoryColor(ExpenseCategory category, ColorScheme colors) {
  const palette = {
    ExpenseCategory.food: Color(0xFFF97316),
    ExpenseCategory.transport: Color(0xFF3B82F6),
    ExpenseCategory.shopping: Color(0xFF8B5CF6),
    ExpenseCategory.bills: Color(0xFF0EA5E9),
    ExpenseCategory.health: Color(0xFFEF4444),
    ExpenseCategory.entertainment: Color(0xFFEC4899),
    ExpenseCategory.other: Color(0xFF64748B),
  };
  return palette[category]!;
}
