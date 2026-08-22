import 'package:flutter/material.dart';

import '../core/format.dart';
import '../models/advanced_finance_models.dart';
import '../models/finance_models.dart';
import '../models/json_helpers.dart';
import '../services/finance_feature_service.dart';

class FinanceFeaturesSheet extends StatefulWidget {
  const FinanceFeaturesSheet({
    super.key,
    required this.expenses,
    required this.budgets,
    required this.accounts,
    required this.savings,
    required this.recurring,
    required this.splitBills,
    required this.reconciliationSnapshots,
    required this.merchantRules,
    required this.onQuickAdd,
    required this.onSaveSplitBill,
    required this.onSaveReconciliation,
    required this.onSaveMerchantRule,
    required this.onDeleteMerchantRule,
    required this.onSaveRecurring,
    required this.onOpenSavings,
  });

  final List<ExpenseEntry> expenses;
  final List<BudgetLimit> budgets;
  final List<MoneyAccount> accounts;
  final List<SavingsGoal> savings;
  final List<RecurringExpense> recurring;
  final List<SplitBill> splitBills;
  final List<ReconciliationSnapshot> reconciliationSnapshots;
  final List<MerchantCategoryRule> merchantRules;
  final VoidCallback onQuickAdd;
  final Future<void> Function(SplitBill bill) onSaveSplitBill;
  final Future<void> Function(ReconciliationSnapshot snapshot)
  onSaveReconciliation;
  final Future<void> Function(MerchantCategoryRule rule) onSaveMerchantRule;
  final Future<void> Function(String id) onDeleteMerchantRule;
  final Future<void> Function(RecurringExpense recurring) onSaveRecurring;
  final VoidCallback onOpenSavings;

  @override
  State<FinanceFeaturesSheet> createState() => _FinanceFeaturesSheetState();
}

class _FinanceFeaturesSheetState extends State<FinanceFeaturesSheet> {
  final _splitTitle = TextEditingController();
  final _splitAmount = TextEditingController();
  final _splitPeople = TextEditingController();
  final _reconcileActual = TextEditingController();
  final _reconcileNote = TextEditingController();
  final _rulePattern = TextEditingController();
  String? _selectedAccountId;
  ExpenseCategory _ruleCategory = ExpenseCategory.other;

  @override
  void dispose() {
    _splitTitle.dispose();
    _splitAmount.dispose();
    _splitPeople.dispose();
    _reconcileActual.dispose();
    _reconcileNote.dispose();
    _rulePattern.dispose();
    super.dispose();
  }

  double get _monthSpend {
    final now = DateTime.now();
    return widget.expenses
        .where(
          (item) => item.date.year == now.year && item.date.month == now.month,
        )
        .fold<double>(0, (sum, item) => sum + item.amount);
  }

  double get _businessSpend =>
      FinanceFeatureService.businessSpend(widget.expenses);
  double get _deductibleTax =>
      FinanceFeatureService.deductibleTax(widget.expenses);

  Future<void> _createSplitBill() async {
    final title = _splitTitle.text.trim();
    final amount = parseAmount(_splitAmount.text);
    final names = _splitPeople.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (title.isEmpty || amount <= 0 || names.isEmpty) {
      _showMessage('Isi judul, total, dan minimal satu nama peserta.');
      return;
    }
    final each = roundMoney(amount / names.length);
    final participants = names
        .map((name) => SplitParticipant(id: newId(), name: name, amount: each))
        .toList();
    final adjustment = roundMoney(
      amount - participants.fold<double>(0, (sum, item) => sum + item.amount),
    );
    if (adjustment != 0) {
      participants[0] = participants[0].copyWith(
        amount: roundMoney(participants[0].amount + adjustment),
      );
    }
    await widget.onSaveSplitBill(
      SplitBill(
        id: newId(),
        title: title,
        totalAmount: amount,
        date: DateTime.now(),
        participants: participants,
        createdAt: DateTime.now(),
      ),
    );
    _splitTitle.clear();
    _splitAmount.clear();
    _splitPeople.clear();
    if (mounted) _showMessage('Split bill tersimpan.');
  }

  Future<void> _saveReconciliation() async {
    final accountId = _selectedAccountId;
    final actual = parseAmount(_reconcileActual.text);
    if (accountId == null || actual < 0) {
      _showMessage('Pilih akun dan masukkan saldo aktual yang valid.');
      return;
    }
    await widget.onSaveReconciliation(
      ReconciliationSnapshot(
        id: newId(),
        accountId: accountId,
        checkedAt: DateTime.now(),
        expectedBalance: _expectedBalance(accountId),
        actualBalance: actual,
        note: _reconcileNote.text.trim(),
        createdAt: DateTime.now(),
      ),
    );
    _reconcileActual.clear();
    _reconcileNote.clear();
    if (mounted) _showMessage('Rekonsiliasi saldo tersimpan.');
  }

  double _expectedBalance(String accountId) => widget.accounts
      .where((item) => item.id == accountId)
      .fold<double>(0, (sum, item) => sum + item.balance);

  Future<void> _saveRule() async {
    final pattern = _rulePattern.text.trim();
    if (pattern.isEmpty) {
      _showMessage('Masukkan kata merchant, misalnya "indomaret".');
      return;
    }
    await widget.onSaveMerchantRule(
      MerchantCategoryRule(
        id: newId(),
        pattern: pattern,
        category: _ruleCategory,
        createdAt: DateTime.now(),
      ),
    );
    _rulePattern.clear();
    if (mounted) _showMessage('Aturan kategori tersimpan.');
  }

  Future<void> _showSplitBillDetails(SplitBill bill) async {
    var current = bill;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(current.title),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: current.participants.map((participant) {
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: participant.isPaid,
                  title: Text(participant.name),
                  subtitle: Text(formatCurrency(participant.amount)),
                  onChanged: (value) async {
                    final updated = current.participants
                        .map(
                          (item) => item.id == participant.id
                              ? item.copyWith(isPaid: value ?? false)
                              : item,
                        )
                        .toList();
                    current = current.copyWith(participants: updated);
                    setDialogState(() {});
                    await widget.onSaveSplitBill(current);
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _promoteRecurring(RecurringCandidate candidate) async {
    final exists = widget.recurring.any(
      (item) =>
          item.title.toLowerCase() == candidate.title.toLowerCase() &&
          (item.amount - candidate.amount).abs() < 0.01,
    );
    if (exists) {
      _showMessage('Transaksi ini sudah ada di daftar berulang.');
      return;
    }
    await widget.onSaveRecurring(
      RecurringExpense(
        id: newId(),
        title: candidate.title,
        amount: candidate.amount,
        category: candidate.category,
        note: 'Dibuat dari deteksi transaksi berulang',
        nextDue: DateTime(
          candidate.lastDate.year,
          candidate.lastDate.month + 1,
          candidate.lastDate.day.clamp(1, 28),
        ),
        createdAt: DateTime.now(),
      ),
    );
    if (mounted) _showMessage('Ditambahkan ke transaksi berulang.');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _sectionTitle(String title, String subtitle, IconData icon) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: 0.62),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(Widget child) => Card(
    margin: EdgeInsets.zero,
    child: Padding(padding: const EdgeInsets.all(14), child: child),
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final candidates = FinanceFeatureService.detectRecurring(widget.expenses);
    final activeBudgets = widget.budgets.where((item) => item.enabled).toList();
    final account = _selectedAccountId == null
        ? null
        : widget.accounts
              .where((item) => item.id == _selectedAccountId)
              .firstOrNull;
    final lastReconciliation = _selectedAccountId == null
        ? null
        : widget.reconciliationSnapshots
              .where((item) => item.accountId == _selectedAccountId)
              .toList()
              .firstOrNull;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.94,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outline,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Pusat fitur keuangan',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                'Semua analisis berjalan dari data lokal agar tetap berguna saat offline.',
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.64),
                ),
              ),
              const SizedBox(height: 18),
              _card(
                Row(
                  children: [
                    Icon(Icons.offline_bolt_outlined, color: colors.primary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Mode offline-first aktif\nTransaksi tersimpan lokal dan tidak menunggu koneksi internet.',
                      ),
                    ),
                    Icon(Icons.check_circle, color: colors.primary),
                  ],
                ),
              ),
              _sectionTitle(
                'Transaksi cepat',
                'Buka form pencatatan dari satu tombol.',
                Icons.flash_on_outlined,
              ),
              _card(
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onQuickAdd();
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Catat pengeluaran sekarang'),
                  ),
                ),
              ),
              _sectionTitle(
                'Batas pengeluaran harian',
                'Sisa anggaran bulanan dibagi dengan sisa hari bulan berjalan.',
                Icons.speed_outlined,
              ),
              if (activeBudgets.isEmpty)
                _card(
                  const Text(
                    'Belum ada anggaran kategori. Tambahkan anggaran dari menu Analisis agar batas harian dapat dihitung.',
                  ),
                )
              else
                ...activeBudgets.map((budget) {
                  final spend = widget.expenses
                      .where((item) => item.category == budget.category)
                      .fold<double>(0, (sum, item) => sum + item.amount);
                  final daily = FinanceFeatureService.safeDailyBudget(
                    monthlyLimit: budget.monthlyLimit,
                    monthToDateSpend: spend,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _card(
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(budget.category.label),
                        subtitle: Text(
                          'Terpakai ${formatCurrency(spend)} dari ${formatCurrency(budget.monthlyLimit)}',
                        ),
                        trailing: Text(
                          formatCurrency(daily),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  );
                }),
              _sectionTitle(
                'Deteksi transaksi berulang',
                'Pola nominal dan tanggal yang berulang dapat dijadikan pengingat.',
                Icons.repeat_rounded,
              ),
              if (candidates.isEmpty)
                _card(
                  const Text(
                    'Belum ditemukan pola berulang. Tambahkan transaksi pada beberapa bulan berbeda untuk memperoleh kandidat.',
                  ),
                )
              else
                ...candidates.map(
                  (candidate) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _card(
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          candidate.merchant.isEmpty
                              ? candidate.title
                              : '${candidate.title} • ${candidate.merchant}',
                        ),
                        subtitle: Text(
                          '${candidate.occurrences} kali • ${formatCurrency(candidate.amount)}',
                        ),
                        trailing: IconButton(
                          tooltip: 'Jadikan transaksi berulang',
                          onPressed: () => _promoteRecurring(candidate),
                          icon: const Icon(Icons.add_task_rounded),
                        ),
                      ),
                    ),
                  ),
                ),
              _sectionTitle(
                'Rekonsiliasi saldo',
                'Bandingkan saldo yang tercatat dengan saldo aktual.',
                Icons.fact_check_outlined,
              ),
              _card(
                Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedAccountId,
                      decoration: const InputDecoration(
                        labelText: 'Akun/dompet',
                      ),
                      items: widget.accounts
                          .where((item) => !item.isArchived)
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.id,
                              child: Text(item.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedAccountId = value),
                    ),
                    if (account != null) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Saldo tercatat: ${formatCurrency(_expectedBalance(account.id))}',
                        ),
                      ),
                      if (lastReconciliation != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Selisih terakhir: ${formatCurrency(lastReconciliation.difference)}',
                          ),
                        ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _reconcileActual,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Saldo aktual',
                          prefixText: 'Rp  ',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _reconcileNote,
                        decoration: const InputDecoration(
                          labelText: 'Catatan (opsional)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: _saveReconciliation,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Simpan rekonsiliasi'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _sectionTitle(
                'Split bill',
                'Bagi tagihan secara rata dan pantau pembayaran peserta.',
                Icons.group_outlined,
              ),
              _card(
                Column(
                  children: [
                    TextField(
                      controller: _splitTitle,
                      decoration: const InputDecoration(
                        labelText: 'Judul transaksi',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _splitAmount,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Total tagihan',
                        prefixText: 'Rp  ',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _splitPeople,
                      decoration: const InputDecoration(
                        labelText: 'Peserta',
                        hintText: 'Andi, Budi, Citra',
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: _createSplitBill,
                        icon: const Icon(Icons.calculate_outlined),
                        label: const Text('Bagi dan simpan'),
                      ),
                    ),
                    if (widget.splitBills.isNotEmpty) ...[
                      const Divider(height: 24),
                      ...widget.splitBills
                          .take(3)
                          .map(
                            (bill) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(bill.title),
                              subtitle: Text(
                                '${formatCurrency(bill.totalAmount)} • ${bill.participants.length} peserta',
                              ),
                              trailing: Text(
                                bill.isBalanced ? 'Seimbang' : 'Belum lengkap',
                              ),
                              onTap: () => _showSplitBillDetails(bill),
                            ),
                          ),
                    ],
                  ],
                ),
              ),
              _sectionTitle(
                'Target keuangan',
                'Pantau progres tabungan dan sasaran keuangan.',
                Icons.flag_outlined,
              ),
              _card(
                Column(
                  children: [
                    if (widget.savings.isEmpty)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Belum ada target keuangan.'),
                      )
                    else
                      ...widget.savings
                          .take(4)
                          .map(
                            (goal) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(goal.name),
                              subtitle: Text(
                                '${formatCurrency(goal.savedAmount)} dari ${formatCurrency(goal.targetAmount)}',
                              ),
                              trailing: Text(
                                '${(goal.progress * 100).round()}%',
                              ),
                            ),
                          ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onOpenSavings();
                        },
                        icon: const Icon(Icons.savings_outlined),
                        label: const Text('Kelola target tabungan'),
                      ),
                    ),
                  ],
                ),
              ),
              _sectionTitle(
                'Kategori merchant otomatis',
                'Aturan ini dipakai saat form menyimpan transaksi baru.',
                Icons.auto_awesome_outlined,
              ),
              _card(
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _rulePattern,
                            decoration: const InputDecoration(
                              labelText: 'Kata merchant',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<ExpenseCategory>(
                            value: _ruleCategory,
                            decoration: const InputDecoration(
                              labelText: 'Kategori',
                            ),
                            items: ExpenseCategory.values
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(item.label),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null)
                                setState(() => _ruleCategory = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: _saveRule,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Tambah aturan'),
                      ),
                    ),
                    if (widget.merchantRules.isNotEmpty) ...[
                      const Divider(height: 24),
                      ...widget.merchantRules.map(
                        (rule) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(rule.pattern),
                          subtitle: Text(rule.category.label),
                          trailing: IconButton(
                            tooltip: 'Hapus aturan',
                            onPressed: () =>
                                widget.onDeleteMerchantRule(rule.id),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _sectionTitle(
                'Laporan pribadi, bisnis, dan pajak',
                'Gunakan penanda bisnis/pajak pada form untuk ringkasan terpisah.',
                Icons.receipt_long_outlined,
              ),
              _card(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengeluaran bulan ini: ${formatCurrency(_monthSpend)}',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pengeluaran bisnis: ${formatCurrency(_businessSpend)}',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Nominal pajak tercatat: ${formatCurrency(_deductibleTax)}',
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Kolom bisnis/pajak juga ikut masuk backup XML dan ekspor transaksi.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
